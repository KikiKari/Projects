#!/usr/bin/env node
// ABSTRACTIONS_MANAGER.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:ABSTRACTIONS_MANAGER.py
// auch in: OpenClaw@gateway2:skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

/** Compatibility entry point for the canonical Abstractions Manager. */

const fs = require('fs');
const path = require('path');

const CANONICAL_MANAGER = path.join('/home/openclaw/.openclaw/workspace/abstraction-manager/ABSTRACTIONS_MANAGER.py');

if (require.main === module) {
    if (!fs.existsSync(CANONICAL_MANAGER) || !fs.statSync(CANONICAL_MANAGER).isFile()) {
        console.error(`Kanonischer Abstraction-Manager fehlt: ${CANONICAL_MANAGER}`);
        process.exit(1);
    }
    
    // Execute the Python script using Python
    const { spawnSync } = require('child_process');
    const result = spawnSync('python3', [CANONICAL_MANAGER], { 
        stdio: 'inherit',
        cwd: process.cwd()
    });
    
    process.exit(result.status);
}
