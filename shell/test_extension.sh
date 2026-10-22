#!/bin/bash
# test_extension.cjs — portiert nach shell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_extension.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_extension.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# This bash translation mimics the JavaScript test functionality
# but due to fundamental differences between languages, some aspects
# are approximated or simplified where direct translation isn't feasible.

root=$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")
extension="$root/browser-extension"

# Helper functions to mimic Node.js behavior
function read_json() {
    jq -r "$1" < "$2"
}

function file_exists() {
    [[ -f "$1" ]]
}

function dir_exists() {
    [[ -d "$1" ]]
}

function sha256sum_hex() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        shasum -a 256 "$1" | cut -d' ' -f1
    else
        sha256sum "$1" | cut -d' ' -f1
    fi
}

# Assertions (basic implementation)
function assert_equal() {
    local expected="$1"
    local actual="$2"
    if [[ "$expected" != "$actual" ]]; then
        echo "Assertion failed: Expected '$expected', got '$actual'"
        exit 1
    fi
}

function assert_true() {
    local condition="$1"
    if ! $condition; then
        echo "Assertion failed: Condition is false"
        exit 1
    fi
}

function assert_false() {
    local condition="$1"
    if $condition; then
        echo "Assertion failed: Condition is true"
        exit 1
    fi
}

function assert_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" != *"$needle"* ]]; then
        echo "Assertion failed: '$haystack' does not contain '$needle'"
        exit 1
    fi
}

function assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "Assertion failed: '$haystack' contains '$needle'"
        exit 1
    fi
}

# Load manifest
manifest_file="$extension/manifest.json"
manifest_version=$(read_json '.manifest_version' "$manifest_file")
version=$(read_json '.version' "$manifest_file")

# Basic assertions on manifest
assert_equal "3" "$manifest_version"
assert_equal "0.8.2" "$version"

permissions=$(jq -r '.permissions[]' "$manifest_file")
host_permissions=$(jq -r '.host_permissions[]' "$manifest_file")

assert_true 'echo "$permissions" | grep -q "sidePanel"'
assert_true 'echo "$permissions" | grep -q "webRequest"'
assert_true 'echo "$permissions" | grep -q "tabCapture"'
assert_true 'echo "$host_permissions" | grep -q "http://127.0.0.1/*"'
assert_true 'echo "$host_permissions" | grep -q "http://localhost/*"'
assert_false 'echo "$permissions" | grep -q "cookies"'
assert_false 'echo "$permissions" | grep -q "webRequestBlocking"'
assert_false 'echo "$permissions" | grep -q "nativeMessaging"'

content_script_js=$(jq -r '.content_scripts[0].js[0]' "$manifest_file")
assert_equal "vendor-mpegts.js" "$content_script_js"

mpegts_files=(
    "$extension/vendor-mpegts.js"
    "$extension/vendor-mpegts.LICENSE.txt"
    "$extension/vendor-mpegts.NOTICE.md"
)

for file in "${mpegts_files[@]}"; do
    assert_true "file_exists \"$file\""
done

expected_hash="0786F9AF6780822FF29240259A73B07ED7BC479BC44966E49418DD38213B8064"
actual_hash=$(sha256sum_hex "$extension/vendor-mpegts.js" | tr '[:lower:]' '[:upper:]')
assert_equal "$expected_hash" "$actual_hash"

mobile_bridge_content=$(cat "$root/mobile-shared/webview-bridge.js")
assert_contains "$mobile_bridge_content" 'location.hostname !== "www.tiktok.com"'
assert_not_contains "$mobile_bridge_content" "document.cookie"
assert_contains "$mobile_bridge_content" "QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400"
assert_contains "$mobile_bridge_content" '"set-auto-reconnect"'
assert_contains "$mobile_bridge_content" '"set-limiter"'

# Check manifest files exist
background_service_worker=$(jq -r '.background.service_worker' "$manifest_file")
side_panel_default_path=$(jq -r '.side_panel.default_path' "$manifest_file")

assert_true "file_exists \"$extension/$background_service_worker\""
assert_true "file_exists \"$extension/$side_panel_default_path\""

jq -r '.content_scripts[].js[]' "$manifest_file" | while read -r js_file; do
    assert_true "file_exists \"$extension/$js_file\""
done

# Check all .js files in extension directory
find "$extension" -maxdepth 1 -name "*.js" | while read -r script; do
    script_name=$(basename "$script")
    
    # Skip peak-limiter-worklet.js as it requires special handling
    if [[ "$script_name" == "peak-limiter-worklet.js" ]]; then
        continue
    fi
    
    source=$(cat "$script")
    
    # Basic syntax check using node if available
    if command -v node >/dev/null 2>&1; then
        if ! node --check "$script"; then
            echo "Syntax error in $script_name"
            exit 1
        fi
    fi
    
    assert_not_contains "$source" '\beval\s*\('
    assert_not_contains "$source" 'new\s+Function\s*\('
    assert_not_contains "$source" '\.innerHTML\s*='
done

echo "PASS: manifest 0.8.2, $(find "$extension" -maxdepth 1 -name "*.js" | wc -l | tr -d ' ') scripts, basic checks performed"

# Run additional tests if node is available
if command -v node >/dev/null 2>&1; then
    node --test "$(dirname "${BASH_SOURCE[0]}")/test_background_runtime.cjs"
    node "$(dirname "${BASH_SOURCE[0]}")/test_sidepanel_player_guard.cjs"
    node "$(dirname "${BASH_SOURCE[0]}")/test_vlc_switch.cjs"
    for script in test_external_speech_filter.cjs test_issue_controls.cjs test_voice_groups.cjs; do
        node "$(dirname "${BASH_SOURCE[0]}")/$script"
    done
fi
