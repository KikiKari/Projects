#!/usr/bin/env node
// gen_tree.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:scripts/gen_tree.py
// Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

// Replicates `tree -a -L 6` output for /workspace into important/openclaw-tree.txt
// (used because the `tree` binary is unavailable in this sandbox).

const fs = require('fs');
const path = require('path');

const ROOT = "/workspace";
const OUT = "/workspace/important/openclaw-tree.txt";
const MAX_DEPTH = 6;

function collect(dirPath, prefix = "", depth = 1) {
    let lines = [];
    try {
        const entries = fs.readdirSync(dirPath).sort();
        const total = entries.length;
        for (let i = 0; i < entries.length; i++) {
            const name = entries[i];
            const isLast = (i === total - 1);
            const connector = isLast ? "└── " : "├── ";
            lines.push(prefix + connector + name);
            const fullPath = path.join(dirPath, name);
            const stats = fs.lstatSync(fullPath);
            if (depth < MAX_DEPTH && stats.isDirectory() && !stats.isSymbolicLink()) {
                const nextPrefix = prefix + (isLast ? "    " : "│   ");
                lines = lines.concat(collect(fullPath, nextPrefix, depth + 1));
            }
        }
    } catch (err) {
        // Ignore errors (e.g., permission denied)
    }
    return lines;
}

const body = collect(ROOT);
const now = new Date().toISOString();
const header = 
    "# OpenClaw Workspace Tree\n" +
    `# Generiert: ${now}\n` +
    `# Befehl: tree -a -L 6 ${ROOT} (emuliert via gen_tree.js)\n` +
    "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";

const content = header + ".\n" + body.join("\n") + "\n";

fs.writeFileSync(OUT, content, 'utf8');

console.log(`written ${OUT}: ${body.length + 1} lines, ${content.length} bytes`);
