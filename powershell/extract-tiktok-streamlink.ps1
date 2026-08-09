#!/usr/bin/env pwsh
# extract-tiktok-streamlink.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)][string]$Username,
    [string]$Quality = "best",
    [string]$JsonFlag = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$TIMESTAMP = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

function Emit-Json {
    param(
        [string[]]$Values
    )
    $keys = @("success", "method", "username", "url", "quality", "author", "title", "error", "timestamp", "status")
    $payload = @{}
    for ($i = 0; $i -lt [Math]::Min($keys.Length, $Values.Length); $i++) {
        if ($Values[$i] -ne "") {
            $payload[$keys[$i]] = $Values[$i]
        }
    }
    if ($payload.ContainsKey("success")) {
        $payload["success"] = $payload["success"].ToLower() -eq "true"
    }
    $json = $payload | ConvertTo-Json -Compress
    Write-Error $json
}

if ($Username -notmatch "^[A-Za-z0-9._]{1,24}$") {
    Write-Error "Invalid TikTok username" -ErrorAction Stop
    exit 64
}

if ($Quality -notmatch "^(best|worst|original|1080p60|720p60|720p|540p|360p|auto)$") {
    Write-Error "Invalid stream quality" -ErrorAction Stop
    exit 64
}

$LOAD_PER_CPU = (Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average / 100
$MAX_LOAD = if ($env:TIKTOK_MAX_LOAD_PER_CPU) { $env:TIKTOK_MAX_LOAD_PER_CPU } else { 1.5 }
if ($LOAD_PER_CPU -gt $MAX_LOAD) {
    Emit-Json @("false", "streamlink", $Username, "", $Quality, "", "", "host overloaded", $TIMESTAMP, "overloaded")
    exit 75
}

$streamlinkPath = Get-Command streamlink -ErrorAction SilentlyContinue
if (-not $streamlinkPath) {
    Emit-Json @("false", "streamlink", $Username, "", $Quality, "", "", "streamlink not installed", $TIMESTAMP, "dependency_missing")
    exit 2
}

$LIVE_URL = "https://www.tiktok.com/@${Username}/live"
switch ($Quality) {
    "original" { $SELECTOR = "origin,uhd_60,hd_60,hd,sd,ld,best,worst" }
    "auto" { $SELECTOR = "best,origin,uhd_60,hd_60,hd,sd,ld,worst" }
    "1080p60" { $SELECTOR = "uhd_60,hd_60,hd,sd,ld,worst" }
    "720p60" { $SELECTOR = "hd_60,hd,sd,ld,worst" }
    "720p" { $SELECTOR = "hd,sd,ld,worst" }
    "540p" { $SELECTOR = "sd,ld,worst" }
    "360p" { $SELECTOR = "ld,worst" }
    default { $SELECTOR = $Quality }
}

$OUTPUT = streamlink --json "$LIVE_URL" "$SELECTOR" 2>$null
$EXIT_CODE = $LASTEXITCODE
if ($EXIT_CODE -ne 0 -or -not $OUTPUT) {
    $URL = streamlink --stream-url "$LIVE_URL" "$SELECTOR" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $URL) {
        Emit-Json @("false", "streamlink", $Username, "", $Quality, "", "", "streamlink failed or no stream found", $TIMESTAMP, "offline")
        exit 1
    }
    if ($JsonFlag -eq "--json") {
        Emit-Json @("true", "streamlink", $Username, $URL, $Quality, "", "", "", $TIMESTAMP, "live")
    } else {
        Write-Output $URL
    }
    exit 0
}

try {
    $data = $OUTPUT | ConvertFrom-Json
    $url = $data.url
    $streams = $data.streams
    if (-not $url -and $streams -is [System.Collections.Hashtable]) {
        foreach ($key in @("best", "worst") + $streams.Keys) {
            $value = $streams.$key
            if ($value -is [System.Collections.Hashtable] -and $value.url) {
                $url = $value.url
                break
            }
        }
    }
    $metadata = $data.metadata
    $author = if ($metadata) { $metadata.author } else { "" }
    $title = if ($metadata) { $metadata.title } else { "" }
    $PARSED = @{
        url = $url
        author = $author
        title = $title
    } | ConvertTo-Json -Compress
} catch {
    Emit-Json @("false", "streamlink", $Username, "", $Quality, "", "", "invalid streamlink JSON", $TIMESTAMP, "technical_error")
    exit 2
}

$PARSED_OBJ = $PARSED | ConvertFrom-Json
$URL = $PARSED_OBJ.url
$AUTHOR = $PARSED_OBJ.author
$TITLE = $PARSED_OBJ.title

if (-not $URL) {
    Emit-Json @("false", "streamlink", $Username, "", $Quality, $AUTHOR, $TITLE, "could not extract stream URL", $TIMESTAMP, "offline")
    exit 1
}

if ($JsonFlag -eq "--json") {
    Emit-Json @("true", "streamlink", $Username, $URL, $Quality, $AUTHOR, $TITLE, "", $TIMESTAMP, "live")
} else {
    Write-Output $URL
}
