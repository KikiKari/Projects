# `tt_live.py` — Code Reference

Source: `tt_live.py`. Single-file Python core for the TikTok LIVE monitor.

This document covers every public surface — constants, functions, classes,
and subcommands — with inputs, outputs, side effects, and exit codes.

The companion files `tt-live.sh`, `tt-live.json`, `get_room_id.py`,
`check_alive.py` are documented in their own `*.md` files. Architecture
and event-format specs live under `docs/`.

---

## 1. Overview

`tt_live.py` is a stdlib-only Python module with three subcommands:

| Subcommand | Purpose | Output |
|---|---|---|
| `check`  | One-shot live status scrape | JSON to stdout |
| `url`    | Resolve current m3u8 stream URL | URL to stdout |
| `daemon` | Poll over a timer window | Events to file |

**The tool produces data. It does not push notifications.** All
notifications and chat announcements are owned by the OpenClaw sub-agent
that invokes it. The sub-agent reads the daemon's event file (or stdout
of `check` / `url`) and decides what to announce.

### 1.1 Dependencies

- Python 3.9+ (uses `tuple[T, ...]` syntax with `from __future__ import annotations`)
- stdlib only for the primary code path: `argparse`, `json`, `os`,
  `shutil`, `subprocess`, `sys`, `time`, `urllib`, `datetime`, `pathlib`
- **Optional** external binaries on `PATH`, used only as fallbacks when
  the direct API extraction fails:
  - `yt-dlp`
  - `streamlink`

If neither optional binary is installed, the primary direct-API path
still works for any TikTok LIVE in the supported region.

### 1.2 Module shape

```
Constants
Workspace helpers      resolve_workspace, ensure_dirs, now_iso
HTTP layer             http_get
SIGI_STATE scrape      parse_sigi_state, fetch_user_live_page, is_live_from_sigi
Webcast API            fetch_room_info, fetch_check_alive
Stream URL extraction  pick_360p_hls, extract_via_ytdlp, extract_via_streamlink,
                       extract_stream_url
IdentityStore (class)  load/save identity, pointer, update_from_scrape
StateStore (class)     read/write state, add_url, strip_stale_urls,
                       get_latest_url
EventWriter (class)    write(evt, **fields)
Subcommands            cmd_check, cmd_url, cmd_daemon
Argparse / main        build_parser, main
```

---

## 2. Constants

All constants are **module-level and intentionally not configurable** at
runtime. Values are part of the contract; changes require a code edit
and a docs update.

### `FORMAT_CAP = "360"`
Hardcoded 360p cap for stream-URL selection. Applied in three places:
`pick_360p_hls()` quality preference order, `extract_via_ytdlp()` format
selector `best[height<=360]/worst[height<=360]/worst`, and
`extract_via_streamlink()` quality argument `360p,worst`. **Not exposed
to the CLI or config.**

### `MIN_POLL_MINUTES = 5`
Floor for the daemon's `--poll-min` argument. Any value below 5 is
silently clamped to 5 in `cmd_daemon()`.

### `DEFAULT_DAEMON_HOURS = 12`
Default value for `daemon --hours` when the flag is omitted.

### `URL_RETENTION_DAYS = 3`
Retention window for stream URLs in `StateStore`. Passive stale-strip
removes entries with `captured_at` older than this on every state-write
path.

### `REQUEST_TIMEOUT_SEC = 15`
Per-HTTP-request timeout, used for direct stdlib calls. Subprocess
fallbacks (yt-dlp, streamlink) get `2 × REQUEST_TIMEOUT_SEC` as their
subprocess timeout.

### `TT_AID = "1988"`
TikTok webcast app id. Sent as the `aid` query parameter on
`/webcast/room/info/` and `/webcast/room/check_alive/` calls. Stable
across observed HAR captures.

### `USER_AGENT`
Realistic Chrome 124 desktop user-agent. Sent on every HTTP request
unless overridden via `extra_headers` in `http_get()`. TikTok's webcast
endpoints reject obviously-non-browser UAs.

### `DEFAULT_WORKSPACE`
`Path.home() / ".openclaw" / "workspace" / "tiktok-monitor"`. Used when
the `TT_LIVE_WORKSPACE` environment variable is unset or empty.

---

## 3. Workspace helpers

### `resolve_workspace() -> Path`
Returns the workspace root.

- If env var `TT_LIVE_WORKSPACE` is set and non-empty, returns
  `Path(env).expanduser().resolve()`.
- Otherwise returns `DEFAULT_WORKSPACE`.

No filesystem access; pure path resolution. Use `ensure_dirs()` before
writing.

### `ensure_dirs(ws: Path) -> None`
Creates the four required subdirectories under `ws` with
`parents=True, exist_ok=True`:

```
<ws>/tiktok-names/identities/
<ws>/tiktok-names/pointers/
<ws>/state/tt-live/
```

Idempotent. Called at the start of every subcommand.

### `now_iso() -> str`
Returns the current UTC time as an ISO 8601 string with second
precision and a trailing `Z`, e.g. `2026-05-25T18:22:13Z`.

Used everywhere a timestamp is persisted or emitted in an event line.

---

## 4. HTTP layer

### `http_get(url, timeout=REQUEST_TIMEOUT_SEC, extra_headers=None) -> tuple[int, bytes]`
Performs a GET request via `urllib.request`.

**Inputs:**
- `url` — full URL string
- `timeout` — seconds (default `REQUEST_TIMEOUT_SEC`)
- `extra_headers` — optional `dict` merged on top of the default header
  set

**Default headers:**
```
User-Agent:      <USER_AGENT>
Accept:          text/html,application/json,*/*
Accept-Language: en-US,en;q=0.9
Referer:         https://www.tiktok.com/
```

**Returns:** `(status_code, body_bytes)`.

**Error handling:**
- `HTTPError` (4xx, 5xx) → returns `(e.code, e.read())`
- `URLError`, `TimeoutError`, `OSError` → returns `(0, b"")`

Never raises. Callers test `status == 200 and body` before parsing.

---

## 5. SIGI_STATE scrape

The TikTok web profile page embeds a `<script id="SIGI_STATE">` JSON
blob containing the user record and current liveRoom metadata. This is
the only source the tool uses for user-level data. `UNIVERSAL_DATA_FOR_REHYDRATION` is **not** used as a fallback.

### `parse_sigi_state(html_bytes: bytes) -> dict | None`
Locates the `<script id="SIGI_STATE" type="application/json">…</script>`
block in the raw HTML and parses the inner JSON.

Returns `None` if the marker is missing, the script tag is unterminated,
or the JSON is malformed.

### `fetch_user_live_page(username: str) -> dict | None`
GETs `https://www.tiktok.com/@<username>/live`, calls
`parse_sigi_state()`, and flattens the relevant fields from
`LiveRoom.liveRoomUserInfo` into a single dict.

**Returned dict shape (when successful):**
```python
{
  "unique_id":  str,    # uniqueId (the @handle)
  "nickname":   str,    # display name
  "user_id":    str,    # numeric user id (e.g. "131475542305824768")
  "sec_uid":    str,    # MS4wLjA... — stable primary key
  "room_id":    str,    # current room_id, "0" or missing if offline
  "status":     int,    # room.status (2 = LIVE)
  "title":      str,    # stream title if live
  "start_time": int,    # unix seconds of stream start
}
```

Returns `None` if HTTP failed or SIGI_STATE could not be located/parsed.

### `is_live_from_sigi(record: dict) -> bool`
Decides if the scraped record represents an active LIVE.

- Primary: `status == 2` (when `status` is an int)
- Fallback: truthy `room_id` and not `"0"`

Used by `cmd_check`, `cmd_url`, and `cmd_daemon` to gate transition
logic and exit codes.

---

## 6. Webcast API

Direct calls to TikTok's webcast service. Used by the stream-URL
extractor and available for ad-hoc checks.

### `fetch_room_info(room_id: str) -> dict | None`
GET `https://webcast.tiktok.com/webcast/room/info/?aid=1988&room_id=<id>`.

Returns the parsed `data` object from the response envelope, or `None`
on any failure (non-200 status, empty body, JSON decode error, missing
`data` field).

The returned `data` dict contains `stream_url`, `room_id`, host info,
and other room metadata. `pick_360p_hls()` consumes it.

### `fetch_check_alive(room_id: str) -> bool | None`
GET `https://webcast.tiktok.com/webcast/room/check_alive/?aid=1988&room_ids=<id>`.

Returns:
- `True` if the response's `data[0].alive` is truthy
- `False` if the first item exists but `alive` is falsy
- `None` on any failure (non-200, malformed JSON, empty `data` array)

This is the same endpoint as `check_alive.py` (the standalone tool).
`tt_live.py` does not call this on the primary path — the SIGI scrape
already tells us whether the user is live. It is included here as an
internal helper for future callers.

---

## 7. Stream URL extraction

### `QUALITY_HEIGHT` (module-level dict)
Maps TikTok stream quality keys to estimated pixel heights:

```python
{
  "ao":      0,      # audio-only
  "ld":      360,    # 360p
  "sd":      540,    # 540p
  "hd":      720,    # 720p
  "hd_60":   720,    # 720p60
  "uhd_60":  1080,   # 1080p60
  "origin":  1080,   # source quality
}
```

Used only by `pick_360p_hls()` to apply the cap.

### `pick_360p_hls(room_info: dict) -> str | None`
Walks the `stream_url` block of a `room/info` response and picks one
HLS m3u8 URL under the 360p cap.

**Two stream_url layouts are handled:**

1. **Layout A**: `stream_url.live_core_sdk_data.pull_data.stream_data`
   is a JSON-encoded string. After decoding, iterate
   `data.<quality>.main.hls`.

2. **Layout B**: `stream_url.hls_pull_url_map` is a flat dict mapping
   quality key to m3u8 URL.

Both layouts feed into a unified `candidates` list of `(quality_key,
url)` tuples.

**Selection rules:**

1. Audio-only (`ao`) excluded unless nothing else is available.
2. Sort by preference:
   - `ld` (exact 360p) always wins
   - Then closest to 360p without exceeding (larger height under the
     cap is better, because TikTok rarely has discrete <360p)
   - Then lowest height above the cap (closer to 360p is better than
     1080p)
3. Return the first candidate's URL.

Returns `None` if no candidates are present.

### `extract_via_ytdlp(username: str) -> str | None`
Subprocess shell-out to `yt-dlp` if it exists on `PATH`.

**Command:**
```
yt-dlp -g -f "best[height<=360]/worst[height<=360]/worst"
       "https://www.tiktok.com/@<username>/live"
```

- `-g` prints the resolved URL(s) to stdout
- Timeout: `2 × REQUEST_TIMEOUT_SEC` (30s default)
- Returns the first line containing `.m3u8`, or the first non-empty
  output line if no m3u8 is found
- Returns `None` if yt-dlp isn't installed, exits non-zero, times out,
  or produces no usable output

### `extract_via_streamlink(username: str) -> str | None`
Subprocess shell-out to `streamlink` if it exists on `PATH`.

**Command:**
```
streamlink --stream-url
           "https://www.tiktok.com/@<username>/live"
           "360p,worst"
```

The quality selector `"360p,worst"` means "give me 360p; if not
available, the worst available."

Returns the trimmed stdout, or `None` on any failure mode.

### `extract_stream_url(room_id: str, username: str) -> tuple[str | None, str]`
Orchestrator that tries each strategy in order. Returns
`(url, source)`:

| Strategy | Source string | When |
|---|---|---|
| `fetch_room_info` → `pick_360p_hls` | `"api"` | Direct API succeeds |
| `extract_via_ytdlp` | `"yt-dlp"` | API failed, yt-dlp on PATH |
| `extract_via_streamlink` | `"streamlink"` | yt-dlp failed/missing |
| (nothing) | `"none"` | All three failed |

The `source` string is also surfaced via `cmd_url --verbose`.

---

## 8. `IdentityStore` class

Filesystem-backed identity registry.

### Layout

```
<workspace>/tiktok-names/
├── identities/
│   └── <sec_uid>.json   # one file per known user
└── pointers/
    └── <unique_id>.json # one file per known @handle
```

`sec_uid` is the primary key. `unique_id` (the `@handle`) is a pointer
that can change when a user renames their account. Old pointer rows
stay on disk with `current=false` so historical lookups still resolve.

### `__init__(workspace: Path)`
Stores `self.ident_dir` and `self.ptr_dir`. Does not create
directories — that's `ensure_dirs()`'s job.

### Internal path helpers
- `_ident_path(sec_uid) -> Path` → `identities/<sec_uid>.json`
- `_ptr_path(unique_id) -> Path` → `pointers/<unique_id>.json`

### `load_identity(sec_uid: str) -> dict | None`
Reads and returns the parsed JSON record, or `None` if the file
doesn't exist or fails to parse.

### `save_identity(sec_uid: str, record: dict) -> None`
Writes the record with two enforced fields:
- `sec_uid` (overwritten from arg)
- `last_seen` (always set to `now_iso()`)
- `first_seen` (set to `last_seen` if not present)

Writes pretty-printed JSON (`indent=2, ensure_ascii=False`).

### `load_pointer(unique_id: str) -> dict | None`
Same shape as `load_identity` but for the pointer file.

### `write_pointer(unique_id: str, sec_uid: str, current: bool = True) -> None`
Writes a pointer file. Preserves `first_pointed_at` if a prior pointer
exists; always updates `last_pointed_at`.

**Record shape:**
```python
{
  "unique_id":         str,
  "sec_uid":           str,
  "current":           bool,
  "first_pointed_at":  iso,
  "last_pointed_at":   iso,
}
```

### `resolve_sec_uid(username: str) -> str | None`
Convenience: load pointer for `username`, return `sec_uid` field or
`None`.

### `update_from_scrape(scrape: dict) -> tuple[str | None, bool]`
The main write path. Called by every subcommand after a successful
`fetch_user_live_page()`.

**Returns:** `(sec_uid, rename_detected)`.

**Logic:**
1. If `sec_uid` or `unique_id` is missing from the scrape → return
   `(None, False)`.
2. Load existing identity for `sec_uid`.
3. If prior `unique_id_current` exists and differs from the fresh
   `unique_id` → `rename_detected = True`.
4. Build the new identity record. Preserve `first_seen` and
   `rename_history` from the existing record.
5. On rename: append a `{from, to, detected_at}` row to
   `rename_history`, and mark the old pointer file `current=false`.
6. Save identity and write the new pointer with `current=true`.

**Identity record shape (after update):**
```python
{
  "sec_uid":            str,
  "unique_id_current":  str,
  "nickname":           str,
  "user_id":            str,
  "first_seen":         iso,
  "last_seen":          iso,
  "rename_history": [   # optional, only if renames happened
    {"from": str, "to": str, "detected_at": iso},
    ...
  ],
}
```

---

## 9. `StateStore` class

Per-`sec_uid` live state and stream URL cache.

### Layout

```
<workspace>/state/tt-live/
└── <sec_uid>.state.json
```

### State record shape

```python
{
  "sec_uid":          str,
  "is_live":          bool,
  "current_room_id":  str | None,
  "last_check_ts":    iso | None,
  "stream_urls": [
    {"room_id": str, "url": str, "captured_at": iso},
    ...
  ],
}
```

### `__init__(workspace: Path)`
Stores `self.dir`. Path: `<workspace>/state/tt-live/`.

### `_path(sec_uid) -> Path`
Returns the state file path.

### `_default(sec_uid) -> dict`
Returns a fresh, zero-state record. Used when no file exists or the
file is unparseable.

### `read(sec_uid: str) -> dict`
Reads the state file. Returns `_default()` on missing file or parse
error. **Never raises.**

### `write(sec_uid: str, state: dict) -> None`
Writes the record pretty-printed. Overwrites `state["sec_uid"]` from
the arg for consistency.

### `add_url(sec_uid: str, room_id: str, url: str) -> None`
Appends a `(room_id, url, captured_at)` entry to `stream_urls` unless
an identical row already exists (dedup by `room_id` + `url`).

### `strip_stale_urls(sec_uid: str, days: int = URL_RETENTION_DAYS) -> None`
Removes entries with `captured_at` older than `days` (default 3).
Malformed timestamps are dropped. Only writes the file if something
actually changed.

This is a **passive** garbage collector — it runs on every state-write
path (`cmd_check`, `cmd_url`, `cmd_daemon`) but never on its own
schedule.

### `get_latest_url(sec_uid: str, room_id: str | None = None) -> str | None`
Returns the most recently captured URL.

- If `room_id` is given: return the most recent URL for that room_id
- Otherwise: return the last URL in the list regardless of room_id
- Returns `None` if `stream_urls` is empty

Used by `cmd_url` for cache-first behavior.

---

## 10. `EventWriter` class

Append-only event log for daemon transitions.

### File path

```
<workspace>/state/tt-live/<sec_uid>.events
```

### `__init__(workspace: Path, sec_uid: str)`
Stores `self.path`. No file is created until `.write()` is called.

### `write(evt: str, **fields) -> None`
Appends one event line.

**Key order in the emitted line:**

1. `ts=<iso>` (always first)
2. `evt=<type>` (always second)
3. `sec_uid=<sec_uid>` (third if non-empty)
4. `unique_id=<unique_id>` (fourth if non-empty)
5. Remaining keys in the order passed to `**fields`
6. `stream_url=<url>` (always last if present)

**The `stream_url=` placement is required** so parsers can take the
substring after `stream_url=` to the end of the line without escaping
the `&` and `=` inside the URL.

**Defined event types:**

| `evt` | When | Required fields |
|---|---|---|
| `daemon_start` | Daemon entry | `sec_uid`, `unique_id`, `hours`, `poll_sec` |
| `daemon_end` | Daemon exit | `sec_uid`, `unique_id`, `reason`, `transitions` |
| `poll_ok` | Successful poll | `sec_uid`, `unique_id`, `alive` |
| `poll_err` | Failed poll | `sec_uid`, `unique_id`, `reason` |
| `go_live` | offline → live transition | `sec_uid`, `unique_id`, `room_id`, `stream_url` |
| `go_offline` | live → offline transition | `sec_uid`, `unique_id`, `last_room_id` |
| `rename_detected` | uniqueId changed for same sec_uid | `sec_uid`, `unique_id` (new), `old_unique_id` |

`reason` values for `daemon_end`: `timer_expired`, `interrupted`.

`reason` values for `poll_err`: `fetch_failed`, `sec_uid_changed`
(plus `new_sec_uid` field in the latter case).

`alive` is the literal string `"true"` or `"false"` (not bool).

---

## 11. Subcommand: `check`

```
python3 tt_live.py check <username>
```

### Function: `cmd_check(args) -> int`

**Behavior:**
1. Resolve workspace + ensure dirs
2. `fetch_user_live_page(username)` — one HTTP request
3. Update identity store from the scrape
4. Update state store with `is_live`, `current_room_id`, `last_check_ts`
5. Run passive stale-strip on stream URLs
6. Print one JSON object to stdout

**stdout JSON shape:**
```json
{
  "sec_uid":         "MS4wLjA...",
  "unique_id":       "luiisamour",
  "nickname":        "Display Name",
  "user_id":         "131475542305824768",
  "live":            true,
  "room_id":         "7643867662644251414",
  "title":           "stream title",
  "start_time":      1748196000,
  "rename_detected": false,
  "checked_at":      "2026-05-25T18:22:13Z"
}
```

When offline, `room_id`, `title`, and `start_time` are `null`.

**Exit codes:**

| Code | Meaning |
|---|---|
| 0 | User is currently live |
| 1 | User is offline (also writes JSON with `live: false`) |
| 2 | Error: HTTP fetch failed, SIGI_STATE missing, sec_uid missing, identity update failed |

**No events are written.** `check` is purely one-shot.

---

## 12. Subcommand: `url`

```
python3 tt_live.py url <username> [--verbose|-v]
```

### Function: `cmd_url(args) -> int`

**Behavior:**
1. Resolve workspace + ensure dirs
2. Fresh scrape (also serves to find current `room_id`)
3. Update identity store
4. If offline → exit 1 (stderr error message)
5. Cache-first: check `StateStore.get_latest_url(sec_uid, room_id)`
6. On cache hit → print cached URL, exit 0
7. On cache miss → `extract_stream_url(room_id, username)`:
   - Direct API first
   - yt-dlp if API fails and yt-dlp is on PATH
   - streamlink if yt-dlp fails too
8. On success → add to state store, run stale-strip, print URL to
   stdout, exit 0
9. If `--verbose`/`-v` → print `# source: <source>` to stderr

**Sources reported with `--verbose`:**
- `cache` — served from `StateStore`
- `api` — direct webcast API
- `yt-dlp` — subprocess fallback
- `streamlink` — subprocess fallback

**Exit codes:**

| Code | Meaning |
|---|---|
| 0 | URL printed |
| 1 | User is offline |
| 2 | Error: HTTP failed, missing room_id, or all three extraction strategies failed |

---

## 13. Subcommand: `daemon`

```
python3 tt_live.py daemon <username> [--hours N] [--poll-min M]
```

### Function: `cmd_daemon(args) -> int`

Default duration 12 hours, default poll interval 5 minutes (floor).
Values below the floor are silently clamped: `max(MIN_POLL_MINUTES, poll_min)`.

**Behavior:**

1. Resolve workspace + ensure dirs
2. **Anchor identity** with a first scrape. If sec_uid can't be
   determined → return 2 (error).
3. Create `EventWriter` for the anchored sec_uid.
4. Compute `deadline = time.time() + hours * 3600`.
5. Seed `last_was_live` from the existing state store.
6. Emit `daemon_start` event.
7. **Poll loop** until `time.time() >= deadline`:
   - Scrape `/@user/live`. If fetch fails → `poll_err
     reason=fetch_failed`, sleep, continue.
   - Update identity. If sec_uid suddenly differs from the anchor →
     `poll_err reason=sec_uid_changed new_sec_uid=...`, sleep, continue.
     (This is an edge case — username re-registered to a new account.)
   - If rename detected → `rename_detected` event (logs both old and
     new uniqueId, anchored to the same sec_uid).
   - Always emit `poll_ok alive=true|false`.
   - If `live` and not `last_was_live` (offline → live):
     - Extract stream URL via `extract_stream_url()`
     - Add URL to state store (if extracted)
     - Update state (`is_live=true`, `current_room_id=room_id`)
     - Emit `go_live` with `room_id` and `stream_url` (stream_url last)
     - Increment `transitions`
   - If `not live` and `last_was_live` (live → offline):
     - Update state (`is_live=false`, `current_room_id=None`)
     - Emit `go_offline` with `last_room_id`
     - Increment `transitions`
   - On no transition: still run `strip_stale_urls`.
   - Sleep `min(poll_sec, remaining_to_deadline)`.
8. On `KeyboardInterrupt`: `end_reason = "interrupted"`.
9. Emit `daemon_end` event.

**stderr lines emitted:**
```
[tt-live] daemon started for @<user> (sec_uid=<first16>..., hours=N, poll=Mmin)
[tt-live] daemon ended (<reason>, transitions=N)
```

**Exit codes:**

| Code | Meaning |
|---|---|
| 0 | Clean end (timer expired OR Ctrl-C) |
| 2 | Could not anchor identity before entering the loop |

The daemon **does not exit** on temporary fetch failures. It emits
`poll_err` and keeps polling until the deadline.

### `_sleep_until(deadline, max_sleep) -> None`
Module-internal helper. Sleeps `min(max_sleep, max(1.0, remaining))`
where `remaining = deadline - time.time()`. Used inside the poll loop
to clamp the final sleep so the daemon doesn't overshoot the deadline.

---

## 14. Argparse

### `build_parser() -> argparse.ArgumentParser`
Constructs the parser with three subcommands. Each subparser sets a
`func` default pointing to its `cmd_*` handler.

### `main(argv: list[str] | None = None) -> int`
Parses arguments and dispatches to `args.func(args)`. Returns the int
exit code.

`if __name__ == "__main__": raise SystemExit(main())` so the file is
directly runnable.

---

## 15. Environment variables

| Variable | Purpose | Default |
|---|---|---|
| `TT_LIVE_WORKSPACE` | Workspace root override | `~/.openclaw/workspace/tiktok-monitor` |

No other environment variables are read.

---

## 16. Filesystem layout (after first use)

```
<workspace>/
├── tiktok-names/
│   ├── identities/
│   │   └── MS4wLjA...secUid.json
│   └── pointers/
│       └── luiisamour.json
└── state/
    └── tt-live/
        ├── MS4wLjA...secUid.state.json
        └── MS4wLjA...secUid.events
```

Both `.state.json` and `.events` filenames use the **raw sec_uid**
(which is URL-safe base64-ish: `[A-Za-z0-9_-]`), so no path escaping is
needed.

---

## 17. What is intentionally NOT in this file

For audit purposes, the following surfaces were considered and
**deliberately excluded** based on confirmed requirements:

- No `Notifier` class
- No `notifications.*` config keys (the entire HTTP-out-to-webhook code
  path)
- No `_post_json` helper
- No external webhook URLs anywhere
- No `bootstrap` / `configure` / `doctor` / `verify` / `check`-as-shell
  subcommand
- No `--all`, `--quality`, `--json`, `--refresh` flags on `url`
- No `dedup-window` event suppression
- No `previous_sec_uids[]` array in pointer files
- No `UNIVERSAL_DATA_FOR_REHYDRATION` fallback for SIGI scraping
- No active garbage collection — only passive stale-strip
- No version string anywhere in the module
- No hardcoded TikTok account names

Each of these was a request the tool would handle differently from what
the user wants. The architecture document covers the reasoning under
"Out-of-scope decisions."
