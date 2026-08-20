#!/usr/bin/env node
// sync_git_to_clawhub.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:scripts/sync_git_to_clawhub.py
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

/** Sync die aktiven Skill-Repositories zu ClawHub. */

const fs = require('fs');
const path = require('path');

// Füge das Skript-Verzeichnis zum Modul-Suchpfad hinzu
const scriptDir = '/home/openclaw/.openclaw/workspace/scripts';
const syncClawhubGitPath = path.join(scriptDir, 'sync_clawhub_git.js');

// Dynamisches Laden des sync_clawhub_git Moduls
const syncModule = require(syncClawhubGitPath);
const { sync_to_clawhub, log } = syncModule;

// Nur aktive Skill-Repositories synchronisieren.
const gitRepos = [
  "sub-agents-utils",
  "multi-nodes-utils",
];

// Check if in git/
const gitPath = "/home/openclaw/.openclaw/workspace/git";
for (const repo of gitRepos) {
  const repoPath = path.join(gitPath, repo);
  if (fs.existsSync(repoPath)) {
    log(`Syncing ${repo} from Git to ClawHub...`);
    sync_to_clawhub(repo, false);
    log(`✅ ${repo} synced to ClawHub`);
  }
}
