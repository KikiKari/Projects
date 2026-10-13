#!/usr/bin/env node
// tree_fallback.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:db-maintainer/scripts/tree_fallback.py
// Erzeugt: 2026-10-13 durch ABSTRACTIONS_MANAGER.py

/**
 * Fallback tree generator for when the `tree` binary is unavailable.
 *
 * Produces output similar to `tree -a -L <depth>` and writes it to
 * important/openclaw-tree.txt with a timestamp header.
 */

const fs = require('fs');
const path = require('path');

const WORKSPACE = '/workspace';
const DEPTH = 6;
const SKIP = new Set(['.git', 'node_modules', '__pycache__', 'venv', '.cache', '.npm', '.local']);
const OUT = path.join(WORKSPACE, 'important', 'openclaw-tree.txt');

function walk(dirPath, prefix = '', depth = 0) {
  const lines = [];
  if (depth >= DEPTH) {
    return lines;
  }
  
  try {
    const entries = fs.readdirSync(dirPath, { withFileTypes: true });
    entries.sort((a, b) => {
      // Sort directories first, then by name
      if (a.isDirectory() !== b.isDirectory()) {
        return a.isDirectory() ? -1 : 1;
      }
      return a.name.localeCompare(b.name);
    });
    
    // Filter out skipped entries
    const filteredEntries = entries.filter(entry => !SKIP.has(entry.name));
    
    for (let i = 0; i < filteredEntries.length; i++) {
      const entry = filteredEntries[i];
      const last = i === filteredEntries.length - 1;
      const connector = last ? '└── ' : '├── ';
      const fullPath = path.join(dirPath, entry.name);
      const suffix = entry.isDirectory() ? '/' : '';
      lines.push(`${prefix}${connector}${entry.name}${suffix}`);
      
      if (entry.isDirectory() && !fs.lstatSync(fullPath).isSymbolicLink()) {
        const extension = last ? '    ' : '│   ';
        lines.push(...walk(fullPath, prefix + extension, depth + 1));
      }
    }
  } catch (error) {
    // Ignore permission errors or other OS errors
    if (error.code !== 'EACCES' && error.code !== 'EPERM') {
      console.error(`Error reading directory ${dirPath}:`, error.message);
    }
  }
  
  return lines;
}

function main() {
  const lines = [WORKSPACE, ...walk(WORKSPACE)];
  const body = lines.join('\n') + '\n';
  const header = 
    `# OpenClaw Workspace Tree\n` +
    `# Generiert: ${new Date().toISOString()}\n` +
    `# Fallback (tree binary nicht verfuegbar), Tiefe ${DEPTH}\n` +
    `# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n`;
  
  // Create directory if it doesn't exist
  const outDir = path.dirname(OUT);
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
  }
  
  fs.writeFileSync(OUT, header + body);
  console.log(`openclaw-tree.txt aktualisiert (Fallback): ${OUT} (${lines.length} Eintraege)`);
}

main();
