#!/usr/bin/env node
// sync-local.sh — portiert nach javascript
// Quelle: shell, Onboarding@main:scripts/sync-local.sh
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import { execSync, exec } from 'child_process';
import { readFileSync, writeFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let BRANCH = "claude/onboarding-persistent-sandbox-vjfmcx";
let INTERVAL = 20;
const COMPOSE_FILE = "docker-compose.dev.yml";
let ONCE = false;

const args = process.argv.slice(2);
for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case "--branch":
      BRANCH = args[++i];
      break;
    case "--interval":
      INTERVAL = parseInt(args[++i]);
      break;
    case "--once":
      ONCE = true;
      break;
    default:
      console.error(`Unbekannte Option: ${args[i]}`);
      process.exit(1);
  }
}

process.chdir(path.join(__dirname, ".."));

const log = (msg) => {
  const now = new Date().toLocaleTimeString('de-DE', { hour12: false });
  console.log(`[${now}] ${msg}`);
};

const compose = (cmd) => {
  try {
    execSync(`docker compose -f "${COMPOSE_FILE}" ${cmd}`, { stdio: 'inherit' });
  } catch (error) {
    log(`WARNUNG: docker compose ${cmd} fehlgeschlagen`);
  }
};

const execSilent = (cmd) => {
  try {
    return execSync(cmd, { encoding: 'utf8' }).trim();
  } catch (error) {
    return null;
  }
};

const current = execSilent('git rev-parse --abbrev-ref HEAD');
if (current !== BRANCH) {
  log(`Wechsle von '${current}' auf '${BRANCH}' …`);
  execSync(`git fetch origin "${BRANCH}"`, { stdio: 'inherit' });
  try {
    execSync(`git switch "${BRANCH}"`, { stdio: 'inherit' });
  } catch (error) {
    execSync(`git switch -c "${BRANCH}" --track "origin/${BRANCH}"`, { stdio: 'inherit' });
  }
}

log(`Sync aktiv: origin/${BRANCH} -> ${process.cwd()} (Intervall ${INTERVAL}s, Compose: ${COMPOSE_FILE})`);

const syncLoop = async () => {
  while (true) {
    try {
      execSync(`git fetch origin "${BRANCH}"`, { stdio: 'pipe' });
    } catch (error) {
      log(`Fetch fehlgeschlagen (Netzwerk?) — nächster Versuch in ${INTERVAL}s`);
      if (ONCE) break;
      await new Promise(resolve => setTimeout(resolve, INTERVAL * 1000));
      continue;
    }

    const local_rev = execSilent('git rev-parse HEAD');
    const remote_rev = execSilent(`git rev-parse "origin/${BRANCH}"`);

    if (local_rev !== remote_rev) {
      const isAncestor = execSilent(`git merge-base --is-ancestor "${local_rev}" "${remote_rev}"; echo $?`);
      if (isAncestor !== "0") {
        log("ACHTUNG: Lokaler Stand von origin/" + BRANCH + " abgewichen — kein automatischer Merge, bitte manuell auflösen.");
      } else {
        const changedOutput = execSilent(`git diff --name-only "${local_rev}..${remote_rev}"`);
        const changed = changedOutput ? changedOutput.split('\n').filter(Boolean) : [];
        
        execSync(`git merge --ff-only "${remote_rev}"`, { stdio: 'ignore' });
        log(`Aktualisiert ${local_rev.substring(0, 7)} -> ${remote_rev.substring(0, 7)} (${changed.length} Datei(en))`);

        let needs_none = true;
        if (changed.includes(COMPOSE_FILE)) {
          log("Compose-Datei geändert — erzeuge Dev-Stack neu …");
          compose("up -d");
          needs_none = false;
        }
        if (changed.some(file => /^backend\/(Dockerfile|requirements.*\.txt)$/.test(file))) {
          log("Backend-Dependencies/Dockerfile geändert — baue nur das Backend neu …");
          compose("up -d --build backend");
          needs_none = false;
        }
        if (changed.some(file => /^(package\.json|package-lock\.json)$/.test(file))) {
          log("Frontend-Dependencies geändert — starte Frontend neu (npm install läuft im Container) …");
          compose("restart frontend");
          needs_none = false;
        }
        if (needs_none) {
          log("Nur Quellcode/Assets — Hot-Reload übernimmt, kein Build nötig.");
        }
      }
    }

    if (ONCE) break;
    await new Promise(resolve => setTimeout(resolve, INTERVAL * 1000));
  }
};

syncLoop();
