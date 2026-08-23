#!/usr/bin/env bash
# tiktok-common.test.js — portiert nach shell
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-common.test.js
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# This script tests the functions from tiktok-common.bash by sourcing it.
# It mimics the behavior of the original JavaScript test file.

# Source the common library
source "$(dirname "${BASH_SOURCE[0]}")/tiktok-common.bash"

# Helper function to simulate assert.strictEqual
assert_strict_equal() {
    local name="$1"
    local actual="$2"
    local expected="$3"
    if [[ "$actual" != "$expected" ]]; then
        echo "FAIL: $name - Expected '$expected', got '$actual'" >&2
        return 1
    fi
}

# Helper function to simulate assert.deepStrictEqual for arrays
assert_deep_strict_equal() {
    local name="$1"; shift
    local actual=("$@")
    local expected=("${!#}") # last argument is expected array as string
    # Remove the last element which was the expected string
    unset 'actual[${#actual[@]}-1]'
    if [[ "${actual[*]}" != "$expected" ]]; then
        echo "FAIL: $name - Expected [$expected], got [${actual[*]}]" >&2
        return 1
    fi
}

# Helper function to simulate assert.throws
assert_throws() {
    local name="$1"
    local cmd="$2"
    if eval "$cmd" &>/dev/null; then
        echo "FAIL: $name - Expected exception but none was thrown" >&2
        return 1
    fi
}

# Test normalizeUsername
echo "Testing normalizeUsername..."
assert_strict_equal "normalizeUsername('@example_creator')" \
    "$(normalizeUsername '@example_creator')" \
    "example_creator"

assert_strict_equal "normalizeUsername(' example_creator ')" \
    "$(normalizeUsername ' example_creator ')" \
    "example_creator"

assert_throws "normalizeUsername('example_creator;id')" \
    "normalizeUsername 'example_creator;id'"

# Test liveHrefSelectors
echo "Testing liveHrefSelectors..."
expected_selectors=("a[href=\"/@example_creator/live\"]" "a[href^=\"/@example_creator/live?\"]")
actual_selectors=($(liveHrefSelectors 'example_creator'))
assert_deep_strict_equal "liveHrefSelectors('example_creator')" \
    "${actual_selectors[@]}" \
    "${expected_selectors[*]}"

# Test loadState
echo "Testing loadState..."
export TIKTOK_TEST_LOAD_PER_CPU="2"
export TIKTOK_MAX_LOAD_PER_CPU="1.5"
load_state_result=$(loadState)
if ! grep -q '"overloaded":true' <<<"$load_state_result"; then
    echo "FAIL: loadState should indicate overloaded=true" >&2
    return 1
fi

# Test isAllowedStreamUrl
echo "Testing isAllowedStreamUrl..."
if ! isAllowedStreamUrl "https://pull-flv-f77-tt04.tiktokcdn-eu.com/game/live.flv?sign=x"; then
    echo "FAIL: Allowed URL incorrectly rejected" >&2
    return 1
fi

if isAllowedStreamUrl "https://attacker.example/path/tiktokcdn/video.flv"; then
    echo "FAIL: Disallowed domain incorrectly allowed" >&2
    return 1
fi

if isAllowedStreamUrl "http://pull-flv-f77-tt04.tiktokcdn-eu.com/game/live.flv"; then
    echo "FAIL: HTTP URL incorrectly allowed" >&2
    return 1
fi

# Test isSuccessfulStreamResponse
echo "Testing isSuccessfulStreamResponse..."
allowed_url="https://pull-flv-f77-tt04.tiktokcdn-eu.com/game/live.flv?sign=x"
if ! isSuccessfulStreamResponse 200 "$allowed_url"; then
    echo "FAIL: Status 200 should be successful" >&2
    return 1
fi

if ! isSuccessfulStreamResponse 206 "$allowed_url"; then
    echo "FAIL: Status 206 should be successful" >&2
    return 1
fi

if isSuccessfulStreamResponse 404 "$allowed_url"; then
    echo "FAIL: Status 404 should not be successful" >&2
    return 1
fi

# Test normalizeExtractorResult
echo "Testing normalizeExtractorResult..."
result=$(normalizeExtractorResult '{"success": "false", "status": "offline"}' "streamlink" "example_creator")
status=$(jq -r '.status' <<<"$result")
assert_strict_equal "normalizeExtractorResult with success=false,status=offline" \
    "$status" \
    "technical_error"

result=$(normalizeExtractorResult '{"success": true, "status": "live"}' "streamlink" "example_creator")
status=$(jq -r '.status' <<<"$result")
assert_strict_equal "normalizeExtractorResult with boolean success=true" \
    "$status" \
    "technical_error"

result=$(normalizeExtractorResult '{"success": false, "status": "offline", "url": "'"$allowed_url"'"}' "streamlink" "example_creator")
status=$(jq -r '.status' <<<"$result")
url_field=$(jq -r '.url // "undefined"' <<<"$result")
assert_strict_equal "normalizeExtractorResult offline result status" "$status" "offline"
assert_strict_equal "normalizeExtractorResult offline result url field" "$url_field" "undefined"

result=$(normalizeExtractorResult '{"success": true, "status": "live", "url": "'"$allowed_url"'"}' "streamlink" "example_creator")
status=$(jq -r '.status' <<<"$result")
assert_strict_equal "normalizeExtractorResult live result" "$status" "live"

# Test classifyFinalFailure
echo "Testing classifyFinalFailure..."
result=$(classifyFinalFailure '[{"status": "offline"}, {"status": "dependency_missing"}]')
status=$(jq -r '.' <<<"$result")
assert_strict_equal "classifyFinalFailure" "$status" "offline"

# Test exitCodeForResult
echo "Testing exitCodeForResult..."
code=$(exitCodeForResult '{"success": false, "status": "restricted"}')
assert_strict_equal "exitCodeForResult restricted" "$code" "1"

code=$(exitCodeForResult '{"success": false, "status": "technical_error"}')
assert_strict_equal "exitCodeForResult technical_error" "$code" "2"

# Test classifyDirectLiveState
echo "Testing classifyDirectLiveState..."
state='{"username":"example_creator","currentPath":"/@example_creator/live","title":"Example (@example_creator) is LIVE - TikTok LIVE","bodyText":"Dieses LIVE enthält Themen, die unangenehm sein könnten.","successfulStreamResponse":false}'
result=$(classifyDirectLiveState "$state")
status=$(jq -r '.status' <<<"$result")
assert_strict_equal "classifyDirectLiveState restricted" "$status" "restricted"

state='{"username":"example_creator","currentPath":"/@example_creator/live","title":"Example (@example_creator) is LIVE - TikTok LIVE","bodyText":"LIVE has ended","successfulStreamResponse":false}'
result=$(classifyDirectLiveState "$state")
status=$(jq -r '.status' <<<"$result")
assert_strict_equal "classifyDirectLiveState offline (ended)" "$status" "offline"

state='{"username":"example_creator","currentPath":"/@example_creator/live","title":"Example (@example_creator) is LIVE - TikTok LIVE","bodyText":"Suggested LIVE creators","successfulStreamResponse":true}'
result=$(classifyDirectLiveState "$state")
status=$(jq -r '.status' <<<"$result")
assert_strict_equal "classifyDirectLiveState live" "$status" "live"

echo "All tests passed."
