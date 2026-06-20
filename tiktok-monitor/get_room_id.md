# `get_room_id.py` — CLI Reference

Source: `get_room_id.py`. Self-contained standalone tool.

A one-shot lookup that fetches the TikTok `/@<user>/live` page, extracts
the embedded `SIGI_STATE` JSON, and prints the user's identity plus
current room metadata as a flat JSON object on stdout.

This is the Python port of the confirmed-working browser-console
snippet. The field selection matches that snippet exactly, with two
derived additions (`live`, `fetched_at`).

---

## 1. Invocation

```
get_room_id.py <username>
```

A single positional argument. Examples:

```
get_room_id.py luiisamour
get_room_id.py @luiisamour      # leading @ is stripped
```

No flags. No subcommands. No environment variables.

---

## 2. stdout output

One JSON object, pretty-printed with `indent=2`. Field order is
deterministic:

```json
{
  "unique_id":  "luiisamour",
  "nickname":   "Display Name",
  "user_id":    "131475542305824768",
  "sec_uid":    "MS4wLjABAAAAPRgsgl2-tpIN4uBswC_8gqHYzknKIt_2MQ-6_TW_ajIcfz2xy8zIMEMV1W4t4iM_",
  "room_id":    "7643867662644251414",
  "status":     2,
  "title":      "stream title here",
  "start_time": 1748196000,
  "live":       true,
  "fetched_at": "2026-05-25T18:22:13Z"
}
```

### 2.1 Field reference

| Field | Type | Source in SIGI_STATE | Notes |
|---|---|---|---|
| `unique_id`  | string | `LiveRoom.liveRoomUserInfo.user.uniqueId` | The `@handle`. Can change if user renames. |
| `nickname`   | string | `LiveRoom.liveRoomUserInfo.user.nickname` | Display name. |
| `user_id`    | string | `LiveRoom.liveRoomUserInfo.user.id` | Numeric user id as string. |
| `sec_uid`    | string | `LiveRoom.liveRoomUserInfo.user.secUid` | Stable primary key. Required for exit < 2. |
| `room_id`    | string \| null | `LiveRoom.liveRoomUserInfo.user.roomId` | `null` if missing or `"0"`. |
| `status`     | int \| null | `LiveRoom.liveRoomUserInfo.liveRoom.status` | TikTok webcast state code. `2` = live. |
| `title`      | string \| null | `LiveRoom.liveRoomUserInfo.liveRoom.title` | Stream title. `null` when offline. |
| `start_time` | int \| null | `LiveRoom.liveRoomUserInfo.liveRoom.startTime` | Unix seconds. `null` when offline. |
| `live`       | bool | derived | `True` iff `status == 2`. |
| `fetched_at` | string | derived | UTC ISO 8601 with trailing Z, second precision. |

Fields tied to room state (`room_id`, `status`, `title`, `start_time`)
may be `null` when the user is offline; the script does not omit them,
it returns them as JSON `null` for schema stability.

---

## 3. Exit codes

| Code | Meaning | stdout | stderr |
|---|---|---|---|
| 0 | User is currently live (`status == 2`) | JSON record | empty |
| 1 | User is offline | JSON record (with `live: false`) | empty |
| 2 | Error: usage, validation, HTTP, or parse failure | empty | one error line |

Exit 0 vs 1 is the primary signal for shell callers; the JSON record is
always produced unless exit is 2.

---

## 4. Error conditions (exit 2)

| stderr message | Cause |
|---|---|
| `usage: get_room_id.py <username>` | Zero or more than one positional argument |
| `error: invalid username argument: <value>` | Username is empty after `@`-strip, contains `/`, or contains `\` |
| `error: failed to fetch <url> (status=<N>)` | HTTP non-200, or network error (status `0`) |
| `error: SIGI_STATE not found or unparseable for @<user>` | Marker missing from HTML, or JSON decode failed |
| `error: SIGI_STATE missing user.secUid for @<user>` | SIGI_STATE parsed but no `user.secUid` field |

The script writes exactly one error line and exits 2. No partial JSON
output on error.

---

## 5. Behavior notes

- **One HTTP request** per invocation: `GET https://www.tiktok.com/@<user>/live`.
  No webcast-API calls, no fallback strategies. If the SIGI page does
  not yield a `secUid`, the script returns exit 2 without retrying.
- **stdlib only.** No `requests`, no `httpx`, no `yt-dlp`, no
  `streamlink`. Runs on any Python 3.9+ install without `pip install`.
- **Stateless.** No filesystem access. No reads or writes of the
  workspace, identity store, or state store. This is the read-only
  counterpart to `tt_live.py check`, intended for situations where the
  caller wants raw SIGI data without touching disk.
- **No retry.** Transient network failures result in exit 2; the
  caller decides whether to re-run.

---

## 6. Relationship to `tt_live.py`

`get_room_id.py` duplicates three things from `tt_live.py`:

| Element | Status |
|---|---|
| `REQUEST_TIMEOUT_SEC = 15` | Mirrored constant |
| `USER_AGENT = "Mozilla/5.0 ..."` | Mirrored constant |
| `parse_sigi_state()` / `http_get()` | Mirrored logic, identical implementation |

This duplication is **intentional**. `get_room_id.py` is a standalone
tool that can be copied to any machine with Python 3.9+ and run on
its own. It does not import `tt_live.py`.

If the mirrored constants change in `tt_live.py`, they must be updated
here too. There is no shared module to update both at once — that is
the explicit trade-off for "standalone."

The output schema is **not** the same as `tt_live.py check`. The latter
adds workspace side-effects (identity write, state update,
`rename_detected` field) and uses a slightly different field set.
`get_room_id.py` produces only what the browser snippet produced, plus
`live` and `fetched_at`.

---

## 7. Usage examples

### 7.1 Shell, plain check

```bash
if get_room_id.py luiisamour > /tmp/rec.json; then
  echo "live: $(jq -r .room_id /tmp/rec.json)"
else
  echo "offline"
fi
```

### 7.2 Extract a single field

```bash
SEC_UID="$(get_room_id.py luiisamour | jq -r '.sec_uid')"
```

### 7.3 Pipe to the daemon-events file path

```bash
SEC_UID="$(get_room_id.py luiisamour | jq -r '.sec_uid')"
EVENTS_FILE="$HOME/.openclaw/workspace/tiktok-monitor/state/tt-live/$SEC_UID.events"
[ -f "$EVENTS_FILE" ] && tail -F "$EVENTS_FILE"
```

### 7.4 Use as a probe before starting a daemon

```bash
get_room_id.py luiisamour > /dev/null && echo "live -> spawn daemon now"
```

(Exit 0 = live; chain with `&&` to act only when live.)

---

## 8. What is intentionally NOT in this file

For audit purposes:

- No flags (`--verbose`, `--json`, `--raw`, etc.) — output format is
  fixed
- No webcast API calls — this is a SIGI-only tool. For check_alive
  semantics, see `check_alive.py`.
- No identity-store / state-store writes — fully stateless
- No retry logic — single attempt
- No daemon mode
- No `__UNIVERSAL_DATA_FOR_REHYDRATION__` fallback — SIGI_STATE only
- No import of `tt_live.py` — intentional duplication of helpers
- No environment-variable knobs
