#!/usr/bin/env node
// setup-xvfb-node2.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/setup-xvfb-node2.sh
// auch in: OpenClaw@gateway2:scripts/setup-xvfb-node2.sh
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

// Xvfb Setup für Node 2 (Netcup VPS)
// Erstellt: 2026-04-09

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function runCommand(command, options = {}) {
    try {
        const result = execSync(command, { 
            stdio: 'inherit',
            ...options
        });
        return result;
    } catch (error) {
        console.error(`Fehler beim Ausführen von: ${command}`);
        process.exit(1);
    }
}

console.log("=== Xvfb + Chromium Setup für Node 2 ===");

// Update & Install
runCommand('sudo apt-get update');
runCommand(`sudo apt-get install -y \
    xvfb \
    chromium-browser \
    chromium-chromedriver \
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
User=openclaw
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target`;

const servicePath = '/etc/systemd/system/xvfb.service';
try {
    fs.writeFileSync(servicePath, serviceContent);
} catch (error) {
    console.error(`Fehler beim Schreiben der Service-Datei: ${servicePath}`);
    process.exit(1);
}

// Service aktivieren
runCommand('sudo systemctl daemon-reload');
runCommand('sudo systemctl enable xvfb');
runCommand('sudo systemctl start xvfb');

console.log("=== Xvfb läuft auf DISPLAY :99 ===");
console.log("Chromium Version:");

try {
    runCommand('chromium-browser --version');
} catch (error) {
    console.log("Chromium nicht gefunden");
}

console.log("=== Setup abgeschlossen ===");
