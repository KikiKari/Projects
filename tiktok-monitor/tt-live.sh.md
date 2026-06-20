# `tt-live.sh` — Wrapper Reference

Source: `tt-live.sh`. Thin bash wrapper around `tt_live.py`.

The wrapper has three responsibilities:

1. Locate the Python core (`tt_live.py`) relative to itself.
2. Pass `check` and `url` through to Python in the foreground.
3. Spawn `daemon` in the background with `nohup`, then report its PID and
   log path.

Everything after the subcommand name is forwarded to `tt_live.py`
untouched. The wrapper does **not** parse Python-level flags such as
`--hours` or `--poll-min` — only `tt_live.py` does.

---

## 1. Invocation

```
tt-live.sh check  <username>
tt-live.sh url    <username> [--verbose|-v]
tt-live.sh daemon <username> [--hours N] [--poll-min M]
tt-live.sh help | --help | -h
```

The wrapper is intentionally locked to these four entry points. Anything
else (`tt-live.sh stop`, `tt-live.sh status`, `tt-live.sh bootstrap`)
returns exit 2 with `error: unknown subcommand: ...`.

---

## 2. Subcommand: `check`

```
tt-live.sh check <username>
```

Foreground passthrough to `python3 tt_live.py check <username>`. The
wrapper uses `exec` so the Python process replaces the shell — exit
code propagates directly.

**Exit codes** (from `tt_live.py`):

| Code | Meaning |
|---|---|
| 0 | User is live |
| 1 | User is offline (still writes JSON to stdout) |
| 2 | Error (HTTP, SIGI parse, identity update) |

**stdout**: JSON record. See `tt_live.md` §11 for the schema.

---

## 3. Subcommand: `url`

```
tt-live.sh url <username> [--verbose|-v]
```

Foreground passthrough to `python3 tt_live.py url <username> [-v]`.

**Exit codes:**

| Code | Meaning |
|---|---|
| 0 | URL printed to stdout |
| 1 | User is offline |
| 2 | All extraction strategies failed |

**stdout**: one line containing the m3u8 URL.
**stderr with `-v`**: `# source: <api|yt-dlp|streamlink|cache>`.

---

## 4. Subcommand: `daemon`

```
tt-live.sh daemon <username> [--hours N] [--poll-min M]
```

Spawns `python3 tt_live.py daemon ...` in the background using `nohup`,
then verifies it is still alive after a 1-second probe.

**What the wrapper does:**

1. Validates that `<username>` is present and well-formed (rejects names
   starting with `-`, containing `/` or `\`, or empty).
2. Creates the log directory: `$WORKSPACE/logs/`.
3. Generates a UTC timestamp: `YYYYMMDDTHHMMSSZ`.
4. Builds the log file path:
   `$WORKSPACE/logs/daemon-<username>-<timestamp>.log`.
5. Spawns `nohup python3 tt_live.py daemon $@ >>$LOG 2>&1 &`.
6. Captures `$!` as `DAEMON_PID`.
7. `sleep 1`, then `kill -0 $DAEMON_PID` to confirm it didn't crash.
8. Prints four key=value lines to stdout (see §4.2).

**Exit codes:**

| Code | Meaning |
|---|---|
| 0 | Daemon spawned and still running 1s later |
| 2 | Username invalid, or daemon exited within 1s (log path printed) |

### 4.1 What ends up in the wrapper log file

The log file at `$LOG_DIR/daemon-<user>-<ts>.log` captures the Python
daemon's **stderr and stdout**:

- `[tt-live] daemon started for @<user> (sec_uid=..., hours=N, poll=Mmin)`
- `[tt-live] daemon ended (timer_expired|interrupted, transitions=N)`
- Any Python tracebacks if the daemon crashes

This is **informal status output**, separate from the structured event
file. Sub-agents should not parse this file for events — they should
read the `.events` file instead (see §4.3).

### 4.2 stdout output on successful spawn

```
pid=<integer>
username=<as given>
workspace=<resolved $TT_LIVE_WORKSPACE or default>
log=<absolute path to daemon log>
events_dir=<absolute path to events directory>
```

The `events_dir` line gives the directory; the actual events file is
`$events_dir/<sec_uid>.events`. Sub-agents resolve `<sec_uid>` by
running `tt-live.sh check <user>` and reading `sec_uid` from the JSON.

### 4.3 The events file is separate

The wrapper does not write to the events file. Only `tt_live.py`
writes events, at `$workspace/state/tt-live/<sec_uid>.events`, in the
format documented in `tt_live.md` §10. Sub-agents tail that file to
detect transitions.

---

## 5. Subcommand: `help`

`tt-live.sh help`, `tt-live.sh --help`, `tt-live.sh -h`, and
`tt-live.sh` with no arguments all print the same usage message and
exit 0.

---

## 6. Path resolution

The wrapper resolves its own script directory to find `tt_live.py`:

```
resolve_script_dir():
  try readlink -f "$0"
  then realpath "$0"
  then fallback to dirname "$0"
```

This makes the wrapper work whether invoked as:

- `./tt-live.sh check user`
- `bash /full/path/tt-live.sh check user`
- via a symlink (e.g. `~/.local/bin/tt-live` → `~/.openclaw/workspace/tiktok-monitor/tt-live.sh`)

`tt_live.py` must live in the same directory as `tt-live.sh`. The
wrapper bails with exit 2 and `error: tt_live.py not found at: <path>`
if it's missing.

---

## 7. Environment

| Variable | Read by | Purpose |
|---|---|---|
| `TT_LIVE_WORKSPACE` | wrapper + `tt_live.py` | Workspace root. Default: `~/.openclaw/workspace/tiktok-monitor` |
| `HOME` | wrapper (via `$HOME` in default) | Standard user home |
| `PATH` | wrapper | Must contain `python3` |

The wrapper does not read any other environment variables.

---

## 8. Error handling

| Situation | Exit | stderr |
|---|---|---|
| `python3` not on PATH | 2 | `error: python3 not found on PATH` |
| `tt_live.py` not next to wrapper | 2 | `error: tt_live.py not found at: <path>` |
| Unknown subcommand | 2 | `error: unknown subcommand: <name>` + usage |
| `daemon` without username | 2 | `error: daemon requires a username argument` + usage |
| Invalid username (`-`, `/`, `\`, empty) | 2 | `error: invalid username argument: <value>` |
| Daemon exits within 1s | 2 | `error: daemon exited immediately. Check log: <path>` |

All other error paths come from `tt_live.py` and pass through unchanged.

---

## 9. Sub-agent usage pattern

The expected call sequence when a sub-agent is asked to monitor a user
over a long window:

```bash
# Step 1: resolve identity (gives sec_uid, plus a snapshot of current state)
JSON="$(tt-live.sh check luiisamour)"
SEC_UID="$(echo "$JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["sec_uid"])')"

# Step 2: spawn the daemon
DAEMON_OUT="$(tt-live.sh daemon luiisamour --hours 12 --poll-min 5)"
EVENTS_DIR="$(echo "$DAEMON_OUT" | awk -F= '/^events_dir=/{print $2}')"
EVENTS_FILE="$EVENTS_DIR/$SEC_UID.events"

# Step 3: tail the events file; each line is one transition or status event
tail -F "$EVENTS_FILE"
```

The sub-agent reads each new line from the events file and decides what
to announce back into its requester chat channel. The wrapper itself
does not announce anything.

For a one-off check ("is @luiisamour live right now"):

```bash
if tt-live.sh check luiisamour > /tmp/status.json; then
  # exit 0 → user is live; /tmp/status.json has room_id, title, etc.
  cat /tmp/status.json
else
  # exit 1 or 2 → offline or error
  ...
fi
```

For a one-off URL grab:

```bash
URL="$(tt-live.sh url luiisamour)" || { echo "not live or extract failed"; exit 1; }
vlc "$URL"
```

---

## 10. Concurrency notes

The wrapper does **not** maintain a PID file or prevent duplicate
daemons. If `tt-live.sh daemon luiisamour --hours 12` is called twice,
both daemons will run in parallel, both will write to the same
`<sec_uid>.events` file, and lines will interleave. Avoiding duplicates
is the caller's (sub-agent's) responsibility.

There is also no `stop` or `kill` subcommand. The sub-agent that started
the daemon has its PID from the `pid=` line and can `kill <pid>` directly.
The Python daemon catches `KeyboardInterrupt` (SIGINT) and writes a
`daemon_end reason=interrupted` event before exiting.

---

## 11. What is intentionally NOT in this file

Same audit principle as `tt_live.md` §17. The wrapper deliberately
omits:

- No `stop` / `kill` subcommand
- No `ps` / `list` / `status` subcommand
- No `bootstrap` / `configure` / `doctor` subcommand
- No PID file management
- No duplicate-daemon prevention
- No internal logging (debug/info/trace) — that is `tt_live.py`'s job
- No flag parsing of `--hours` / `--poll-min` — those go straight through
- No version string
