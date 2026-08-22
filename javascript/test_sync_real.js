#!/usr/bin/env node
// test_sync_real.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:scripts/test_sync_real.py
// auch in: OpenClaw@gateway2:scripts/test_sync_real.py
// Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

/** Test echte Synchronisation */

import { execSync } from 'child_process';
import { existsSync, readdirSync } from 'fs';
import { join } from 'path';

// Füge das Verzeichnis zum Modulsuchpfad hinzu
// In Node.js machen wir das über relative Pfade oder NODE_PATH
import { syncToGit, log } from './sync_clawhub_git.js';

// Test: db-maintainer ClawHub → Git (ECHT)
console.log("=== TEST: db-maintainer sync (REAL) ===");
const skill = "db-maintainer";
const result = syncToGit(skill, false);
console.log(`Result: ${result ? 'SUCCESS' : 'FAILED'}`);

// Prüfe Ergebnis
const target = "/home/openclaw/.openclaw/workspace/git/skills/db-maintainer";
if (existsSync(target)) {
    console.log(`\n✅ Git-Repo erstellt: ${target}`);
    
    // Rekursive Funktion zum Auflisten des Verzeichnisbaums
    function walkDir(dir, indent = '') {
        const files = readdirSync(dir, { withFileTypes: true });
        
        files.forEach(file => {
            if (file.isDirectory()) {
                console.log(`${indent}${file.name}/`);
                walkDir(join(dir, file.name), `${indent}  `);
            } else {
                console.log(`${indent}  ${file.name}`);
            }
        });
    }
    
    walkDir(target);
}
