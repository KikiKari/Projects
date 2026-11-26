#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "83813dbfe97f5c87c6b5aad20ed988cdceb5e1c502d693bb47d5c423534bb23a", "source_sha256": "a77f5c2629fe7fafac268cfbf2f0b3e77a194322aee8f9c06967eb6c33db043e", "target_language": "javascript"}
// openclaw-maintenance.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const OPENCLAW_BIN = process.env.OPENCLAW_BIN || path.join(process.env.HOME, '.local', 'bin', 'openclaw');

if (!fs.existsSync(OPENCLAW_BIN) || !fs.statSync(OPENCLAW_BIN).isFile() || !(fs.statSync(OPENCLAW_BIN).mode & 0o111)) {
  console.error(`ERROR: OpenClaw binary not found: ${OPENCLAW_BIN}`);
  process.exit(1);
}

console.log(`Using OpenClaw: ${execSync(`${OPENCLAW_BIN} --version`, { encoding: 'utf8' }).trim()}`);

// === 1. Service-/Config-Drift ===
execSync(`${OPENCLAW_BIN} doctor`, { stdio: 'inherit' });

// === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
execSync(`${OPENCLAW_BIN} plugins registry --refresh`, { stdio: 'inherit' });

if (process.env.RUN_PLUGIN_UPDATE === '1') {
  execSync(`${OPENCLAW_BIN} plugins update --all`, { stdio: 'inherit' });
} else {
  console.log('Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable.');
}

// === 3. Tasks ===
execSync(`${OPENCLAW_BIN} tasks maintenance --apply`, { stdio: 'inherit' });

// === 4. Sessions – alle Agents auf einmal ===
execSync(`${OPENCLAW_BIN} sessions cleanup --enforce --all-agents`, { stdio: 'inherit' });

// === 5. Memory – status/index decken alle Agents ab ===
execSync(`${OPENCLAW_BIN} memory status --deep --fix`, { stdio: 'inherit' });
execSync(`${OPENCLAW_BIN} memory index --force`, { stdio: 'inherit' });

// === 6. Memory promote – MUSS pro Agent ===
const agents = ['main', 'knecht', 'docs', 'ops-hub', 'cron'];
for (const agent of agents) {
  execSync(`${OPENCLAW_BIN} memory promote --apply --agent ${agent}`, { stdio: 'inherit' });
}

// === 7. Secrets ===
execSync(`${OPENCLAW_BIN} secrets reload`, { stdio: 'inherit' });
