#!/bin/bash
# test_extension.cjs — portiert nach shell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_extension.cjs
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# This bash translation mimics the JavaScript tests but due to fundamental differences
# between shell scripting and JavaScript, many assertions are not directly translatable.
# The script will check for existence of files and basic content patterns where possible.

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
extension="$root/browser-extension"

# Check if required directories exist
if [[ ! -d "$extension" ]]; then
    echo "FAIL: Extension directory does not exist"
    exit 1
fi

# Check manifest version
manifest_version=$(jq -r '.manifest_version' "$extension/manifest.json")
version=$(jq -r '.version' "$extension/manifest.json")

if [[ "$manifest_version" != "3" ]]; then
    echo "FAIL: Manifest version is not 3"
    exit 1
fi

if [[ "$version" != "0.8.0" ]]; then
    echo "FAIL: Version is not 0.8.0"
    exit 1
fi

# Check permissions
permissions=$(jq -r '.permissions[]' "$extension/manifest.json")
host_permissions=$(jq -r '.host_permissions[]' "$extension/manifest.json")

required_permissions=("sidePanel" "webRequest" "tabCapture")
for perm in "${required_permissions[@]}"; do
    if ! echo "$permissions" | grep -q "$perm"; then
        echo "FAIL: Missing permission $perm"
        exit 1
    fi
done

required_host_permissions=("http://127.0.0.1/*" "http://localhost/*")
for perm in "${required_host_permissions[@]}"; do
    if ! echo "$host_permissions" | grep -q "$perm"; then
        echo "FAIL: Missing host permission $perm"
        exit 1
    fi
done

forbidden_permissions=("cookies" "webRequestBlocking" "nativeMessaging")
for perm in "${forbidden_permissions[@]}"; do
    if echo "$permissions" | grep -q "$perm"; then
        echo "FAIL: Forbidden permission $perm found"
        exit 1
    fi
done

# Check content scripts
content_script_js=($(jq -r '.content_scripts[0].js[]' "$extension/manifest.json"))
if [[ "${content_script_js[0]}" != "vendor-mpegts.js" ]]; then
    echo "FAIL: First content script JS is not vendor-mpegts.js"
    exit 1
fi

# Check vendor files exist
mpegts_files=("vendor-mpegts.js" "vendor-mpegts.LICENSE.txt" "vendor-mpegts.NOTICE.md")
for file in "${mpegts_files[@]}"; do
    if [[ ! -f "$extension/$file" ]]; then
        echo "FAIL: Missing vendor file $file"
        exit 1
    fi
done

# Check SHA256 hash of vendor-mpegts.js
actual_hash=$(openssl dgst -sha256 "$extension/vendor-mpegts.js" | awk '{print $NF}' | tr '[:lower:]' '[:upper:]')
expected_hash="0786F9AF6780822FF29240259A73B07ED7BC479BC44966E49418DD38213B8064"

if [[ "$actual_hash" != "$expected_hash" ]]; then
    echo "FAIL: SHA256 hash mismatch for vendor-mpegts.js"
    exit 1
fi

# Check mobile bridge content
mobile_bridge_content=$(cat "$root/mobile-shared/webview-bridge.js")
if ! echo "$mobile_bridge_content" | grep -q 'location.hostname !== "www.tiktok.com"'; then
    echo "FAIL: Mobile bridge missing location check"
    exit 1
fi

if echo "$mobile_bridge_content" | grep -q "document.cookie"; then
    echo "FAIL: Mobile bridge contains document.cookie"
    exit 1
fi

required_mobile_patterns=(
    "QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400"
    '"set-auto-reconnect"'
    '"set-limiter"'
)

for pattern in "${required_mobile_patterns[@]}"; do
    if ! echo "$mobile_bridge_content" | grep -q "$pattern"; then
        echo "FAIL: Mobile bridge missing pattern: $pattern"
        exit 1
    fi
done

# Check manifest files exist
manifest_background_service_worker=$(jq -r '.background.service_worker' "$extension/manifest.json")
manifest_side_panel_default_path=$(jq -r '.side_panel.default_path' "$extension/manifest.json")

manifest_files=("$manifest_background_service_worker" "$manifest_side_panel_default_path")
for js_file in "${content_script_js[@]}"; do
    manifest_files+=("$js_file")
done

for relative in "${manifest_files[@]}"; do
    if [[ ! -f "$extension/$relative" ]]; then
        echo "FAIL: Missing manifest file: $relative"
        exit 1
    fi
done

# Check all .js files in extension directory
script_files=()
while IFS= read -r -d '' file; do
    script_files+=("$(basename "$file")")
done < <(find "$extension" -maxdepth 1 -name "*.js" -print0)

# Basic checks on script files (existence only since we can't evaluate JS in bash)
for name in "${script_files[@]}"; do
    if [[ ! -f "$extension/$name" ]]; then
        echo "FAIL: Script file $name does not exist"
        exit 1
    fi
    
    # Check for dangerous patterns
    source=$(cat "$extension/$name")
    if echo "$source" | grep -q "\beval\s*("; then
        echo "FAIL: $name contains eval()"
        exit 1
    fi
    
    if echo "$source" | grep -q "new\s\+Function\s*("; then
        echo "FAIL: $name contains new Function()"
        exit 1
    fi
    
    if echo "$source" | grep -q "\.innerHTML\s*="; then
        echo "FAIL: $name assigns innerHTML"
        exit 1
    fi
done

echo "PASS: Basic file checks passed"

# Note: The extensive functional tests from the JavaScript code cannot be replicated
# in bash without actually running a JavaScript engine, which defeats the purpose
# of translating to bash. The remaining tests would require implementing JavaScript
# logic in bash or using external tools like node.js to execute the actual tests.

# For a complete validation equivalent to the JavaScript version, you would need
# to run the original JavaScript tests with node.js instead of this bash translation.
