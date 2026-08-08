#!/usr/bin/env pwsh
# browser-session.py — portiert nach powershell
# Quelle: python, Projects@abstractions:python/browser-session.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Persistente Browser-Sitzung der Sandbox.

.DESCRIPTION
Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.

Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).

Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
  xvfb-run -a pwsh browser-session.ps1 open <URL>          # öffnen, Cookies akzeptieren, Screenshot
  xvfb-run -a pwsh browser-session.ps1 login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
  xvfb-run -a pwsh browser-session.ps1 shot <URL> [--out file.png] [--wait ms] [--full]
  xvfb-run -a pwsh browser-session.ps1 state                 # gespeicherte Cookies auflisten (Domains)

Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("open", "shot", "login", "state")]
    [string]$Command,

    [Parameter(Mandatory=$false)]
    [string]$Url,

    [string]$UserField = "input[type=email], input[name=email], input[name=username], input[id*=email i]",
    
    [string]$PassField = "input[type=password]",
    
    [string]$EnvUser = "",
    
    [string]$EnvPass = "",
    
    [string]$User = "",
    
    [string]$Password = "",
    
    [string]$Out = "",
    
    [int]$Wait = 2500,
    
    [switch]$Full,
    
    [string]$Socks = "",
    
    [switch]$Insecure
)

# Konstanten
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$Repo = Split-Path $ScriptDir -Parent
$ProfileDir = if ($env:BROWSER_PROFILE_DIR) { $env:BROWSER_PROFILE_DIR } else { Join-Path $Repo ".browser-profile" }
$ChromePaths = @("/usr/bin/google-chrome-stable", "/usr/bin/google-chrome")
$Chrome = $ChromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

function Load-Env {
    <#
    .SYNOPSIS
    Lade .env Datei (nur für login-Credentials; nichts wird geloggt)
    #>
    $EnvFile = Join-Path $Repo ".env"
    if (-not (Test-Path $EnvFile)) {
        return @{}
    }
    
    $EnvVars = @{}
    Get-Content $EnvFile | ForEach-Object {
        $Line = $_.Trim()
        if ($Line -and -not $Line.StartsWith("#")) {
            $Parts = $Line -split "=", 2
            if ($Parts.Count -eq 2) {
                $Key = $Parts[0].Trim()
                $Value = $Parts[1].Trim().Trim('"')
                $EnvVars[$Key] = $Value
            }
        }
    }
    return $EnvVars
}

function Accept-Cookies {
    param($Page)
    
    <#
    .SYNOPSIS
    Häufige Cookie-Consent-Buttons klicken (mehrsprachig, best effort).
    #>
    $Labels = @(
        "Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
        "Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
        "Allow all", "Akzeptieren", "Accept", "Got it", "Agree"
    )
    
    foreach ($Name in $Labels) {
        try {
            $Btn = $Page.GetByRole("button", @{name=$Name; exact=$false}).First
            if ($Btn.IsVisible(@{timeout=800})) {
                $Btn.Click(@{timeout=1500})
                return $Name
            }
        } catch {
            # Ignorieren und weitermachen
        }
    }
    
    # Generische Consent-IDs
    $Selectors = @("#onetrust-accept-btn-handler", "[aria-label*='accept' i]", "button[title*='accept' i]")
    foreach ($Sel in $Selectors) {
        try {
            $El = $Page.Locator($Sel).First
            if ($El.IsVisible(@{timeout=500})) {
                $El.Click(@{timeout=1500})
                return $Sel
            }
        } catch {
            # Ignorieren und weitermachen
        }
    }
    
    return $null
}

try {
    # Erstelle Profil-Verzeichnis
    if (-not (Test-Path $ProfileDir)) {
        New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    }
    
    # Proxy-Konfiguration
    $ProxyServer = $null
    if ($Socks) {
        $ProxyServer = "socks5://$Socks"
    } else {
        $ProxyServer = $env:HTTPS_PROXY ?? $env:https_proxy
    }
    
    # Import Playwright .NET assembly
    Add-Type -Path (Join-Path $PSScriptRoot "Playwright.dll")
    
    # Starte Playwright
    $Playwright = [Microsoft.Playwright.Playwright]::CreateAsync().GetAwaiter().GetResult()
    
    # Browser-Argumente vorbereiten
    $BrowserArgs = @(
        "--no-sandbox",
        "--autoplay-policy=no-user-gesture-required",
        "--disable-blink-features=AutomationControlled"
    )
    
    if ($ProxyServer) {
        $BrowserArgs += "--ssl-version-max=tls1.2"
    }
    
    # Starte den Browser mit persistentem Kontext
    $ContextOptions = [Microsoft.Playwright.BrowserTypeLaunchPersistentContextOptions]::new()
    $ContextOptions.Headless = $false
    $ContextOptions.ExecutablePath = $Chrome
    $ContextOptions.Viewport = @{ width = 1440; height = 900 }
    $ContextOptions.AcceptDownloads = $true
    $ContextOptions.IgnoreHTTPSErrors = $Insecure.IsPresent
    
    if ($ProxyServer) {
        $ProxyOptions = [Microsoft.Playwright.Proxy]::new()
        $ProxyOptions.Server = $ProxyServer
        $ProxyOptions.Bypass = "localhost,127.0.0.1,::1"
        $ContextOptions.Proxy = $ProxyOptions
    }
    
    $ContextOptions.Args = $BrowserArgs
    
    $Context = $Playwright.Chromium.LaunchPersistentContextAsync($ProfileDir, $ContextOptions).GetAwaiter().GetResult()
    
    try {
        $Pages = $Context.Pages
        $Page = if ($Pages.Count -gt 0) { $Pages[0] } else { $Context.NewPageAsync().GetAwaiter().GetResult() }
        
        switch ($Command) {
            "state" {
                $Cookies = $Context.CookiesAsync().GetAwaiter().GetResult()
                $Domains = $Cookies | ForEach-Object { $_.Domain } | Sort-Object -Unique
                Write-Output "Profil: $ProfileDir"
                Write-Output "$($Cookies.Count) Cookies über $($Domains.Count) Domains:"
                $Domains | ForEach-Object { Write-Output "  $_" }
            }
            
            {$_ -in "open", "shot"} {
                if (-not $Url) {
                    throw "URL fehlt"
                }
                
                $Page.GotoAsync($Url, @{waitUntil="domcontentloaded"; timeout=60000}).GetAwaiter().GetResult()
                Start-Sleep -Milliseconds $Wait
                
                $Accepted = Accept-Cookies -Page $Page
                if ($Accepted) {
                    Write-Output "Cookie-Consent bestätigt via: $Accepted"
                }
                
                Start-Sleep -Milliseconds 1000
                
                $OutFile = if ($Out) { $Out } else { "/tmp/browser-$([int](Get-Date).ToFileTimeUtc()).png" }
                $Page.ScreenshotAsync(@{path=$OutFile; fullPage=$Full.IsPresent}).GetAwaiter().GetResult()
                Write-Output "Screenshot: $OutFile"
                Write-Output "URL final: $($Page.Url)"
            }
            
            "login" {
                if (-not $Url) {
                    throw "URL fehlt"
                }
                
                $Env = Load-Env
                $UserValue = if ($EnvUser -and $Env.ContainsKey($EnvUser)) { $Env[$EnvUser] } elseif ($User) { $User } else { "" }
                $PasswordValue = if ($EnvPass -and $Env.ContainsKey($EnvPass)) { $Env[$EnvPass] } elseif ($Password) { $Password } else { "" }
                
                $Page.GotoAsync($Url, @{waitUntil="domcontentloaded"; timeout=60000}).GetAwaiter().GetResult()
                Start-Sleep -Milliseconds 2500
                Accept-Cookies -Page $Page | Out-Null
                
                if ($UserValue) {
                    $Page.Locator($UserField).First.FillAsync($UserValue, @{timeout=8000}).GetAwaiter().GetResult()
                }
                
                if ($PasswordValue) {
                    $Page.Locator($PassField).First.FillAsync($PasswordValue, @{timeout=8000}).GetAwaiter().GetResult()
                }
                
                $OutFile = if ($Out) { $Out } else { "/tmp/login-$([int](Get-Date).ToFileTimeUtc()).png" }
                $Page.ScreenshotAsync(@{path=$OutFile}).GetAwaiter().GetResult()
                Write-Output "Login-Formular ausgefüllt (user=$(if ($UserValue) {'gesetzt'} else {'-'}) pass=$(if ($PasswordValue) {'gesetzt'} else {'-'})). Screenshot: $OutFile"
                Write-Output "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung."
            }
            
            default {
                Write-Output "Befehle: open <URL> | shot <URL> | login <URL> | state"
            }
        }
    } finally {
        $Context.CloseAsync().GetAwaiter().GetResult()  # Profil (Cookies) bleibt auf Platte erhalten
        $Playwright.Dispose()
    }
} catch {
    Write-Error "Fehler: $_"
    exit 1
}
