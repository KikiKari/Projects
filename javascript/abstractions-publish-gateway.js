#!/usr/bin/env node
// abstractions-publish-gateway.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
// Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

// Workspace-visible wrapper for the gateway publish job.
const { spawn } = require('child_process');
const path = require('path');

const scriptPath = path.join('/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh');

const child = spawn(scriptPath, process.argv.slice(2), {
  stdio: 'inherit'
});

child.on('error', (err) => {
  console.error(`Failed to start script: ${err.message}`);
  process.exit(1);
});

child.on('close', (code) => {
  process.exit(code);
});
