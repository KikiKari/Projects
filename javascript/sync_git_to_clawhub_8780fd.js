#!/usr/bin/env node
// sync_git_to_clawhub.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:scripts/sync_git_to_clawhub.py
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

/** Sync die 4 Git-Repos zu ClawHub */

import { appendFileSync } from 'fs';
import { join, existsSync } from 'path';
import { syncToClawHub, log } from '/home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.js';

// Die 4 Git-Repos die zu ClawHub müssen
const gitRepos = [
    "abstractions-utils",
    "sub-agents-utils", 
    "multi-nodes-utils",
    "Abstraktionen"
];

// Check if in git/
const gitPath = "/home/openclaw/.openclaw/workspace/git";
for (const repo of gitRepos) {
    const repoPath = join(gitPath, repo);
    if (existsSync(repoPath)) {
        log(`Syncing ${repo} from Git to ClawHub...`);
        // Rename für sync function
        if (repo === "Abstraktionen") {
            continue;  // Skip - ist kein Skill
        }
        syncToClawHub(repo, false);
        log(`✅ ${repo} synced to ClawHub`);
    }
}
