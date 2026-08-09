#!/usr/bin/env node
// openclaw-maintenance.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

const { spawnSync } = require('child_process');
const path = require('path');

const OPENCLAW_BIN = process.env.OPENCLAW_BIN || path.join(process.env.HOME, '.local', 'bin', 'openclaw');

// Helper function to execute command and check exit code
function runCommand(command, args = [], options = {}) {
  const result = spawnSync(command, args, {
    stdio: 'inherit',
    ...options
  });
  
  if (result.error) {
    console.error(`ERROR: Failed to execute ${command}: ${result.error.message}`);
    process.exit(1);
  }
  
  if (result.status !== 0) {
    console.error(`ERROR: Command failed with exit code ${result.status}: ${command} ${args.join(' ')}`);
    process.exit(result.status);
  }
  
  return result;
}

// Check if OpenClaw binary exists and is executable
try {
  const stat = require('fs').statSync(OPENCLAW_BIN);
  if (!stat.isFile() || !(stat.mode & 0o111)) {
    console.error(`ERROR: OpenClaw binary not found or not executable: ${OPENCLAW_BIN}`);
    process.exit(1);
  }
} catch (err) {
  console.error(`ERROR: OpenClaw binary not found: ${OPENCLAW_BIN}`);
  process.exit(1);
}

console.log(`Using OpenClaw: ${runCommand(OPENCLAW_BIN, ['--version'], { stdio: ['pipe', 'pipe', 'inherit'] }).stdout?.toString().trim() || ''}`);

// === 1. Service-/Config-Drift ===
runCommand(OPENCLAW_BIN, ['doctor']);

// === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
runCommand(OPENCLAW_BIN, ['plugins', 'registry', '--refresh']);

if (process.env.RUN_PLUGIN_UPDATE === '1') {
  runCommand(OPENCLAW_BIN, ['plugins', 'update', '--all']);
} else {
  console.log('Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable.');
}

// === 3. Tasks ===
runCommand(OPENCLAW_BIN, ['tasks', 'maintenance', '--apply']);

// === 4. Sessions – alle Agents auf einmal ===
runCommand(OPENCLAW_BIN, ['sessions', 'cleanup', '--enforce', '--all-agents']);

// === 5. Memory – status/index decken alle Agents ab ===
runCommand(OPENCLAW_BIN, ['memory', 'status', '--deep', '--fix']);
runCommand(OPENCLAW_BIN, ['memory', 'index', '--force']);

// === 6. Memory promote – MUSS pro Agent ===
for (const AGENT of ['main', 'knecht', 'docs', 'ops-hub', 'cron']) {
  runCommand(OPENCLAW_BIN, ['memory', 'promote', '--apply', '--agent', AGENT]);
}

// === 7. Secrets ===
runCommand(OPENCLAW_BIN, ['secrets', 'reload']);
