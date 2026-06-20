#!/usr/bin/env bash
# tt-live.sh — TikTok LIVE monitor wrapper
#
# Dispatches subcommands to tt_live.py. The daemon subcommand is spawned in
# the background with nohup so it survives shell exit; check and url run in
# the foreground and pass through their exit codes.
#
# This wrapper is intentionally minimal. It does not parse subcommand flags;
# everything after the subcommand name is forwarded to tt_live.py untouched.

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

# Resolve script directory robustly: try readlink -f, then realpath, then
# fall back to the literal $0. This makes the wrapper work whether it is
# invoked directly, via a relative path, or through a symlink.
resolve_script_dir() {
  local target="$0"
  if command -v readlink >/dev/null 2>&1 && readlink -f "$target" >/dev/null 2>&1; then
    target="$(readlink -f "$target")"
  elif command -v realpath >/dev/null 2>&1; then
    target="$(realpath "$target" 2>/dev/null || printf '%s' "$target")"
  fi
  cd "$(dirname "$target")" && pwd
}

SCRIPT_DIR="$(resolve_script_dir)"
PY_CORE="$SCRIPT_DIR/tt_live.py"

# Workspace root: env override or default. Mirrors tt_live.py's logic so the
# wrapper-managed log directory ends up under the same workspace.
WORKSPACE="${TT_LIVE_WORKSPACE:-$HOME/.openclaw/workspace/tiktok-monitor}"
LOG_DIR="$WORKSPACE/logs"
EVENTS_DIR="$WORKSPACE/state/tt-live"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() { printf '%s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Usage:
  tt-live.sh check  <username>
  tt-live.sh url    <username> [--verbose|-v]
  tt-live.sh daemon <username> [--hours N] [--poll-min M]
  tt-live.sh help | --help | -h

Subcommands:
  check    One-shot live status check; JSON to stdout.
           Exit 0 = live, 1 = offline, 2 = error.

  url      Resolve current m3u8 stream URL.
           Exit 0 = ok, 1 = offline, 2 = error.

  daemon   Spawn a background daemon that polls the user for --hours hours
           (default 12) at --poll-min minute intervals (floor 5).
           Prints pid, log path, workspace, and events dir to stdout.
           Exit 0 = spawned, 2 = spawn failed.

Environment:
  TT_LIVE_WORKSPACE   Workspace root.
                      Default: ~/.openclaw/workspace/tiktok-monitor
EOF
}

require_python() {
  if ! command -v python3 >/dev/null 2>&1; then
    err "error: python3 not found on PATH"
    exit 2
  fi
}

require_core() {
  if [ ! -f "$PY_CORE" ]; then
    err "error: tt_live.py not found at: $PY_CORE"
    exit 2
  fi
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

case "${1:-}" in

  check)
    require_python
    require_core
    shift
    exec python3 "$PY_CORE" check "$@"
    ;;

  url)
    require_python
    require_core
    shift
    exec python3 "$PY_CORE" url "$@"
    ;;

  daemon)
    require_python
    require_core
    shift

    if [ $# -lt 1 ]; then
      err "error: daemon requires a username argument"
      err ""
      usage
      exit 2
    fi

    # Capture username for the log filename only; do NOT consume it from $@
    # because tt_live.py daemon still expects it as the first positional.
    USERNAME="$1"

    # Reject obviously malformed usernames so the log filename stays sane.
    # tt_live.py applies its own validation through TikTok's response.
    case "$USERNAME" in
      -*|*/*|*\\*|"")
        err "error: invalid username argument: $USERNAME"
        exit 2
        ;;
    esac

    mkdir -p "$LOG_DIR"

    TS="$(date -u +'%Y%m%dT%H%M%SZ')"
    LOG_FILE="$LOG_DIR/daemon-${USERNAME}-${TS}.log"

    # nohup + & for survive-after-shell-exit. Both stdout and stderr go to
    # the same log file. tt_live.py's structured events go to a separate
    # file: $EVENTS_DIR/<sec_uid>.events (sec_uid is resolved on first
    # scrape; the sub-agent looks it up via `tt-live.sh check`).
    nohup python3 "$PY_CORE" daemon "$@" \
      >>"$LOG_FILE" 2>&1 &
    DAEMON_PID=$!

    # Brief liveness probe: if the daemon failed to start (missing module,
    # syntax error, immediate fetch failure with exit 2) it'll be gone in
    # about a second. Wait briefly, then verify the process still exists.
    sleep 1
    if ! kill -0 "$DAEMON_PID" 2>/dev/null; then
      err "error: daemon exited immediately. Check log:"
      err "  $LOG_FILE"
      exit 2
    fi

    # Report what the sub-agent / caller needs to find the daemon and its
    # outputs. The events file is named <sec_uid>.events inside EVENTS_DIR;
    # the sub-agent should run `tt-live.sh check <user>` to learn sec_uid.
    printf 'pid=%s\n'        "$DAEMON_PID"
    printf 'username=%s\n'   "$USERNAME"
    printf 'workspace=%s\n'  "$WORKSPACE"
    printf 'log=%s\n'        "$LOG_FILE"
    printf 'events_dir=%s\n' "$EVENTS_DIR"
    exit 0
    ;;

  help|-h|--help|"")
    usage
    exit 0
    ;;

  *)
    err "error: unknown subcommand: $1"
    err ""
    usage
    exit 2
    ;;

esac
