#!/usr/bin/env pwsh
# test_mobile_projects.py — portiert nach powershell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

$ROOT = Resolve-Path "$PSScriptRoot/../../.."
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
    $manifest = Get-Content -Path (Join-Path $ANDROID "app/src/main/AndroidManifest.xml") -Encoding Utf8
    $gradle = Get-Content -Path (Join-Path $ANDROID "app/build.gradle.kts") -Encoding Utf8
    $android_webview = Get-Content -Path (Join-Path $ANDROID "app/src/main/java/app/tiktoklivecompanion/CompanionWebView.kt") -Encoding Utf8
    
    Require ('minSdk = 21' -in $gradle -and 'versionName = "0.8.0"' -in $gradle) "Android version contract"
    Require ('usesCleartextTraffic="false"' -in $manifest) "Android cleartext must be disabled"
    Require ("addJavascriptInterface" -notin $android_webview) "insecure Android JavaScript interface"
    Require ("addWebMessageListener" -in $android_webview -and "ALLOWED_ORIGIN" -in $android_webview) "origin-restricted Android bridge"
    
    $aarFiles = Get-ChildItem -Path (Join-Path $ANDROID "app/libs") -Filter "*.aar" -ErrorAction SilentlyContinue
    Require (-not $aarFiles) "ShazamKit AAR must not be committed"
    
    $androidBridge = Get-Content -Path (Join-Path $ANDROID "app/src/main/res/raw/webview_bridge.js") -AsByteStream -Raw
    $sharedBytes = Get-Content -Path $SHARED -AsByteStream -Raw
    Require ($sharedBytes -ceq $androidBridge) "Android bridge copy drift"
}

if (Test-Path $IOS) {
    $ios_webview = Get-Content -Path (Join-Path $IOS "TikTokLiveCompanion/CompanionWebView.swift") -Encoding Utf8
    $pbx = Get-Content -Path (Join-Path $IOS "TikTokLiveCompanion.xcodeproj/project.pbxproj") -Encoding Utf8
    
    Require ("forMainFrameOnly: false" -in $ios_webview -and "securityOrigin.host == `"www.tiktok.com`"" -in $ios_webview) "origin-restricted iOS subframe bridge"
    Require ("MARKETING_VERSION = 0.8.0" -in $pbx -and "IPHONEOS_DEPLOYMENT_TARGET = 15.0" -in $pbx) "iOS version contract"
    
    $requiredNames = @("StreamNameNormalizer.swift in Sources", "StreamNameNormalizerTests.swift in Sources", "MobileUIStructureTests.swift in Sources")
    $allPresent = $true
    foreach ($name in $requiredNames) {
        if ($name -notin $pbx) {
            $allPresent = $false
            break
        }
    }
    Require $allPresent "iOS source and XCTest membership"
    
    $iosBridge = Get-Content -Path (Join-Path $IOS "Resources/webview-bridge.js") -AsByteStream -Raw
    $sharedBytes = Get-Content -Path $SHARED -AsByteStream -Raw
    Require ($sharedBytes -ceq $iosBridge) "iOS bridge copy drift"
    
    $infoPlistPath = Join-Path $IOS "TikTokLiveCompanion/Info.plist"
    $info = ConvertFrom-StringData (Get-Content -Path $infoPlistPath -Raw | ForEach-Object { $_ -replace '^.*?=\s*', '' })
    Require ($info["CFBundleShortVersionString"] -eq "0.8.0") "iOS plist version"
}

$p8Files = Get-ChildItem -Path $ROOT -Recurse -Filter "*.p8" -ErrorAction SilentlyContinue
Require (-not $p8Files) "Apple private key must not be committed"

$schemaContent = Get-Content -Path (Join-Path $ROOT "plugin-source/mobile-shared/recognition-result.schema.json") -Encoding Utf8
$schema = $schemaContent | ConvertFrom-Json
Require (($schema.properties.source.enum -join ",") -eq "microphone,webview") "recognition source schema"

Write-Host "PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions"
