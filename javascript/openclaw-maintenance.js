#!/usr/bin/env node
// openclaw-maintenance.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import { execSync } from 'child_process';
import { stdout } from 'process';

// === 1. Service-/Config-Drift ===
execSync('openclaw doctor', { stdio: 'inherit' });

// === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
execSync('openclaw plugins registry --refresh', { stdio: 'inherit' });
execSync('openclaw plugins update --all', { stdio: 'inherit' });

// === 3. Tasks ===
execSync('openclaw tasks maintenance --apply', { stdio: 'inherit' });

// === 4. Sessions – alle Agents auf einmal ===
execSync('openclaw sessions cleanup --enforce --all-agents', { stdio: 'inherit' });

// === 5. Memory – status/index decken alle Agents ab ===
execSync('openclaw memory status --deep --fix', { stdio: 'inherit' });
execSync('openclaw memory index --force', { stdio: 'inherit' });

// === 6. Memory promote – MUSS pro Agent ===
const agents = ['main', 'knecht', 'docs', 'ops-hub', 'cron'];
for (const agent of agents) {
  execSync(`openclaw memory promote --apply --agent "${agent}"`, { stdio: 'inherit' });
}

// === 7. Secrets ===
execSync('openclaw secrets reload', { stdio: 'inherit' });
