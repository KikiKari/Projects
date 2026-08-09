#!/usr/bin/env node
// ABSTRACTIONS_MANAGER.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

/**
 * Skill-Einstieg fuer den kanonischen Abstractions Manager.
 */

const path = require('path');
const fs = require('fs');

const KANONISCHER_MANAGER = path.join(
    '/home/openclaw/.openclaw/workspace/abstractions/ABSTRACTIONS_MANAGER.py'
);

if (require.main === module) {
    if (!fs.existsSync(KANONISCHER_MANAGER) || !fs.statSync(KANONISCHER_MANAGER).isFile()) {
        console.error(`Kanonischer Abstractions Manager fehlt: ${KANONISCHER_MANAGER}`);
        process.exit(1);
    }
    
    // In Node.js können wir Python-Dateien nicht direkt ausführen.
    // Wir müssen den Python-Interpreter aufrufen.
    const { spawnSync } = require('child_process');
    const result = spawnSync('python3', [KANONISCHER_MANAGER], { stdio: 'inherit' });
    
    if (result.error) {
        console.error(`Fehler beim Ausführen des Python-Skripts: ${result.error.message}`);
        process.exit(1);
    }
    
    process.exit(result.status || 0);
}
