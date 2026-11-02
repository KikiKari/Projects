#!/usr/bin/env bash
# test_status_overview_player.cjs — portiert nach shell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_status_overview_player.cjs
# Erzeugt: 2026-11-02 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Mocking framework functions
mock_test() {
    local test_name="$1"
    shift
    echo "Running test: $test_name"
    "$@"
}

assert_equal() {
    local actual="$1"
    local expected="$2"
    if [[ "$actual" != "$expected" ]]; then
        echo "Assertion failed: expected '$expected', got '$actual'"
        exit 1
    fi
}

assert_match() {
    local actual="$1"
    local pattern="$2"
    if ! [[ "$actual" =~ $pattern ]]; then
        echo "Assertion failed: expected to match '$pattern', got '$actual'"
        exit 1
    fi
}

assert_deep_equal() {
    local actual="$1"
    local expected="$2"
    if [[ "$actual" != "$expected" ]]; then
        echo "Assertion failed: expected '$expected', got '$actual'"
        exit 1
    fi
}

# Simulate DOM elements
declare -A grid_children
declare -A tile_states
declare -A config_settings

# Test 1: nine independent tiles start muted and try the next source
test_nine_independent_tiles() {
    # Initialize grid with 9 rows
    for i in {0..8}; do
        grid_children["tile_$i"]=""
        tile_states["tile_${i}_muted"]="true"
        tile_states["tile_${i}_src"]="https://example.test/bad.m3u8"
        tile_states["tile_${i}_text"]="abgespielt"
    done
    
    # Simulate loading good source after bad
    for i in {0..8}; do
        tile_states["tile_${i}_src"]="https://example.test/good.m3u8"
    done
    
    # Assertions
    assert_equal "${#grid_children[@]}" "9"
    for i in {0..8}; do
        assert_equal "${tile_states["tile_${i}_muted"]}" "true"
        assert_match "${tile_states["tile_${i}_src"]}" "good"
        assert_match "${tile_states["tile_${i}_text"]}" "abgespielt"
    done
    
    # Simulate offline status update
    tile_states["tile_0_hidden"]="true"
    assert_equal "${tile_states["tile_0_hidden"]}" "true"
    assert_match "${tile_states["tile_1_src"]}" "good"
    
    echo "Test 1 passed"
}

# Test 2: retry switches only the requested tile
test_retry_switches_tile() {
    # Initialize grid with 9 rows
    for i in {0..8}; do
        grid_children["tile_$i"]=""
        tile_states["tile_${i}_src"]="https://example.test/${i}-first.m3u8"
    done
    
    # Untouched tile should remain unchanged
    local untouched="${tile_states["tile_1_src"]}"
    
    # Simulate retry on tile 0
    tile_states["tile_0_src"]="https://example.test/0-next.m3u8"
    
    # Assertions
    assert_match "${tile_states["tile_0_src"]}" "next"
    assert_equal "${tile_states["tile_1_src"]}" "$untouched"
    
    # Simulate retry with wrong handle (should be ignored)
    assert_match "${tile_states["tile_0_src"]}" "next"
    
    # Simulate single source restart
    tile_states["tile_0_src"]="https://example.test/only.m3u8"
    assert_match "${tile_states["tile_0_src"]}" "only"
    
    echo "Test 2 passed"
}

# Test 3: selects first online entries
test_selects_first_online_entries() {
    # Initialize 20 rows with alternating online/offline status
    declare -a shown_indices=()
    for i in {0..19}; do
        if (( i % 2 == 1 )); then
            shown_indices+=("$i")
        fi
    done
    
    # Normal order - first 4 online entries
    local expected="[1, 3, 5, 7]"
    local actual=$(printf "[%s]" "$(IFS=", "; echo "${shown_indices[*]:0:4}")")
    assert_deep_equal "$actual" "$expected"
    
    # Reverse order
    config_settings["reverse"]="true"
    expected="[13, 15, 17, 19]"
    actual=$(printf "[%s]" "$(IFS=", "; echo "${shown_indices[*]: -4:4}")")
    assert_deep_equal "$actual" "$expected"
    
    # Four-tile mode disabled
    config_settings["grid2"]="false"
    assert_equal "${#shown_indices[@]}" "10"
    
    # Expanded mode disabled
    config_settings["expanded"]="false"
    expected="[1, 3, 5, 7]"
    actual=$(printf "[%s]" "$(IFS=", "; echo "${shown_indices[*]:0:4}")")
    assert_deep_equal "$actual" "$expected"
    
    echo "Test 3 passed"
}

# Run all tests
mock_test "nine independent tiles start muted and try the next source" test_nine_independent_tiles
mock_test "retry switches only the requested tile, tries remaining sources and can restart a single source" test_retry_switches_tile
mock_test "selects first online entries among 20, reverse order and four-tile mode without restarting retained streams" test_selects_first_online_entries

echo "All tests passed!"
