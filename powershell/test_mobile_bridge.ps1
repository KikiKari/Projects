#!/usr/bin/env pwsh
# test_mobile_bridge.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_bridge.cjs
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

# Define paths
$root = Join-Path $PSScriptRoot ".."
$bridgePath = Join-Path $root "mobile-shared" "webview-bridge.js"

# Read the source file
$source = Get-Content -Path $bridgePath -Raw -Encoding UTF8

# Validate that the script compiles without error by using Invoke-Expression in a safe context
try {
    $null = [System.Management.Automation.Language.Parser]::ParseInput($source, [ref]$null, [ref]$null)
} catch {
    throw "Syntax error in webview-bridge.js: $_"
}

# Perform assertions on content inclusion/exclusion
function Assert-Includes {
    param ([string]$content, [string]$expected)
    if (-not $content.Contains($expected)) {
        throw "Assertion failed: Expected to find '$expected' in source."
    }
}

function Assert-NotIncludes {
    param ([string]$content, [string]$unexpected)
    if ($content.Contains($unexpected)) {
        throw "Assertion failed: Unexpected content found '$unexpected' in source."
    }
}

Assert-Includes $source 'location.hostname !== "www.tiktok.com"'
Assert-Includes $source "root.top === root"
Assert-Includes $source "if (!isTop) return"
Assert-Includes $source "MAX_MESSAGE_BYTES = 64 * 1024"
Assert-Includes $source "MAX_AUDIO_SECONDS = 12"
Assert-Includes $source "QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400"
Assert-Includes $source "ALLOWED_COMMANDS"
Assert-Includes $source '"set-auto-reconnect"'
Assert-Includes $source '"set-limiter"'
Assert-Includes $source '"scan-recommendations"'
Assert-Includes $source '"cancel-recommendation-scan"'
Assert-Includes $source "MAX_MEDIA_URLS = 12"
Assert-Includes $source "const mediaUrls = new Map()"
Assert-Includes $source 'emit("media-url"'
Assert-Includes $source "addEventListener(`"message`""
Assert-NotIncludes $source ".send ="
Assert-NotIncludes $source "document.cookie"
Assert-NotIncludes $source "localStorage"
Assert-Includes $source 'FORCE_RETURN_KEY = "tlc-force-return"'
Assert-Includes $source "sessionStorage.getItem(FORCE_RETURN_KEY)"
Assert-NotIncludes $source "sessionStorage.clear"
Assert-NotIncludes $source "innerHTML"

# Check copies match original
$copies = @(
    (Join-Path $root ".." "mobile" "ios" "Resources" "webview-bridge.js"),
    (Join-Path $root ".." "mobile" "android" "app" "src" "main" "res" "raw" "webview_bridge.js")
)

foreach ($copy in $copies) {
    $copyContent = Get-Content -Path $copy -Raw -Encoding UTF8
    if ($copyContent -ne $source) {
        throw "Bridge copy drifted: $copy"
    }
}

Write-Host "PASS: mobile bridge origin, main-frame, size, command, audio-duration and storage guards"
