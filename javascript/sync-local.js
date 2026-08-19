#!/usr/bin/env node
// sync-local.ps1 — portiert nach javascript
// Quelle: powershell, Onboarding@main:scripts/sync-local.ps1
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

/*
.SYNOPSIS
  Hält den lokalen Dev-Stack (docker-compose.dev.yml) inkrementell mit GitHub synchron.

.DESCRIPTION
  Pollt origin/<Branch> und zieht neue Commits per Fast-Forward. Danach entscheidet
  der Diff, was nötig ist:
    - nur Quellcode geändert            -> nichts tun, Hot-Reload übernimmt
    - package.json / package-lock.json  -> Frontend-Container neu starten
                                           (Entrypoint installiert Dependencies nur
                                           bei geändertem Lockfile-Hash nach)
    - backend/Dockerfile, requirements* -> Backend-Image gezielt neu bauen
    - docker-compose.dev.yml            -> Dev-Stack neu erzeugen
  Es wird nie „blind" der ganze Branch neu gebaut.
*/

const { execSync, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

// Parameter
const args = process.argv.slice(2);
let Branch = "claude/onboarding-persistent-sandbox-vjfmcx";
let IntervalSeconds = 20;
let ComposeFile = "docker-compose.dev.yml";
let Once = false;

// Parameter parsen
for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case '-Branch':
      Branch = args[++i];
      break;
    case '-IntervalSeconds':
      IntervalSeconds = parseInt(args[++i]);
      break;
    case '-ComposeFile':
      ComposeFile = args[++i];
      break;
    case '-Once':
      Once = true;
      break;
  }
}

const repoRoot = path.dirname(__dirname);
process.chdir(repoRoot);

function log(msg) {
  console.log(`[${new Date().toLocaleTimeString()}] ${msg}`);
}

function invokeCompose(composeArgs) {
  const cmd = `docker compose -f ${ComposeFile} ${composeArgs.join(' ')}`;
  try {
    execSync(cmd, { stdio: 'inherit' });
  } catch (error) {
    log(`WARNUNG: docker compose ${composeArgs.join(' ')} fehlgeschlagen (Exit ${error.status})`);
  }
}

// Sicherstellen, dass der Ziel-Branch ausgecheckt ist.
let current;
try {
  current = execSync('git rev-parse --abbrev-ref HEAD', { encoding: 'utf8' }).trim();
} catch (error) {
  throw new Error("Konnte aktuellen Branch nicht ermitteln.");
}

if (current !== Branch) {
  log(`Wechsle von '${current}' auf '${Branch}' …`);
  try {
    execSync(`git fetch origin ${Branch}`, { stdio: 'inherit' });
  } catch (error) {
    // Ignorieren, Fehler wird später behandelt
  }
  
  try {
    execSync(`git switch ${Branch}`, { stdio: 'ignore' });
  } catch (error) {
    try {
      execSync(`git switch -c ${Branch} --track origin/${Branch}`, { stdio: 'inherit' });
    } catch (error2) {
      throw new Error(`Branch '${Branch}' konnte nicht ausgecheckt werden.`);
    }
  }
}

log(`Sync aktiv: origin/${Branch} -> ${repoRoot} (Intervall ${IntervalSeconds}s, Compose: ${ComposeFile})`);

async function sleep(seconds) {
  return new Promise(resolve => setTimeout(resolve, seconds * 1000));
}

async function mainLoop() {
  while (true) {
    try {
      execSync(`git fetch origin ${Branch} --quiet`);
    } catch (error) {
      log(`Fetch fehlgeschlagen (Netzwerk?) — nächster Versuch in ${IntervalSeconds}s`);
      if (Once) break;
      await sleep(IntervalSeconds);
      continue;
    }

    let local, remote;
    try {
      local = execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim();
      remote = execSync(`git rev-parse origin/${Branch}`, { encoding: 'utf8' }).trim();
    } catch (error) {
      log("Fehler beim Ermitteln der Commit-Hashes");
      if (Once) break;
      await sleep(IntervalSeconds);
      continue;
    }

    if (local !== remote) {
      let isAncestor = false;
      try {
        execSync(`git merge-base --is-ancestor ${local} ${remote}`);
        isAncestor = true;
      } catch (error) {
        // Wenn Exit-Code != 0, dann ist es kein Vorfahre
      }

      if (!isAncestor) {
        log(`ACHTUNG: Lokaler Stand ist von origin/${Branch} abgewichen (lokale Commits?). Kein automatischer Merge — bitte manuell auflösen.`);
      } else {
        let changedFiles = [];
        try {
          const diffOutput = execSync(`git diff --name-only ${local}..${remote}`, { encoding: 'utf8' });
          changedFiles = diffOutput.split('\n').filter(line => line.trim() !== '');
        } catch (error) {
          log("Fehler beim Ermitteln der geänderten Dateien");
          if (Once) break;
          await sleep(IntervalSeconds);
          continue;
        }

        try {
          execSync(`git merge --ff-only ${remote} --quiet`);
          log(`Aktualisiert ${local.substring(0, 7)} -> ${remote.substring(0, 7)} (${changedFiles.length} Datei(en))`);
        } catch (error) {
          log(`Merge fehlgeschlagen: ${error.message}`);
          if (Once) break;
          await sleep(IntervalSeconds);
          continue;
        }

        const frontendDeps = changedFiles.filter(file => 
          file === "package.json" || file === "package-lock.json"
        );
        
        const backendImage = changedFiles.filter(file => 
          /^backend\/(Dockerfile|requirements.*\.txt)$/.test(file)
        );
        
        const composeChanged = changedFiles.includes(ComposeFile);

        if (composeChanged) {
          log("Compose-Datei geändert — erzeuge Dev-Stack neu …");
          invokeCompose(["up", "-d"]);
        }
        if (backendImage.length > 0) {
          log("Backend-Dependencies/Dockerfile geändert — baue nur das Backend neu …");
          invokeCompose(["up", "-d", "--build", "backend"]);
        }
        if (frontendDeps.length > 0) {
          log("Frontend-Dependencies geändert — starte Frontend neu (npm install läuft im Container) …");
          invokeCompose(["restart", "frontend"]);
        }
        if (!(composeChanged || backendImage.length > 0 || frontendDeps.length > 0)) {
          log("Nur Quellcode/Assets — Hot-Reload übernimmt, kein Build nötig.");
        }
      }
    }

    if (Once) break;
    await sleep(IntervalSeconds);
  }
}

mainLoop().catch(error => {
  console.error(error.message);
  process.exit(1);
});
