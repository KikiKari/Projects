#!/usr/bin/env bash
# test-skill-contract.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:skills/tiktok-live/scripts/test-skill-contract.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Regression checks for the documented /tiktok_live normal flow.

# Define constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL="$SCRIPT_DIR/../SKILL.md"
CANONICAL_COMMAND="/home/openclaw/.openclaw/workspace/tiktok-monitor/tiktok_dispatch.py url @handle --quality auto --json"
NODE_COMMAND="$CANONICAL_COMMAND"

# Read the skill file content
text=$(cat "$SKILL")
normalized_text=$(echo "$text" | tr -s ' \t\n' ' ')

# Helper function for assertions
assert_in() {
    local expected="$1"
    local actual="$2"
    if [[ "$actual" != *"$expected"* ]]; then
        echo "Assertion failed: '$expected' not found in text"
        exit 1
    fi
}

assert_not_in() {
    local unexpected="$1"
    local actual="$2"
    if [[ "$actual" == *"$unexpected"* ]]; then
        echo "Assertion failed: '$unexpected' found in text"
        exit 1
    fi
}

# Test functions
test_dispatcher_is_the_documented_first_action() {
    assert_in "Make the existing dispatcher the first action" "$text"
    assert_in "first tool call of the request" "$normalized_text"
    local count
    count=$(grep -F "$CANONICAL_COMMAND" "$SKILL" | wc -l)
    if [[ $count -ne 2 ]]; then
        echo "Assertion failed: Expected exactly 2 occurrences of CANONICAL_COMMAND"
        exit 1
    fi
}

test_slash_command_bypasses_the_model() {
    assert_in "command-dispatch: tool" "$text"
    assert_in "command-tool: tiktok_live_command" "$text"
    assert_in "command-arg-mode: raw" "$text"
}

test_no_preliminary_playwright_or_dependency_probe() {
    assert_in "Before this dispatcher call, do not invoke or inspect" "$normalized_text"
    assert_in "\`tiktok-check-profile.js\`" "$normalized_text"
    assert_in "Do not attempt to install or repair browser dependencies" "$normalized_text"
    assert_in "failed preliminary tool call" "$normalized_text"
}

test_direct_exec_without_shell_wrapper() {
    assert_in "Invoke that executable directly as the exec command" "$normalized_text"
    assert_in "Do not invoke \`bash\`" "$normalized_text"
    assert_in "\`bash -lc\`" "$normalized_text"
    assert_in "wrapper must not be attempted in the first place" "$normalized_text"
}

test_success_json_wins_over_trailing_diagnostics() {
    assert_in "display the final stdout JSON before trailing stderr diagnostics" "$normalized_text"
    assert_in "regardless of its visual position" "$normalized_text"
    assert_in "the tool execution succeeded" "$normalized_text"
    assert_in "Never replace such a result with a generic tool-failure message" "$normalized_text"
    assert_in "\`node_available\`" "$normalized_text"
}

test_auto_host_and_bounded_node_fallback() {
    assert_in "tools.exec.host=auto" "$text"
    assert_in "omit both the \`host\` and \`node\` fields" "$text"
    assert_in "retry exactly once" "$text"
    assert_in "least-loaded connected paired node" "$text"
    assert_in "host=node" "$text"
    assert_in "$NODE_COMMAND" "$text"
    assert_in "Never replace it with" "$text"
    assert_in "\`technical_error\`, \`dependency_missing\`, or \`overloaded\`" "$normalized_text"
    assert_not_in "host=gateway" "$text"
    assert_in "Never start a second node retry" "$text"
    assert_in "never\nchange the global exec host" "$text"
    assert_in "runtime block occurs before the Node allowlist" "$text"
    
    local count
    count=$(grep -F "$CANONICAL_COMMAND" "$SKILL" | wc -l)
    if [[ $count -ne 2 ]]; then
        echo "Assertion failed: Expected exactly 2 occurrences of CANONICAL_COMMAND"
        exit 1
    fi
}

test_public_contract_covers_legacy_and_rich_formats() {
    local legacy="@<handle> is currently <OFFLINE|RESTRICTED|OVERLOADED|TECHNICAL_ERROR> on TikTok.
VLC/MPV: not available
Method: <validated method>"
    
    assert_in "$legacy" "$text"
    assert_in "@<handle> is currently LIVE on TikTok.
Titel: <room.title>" "$text"
    
    assert_in "Stream-URLs:" "$normalized_text"
    assert_in "<label> (HLS):" "$normalized_text"
    assert_in "<label> (FLV):" "$normalized_text"
    assert_in "Live seit: <HH:MM UTC> (<Xh Ym>)" "$normalized_text"
    assert_in "exactly one URL and nothing else" "$normalized_text"
    assert_in "degrades to the legacy three lines including the \`VLC/MPV:\` URL" "$normalized_text"
    assert_in "No raw URL appears in plain text" "$normalized_text"
}

test_existing_capabilities_are_preserved() {
    local capabilities=("Node" "browser" "file" "directory" "configuration" "dependency" "diagnostic tools remain available")
    for capability in "${capabilities[@]}"; do
        assert_in "$capability" "$text"
    done
}

test_no_response_flag_is_documented() {
    assert_not_in "--response" "$text"
}

test_atomic_output_and_synchronized_audio() {
    assert_in "send it atomically" "$normalized_text"
    assert_in "Preserve every returned URL byte-for-byte" "$normalized_text"
    assert_in "channel voice output set to \`always\`" "$normalized_text"
    assert_in "Do not invoke the \`tts\` tool" "$normalized_text"
    assert_in "do not emit \`[[tts:text]]\` wrappers" "$normalized_text"
    assert_in "visible text remains the authoritative source" "$normalized_text"
}

# Run all tests
run_tests() {
    declare -a tests=(
        "test_dispatcher_is_the_documented_first_action"
        "test_slash_command_bypasses_the_model"
        "test_no_preliminary_playwright_or_dependency_probe"
        "test_direct_exec_without_shell_wrapper"
        "test_success_json_wins_over_trailing_diagnostics"
        "test_auto_host_and_bounded_node_fallback"
        "test_public_contract_covers_legacy_and_rich_formats"
        "test_existing_capabilities_are_preserved"
        "test_no_response_flag_is_documented"
        "test_atomic_output_and_synchronized_audio"
    )
    
    local passed=0
    local failed=0
    
    for test_func in "${tests[@]}"; do
        if "$test_func"; then
            ((passed++))
            echo "PASS: $test_func"
        else
            ((failed++))
            echo "FAIL: $test_func"
        fi
    done
    
    echo "Tests run: $((passed + failed)), Passed: $passed, Failed: $failed"
    
    if [[ $failed -gt 0 ]]; then
        exit 1
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi
