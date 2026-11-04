#!/usr/bin/env node
// run_sync_agent.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:scripts/run_sync_agent.py
// Erzeugt: 2026-11-04 durch ABSTRACTIONS_MANAGER.py

/** Sandbox-Wrapper für sync_agent.js: mappt hartcodierte Host-Pfade auf /workspace. */
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Füge Pfade zum Modulsuchpfad hinzu
const modulePaths = [
  '/workspace/scripts',
  '/workspace/skills/clawhub-git-sync-agent/scripts'
];

// Aktualisiere den Modulsuchpfad
const originalModulePaths = [...module.paths];
module.paths = [...modulePaths, ...originalModulePaths];

// Importiere das sync_agent Modul
import sync_agent from 'sync_agent';

const WS = '/workspace';
sync_agent.CLAWHUB_DIR = join(WS, 'skills');
sync_agent.GIT_DIR = join(WS, 'git', 'skills');
sync_agent.STATE_FILE = join(WS, 'db', 'sync_state.json');

if (import.meta.url === `file://${process.argv[1]}`) {
  sync_agent.main();
}
