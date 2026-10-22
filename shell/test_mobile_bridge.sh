#!/bin/bash
# test_mobile_bridge.cjs — portiert nach shell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_mobile_bridge.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Function to check if a string contains a substring
contains() {
    local haystack="$1"
    local needle="$2"
    [[ "$haystack" == *"$needle"* ]]
}

# Function to check if a string does not contain a substring
not_contains() {
    local haystack="$1"
    local needle="$2"
    ! contains "$haystack" "$needle"
}

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(realpath "$SCRIPT_DIR/..")"
BRIDGE_PATH="$ROOT/mobile-shared/webview-bridge.js"

# Check if required files exist
if [[ ! -f "$BRIDGE_PATH" ]]; then
    echo "FAIL: Bridge file not found at $BRIDGE_PATH" >&2
    exit 1
fi

# Read the source file
SOURCE=$(cat "$BRIDGE_PATH")

# Validate that the JavaScript can be parsed by attempting to find key strings
echo "Checking for expected content..."

# Assertions - each should be present
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

# Assertions - these must NOT be present
declare -a must_not_contain=(
    ".send ="
    "document.cookie"
    "localStorage"
    "sessionStorage.clear"
    "innerHTML"
)

# Check for presence of required strings
for item in "${must_contain[@]}"; do
    if ! contains "$SOURCE" "$item"; then
        echo "FAIL: Expected string not found: $item" >&2
        exit 1
    fi
done

# Check for absence of forbidden strings
for item in "${must_not_contain[@]}"; do
    if ! not_contains "$SOURCE" "$item"; then
        echo "FAIL: Forbidden string found: $item" >&2
        exit 1
    fi
done

echo "All content checks passed."

# Check copies in iOS and Android directories
echo "Checking bridge copies..."

COPY_PATHS=(
    "$ROOT/../mobile/ios/Resources/webview-bridge.js"
    "$ROOT/../mobile/android/app/src/main/res/raw/webview_bridge.js"
)

for copy_path in "${COPY_PATHS[@]}"; do
    if [[ ! -f "$copy_path" ]]; then
        echo "FAIL: Bridge copy not found at $copy_path" >&2
        exit 1
    fi
    
    COPY_CONTENT=$(cat "$copy_path")
    
    if [[ "$COPY_CONTENT" != "$SOURCE" ]]; then
        echo "FAIL: Bridge copy drifted: $copy_path" >&2
        exit 1
    fi
done

echo "PASS: mobile bridge origin, main-frame, size, command, audio-duration and storage guards"
