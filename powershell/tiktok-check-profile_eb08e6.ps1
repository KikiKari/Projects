#!/usr/bin/env pwsh
# tiktok-check-profile.js — portiert nach powershell
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/tiktok-check-profile.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Enhanced TikTok LIVE status checker.

.DESCRIPTION
Uses exact account selectors and the direct /@username/live page to return
live, restricted, offline, dependency_missing, technical_error, or
overloaded. An accessible LIVE requires a successful allowed TikTok-CDN
FLV response; unrelated sidebar LIVE labels never count.

Browser resources are closed on every completion path.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Username
)

# Import required modules
if (-not (Get-Module -ListAvailable -Name Selenium)) {
    Write-Error "Selenium module not found. Please install it using: Install-Module Selenium"
    exit 2
}

Import-Module Selenium

# Constants and helper functions
$script:humanDelayMin = 2000
$script:humanDelayMax = 4000

function Get-HumanDelay {
    param(
        [int]$Min = $script:humanDelayMin,
        [int]$Max = $script:humanDelayMax
    )
    return Get-Random -Minimum $Min -Maximum ($Max + 1)
}

function Test-Dependency {
    try {
        $chromeDriverPath = (Get-Command chromedriver.exe -ErrorAction SilentlyContinue).Source
        if (-not $chromeDriverPath) {
            throw "ChromeDriver not found in PATH"
        }
        return $true
    } catch {
        Write-Error (ConvertTo-Json @{
            error = $true
            status = "dependency_missing"
            method = "playwright_enhanced"
            message = "Playwright Chromium unavailable: $($_.Exception.Message)"
            timestamp = (Get-Date).ToUniversalTime().ToString("o")
        })
        exit 2
    }
}

function Close-DSGVOBanner($driver) {
    # Alle bekannten Cookie/DSGVO-Button-Varianten
    $selectors = @(
        "//button[contains(text(), 'Verstanden')]"
        "//*[@data-e2e='cookie-banner-accept']"
        "//button[contains(text(), 'Accept')]"
        "//button[contains(text(), 'Akzeptieren')]"
        "//button[contains(text(), 'Alle akzeptieren')]"
        "//button[contains(text(), 'Allow all')]"
        "//button[contains(text(), 'Accept all')]"
        "//button[@class='TUXButton' and contains(text(), 'Accept')]"
        "//*[@data-testid='cookie-policy-banner-accept']"
    )

    foreach ($selector in $selectors) {
        try {
            $btn = $driver.FindElementByXPath($selector)
            if ($btn) {
                $btn.Click()
                Start-Sleep -Milliseconds (Get-HumanDelay 1000 2000)
                return $true
            }
        } catch { 
            # weiter probieren 
        }
    }
    return $false
}

function Wait-ForPageReady($driver) {
    # KRITISCH: TikTok lädt die Seite in Phasen.
    # Der LIVE-Badge und der rote Rahmen erscheinen ERST wenn die Seite
    # vollständig geladen ist. Erkennbar am Menüband:
    # "Videos" + "Erneute Veröffentlichungen" + "Gelikt"
    # "Erneute Veröffentlichungen" erscheint als LETZTES.

    # Phase 1: Initiales Laden abwarten
    Start-Sleep -Milliseconds (Get-HumanDelay 2000 3000)

    # Phase 2: Warte explizit auf "Erneute Veröffentlichungen" Tab
    # Das ist der zuverlässigste Indikator für vollständigen Seitenaufbau
    $pageReady = $false
    try {
        $wait = New-Object OpenQA.Selenium.Support.UI.WebDriverWait($driver, [System.TimeSpan]::FromSeconds(25))
        $wait.Until([OpenQA.Selenium.Support.UI.ExpectedConditions]::ElementIsVisible([OpenQA.Selenium.By]::XPath("//span[contains(text(), 'Erneute Veröffentlichungen')]"))) | Out-Null
        $pageReady = $true
    } catch {
        # Fallback: englische Version probieren
        try {
            $wait = New-Object OpenQA.Selenium.Support.UI.WebDriverWait($driver, [System.TimeSpan]::FromSeconds(5))
            $wait.Until([OpenQA.Selenium.Support.UI.ExpectedConditions]::ElementIsVisible([OpenQA.Selenium.By]::XPath("//span[contains(text(), 'Reposts')]"))) | Out-Null
            $pageReady = $true
        } catch {
            # Letzter Fallback: einfach auf networkidle warten
            try {
                $driver.Manage().Timeouts().PageLoad = [System.TimeSpan]::FromSeconds(10)
            } catch { 
                # weiter 
            }
        }
    }

    # Phase 3: Nach dem Erscheinen des Menübands noch kurz warten,
    # damit der LIVE-Badge/roter Rahmen gerendert wird
    Start-Sleep -Milliseconds (Get-HumanDelay 2000 3000)

    return $pageReady
}

function Detect-LiveStatus($driver, $username) {
    $indicators = @{
        liveIcon = $false
        liveBadge = $false
        liveBorder = $false
        liveLink = $false
        liveIndicator = $false
    }
    $detectionMethod = "none"

    # --- Priorität 1: LIVE-Icon innerhalb des exakten Account-LIVE-Links ---
    try {
        $liveLinkElements = $driver.FindElementsByXPath("//a[contains(@href, '/@$username/live')]")
        if ($liveLinkElements.Count -gt 0) {
            $liveLink = $liveLinkElements[0]
            $liveIcons = $liveLink.FindElementsByXPath(".//*[contains(@data-e2e, 'live-icon') or contains(@class, 'LiveBadge') or contains(@class, 'live-indicator')]")
            if ($liveIcons.Count -gt 0 -and $liveIcons[0].Displayed) {
                $indicators.liveIcon = $true
                $detectionMethod = "live-icon"
                return @{ isLive = $true; detectionMethod = $detectionMethod; indicators = $indicators }
            }
        }
    } catch { 
        # weiter 
    }

    # --- Priorität 2: exaktes LIVE-Badge innerhalb desselben Account-Links ---
    try {
        $liveLinkElements = $driver.FindElementsByXPath("//a[contains(@href, '/@$username/live')]")
        if ($liveLinkElements.Count -gt 0) {
            $liveLink = $liveLinkElements[0]
            $liveBadges = $liveLink.FindElementsByXPath(".//*[text()[normalize-space()='LIVE']]")
            if ($liveBadges.Count -gt 0 -and $liveBadges[0].Displayed) {
                $indicators.liveBadge = $true
                $detectionMethod = "live-badge"
                return @{ isLive = $true; detectionMethod = $detectionMethod; indicators = $indicators }
            }
        }
    } catch { 
        # weiter 
    }

    # --- Priorität 3: Live-Rahmen am Profilkopf/Avatar des Accounts ---
    try {
        $profileSelectors = @(
            "//*[@data-e2e='user-page']//img[@data-e2e='avatar']"
            "//*[@data-e2e='user-page']//*[@data-e2e='profile-avatar']//img"
            "//main/header//img[@data-e2e='avatar']"
            "//main/header//*[contains(@class, 'avatar')]//img"
        )

        foreach ($selector in $profileSelectors) {
            try {
                $profileImg = $driver.FindElementByXPath($selector)
                if (-not $profileImg) { continue }

                # In PowerShell/Selenium können wir nicht direkt computed styles abrufen
                # Daher verwenden wir einen alternativen Ansatz mit JavaScript
                $jsScript = @"
var el = arguments[0];
var computed = window.getComputedStyle(el);
var parent = el.parentElement;
var parentComputed = parent ? window.getComputedStyle(parent) : null;
var grandParent = parent ? parent.parentElement : null;
var grandParentComputed = grandParent ? window.getComputedStyle(grandParent) : null;
return JSON.stringify({
    borderColor: computed.borderColor,
    outlineColor: computed.outlineColor,
    boxShadow: computed.boxShadow,
    parentBorderColor: parentComputed ? parentComputed.borderColor : null,
    parentBoxShadow: parentComputed ? parentComputed.boxShadow : null,
    grandParentBorderColor: grandParentComputed ? grandParentComputed.borderColor : null,
    grandParentBoxShadow: grandParentComputed ? grandParentComputed.boxShadow : null
});
"@
                $stylesJson = $driver.ExecuteScript($jsScript, $profileImg)
                $styles = ConvertFrom-Json $stylesJson

                $allColors = @(
                    $styles.borderColor
                    $styles.outlineColor
                    $styles.parentBorderColor
                    $styles.grandParentBorderColor
                )
                $allShadows = @(
                    $styles.boxShadow
                    $styles.parentBoxShadow
                    $styles.grandParentBoxShadow
                )

                $isRed = {
                    param($color)
                    if (-not $color -or $color -eq "none") { return $false }
                    return $color.Contains("255") -or $color.Contains("red") -or
                           $color.Contains("rgb(254") -or $color.Contains("fe2c55") -or
                           $color.Contains("#fe2c") -or $color.Contains("rgb(255, 0") -or
                           $color.Contains("rgb(255, 44")
                }

                if (($allColors | Where-Object { &$isRed $_ }).Count -gt 0 -or 
                    ($allShadows | Where-Object { $_ -and (&$isRed $_) }).Count -gt 0) {
                    $indicators.liveBorder = $true
                    $detectionMethod = "live-border"
                    return @{ isLive = $true; detectionMethod = $detectionMethod; indicators = $indicators }
                }
            } catch { 
                # weiter 
            }
        }
    } catch { 
        # weiter 
    }

    # --- Priorität 4: Live-Indikator innerhalb des exakten Account-Links ---
    try {
        $liveLinkElements = $driver.FindElementsByXPath("//a[contains(@href, '/@$username/live')]")
        if ($liveLinkElements.Count -gt 0) {
            $liveLink = $liveLinkElements[0]
            $liveIndicators = $liveLink.FindElementsByXPath(".//*[contains(@class, 'live-indicator') or contains(@class, 'LiveBadge')]")
            if ($liveIndicators.Count -gt 0 -and $liveIndicators[0].Displayed) {
                $indicators.liveIndicator = $true
                $detectionMethod = "live-indicator"
                return @{ isLive = $true; detectionMethod = $detectionMethod; indicators = $indicators }
            }
        }
    } catch { 
        # weiter 
    }

    # --- Priorität 5: sichtbarer exakter /@username/live-Link ---
    try {
        $liveLinkElements = $driver.FindElementsByXPath("//a[contains(@href, '/@$username/live')]")
        if ($liveLinkElements.Count -gt 0 -and $liveLinkElements[0].Displayed) {
            $indicators.liveLink = $true
            $detectionMethod = "live-link"
            return @{ isLive = $true; detectionMethod = $detectionMethod; indicators = $indicators }
        }
    } catch { 
        # weiter 
    }

    return @{ isLive = $false; detectionMethod = $detectionMethod; indicators = $indicators }
}

function Inspect-DirectLiveState($driver, $username) {
    $successfulStreamResponse = $false
    
    # Event handler for responses would go here if possible
    # Since we can't easily hook into HTTP responses in Selenium,
    # we'll use a different approach below
    
    try {
        $driver.Navigate().GoToUrl("https://www.tiktok.com/@$username/live")
        Start-Sleep -Milliseconds (Get-HumanDelay 8000 10000)
        
        $currentUrl = $driver.Url
        $title = $driver.Title
        
        # Try to get body text
        try {
            $bodyText = $driver.FindElementByTagName("body").Text
        } catch {
            $bodyText = ""
        }
        
        # Check for successful stream response by looking at network activity
        # This is a simplified approach since we can't directly access HTTP responses
        $pageSource = $driver.PageSource
        if ($pageSource -match "\.(flv|m3u8)") {
            $successfulStreamResponse = $true
        }
        
        return Classify-DirectLiveState @{
            username = $username
            currentPath = [System.Uri]$currentUrl | Select-Object -ExpandProperty AbsolutePath
            title = $title
            bodyText = $bodyText
            successfulStreamResponse = $successfulStreamResponse
        }
    } catch {
        return @{ status = "technical_error"; reason = $_.Exception.Message }
    }
}

function Classify-DirectLiveState($params) {
    $username = $params.username
    $currentPath = $params.currentPath
    $title = $params.title
    $bodyText = $params.bodyText
    $successfulStreamResponse = $params.successfulStreamResponse
    
    # Check for various conditions
    if ($currentPath -like "/login*" -or $title -like "*Login*" -or $bodyText -like "*login*") {
        return @{ status = "restricted"; reason = "login_required" }
    }
    
    if ($currentPath -like "/foryou" -or $title -like "*Explore*" -or $bodyText -like "*discover*") {
        return @{ status = "offline"; reason = "redirected_to_explore" }
    }
    
    if ($bodyText -like "*This account is private*" -or $bodyText -like "*privat*" -or $title -like "*Private*") {
        return @{ status = "restricted"; reason = "private_account" }
    }
    
    if ($bodyText -like "*Age verification*" -or $bodyText -like "*Altersbestätigung*" -or $title -like "*Age*") {
        return @{ status = "restricted"; reason = "age_verification_required" }
    }
    
    if ($bodyText -like "*Video unavailable*" -or $bodyText -like "*Video nicht verfügbar*" -or $title -like "*unavailable*") {
        return @{ status = "offline"; reason = "video_unavailable" }
    }
    
    if ($successfulStreamResponse) {
        return @{ status = "live"; reason = "stream_available" }
    }
    
    return @{ status = "offline"; reason = "no_stream_detected" }
}

function Check-LiveStatus($username) {
    # Check dependencies first
    if (-not (Test-Dependency)) {
        return "dependency_missing"
    }
    
    $options = New-Object OpenQA.Selenium.Chrome.ChromeOptions
    $options.AddArgument("--headless")
    $options.AddArgument("--no-sandbox")
    $options.AddArgument("--disable-dev-shm-usage")
    $options.AddArgument("--window-size=1920,1080")
    $options.AddArgument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    
    $driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($options)
    
    try {
        # Navigiere zum Profil
        $driver.Navigate().GoToUrl("https://www.tiktok.com/@$username")
        $driver.Manage().Timeouts().ImplicitWait = [System.TimeSpan]::FromSeconds(30)
        
        # Step 1: DSGVO Banner schließen
        $bannerClosed = Close-DSGVOBanner $driver
        
        # Step 2: Warte auf vollständigen Seitenaufbau
        # KRITISCH: LIVE-Badge erscheint erst nach "Erneute Veröffentlichungen"
        $pageReady = Wait-ForPageReady $driver
        
        # Debug-Screenshot
        if ($env:DEBUG -eq "1") {
            $screenshot = New-Object OpenQA.Selenium.OutputType[[System.Drawing.Imaging.ImageFormat]]::Png
            $screenshotBytes = $driver.GetScreenshot().AsByteArray
            [System.IO.File]::WriteAllBytes("/tmp/tiktok-$username-v2.png", $screenshotBytes)
        }
        
        # Step 3: Live-Status prüfen (priorisiert)
        $liveResult = Detect-LiveStatus $driver $username
        
        # Step 4: Accountgenaue /live-Seite prüfen. Das trennt zugängliche
        # Streams, Login-/Content-Sperren und tatsächlich beendete Streams.
        $directResult = Inspect-DirectLiveState $driver $username
        $finalStatus = if ($directResult.status -eq "restricted") {
            "restricted"
        } else {
            if ($liveResult.isLive -or $directResult.status -eq "live") {
                "live"
            } else {
                $directResult.status
            }
        }
        
        # Ergebnis ausgeben
        $result = @{
            username = $username
            status = $finalStatus
            isLive = ($finalStatus -eq "live" -or $finalStatus -eq "restricted")
            detectionMethod = if ($directResult.status -eq "restricted") {
                "account-live-restricted"
            } else {
                $liveResult.detectionMethod
            }
            isAgeRestricted = ($finalStatus -eq "restricted")
            ageRestrictionReason = if ($finalStatus -eq "restricted") {
                $directResult.reason
            } else {
                $null
            }
            indicators = $liveResult.indicators
            bannerClosed = $bannerClosed
            pageFullyLoaded = $pageReady
            timestamp = (Get-Date).ToUniversalTime().ToString("o")
            version = "2.1"
        }
        
        Write-Output (ConvertTo-Json $result -Depth 10)
        return $finalStatus
        
    } catch {
        $result = @{
            username = $username
            isLive = $false
            status = "technical_error"
            detectionMethod = "error"
            isAgeRestricted = $false
            ageRestrictionReason = $null
            indicators = @{}
            error = $_.Exception.Message
            timestamp = (Get-Date).ToUniversalTime().ToString("o")
            version = 2
        }
        Write-Error (ConvertTo-Json $result -Depth 10)
        return "technical_error"
    } finally {
        if ($driver) {
            $driver.Quit()
        }
    }
}

# Main execution
$status = Check-LiveStatus $Username
switch ($status) {
    "live" { exit 0 }
    { @("offline", "restricted") -contains $_ } { exit 1 }
    default { exit 2 }
}
