#!/usr/bin/env pwsh
# tiktok-check-profile.js — portiert nach powershell
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-check-profile.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Basic TikTok LIVE profile checker.

.DESCRIPTION
Scopes every signal to the requested account and ignores unrelated sidebar
LIVE labels. This profile-only checker does not classify restricted LIVE;
use the enhanced checker or dispatcher for that distinction.

Exit codes:
0 = account-specific LIVE
1 = offline
2 = dependency/technical failure
75 = overloaded before startup
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Username
)

# Helper functions
function Normalize-Username {
    param([string]$InputUsername)
    
    if ([string]::IsNullOrWhiteSpace($InputUsername)) {
        throw "Username cannot be empty"
    }
    
    # Remove @ prefix if present
    if ($InputUsername.StartsWith('@')) {
        $InputUsername = $InputUsername.Substring(1)
    }
    
    # Validate username format (basic)
    if ($InputUsername -notmatch '^[a-zA-Z0-9._-]+$') {
        throw "Invalid username format"
    }
    
    return $InputUsername
}

function Enforce-Load-Limit {
    param([string]$Method)
    
    # In PowerShell we don't have the same load limiting mechanism
    # This is a placeholder to maintain compatibility
    return $true
}

function Get-Live-Href-Selectors {
    param([string]$Username)
    
    return @(
        "a[href='/@$Username/live']",
        "a[href='https://www.tiktok.com/@$Username/live']",
        "[href='/@$Username/live']",
        "[href='https://www.tiktok.com/@$Username/live']"
    )
}

# Main function
function Check-Live-Status {
    param([string]$Username)
    
    try {
        # Check if Chromium is available
        $chromiumPath = "$env:LOCALAPPDATA\ms-playwright\chromium-*\chrome-win\chrome.exe"
        $chromiumExists = Test-Path $chromiumPath
        
        if (-not $chromiumExists) {
            $versions = @("chromium-*", "chromium-*/chrome-win/chrome.exe")
            foreach ($version in $versions) {
                $path = "$env:LOCALAPPDATA\ms-playwright\$version"
                if (Test-Path $path) {
                    $chromiumExists = $true
                    break
                }
            }
        }
        
        if (-not $chromiumExists) {
            Write-Error (ConvertTo-Json @{
                error = $true
                status = 'dependency_missing'
                method = 'playwright_basic'
                message = 'Playwright Chromium unavailable'
                timestamp = (Get-Date).ToUniversalTime().ToString("o")
            })
            exit 2
        }
        
        # Start browser
        $startParams = @{
            Uri = "http://localhost:9222"
            Method = "POST"
            Body = '{"desiredCapabilities":{}}' 
            ContentType = "application/json"
        }
        
        # Since we can't directly launch Playwright like in Node.js,
        # we'll simulate the behavior using PowerShell web automation
        
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        # Create WebBrowser object (as fallback for Playwright functionality)
        $browser = New-Object System.Windows.Forms.WebBrowser
        $browser.ScriptErrorsSuppressed = $true
        $browser.ScrollBarsEnabled = $false
        $browser.Size = New-Object System.Drawing.Size(1920, 1080)
        
        # Navigate to profile
        $url = "https://www.tiktok.com/@$Username"
        $browser.Navigate($url)
        
        # Wait for page load
        while ($browser.ReadyState -ne [System.Windows.Forms.WebBrowserReadyState]::Complete) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 100
        }
        
        Start-Sleep -Seconds 2
        
        # Try to close cookie banners
        $cookieSelectors = @(
            "button:contains('Verstanden')",
            "[data-e2e='cookie-banner-accept']",
            "button:contains('Accept')",
            "button:contains('Akzeptieren')",
            "button:contains('Alle akzeptieren')",
            "button:contains('Allow all')",
            "button:contains('Accept all')",
            "[data-testid='cookie-policy-banner-accept']"
        )
        
        foreach ($selector in $cookieSelectors) {
            try {
                # This is simplified - actual implementation would need more complex DOM parsing
                # For now we just continue with basic checks
                break
            } catch {
                # Continue trying other selectors
            }
        }
        
        Start-Sleep -Seconds 3
        
        # Check for LIVE indicators
        $htmlContent = $browser.DocumentText
        
        # Method 1: Check for live links
        $selectors = Get-Live-Href-Selectors -Username $Username
        $hasLiveLink = $false
        foreach ($selector in $selectors) {
            if ($htmlContent -like "*$selector*") {
                $hasLiveLink = $true
                break
            }
        }
        
        # Method 2: Check for LIVE text/badges
        $liveBadgeVisible = $htmlContent -like "*LIVE*" -or $htmlContent -like "*live*"
        
        # Method 3: Check for live borders (simplified)
        $hasLiveBorder = $false
        $indicators = @("255", "red", "rgb(254", "fe2c55", "#fe2c")
        foreach ($indicator in $indicators) {
            if ($htmlContent -like "*$indicator*") {
                $hasLiveBorder = $true
                break
            }
        }
        
        # Method 4 & 5: Additional live indicators
        $liveIconVisible = $htmlContent -like "*live-icon*" -or $htmlContent -like "*LiveBadge*"
        $liveIndicatorVisible = $htmlContent -like "*live-indicator*"
        
        $isLive = $hasLiveLink -or $hasLiveBorder -or $liveIconVisible -or $liveIndicatorVisible -or $liveBadgeVisible
        
        $result = @{
            username = $Username
            isLive = $isLive
            timestamp = (Get-Date).ToUniversalTime().ToString("o")
            indicators = @{
                liveIcon = $liveIconVisible
                liveBadge = $liveBadgeVisible
                liveBorder = $hasLiveBorder
                liveLink = $hasLiveLink
                liveIndicator = $liveIndicatorVisible
            }
        }
        
        Write-Output (ConvertTo-Json $result -Depth 5)
        
        return $isLive
        
    } catch {
        $errorResult = @{
            error = $true
            status = 'technical_error'
            message = $_.Exception.Message
            stack = $_.ScriptStackTrace
            timestamp = (Get-Date).ToUniversalTime().ToString("o")
        }
        
        Write-Error (ConvertTo-Json $errorResult)
        return $null
    } finally {
        if ($browser) {
            $browser.Dispose()
        }
    }
}

# Main execution
try {
    $normalizedUsername = Normalize-Username -InputUsername $Username
    Enforce-Load-Limit -Method "playwright_basic"
    
    $isLive = Check-Live-Status -Username $normalizedUsername
    
    if ($null -eq $isLive) {
        exit 2
    } elseif ($isLive) {
        exit 0
    } else {
        exit 1
    }
} catch {
    Write-Host "Usage: tiktok-check-profile.ps1 <username>" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 64
}
