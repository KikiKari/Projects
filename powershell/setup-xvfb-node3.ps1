#!/usr/bin/env pwsh
# setup-xvfb-node3.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/setup-xvfb-node3.sh
# auch in: OpenClaw@gateway2:scripts/setup-xvfb-node3.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Xvfb Setup für Node 3 (xNetX VPS)
# Erstellt: 2026-04-09
# Hinweis: Altes VNC-Setup wird entfernt

Write-Output "=== Xvfb + Chromium Setup für Node 3 ==="
Write-Output "=== Entferne altes VNC-Setup ==="

# Altes VNC stoppen & entfernen (falls vorhanden)
try {
    Get-Service "vncserver*" | Stop-Service -Force -ErrorAction SilentlyContinue
    Get-Service "vncserver*" | Set-Service -StartupType Disabled -ErrorAction SilentlyContinue
} catch {
    Write-Warning "Konnte VNC-Dienste nicht stoppen oder deaktivieren."
}

# Entferne VNC-Pakete (Beispielhaft, da Paketnamen variieren können)
$packagesToRemove = @("tightvncserver", "tigervnc-standalone-server")
foreach ($pkg in $packagesToRemove) {
    if (Get-Command "apt-get" -ErrorAction SilentlyContinue) {
        try {
            sudo apt-get remove -y $pkg 2>$null
        } catch {
            Write-Verbose "Paket '$pkg' nicht gefunden oder konnte nicht entfernt werden."
        }
    }
}

# Entferne VNC-Konfigurationsdateien
$vncPaths = @("$env:HOME/.vnc", "/tmp/.X11-unix/X*")
foreach ($path in $vncPaths) {
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
    }
}

Write-Output "=== Installiere Xvfb + Chromium ==="

# Update & Install
if (!(Get-Command "apt-get" -ErrorAction SilentlyContinue)) {
    Write-Error "Dieses Skript benötigt ein Debian-basiertes System mit apt-get."
    exit 1
}

sudo apt-get update
$packagesToInstall = @(
    "xvfb",
    "chromium",
    "chromium-driver",
    "fonts-liberation",
    "libappindicator3-1",
    "libasound2",
    "libatk-bridge2.0-0",
    "libatk1.0-0",
    "libcups2",
    "libgtk-3-0",
    "libnspr4",
    "libnss3",
    "libxss1",
    "xdg-utils"
)

$installCmd = "sudo apt-get install -y " + ($packagesToInstall -join " ")
Invoke-Expression $installCmd

# Xvfb Systemd Service erstellen
$xvfbServiceContent = @"
[Unit]
Description=X Virtual Framebuffer
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
"@

Set-Content -Path "/etc/systemd/system/xvfb.service" -Value $xvfbServiceContent

# Service aktivieren
sudo systemctl daemon-reload
sudo systemctl enable xvfb
sudo systemctl start xvfb

Write-Output "=== Xvfb läuft auf DISPLAY :99 ==="
Write-Output "Chromium Version:"
try {
    chromium --version
} catch {
    Write-Output "Chromium nicht gefunden"
}

Write-Output "=== Setup abgeschlossen ==="
Write-Output "=== Altes VNC-Setup wurde entfernt ==="
