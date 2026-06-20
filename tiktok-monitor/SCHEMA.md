# Schema Reference

Concrete schemas for every JSON object and event line produced or
consumed by the tt-live skill. Anything written to disk, printed to
stdout, or appended to the events file is documented here.

Type notation:
- `string` — JSON string
- `int` — JSON number (integer)
- `bool` — JSON boolean
- `iso` — ISO-8601 UTC timestamp, second precision, trailing `Z`
  (e.g. `2026-05-25T18:22:13Z`)
- `string|null` — nullable field (always present, but value may be `null`)
- Square brackets denote arrays. Curly braces denote nested objects.

---

## 1. Filesystem layout

```
<workspace>/
├── tiktok-names/
│   ├── identities/<sec_uid>.json     §2  Identity record
│   └── pointers/<unique_id>.json     §3  Pointer record
└── state/tt-live/
    ├── <sec_uid>.state.json          §4  State record
    └── <sec_uid>.events              §5  Event lines (append-only)
```

`<workspace>` resolves to `$TT_LIVE_WORKSPACE` (default
`~/.openclaw/workspace/tiktok-monitor/`).

All filenames use the **raw** `sec_uid` or `unique_id` value. No path
escaping is needed because:
- `sec_uid` values are URL-safe base64-ish: `[A-Za-z0-9_-]`
- `unique_id` values are TikTok handles, restricted by TikTok to
  `[A-Za-z0-9._]`

Files are JSON, pretty-printed with `indent=2`, UTF-8 encoded.

---

## 2. Identity record

**Path:** `<workspace>/tiktok-names/identities/<sec_uid>.json`
**Written by:** `IdentityStore.update_from_scrape`, `IdentityStore.save_identity`
**Read by:** `IdentityStore.load_identity`, manual inspection

### 2.1 Schema

```jsonc
{
  "sec_uid":           "string",      // primary key; matches the filename
  "unique_id_current": "string",      // current @handle
  "nickname":          "string|null", // display name (can be null if SIGI was sparse)
  "user_id":           "string|null", // numeric user id as string
  "first_seen":        "iso",         // first time this sec_uid was observed
  "last_seen":         "iso",         // most recent observation
  "rename_history":    [              // optional; present only if renames detected
    {
      "from":        "string",       // previous unique_id
      "to":          "string",       // new unique_id at detection
      "detected_at": "iso"
    }
  ]
}
```

### 2.2 Example (with one rename)

```json
{
  "sec_uid": "MS4wLjABAAAAPRgsgl2-tpIN4uBswC_8gqHYzknKIt_2MQ-6_TW_ajIcfz2xy8zIMEMV1W4t4iM_",
  "unique_id_current": "luiisamour",
  "nickname": "lui",
  "user_id": "131475542305824768",
  "first_seen": "2026-05-20T14:00:00Z",
  "last_seen": "2026-05-25T18:22:13Z",
  "rename_history": [
    {
      "from": "lui_amour",
      "to": "luiisamour",
      "detected_at": "2026-05-22T09:14:00Z"
    }
  ]
}
```

### 2.3 Field notes

- `sec_uid` is the stable primary key; never changes for a user.
- `unique_id_current` is the most recently observed `@handle`.
- `rename_history` is **append-only**. The skill never removes entries.
  An entry per detected rename, in chronological order.
- `nickname` and `user_id` can be `null` if a malformed SIGI returned
  partial data, but the file is still written.

---

## 3. Pointer record

**Path:** `<workspace>/tiktok-names/pointers/<unique_id>.json`
**Written by:** `IdentityStore.write_pointer`
**Read by:** `IdentityStore.load_pointer`, `IdentityStore.resolve_sec_uid`

### 3.1 Schema

```jsonc
{
  "unique_id":         "string",  // the @handle; matches the filename
  "sec_uid":           "string",  // → identities/<sec_uid>.json
  "current":           "bool",    // true if this @handle is the user's current one
  "first_pointed_at":  "iso",
  "last_pointed_at":   "iso"
}
```

### 3.2 Example (current pointer)

```json
{
  "unique_id": "luiisamour",
  "sec_uid": "MS4wLjABAAAAPRgsgl2-tpIN4uBswC_8gqHYzknKIt_2MQ-6_TW_ajIcfz2xy8zIMEMV1W4t4iM_",
  "current": true,
  "first_pointed_at": "2026-05-22T09:14:00Z",
  "last_pointed_at": "2026-05-25T18:22:13Z"
}
```

### 3.3 Example (historical pointer, after a rename)

```json
{
  "unique_id": "lui_amour",
  "sec_uid": "MS4wLjABAAAAPRgsgl2-tpIN4uBswC_8gqHYzknKIt_2MQ-6_TW_ajIcfz2xy8zIMEMV1W4t4iM_",
  "current": false,
  "first_pointed_at": "2026-05-20T14:00:00Z",
  "last_pointed_at": "2026-05-22T09:14:00Z"
}
```

### 3.4 Field notes

- Multiple pointer files can point at the same `sec_uid` (one per
  historical `@handle`).
- Exactly **one** pointer per `sec_uid` has `current: true` at any
  time — the one matching `identities/<sec_uid>.json::unique_id_current`.
- Old pointers are **never deleted**, only marked `current=false`. This
  preserves historical lookups by old `@handle`.

---

## 4. State record

**Path:** `<workspace>/state/tt-live/<sec_uid>.state.json`
**Written by:** `StateStore.write`, `StateStore.add_url`, `StateStore.strip_stale_urls`
**Read by:** `StateStore.read`, `StateStore.get_latest_url`

### 4.1 Schema

```jsonc
{
  "sec_uid":          "string",       // primary key; matches the filename
  "is_live":          "bool",         // most recently observed live state
  "current_room_id":  "string|null",  // present room_id if is_live, else null
  "last_check_ts":    "iso|null",     // null if never checked
  "stream_urls": [
    {
      "room_id":     "string",
      "url":         "string",       // m3u8 URL
      "captured_at": "iso"
    }
  ]
}
```

### 4.2 Example (currently live, with one cached URL)

```json
{
  "sec_uid": "MS4wLjABAAAAPRgsgl2-tpIN4uBswC_8gqHYzknKIt_2MQ-6_TW_ajIcfz2xy8zIMEMV1W4t4iM_",
  "is_live": true,
  "current_room_id": "7643867662644251414",
  "last_check_ts": "2026-05-25T18:22:13Z",
  "stream_urls": [
    {
      "room_id": "7643867662644251414",
      "url": "https://pull-hls-f16-tt04.tiktokcdn-eu.com/.../index.m3u8?expire=1748800000&sign=...",
      "captured_at": "2026-05-25T18:22:13Z"
    }
  ]
}
```

### 4.3 Field notes

- `stream_urls` retention: entries older than `URL_RETENTION_DAYS`
  (default 3) are removed on every state-write path by
  `StateStore.strip_stale_urls`. Malformed `captured_at` values cause
  the entry to be dropped.
- `stream_urls` dedup: `add_url` is a no-op if an entry with the same
  `(room_id, url)` already exists. There is no count or last-seen
  field — just the original `captured_at`.
- A single `sec_uid` may have multiple `stream_urls` entries spanning
  different `room_id` values (the user went offline and back live with
  a new room).

---

## 5. Event line format

**Path:** `<workspace>/state/tt-live/<sec_uid>.events`
**Written by:** `EventWriter.write`
**Read by:** sub-agents tailing the file

This is **not JSON**. Each event is one line, key=value space-separated.

### 5.1 Field order rules

```
ts=<iso> evt=<type> sec_uid=<...> unique_id=<...> [k=v ...] [stream_url=...]
```

1. `ts=` always first
2. `evt=` always second
3. `sec_uid=` third (when present; always present in current emitters)
4. `unique_id=` fourth (when present)
5. Other keys in the order the emitter passed them
6. `stream_url=` always **last** when present (URL contains `&` and `=`)

Values must not contain spaces. URLs are space-free by HTTP spec, so
this holds in practice.

### 5.2 Event type reference

| `evt=` | Required fields | Optional fields |
|---|---|---|
| `daemon_start` | `sec_uid`, `unique_id`, `hours`, `poll_sec` | — |
| `daemon_end` | `sec_uid`, `unique_id`, `reason`, `transitions` | — |
| `poll_ok` | `sec_uid`, `unique_id`, `alive` | — |
| `poll_err` | `sec_uid`, `unique_id`, `reason` | `new_sec_uid` (only with `reason=sec_uid_changed`) |
| `go_live` | `sec_uid`, `unique_id`, `room_id` | `stream_url` (present iff extraction succeeded) |
| `go_offline` | `sec_uid`, `unique_id` | `last_room_id` |
| `rename_detected` | `sec_uid`, `unique_id` (NEW handle), `old_unique_id` | — |

### 5.3 Field value reference

| Field | Type | Notes |
|---|---|---|
| `ts` | iso | UTC, second precision |
| `evt` | string | one of the seven types above |
| `sec_uid` | string | the user's `secUid` |
| `unique_id` | string | current `@handle` at emit time |
| `hours` | int | from `--hours` argument |
| `poll_sec` | int | poll interval in seconds (poll_min * 60) |
| `reason` | string | for `daemon_end`: `timer_expired` \| `interrupted`. For `poll_err`: `fetch_failed` \| `sec_uid_changed` |
| `transitions` | int | count of `go_live` + `go_offline` events emitted in this daemon run |
| `alive` | string | literal `"true"` or `"false"` (not bool — values are flat strings in line format) |
| `new_sec_uid` | string | only with `reason=sec_uid_changed`; the unexpected new `secUid` |
| `room_id` | string | TikTok room id |
| `last_room_id` | string | the `room_id` recorded in state before the offline transition |
| `old_unique_id` | string | the previous `@handle` before rename |
| `stream_url` | string | full m3u8 URL; always last key |

### 5.4 Examples

```
ts=2026-05-25T18:12:11Z evt=daemon_start sec_uid=MS4wLjA... unique_id=luiisamour hours=12 poll_sec=300
ts=2026-05-25T18:17:11Z evt=poll_ok sec_uid=MS4wLjA... unique_id=luiisamour alive=false
ts=2026-05-25T18:22:13Z evt=poll_ok sec_uid=MS4wLjA... unique_id=luiisamour alive=true
ts=2026-05-25T18:22:13Z evt=go_live sec_uid=MS4wLjA... unique_id=luiisamour room_id=7643867662644251414 stream_url=https://pull-hls-f16-tt04.tiktokcdn-eu.com/.../index.m3u8?expire=1748800000&sign=...
ts=2026-05-25T19:14:00Z evt=rename_detected sec_uid=MS4wLjA... unique_id=lui_x old_unique_id=luiisamour
ts=2026-05-25T22:05:00Z evt=poll_ok sec_uid=MS4wLjA... unique_id=lui_x alive=false
ts=2026-05-25T22:05:00Z evt=go_offline sec_uid=MS4wLjA... unique_id=lui_x last_room_id=7643867662644251414
ts=2026-05-26T06:12:11Z evt=daemon_end sec_uid=MS4wLjA... unique_id=lui_x reason=timer_expired transitions=2
```

### 5.5 Parsing snippets

**Extract `evt=` (awk):**
```bash
awk '{ for(i=1;i<=NF;i++) if($i ~ /^evt=/){ sub("evt=","",$i); print $i; exit } }'
```

**Extract `stream_url=` from a `go_live` line (bash):**
```bash
URL="${line#*stream_url=}"
```

**Extract all keys into shell variables (bash):**
```bash
while IFS= read -r line; do
  # everything except stream_url
  head="${line%%stream_url=*}"
  # stream_url, if present
  case "$line" in *" stream_url="*) URL="${line#*stream_url=}";; *) URL="";; esac
  # walk head's space-separated tokens
  for tok in $head; do
    k="${tok%%=*}"; v="${tok#*=}"
    eval "FIELD_$k=\"\$v\""
  done
done < events.log
```

---

## 6. stdout schemas

### 6.1 `tt-live.sh check <user>` → `tt_live.py check`

```jsonc
{
  "sec_uid":         "string",
  "unique_id":       "string",
  "nickname":        "string|null",
  "user_id":         "string|null",
  "live":            "bool",
  "room_id":         "string|null",   // null when offline
  "title":           "string|null",   // null when offline
  "start_time":      "int|null",      // unix seconds; null when offline
  "rename_detected": "bool",
  "checked_at":      "iso"
}
```

Exit `0` = live, `1` = offline, `2` = error.

### 6.2 `tt-live.sh url <user>` → `tt_live.py url`

stdout: a single line containing the m3u8 URL. Not JSON.

With `--verbose|-v`, stderr also contains one line:
```
# source: cache|api|yt-dlp|streamlink
```

Exit `0` = ok, `1` = offline, `2` = error.

### 6.3 `tt-live.sh daemon <user>` (wrapper)

stdout: exactly 5 lines, key=value:
```
pid=<integer>
username=<as given>
workspace=<absolute path>
log=<absolute path to daemon log>
events_dir=<absolute path>
```

Events file: `${events_dir}/${sec_uid}.events`. Caller resolves
`${sec_uid}` by running `tt-live.sh check <user>` and reading
`sec_uid` from its JSON.

Exit `0` = spawned, `2` = spawn failed.

### 6.4 `get_room_id.py <user>`

```jsonc
{
  "unique_id":  "string|null",
  "nickname":   "string|null",
  "user_id":    "string|null",
  "sec_uid":    "string",          // never null (would cause exit 2)
  "room_id":    "string|null",     // null if missing or "0"
  "status":     "int|null",        // TikTok webcast state code
  "title":      "string|null",
  "start_time": "int|null",
  "live":       "bool",            // derived: status == 2
  "fetched_at": "iso"
}
```

Exit `0` = live, `1` = offline, `2` = error.

### 6.5 `check_alive.py <room_id>`

```jsonc
{
  "room_id":    "string",   // echoed input, stripped
  "alive":      "bool",
  "checked_at": "iso"
}
```

Exit `0` = alive, `1` = not alive, `2` = error.

---

## 7. Cross-reference invariants

These invariants hold across the four file types after any successful
operation:

1. **One identity per sec_uid.** Exactly one
   `identities/<sec_uid>.json` exists per known user.
2. **One state per sec_uid.** At most one `state/tt-live/<sec_uid>.state.json`
   exists; missing file means "never checked" and behaves as the
   `_default()` record.
3. **One events file per sec_uid.** At most one
   `state/tt-live/<sec_uid>.events` exists; created on first
   `EventWriter.write` call.
4. **Pointers fan in.** Multiple `pointers/<unique_id>.json` files
   can point at the same `sec_uid`, but exactly one has
   `current: true`.
5. **`identities/.unique_id_current` matches the current pointer.**
   `identities/<sec_uid>.json::unique_id_current` equals the
   `unique_id` of the pointer file with `current: true` for that
   `sec_uid`.
6. **State `current_room_id` ⇒ `is_live`.** If
   `state/<sec_uid>.state.json::current_room_id` is non-null, then
   `is_live: true`. (The reverse is not strictly enforced — there is a
   brief window during `cmd_check` updates where they could mismatch
   on a partial write, but the final write is atomic for `state` data.)
7. **`go_live` is always followed eventually by `go_offline` or
   `daemon_end`.** The daemon never re-emits `go_live` without an
   intervening `go_offline` — the `last_was_live` flag prevents that.
8. **`stream_url` only appears in `go_live` events.** No other event
   type carries it.
