#!/usr/bin/env node
// test_sync.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:scripts/test_sync.py
// auch in: OpenClaw@gateway2:scripts/test_sync.py
// Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

// Test für Sync-Script

const fs = require('fs');
const path = require('path');

// Add the script path to module search paths
const scriptPath = '/home/openclaw/.openclaw/workspace/scripts';
const syncModulePath = path.join(scriptPath, 'sync_clawhub_git.js');

// Dynamically import the sync module
const { syncToGit, log } = require(syncModulePath);

// Test: db-maintainer ClawHub → Git (DRY-RUN)
console.log("=== TEST: db-maintainer sync (DRY-RUN) ===");
const skill = "db-maintainer";
const result = syncToGit(skill, true);
console.log(`Result: ${result ? 'SUCCESS' : 'FAILED'}`);

console.log("\n=== LOG-Inhalt ===");
try {
    const logContent = fs.readFileSync("/home/openclaw/.openclaw/workspace/logs/sync.log", "utf8");
    console.log(logContent);
} catch (error) {
    console.error("Fehler beim Lesen der Log-Datei:", error.message);
}
