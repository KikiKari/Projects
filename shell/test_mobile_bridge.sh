#!/bin/bash
# test_mobile_bridge.cjs — portiert nach shell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_bridge.cjs
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Function to check if a string contains a substring
contains() {
    local haystack="$1"
    local needle="$2"
    [[ "$haystack" == *"$needle"* ]]
}

# Function to check if a string does NOT contain a substring
not_contains() {
    local haystack="$1"
    local needle="$2"
    ! contains "$haystack" "$needle"
}

# Get the directory of this script and resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(realpath "$SCRIPT_DIR/..")"
BRIDGE_PATH="$ROOT/mobile-shared/webview-bridge.js"

# Check if bridge file exists
if [[ ! -f "$BRIDGE_PATH" ]]; then
    echo "ERROR: Bridge file not found at $BRIDGE_PATH" >&2
    exit 1
fi

# Read the source file
SOURCE=$(cat "$BRIDGE_PATH")

# Run assertions - each should be contained in source
declare -a must_contain=(
    'location.hostname !== "www.tiktok.com"'
    "root.top === root"
    "if (!isTop) return"
    "MAX_MESSAGE_BYTES = 64 * 1024"
    "MAX_AUDIO_SECONDS = 12"
    "QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400"
    "ALLOWED_COMMANDS"
    '"set-auto-reconnect"'
    '"set-limiter"'
    '"scan-recommendations"'
    '"cancel-recommendation-scan"'
    "MAX_MEDIA_URLS = 12"
    "const mediaUrls = new Map()"
    'emit("media-url"'
    'addEventListener("message"'
    'FORCE_RETURN_KEY = "tlc-force-return"'
    "sessionStorage.getItem(FORCE_RETURN_KEY)"
)

# Run negative assertions - each should NOT be contained in source
declare -a must_not_contain=(
    ".send ="
    "document.cookie"
    "localStorage"
    "sessionStorage.clear"
    "innerHTML"
)

# Check positive assertions
for item in "${must_contain[@]}"; do
    if ! contains "$SOURCE" "$item"; then
        echo "FAIL: Expected to find '$item' in bridge source" >&2
        exit 1
    fi
done

# Check negative assertions
for item in "${must_not_contain[@]}"; do
    if ! not_contains "$SOURCE" "$item"; then
        echo "FAIL: Not expected to find '$item' in bridge source" >&2
        exit 1
    fi
done

# Check copies match
COPY_PATHS=(
    "$ROOT/../mobile/ios/Resources/webview-bridge.js"
    "$ROOT/../mobile/android/app/src/main/res/raw/webview_bridge.js"
)

for copy_path in "${COPY_PATHS[@]}"; do
    if [[ ! -f "$copy_path" ]]; then
        echo "ERROR: Bridge copy not found at $copy_path" >&2
        exit 1
    fi
    
    COPY_CONTENT=$(cat "$copy_path")
    if [[ "$COPY_CONTENT" != "$SOURCE" ]]; then
        echo "FAIL: Bridge copy drifted: $copy_path" >&2
        exit 1
    fi
done

echo "PASS: mobile bridge origin, main-frame, size, command, audio-duration and storage guards"
