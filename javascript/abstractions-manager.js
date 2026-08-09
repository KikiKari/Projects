#!/usr/bin/env node
// abstractions-manager.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

const { spawn } = require('child_process');
const path = require('path');

const scriptPath = path.join('/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh');

const child = spawn(scriptPath, process.argv.slice(2), {
  stdio: 'inherit'
});

child.on('error', (err) => {
  console.error(`Fehler beim Ausführen des Scripts: ${err.message}`);
  process.exit(1);
});

child.on('close', (code) => {
  process.exit(code);
});
