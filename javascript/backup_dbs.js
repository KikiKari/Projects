#!/usr/bin/env node
// backup_dbs.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:tmp/backup_dbs.py
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

/** Backup docs.db and tree.db with timestamp into /workspace/db/backups */
const fs = require('fs');
const path = require('path');

const workspace = process.env.OPENCLAW_WORKSPACE || '/workspace';
const backupDir = path.join(workspace, 'db', 'backups');

// Ensure backupDir exists
fs.mkdirSync(backupDir, { recursive: true });

const timestamp = new Date().toISOString().slice(0, 19).replace(/:/g, '-').replace('T', '_');

['docs.db', 'tree.db'].forEach(dbName => {
    const src = path.join(workspace, dbName);
    if (fs.existsSync(src) && fs.statSync(src).isFile()) {
        const dest = path.join(backupDir, `${timestamp}_${dbName}.bak`);
        fs.copyFileSync(src, dest);
        console.log(`Backup created: ${dest}`);
    } else {
        console.log(`Source db not found: ${src}`);
    }
});
