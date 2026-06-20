# `check_alive.py` — CLI Reference

Source: `check_alive.py`. Self-contained standalone tool.

A one-shot liveness check against TikTok's `webcast/room/check_alive`
endpoint. Takes a numeric `room_id`, returns whether that room is
currently alive.

This is the Python port of the confirmed-working browser-console
check_alive snippet. The response shape is intentionally minimal:
`room_id`, `alive`, `checked_at`.

---

## 1. Invocation

```
check_alive.py <room_id>
```

A single positional argument: the numeric TikTok room id. Examples:

```
check_alive.py 7643867662644251414
```

No flags. No subcommands. No environment variables.

---

## 2. stdout output

One JSON object, pretty-printed with `indent=2`. Field order is
deterministic:

```json
{
  "room_id":    "7643867662644251414",
  "alive":      true,
  "checked_at": "2026-05-25T18:22:13Z"
}
```

### 2.1 Field reference

| Field | Type | Source | Notes |
|---|---|---|---|
| `room_id`    | string | argv[1], stripped | Echoed back as-is for caller convenience |
| `alive`      | bool | `response.data[0].alive` | `True` if the API confirms the room is live |
| `checked_at` | string | derived | UTC ISO 8601 with trailing Z, second precision |

Output schema is **fixed**: three fields, always present, never `null`.

---

## 3. Exit codes

| Code | Meaning | stdout | stderr |
|---|---|---|---|
| 0 | Room is alive | JSON record | empty |
| 1 | Room is NOT alive (offline / ended / never existed) | JSON record (with `alive: false`) | empty |
| 2 | Error: usage, validation, HTTP, or parse failure | empty | one error line |

Exit 0 vs 1 is the primary signal for shell callers. Exit 2 is reserved
for cases where the answer is "I don't know" — never confused with "I
checked and it's offline."

---

## 4. Error conditions (exit 2)

| stderr message | Cause |
|---|---|
| `usage: check_alive.py <room_id>` | Zero or more than one positional argument |
| `error: invalid room_id (must be numeric): <value>` | room_id is empty, contains non-digit characters, or has a leading sign |
| `error: failed to check room_id <id> (HTTP, parse, or empty response)` | HTTP non-200, network error, JSON decode failure, or empty `data` array |

Validation uses `str.isdigit()`, which means:
- Accepts: `"7643867662644251414"`, `"0"`, `"123"`
- Rejects: `""`, `"abc"`, `"@123"`, `"-1"`, `"+1"`, `" 123 "` after strip
  still works, but `"12.0"` rejected

The script writes exactly one error line and exits 2. No partial JSON
on error.

---

## 5. Behavior notes

- **One HTTP request** per invocation:
  `GET https://webcast.tiktok.com/webcast/room/check_alive/?aid=1988&room_ids=<id>`.
  No SIGI scrape, no second request, no fallback strategies.
- **stdlib only.** No `requests`, no `httpx`. Runs on any Python 3.9+
  install without `pip install`.
- **Stateless.** No filesystem access. No reads or writes of the
  workspace, identity store, or state store.
- **No retry.** Transient network failures result in exit 2; the caller
  decides whether to re-run.
- **Single room_id only.** The endpoint supports
  `room_ids=ID1,ID2,ID3` for batch queries, but `check_alive.py`
  exposes only the single-ID case. Callers that need batch behavior
  should make multiple invocations or write their own thin batch
  wrapper.

---

## 6. Relationship to `get_room_id.py` and `tt_live.py`

### 6.1 When to use which

| Tool | When |
|---|---|
| `get_room_id.py <username>` | You have only a username and need to discover the current room_id (and the rest of the identity record) |
| `check_alive.py <room_id>` | You already know the room_id and just want a cheap "is it still live?" check |
| `tt_live.py check <user>` | You want the workspace identity/state side-effects too (recommended in OpenClaw sub-agent flows) |
| `tt_live.py daemon <user>` | You want a watching session with transition events |

`get_room_id.py` and `check_alive.py` are **read-only probes**.
`tt_live.py` is the stateful core.

### 6.2 Duplicated constants

`check_alive.py` duplicates these from `tt_live.py`:

| Element | Status |
|---|---|
| `REQUEST_TIMEOUT_SEC = 15` | Mirrored constant |
| `TT_AID = "1988"` | Mirrored constant |
| `USER_AGENT = "Mozilla/5.0 ..."` | Mirrored constant |
| `http_get()` | Mirrored function |
| Inner logic of `check_alive()` | Same as `tt_live.fetch_check_alive()` |

Duplication is **intentional**. If `tt_live.py`'s values change, they
must be updated here too. The trade-off is "standalone."

---

## 7. Usage examples

### 7.1 Probe an already-known room

```bash
if check_alive.py 7643867662644251414 > /dev/null; then
  echo "still live"
else
  echo "ended or error"
fi
```

### 7.2 Chain with `get_room_id.py`

```bash
ROOM_ID="$(get_room_id.py luiisamour | jq -r '.room_id // empty')"
if [ -n "$ROOM_ID" ] && check_alive.py "$ROOM_ID" > /dev/null; then
  echo "live, room_id=$ROOM_ID"
fi
```

### 7.3 Use as a cheap heartbeat between full scrapes

A caller that has already resolved room_id via `tt_live.py check` or
`get_room_id.py` can ping `check_alive.py` repeatedly to confirm the
stream is still going, without re-fetching the SIGI HTML page each
time. This is cheaper but less informative (no rename detection, no
title changes).

```bash
ROOM_ID="7643867662644251414"
while check_alive.py "$ROOM_ID" > /dev/null; do
  sleep 60
done
echo "stream ended at $(date -u +%FT%TZ)"
```

Note: the OpenClaw daemon mode in `tt_live.py daemon` does NOT use this
pattern — it uses the full SIGI scrape on every poll because it also
needs identity/rename detection.

---

## 8. What is intentionally NOT in this file

For audit purposes:

- No batch mode — single room_id per invocation
- No flags (`--verbose`, `--json`, `--raw`, etc.)
- No retry logic
- No identity-store / state-store writes
- No SIGI scrape fallback if the API fails
- No username-based mode (use `get_room_id.py` for that, then chain)
- No import of `tt_live.py` — intentional duplication of helpers
- No environment-variable knobs
- No support for the `data[1..N]` items the endpoint can return if
  batch IDs are passed — we always look at `data[0]` only
