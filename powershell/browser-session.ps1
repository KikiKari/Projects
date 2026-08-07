#!/usr/bin/env pwsh
# browser-session.mjs — portiert nach powershell
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

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
    [string]$cmd,
    [string]$target,
    [string[]]$rest
)

# Hilfsfunktionen für Parameterverarbeitung
function Get-FlagValue {
    param([string]$name, [string]$default)
    $index = [System.Array]::IndexOf($rest, "--$name")
    if ($index -ge 0 -and $index + 1 -lt $rest.Count) {
        return $rest[$index + 1]
    }
    return $default
}

function Has-Flag {
    param([string]$name)
    return ($rest -contains "--$name")
}

# Umgebungsvariablen laden
function Load-Env {
    $envPath = Join-Path $REPO ".env"
    $out = @{}
    if (Test-Path $envPath) {
        Get-Content $envPath | ForEach-Object {
            if ($_ -match '^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?\s*$') {
                $out[$matches[1]] = $matches[2]
            }
        }
    }
    return $out
}

# Cookie Consent akzeptieren
function Accept-Cookies {
    param($page)
    $labels = @(
        "Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
        "Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
        "Allow all", "Akzeptieren", "Accept", "Got it", "Agree"
    )
    
    foreach ($name in $labels) {
        try {
            $btn = $page | Get-PlaywrightElement -Role "button" -Name $name -First
            if ($btn | Test-PlaywrightElementVisible -Timeout 800) {
                $btn | Invoke-PlaywrightClick -Timeout 1500
                return $name
            }
        } catch { }
    }
    
    # Generische Consent-IDs
    $selectors = @("#onetrust-accept-btn-handler", "[aria-label*='accept' i]", "button[title*='accept' i]")
    foreach ($sel in $selectors) {
        try {
            $el = $page | Get-PlaywrightElement -Selector $sel -First
            if ($el | Test-PlaywrightElementVisible -Timeout 500) {
                $el | Invoke-PlaywrightClick -Timeout 1500
                return $sel
            }
        } catch { }
    }
    return $null
}

# Hauptskript
$ErrorActionPreference = "Stop"

# Pfad-Konfiguration
$scriptPath = $MyInvocation.MyCommand.Path
$REPO = Split-Path (Split-Path $scriptPath -Parent) -Parent
$PROFILE_DIR = if ($env:BROWSER_PROFILE_DIR) { $env:BROWSER_PROFILE_DIR } else { Join-Path $REPO ".browser-profile" }
$CHROME = @("/usr/bin/google-chrome-stable", "/usr/bin/google-chrome") | Where-Object { Test-Path $_ } | Select-Object -First 1

# Profil-Verzeichnis erstellen
if (!(Test-Path $PROFILE_DIR)) {
    New-Item -ItemType Directory -Path $PROFILE_DIR -Force | Out-Null
}

# Proxy-Konfiguration
$SOCKS = Get-FlagValue "socks" $null
if ($SOCKS) {
    $PROXY = "socks5://$SOCKS"
} else {
    $PROXY = $env:HTTPS_PROXY ?? $env:https_proxy ?? $null
}

# Browser-Kontext starten
$browserArgs = @(
    "--no-sandbox",
    "--autoplay-policy=no-user-gesture-required",
    "--disable-blink-features=AutomationControlled"
)

if ($PROXY) {
    $browserArgs += "--ssl-version-max=tls1.2"
}

$ctx = Start-PlaywrightChromium -UserDataDir $PROFILE_DIR -Headless:$false -ExecutablePath $CHROME -ViewportWidth 1440 -ViewportHeight 900 -AcceptDownloads -IgnoreHTTPSErrors:(Has-Flag "insecure") -Proxy:$PROXY -ProxyBypass "localhost,127.0.0.1,::1" -Args $browserArgs
$page = $ctx.Pages[0] ?? ($ctx | New-PlaywrightPage)

try {
    if ($cmd -eq "state") {
        $cookies = $ctx | Get-PlaywrightCookies
        $domains = $cookies.Domain | Sort-Object -Unique | Sort-Object
        Write-Host "Profil: $PROFILE_DIR"
        Write-Host "$($cookies.Count) Cookies über $($domains.Count) Domains:"
        $domains | ForEach-Object { Write-Host "  $_" }
    }
    elseif ($cmd -eq "open" -or $cmd -eq "shot") {
        if (-not $target) { throw "URL fehlt" }
        $page | Invoke-PlaywrightGoto -Url $target -WaitUntil "domcontentloaded" -Timeout 60000
        $waitTime = [int](Get-FlagValue "wait" "2500")
        Start-Sleep -Milliseconds $waitTime
        $accepted = Accept-Cookies $page
        if ($accepted) { Write-Host "Cookie-Consent bestätigt via: $accepted" }
        Start-Sleep -Milliseconds 1000
        $out = Get-FlagValue "out" (Join-Path "/tmp" "browser-$((Get-Date).ToFileTime()).png")
        $page | Save-PlaywrightScreenshot -Path $out -FullPage:(Has-Flag "full")
        Write-Host "Screenshot: $out"
        Write-Host "URL final: $($page.Url)"
    }
    elseif ($cmd -eq "login") {
        if (-not $target) { throw "URL fehlt" }
        $envVars = Load-Env
        $user = $envVars[(Get-FlagValue "env-user" "")] ?? (Get-FlagValue "user" "")
        $pass = $envVars[(Get-FlagValue "env-pass" "")] ?? (Get-FlagValue "pass" "")
        $page | Invoke-PlaywrightGoto -Url $target -WaitUntil "domcontentloaded" -Timeout 60000
        Start-Sleep -Milliseconds 2500
        Accept-Cookies $page | Out-Null
        if ($user) {
            $uf = Get-FlagValue "user-field" "input[type=email], input[name=email], input[name=username], input[id*=email i]"
            ($page | Get-PlaywrightElement -Selector $uf -First) | Set-PlaywrightElementValue -Value $user -Timeout 8000
        }
        if ($pass) {
            $pf = Get-FlagValue "pass-field" "input[type=password]"
            ($page | Get-PlaywrightElement -Selector $pf -First) | Set-PlaywrightElementValue -Value $pass -Timeout 8000
        }
        $out = Get-FlagValue "out" (Join-Path "/tmp" "login-$((Get-Date).ToFileTime()).png")
        $page | Save-PlaywrightScreenshot -Path $out
        Write-Host "Login-Formular ausgefüllt (user=$(@{true="gesetzt";false="-"}[$user.Length -gt 0]), pass=$(@{true="gesetzt";false="-"}[$pass.Length -gt 0])). Screenshot: $out"
        Write-Host "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung."
    }
    else {
        Write-Host "Befehle: open <URL> | shot <URL> | login <URL> | state"
    }
} finally {
    $ctx | Stop-PlaywrightContext  # Profil (Cookies) bleibt auf Platte erhalten
}
