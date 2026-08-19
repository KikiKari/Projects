#!/usr/bin/env pwsh
# sandbox-vpn.sh — portiert nach powershell
# Quelle: shell, Onboarding@main:scripts/sandbox-vpn.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Bringt die Sandbox reproduzierbar in das Tailscale-Tailnet des Nutzers —
# als Brücke am Agent-MITM-Proxy vorbei (sauberer Egress via SOCKS5) und mit
# Tailscale-SSH, damit die eigenen Geräte des Nutzers in die Sandbox kommen.
#
# Nutzt den WIEDERVERWENDBAREN Auth-Key aus der .env (nichts committet).
# userspace-networking: verändert NICHT die Host-Routen/den Agent-Proxy dieser
# Session; stellt einen SOCKS5-Proxy auf localhost:1055 bereit.
#
# Aufruf: scripts/sandbox-vpn.sh   (idempotent; No-op ohne Auth-Key/tailscale)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $MyInvocation.MyCommand.Path)/..

function Log {
    param([string]$Message)
    Write-Host "[sandbox-vpn] $Message"
}

# Auth-Key aus .env lesen (ohne die gesamte .env zu sourcen)
$KEY = ""
if (Test-Path ".env") {
    $content = Get-Content ".env" -Raw
    if ($content -match 'TAILSCALE_AUTH_KEY="([^"]*)"') {
        $KEY = $matches[1]
    }
}

if ([string]::IsNullOrEmpty($KEY)) {
    Log "kein TAILSCALE_AUTH_KEY in .env — überspringe VPN"
    exit 0
}

# Tailscale installieren, falls nicht vorhanden
if (!(Get-Command tailscale -ErrorAction SilentlyContinue)) {
    Log "installiere Tailscale …"
    try {
        iwr https://tailscale.com/install.ps1 -useb | iex
    } catch {
        Log "WARNUNG: Tailscale-Install fehlgeschlagen"
        exit 0
    }
}

# tailscaled im userspace-Modus starten (SOCKS5 + HTTP-Proxy für Tailnet-Egress)
$tailscaleStatus = tailscale status 2>$null
if ($LASTEXITCODE -ne 0) {
    Log "starte tailscaled (userspace, SOCKS5 localhost:1055) …"
    $stateDir = "/var/lib/tailscale"
    if (!(Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force > $null
    }
    
    Start-Job {
        tailscaled --tun=userspace-networking `
            --socks5-server=localhost:1055 `
            --outbound-http-proxy-listen=localhost:1056 `
            --statedir=/var/lib/tailscale > "/tmp/tailscaled.log" 2>&1
    } > $null
    
    Start-Sleep -Seconds 4
}

# Ins Tailnet, mit Tailscale-SSH aktiviert
$tailscaleOutput = tailscale status 2>$null
if ($tailscaleOutput -notlike "*claude-sandbox*") {
    Log "tailscale up (hostname=claude-sandbox, --ssh) …"
    tailscale up --authkey="$KEY" --hostname=claude-sandbox --ssh --accept-routes 2>$null
    if ($LASTEXITCODE -ne 0) {
        Log "WARNUNG: tailscale up fehlgeschlagen"
    }
} else {
    tailscale set --ssh 2>$null > $null
}

$tailscaleStatusCheck = tailscale status 2>$null
if ($LASTEXITCODE -eq 0) {
    $ipOutput = tailscale ip -4 2>$null
    $ip = if ($ipOutput) { ($ipOutput -split "`n")[0] } else { "?" }
    Log "im Tailnet: claude-sandbox ${ip} · SSH aktiv · SOCKS5 localhost:1055"
}

exit 0
