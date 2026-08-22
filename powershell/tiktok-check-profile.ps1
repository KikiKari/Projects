#!/usr/bin/env pwsh
# tiktok-check-profile.js — portiert nach powershell
# Quelle: javascript, OpenClaw@gateway1:skills/tiktok-live/scripts/tiktok-check-profile.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
TikTok Live Status Checker
.DESCRIPTION
Prüft ausschließlich profilgebundene Live-Indikatoren.
Der allgemeine TikTok-Navigationspunkt "LIVE" ist kein Statussignal.
Unterstützt @handle-Normalisierung und optionalen Node-Lastschutz
via TIKTOK_MAX_LOAD_PER_CPU (Exit-Code 75 bei NODE_BUSY).
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Username
)

# Normalize username by removing leading @ symbols
$normalizedUsername = $Username -replace '^@+', ''

if ([string]::IsNullOrWhiteSpace($normalizedUsername)) {
    Write-Error "Username must not be empty"
    exit 1
}

function Test-BusyNode {
    $limit = $env:TIKTOK_MAX_LOAD_PER_CPU
    if (-not ($limit -as [double]) -or ($limit -le 0)) { return }

    try {
        $cpuCount = [Math]::Max(1, (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors)
        $loadAvg = (Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 5 | 
                  Measure-Object -Property CounterSamples.CookedValue -Average).Average / 100
        $normalizedLoad = $loadAvg / $cpuCount
        
        if ($normalizedLoad -gt $limit) {
            Write-Error "NODE_BUSY normalizedLoad=$('{0:F2}' -f $normalizedLoad) limit=$limit"
            exit 75
        }
    }
    catch {
        # Ignore load checking errors
    }
}

Test-BusyNode

function Test-TikTokLiveStatus {
    param([string]$Username)
    
    # Import required assemblies
    Add-Type -AssemblyName System.Web
    
    try {
        # Create WebBrowser session using Internet Explorer engine
        $ie = New-Object -ComObject InternetExplorer.Application
        $ie.Visible = $false
        $ie.Navigate("https://www.tiktok.com/@$Username")
        
        # Wait for page to load
        $timeout = 0
        while ($ie.Busy -or $ie.ReadyState -ne 4) {
            Start-Sleep -Milliseconds 100
            $timeout++
            if ($timeout -gt 300) { throw "Page load timeout" }
        }
        
        Start-Sleep -Seconds 2
        
        # Try to close cookie banners
        $doc = $ie.Document
        $bannerSelectors = @(
            "button:contains('Verstanden')",
            "[data-e2e='cookie-banner-accept']",
            "button:contains('Accept')",
            "button:contains('Akzeptieren')",
            "button:contains('Alle akzeptieren')",
            "button:contains('Allow all')",
            "button:contains('Accept all')",
            ".TUXButton:contains('Accept')",
            "[data-testid='cookie-policy-banner-accept']"
        )
        
        foreach ($selector in $bannerSelectors) {
            try {
                $elements = $doc.querySelectorAll($selector)
                if ($elements.length -gt 0) {
                    $elements[0].click()
                    Start-Sleep -Milliseconds 500
                    break
                }
            }
            catch {}
        }
        
        Start-Sleep -Seconds 3
        
        # Check for LIVE indicators
        $isLive = $false
        $indicators = @{
            liveIcon = $false
            liveBadge = $false
            liveBorder = $false
            liveLink = $false
            liveIndicator = $false
        }
        
        # Method 1: data-e2e="live-icon"
        try {
            $liveIcons = $doc.querySelectorAll('[data-e2e="live-icon"]')
            if ($liveIcons.length -gt 0) {
                $indicators.liveIcon = $true
                $isLive = $true
            }
        }
        catch {}
        
        # Method 2: LIVE text/badge
        try {
            $liveBadges = $doc.querySelectorAll('[data-e2e="creator-page-header"], [data-e2e="profile-avatar"]')
            foreach ($badgeContainer in $liveBadges) {
                $liveTextElements = $badgeContainer.querySelectorAll('*')
                foreach ($element in $liveTextElements) {
                    if (($element.textContent -match "^LIVE$" -or $element.innerText -match "^LIVE$") -and $element.offsetParent -ne $null) {
                        $indicators.liveBadge = $true
                        $isLive = $true
                        break
                    }
                }
                if ($indicators.liveBadge) { break }
            }
        }
        catch {}
        
        # Method 3: Red border around profile image
        $profileSelectors = @(
            'img[data-e2e="avatar"]',
            'div[data-e2e="profile-avatar"] img',
            '[data-e2e="creator-page-header"] img[alt*="profile"]'
        )
        
        foreach ($selector in $profileSelectors) {
            try {
                $profileImages = $doc.querySelectorAll($selector)
                foreach ($img in $profileImages) {
                    if ($img -and $img.offsetParent -ne $null) {
                        $computedStyles = $img.currentStyle
                        if (-not $computedStyles) {
                            $computedStyles = $img.style
                        }
                        
                        $borderColor = $computedStyles.borderColor
                        $outlineColor = $computedStyles.outlineColor
                        $boxShadow = $computedStyles.boxShadow
                        
                        $parentBorderColor = ""
                        if ($img.parentElement) {
                            $parentStyles = $img.parentElement.currentStyle
                            if (-not $parentStyles) {
                                $parentStyles = $img.parentElement.style
                            }
                            $parentBorderColor = $parentStyles.borderColor
                        }
                        
                        $redIndicators = @($borderColor, $outlineColor, $parentBorderColor)
                        foreach ($color in $redIndicators) {
                            if ($color -and ($color.Contains("255") -or $color.Contains("red") -or $color.Contains("rgb(254") -or $color.Contains("fe2c55") -or $color.Contains("#fe2c"))) {
                                $indicators.liveBorder = $true
                                $isLive = $true
                                break
                            }
                        }
                        
                        if ($boxShadow -and ($boxShadow.Contains("255") -or $boxShadow.Contains("254"))) {
                            $indicators.liveBorder = $true
                            $isLive = $true
                        }
                        
                        if ($indicators.liveBorder) { break }
                    }
                }
                if ($indicators.liveBorder) { break }
            }
            catch {}
        }
        
        # Method 4: Check for Live link
        try {
            $liveLinks = $doc.querySelectorAll("a[href*='/@$Username/live']")
            if ($liveLinks.length -gt 0) {
                $indicators.liveLink = $true
                $isLive = $true
            }
        }
        catch {}
        
        # Method 5: Check for live indicator dot
        try {
            $liveIndicators = $doc.querySelectorAll('[class*="live-indicator"], div[class*="LiveBadge"]')
            if ($liveIndicators.length -gt 0) {
                $indicators.liveIndicator = $true
                $isLive = $true
            }
        }
        catch {}
        
        # Take screenshot if DEBUG enabled
        if ($env:DEBUG -eq "1") {
            try {
                $bitmap = New-Object System.Drawing.Bitmap($ie.Width, $ie.Height)
                $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
                $graphics.CopyFromScreen($ie.Left, $ie.Top, 0, 0, $bitmap.Size)
                $bitmap.Save("/tmp/tiktok-$Username.png")
                $bitmap.Dispose()
                $graphics.Dispose()
            }
            catch {}
        }
        
        $ie.Quit()
        
        $result = @{
            username = $Username
            isLive = $isLive
            timestamp = (Get-Date).ToUniversalTime().ToString("o")
            indicators = $indicators
        }
        
        Write-Output ($result | ConvertTo-Json)
        return $isLive
    }
    catch {
        $ie.Quit()
        $errorResult = @{
            error = $true
            message = $_.Exception.Message
            stack = $_.ScriptStackTrace
            timestamp = (Get-Date).ToUniversalTime().ToString("o")
        }
        Write-Error ($errorResult | ConvertTo-Json)
        exit 1
    }
}

try {
    $isLive = Test-TikTokLiveStatus -Username $normalizedUsername
    if ($isLive) {
        exit 0
    } else {
        exit 1
    }
}
catch {
    $errorResult = @{
        error = $true
        message = $_.Exception.Message
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
    }
    Write-Error ($errorResult | ConvertTo-Json)
    exit 1
}
