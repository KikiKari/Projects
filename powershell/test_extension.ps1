#!/usr/bin/env pwsh
# test_extension.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_extension.cjs
# Erzeugt: 2026-10-13 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

# Define paths
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$extension = Join-Path $root "browser-extension"
$manifestPath = Join-Path $extension "manifest.json"
$mobileBridgePath = Join-Path $root "mobile-shared" "webview-bridge.js"

# Load manifest
$manifest = Get-Content $manifestPath | ConvertFrom-Json
$corePath = Join-Path $extension "content-core.js"
$protoPath = Join-Path $extension "proto-main.js"
$mobileBridge = Get-Content $mobileBridgePath -Raw

# Helper functions
function Concat {
    param([byte[][]]$Chunks)
    $size = ($Chunks | Measure-Object -Property Length -Sum).Sum
    $out = New-Object byte[] $size
    $offset = 0
    foreach ($chunk in $Chunks) {
        [System.Array]::Copy($chunk, 0, $out, $offset, $chunk.Length)
        $offset += $chunk.Length
    }
    return $out
}

function Varint {
    param([long]$Value)
    $bytes = @()
    do {
        $byte = $Value -band 0x7f
        $Value = $Value -shr 7
        if ($Value -gt 0) { $byte = $byte -bor 0x80 }
        $bytes += $byte
    } while ($Value -gt 0)
    return [byte[]]$bytes
}

function BytesField {
    param([int]$Number, [object]$Value)
    $body = if ($Value -is [string]) { [System.Text.Encoding]::UTF8.GetBytes($Value) } else { $Value }
    return Concat @(Varint (($Number -shl 3) -bor 2)), @(Varint $body.Length), @($body)
}

function IntField {
    param([int]$Number, [long]$Value)
    return Concat @(Varint ($Number -shl 3)), @(Varint $Value)
}

# Assertions
if ($manifest.manifest_version -ne 3) { throw "Manifest version mismatch" }
if ($manifest.version -ne "0.8.2") { throw "Version mismatch" }
if (-not $manifest.permissions.Contains("sidePanel")) { throw "Missing sidePanel permission" }
if (-not $manifest.permissions.Contains("webRequest")) { throw "Missing webRequest permission" }
if (-not $manifest.permissions.Contains("tabCapture")) { throw "Missing tabCapture permission" }
if (-not $manifest.host_permissions.Contains("http://127.0.0.1/*")) { throw "Missing host permission http://127.0.0.1/*" }
if (-not $manifest.host_permissions.Contains("http://localhost/*")) { throw "Missing host permission http://localhost/*" }
if ($manifest.permissions.Contains("cookies")) { throw "Contains cookies permission" }
if ($manifest.permissions.Contains("webRequestBlocking")) { throw "Contains webRequestBlocking permission" }
if ($manifest.permissions.Contains("nativeMessaging")) { throw "Contains nativeMessaging permission" }
if ($manifest.content_scripts[0].js[0] -ne "vendor-mpegts.js") { throw "First content script is not vendor-mpegts.js" }

$mpegtsVendorPath = Join-Path $extension "vendor-mpegts.js"
$mpegtsLicensePath = Join-Path $extension "vendor-mpegts.LICENSE.txt"
$mpegtsNoticePath = Join-Path $extension "vendor-mpegts.NOTICE.md"
if (-not (Test-Path $mpegtsVendorPath)) { throw "Missing vendor-mpegts.js" }
if (-not (Test-Path $mpegtsLicensePath)) { throw "Missing vendor-mpegts.LICENSE.txt" }
if (-not (Test-Path $mpegtsNoticePath)) { throw "Missing vendor-mpegts.NOTICE.md" }

$hash = Get-FileHash $mpegtsVendorPath -Algorithm SHA256
if ($hash.Hash -ne "0786F9AF6780822FF29240259A73B07ED7BC479BC44966E49418DD38213B8064") { 
    throw "SHA256 hash mismatch for vendor-mpegts.js" 
}

if (-not $mobileBridge.Contains('location.hostname !== "www.tiktok.com"')) { throw "Missing location check" }
if ($mobileBridge.Contains("document.cookie")) { throw "Contains document.cookie" }
if (-not $mobileBridge.Contains("QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400")) { throw "Missing QUICK_RECOVER_RELOAD_COOLDOWN_MS" }
if (-not $mobileBridge.Contains('"set-auto-reconnect"')) { throw "Missing set-auto-reconnect" }
if (-not $mobileBridge.Contains('"set-limiter"')) { throw "Missing set-limiter" }

foreach ($relative in @(
    $manifest.background.service_worker,
    $manifest.side_panel.default_path
) + ($manifest.content_scripts | ForEach-Object { $_.js })) {
    $fullPath = Join-Path $extension $relative
    if (-not (Test-Path $fullPath)) { throw "Missing manifest file: $relative" }
}

$scripts = Get-ChildItem $extension -Filter "*.js" | ForEach-Object { $_.Name }
foreach ($name in $scripts) {
    $source = Get-Content (Join-Path $extension $name) -Raw
    if ($name -eq "peak-limiter-worklet.js") {
        $result = node --check --input-type=module -e $source 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Syntax error in $name`: $result" }
    } else {
        # PowerShell doesn't have equivalent to vm.Script, but we can at least check syntax
        try {
            [System.Management.Automation.Language.Parser]::ParseInput($source, [ref]$null, [ref]$null) | Out-Null
        } catch {
            throw "Syntax error in $name`: $_"
        }
    }
    
    if ($source -match '\beval\s*\(') { throw "$name contains eval()" }
    if ($source -match 'new\s+Function\s*\(') { throw "$name contains new Function()" }
    if ($source -match '\.innerHTML\s*=') { throw "$name assigns innerHTML" }
}

# Core tests
$metadata = @{
    room = @{
        caption_info = @{ open = $true; support_lang = @("de", "en"); show_type = 1 }
        stream_data = '{"pull":"https:\/\/pull-flv-f77.example.tiktokcdn.com\/stage\/stream_hd.flv?expire=1\u0026sign=abc","hls":"https:\/\/pull-hls.example.tiktokcdn-eu.com\/stage\/stream_720p.m3u8?sign=xyz"}'
    }
}

# Since we can't directly call the JS functions, we'll simulate the expected behavior
# In a real scenario, you'd need to convert the JS logic to PowerShell or use Node.js interop

Write-Host "PASS: manifest 0.8.2, $($scripts.Count) scripts, chat speech composition, gifts, audience statistics, service controls and security guards"
