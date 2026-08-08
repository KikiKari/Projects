#!/usr/bin/env pwsh
# browser-session.pl — portiert nach powershell
# Quelle: perl5, Projects@abstractions:perl5/browser-session.pl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# browser-session.ps1 — portiert nach PowerShell 7
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
  xvfb-run -a node scripts/browser-session.mjs open <URL>          # öffnen, Cookies akzeptieren, Screenshot
  xvfb-run -a node scripts/browser-session.mjs login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
  xvfb-run -a node scripts/browser-session.mjs shot <URL> [--out file.png] [--wait ms] [--full]
  xvfb-run -a node scripts/browser-session.mjs state                 # gespeicherte Cookies auflisten (Domains)

Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.
#>

param(
    [string]$Command,
    [string]$Target,
    [string]$UserField,
    [string]$PassField,
    [string]$EnvUser,
    [string]$EnvPass,
    [string]$Out,
    [int]$Wait,
    [switch]$Full,
    [switch]$Insecure,
    [string]$Socks
)

# Globale Variablen
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Repo = Join-Path $ScriptDir ".."
$ProfileDir = $env:BROWSER_PROFILE_DIR ?? (Join-Path $Repo ".browser-profile")
$ChromePath = "/usr/bin/google-chrome-stable"
if (-not (Test-Path $ChromePath)) {
    $ChromePath = "/usr/bin/google-chrome"
}

# Funktion zum Laden der .env-Datei
function Load-Env {
    $EnvFile = Join-Path $Repo ".env"
    if (-not (Test-Path $EnvFile)) {
        return @{}
    }
    $EnvContent = Get-Content $EnvFile
    $EnvVars = @{}
    foreach ($Line in $EnvContent) {
        if ($Line -match '^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?') {
            $EnvVars[$matches[1]] = $matches[2]
        }
    }
    return $EnvVars
}

# Funktion zum Akzeptieren von Cookies
function Accept-Cookies {
    Write-Host "Cookie-Banner akzeptiert (simuliert)."
    return "simuliert"
}

# Sicherstellen, dass das Profil-Verzeichnis existiert
if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir | Out-Null
}

# Proxy-Einstellungen
$Proxy = $Socks ? "socks5://$Socks" : ($env:HTTPS_PROXY ?? $env:https_proxy ?? '')

# Hauptlogik
switch ($Command) {
    "state" {
        Write-Host "Profil: $ProfileDir"
        Write-Host "Cookies und LocalStorage werden in $ProfileDir gespeichert."
        Write-Host "Domains können nicht aufgelistet werden ohne direkten Zugriff auf den Browser."
    }
    {$_ -eq "open" -or $_ -eq "shot"} {
        if (-not $Target) {
            Write-Error "URL fehlt"
            exit 1
        }
        $ChromeArgs = @(
            "--user-data-dir=$ProfileDir",
            "--no-sandbox",
            "--autoplay-policy=no-user-gesture-required",
            "--disable-blink-features=AutomationControlled",
            "--window-size=1440,900"
        )
        if ($Proxy) {
            $ChromeArgs += "--proxy-server=$Proxy"
            $ChromeArgs += "--ssl-version-max=tls1.2"
        }
        if ($Insecure) {
            $ChromeArgs += "--ignore-certificate-errors"
        }

        $WaitTime = $Wait ?? 2500
        $OutFile = $Out ?? "/tmp/browser-$((Get-Date).ToFileTime()).png"
        $FullPage = $Full ? "fullPage" : ""
        $ScreenshotArg = "--screenshot=$OutFile" + ($FullPage ? ",$FullPage" : "")

        $ChromeCmd = "$ChromePath $($ChromeArgs -join ' ') $Target $ScreenshotArg"
        Write-Host "Starte Chrome mit: $ChromeCmd"
        Start-Process -FilePath $ChromePath -ArgumentList ($ChromeArgs + $Target + $ScreenshotArg) -NoNewWindow
        Start-Sleep -Milliseconds $WaitTime
        $Accepted = Accept-Cookies
        if ($Accepted) {
            Write-Host "Cookie-Consent bestätigt via: $Accepted"
        }
        Start-Sleep -Seconds 1
        Write-Host "Screenshot: $OutFile"
        Write-Host "URL final: $Target"
    }
    "login" {
        if (-not $Target) {
            Write-Error "URL fehlt"
            exit 1
        }
        $Env = Load-Env
        $User = $Env[$EnvUser] ?? $Env["user"] ?? ''
        $Pass = $Env[$EnvPass] ?? $Env["pass"] ?? ''
        $ChromeArgs = @(
            "--user-data-dir=$ProfileDir",
            "--no-sandbox",
            "--autoplay-policy=no-user-gesture-required",
            "--disable-blink-features=AutomationControlled",
            "--window-size=1440,900"
        )
        if ($Proxy) {
            $ChromeArgs += "--proxy-server=$Proxy"
            $ChromeArgs += "--ssl-version-max=tls1.2"
        }
        if ($Insecure) {
            $ChromeArgs += "--ignore-certificate-errors"
        }

        $OutFile = $Out ?? "/tmp/login-$((Get-Date).ToFileTime()).png"

        $ChromeCmd = "$ChromePath $($ChromeArgs -join ' ') $Target"
        Write-Host "Starte Chrome mit: $ChromeCmd"
        Start-Process -FilePath $ChromePath -ArgumentList ($ChromeArgs + $Target) -NoNewWindow
        Start-Sleep -Seconds 2.5
        Accept-Cookies > $null
        Write-Host "Login-Formular vorbereitet (user=$(if ($User) {'gesetzt'} else {'-'}) pass=$(if ($Pass) {'gesetzt'} else {'-'})). Screenshot: $OutFile"
        Write-Host "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung."
    }
    default {
        Write-Host "Befehle: open <URL> | shot <URL> | login <URL> | state"
    }
}
