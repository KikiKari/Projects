#!/usr/bin/env pwsh
# test_mobile_projects.py — portiert nach powershell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_mobile_projects.py
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

# Define paths
$ROOT = Resolve-Path "$PSScriptRoot/../../"
$IOS = "$ROOT/mobile/ios"
$ANDROID = "$ROOT/mobile/android"
$SHARED = "$ROOT/plugin-source/mobile-shared/webview-bridge.js"

function Require {
    param (
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        throw $Message
    }
}

if (Test-Path $ANDROID) {
    $manifest = Get-Content -Path "$ANDROID/app/src/main/AndroidManifest.xml" -Encoding Utf8
    $gradle = Get-Content -Path "$ANDROID/app/build.gradle.kts" -Encoding Utf8
    $android_webview = Get-Content -Path "$ANDROID/app/src/main/java/app/tiktoklivecompanion/CompanionWebView.kt" -Encoding Utf8
    Require ('minSdk = 21' -in $gradle -and 'versionName = "0.8.2"' -in $gradle) "Android version contract"
    Require ('usesCleartextTraffic="false"' -in $manifest) "Android cleartext must be disabled"
    Require ("addJavascriptInterface" -notin $android_webview) "insecure Android JavaScript interface"
    Require (("addWebMessageListener" -in $android_webview) -and ("ALLOWED_ORIGIN" -in $android_webview)) "origin-restricted Android bridge"
    $aarFiles = Get-ChildItem -Path "$ANDROID/app/libs" -Filter "*.aar" -ErrorAction SilentlyContinue
    Require (-not $aarFiles) "ShazamKit AAR must not be committed"
    $sharedBytes = Get-Content -Path $SHARED -Raw -Encoding Byte
    $androidBridgeBytes = Get-Content -Path "$ANDROID/app/src/main/res/raw/webview_bridge.js" -Raw -Encoding Byte
    Require ([System.Linq.Enumerable]::SequenceEqual($sharedBytes, $androidBridgeBytes)) "Android bridge copy drift"
}

if (Test-Path $IOS) {
    $ios_webview = Get-Content -Path "$IOS/TikTokLiveCompanion/CompanionWebView.swift" -Encoding Utf8
    $pbx = Get-Content -Path "$IOS/TikTokLiveCompanion.xcodeproj/project.pbxproj" -Encoding Utf8
    Require (('forMainFrameOnly: false' -in $ios_webview) -and ('securityOrigin.host == "www.tiktok.com"' -in $ios_webview)) "origin-restricted iOS subframe bridge"
    Require (('MARKETING_VERSION = 0.8.2' -in $pbx) -and ('IPHONEOS_DEPLOYMENT_TARGET = 15.0' -in $pbx)) "iOS version contract"
    $requiredNames = @("StreamNameNormalizer.swift in Sources", "StreamNameNormalizerTests.swift in Sources", "MobileUIStructureTests.swift in Sources")
    $allFound = $true
    foreach ($name in $requiredNames) {
        if ($pbx -notcontains $name) {
            $allFound = $false
            break
        }
    }
    Require $allFound "iOS source and XCTest membership"
    $sharedBytes = Get-Content -Path $SHARED -Raw -Encoding Byte
    $iosBridgeBytes = Get-Content -Path "$IOS/Resources/webview-bridge.js" -Raw -Encoding Byte
    Require ([System.Linq.Enumerable]::SequenceEqual($sharedBytes, $iosBridgeBytes)) "iOS bridge copy drift"
    $info = plutil -convert json -o - "$IOS/TikTokLiveCompanion/Info.plist" | ConvertFrom-Json
    Require ($info.CFBundleShortVersionString -eq "0.8.2") "iOS plist version"
}

$p8Files = Get-ChildItem -Recurse -Path $ROOT -Filter "*.p8" -ErrorAction SilentlyContinue
Require (-not $p8Files) "Apple private key must not be committed"

$schemaContent = Get-Content -Path "$ROOT/plugin-source/mobile-shared/recognition-result.schema.json" -Encoding Utf8
$schema = $schemaContent | ConvertFrom-Json
Require (($schema.properties.source.enum -join ',') -eq 'microphone,webview') "recognition source schema"
Write-Output "PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions"
