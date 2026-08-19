#!/usr/bin/env node
// pplx-status.sh — portiert nach javascript
// Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-status.sh
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

// Quick status of the codespace Perplexity daemon session.
'use strict';

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const CFG = process.env.PERPLEXITY_CONFIG_DIR || path.join(process.env.HOME, '.perplexity-mcp');
const PROFILE = process.env.PERPLEXITY_PROFILE || 'codespace';
const STAT = path.join(CFG, 'profiles', PROFILE, 'daemon-status.json');

if (fs.existsSync(STAT)) {
  const content = fs.readFileSync(STAT, 'utf8');
  try {
    const parsed = JSON.parse(content);
    console.log(JSON.stringify(parsed, null, 2));
  } catch (e) {
    console.log(content);
  }
} else {
  console.log(`no daemon-status.json at ${STAT}`);
}

console.log('--- recent auth lines ---');

const logFile = path.join(CFG, 'daemon.log');
if (fs.existsSync(logFile)) {
  const grep = spawn('grep', ['-iE', 'Authenticated as user|Account tier|Injected .* cookies|Reinit requested|not-logged-in', logFile]);
  const tail = spawn('tail', ['-6']);
  
  grep.stdout.pipe(tail.stdin);
  tail.stdout.pipe(process.stdout);
  
  grep.stderr.pipe(process.stderr);
  tail.stderr.pipe(process.stderr);
  
  let exitCode = 0;
  grep.on('exit', (code) => {
    if (code !== 0 && code !== 1) exitCode = code;
  });
  tail.on('exit', (code) => {
    if (code !== 0) exitCode = code;
    process.exit(exitCode);
  });
} else {
  process.exit(0);
}
