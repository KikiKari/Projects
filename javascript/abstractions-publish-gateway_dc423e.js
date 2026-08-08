#!/usr/bin/env node
// abstractions-publish-gateway.sh — portiert nach javascript
// Quelle: shell, Projects@clawhub:clawhub/Scripts/abstractions-publish-gateway.sh
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

import { execSync } from 'child_process';
import { writeFileSync, existsSync, mkdirSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ABSTRACTIONS_REPO = "/home/openclaw/.openclaw/workspace/git/Abstraktionen";
const LOG_DIR = "/home/openclaw/.openclaw/logs/abstractions-publish-gateway";

// Erzeuge das Log-Verzeichnis, falls es nicht existiert
if (!existsSync(LOG_DIR)) {
  mkdirSync(LOG_DIR, { recursive: true });
}

const dateStr = new Date().toISOString().split('T')[0];
const LOG_FILE = path.join(LOG_DIR, `${dateStr}.log`);

function log(message) {
  const timestamp = new Date().toISOString().replace('T', ' ').split('.')[0];
  const logMessage = `[${timestamp}] ${message}`;
  console.log(logMessage);
  writeFileSync(LOG_FILE, logMessage + '\n', { flag: 'a' });
}

function runGitCommand(command, options = {}) {
  try {
    return execSync(`git ${command}`, {
      cwd: ABSTRACTIONS_REPO,
      encoding: 'utf-8',
      ...options
    });
  } catch (error) {
    if (!options.ignoreError) {
      throw error;
    }
    return null;
  }
}

// --- Schritt 1: Repo erreichbar? ---
try {
  process.chdir(ABSTRACTIONS_REPO);
} catch (error) {
  log("STATUS=error CODE=4 REASON=repo-unreachable PATH=" + ABSTRACTIONS_REPO);
  process.exit(4);
}

if (!existsSync('.git')) {
  log("STATUS=error CODE=4 REASON=not-a-git-repo PATH=" + ABSTRACTIONS_REPO);
  process.exit(4);
}

// --- Schritt 2: Branch ermitteln ---
let BRANCH;
try {
  BRANCH = runGitCommand('branch --show-current').trim();
} catch (error) {
  log("STATUS=error CODE=1 REASON=unexpected-branch BRANCH=unknown");
  process.exit(1);
}

if (BRANCH !== "gateway1-abstractions" && BRANCH !== "gateway2-abstractions") {
  log(`STATUS=error CODE=1 REASON=unexpected-branch BRANCH=${BRANCH}`);
  process.exit(1);
}
log(`STATUS=info STEP=branch-detected BRANCH=${BRANCH}`);

// --- Schritt 3: Hat sich was geändert? ---
let STATUS_OUTPUT;
try {
  STATUS_OUTPUT = runGitCommand('status --porcelain').trim();
} catch (error) {
  log("STATUS=error CODE=3 REASON=git-status-failed");
  process.exit(3);
}

if (!STATUS_OUTPUT) {
  log(`STATUS=skip REASON=no-changes BRANCH=${BRANCH}`);
  process.exit(0);
}

const CHANGED_COUNT = STATUS_OUTPUT.split('\n').length;
log(`STATUS=info STEP=changes-detected COUNT=${CHANGED_COUNT} BRANCH=${BRANCH}`);

// --- Schritt 4: Secret-Scan auf geänderte Dateien ---
const SECRET_PATTERNS = [
  /sk-[A-Za-z0-9]{20,}/,
  /ghp_[A-Za-z0-9]{30,}/,
  /github_pat_[A-Za-z0-9_]{30,}/,
  /ntn_[A-Za-z0-9]{30,}/,
  /secret_[A-Za-z0-9]{30,}/,
  /tvly-[A-Za-z0-9-]{20,}/,
  /nvapi-[A-Za-z0-9]{30,}/,
  /tskey-[A-Za-z0-9-]{20,}/,
  /xoxb-[A-Za-z0-9-]{20,}/,
  /xapp-[A-Za-z0-9-]{20,}/,
  /AIza[A-Za-z0-9_-]{30,}/
];

const lines = STATUS_OUTPUT.split('\n');
let SECRET_HITS = [];

for (const line of lines) {
  const filePath = line.substring(3);
  if (existsSync(filePath)) {
    try {
      const content = runGitCommand(`show :${filePath}`, { encoding: 'utf-8' });
      for (const pattern of SECRET_PATTERNS) {
        if (pattern.test(content)) {
          const match = content.match(pattern);
          SECRET_HITS.push(`${filePath}[${match[0].substring(0, 10)}...]`);
          break;
        }
      }
    } catch (error) {
      // Ignoriere Fehler beim Lesen der Datei
    }
  }
}

if (SECRET_HITS.length > 0) {
  log(`STATUS=error CODE=2 REASON=secrets-found HITS=${SECRET_HITS.join(' ')}`);
  process.exit(2);
}
log("STATUS=info STEP=secret-scan-clean");

// --- Schritt 5: Stage + Commit ---
try {
  runGitCommand('add -A');
} catch (error) {
  log("STATUS=error CODE=3 REASON=git-add-failed");
  process.exit(3);
}

const COMMIT_MSG = `auto: abstractions-sync ${new Date().toISOString().replace('T', ' ').split('.')[0]}`;

try {
  runGitCommand(`commit -m "${COMMIT_MSG}"`);
} catch (error) {
  const status = runGitCommand('status --porcelain').trim();
  if (status) {
    log("STATUS=error CODE=3 REASON=git-commit-failed");
    process.exit(3);
  } else {
    log("STATUS=skip REASON=nothing-staged-after-add");
    process.exit(0);
  }
}

let COMMIT_HASH;
try {
  COMMIT_HASH = runGitCommand('log -1 --format=%h').trim();
} catch (error) {
  log("STATUS=error CODE=3 REASON=git-log-failed");
  process.exit(3);
}
log(`STATUS=info STEP=commit-created HASH=${COMMIT_HASH} MSG="${COMMIT_MSG}"`);

// --- Schritt 6: Push ---
try {
  runGitCommand('push');
} catch (error) {
  log(`STATUS=error CODE=3 REASON=git-push-failed BRANCH=${BRANCH} HASH=${COMMIT_HASH}`);
  process.exit(3);
}

// --- Erfolg ---
log(`STATUS=ok BRANCH=${BRANCH} COUNT=${CHANGED_COUNT} HASH=${COMMIT_HASH}`);
console.log("");
console.log("=== SUMMARY ===");
console.log(`Branch:  ${BRANCH}`);
console.log(`Files:   ${CHANGED_COUNT}`);
console.log(`Commit:  ${COMMIT_HASH}`);
console.log("Status:  OK - gepusht nach origin/" + BRANCH);
process.exit(0);
