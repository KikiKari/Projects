#!/usr/bin/env node
// server-maintenance.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/server-maintenance.sh
// auch in: OpenClaw@gateway2:scripts/server-maintenance.sh
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

// Server Maintenance Script
// RAM: 8GB, Uhr: Europe/Berlin

const fs = require('fs');
const { execSync } = require('child_process');

const LOG_FILE = "/var/log/server-maintenance.log";
const DATE = new Date().toLocaleString('sv-SE', { timeZone: 'Europe/Berlin' }).replace(' ', ' ');
const HOST = require('os').hostname();

// Farben für Terminal
const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const NC = '\x1b[0m';

function log(message) {
    const logMessage = `[${DATE}] ${message}`;
    console.log(logMessage);
    fs.appendFileSync(LOG_FILE, logMessage + '\n');
}

log("=== Server Maintenance Check ===");

// 1. APT Update Check
log("Checking for updates...");
try {
    const aptUpdateOutput = execSync('apt update -qq 2>&1', { encoding: 'utf8' });
    const lastLines = aptUpdateOutput.split('\n').slice(-5).join('\n');
    log(lastLines);
    
    const upgradableOutput = execSync('apt list --upgradable 2>/dev/null', { encoding: 'utf8' });
    const updates = upgradableOutput.trim() ? upgradableOutput.split('\n').length - 1 : 0;
    if (updates > 0) {
        log(`⚠️ ${updates} packages can be upgraded`);
    }
} catch (error) {
    log(`Error checking updates: ${error.message}`);
}

// 2. RAM Check (8GB total)
log("Checking RAM usage...");
const RAM_TOTAL = 8192; // 8GB in MB
const freeOutput = execSync('free -m', { encoding: 'utf8' });
const ramLine = freeOutput.split('\n')[1];
const RAM_USED = parseInt(ramLine.split(/\s+/)[2]);
const RAM_PERCENT = Math.round((RAM_USED * 100) / RAM_TOTAL);
log(`RAM: ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PERCENT}%)`);

if (RAM_PERCENT > 90) {
    log("🔴 WARNING: RAM usage > 90%!");
} else if (RAM_PERCENT > 80) {
    log("🟡 WARNING: RAM usage > 80%");
}

// 3. Disk Space Check
log("Checking disk space...");
try {
    const dfOutput = execSync('df -h /', { encoding: 'utf8' });
    const diskLine = dfOutput.split('\n')[1];
    const diskParts = diskLine.split(/\s+/);
    const used = diskParts[2];
    const total = diskParts[1];
    const percent = diskParts[4];
    log(`Disk: ${used} / ${total} (${percent} used)`);
    
    const DISK_PERCENT = parseInt(percent.replace('%', ''));
    if (DISK_PERCENT > 90) {
        log("🔴 WARNING: Disk > 90%!");
    } else if (DISK_PERCENT > 80) {
        log("🟡 WARNING: Disk > 80%");
    }
} catch (error) {
    log(`Error checking disk space: ${error.message}`);
}

// 4. NTP Check
log("Checking NTP sync...");
try {
    const ntpStatus = execSync('timedatectl status', { encoding: 'utf8' });
    if (ntpStatus.includes("NTP synchronized: yes")) {
        log("✅ NTP synchronized");
    } else {
        log("⚠️ NTP not synchronized");
    }
} catch (error) {
    log(`Error checking NTP: ${error.message}`);
}

// 5. OpenClaw Gateway Status
log("Checking OpenClaw Gateway...");
try {
    execSync('systemctl is-active --quiet openclaw-gateway');
    log("✅ OpenClaw Gateway running");
} catch (error) {
    log("🔴 OpenClaw Gateway NOT running!");
    try {
        execSync('systemctl restart openclaw-gateway');
    } catch (restartError) {
        log(`Failed to restart OpenClaw Gateway: ${restartError.message}`);
    }
}

// 6. Load Average
try {
    const uptimeOutput = execSync('uptime', { encoding: 'utf8' });
    const loadMatch = uptimeOutput.match(/load average:\s*([0-9]+\.?[0-9]*)/);
    const LOAD = loadMatch ? loadMatch[1] : 'unknown';
    log(`Load Average: ${LOAD}`);
} catch (error) {
    log(`Error getting load average: ${error.message}`);
}

log("=== Maintenance Complete ===");
log("");
