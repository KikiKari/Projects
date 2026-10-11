#!/usr/bin/env pwsh
# test_mobile_projects.py — portiert nach powershell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_mobile_projects.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

$ROOT = Resolve-Path "$PSScriptRoot/../.."
$IOS = Join-Path $ROOT "mobile/ios"
$ANDROID = Join-Path $ROOT "mobile/android"
$SHARED = Join-Path $ROOT "plugin-source/mobile-shared/webview-bridge.js"

function Require {
    param(
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        throw $Message
    }
}

if (Test-Path $ANDROID) {
    $manifest = Get-Content -Path (Join-Path $ANDROID "app/src/main/AndroidManifest.xml") -Encoding UTF8
    $gradle = Get-Content -Path (Join-Path $ANDROID "app/build.gradle.kts") -Encoding UTF8
    $android_webview = Get-Content -Path (Join-Path $ANDROID "app/src/main/java/app/tiktoklivecompanion/CompanionWebView.kt") -Encoding UTF8
    Require ('minSdk = 21' -in $gradle -and 'versionName = "0.8.2"' -in $gradle) "Android version contract"
    Require ('usesCleartextTraffic="false"' -in $manifest) "Android cleartext must be disabled"
    Require ("addJavascriptInterface" -notin $android_webview) "insecure Android JavaScript interface"
    Require ("addWebMessageListener" -in $android_webview -and "ALLOWED_ORIGIN" -in $android_webview) "origin-restricted Android bridge"
    Require (-not (Get-ChildItem -Path (Join-Path $ANDROID "app/libs") -Filter "*.aar")) "ShazamKit AAR must not be committed"
    Require ((Get-Content -Path $SHARED -Raw) -eq (Get-Content -Path (Join-Path $ANDROID "app/src/main/res/raw/webview_bridge.js") -Raw)) "Android bridge copy drift"
}

if (Test-Path $IOS) {
    $ios_webview = Get-Content -Path (Join-Path $IOS "TikTokLiveCompanion/CompanionWebView.swift") -Encoding UTF8
    $pbx = Get-Content -Path (Join-Path $IOS "TikTokLiveCompanion.xcodeproj/project.pbxproj") -Encoding UTF8
    Require ("forMainFrameOnly: false" -in $ios_webview -and "securityOrigin.host == `"www.tiktok.com`"" -in $ios_webview) "origin-restricted iOS subframe bridge"
    Require ("MARKETING_VERSION = 0.8.2" -in $pbx -and "IPHONEOS_DEPLOYMENT_TARGET = 15.0" -in $pbx) "iOS version contract"
    Require (@("StreamNameNormalizer.swift in Sources", "StreamNameNormalizerTests.swift in Sources", "MobileUIStructureTests.swift in Sources") | ForEach-Object { $_ -in $pbx }) "iOS source and XCTest membership"
    Require ((Get-Content -Path $SHARED -Raw) -eq (Get-Content -Path (Join-Path $IOS "Resources/webview-bridge.js") -Raw)) "iOS bridge copy drift"
    
    $info = Get-Content -Path (Join-Path $IOS "TikTokLiveCompanion/Info.plist") -Raw | ConvertFrom-Json
    Require ($info.CFBundleShortVersionString -eq "0.8.2") "iOS plist version"
}

Require (-not (Get-ChildItem -Recurse -Path $ROOT -Filter "*.p8")) "Apple private key must not be committed"

$schema = Get-Content -Path (Join-Path $ROOT "plugin-source/mobile-shared/recognition-result.schema.json") -Raw | ConvertFrom-Json
Require ($schema.properties.source.enum -eq @("microphone", "webview")) "recognition source schema"
Write-Host "PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions"
