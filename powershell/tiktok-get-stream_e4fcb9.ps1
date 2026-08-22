#!/usr/bin/env pwsh
# tiktok-get-stream.js — portiert nach powershell
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/tiktok-get-stream.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Enhanced TikTok LIVE URL extractor.

.DESCRIPTION
Order: Playwright response interception, streamlink, then yt-dlp. Every
result is schema-normalized and must be an allowed HTTPS TikTok-CDN FLV
URL. Fallbacks use fixed argument arrays, bounded output, timeouts, and
process-group cleanup.

Exit codes:
0 = URL extracted successfully
1 = offline/restricted/no URL
2 = dependency/technical failure
75 = overloaded before Playwright startup
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [ValidateSet('original', '1080p60', '720p60', '720p', '540p', '360p', 'auto')]
    [string]$Quality = 'auto',
    
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$FALLBACK_TIMEOUT_MS = 45000
$FALLBACK_MAX_OUTPUT = 1MB

# Import common functions
. "$PSScriptRoot/tiktok-common.ps1"

function Write-Log {
    param([string]$Message)
    Write-Error $Message
}

function Invoke-Fallback {
    param(
        [string]$ScriptPath,
        [string[]]$Arguments
    )
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "bash"
    $psi.Arguments = @($ScriptPath) + $Arguments
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $process.EnableRaisingEvents = $true
    
    $stdout = ""
    $stderr = ""
    $overflow = $false
    
    $process.OutputDataReceived.Add_EventHandler({
        param($sender, $e)
        if ($e.Data -ne $null) {
            $next = $stdout + $e.Data
            if ([System.Text.Encoding]::UTF8.GetByteCount($next) -gt $FALLBACK_MAX_OUTPUT) {
                $overflow = $true
                return
            }
            $stdout = $next
        }
    })
    
    $process.ErrorDataReceived.Add_EventHandler({
        param($sender, $e)
        if ($e.Data -ne $null) {
            $next = $stderr + $e.Data
            if ([System.Text.Encoding]::UTF8.GetByteCount($next) -gt $FALLBACK_MAX_OUTPUT) {
                $overflow = $true
                return
            }
            $stderr = $next
        }
    })
    
    try {
        [void]$process.Start()
        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()
        
        $waitResult = $process.WaitForExit($FALLBACK_TIMEOUT_MS)
        if (-not $waitResult) {
            # Timeout - kill process tree
            try {
                taskkill /PID $process.Id /T /F 2>$null
            } catch {
                # Process may have already exited
            }
            Start-Sleep -Milliseconds 3000
            
            return @{
                Code = 2
                Stdout = $stdout
                Stderr = ($stderr + "`ntimeout").Trim()
            }
        }
        
        if ($overflow) {
            return @{
                Code = 2
                Stdout = ""
                Stderr = "fallback output exceeded limit"
            }
        }
        
        return @{
            Code = if ($process.ExitCode -eq $null) { 2 } else { $process.ExitCode }
            Stdout = $stdout.Trim()
            Stderr = $stderr.Trim()
        }
    } catch {
        return @{
            Code = 2
            Stdout = $stdout
            Stderr = ($stderr + "`n" + $_.Exception.Message).Trim()
        }
    }
}

function ConvertFrom-FallbackResult {
    param(
        [string]$Method,
        [string]$Username,
        [hashtable]$Execution
    )
    
    foreach ($text in @($Execution.Stdout, $Execution.Stderr)) {
        if ([string]::IsNullOrWhiteSpace($text)) { continue }
        
        try {
            $value = $text | ConvertFrom-Json
            if ($value -and $value.GetType().Name -eq 'PSCustomObject') {
                return ConvertTo-NormalizedExtractorResult $value $Method $Username
            }
        } catch {
            # Try next channel
        }
    }
    
    $message = if ($Execution.Code -eq 75) { 
        "overloaded" 
    } else { 
        $Execution.Stderr -or "fallback exited $($Execution.Code)" 
    }
    
    return ConvertTo-NormalizedExtractorResult @{
        success = $false
        status = if ($Execution.Code -eq 75) { "overloaded" } else { "technical_error" }
        method = $Method
        username = $Username
        message = $message
    } $Method $Username
}

function Test-PlaywrightPreflight {
    try {
        # Check if Playwright Chromium is available
        $executable = & playwright install chromium --dry-run 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Playwright not installed"
        }
        return @{ Ok = $true }
    } catch {
        return @{
            Ok = $false
            Status = "dependency_missing"
            Error = "Playwright Chromium unavailable: $($_.Exception.Message)"
        }
    }
}

function Get-RandomDelay {
    param(
        [int]$Min = 2000,
        [int]$Max = 4000
    )
    return Get-Random -Minimum $Min -Maximum ($Max + 1)
}

# Close GDPR and login popups
function Close-Popups {
    param([object]$Page)
    
    $closed = $false
    
    # GDPR selectors
    $dsgvoSelectors = @(
        'button:has-text("Verstanden")'
        '[data-e2e="cookie-banner-accept"]'
        'button:has-text("Accept")'
        'button:has-text("Akzeptieren")'
        'button:has-text("Alle akzeptieren")'
        'button:has-text("Allow all")'
        'button:has-text("Accept all")'
        '[data-testid="cookie-policy-banner-accept"]'
    )
    
    foreach ($sel in $dsgvoSelectors) {
        try {
            $btn = $Page.Locator($sel).WaitFor(@{ State = "visible"; Timeout = 3000 })
            if ($btn) {
                $btn.Click()
                Start-Sleep -Milliseconds (Get-RandomDelay 1000 2000)
                $closed = $true
                break
            }
        } catch {
            # Continue to next selector
        }
    }
    
    # Login popup 1: "Bei TikTok anmelden" → X-Button
    try {
        $loginText = $Page.Locator('text="Bei TikTok anmelden"').First()
        if ($loginText) {
            $closeBtn = $Page.Locator('div[role="dialog"] [aria-label="Close"], div[role="dialog"] button[aria-label="Schließen"], div[role="dialog"] svg').First()
            if ($closeBtn) {
                $closeBtn.Click()
                Start-Sleep -Milliseconds (Get-RandomDelay 1000 2000)
                $closed = $true
            }
        }
    } catch {
        # Not present
    }
    
    # Login popup 2: "Jetzt nicht" button
    try {
        $skipBtn = $Page.Locator('button:has-text("Jetzt nicht"), button:has-text("Not now")').First()
        if ($skipBtn) {
            $skipBtn.Click()
            Start-Sleep -Milliseconds (Get-RandomDelay 1000 2000)
            $closed = $true
        }
    } catch {
        # Not present
    }
    
    return $closed
}

# Check if stream is restricted (after popup handling)
function Test-Restrictions {
    param([object]$Page)
    
    $restrictionTexts = @(
        'text="Bei TikTok anmelden"'
        'text=/Dieses LIVE enthält Themen/'
        'text="Melde dich an für das vollständige Erlebnis"'
        'text=/Melde dich an für das volle/'
        'text="Log in to TikTok"'
        'text=/mature content/'
        'text=/age-restricted/'
    )
    
    foreach ($sel in $restrictionTexts) {
        try {
            $el = $Page.Locator($sel).First()
            if ($el -and $el.IsVisible()) {
                return @{
                    Restricted = $true
                    Reason = $sel.Replace('text=', '').Replace('/', '').Replace('"', '')
                }
            }
        } catch {
            # Continue to next selector
        }
    }
    
    return @{ Restricted = $false; Reason = $null }
}

# Playwright-based FLV extraction
function Get-WithPlaywright {
    param(
        [string]$Username,
        [string]$QualityPreference
    )
    
    $preflight = Test-PlaywrightPreflight
    if (-not $preflight.Ok) {
        return @{
            Success = $false
            Method = "playwright"
            Status = $preflight.Status
            Error = $preflight.Error
        }
    }
    
    try {
        # Launch browser with specific arguments
        $launchArgs = @("--no-sandbox", "--disable-setuid-sandbox", "--disable-gpu", "--disable-dev-shm-usage")
        $browser = playwright launch chromium --headless $launchArgs
        
        # Create context with user agent and viewport
        $context = $browser.NewContext(@{
            UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            Viewport = @{ Width = 1920; Height = 1080 }
        })
        
        $page = $context.NewPage()
        
        # Collect FLV URLs via event listener BEFORE navigation
        $collectedUrls = @()
        $page.On("response", {
            param($response)
            $url = $response.Url
            if ($collectedUrls.Count -lt 100 -and (Test-StreamResponse -Status $response.Status -Url $url)) {
                $collectedUrls += @{
                    Url = $url
                    Status = $response.Status
                    Timestamp = (Get-Date).ToString("o")
                }
            }
        })
        
        # Navigate directly to /live
        $page.Goto("https://www.tiktok.com/@${Username}/live", @{ WaitUntil = "domcontentloaded"; Timeout = 30000 }) | Out-Null
        
        # Close popups
        Close-Popups $page | Out-Null
        
        # Wait for page load
        Start-Sleep -Milliseconds (Get-RandomDelay 3000 5000)
        try {
            $page.WaitForLoadState("networkidle", @{ Timeout = 10000 }) | Out-Null
        } catch {
            # OK to continue
        }
        
        # Check for restrictions
        $restrictions = Test-Restrictions $page
        if ($restrictions.Restricted) {
            Write-Log "Playwright: Stream restricted - $($restrictions.Reason)"
            return @{
                Success = $false
                Method = "playwright"
                Status = "restricted"
                Restricted = $true
                Reason = $restrictions.Reason
            }
        }
        
        # Try to play video if needed
        try {
            $video = $page.Locator("video").First()
            if ($video) {
                $video.Evaluate("v => v.play()") | Out-Null
            }
        } catch {
            # OK to continue
        }
        
        # Wait for FLV URLs (stream must load)
        Start-Sleep -Milliseconds (Get-RandomDelay 8000 12000)
        
        # Second attempt to close popups (may appear after delay)
        Close-Popups $page | Out-Null
        Start-Sleep -Milliseconds (Get-RandomDelay 3000 5000)
        
        # Check restrictions again
        $restrictions2 = Test-Restrictions $page
        if ($restrictions2.Restricted) {
            Write-Log "Playwright: Stream became restricted after wait - $($restrictions2.Reason)"
            return @{
                Success = $false
                Method = "playwright"
                Status = "restricted"
                Restricted = $true
                Reason = $restrictions2.Reason
            }
        }
        
        # Evaluate URLs
        if ($collectedUrls.Count -eq 0) {
            Write-Log "Playwright: No FLV URLs captured via network monitoring."
            return @{
                Success = $false
                Method = "playwright"
                Status = "offline"
                Restricted = $false
                Reason = "No FLV URLs found"
            }
        }
        
        # Deduplicate and sort by quality
        $uniqueUrls = $collectedUrls | Sort-Object Url -Unique
        
        # Apply quality preference
        $qualityOrder = switch ($QualityPreference) {
            "original" { @("_origin.flv", "_uhd_60.flv", "_hd_60.flv", "_hd.flv", "_sd.flv", "_ld.flv") }
            "1080p60" { @("_uhd_60.flv", "_hd_60.flv", "_hd.flv", "_sd.flv", "_ld.flv") }
            "720p60" { @("_hd_60.flv", "_hd.flv", "_sd.flv", "_ld.flv") }
            "720p" { @("_hd.flv", "_sd.flv", "_ld.flv") }
            "540p" { @("_sd.flv", "_ld.flv") }
            "360p" { @("_ld.flv") }
            default { @("_origin.flv", "_uhd_60.flv", "_hd_60.flv", "_hd.flv", "_sd.flv", "_ld.flv") }
        }
        
        $bestUrl = $null
        foreach ($suffix in $qualityOrder) {
            $bestUrl = $uniqueUrls | Where-Object { $_.Url.Contains($suffix) } | Select-Object -First 1
            if ($bestUrl) { break }
        }
        
        if (-not $bestUrl -and ($QualityPreference -eq "auto" -or $QualityPreference -eq "original")) {
            $bestUrl = $uniqueUrls | Select-Object -First 1
        }
        
        if (-not $bestUrl) {
            return @{
                Success = $false
                Method = "playwright"
                Status = "quality_unavailable"
                Reason = "Requested quality ${QualityPreference} was not captured in this fresh browser session"
            }
        }
        
        return @{
            Success = $true
            Status = "live"
            Method = "playwright"
            Username = $Username
            Url = $bestUrl.Url
            Quality = $QualityPreference
            AllUrls = $uniqueUrls | ForEach-Object {
                @{
                    Url = $_.Url
                    Quality = Get-QualityKeyFromUrl $_.Url
                }
            }
            AllUrlsCount = $uniqueUrls.Count
            Timestamp = (Get-Date).ToString("o")
        }
    } catch {
        Write-Log "Playwright error: $($_.Exception.Message)"
        return @{
            Success = $false
            Method = "playwright"
            Status = "technical_error"
            Error = $_.Exception.Message
        }
    } finally {
        if ($browser) {
            $browser.Close()
        }
    }
}

# Streamlink fallback
function Invoke-Streamlink {
    param(
        [string]$Username,
        [string]$Quality
    )
    
    $scriptPath = Join-Path $PSScriptRoot "extraction-methods" "extract-tiktok-streamlink.sh"
    $execution = Invoke-Fallback $scriptPath @($Username, $Quality, "--json")
    return ConvertFrom-FallbackResult "streamlink" $Username $execution
}

# yt-dlp fallback
function Invoke-YtDlp {
    param(
        [string]$Username,
        [string]$Quality
    )
    
    $scriptPath = Join-Path $PSScriptRoot "extraction-methods" "extract-tiktok-yt-dlp.sh"
    
    $ytFormatMap = @{
        original = "hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld"
        "1080p60" = "hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld"
        "720p60" = "hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld"
        "720p" = "hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld"
        "540p" = "hls-sd/hls-ld/flv-sd/flv-ld"
        "360p" = "hls-ld/flv-ld"
        auto = "hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld"
    }
    
    $ytFormat = $ytFormatMap[$Quality]
    $execution = Invoke-Fallback $scriptPath @($Username, $ytFormat, "--json")
    return ConvertFrom-FallbackResult "yt-dlp" $Username $execution
}

# Main function with fallback chain
function Get-StreamUrl {
    param(
        [string]$Username,
        [string]$QualityPreference = "auto"
    )
    
    $timestamp = (Get-Date).ToString("o")
    
    # --- 1. Playwright ---
    Write-Log "[1/3] Trying Playwright for @$Username..."
    $pwResult = Get-WithPlaywright $Username $QualityPreference
    if ($pwResult.Success) {
        $pwResult.Timestamp = $timestamp
        return $pwResult
    }
    if ($pwResult.Status -eq "restricted" -or $pwResult.Status -eq "overloaded") {
        return $pwResult
    }
    Write-Log "Playwright result: $($pwResult.Reason -or $pwResult.Error -or 'failed')"
    
    # --- 2. Streamlink (bounded fallback; output is normalized below) ---
    Write-Log "[2/3] Trying streamlink for @$Username (quality: $QualityPreference)..."
    $slResult = Invoke-Streamlink $Username $QualityPreference
    if ($slResult.Success) {
        return $slResult
    }
    if ($slResult.Status -eq "restricted" -or $slResult.Status -eq "overloaded") {
        return $slResult
    }
    Write-Log "Streamlink result: $($slResult.Message -or $slResult.Error -or 'failed')"
    
    # --- 3. yt-dlp (final bounded fallback; output is normalized below) ---
    Write-Log "[3/3] Trying yt-dlp for @$Username..."
    $ytResult = Invoke-YtDlp $Username $QualityPreference
    if ($ytResult.Success) {
        return $ytResult
    }
    if ($ytResult.Status -eq "restricted" -or $ytResult.Status -eq "overloaded") {
        return $ytResult
    }
    Write-Log "yt-dlp result: $($ytResult.Message -or $ytResult.Error -or 'failed')"
    
    # --- All failed ---
    $status = Get-ClassifiedFinalFailure @($pwResult, $slResult, $ytResult)
    return @{
        Success = $false
        Status = $status
        Username = $Username
        Message = "All extraction methods failed (Playwright, streamlink, yt-dlp)."
        PlaywrightReason = $pwResult.Reason -or $pwResult.Error
        StreamlinkReason = $slResult.Message -or $slResult.Error
        YtdlpReason = $ytResult.Message -or $ytResult.Error
        Timestamp = $timestamp
    }
}

# --- MAIN EXECUTION ---
try {
    $normalizedUsername = ConvertTo-NormalizedUsername $Username
    Confirm-LoadLimit "playwright_streamlink_ytdlp"
    if (Test-ForcedOffline "playwright_streamlink_ytdlp" $normalizedUsername) {
        exit 1
    }
    
    $result = Get-StreamUrl $normalizedUsername $Quality
    
    if ($Json) {
        $result | ConvertTo-Json -Depth 10
    } else {
        if ($result.Success) {
            Write-Output $result.Url
        } else {
            Write-Error $result.Message
        }
    }
    
    exit (Get-ExitCodeForResult $result)
} catch {
    Write-Error "Unhandled error: $($_.Exception.Message)"
    exit 2
}
