#!/usr/bin/env node
// abstractions-publish-gateway.pl — portiert nach javascript
// Quelle: perl5, Projects@abstractions:perl5/abstractions-publish-gateway.pl
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// abstractions-publish-gateway.sh — portiert nach perl5
// Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
// Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

// Workspace-visible wrapper for the gateway publish job.

const { spawn } = require('child_process');
const path = require('path');

const scriptPath = path.join('/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh');

// Forward all arguments to the shell script
const child = spawn(scriptPath, process.argv.slice(2), {
  stdio: 'inherit'
});

child.on('error', (err) => {
  console.error(`Fehler beim Ausführen des Skripts: ${err.message}`);
  process.exit(1);
});

child.on('close', (code) => {
  process.exit(code);
});
