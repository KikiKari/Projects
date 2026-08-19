#!/usr/bin/env pwsh
# sandbox-setup.sh — portiert nach powershell
# Quelle: shell, Onboarding@main:scripts/sandbox-setup.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Provisioniert die Claude-Code-Sandbox (Remote-Umgebung) reproduzierbar:
#   - Node-Dependencies (Frontend, npm)
#   - Python-Dependencies (Backend inkl. pytest)
#   - Medien-Tools: ffmpeg, ImageMagick, GIMP, Blender headless (apt) —
#     Fehlschlag blockiert die Session nicht; --skip-heavy laesst GIMP/Blender aus
# Idempotent: bereits Vorhandenes wird uebersprungen; der Container-Cache der
# Umgebung macht die apt-Installation zum Einmal-Aufwand.

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$SKIP_HEAVY = 0
if ($args.Count -gt 0 -and $args[0] -eq "--skip-heavy") {
    $SKIP_HEAVY = 1
}

Push-Location "$(Split-Path $PSScriptRoot)/.."

function Log {
    param([string]$Message)
    Write-Host "[sandbox-setup] $Message"
}

function AptInstall {
    param(
        [string]$Package,
        [string]$Binary
    )
    
    if (Get-Command $Binary -ErrorAction SilentlyContinue) {
        $versionOutput = & $Binary "--version" 2>&1 | Select-Object -First 1
        Log "$Package bereits vorhanden ($versionOutput)"
        return
    }
    
    Log "Installiere $Package …"
    if (-not $script:APT_UPDATED) {
        $env:DEBIAN_FRONTEND = "noninteractive"
        apt-get update -qq
        $script:APT_UPDATED = $true
    }
    
    try {
        $env:DEBIAN_FRONTEND = "noninteractive"
        apt-get install -y -qq $Package *>$null
    } catch {
        Log "WARNUNG: $Package konnte nicht installiert werden (Netzwerk-Policy?) — Medien-Schritte ggf. eingeschraenkt"
    }
}

Log "Node-Dependencies (npm install) …"
try {
    npm install --no-audit --no-fund *>$null
} catch {
    Log "FEHLER: npm install fehlgeschlagen"
    exit 1
}

Log "Python-Dependencies (backend/requirements-dev.txt) …"
try {
    pip3 install --quiet -r backend/requirements-dev.txt *>$null
} catch {
    Log "FEHLER: pip install fehlgeschlagen"
    exit 1
}

AptInstall "ffmpeg" "ffmpeg"
AptInstall "imagemagick" "convert"
if ($SKIP_HEAVY -eq 0) {
    AptInstall "gimp" "gimp"
    AptInstall "blender" "blender"
}

# Visual QA: echtes Google Chrome (H.264/AAC-Codecs → Videos sichtbar; der
# Playwright-Bundle-Chromium hat keine proprietären Codecs), Xvfb (headed-Läufe
# für echte Web-Logins) und NSS-Tools, um die Proxy-CA in Chromes Trust-Store zu
# importieren. Ohne all das: Videos schwarz bzw. TLS-Fehler beim externen Surfen.
AptInstall "xvfb" "Xvfb"
AptInstall "x11-utils" "xdpyinfo"
AptInstall "libnss3-tools" "certutil"

if (-not (Get-Command google-chrome-stable -ErrorAction SilentlyContinue)) {
    Log "Installiere Google Chrome Stable …"
    $tmpDeb = [System.IO.Path]::GetTempFileName() + ".deb"
    try {
        Invoke-WebRequest -Uri "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -OutFile $tmpDeb
        $env:DEBIAN_FRONTEND = "noninteractive"
        apt-get install -y -qq $tmpDeb *>$null
        $chromeVersion = & google-chrome-stable --version 2>$null
        Log "Chrome installiert: $chromeVersion"
    } catch {
        Log "WARNUNG: Chrome-Installation fehlgeschlagen"
    } finally {
        if (Test-Path $tmpDeb) {
            Remove-Item $tmpDeb -Force
        }
    }
}

# Proxy-CA in Chromes NSS-DB, damit externes HTTPS ohne Zertifikatsfehler läuft.
if ((Get-Command certutil -ErrorAction SilentlyContinue) -and (Test-Path "/root/.ccr/ca-bundle.crt")) {
    $nssdbPath = "$HOME/.pki/nssdb"
    New-Item -ItemType Directory -Path $nssdbPath -Force *>$null
    certutil -d "sql:$nssdbPath" -N --empty-password 2>$null
    if (-not (certutil -d "sql:$nssdbPath" -L 2>$null | Select-String -Pattern "ccr-proxy-ca")) {
        certutil -d "sql:$nssdbPath" -A -t "C,," -n ccr-proxy-ca -i /root/.ccr/ca-bundle.crt 2>$null
        Log "Proxy-CA in Chrome-NSS-Store importiert"
    }
}

# Playwright-Node-Module ins Projekt verlinken (visual-qa.mjs / browser-session.mjs).
if ((Test-Path "node_modules") -and -not (Test-Path "node_modules/playwright")) {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        try {
            npm install --no-audit --no-fund --no-save playwright *>$null
            Log "Playwright (Node) installiert"
        } catch {
            Log "WARNUNG: Playwright-npm-Install fehlgeschlagen"
        }
    }
}

# Git-Push-Weg: Der Session-Git-Proxy (origin) ist read-only. Pushes laufen
# direkt zu github.com mit dem Nutzer-PAT (GH_ACCESS_TOKEN aus Umgebungs-Env
# oder .env, geliefert vom Credential-Helper — kein Secret in der Git-Config).
if (git rev-parse --is-inside-work-tree *>$null) {
    $credentialHelperScript = "$(Get-Location)/.claude/git-credential-pat.sh"
    git config credential."https://x-access-token@github.com".helper "!$credentialHelperScript"
    git remote set-url --push origin "https://x-access-token@github.com/KikiKari/Onboarding.git"
    Log "Git-Push-Route: direkt zu github.com (PAT via Credential-Helper)"
}

# Docker-Daemon fuer Dev-Compose-Verifikation in der Sandbox.
# Docker-Hub-Blobs (cloudfront.docker.com) sind von der Netz-Policy blockiert —
# mirror.gcr.io liefert die Library-Images. Container brauchen zusaetzlich die
# Proxy-CA (siehe docker-compose.sandbox.yml).
if ((Get-Command dockerd -ErrorAction SilentlyContinue) -and -not (docker info *>$null)) {
    Log "Starte Docker-Daemon (Registry-Mirror: mirror.gcr.io) …"
    New-Item -ItemType Directory -Path "/etc/docker" -Force *>$null
    if (-not (Test-Path "/etc/docker/daemon.json")) {
        '{"registry-mirrors":["https://mirror.gcr.io"]}' | Out-File -FilePath "/etc/docker/daemon.json" -Encoding ASCII
    }
    
    Start-Job -ScriptBlock {
        dockerd > /tmp/dockerd.log 2>&1
    } | Out-Null
    
    for ($i = 1; $i -le 15; $i++) {
        if (docker info *>$null) {
            break
        }
        Start-Sleep -Seconds 1
    }
    
    if (docker info *>$null) {
        Log "Docker-Daemon laeuft"
    } else {
        Log "WARNUNG: Docker-Daemon nicht gestartet"
    }
}

Log "Fertig. Versionen:"
& node --version | ForEach-Object { "[sandbox-setup]   node $_" }
& python3 --version | ForEach-Object { "[sandbox-setup]   $_" }
if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
    & ffmpeg -version 2>$null | Select-Object -First 1 | ForEach-Object { "[sandbox-setup]   $_" }
}
if (Get-Command convert -ErrorAction SilentlyContinue) {
    & convert -version 2>$null | Select-Object -First 1 | ForEach-Object { "[sandbox-setup]   $_" }
}
if (Get-Command gimp -ErrorAction SilentlyContinue) {
    & gimp --version 2>$null | Select-Object -First 1 | ForEach-Object { "[sandbox-setup]   $_" }
}
if (Get-Command blender -ErrorAction SilentlyContinue) {
    & blender --version 2>$null | Select-Object -First 1 | ForEach-Object { "[sandbox-setup]   $_" }
}

Pop-Location
exit 0
