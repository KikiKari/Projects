#!/usr/bin/env pwsh
# extract-tiktok-yt-dlp.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

param(
    [string]$UsernameParam,
    [string]$Format = "best",
    [string]$JsonFlag
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Emit-Json {
    param(
        [string]$Success,
        [string]$Method,
        [string]$Username,
        [string]$Url,
        [string]$FormatParam,
        [string]$Error,
        [string]$Timestamp,
        [string]$Status
    )

    $payload = [ordered]@{}
    if ($Success -ne "") { $payload["success"] = ($Success -eq "true") }
    if ($Method -ne "") { $payload["method"] = $Method }
    if ($Username -ne "") { $payload["username"] = $Username }
    if ($Url -ne "") { $payload["url"] = $Url }
    if ($FormatParam -ne "") { $payload["format"] = $FormatParam }
    if ($Error -ne "") { $payload["error"] = $Error }
    if ($Timestamp -ne "") { $payload["timestamp"] = $Timestamp }
    if ($Status -ne "") { $payload["status"] = $Status }

    return $payload | ConvertTo-Json -Compress
}

$TIMESTAMP = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$TMP_DIR = New-TemporaryFile | ForEach-Object { 
    $dir = $_.DirectoryName + "\tiktok-yt-dlp." + (Get-Random)
    New-Item -ItemType Directory -Path $dir
} | Select-Object -First 1

try {
    $USERNAME = $UsernameParam.TrimStart("@")
    
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

    if ($validFormats -notcontains $Format) {
        Write-Error "Invalid yt-dlp format" -ErrorAction Stop
        exit 64
    }

    $LOAD_PER_CPU = (Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average / 100
    $MAX_LOAD = if ($env:TIKTOK_MAX_LOAD_PER_CPU) { $env:TIKTOK_MAX_LOAD_PER_CPU } else { "1.5" }
    
    if ([double]$LOAD_PER_CPU -gt [double]$MAX_LOAD) {
        $json = Emit-Json "false" "yt-dlp" $USERNAME "" $Format "host overloaded" $TIMESTAMP "overloaded"
        Write-Error $json -ErrorAction Stop
        exit 75
    }

    $ytDlpPath = Get-Command yt-dlp -ErrorAction SilentlyContinue
    if (-not $ytDlpPath) {
        $json = Emit-Json "false" "yt-dlp" $USERNAME "" $Format "yt-dlp not installed" $TIMESTAMP "dependency_missing"
        Write-Error $json -ErrorAction Stop
        exit 2
    }

    $LIVE_URL = "https://www.tiktok.com/@${USERNAME}/live"
    $stdoutFile = Join-Path $TMP_DIR "stdout.json"
    $stderrFile = Join-Path $TMP_DIR "stderr.log"

    yt-dlp --no-warnings --dump-single-json --skip-download --format $Format $LIVE_URL 2>$stderrFile >$stdoutFile
    $EXIT_CODE = $LASTEXITCODE

    if ($EXIT_CODE -ne 0) {
        $stderrContent = Get-Content $stderrFile -Raw
        if ($stderrContent -match "(?i)not currently live|No live cdn found|not available|private video") {
            $STATUS = "offline"
            $CODE = 1
        } else {
            $STATUS = "technical_error"
            $CODE = 2
        }
        
        $errorText = (Get-Content $stderrFile -Head 1000) -join "`n"
        $json = Emit-Json "false" "yt-dlp" $USERNAME "" $Format $errorText $TIMESTAMP $STATUS
        Write-Error $json -ErrorAction Stop
        exit $CODE
    }

    $jsonContent = Get-Content $stdoutFile | ConvertFrom-Json
    $candidates = @()
    
    if ($jsonContent.url -and $jsonContent.url -is [string]) {
        $candidates += $jsonContent.url
    }
    
    if ($jsonContent.formats) {
        foreach ($item in $jsonContent.formats) {
            if ($item.url -and $item.url -is [string]) {
                $candidates += $item.url
            }
        }
    }

    $URL = ""
    foreach ($value in $candidates) {
        $low = $value.ToLower()
        if ($value.StartsWith("https://") -and ($low.Contains(".m3u8") -or $low.Contains(".flv")) -and -not $low.Contains("only_audio=1")) {
            $URL = $value
            break
        }
    }

    if (-not $URL) {
        $json = Emit-Json "false" "yt-dlp" $USERNAME "" $Format "could not extract HTTPS video URL" $TIMESTAMP "offline"
        Write-Error $json -ErrorAction Stop
        exit 1
    }

    if ($JsonFlag -eq "--json") {
        $json = Emit-Json "true" "yt-dlp" $USERNAME $URL $Format "" $TIMESTAMP "live"
        Write-Output $json
    } else {
        Write-Output $URL
    }
} finally {
    if (Test-Path $TMP_DIR) {
        Remove-Item $TMP_DIR -Recurse -Force
    }
}
