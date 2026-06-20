# Architecture

How the tt-live skill is wired together: components, classes, data
flows, and the reasoning behind each design choice.

For per-file API details see `../tt_live.md`, `../tt-live.sh.md`, etc.
For JSON schemas see [SCHEMA.md](SCHEMA.md). For daemon-mode internals
see [DAEMON.md](DAEMON.md).

---

## 1. Component overview

```
                    requester
                        │
                        ▼
              OpenClaw sub-agent
                        │
                        ▼
                   tt-live.sh
                        │
              ┌─────────┴─────────────────┐
              │                           │
              ▼                           ▼
         tt_live.py             (standalone tools)
        check / url / daemon    get_room_id.py
              │                 check_alive.py
              │
        ┌─────┴─────┬───────────────┐
        ▼           ▼               ▼
   IdentityStore  StateStore   EventWriter
        │           │               │
        ▼           ▼               ▼
   tiktok-names/  state/        state/
   identities/    tt-live/      tt-live/
   pointers/      *.state.json  *.events
```

**Trust boundary:** the sub-agent is the only thing that reads events
and announces. The wrapper, the Python core, and the storage layer
never talk to chat.

---

## 2. Module structure: `tt_live.py`

```
tt_live.py
│
├── Constants
│     FORMAT_CAP="360"   MIN_POLL_MINUTES=5   DEFAULT_DAEMON_HOURS=12
│     URL_RETENTION_DAYS=3   REQUEST_TIMEOUT_SEC=15   TT_AID="1988"
│     USER_AGENT   DEFAULT_WORKSPACE
│
├── Workspace helpers
│     resolve_workspace()   ensure_dirs(ws)   now_iso()
│
├── HTTP layer
│     http_get(url) → (status, body)
│
├── SIGI_STATE scrape
│     parse_sigi_state(html)
│     fetch_user_live_page(username) → flattened identity+room dict
│     is_live_from_sigi(record) → bool
│
├── Webcast API
│     fetch_room_info(room_id) → room data dict
│     fetch_check_alive(room_id) → bool|None
│
├── Stream URL extraction
│     QUALITY_HEIGHT dict
│     pick_360p_hls(room_info) → url|None
│     extract_via_ytdlp(username) → url|None       (subprocess fallback)
│     extract_via_streamlink(username) → url|None  (subprocess fallback)
│     extract_stream_url(room_id, username) → (url, source)
│
├── class IdentityStore
│     load_identity / save_identity
│     load_pointer / write_pointer
│     resolve_sec_uid
│     update_from_scrape ← primary write path
│
├── class StateStore
│     read / write
│     add_url
│     strip_stale_urls ← passive garbage collector
│     get_latest_url
│
├── class EventWriter
│     write(evt, **fields) ← append-only line writer
│
└── Subcommands
      cmd_check(args)     → JSON to stdout, exit 0/1/2
      cmd_url(args)       → URL to stdout, exit 0/1/2
      cmd_daemon(args)    → background loop, events to file, exit 0/2
      build_parser()   main()   _sleep_until()
```

The three classes are the only mutable state. Everything else is a pure
function or a subprocess shell-out.

---

## 3. Data flow: `check`

```
tt-live.sh check <user>
       │
       ▼
python3 tt_live.py check <user>
       │
       ▼
cmd_check(args)
       │
       ▼
resolve_workspace → ensure_dirs → IdentityStore + StateStore
       │
       ▼
fetch_user_live_page(<user>)
       │ HTTP GET /@<user>/live
       │ parse_sigi_state
       ▼
flattened scrape dict { unique_id, nickname, user_id, sec_uid,
                        room_id, status, title, start_time }
       │
       ▼
IdentityStore.update_from_scrape(scrape)
       │ writes identities/<sec_uid>.json
       │ writes pointers/<unique_id>.json (current=true)
       │ if rename: marks old pointer current=false + appends rename_history
       ▼
is_live_from_sigi(scrape) → bool
       │
       ▼
StateStore.write(sec_uid, {is_live, current_room_id, last_check_ts})
       │
       ▼
StateStore.strip_stale_urls(sec_uid)  ← passive GC
       │
       ▼
JSON object → stdout
exit 0 (live) | 1 (offline) | 2 (error)
```

**One HTTP request per invocation.** No webcast API calls. No retry.

---

## 4. Data flow: `url`

```
tt-live.sh url <user>
       │
       ▼
python3 tt_live.py url <user>
       │
       ▼
cmd_url(args)
       │
       ├──► same scrape + identity update as `check`
       │
       ▼
is_live_from_sigi → offline? exit 1
       │
       ▼
StateStore.get_latest_url(sec_uid, room_id)
       │ cache hit? print URL → exit 0
       │
       ▼ cache miss
extract_stream_url(room_id, username):
       │
       ├── try 1: fetch_room_info → pick_360p_hls
       │            │ direct webcast API → JSON envelope → stream_url paths
       │            │ source = "api"
       │            ▼ success: return url
       │
       ├── try 2: extract_via_ytdlp (if yt-dlp on PATH)
       │            │ subprocess: yt-dlp -g -f "best[height<=360]/..."
       │            │ source = "yt-dlp"
       │            ▼ success: return url
       │
       └── try 3: extract_via_streamlink (if streamlink on PATH)
                    │ subprocess: streamlink --stream-url ... "360p,worst"
                    │ source = "streamlink"
                    ▼ success: return url

       │ all three failed? exit 2
       ▼
StateStore.add_url(sec_uid, room_id, url)
StateStore.strip_stale_urls(sec_uid)
       │
       ▼
URL → stdout
exit 0
```

**Cache-first** keeps repeat calls cheap (one HTTP for the SIGI scrape,
plus the disk read). Only on cache miss do we call the webcast API or
shell out.

---

## 5. Data flow: `daemon`

```
tt-live.sh daemon <user> --hours N --poll-min M
       │ wrapper nohup-spawns the daemon
       ▼
python3 tt_live.py daemon <user> --hours N --poll-min M
       │
       ▼
cmd_daemon(args)
       │
       ▼
first scrape → anchor sec_uid (exit 2 if it fails)
       │
       ▼
EventWriter.write(daemon_start)
       │
       ▼
┌─── poll loop until deadline ──────────────────────────────────┐
│                                                                │
│  fetch_user_live_page                                          │
│    │ failed? → poll_err reason=fetch_failed → sleep → continue │
│    ▼                                                           │
│  update_from_scrape                                            │
│    │ sec_uid changed? → poll_err reason=sec_uid_changed → ...  │
│    │ rename? → EventWriter.write(rename_detected)              │
│    ▼                                                           │
│  EventWriter.write(poll_ok alive=true|false)                   │
│    ▼                                                           │
│  transition logic:                                             │
│    ├ live & !last_was_live   → extract_stream_url              │
│    │                            → StateStore.add_url           │
│    │                            → StateStore.write             │
│    │                            → go_live event (stream_url=)  │
│    │                            transitions++                  │
│    │                                                           │
│    ├ !live & last_was_live   → StateStore.write                │
│    │                            → go_offline event             │
│    │                            transitions++                  │
│    │                                                           │
│    └ no transition           → strip_stale_urls only           │
│                                                                │
│  _sleep_until(deadline, poll_sec)                              │
│                                                                │
└────────────────────────────────────────────────────────────────┘
       │
       ▼ KeyboardInterrupt → end_reason = "interrupted"
EventWriter.write(daemon_end reason=... transitions=...)
       │
       ▼
exit 0
```

The daemon **always emits a `daemon_end` line** on the way out, no
matter how it exits (timer, SIGINT). The only path that bypasses
`daemon_end` is an uncaught crash — those go to the wrapper's log file
as a Python traceback. See [DAEMON.md](DAEMON.md) for poll cadence
details.

---

## 6. Event line structure

```
ts=<iso> evt=<type> sec_uid=<...> unique_id=<...> [k=v ...] [stream_url=...]
                                                              ▲
                                                              │
                                                       always LAST when present;
                                                       value contains & and =
                                                       which would break naive
                                                       key=value parsers
```

Field order is **deterministic** so consumers can write trivial parsers
without a state machine:

1. `ts=` always at index 0
2. `evt=` always at index 1
3. `sec_uid=` always at index 2 (when present)
4. `unique_id=` always at index 3 (when present)
5. Other keys in the order they were passed to `EventWriter.write()`
6. `stream_url=` always at the **end** when present

To extract the stream URL from a `go_live` line, a parser can take the
substring after the literal `" stream_url="` to end-of-line — no
escape handling needed.

The seven event types are documented in [SCHEMA.md](SCHEMA.md) §5
and [`../tt_live.md`](../tt_live.md) §10.

---

## 7. Design decisions

### 7.1 `secUid` is the primary key, not `uniqueId`

TikTok lets users rename their `@handle` (the `uniqueId`). The `secUid`
is the only identifier that does not change across renames.

The identity store keeps two file types:
- `identities/<sec_uid>.json` — one per user, the canonical record
- `pointers/<unique_id>.json` — one per known `@handle`, points at a `sec_uid`

When a rename is detected, the old pointer file stays on disk with
`current=false`. This means historical references to the old `@handle`
still resolve to the right user.

**Trade-off:** the pointer directory accumulates files over time. There
is no built-in cleanup. Given typical pointer file size (~150 bytes)
and rename frequency (rare), this is acceptable indefinitely.

### 7.2 Identity record carries `rename_history`

Each identity file records every rename in an append-only
`rename_history` list: `{from, to, detected_at}`. This is a forensic
record, not a navigational structure. The current `unique_id` lives in
`unique_id_current`.

### 7.3 Append-only event log per `secUid`

Daemon transitions go to `state/tt-live/<sec_uid>.events`, one line per
event, append-only. Consumers use `tail -F` to follow. This avoids a
database, a queue, or any in-memory state that would require the
daemon and the sub-agent to be co-located.

**Trade-off:** multiple daemons for the same user would interleave
lines. The wrapper does not prevent this; the sub-agent is responsible
for not double-spawning.

### 7.4 `stream_url=` is always the last key

Stream URL values contain `&` and `=` from query parameters (`expire=`,
`sign=`, etc.). A naive `awk -F= '{print $2}'` would mangle them. By
fixing `stream_url=` as the last key, consumers can extract the URL
with `"${line#*stream_url=}"` (bash) — no escaping, no quoting.

### 7.5 Passive stale-strip instead of an active GC

`StateStore.strip_stale_urls()` runs on every state-write path
(`cmd_check`, `cmd_url`, `cmd_daemon` poll loop). There is no scheduled
job, no separate process. Stale entries are removed as a side effect
of normal operation.

**Trade-off:** if a state file is never written to again, its stale
entries persist. Given the workspace is per-user and writes happen
whenever the daemon polls, this is not a problem in practice.

### 7.6 SIGI_STATE only — no UNIVERSAL_DATA fallback

The `/@<user>/live` page sometimes embeds a second blob,
`__UNIVERSAL_DATA_FOR_REHYDRATION__`, with a different schema. Its
structure for live-room data is not stable enough to rely on. The
skill checks only `SIGI_STATE`; missing or malformed SIGI returns
exit 2 immediately.

### 7.7 Stream-URL extraction order: API → yt-dlp → streamlink

The direct webcast API is the fastest and stdlib-only path. yt-dlp and
streamlink exist as fallbacks for cases where the API has shifted or
is blocked. Both fallbacks are optional — the skill works without
either.

The orchestrator (`extract_stream_url`) tries them in fixed order and
records which one produced the URL (`source` field). The order is not
configurable.

### 7.8 360p hardcoded

The format cap is fixed at 360p. The selection logic in
`pick_360p_hls` prefers (1) the `ld` quality key, (2) the largest
quality under 360p, (3) the smallest quality above 360p as last
resort.

**Trade-off:** higher-bandwidth use cases (1080p archival) are not
supported. This is intentional. Sub-agent announce flows need
predictable bandwidth.

### 7.9 5-minute poll floor

`MIN_POLL_MINUTES = 5` clamps the daemon's `--poll-min`. TikTok rate-
limits aggressive polling, and the `go_live` / `go_offline` resolution
this provides is sufficient for any announcement use case.

### 7.10 Standalone tools duplicate constants

`get_room_id.py` and `check_alive.py` re-declare `REQUEST_TIMEOUT_SEC`,
`USER_AGENT`, `TT_AID`, and the helper functions `now_iso` and
`http_get`. They do not import `tt_live.py`.

**Trade-off:** if `tt_live.py`'s constants change, two more files
need updating. The benefit is that either standalone tool can be
copied to any Python-3.9+ machine and run on its own.

### 7.11 No notifications, ever

The skill never emits chat output. There is no `Notifier` class, no
webhook configuration, no Slack/Discord integration. All chat
announcements are the sub-agent's job through OpenClaw's normal
announce mechanism.

This separation keeps the skill testable in isolation and prevents
accidental cross-channel leaks.

### 7.12 No version field in source

The Python files and shell script carry no version constants. Version
information lives in exactly one place: the `version:` field in
`SKILL.md`'s frontmatter. This is the only file that needs editing on
a release bump.

---

## 8. Out of scope

| Item | Why not |
|---|---|
| Recording or saving stream content | Out of scope; the skill resolves URLs, doesn't capture frames |
| Multi-user batch in a single daemon | One daemon per user keeps state files and event files cleanly partitioned |
| External notifications (Slack, Discord, webhooks) | Sub-agent's job, not skill's |
| Stop / pause / resume daemon commands | Sub-agent has the pid; `kill <pid>` triggers a clean `daemon_end reason=interrupted` |
| OpenClaw cron mode | OpenClaw 2026.5.x cron has `ask=always` enforcement that breaks ~16k tokens per run; explicitly disabled at the gateway |
| `--quality` / `--format` flags | 360p hardcoded; bandwidth predictability |
| HTTP retry logic | Single attempt; transient failure → caller decides whether to re-run |
| Identity-store cleanup | Pointer/identity files are tiny; never deleted automatically |
| `__UNIVERSAL_DATA_FOR_REHYDRATION__` fallback | Schema unreliable for live-room data |
| Per-user config files | All knobs live in `tt-live.json` (defaults reference) and `tt_live.py` (live constants) |

Each entry is a conscious choice, not an oversight. Re-adding any of
them is a substantive change that requires confirming the underlying
assumption still holds.
