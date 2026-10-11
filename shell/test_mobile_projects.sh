#!/bin/bash
# test_mobile_projects.py — portiert nach shell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_mobile_projects.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(realpath "$SCRIPT_DIR/../..")"
IOS="$ROOT/mobile/ios"
ANDROID="$ROOT/mobile/android"
SHARED="$ROOT/plugin-source/mobile-shared/webview-bridge.js"

# Function to check condition and exit with error message if false
require() {
    local condition=$1
    local message=$2
    if ! eval "$condition"; then
        echo "Assertion failed: $message" >&2
        exit 1
    fi
}

# Android checks
if [[ -d "$ANDROID" ]]; then
    MANIFEST="$ANDROID/app/src/main/AndroidManifest.xml"
    GRADLE="$ANDROID/app/build.gradle.kts"
    ANDROID_WEBVIEW="$ANDROID/app/src/main/java/app/tiktoklivecompanion/CompanionWebView.kt"
    ANDROID_BRIDGE_COPY="$ANDROID/app/src/main/res/raw/webview_bridge.js"
    AAR_LIBS=("$ANDROID/app/libs"/*.aar)

    # Check Gradle file contents
    require 'grep -q "minSdk = 21" "$GRADLE"' "Android version contract"
    require 'grep -q "versionName = \"0.8.2\"" "$GRADLE"' "Android version contract"

    # Check Manifest for cleartext traffic setting
    require 'grep -q "usesCleartextTraffic=\"false\"" "$MANIFEST"' "Android cleartext must be disabled"

    # Check WebView implementation security
    require '! grep -q "addJavascriptInterface" "$ANDROID_WEBVIEW"' "insecure Android JavaScript interface"
    require 'grep -q "addWebMessageListener" "$ANDROID_WEBVIEW" && grep -q "ALLOWED_ORIGIN" "$ANDROID_WEBVIEW"' "origin-restricted Android bridge"

    # Ensure no .aar files are committed
    if [[ ${#AAR_LIBS[@]} -gt 0 ]] && [[ -f "${AAR_LIBS[0]}" ]]; then
        echo "ShazamKit AAR must not be committed" >&2
        exit 1
    fi

    # Compare shared JS file with Android copy
    require 'cmp -s "$SHARED" "$ANDROID_BRIDGE_COPY"' "Android bridge copy drift"
fi

# iOS checks
if [[ -d "$IOS" ]]; then
    IOS_WEBVIEW="$IOS/TikTokLiveCompanion/CompanionWebView.swift"
    PBX="$IOS/TikTokLiveCompanion.xcodeproj/project.pbxproj"
    IOS_BRIDGE_COPY="$IOS/Resources/webview-bridge.js"
    INFO_PLIST="$IOS/TikTokLiveCompanion/Info.plist"

    # Check iOS webview restrictions
    require 'grep -q "forMainFrameOnly: false" "$IOS_WEBVIEW" && grep -q "securityOrigin.host == \"www.tiktok.com\"" "$IOS_WEBVIEW"' "origin-restricted iOS subframe bridge"

    # Check project settings
    require 'grep -q "MARKETING_VERSION = 0.8.2" "$PBX" && grep -q "IPHONEOS_DEPLOYMENT_TARGET = 15.0" "$PBX"' "iOS version contract"

    # Check source memberships
    require 'grep -q "StreamNameNormalizer.swift in Sources" "$PBX" && grep -q "StreamNameNormalizerTests.swift in Sources" "$PBX" && grep -q "MobileUIStructureTests.swift in Sources" "$PBX"' "iOS source and XCTest membership"

    # Compare shared JS file with iOS copy
    require 'cmp -s "$SHARED" "$IOS_BRIDGE_COPY"' "iOS bridge copy drift"

    # Parse Info.plist and verify version
    INFO_VERSION=$(plutil -extract CFBundleShortVersionString raw "$INFO_PLIST" 2>/dev/null || true)
    require '[[ "$INFO_VERSION" == "0.8.2" ]]' "iOS plist version"
fi

# Check that no Apple private keys are committed
P8_FILES=$(find "$ROOT" -type f -name "*.p8" -print 2>/dev/null || true)
if [[ -n "$P8_FILES" ]]; then
    echo "Apple private key must not be committed" >&2
    exit 1
fi

# Schema validation
SCHEMA_FILE="$ROOT/plugin-source/mobile-shared/recognition-result.schema.json"
SOURCE_ENUM=$(jq -r '.properties.source.enum | join(",")' "$SCHEMA_FILE" 2>/dev/null || echo "")
require '[[ "$SOURCE_ENUM" == "microphone,webview" ]]' "recognition source schema"

echo "PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions"
