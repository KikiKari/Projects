#!/bin/bash
# test_mobile_projects.py — portiert nach shell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_mobile_projects.py
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

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
    if [[ $condition -eq 0 ]]; then
        echo "AssertionError: $message" >&2
        exit 1
    fi
}

# Android checks
if [[ -d "$ANDROID" ]]; then
    MANIFEST="$ANDROID/app/src/main/AndroidManifest.xml"
    GRADLE="$ANDROID/app/build.gradle.kts"
    ANDROID_WEBVIEW="$ANDROID/app/src/main/java/app/tiktoklivecompanion/CompanionWebView.kt"
    BRIDGE_JS="$ANDROID/app/src/main/res/raw/webview_bridge.js"
    AAR_LIBS=("$ANDROID/app/libs"/*.aar)

    # Check Gradle file contents
    if ! grep -q 'minSdk = 21' "$GRADLE" || ! grep -q 'versionName = "0.8.2"' "$GRADLE"; then
        require 0 "Android version contract"
    fi

    # Check Manifest content
    if ! grep -q 'usesCleartextTraffic="false"' "$MANIFEST"; then
        require 0 "Android cleartext must be disabled"
    fi

    # Check WebView security settings
    if grep -q "addJavascriptInterface" "$ANDROID_WEBVIEW"; then
        require 0 "insecure Android JavaScript interface"
    fi

    if ! grep -q "addWebMessageListener" "$ANDROID_WEBVIEW" || ! grep -q "ALLOWED_ORIGIN" "$ANDROID_WEBVIEW"; then
        require 0 "origin-restricted Android bridge"
    fi

    # Ensure no .aar files are committed
    if compgen -G "$ANDROID/app/libs/*.aar" > /dev/null; then
        require 0 "ShazamKit AAR must not be committed"
    fi

    # Compare shared JS file with Android copy
    if ! cmp --silent "$SHARED" "$BRIDGE_JS"; then
        require 0 "Android bridge copy drift"
    fi
fi

# iOS checks
if [[ -d "$IOS" ]]; then
    IOS_WEBVIEW="$IOS/TikTokLiveCompanion/CompanionWebView.swift"
    PBXPROJ="$IOS/TikTokLiveCompanion.xcodeproj/project.pbxproj"
    IOS_BRIDGE_JS="$IOS/Resources/webview-bridge.js"
    INFO_PLIST="$IOS/TikTokLiveCompanion/Info.plist"

    # Check WebView security settings
    if ! grep -q "forMainFrameOnly: false" "$IOS_WEBVIEW" || ! grep -q 'securityOrigin.host == "www.tiktok.com"' "$IOS_WEBVIEW"; then
        require 0 "origin-restricted iOS subframe bridge"
    fi

    # Check project settings
    if ! grep -q "MARKETING_VERSION = 0.8.2" "$PBXPROJ" || ! grep -q "IPHONEOS_DEPLOYMENT_TARGET = 15.0" "$PBXPROJ"; then
        require 0 "iOS version contract"
    fi

    # Check source memberships
    for name in "StreamNameNormalizer.swift in Sources" "StreamNameNormalizerTests.swift in Sources" "MobileUIStructureTests.swift in Sources"; do
        if ! grep -q "$name" "$PBXPROJ"; then
            require 0 "iOS source and XCTest membership"
        fi
    done

    # Compare shared JS file with iOS copy
    if ! cmp --silent "$SHARED" "$IOS_BRIDGE_JS"; then
        require 0 "iOS bridge copy drift"
    fi

    # Check Info.plist version
    PLIST_VERSION=$(plutil -extract CFBundleShortVersionString raw "$INFO_PLIST" 2>/dev/null || echo "")
    if [[ "$PLIST_VERSION" != "0.8.2" ]]; then
        require 0 "iOS plist version"
    fi
fi

# Check for Apple private keys
if find "$ROOT" -type f -name "*.p8" | grep -q .; then
    require 0 "Apple private key must not be committed"
fi

# Schema validation
SCHEMA_FILE="$ROOT/plugin-source/mobile-shared/recognition-result.schema.json"
SOURCE_ENUM=$(jq -r '.properties.source.enum[]' "$SCHEMA_FILE" 2>/dev/null || echo "")

if [[ "$SOURCE_ENUM" != $'microphone\nwebview' ]]; then
    require 0 "recognition source schema"
fi

echo "PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions"
