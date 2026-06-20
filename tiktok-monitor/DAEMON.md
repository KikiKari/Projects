# Daemon Mode

How `tt_live.py daemon` actually works: lifecycle, polling cadence,
transition detection, failure modes, and how to observe or stop a
running daemon.

For the high-level data flow see [ARCHITECTURE.md §5](ARCHITECTURE.md).
For the event line schema see [SCHEMA.md §5](SCHEMA.md).

---

## 1. What the daemon is

A single Python process that polls a single TikTok user over a fixed
time window and writes structured transition events to a per-user
append-only log file.

```
python3 tt_live.py daemon <user> [--hours N] [--poll-min M]
```

- **Default duration:** 12 hours
- **Default poll interval:** 5 minutes
- **Hard floor on poll interval:** 5 minutes (lower values clamped silently)
- **Hard floor on duration:** 1 hour (lower values clamped silently)

The daemon does not background itself. The `tt-live.sh` wrapper is
responsible for `nohup`-spawning it. See §9.

---

## 2. Lifecycle

```
[1] arg parse + workspace setup
      │
      ▼
[2] anchor identity (one scrape)
      │ failure here → exit 2 (no daemon_end event)
      ▼
[3] EventWriter.write(daemon_start)
      │
      ▼
[4] poll loop (until deadline or SIGINT)
      │
      ▼
[5] EventWriter.write(daemon_end)
      │
      ▼
exit 0
```

Phases [2] through [5] are all under `cmd_daemon(args)` in `tt_live.py`.

The **only** path that bypasses phase [5] is an uncaught crash (Python
traceback). All clean exits — timer reaching the deadline, SIGINT/Ctrl-C
— produce a `daemon_end` line first.

---

## 3. Anchoring (phase 2)

The first action after argument parsing is to fetch
`/@<username>/live` once and resolve the user's `sec_uid`. This is the
**anchor sec_uid** for the rest of the run.

```python
first = fetch_user_live_page(username)
if not first or not first.get("sec_uid"):
    return 2     # cannot anchor → exit 2, no daemon_start, no daemon_end
sec_uid, _ = ids.update_from_scrape(first)
```

If anchoring fails (HTTP error, SIGI_STATE missing, no `secUid` in
SIGI), the daemon exits 2 immediately. The wrapper's 1-second liveness
probe detects this and prints `error: daemon exited immediately.` with
the log path.

After anchoring, the daemon has:
- `sec_uid` — the anchor; never reassigned for the rest of the run
- `unique_id` — the current `@handle`; reassigned only on
  `rename_detected`
- `events: EventWriter` — bound to `<workspace>/state/tt-live/<sec_uid>.events`
- `last_was_live` — seeded from the existing state store
  (`state_store.read(sec_uid).is_live`), so a daemon restart against a
  user who was already live won't emit a spurious `go_live`

`daemon_start` is emitted right after anchoring succeeds.

---

## 4. The poll loop (phase 4)

Each iteration:

```
[4.1] scrape /@username/live
[4.2] update identity store; check for rename or sec_uid change
[4.3] emit poll_ok (or poll_err if step 4.1 failed)
[4.4] detect and handle transitions
[4.5] sleep
```

### 4.1 Scrape

`fetch_user_live_page(username)` does one HTTP GET to TikTok and parses
SIGI_STATE. On any failure it returns `None`. There is no retry inside
the loop; one failure produces one `poll_err`.

### 4.2 Identity update

`ids.update_from_scrape(scrape)` returns `(new_sec_uid, rename_detected)`.

Three branches:

| Result | Action |
|---|---|
| `new_sec_uid is None` | shouldn't happen post-anchor (scrape was non-None); fall through |
| `new_sec_uid != anchor sec_uid` | emit `poll_err reason=sec_uid_changed new_sec_uid=<X>`; sleep; continue. The anchor `sec_uid` is **not** reassigned. The daemon stays bound to its original target. |
| `rename_detected == True` | emit `rename_detected`, reassign `unique_id = scrape["unique_id"]` |

The `sec_uid_changed` branch is rare — it would mean TikTok unbound the
`@handle` from one user and bound it to a different `secUid`. The
daemon does not chase that; it keeps watching its anchored user (whose
current `@handle` may now be different from the requested `<username>`,
which would surface on the next scrape via SIGI returning a different
`secUid` again — at which point we keep emitting `poll_err`).

In practice this branch protects against `<username>` typos that
accidentally resolve to a real account, followed by that account
disappearing.

### 4.3 poll_ok / poll_err

Every poll emits exactly one of:
- `poll_ok alive=true|false` — successful scrape
- `poll_err reason=<...>` — scrape failed, or `sec_uid_changed`

Sub-agents tailing the events file can use `poll_ok` lines as a
heartbeat. **Do not announce poll_ok lines to the requester** — they
fire every poll interval (5 min default) for the entire watch window.

`poll_err` lines may be useful to surface only if they occur many in a
row (e.g. "TikTok has been unreachable for 30 minutes"). One-off
poll_err lines are normal — TikTok sometimes returns 5xx for a single
request.

### 4.4 Transition detection

The transition logic uses one local variable: `last_was_live` (bool).
Seeded from state store at startup; updated on every transition.

```
if live and not last_was_live:    # offline → live
    extract stream URL
    update state (is_live=true, current_room_id=room_id)
    emit go_live (stream_url last)
    transitions += 1
    last_was_live = True

elif not live and last_was_live:  # live → offline
    update state (is_live=false, current_room_id=null)
    emit go_offline last_room_id=<...>
    transitions += 1
    last_was_live = False

else:                              # no transition
    strip_stale_urls only
```

**One `go_live` per actual live session.** The `last_was_live` flag
prevents re-emission while the user remains live.

**Stream URL extraction at `go_live` time** uses the same orchestrator
as `cmd_url`: direct API → yt-dlp → streamlink. If all three fail, the
`go_live` event is **still emitted**, but without a `stream_url=`
field. Sub-agents that need a URL can call `tt-live.sh url <user>` on
the side; the URL cache will be populated on the next successful
extraction.

### 4.5 Sleep

```python
def _sleep_until(deadline, max_sleep):
    remaining = deadline - time.time()
    if remaining <= 0:
        return
    time.sleep(min(max_sleep, max(1.0, remaining)))
```

The sleep is **clamped to the remaining time before deadline**. This
keeps the daemon from overshooting by up to `poll_sec` at the end of
the window. The `max(1.0, remaining)` floor ensures we sleep at least
one second when very close to deadline.

---

## 5. Timing math

| Parameter | Source | Notes |
|---|---|---|
| `hours` | `--hours` arg | clamped to `max(1, int(args.hours))` |
| `poll_min` | `--poll-min` arg | clamped to `max(5, int(args.poll_min))` |
| `poll_sec` | derived | `poll_min * 60` |
| `deadline` | derived | `time.time() + hours * 3600` (captured once, at loop entry) |

The deadline is captured **once** before the loop. The daemon does not
adjust for slow polls — if `fetch_user_live_page` takes 8 seconds, the
next sleep is `poll_sec` from when the sleep call starts, not from when
the previous sleep ended. Total run time is at most
`hours * 3600 + poll_sec` (one extra sleep if we just barely missed
deadline check).

**Example: `--hours 12 --poll-min 5`:**
- `poll_sec = 300`
- `deadline ≈ now + 43200`
- Expected poll count: ~144 (`43200 / 300`)
- Expected event count (worst case): 1 (start) + 144 (poll_ok or
  poll_err) + 1 (daemon_end) + transitions + renames ≈ 150 events

---

## 6. Failure modes

| What goes wrong | What the daemon does |
|---|---|
| Anchor scrape fails (phase 2) | exit 2 immediately; no `daemon_start`, no `daemon_end` |
| Single poll scrape fails | emit `poll_err reason=fetch_failed`; sleep; continue |
| sec_uid changes mid-run | emit `poll_err reason=sec_uid_changed new_sec_uid=<X>`; stay bound to anchor; sleep; continue |
| Stream URL extraction fails on `go_live` | emit `go_live` **without** `stream_url=`; mark live in state; next `url` call will retry extraction |
| State file becomes unreadable | `StateStore.read` returns `_default()`; the run proceeds as if state was fresh (loses cached URLs and `last_was_live` memory) |
| Identity file becomes unreadable | `IdentityStore.load_identity` returns `None`; treated as a fresh user (no rename detection until next save) |
| SIGINT / Ctrl-C | caught by `except KeyboardInterrupt`; `end_reason = "interrupted"`; emits `daemon_end`; exits 0 |
| SIGTERM | not explicitly caught; default Python behavior is exit with no `daemon_end` emitted. To stop a daemon cleanly, send SIGINT. |
| Python traceback | propagates out of `cmd_daemon`; no `daemon_end` emitted; traceback goes to the wrapper's log file |

---

## 7. Exit conditions and reasons

The `daemon_end` event's `reason` field has two values:

| `reason=` | When |
|---|---|
| `timer_expired` | The loop exits because `time.time() >= deadline` |
| `interrupted` | The loop catches `KeyboardInterrupt` (SIGINT) |

There is no `reason=crash` because crashes bypass the `daemon_end`
emission entirely. There is no `reason=stopped` for SIGTERM for the
same reason — see §6.

---

## 8. State writes vs event writes — what touches disk per poll

In the **no-transition** case (most polls), the daemon touches disk:

- 1 read: `state/tt-live/<sec_uid>.state.json` (inside `strip_stale_urls`)
- 1 write: same file, only if `strip_stale_urls` actually removed
  something (usually no)
- 1 read: `identities/<sec_uid>.json` (inside `update_from_scrape`)
- 1 write: same file (last_seen update)
- 1 read: `pointers/<unique_id>.json`
- 1 write: same file (last_pointed_at update)
- 1 append: `<sec_uid>.events` (the `poll_ok` line)

In the **transition** case, add:

- 1 read+write: state file (is_live, current_room_id, last_check_ts updates)
- 1 read+write: state file (add_url on go_live)
- 1 append: `<sec_uid>.events` (the `go_live` or `go_offline` line)
- 1 HTTP call: `fetch_room_info` for stream URL extraction (only on go_live)
- 0-1 subprocess: yt-dlp or streamlink if API extraction failed

Total per poll cycle (no transition): ~6-7 file ops + 1 HTTP request.
This is well below any I/O concern on a normal filesystem and well
below TikTok's rate limit threshold.

---

## 9. The wrapper's role

`tt-live.sh daemon ...` is what actually puts the Python process in
the background:

```bash
nohup python3 "$PY_CORE" daemon "$@" >>"$LOG_FILE" 2>&1 &
DAEMON_PID=$!
sleep 1
kill -0 "$DAEMON_PID" || { error; exit 2 }
```

The wrapper:
1. Creates `$WORKSPACE/logs/`.
2. Builds a per-invocation log path: `daemon-<user>-<UTC-ts>.log`.
3. Spawns the daemon with `nohup` so it survives shell exit.
4. Redirects stdout+stderr of the daemon to the log file.
5. Probes with `kill -0` after 1 second to verify the daemon is alive.
6. Prints `pid=`, `username=`, `workspace=`, `log=`, `events_dir=` to
   stdout and returns.

The wrapper does **not** write any structured events. Only the Python
daemon writes to the `.events` file. The wrapper's log file is for
unstructured stderr (Python tracebacks, the daemon's own
`[tt-live] daemon started/ended` info lines).

---

## 10. Observing a running daemon

### 10.1 Is it still running?

```bash
ps -p <pid>
# or
kill -0 <pid> && echo "alive"
```

`<pid>` came from the wrapper's `pid=` line.

### 10.2 What is it doing right now?

```bash
tail -F "$LOG_FILE"
```

The wrapper's log file (the `log=` line) contains:
- `[tt-live] daemon started for @<user> (sec_uid=..., hours=N, poll=Mmin)`
- `[tt-live] daemon ended (timer_expired|interrupted, transitions=N)`
- Any Python tracebacks if it crashed

### 10.3 What transitions has it seen?

```bash
tail -F "$EVENTS_DIR/$SEC_UID.events"
```

Resolve `$SEC_UID` via `tt-live.sh check <user> | jq -r .sec_uid`.

### 10.4 Quick health summary

```bash
# Last 5 events of any type
tail -n 5 "$EVENTS_DIR/$SEC_UID.events"

# Most recent poll_ok / poll_err
grep -E ' evt=(poll_ok|poll_err) ' "$EVENTS_DIR/$SEC_UID.events" | tail -1

# All go_live / go_offline transitions
grep -E ' evt=(go_live|go_offline) ' "$EVENTS_DIR/$SEC_UID.events"
```

---

## 11. Stopping a daemon

Use SIGINT (`kill -INT <pid>` or Ctrl-C if running in foreground).

```bash
kill -INT <pid>
```

The Python daemon catches SIGINT as `KeyboardInterrupt`, writes
`daemon_end reason=interrupted` to the events file, and exits 0.

**Do not use SIGTERM (`kill <pid>`).** SIGTERM is not caught, so no
`daemon_end` line is written. Sub-agents tailing the events file will
not learn that the daemon stopped except by noticing that `poll_ok`
lines have stopped arriving.

**Do not use SIGKILL (`kill -9 <pid>`).** Same problem as SIGTERM, plus
no chance for the daemon to flush pending file writes.

---

## 12. Restart behavior

Restarting a daemon for a user the system has seen before is safe:

- `IdentityStore` is read; existing identity is preserved.
- `StateStore.read(sec_uid).is_live` seeds `last_was_live`, so
  if the user is currently live (from a previous daemon's perspective
  or a manual `check`), the new daemon will **not** emit a spurious
  `go_live` on its first transition check.
- The events file is **appended to**, not overwritten. A user's events
  log accumulates across daemon runs over time.

This means:

```bash
# Daemon 1: 6-hour watch, user goes live at hour 3
tt-live.sh daemon luiisamour --hours 6
# events: daemon_start, poll_ok×, go_live, poll_ok×, daemon_end (transitions=1)

# Daemon 2: started right after Daemon 1 ended; user still live
tt-live.sh daemon luiisamour --hours 6
# events appended: daemon_start, poll_ok×, ..., daemon_end (no spurious go_live)
```

To clear an events file, delete it manually. It will be recreated on
the next event emission.

---

## 13. Limitations

| Limitation | Workaround |
|---|---|
| Single user per daemon | Spawn one daemon per user; each gets its own events file |
| 5-minute resolution | TikTok rate limits prevent faster polling; no workaround |
| No stream-content capture | Use the URL with VLC, ffmpeg, or yt-dlp externally |
| No SIGTERM handling | Use SIGINT to stop cleanly |
| Events file grows unbounded | Periodic external rotation (e.g. logrotate) is the caller's responsibility |
| Stream URL may expire before daemon ends | Caller can re-run `tt-live.sh url <user>` to refresh the cache mid-watch |
