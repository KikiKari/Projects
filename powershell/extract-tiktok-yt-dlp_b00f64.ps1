#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "31753f90b316fa53ac709cb6e945b5ab43ac90cabd4ed954da77cce0ae39b556", "source_sha256": "b00f64d55d344bbcc351ae7ade12137f0d9293b556aa0881ede43bef5bcb778b", "target_language": "powershell"}
# extract-tiktok-yt-dlp.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Bounded fallback used by the enhanced extractor. Temporary files are cleaned
# on every exit and output is normalized again by tiktok-get-stream.js.
# Standalone overload exits 75 before yt-dlp starts.
$ErrorActionPreference = "Stop"

$USERNAME = $args[0] -replace '^@', ''
$FORMAT = if ($args.Count -gt 1) { $args[1] } else { "best" }
$JSON_FLAG = if ($args.Count -gt 2) { $args[2] } else { "" }
$TIMESTAMP = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$TMP_DIR = New-TemporaryDirectory
$EXIT_CODE = 0

function Remove-TemporaryDirectory {
    if (Test-Path $TMP_DIR) {
        Remove-Item -Recurse -Force $TMP_DIR
    }
}
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Remove-TemporaryDirectory } | Out-Null

function emit_json {
    param(
        [string]$success,
        [string]$method,
        [string]$username,
        [string]$url,
        [string]$format,
        [string]$error,
        [string]$timestamp,
        [string]$status
    )
    
    $payload = @{}
    if ($success -ne "") { $payload["success"] = ($success.ToLower() -eq "true") }
    if ($method -ne "") { $payload["method"] = $method }
    if ($username -ne "") { $payload["username"] = $username }
    if ($url -ne "") { $payload["url"] = $url }
    if ($format -ne "") { $payload["format"] = $format }
    if ($error -ne "") { $payload["error"] = $error }
    if ($timestamp -ne "") { $payload["timestamp"] = $timestamp }
    if ($status -ne "") { $payload["status"] = $status }
    
    $payload | ConvertTo-Json -Compress
}

if ($USERNAME -notmatch '^[A-Za-z0-9._]{1,24}$') {
    Write-Error "Invalid TikTok username" -ErrorAction Stop
    exit 64
}

$validFormats = @(
    "hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld",
    "hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
    "hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
    "hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld",
    "hls-sd/hls-ld/flv-sd/flv-ld",
    "hls-ld/flv-ld",
    "hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld"
)

if ($validFormats -notcontains $FORMAT) {
    Write-Error "Invalid yt-dlp format" -ErrorAction Stop
    exit 64
}

# Get load average per CPU (approximation using Performance Counters)
$cpuLoad = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue / 100
$cpuCount = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
$LOAD_PER_CPU = $cpuLoad / [Math]::Max(1, $cpuCount)
$MAX_LOAD = if ($env:TIKTOK_MAX_LOAD_PER_CPU) { [double]$env:TIKTOK_MAX_LOAD_PER_CPU } else { 1.5 }

if ($LOAD_PER_CPU -gt $MAX_LOAD) {
    emit_json "false" "yt-dlp" $USERNAME "" $FORMAT "host overloaded" $TIMESTAMP "overloaded" | Write-Error
    exit 75
}

try {
    $null = Get-Command yt-dlp -ErrorAction Stop
} catch {
    emit_json "false" "yt-dlp" $USERNAME "" $FORMAT "yt-dlp not installed" $TIMESTAMP "dependency_missing" | Write-Error
    exit 2
}

$LIVE_URL = "https://www.tiktok.com/@${USERNAME}/live"
$stdoutFile = Join-Path $TMP_DIR "stdout.json"
$stderrFile = Join-Path $TMP_DIR "stderr.log"

& yt-dlp --no-warnings --dump-single-json --skip-download --format $FORMAT $LIVE_URL 2>$stderrFile >$stdoutFile
$EXIT_CODE = $LASTEXITCODE

if ($EXIT_CODE -ne 0) {
    $STATUS = "technical_error"
    $CODE = 2
    
    if (Test-Path $stderrFile) {
        $stderrContent = Get-Content $stderrFile -Raw
        if ($stderrContent -match "(?i)not currently live|No live cdn found|not available|private video") {
            $STATUS = "offline"
            $CODE = 1
        }
        $errorMessage = ($stderrContent -split "`n")[0..20] -join "`n"
        if ($errorMessage.Length -gt 1000) {
            $errorMessage = $errorMessage.Substring(0, 1000)
        }
        emit_json "false" "yt-dlp" $USERNAME "" $FORMAT $errorMessage $TIMESTAMP $STATUS | Write-Error
    }
    exit $CODE
}

$URL = ""
if (Test-Path $stdoutFile) {
    try {
        $json = Get-Content $stdoutFile | ConvertFrom-Json
        $candidates = @()
        
        if ($json.url -and $json.url -is [string]) {
            $candidates += $json.url
        }
        
        if ($json.formats -and $json.formats -is [array]) {
            foreach ($item in $json.formats) {
                if ($item -is [pscustomobject] -and $item.url -and $item.url -is [string]) {
                    $candidates += $item.url
                }
            }
        }
        
        foreach ($value in $candidates) {
            $low = $value.ToLower()
            if ($value.StartsWith("https://") -and ($low.Contains(".m3u8") -or $low.Contains(".flv")) -and -not $low.Contains("only_audio=1")) {
                $URL = $value
                break
            }
        }
    } catch {
        # Ignore JSON parsing errors
    }
}

if ([string]::IsNullOrEmpty($URL)) {
    emit_json "false" "yt-dlp" $USERNAME "" $FORMAT "could not extract HTTPS video URL" $TIMESTAMP "offline" | Write-Error
    exit 1
}

if ($JSON_FLAG -eq "--json") {
    emit_json "true" "yt-dlp" $USERNAME $URL $FORMAT "" $TIMESTAMP "live"
} else {
    Write-Output $URL
}
