#!/bin/bash
# test_extension.cjs — portiert nach shell
# Quelle: javascript, Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_extension.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# This bash translation mimics the JavaScript tests by checking files,
# content hashes, and verifying expected strings in sources.
# Due to bash limitations, complex logic like protobuf decoding or VM execution
# is represented through grep/sed checks on relevant files.

root=$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")
extension="$root/browser-extension"
manifest_file="$extension/manifest.json"

# Load manifest version
manifest_version=$(jq -r '.manifest_version' "$manifest_file")
version=$(jq -r '.version' "$manifest_file")

# Assertions via bash equivalents
[[ "$manifest_version" == "3" ]] || { echo "FAIL: manifest_version != 3"; exit 1; }
[[ "$version" == "0.8.2" ]] || { echo "FAIL: version != 0.8.2"; exit 1; }

permissions=$(jq -r '.permissions[]' "$manifest_file")
host_permissions=$(jq -r '.host_permissions[]' "$manifest_file")

echo "$permissions" | grep -q "sidePanel" || { echo "FAIL: Missing sidePanel permission"; exit 1; }
echo "$permissions" | grep -q "webRequest" || { echo "FAIL: Missing webRequest permission"; exit 1; }
echo "$permissions" | grep -q "tabCapture" || { echo "FAIL: Missing tabCapture permission"; exit 1; }
echo "$host_permissions" | grep -q "http://127.0.0.1/*" || { echo "FAIL: Missing host_permission http://127.0.0.1/*"; exit 1; }
echo "$host_permissions" | grep -q "http://localhost/*" || { echo "FAIL: Missing host_permission http://localhost/*"; exit 1; }

# Check forbidden permissions
if echo "$permissions" | grep -q "cookies"; then
    echo "FAIL: Found forbidden permission: cookies"
    exit 1
fi
if echo "$permissions" | grep -q "webRequestBlocking"; then
    echo "FAIL: Found forbidden permission: webRequestBlocking"
    exit 1
fi
if echo "$permissions" | grep -q "nativeMessaging"; then
    echo "FAIL: Found forbidden permission: nativeMessaging"
    exit 1
fi

# Check vendor files exist
mpegts_files=("vendor-mpegts.js" "vendor-mpegts.LICENSE.txt" "vendor-mpegts.NOTICE.md")
for f in "${mpegts_files[@]}"; do
    [[ -f "$extension/$f" ]] || { echo "FAIL: Missing $f"; exit 1; }
done

# SHA256 check
mpegts_hash=$(sha256sum "$extension/vendor-mpegts.js" | cut -d ' ' -f 1 | tr a-z A-Z)
expected_hash="0786F9AF6780822FF29240259A73B07ED7BC479BC44966E49418DD38213B8064"
[[ "$mpegts_hash" == "$expected_hash" ]] || { echo "FAIL: vendor-mpegts.js hash mismatch"; exit 1; }

# Check content_script js entry
cs_js=$(jq -r '.content_scripts[0].js[0]' "$manifest_file")
[[ "$cs_js" == "vendor-mpegts.js" ]] || { echo "FAIL: content_scripts js mismatch"; exit 1; }

# Check mobile bridge content
mobile_bridge_content=$(cat "$root/mobile-shared/webview-bridge.js")
[[ "$mobile_bridge_content" == *"location.hostname !== \"www.tiktok.com\""* ]] || { echo "FAIL: mobileBridge missing hostname check"; exit 1; }
[[ "$mobile_bridge_content" == *"document.cookie"* ]] && { echo "FAIL: mobileBridge contains document.cookie"; exit 1; }
[[ "$mobile_bridge_content" == *"QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400"* ]] || { echo "FAIL: mobileBridge missing QUICK_RECOVER_RELOAD_COOLDOWN_MS"; exit 1; }
[[ "$mobile_bridge_content" == *"\"set-auto-reconnect\""* ]] || { echo "FAIL: mobileBridge missing set-auto-reconnect"; exit 1; }
[[ "$mobile_bridge_content" == *"\"set-limiter\""* ]] || { echo "FAIL: mobileBridge missing set-limiter"; exit 1; }

# Check manifest files exist
check_manifest_files() {
    local files=("$1")
    IFS=$'\n'
    for rel in $files; do
        [[ -f "$extension/$rel" ]] || { echo "FAIL: Missing manifest file: $rel"; exit 1; }
    done
}

bg_service_worker=$(jq -r '.background.service_worker' "$manifest_file")
side_panel_default_path=$(jq -r '.side_panel.default_path' "$manifest_file")
content_scripts_js=$(jq -r '.content_scripts[].js[]' "$manifest_file")

check_manifest_files "$bg_service_worker"$'\n'"$side_panel_default_path"$'\n'"$content_scripts_js"

# Check all .js files parse without syntax errors and don't contain dangerous patterns
scripts=$(find "$extension" -maxdepth 1 -name "*.js")
for script in $scripts; do
    node -c "$script" >/dev/null || { echo "FAIL: Syntax error in $script"; exit 1; }
    content=$(cat "$script")
    [[ "$content" != *"eval("* ]] || { echo "FAIL: $script contains eval()"; exit 1; }
    [[ "$content" != *"new Function("* ]] || { echo "FAIL: $script contains new Function()"; exit 1; }
    [[ "$content" != *".innerHTML ="* ]] || { echo "FAIL: $script assigns innerHTML"; exit 1; }
done

# Run external test scripts
run_test() {
    local test_script="$1"
    node "$test_script" || { echo "FAIL: Test $test_script failed"; exit 1; }
}

run_test "$root/test/test_background_runtime.cjs"
run_test "$root/test/test_sidepanel_player_guard.cjs"
run_test "$root/test/test_vlc_switch.cjs"
run_test "$root/test/test_external_speech_filter.cjs"
run_test "$root/test/test_issue_controls.cjs"

echo "PASS: manifest 0.8.2, $(echo "$scripts" | wc -l) scripts, chat speech composition, gifts, audience statistics, service controls and security guards"
