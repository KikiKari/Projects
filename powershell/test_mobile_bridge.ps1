#!/usr/bin/env pwsh
# test_mobile_bridge.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_mobile_bridge.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

# Define paths
$root = Join-Path $PSScriptRoot ".."
$bridgePath = Join-Path $root "mobile-shared" "webview-bridge.js"

# Read the source file
$source = Get-Content -Path $bridgePath -Raw -Encoding UTF8

# Validate that the source can be parsed as JavaScript by attempting to create a script block
try {
    [ScriptBlock]::Create($source) | Out-Null
} catch {
    throw "Failed to parse JavaScript source: $_"
}

# Assertions to check for specific strings in the source
Assert-True ($source -like '*location.hostname !== "www.tiktok.com"*') "Missing location.hostname check"
Assert-True ($source -like '*root.top === root*') "Missing root.top check"
Assert-True ($source -like '*if (!isTop) return*') "Missing isTop guard"
Assert-True ($source -like '*MAX_MESSAGE_BYTES = 64 * 1024*') "Missing MAX_MESSAGE_BYTES definition"
Assert-True ($source -like '*MAX_AUDIO_SECONDS = 12*') "Missing MAX_AUDIO_SECONDS definition"
Assert-True ($source -like '*QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400*') "Missing QUICK_RECOVER_RELOAD_COOLDOWN_MS definition"
Assert-True ($source -like '*ALLOWED_COMMANDS*') "Missing ALLOWED_COMMANDS reference"
Assert-True ($source -like '*"set-auto-reconnect"*') "Missing set-auto-reconnect command"
Assert-True ($source -like '*"set-limiter"*') "Missing set-limiter command"
Assert-True ($source -like '*"scan-recommendations"*') "Missing scan-recommendations command"
Assert-True ($source -like '*"cancel-recommendation-scan"*') "Missing cancel-recommendation-scan command"
Assert-True ($source -like '*MAX_MEDIA_URLS = 12*') "Missing MAX_MEDIA_URLS definition"
Assert-True ($source -like '*const mediaUrls = new Map()*') "Missing mediaUrls Map declaration"
Assert-True ($source -like '*emit("media-url"*') "Missing emit media-url call"
Assert-True ($source -like '*addEventListener("message"*') "Missing addEventListener message"
Assert-False ($source -like '*.send =*') "Found forbidden .send assignment"
Assert-False ($source -like '*document.cookie*') "Found forbidden document.cookie usage"
Assert-False ($source -like '*localStorage*') "Found forbidden localStorage usage"
Assert-True ($source -like '*FORCE_RETURN_KEY = "tlc-force-return"*') "Missing FORCE_RETURN_KEY definition"
Assert-True ($source -like '*sessionStorage.getItem(FORCE_RETURN_KEY)*') "Missing sessionStorage.getItem usage"
Assert-False ($source -like '*sessionStorage.clear*') "Found forbidden sessionStorage.clear usage"
Assert-False ($source -like '*innerHTML*') "Found forbidden innerHTML usage"

# Check copies of the bridge file
$copies = @(
    Join-Path $root ".." "mobile" "ios" "Resources" "webview-bridge.js"
    Join-Path $root ".." "mobile" "android" "app" "src" "main" "res" "raw" "webview_bridge.js"
)

foreach ($copy in $copies) {
    $copyContent = Get-Content -Path $copy -Raw -Encoding UTF8
    Assert-True ($copyContent -eq $source) "Bridge copy drifted: $copy"
}

Write-Host "PASS: mobile bridge origin, main-frame, size, command, audio-duration and storage guards"

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

function Assert-False([bool]$Condition, [string]$Message) {
    if ($Condition) {
        throw "Assertion failed: $Message"
    }
}
