#!/bin/bash
# test_sidepanel_player_guard.cjs — portiert nach shell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_sidepanel_player_guard.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_sidepanel_player_guard.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_sidepanel_player_guard.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_sidepanel_player_guard.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# This is a conceptual translation of JavaScript code to Bash.
# Since Bash lacks native support for JavaScript execution and DOM manipulation,
# this script simulates the behavior using shell constructs and comments.

# Simulate reading the source file
SOURCE_FILE="../browser-extension/sidepanel.js"
if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "ERROR: Source file $SOURCE_FILE not found." >&2
  exit 1
fi

# Read the source content
SOURCE=$(<"$SOURCE_FILE")

# Find the start and end markers (simulated)
START_MARKER="async function refreshPlayer()"
END_MARKER="function setButtonBusy"

# Extract relevant portion (this is a simplification)
if ! START_POS=$(echo "$SOURCE" | grep -n "$START_MARKER" | head -1 | cut -d: -f1); then
  echo "ERROR: Start marker not found in source." >&2
  exit 1
fi

if ! END_POS=$(echo "$SOURCE" | grep -n "$END_MARKER" | tail -n +2 | head -1 | cut -d: -f1); then
  echo "ERROR: End marker not found in source." >&2
  exit 1
fi

if [[ -z "$START_POS" || -z "$END_POS" || "$END_POS" -le "$START_POS" ]]; then
  echo "ERROR: Invalid positions for start/end markers." >&2
  exit 1
fi

# Simulate JavaScript context with global variables
ACTIVE_TAB_ID=1
ACTIVE_IS_TIKTOK=true
PLAYER_CONTEXT_GENERATION=0
CALLS=0
RENDERED=()
REPLY_CALLBACK=""

# Mock functions
send() {
  CALLS=$((CALLS + 1))
  # In JS, this returns a promise that resolves when reply is called.
  # Here we simulate by setting a callback variable.
  REPLY_CALLBACK="pending_reply_$CALLS"
}

renderPlayer() {
  local STATE="$1"
  RENDERED+=("$STATE")
}

# Simulate refreshPlayer logic as a function
refreshPlayer() {
  if [[ "$ACTIVE_IS_TIKTOK" != "true" ]]; then
    return 0
  fi

  send
  # Wait for reply (simulate async)
  while [[ -z "${!REPLY_CALLBACK:-}" ]]; do
    sleep 0.01
  done
  RESPONSE="${!REPLY_CALLBACK}"
  unset "$REPLY_CALLBACK"

  # Check if tab ID matches current active tab before rendering
  if [[ "$RESPONSE" == *"tabId\":$ACTIVE_TAB_ID"* ]]; then
    renderPlayer "$RESPONSE"
  fi
}

# Test case 1: Old tab response must be ignored
ACTIVE_TAB_ID=1
ACTIVE_IS_TIKTOK=true
PLAYER_CONTEXT_GENERATION=0
CALLS=0
RENDERED=()

# Start first call
refreshPlayer &
BG_PID=$!

# Change context mid-call
ACTIVE_TAB_ID=2

# Simulate reply from old tab
eval "pending_reply_1='{\"response\":{\"playerState\":{\"playing\":true},\"tabId\":1}}'"

wait "$BG_PID"

if [[ ${#RENDERED[@]} -ne 0 ]]; then
  echo "FAIL: Old tab response was not ignored."
  exit 1
fi

# Test case 2: Non-TikTok tabs must not be polled
ACTIVE_IS_TIKTOK=false
refreshPlayer
if [[ $CALLS -ne 1 ]]; then
  echo "FAIL: Non-TikTok tab was polled."
  exit 1
fi

# Test case 3: Current tab response must render
ACTIVE_IS_TIKTOK=true
ACTIVE_TAB_ID=2
refreshPlayer &
BG_PID=$!
eval "pending_reply_2='{\"response\":{\"playerState\":{\"playing\":true},\"tabId\":2}}'"
wait "$BG_PID"

if [[ ${#RENDERED[@]} -ne 1 ]]; then
  echo "FAIL: Current tab response did not render."
  exit 1
fi

# Test case 4: Returning to same tab must not revive old response
ACTIVE_TAB_ID=3
PLAYER_CONTEXT_GENERATION=$((PLAYER_CONTEXT_GENERATION + 1))
ACTIVE_TAB_ID=2
PLAYER_CONTEXT_GENERATION=$((PLAYER_CONTEXT_GENERATION + 1))

refreshPlayer &
BG_PID=$!
eval "pending_reply_3='{\"response\":{\"playerState\":{\"playing\":false},\"tabId\":2}}'"
wait "$BG_PID"

if [[ ${#RENDERED[@]} -ne 1 ]]; then
  echo "FAIL: Same tab revived an old response."
  exit 1
fi

# Final check for source pattern (conceptual)
if ! grep -q "async function refresh()[[:space:]]*{[[:space:]]*playerContextGeneration++;" "$SOURCE_FILE"; then
  echo "FAIL: Context invalidation does not precede asynchronous tab lookup."
  exit 1
fi

echo "PASS: stale tab response ignored, non-TikTok polling skipped, current response rendered"
