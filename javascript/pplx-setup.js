#!/usr/bin/env node
// pplx-setup.sh — portiert nach javascript
// Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-setup.sh
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

// One-time (idempotent): make sure the Perplexity VS Code extension daemon can
// find a Chromium. The daemon uses its OWN bundled patchright, which pins a
// specific chromium revision; install exactly that revision.
'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

function findExtensionPatchright() {
  const extensionsDir = path.join(process.env.HOME, '.vscode-remote', 'extensions');
  try {
    const files = fs.readdirSync(extensionsDir);
    const patchrightDirs = files
      .filter(file => file.startsWith('nskha.perplexity-vscode-'))
      .map(dir => path.join(extensionsDir, dir, 'dist', 'node_modules', 'patchright'))
      .filter(dir => fs.existsSync(dir))
      .sort((a, b) => a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' }));
    
    return patchrightDirs.length > 0 ? patchrightDirs[patchrightDirs.length - 1] : null;
  } catch (err) {
    return null;
  }
}

const extpr = findExtensionPatchright();
if (!extpr) {
  console.log('[setup] extension patchright not found — is the Perplexity extension installed?');
  process.exit(0);
}

let exp = '';
try {
  exp = execSync(`node -e "const {chromium}=require('${extpr}');console.log(chromium.executablePath())"`, {
    stdio: ['pipe', 'pipe', 'ignore']
  }).toString().trim();
} catch (err) {
  // Ignore error, exp remains empty
}

if (exp && fs.existsSync(exp) && fs.statSync(exp).isFile()) {
  console.log(`[setup] daemon browser already present: ${exp}`);
  process.exit(0);
}

console.log(`[setup] installing matching chromium for the extension daemon (expected: ${exp || 'unknown'})...`);
execSync(`node "${path.join(extpr, 'cli.js')}" install chromium`, { stdio: 'inherit' });
console.log('[setup] done.');
