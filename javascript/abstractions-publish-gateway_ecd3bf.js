#!/usr/bin/env node
// abstractions-publish-gateway.py — portiert nach javascript
// Quelle: python, Projects@abstractions:python/abstractions-publish-gateway.py
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// abstractions-publish-gateway.sh — portiert nach python
// Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
// Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

// Workspace-visible wrapper for the gateway publish job.
const { spawn } = require('child_process');
const { existsSync } = require('fs');
const { resolve } = require('path');

function main() {
    // Define the path to the actual script
    const scriptPath = '/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh';
    
    // Check if the script exists
    if (!existsSync(scriptPath)) {
        console.error(`Error: Script not found at ${scriptPath}`);
        process.exit(1);
    }
    
    // Execute the script with all passed arguments
    const args = process.argv.slice(2);
    const child = spawn(scriptPath, args, { stdio: 'inherit' });
    
    child.on('close', (code) => {
        process.exit(code);
    });
    
    child.on('error', (err) => {
        console.error(`Error executing script: ${err.message}`);
        process.exit(1);
    });
}

if (require.main === module) {
    main();
}
