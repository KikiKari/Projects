#!/usr/bin/env pwsh
# setup-xvfb-node2.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/setup-xvfb-node2.sh
# auch in: OpenClaw@gateway2:scripts/setup-xvfb-node2.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Xvfb Setup für Node 2 (Netcup VPS)
# Erstellt: 2026-04-09

Write-Host "=== Xvfb + Chromium Setup für Node 2 ==="

# Update & Install
Write-Host "Aktualisiere Paketliste und installiere benötigte Pakete..."
& sudo apt-get update
if ($LASTEXITCODE -ne 0) {
    Write-Error "Fehler beim Aktualisieren der Paketliste"
    exit 1
}

$packages = @(
    "xvfb"
    "chromium-browser"
    "chromium-chromedriver"
    "fonts-liberation"
    "libappindicator3-1"
    "libasound2"
    "libatk-bridge2.0-0"
    "libatk1.0-0"
    "libcups2"
    "libgtk-3-0"
    "libnspr4"
    "libnss3"
    "libxss1"
    "xdg-utils"
)

& sudo apt-get install -y $packages
if ($LASTEXITCODE -ne 0) {
    Write-Error "Fehler beim Installieren der Pakete"
    exit 1
}

# Xvfb Systemd Service erstellen
$xvfbServiceContent = @"
[Unit]
Description=X Virtual Framebuffer
After=network.target

[Service]
Type=simple
User=openclaw
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
"@

$xvfbServiceContent | sudo tee /etc/systemd/system/xvfb.service > $null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Fehler beim Erstellen des Xvfb-Service"
    exit 1
}

# Service aktivieren
& sudo systemctl daemon-reload
if ($LASTEXITCODE -ne 0) {
    Write-Error "Fehler beim Neuladen der Systemd-Daemon"
    exit 1
}

& sudo systemctl enable xvfb
if ($LASTEXITCODE -ne 0) {
    Write-Error "Fehler beim Aktivieren des Xvfb-Service"
    exit 1
}

& sudo systemctl start xvfb
if ($LASTEXITCODE -ne 0) {
    Write-Error "Fehler beim Starten des Xvfb-Service"
    exit 1
}

Write-Host "=== Xvfb läuft auf DISPLAY :99 ==="
Write-Host "Chromium Version:"

$chromiumVersion = & chromium-browser --version
if ($LASTEXITCODE -eq 0) {
    Write-Host $chromiumVersion
} else {
    Write-Host "Chromium nicht gefunden"
}

Write-Host "=== Setup abgeschlossen ==="
