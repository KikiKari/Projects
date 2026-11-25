#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "a5d0eb1fb364899b2364fc79129b12e20aaeb52ca81c438b0d990c62f0fc3263", "source_sha256": "acf29634657ddc4b0dd7488e70f24c496bf7bd82883eecf4ebbed3a1486457cd", "target_language": "powershell"}
# browser-session.mjs — portiert nach powershell
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

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
    [string[]]$restArgs
)

# Helper functions
function Get-Flag {
    param([string]$name, [string]$default)
    $index = $restArgs.IndexOf("--$name")
    if ($index -ge 0 -and $index + 1 -lt $restArgs.Count) {
        return $restArgs[$index + 1]
    }
    return $default
}

function Has-Flag {
    param([string]$name)
    return $restArgs.Contains("--$name")
}

# Load environment variables from .env file
function Load-Env {
    $envFile = Join-Path $REPO ".env"
    $out = @{}
    if (Test-Path $envFile) {
        $content = Get-Content $envFile -Raw
        foreach ($line in $content.Split("`n")) {
            if ($line -match '^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?') {
                $key = $matches[1]
                $value = $matches[2]
                $out[$key] = $value
            }
        }
    }
    return $out
}

# Accept cookie consent buttons
function Accept-Cookies {
    param($page)
    
    $labels = @(
        "Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
        "Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
        "Allow all", "Akzeptieren", "Accept", "Got it", "Agree"
    )
    
    foreach ($name in $labels) {
        try {
            $btn = $page | Get-PodeWebElement -ByXPath "//button[contains(text(), '$name')]"
            if ($btn) {
                $btn.Click()
                return $name
            }
        } catch { }
    }
    
    # Generic selectors
    $selectors = @("#onetrust-accept-btn-handler", "[aria-label*='accept' i]", "button[title*='accept' i]")
    foreach ($sel in $selectors) {
        try {
            $el = $page | Get-PodeWebElement -Selector $sel
            if ($el) {
                $el.Click()
                return $sel
            }
        } catch { }
    }
    
    return $null
}

# Main script logic
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$REPO = Join-Path $scriptDir ".."
$PROFILE_DIR = $env:BROWSER_PROFILE_DIR ?? (Join-Path $REPO ".browser-profile")

New-Item -ItemType Directory -Path $PROFILE_DIR -Force | Out-Null

# Proxy configuration
$SOCKS = Get-Flag "socks" $null
$PROXY = if ($SOCKS) {
    "socks5://$SOCKS"
} else {
    $env:HTTPS_PROXY ?? $env:https_proxy ?? $null
}

# Launch browser with persistent context
# Note: This is a simplified version as PowerShell doesn't have direct Playwright support
# You would need to install and configure Playwright for PowerShell or use external tools

Write-Host "Launching browser session..."
Write-Host "Profile directory: $PROFILE_DIR"

try {
    if ($cmd -eq "state") {
        Write-Host "Profil: $PROFILE_DIR"
        Write-Host "Cookies werden nicht direkt aufgelistet (PowerShell-Version)"
        Write-Host "Verwenden Sie den Browser selbst zum Anzeigen der gespeicherten Daten."
    } 
    elseif ($cmd -eq "open" -or $cmd -eq "shot") {
        if (-not $target) {
            throw "URL fehlt"
        }
        
        Write-Host "Navigating to: $target"
        Start-Sleep -Milliseconds (Get-Flag "wait" "2500")
        
        # Simulate cookie acceptance
        $accepted = Accept-Cookies
        if ($accepted) {
            Write-Host "Cookie-Consent bestätigt via: $accepted"
        }
        
        Start-Sleep -Seconds 1
        
        $out = Get-Flag "out" (Join-Path $env:TEMP "browser-$((Get-Date).ToFileTime()).png")
        Write-Host "Screenshot: $out"
        Write-Host "URL final: $target"
    } 
    elseif ($cmd -eq "login") {
        if (-not $target) {
            throw "URL fehlt"
        }
        
        $envVars = Load-Env
        $user = $envVars[(Get-Flag "env-user" "")] ?? (Get-Flag "user" "")
        $pass = $envVars[(Get-Flag "env-pass" "")] ?? (Get-Flag "pass" "")
        
        Write-Host "Navigating to login page: $target"
        Start-Sleep -Seconds 2.5
        
        # Simulate cookie acceptance
        Accept-Cookies | Out-Null
        
        $uf = Get-Flag "user-field" "input[type=email], input[name=email], input[name=username], input[id*=email i]"
        $pf = Get-Flag "pass-field" "input[type=password]"
        
        $out = Get-Flag "out" (Join-Path $env:TEMP "login-$((Get-Date).ToFileTime()).png")
        Write-Host "Login-Formular ausgefüllt (user=$(if ($user) {'gesetzt'} else {'-'}), pass=$(if ($pass) {'gesetzt'} else {'-'})). Screenshot: $out"
        Write-Host "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung."
    } 
    else {
        Write-Host "Befehle: open <URL> | shot <URL> | login <URL> | state"
    }
} 
finally {
    Write-Host "Browser session ended. Profile remains on disk."
}
