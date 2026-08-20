#!/usr/bin/env bash
# test-skill-contract.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/test-skill-contract.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Regression checks for /tiktok_live_mon routing and monitor actions.

readonly SKILL="$(realpath "$(dirname "${BASH_SOURCE[0]}")/../SKILL.md")"
readonly DISPATCHER="/home/openclaw/.openclaw/workspace/tiktok-monitor/tiktok_dispatch.py url @name --quality auto --json"
readonly CONTROLLER="/home/openclaw/.openclaw/workspace/tiktok-monitor/tiktok-monitorctl.sh"

text=$(cat "$SKILL")
normalized_text=$(echo "$text" | tr -s '[:space:]' ' ')

function assertIn() {
    local expected="$1"
    local actual="$2"
    if [[ "$actual" != *"$expected"* ]]; then
        echo "FAIL: Expected '$expected' not found in text."
        exit 1
    fi
}

function test_bare_handle_uses_dispatcher_as_first_tool_call() {
    assertIn "dispatcher exec must be the first tool call" "$normalized_text"
    assertIn "$DISPATCHER" "$text"
    assertIn "A bare handle never starts a daemon" "$text"
}

function test_slash_command_bypasses_the_model() {
    for expected in \
        "command-dispatch: tool" \
        "command-tool: tiktok_live_mon_command" \
        "command-arg-mode: raw"; do
        assertIn "$expected" "$text"
    done
}

function test_no_preliminary_playwright_or_dependency_probe() {
    for expected in \
        "Before this dispatcher call, do not invoke or inspect" \
        "\`tiktok-check-profile.js\`" \
        "Do not attempt to install or repair browser dependencies" \
        "failed preliminary tool call"; do
        assertIn "$expected" "$normalized_text"
    done
}

function test_direct_exec_without_shell_wrapper() {
    for expected in \
        "Invoke that executable directly as the exec command" \
        "Do not invoke \`bash\`" \
        "\`bash -lc\`" \
        "wrapper must not be attempted in the first place"; do
        assertIn "$expected" "$normalized_text"
    done
}

function test_success_json_wins_over_trailing_diagnostics() {
    for expected in \
        "display the final stdout JSON before trailing stderr diagnostics" \
        "regardless of its visual position" \
        "the tool execution succeeded" \
        "Never replace such a result with a generic tool-failure message" \
        "\`node_available\`"; do
        assertIn "$expected" "$normalized_text"
    done
}

function test_running_dispatcher_is_polled_without_restart() {
    for expected in \
        "Start exactly one dispatcher exec per request" \
        "do not rerun exec" \
        'sessionId: "NAME"' \
        "Continue polling that same name until completion"; do
        assertIn "$expected" "$text"
    done
}

function test_monitor_actions_remain_controller_backed() {
    for action in start status stop; do
        assertIn "$CONTROLLER $action @name" "$text"
    done
    assertIn "prevents duplicate active monitors" "$text"
    assertIn "Without the current word \`start\`" "$text"
}

function test_one_shot_response_contract_covers_all_statuses() {
    local legacy="@<handle> is currently <OFFLINE|RESTRICTED|OVERLOADED|TECHNICAL_ERROR> on TikTok.
VLC/MPV: not available
Method: <method>"
    assertIn "$legacy" "$text"
    assertIn "@<handle> is currently LIVE on TikTok.
Titel: <room.title>" "$text"

    normalized_single_line=$(echo "$text" | tr '\n' ' ')
    for expected in \
        "Stream-URLs:" \
        "<label> (HLS):" \
        "<label> (FLV):" \
        "exactly one URL and nothing else" \
        "No raw URL appears in plain text"; do
        assertIn "$expected" "$normalized_single_line"
    done

    for status in live offline restricted overloaded dependency_missing technical_error; do
        assertIn "$status" "$text"
    done
}

function test_invalid_current_input_is_not_taken_from_history() {
    assertIn "Derive the action, handle, hours, and poll interval only" "$text"
    assertIn "Never take them from" "$text"
}

# Run all tests
test_bare_handle_uses_dispatcher_as_first_tool_call
test_slash_command_bypasses_the_model
test_no_preliminary_playwright_or_dependency_probe
test_direct_exec_without_shell_wrapper
test_success_json_wins_over_trailing_diagnostics
test_running_dispatcher_is_polled_without_restart
test_monitor_actions_remain_controller_backed
test_one_shot_response_contract_covers_all_statuses
test_invalid_current_input_is_not_taken_from_history

echo "All tests passed."
