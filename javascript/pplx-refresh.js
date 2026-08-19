#!/usr/bin/env node
// pplx-refresh.sh — portiert nach javascript
// Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-refresh.sh
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';
import { spawnSync, execSync } from 'child_process';

// Refresh the codespace Perplexity session from a locally-exported cookie.
//
// Usage:
//   ./pplx-refresh.js [cookie-file]
//
// cookie-file defaults to ~/pplx-cookies.txt. Put your local browser's
// __Secure-next-auth.session-token value (raw), or the whole Cookie header,
// or a JSON cookie export, into that file first.
//
// Steps: ensure daemon browser -> read daemon passphrase -> inject into vault
//        -> trigger reinit -> verify authenticated.

const HERE = path.dirname(new URL(import.meta.url).pathname);
const CFG = process.env.PERPLEXITY_CONFIG_DIR || path.join(process.env.HOME, '.perplexity-mcp');
const PROFILE = process.env.PERPLEXITY_PROFILE || 'codespace';
const COOKIE_FILE = process.argv[2] || path.join(process.env.HOME, 'pplx-cookies.txt');

if (!fs.existsSync(COOKIE_FILE) || fs.statSync(COOKIE_FILE).size === 0) {
  console.error(`✗ Cookie file empty/missing: ${COOKIE_FILE}`);
  console.error("  Export __Secure-next-auth.session-token from your local browser");
  console.error("  (DevTools → Application → Cookies → www.perplexity.ai) into that file.");
  process.exit(1);
}

// 1. ensure the extension daemon has a usable browser (idempotent)
spawnSync('bash', [path.join(HERE, 'pplx-setup.sh')], { stdio: 'inherit' });

// 2. daemon pid + vault passphrase (never guessed — read from the live daemon)
const LOCK = path.join(CFG, 'daemon.lock');
if (!fs.existsSync(LOCK)) {
  console.error(`✗ no daemon.lock at ${LOCK} — is the extension running?`);
  process.exit(1);
}

let lockData;
try {
  lockData = JSON.parse(fs.readFileSync(LOCK, 'utf8'));
} catch (e) {
  console.error(`✗ failed to parse daemon.lock: ${e.message}`);
  process.exit(1);
}

const PID = lockData.pid;
try {
  execSync(`kill -0 ${PID}`, { stdio: 'ignore' });
} catch (e) {
  console.error(`✗ daemon pid ${PID} not running`);
  process.exit(1);
}

let PASS = '';
try {
  const environ = fs.readFileSync(`/proc/${PID}/environ`, 'utf8');
  const vars = environ.split('\0');
  for (const v of vars) {
    if (v.startsWith('PERPLEXITY_VAULT_PASSPHRASE=')) {
      PASS = v.substring('PERPLEXITY_VAULT_PASSPHRASE='.length);
      break;
    }
  }
} catch (e) {
  console.error(`✗ failed to read daemon environment: ${e.message}`);
  process.exit(1);
}

if (!PASS) {
  console.error("✗ no PERPLEXITY_VAULT_PASSPHRASE in daemon env");
  process.exit(1);
}

// 3. locate the perplexity-user-mcp dist (populate npx cache if needed)
let DIST = '';
try {
  const npxDir = path.join(process.env.HOME, '.npm', '_npx');
  const dirs = fs.readdirSync(npxDir);
  for (const dir of dirs) {
    const fullPath = path.join(npxDir, dir);
    const stat = fs.statSync(fullPath, { throwIfNoEntry: false });
    if (stat && stat.isDirectory()) {
      const distPath = path.join(fullPath, 'dist');
      if (fs.existsSync(distPath)) {
        DIST = distPath;
        break;
      }
    }
  }
} catch (e) {
  // ignore and try npx fallback
}

if (!DIST) {
  try {
    execSync('npx -y perplexity-user-mcp --version', { stdio: 'ignore' });
    // retry search after npx install
    const npxDir = path.join(process.env.HOME, '.npm', '_npx');
    const dirs = fs.readdirSync(npxDir);
    for (const dir of dirs) {
      const fullPath = path.join(npxDir, dir);
      const stat = fs.statSync(fullPath, { throwIfNoEntry: false });
      if (stat && stat.isDirectory()) {
        const distPath = path.join(fullPath, 'dist');
        if (fs.existsSync(distPath)) {
          DIST = distPath;
          break;
        }
      }
    }
  } catch (e) {
    // ignore
  }
}

// 4. inject
const injectEnv = {
  ...process.env,
  PERPLEXITY_VAULT_PASSPHRASE: PASS,
  PERPLEXITY_CONFIG_DIR: CFG,
  PERPLEXITY_PROFILE: PROFILE,
  PPLX_DIST: DIST
};

const injectResult = spawnSync('node', [path.join(HERE, 'pplx-inject.mjs'), COOKIE_FILE], {
  env: injectEnv,
  stdio: 'inherit'
});

if (injectResult.status !== 0) {
  process.exit(injectResult.status || 1);
}

// 5. trigger daemon reinit
const reinitFile = path.join(CFG, 'profiles', PROFILE, '.reinit');
fs.writeFileSync(reinitFile, Math.floor(Date.now() / 1000).toString());
console.log("→ reinit triggered, waiting for daemon...");

// 6. verify
const STAT = path.join(CFG, 'profiles', PROFILE, 'daemon-status.json');
for (let i = 1; i <= 20; i++) {
  await new Promise(resolve => setTimeout(resolve, 1500));
  
  let statusData;
  try {
    statusData = JSON.parse(fs.readFileSync(STAT, 'utf8'));
  } catch (e) {
    continue;
  }
  
  const AUTH = statusData.authenticated;
  const TIER = statusData.tier;
  
  if (AUTH === true) {
    console.log(`✅ authenticated — tier: ${TIER}`);
    process.exit(0);
  }
}

console.error(`⚠️  not authenticated yet. Check: tail -20 ${path.join(CFG, 'daemon.log')}`);
process.exit(1);
