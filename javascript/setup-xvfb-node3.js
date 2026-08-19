#!/usr/bin/env node
// setup-xvfb-node3.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/setup-xvfb-node3.sh
// auch in: OpenClaw@gateway2:scripts/setup-xvfb-node3.sh
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

// Xvfb Setup für Node 3 (xNetX VPS)
// Erstellt: 2026-04-09
// Hinweis: Altes VNC-Setup wird entfernt

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function runCommand(command, ignoreErrors = false) {
    try {
        console.log(`Executing: ${command}`);
        const result = execSync(command, { stdio: 'inherit' });
        return result;
    } catch (error) {
        if (ignoreErrors) {
            console.log(`Command failed (ignored): ${command}`);
            return null;
        } else {
            throw error;
        }
    }
}

console.log("=== Xvfb + Chromium Setup für Node 3 ===");
console.log("=== Entferne altes VNC-Setup ===");

// Altes VNC stoppen & entfernen (falls vorhanden)
runCommand('sudo systemctl stop vncserver@* 2>/dev/null', true);
runCommand('sudo systemctl disable vncserver@* 2>/dev/null', true);
runCommand('sudo apt-get remove -y tightvncserver tigervnc-standalone-server 2>/dev/null', true);

// Entferne VNC Dateien
try {
    runCommand('sudo rm -rf ~/.vnc /tmp/.X11-unix/X*', true);
} catch (error) {
    // Ignoriere Fehler beim Löschen
}

console.log("=== Installiere Xvfb + Chromium ===");

// Update & Install
runCommand('sudo apt-get update');
runCommand(`sudo apt-get install -y \
    xvfb \
    chromium \
    chromium-driver \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libxss1 \
    xdg-utils`);

// Xvfb Systemd Service erstellen
const serviceContent = `[Unit]
Description=X Virtual Framebuffer
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target`;

const servicePath = '/etc/systemd/system/xvfb.service';
try {
    fs.writeFileSync(servicePath, serviceContent);
    console.log(`Service file created at ${servicePath}`);
} catch (error) {
    console.error(`Failed to create service file: ${error.message}`);
    process.exit(1);
}

// Service aktivieren
runCommand('sudo systemctl daemon-reload');
runCommand('sudo systemctl enable xvfb');
runCommand('sudo systemctl start xvfb');

console.log("=== Xvfb läuft auf DISPLAY :99 ===");
console.log("Chromium Version:");

try {
    runCommand('chromium --version');
} catch (error) {
    console.log("Chromium nicht gefunden");
}

console.log("=== Setup abgeschlossen ===");
console.log("=== Altes VNC-Setup wurde entfernt ===");
