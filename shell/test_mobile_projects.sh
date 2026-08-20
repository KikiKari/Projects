#!/bin/bash
# test_mobile_projects.py — portiert nach shell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Bestimme das Wurzelverzeichnis relativ zu diesem Skript
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(realpath "$SCRIPT_DIR/../..")"

# Pfade definieren
IOS="$ROOT/mobile/ios"
ANDROID="$ROOT/mobile/android"
SHARED="$ROOT/plugin-source/mobile-shared/webview-bridge.js"

# Hilfsfunktion zur Fehlerausgabe und Abbruch
require() {
    local condition=$1
    local message=$2
    if ! eval "$condition"; then
        echo "AssertionError: $message" >&2
        exit 1
    fi
}

# Android-Prüfungen
if [[ -d "$ANDROID" ]]; then
    MANIFEST="$ANDROID/app/src/main/AndroidManifest.xml"
    GRADLE="$ANDROID/app/build.gradle.kts"
    ANDROID_WEBVIEW="$ANDROID/app/src/main/java/app/tiktoklivecompanion/CompanionWebView.kt"
    ANDROID_BRIDGE_JS="$ANDROID/app/src/main/res/raw/webview_bridge.js"
    AAR_LIBS=("$ANDROID"/app/libs/*.aar)

    require "[[ -f '$MANIFEST' ]]" "AndroidManifest.xml nicht gefunden"
    require "[[ -f '$GRADLE' ]]" "build.gradle.kts nicht gefunden"
    require "[[ -f '$ANDROID_WEBVIEW' ]]" "CompanionWebView.kt nicht gefunden"

    # Prüfe Gradle-Einstellungen
    require "grep -q 'minSdk = 21' '$GRADLE'" "Android minSdk != 21"
    require "grep -q 'versionName = \"0.8.0\"' '$GRADLE'" "Android versionName != 0.8.0"

    # Prüfe Manifest
    require "grep -q 'usesCleartextTraffic=\"false\"' '$MANIFEST'" "Android cleartext traffic nicht deaktiviert"

    # Prüfe WebView-Sicherheit
    require "! grep -q 'addJavascriptInterface' '$ANDROID_WEBVIEW'" "Unsicheres addJavascriptInterface in Android WebView"
    require "grep -q 'addWebMessageListener' '$ANDROID_WEBVIEW'" "addWebMessageListener fehlt in Android WebView"
    require "grep -q 'ALLOWED_ORIGIN' '$ANDROID_WEBVIEW'" "ALLOWED_ORIGIN fehlt in Android WebView"

    # Prüfe AAR-Bibliotheken
    if [[ ${#AAR_LIBS[@]} -gt 0 ]] && [[ -f "${AAR_LIBS[0]}" ]]; then
        echo "Fehler: ShazamKit AAR darf nicht committed sein" >&2
        exit 1
    fi

    # Prüfe Synchronisation der Bridge-Datei
    require "[[ -f '$ANDROID_BRIDGE_JS' ]]" "Android Bridge JS nicht gefunden"
    require "cmp -s '$SHARED' '$ANDROID_BRIDGE_JS'" "Android Bridge-Kopie abweichend"
fi

# iOS-Prüfungen
if [[ -d "$IOS" ]]; then
    IOS_WEBVIEW="$IOS/TikTokLiveCompanion/CompanionWebView.swift"
    PBX="$IOS/TikTokLiveCompanion.xcodeproj/project.pbxproj"
    IOS_BRIDGE_JS="$IOS/Resources/webview-bridge.js"
    INFO_PLIST="$IOS/TikTokLiveCompanion/Info.plist"

    require "[[ -f '$IOS_WEBVIEW' ]]" "iOS CompanionWebView.swift nicht gefunden"
    require "[[ -f '$PBX' ]]" "iOS project.pbxproj nicht gefunden"
    require "[[ -f '$INFO_PLIST' ]]" "iOS Info.plist nicht gefunden"

    # Prüfe WebView-Einschränkungen
    require "grep -q 'forMainFrameOnly: false' '$IOS_WEBVIEW'" "iOS WebView forMainFrameOnly fehlt"
    require "grep -q 'securityOrigin.host == \"www.tiktok.com\"' '$IOS_WEBVIEW'" "iOS WebView Origin-Einschränkung fehlt"

    # Prüfe Projektversionen
    require "grep -q 'MARKETING_VERSION = 0.8.0' '$PBX'" "iOS MARKETING_VERSION != 0.8.0"
    require "grep -q 'IPHONEOS_DEPLOYMENT_TARGET = 15.0' '$PBX'" "iOS IPHONEOS_DEPLOYMENT_TARGET != 15.0"

    # Prüfe Dateizugehörigkeit im Xcode-Projekt
    require "grep -q 'StreamNameNormalizer.swift in Sources' '$PBX'" "StreamNameNormalizer.swift nicht in Xcode Sources"
    require "grep -q 'StreamNameNormalizerTests.swift in Sources' '$PBX'" "StreamNameNormalizerTests.swift nicht in Xcode Sources"
    require "grep -q 'MobileUIStructureTests.swift in Sources' '$PBX'" "MobileUIStructureTests.swift nicht in Xcode Sources"

    # Prüfe Synchronisation der Bridge-Datei
    require "[[ -f '$IOS_BRIDGE_JS' ]]" "iOS Bridge JS nicht gefunden"
    require "cmp -s '$SHARED' '$IOS_BRIDGE_JS'" "iOS Bridge-Kopie abweichend"

    # Prüfe Info.plist Version
    PLIST_VERSION=$(plutil -extract CFBundleShortVersionString raw "$INFO_PLIST" 2>/dev/null || true)
    require "[[ '$PLIST_VERSION' == '0.8.0' ]]" "iOS plist version != 0.8.0"
fi

# Prüfung auf Apple Private Keys
PRIVATE_KEYS=("$ROOT"/**/*.p8)
if [[ ${#PRIVATE_KEYS[@]} -gt 0 ]] && [[ -f "${PRIVATE_KEYS[0]}" ]]; then
    echo "Fehler: Apple Private Key darf nicht committed sein" >&2
    exit 1
fi

# Schema-Prüfung
SCHEMA_FILE="$ROOT/plugin-source/mobile-shared/recognition-result.schema.json"
require "[[ -f '$SCHEMA_FILE' ]]" "Schema-Datei nicht gefunden"

SOURCE_ENUM=$(jq -r '.properties.source.enum | join(",")' "$SCHEMA_FILE" 2>/dev/null || true)
require "[[ '$SOURCE_ENUM' == 'microphone,webview' ]]" "Recognition source enum falsch"

echo "PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions"
