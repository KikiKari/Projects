#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "dbc8ab5c8b224b9481d950f8b4519ff50fa26998e9878943d0f1b1d99cfe741a", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "javascript"}
// openclaw-maintenance.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import { execSync } from 'child_process';
import { exit } from 'process';

// === 1. Service-/Config-Drift ===
try {
  execSync('openclaw doctor', { stdio: 'inherit' });
} catch (error) {
  console.error('Error executing openclaw doctor:', error.message);
  exit(1);
}

// === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
try {
  execSync('openclaw plugins registry --refresh', { stdio: 'inherit' });
  execSync('openclaw plugins update --all', { stdio: 'inherit' });
} catch (error) {
  console.error('Error updating plugins:', error.message);
  exit(1);
}

// === 3. Tasks ===
try {
  execSync('openclaw tasks maintenance --apply', { stdio: 'inherit' });
} catch (error) {
  console.error('Error executing tasks maintenance:', error.message);
  exit(1);
}

// === 4. Sessions – alle Agents auf einmal ===
try {
  execSync('openclaw sessions cleanup --enforce --all-agents', { stdio: 'inherit' });
} catch (error) {
  console.error('Error cleaning up sessions:', error.message);
  exit(1);
}

// === 5. Memory – status/index decken alle Agents ab ===
try {
  execSync('openclaw memory status --deep --fix', { stdio: 'inherit' });
  execSync('openclaw memory index --force', { stdio: 'inherit' });
} catch (error) {
  console.error('Error handling memory operations:', error.message);
  exit(1);
}

// === 6. Memory promote – MUSS pro Agent ===
const agents = ['main', 'knecht', 'docs', 'ops-hub', 'cron'];
for (const agent of agents) {
  try {
    execSync(`openclaw memory promote --apply --agent "${agent}"`, { stdio: 'inherit' });
  } catch (error) {
    console.error(`Error promoting memory for agent ${agent}:`, error.message);
    exit(1);
  }
}

// === 7. Secrets ===
try {
  execSync('openclaw secrets reload', { stdio: 'inherit' });
} catch (error) {
  console.error('Error reloading secrets:', error.message);
  exit(1);
}
