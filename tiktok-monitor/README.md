# tt-live

TikTok LIVE monitor for OpenClaw. Resolves a TikTok user's live status,
m3u8 stream URL, or watches them over a timer window emitting structured
transition events for a sub-agent to announce.

The skill is a **pure data provider**. It does no chat output of its
own. Sub-agents reading the daemon's event file are responsible for all
human-facing announcements.

---

## Why this exists

TikTok's `/@<user>/live` page serves a `SIGI_STATE` JSON blob with the
user's identity and current `roomId`. The `webcast/room/info/` API
returns the m3u8 stream URLs for a known `roomId`. Combining the two
gives a reliable, browser-free way to:

1. Check if a TikTok user is live right now
2. Resolve a VLC-playable 360p m3u8 URL for an active stream
3. Watch a user over hours and detect `go_live` / `go_offline` /
   `rename_detected` transitions without keeping a browser open

The skill packages this for OpenClaw sub-agents to invoke through one
shell wrapper and three subcommands.

---

## Use cases

| Requester says | Sub-agent invokes |
|---|---|
| "Is @&lt;user&gt; live right now?" | `tt-live.sh check <user>` |
| "Give me the stream URL for @&lt;user&gt;" | `tt-live.sh url <user>` |
| "Watch @&lt;user&gt; for the next 12 hours and tell me when they go live" | `tt-live.sh daemon <user> --hours 12 --poll-min 5`, then tail the events file |
| "Did @&lt;user&gt; rename recently?" | `tt-live.sh check <user>`, read `rename_detected` field |
| "I have room_id X — is it still alive?" | `check_alive.py X` (standalone, no workspace touch) |
| "I have a username, just give me the IDs" | `get_room_id.py <user>` (standalone, no workspace touch) |

---

## File index

```
tt-live/
├── SKILL.md                OpenClaw skill manifest (frontmatter + agent instructions)
├── tt_live.py              Core Python module (check / url / daemon)
├── tt_live.md              Code reference for tt_live.py
├── tt-live.sh              Bash wrapper (dispatches to tt_live.py, nohup-spawns daemon)
├── tt-live.sh.md           Wrapper reference
├── tt-live.json            Canonical defaults reference (NOT loaded by tt_live.py)
├── tt-live.json.md         Config reference + change-workflow notes
├── get_room_id.py          Standalone SIGI scrape (username → identity JSON)
├── get_room_id.md          CLI reference for get_room_id.py
├── check_alive.py          Standalone webcast API ping (room_id → alive bool)
├── check_alive.md          CLI reference for check_alive.py
└── docs/
    ├── README.md           This file
    ├── ARCHITECTURE.md     Class diagram, data flow, event flow, design decisions
    ├── SCHEMA.md           JSON schemas for identity, pointer, state, events
    └── DAEMON.md           Daemon-mode internals: timer loop, polling, lifecycle
```

---

## Quick start

### One-off live check

```bash
$ tt-live.sh check <user>
{
  "sec_uid":         "MS4wLjA...",
  "unique_id":       "<user>",
  "nickname":        "Display Name",
  "user_id":         "131475542305824768",
  "live":            true,
  "room_id":         "7643867662644251414",
  "title":           "stream title",
  "start_time":      1748196000,
  "rename_detected": false,
  "checked_at":      "2026-05-25T18:22:13Z"
}
$ echo $?
0
```

Exit `0` = live, `1` = offline (JSON still printed), `2` = error.

### Resolve a stream URL

```bash
$ tt-live.sh url <user>
https://pull-hls-f16-tt04.tiktokcdn-eu.com/.../index.m3u8?expire=1748800000&sign=...
$ vlc "$(tt-live.sh url <user>)"
```

URL is cache-first (3-day retention). Cache miss falls back to direct
webcast API → yt-dlp → streamlink.

### Watch for transitions

```bash
$ tt-live.sh daemon <user> --hours 12 --poll-min 5
pid=12345
username=<user>
workspace=/home/openclaw/.openclaw/workspace/tiktok-monitor
log=/home/openclaw/.openclaw/workspace/tiktok-monitor/logs/daemon-<user>-20260525T182213Z.log
events_dir=/home/openclaw/.openclaw/workspace/tiktok-monitor/state/tt-live
```

Daemon runs in the background. Its events go to
`<events_dir>/<sec_uid>.events`. Resolve `<sec_uid>` from
`tt-live.sh check <user>` output, then `tail -F` the events file.

---

## Sub-agent workflow

The full long-running-watch workflow:

```bash
# 1) Resolve identity. JSON contains sec_uid, which is needed for the
#    events file path.
JSON="$(tt-live.sh check <user>)"
SEC_UID="$(echo "$JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["sec_uid"])')"

# 2) Spawn daemon. Capture events_dir from its key=value output.
DAEMON_OUT="$(tt-live.sh daemon <user> --hours 12 --poll-min 5)"
EVENTS_DIR="$(echo "$DAEMON_OUT" | awk -F= '/^events_dir=/{print $2}')"
EVENTS_FILE="$EVENTS_DIR/$SEC_UID.events"

# 3) Tail events file; act on each new line.
tail -F "$EVENTS_FILE" | while IFS= read -r line; do
  EVT="$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i ~ /^evt=/){sub("evt=","",$i); print $i}}')"
  case "$EVT" in
    go_live)
      # extract stream_url (last key, contains & and =)
      URL="${line#*stream_url=}"
      echo "ANNOUNCE: @<user> is now live: $URL"
      ;;
    go_offline)
      echo "ANNOUNCE: stream ended"
      ;;
    rename_detected)
      OLD="$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i ~ /^old_unique_id=/){sub("old_unique_id=","",$i); print $i}}')"
      NEW="$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i ~ /^unique_id=/){sub("unique_id=","",$i); print $i}}')"
      echo "ANNOUNCE: @handle changed: @$OLD → @$NEW"
      ;;
    daemon_end)
      echo "ANNOUNCE: watch window ended"
      break
      ;;
  esac
done
```

In a real OpenClaw sub-agent, the `echo "ANNOUNCE: ..."` lines are
replaced by calls into the sub-agent's chat-send mechanism (e.g.
`openclaw message send --channel <id>` or the equivalent via the
channel-runner runtime).

The skill itself does not announce. Sub-agent → requester channel is
the only path.

---

## Workspace location

Default: `~/.openclaw/workspace/tiktok-monitor/`

Override: set `TT_LIVE_WORKSPACE` to any absolute path. The directory
is created on first invocation.

Layout details, including the per-file JSON schemas, are in
[`SCHEMA.md`](SCHEMA.md).

---

## Hard constraints

| Constraint | Value | Why |
|---|---|---|
| Stream format cap | 360p (HLS m3u8) | Predictable bandwidth for sub-agent use cases |
| Poll interval floor | 5 minutes | TikTok rate-limits aggressive polling |
| URL cache retention | 3 days | Matches practical signature validity |
| HTTP request timeout | 15 seconds | Calibrated to TikTok's observed response latency |
| Notifications | none | The skill is a data provider; sub-agents announce |
| Cron mode | not supported | OpenClaw cron has ask=always; out of scope |

Changing these requires editing `tt_live.py` directly. See
[`../tt-live.json.md`](../tt-live.json.md) §4 for the recommended
change-via-script workflow.

---

## Deeper documentation

- [**ARCHITECTURE.md**](ARCHITECTURE.md) — class diagram, data flow,
  event flow, design decisions and trade-offs
- [**SCHEMA.md**](SCHEMA.md) — JSON schemas for identity records,
  pointers, state files, and event lines
- [**DAEMON.md**](DAEMON.md) — daemon-mode internals: timer loop,
  polling cadence, transition detection, lifecycle

For per-file API references see the `*.md` siblings of each source
file: [`../tt_live.md`](../tt_live.md),
[`../tt-live.sh.md`](../tt-live.sh.md),
[`../tt-live.json.md`](../tt-live.json.md),
[`../get_room_id.md`](../get_room_id.md),
[`../check_alive.md`](../check_alive.md).

---

## Requirements

- Python 3.9 or newer
- bash 4+
- Linux or macOS
- Optional: `yt-dlp` on PATH (fallback when direct API extraction fails)
- Optional: `streamlink` on PATH (second-tier fallback)

The primary stream-URL path is direct webcast API and requires neither
of the optional tools.
