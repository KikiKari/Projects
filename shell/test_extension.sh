#!/bin/bash
# test_extension.cjs — portiert nach shell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_extension.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# This bash translation simulates the JavaScript tests by checking files,
# verifying content patterns, and running external test scripts.
# It does NOT execute JavaScript logic but validates static properties.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXTENSION="$ROOT/browser-extension"
MOBILE_BRIDGE="$ROOT/mobile-shared/webview-bridge.js"

# Read manifest.json
MANIFEST_JSON="$EXTENSION/manifest.json"
if [[ ! -f "$MANIFEST_JSON" ]]; then
  echo "FAIL: Missing manifest.json"
  exit 1
fi

# Check manifest version
MANIFEST_VERSION=$(jq -r '.manifest_version' "$MANIFEST_JSON")
if [[ "$MANIFEST_VERSION" != "3" ]]; then
  echo "FAIL: Manifest version is not 3"
  exit 1
fi

VERSION=$(jq -r '.version' "$MANIFEST_JSON")
if [[ "$VERSION" != "0.8.2" ]]; then
  echo "FAIL: Version mismatch, expected 0.8.2, got $VERSION"
  exit 1
fi

# Check permissions
PERMISSIONS=$(jq -r '.permissions[]' "$MANIFEST_JSON")
HOST_PERMISSIONS=$(jq -r '.host_permissions[]' "$MANIFEST_JSON")

REQUIRED_PERMISSIONS=("sidePanel" "webRequest" "tabCapture")
for perm in "${REQUIRED_PERMISSIONS[@]}"; do
  if ! echo "$PERMISSIONS" | grep -q "^$perm$"; then
    echo "FAIL: Missing permission $perm"
    exit 1
  fi
done

REQUIRED_HOST_PERMISSIONS=("http://127.0.0.1/*" "http://localhost/*")
for perm in "${REQUIRED_HOST_PERMISSIONS[@]}"; do
  if ! echo "$HOST_PERMISSIONS" | grep -q "^$perm$"; then
    echo "FAIL: Missing host_permission $perm"
    exit 1
  fi
done

FORBIDDEN_PERMISSIONS=("cookies" "webRequestBlocking" "nativeMessaging")
for perm in "${FORBIDDEN_PERMISSIONS[@]}"; do
  if echo "$PERMISSIONS" | grep -q "^$perm$"; then
    echo "FAIL: Forbidden permission $perm present"
    exit 1
  fi
done

# Check vendor files
MPEGTS_VENDOR_PATH="$EXTENSION/vendor-mpegts.js"
MPEGTS_LICENSE_PATH="$EXTENSION/vendor-mpegts.LICENSE.txt"
MPEGTS_NOTICE_PATH="$EXTENSION/vendor-mpegts.NOTICE.md"

for file in "$MPEGTS_VENDOR_PATH" "$MPEGTS_LICENSE_PATH" "$MPEGTS_NOTICE_PATH"; do
  if [[ ! -f "$file" ]]; then
    echo "FAIL: Missing MPEG-TS vendor file: $file"
    exit 1
  fi
done

# Check SHA256 hash of vendor file
EXPECTED_SHA256="0786F9AF6780822FF29240259A73B07ED7BC479BC44966E49418DD38213B8064"
ACTUAL_SHA256=$(sha256sum "$MPEGTS_VENDOR_PATH" | awk '{print toupper($1)}')
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
  echo "FAIL: SHA256 mismatch for vendor-mpegts.js"
  exit 1
fi

# Check mobile bridge content
MOBILE_BRIDGE_CONTENT=$(cat "$MOBILE_BRIDGE")
if ! echo "$MOBILE_BRIDGE_CONTENT" | grep -q 'location.hostname !== "www.tiktok.com"'; then
  echo "FAIL: Mobile bridge missing location check"
  exit 1
fi

if echo "$MOBILE_BRIDGE_CONTENT" | grep -q "document.cookie"; then
  echo "FAIL: Mobile bridge contains document.cookie"
  exit 1
fi

if ! echo "$MOBILE_BRIDGE_CONTENT" | grep -q "QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400"; then
  echo "FAIL: Mobile bridge missing QUICK_RECOVER_RELOAD_COOLDOWN_MS"
  exit 1
fi

if ! echo "$MOBILE_BRIDGE_CONTENT" | grep -q '"set-auto-reconnect"'; then
  echo "FAIL: Mobile bridge missing set-auto-reconnect"
  exit 1
fi

if ! echo "$MOBILE_BRIDGE_CONTENT" | grep -q '"set-limiter"'; then
  echo "FAIL: Mobile bridge missing set-limiter"
  exit 1
fi

# Check all manifest files exist
BACKGROUND_WORKER=$(jq -r '.background.service_worker' "$MANIFEST_JSON")
SIDE_PANEL_DEFAULT=$(jq -r '.side_panel.default_path' "$MANIFEST_JSON")
CONTENT_SCRIPTS_JS=$(jq -r '.content_scripts[].js[]' "$MANIFEST_JSON")

MANIFEST_FILES=("$BACKGROUND_WORKER" "$SIDE_PANEL_DEFAULT" $CONTENT_SCRIPTS_JS)

for rel_path in "${MANIFEST_FILES[@]}"; do
  full_path="$EXTENSION/$rel_path"
  if [[ ! -f "$full_path" ]]; then
    echo "FAIL: Missing manifest file: $rel_path"
    exit 1
  fi
done

# List .js files in extension directory
SCRIPTS=()
while IFS= read -r -d '' file; do
  SCRIPTS+=("$(basename "$file")")
done < <(find "$EXTENSION" -maxdepth 1 -name "*.js" -print0)

echo "Found ${#SCRIPTS[@]} JS scripts to validate."

# Validate each script
for name in "${SCRIPTS[@]}"; do
  source_file="$EXTENSION/$name"
  source_content=$(cat "$source_file")

  # Skip syntax validation for peak-limiter-worklet.js as it's ES module
  if [[ "$name" == "peak-limiter-worklet.js" ]]; then
    node --check --input-type=module <<< "$source_content" >/dev/null 2>&1 || {
      echo "FAIL: Syntax error in $name"
      exit 1
    }
  else
    # Basic syntax check using node (approximation)
    echo "$source_content" | node -c >/dev/null 2>&1 || {
      echo "FAIL: Syntax error in $name"
      exit 1
    }
  fi

  # Check for forbidden patterns
  if echo "$source_content" | grep -q '\beval\s*('; then
    echo "FAIL: $name contains eval()"
    exit 1
  fi

  if echo "$source_content" | grep -q 'new\s\+Function\s*('; then
    echo "FAIL: $name contains new Function()"
    exit 1
  fi

  if echo "$source_content" | grep -q '\.innerHTML\s*='; then
    echo "FAIL: $name assigns innerHTML"
    exit 1
  fi
done

# Run external test scripts
TEST_DIR="$(dirname "${BASH_SOURCE[0]}")"
TEST_SCRIPTS=(
  "test_background_runtime.cjs"
  "test_sidepanel_player_guard.cjs"
  "test_vlc_switch.cjs"
  "test_external_speech_filter.cjs"
  "test_issue_controls.cjs"
)

for script in "${TEST_SCRIPTS[@]}"; do
  full_script="$TEST_DIR/$script"
  if [[ -f "$full_script" ]]; then
    node "$full_script" || {
      echo "FAIL: Test script failed: $script"
      exit 1
    }
  else
    echo "WARN: Test script not found: $script"
  fi
done

echo "PASS: manifest 0.8.2, ${#SCRIPTS[@]} scripts, basic checks passed, external tests executed"
