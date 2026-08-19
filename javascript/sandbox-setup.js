#!/usr/bin/env node
// sandbox-setup.sh — portiert nach javascript
// Quelle: shell, Onboarding@main:scripts/sandbox-setup.sh
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

// Provisioniert die Claude-Code-Sandbox (Remote-Umgebung) reproduzierbar:
//   - Node-Dependencies (Frontend, npm)
//   - Python-Dependencies (Backend inkl. pytest)
//   - Medien-Tools: ffmpeg, ImageMagick, GIMP, Blender headless (apt) —
//     Fehlschlag blockiert die Session nicht; --skip-heavy laesst GIMP/Blender aus
// Idempotent: bereits Vorhandenes wird uebersprungen; der Container-Cache der
// Umgebung macht die apt-Installation zum Einmal-Aufwand.

import { execSync, spawn } from 'child_process';
import { writeFileSync, existsSync, readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const args = process.argv.slice(2);
const SKIP_HEAVY = args.includes('--skip-heavy');

process.chdir(join(__dirname, '..'));

function log(message) {
  console.log(`[sandbox-setup] ${message}`);
}

function runCommand(command, options = {}) {
  try {
    const result = execSync(command, { encoding: 'utf8', ...options });
    return result.trim();
  } catch (error) {
    return null;
  }
}

function commandExists(command) {
  return runCommand(`which ${command}`) !== null;
}

log('Node-Dependencies (npm install) …');
try {
  execSync('npm install --no-audit --no-fund', { stdio: 'inherit' });
} catch (error) {
  log('FEHLER: npm install fehlgeschlagen');
  process.exit(1);
}

log('Python-Dependencies (backend/requirements-dev.txt) …');
try {
  execSync('pip3 install --quiet -r backend/requirements-dev.txt', { stdio: 'inherit' });
} catch (error) {
  log('FEHLER: pip install fehlgeschlagen');
  process.exit(1);
}

let APT_UPDATED = false;

function aptInstall(pkg, bin) {
  if (commandExists(bin)) {
    const versionOutput = runCommand(`${bin} -version 2>&1 | head -1`) || '';
    log(`${pkg} bereits vorhanden (${versionOutput})`);
    return true;
  }
  
  log(`Installiere ${pkg} …`);
  try {
    if (!APT_UPDATED) {
      execSync('DEBIAN_FRONTEND=noninteractive apt-get update -qq', { stdio: 'pipe' });
      APT_UPDATED = true;
    }
    execSync(`DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ${pkg}`, { stdio: 'pipe' });
    return true;
  } catch (error) {
    log(`WARNUNG: ${pkg} konnte nicht installiert werden (Netzwerk-Policy?) — Medien-Schritte ggf. eingeschraenkt`);
    return false;
  }
}

aptInstall('ffmpeg', 'ffmpeg');
aptInstall('imagemagick', 'convert');

if (!SKIP_HEAVY) {
  aptInstall('gimp', 'gimp');
  aptInstall('blender', 'blender');
}

aptInstall('xvfb', 'Xvfb');
aptInstall('x11-utils', 'xdpyinfo');
aptInstall('libnss3-tools', 'certutil');

if (!commandExists('google-chrome-stable')) {
  log('Installiere Google Chrome Stable …');
  const tmpDeb = '/tmp/google-chrome.deb';
  try {
    execSync(`curl -fsSL -o ${tmpDeb} https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb`, { stdio: 'pipe' });
    execSync(`DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ${tmpDeb}`, { stdio: 'pipe' });
    const chromeVersion = runCommand('google-chrome-stable --version') || '';
    log(`Chrome installiert: ${chromeVersion}`);
  } catch (error) {
    log('WARNUNG: Chrome-Installation fehlgeschlagen');
  }
}

// Proxy-CA in Chromes NSS-DB, damit externes HTTPS ohne Zertifikatsfehler läuft.
if (commandExists('certutil') && existsSync('/root/.ccr/ca-bundle.crt')) {
  const nssdbPath = `${process.env.HOME}/.pki/nssdb`;
  try {
    execSync(`mkdir -p ${nssdbPath}`, { stdio: 'pipe' });
    execSync(`certutil -d sql:${nssdbPath} -N --empty-password`, { stdio: 'pipe' });
    
    const certList = runCommand(`certutil -d sql:${nssdbPath} -L`) || '';
    if (!certList.includes('ccr-proxy-ca')) {
      execSync(`certutil -d sql:${nssdbPath} -A -t "C,," -n ccr-proxy-ca -i /root/.ccr/ca-bundle.crt`, { stdio: 'pipe' });
      log('Proxy-CA in Chrome-NSS-Store importiert');
    }
  } catch (error) {
    // Ignore errors
  }
}

// Playwright-Node-Module ins Projekt verlinken (visual-qa.mjs / browser-session.mjs).
if (existsSync('node_modules') && !existsSync('node_modules/playwright')) {
  if (commandExists('npm')) {
    try {
      execSync('npm install --no-audit --no-fund --no-save playwright', { stdio: 'pipe' });
      log('Playwright (Node) installiert');
    } catch (error) {
      log('WARNUNG: Playwright-npm-Install fehlgeschlagen');
    }
  }
}

// Git-Push-Weg: Der Session-Git-Proxy (origin) ist read-only. Pushes laufen
// direkt zu github.com mit dem Nutzer-PAT (GH_ACCESS_TOKEN aus Umgebungs-Env
// oder .env, geliefert vom Credential-Helper — kein Secret in der Git-Config).
try {
  execSync('git rev-parse --is-inside-work-tree', { stdio: 'pipe' });
  const pwd = process.cwd();
  execSync(`git config credential."https://x-access-token@github.com".helper "!${pwd}/.claude/git-credential-pat.sh"`);
  execSync('git remote set-url --push origin "https://x-access-token@github.com/KikiKari/Onboarding.git"');
  log('Git-Push-Route: direkt zu github.com (PAT via Credential-Helper)');
} catch (error) {
  // Not a git repository or other git error
}

// Docker-Daemon fuer Dev-Compose-Verifikation in der Sandbox.
// Docker-Hub-Blobs (cloudfront.docker.com) sind von der Netz-Policy blockiert —
// mirror.gcr.io liefert die Library-Images. Container brauchen zusaetzlich die
// Proxy-CA (siehe docker-compose.sandbox.yml).
if (commandExists('dockerd') && !runCommand('docker info')) {
  log('Starte Docker-Daemon (Registry-Mirror: mirror.gcr.io) …');
  
  try {
    execSync('mkdir -p /etc/docker', { stdio: 'pipe' });
    if (!existsSync('/etc/docker/daemon.json')) {
      writeFileSync('/etc/docker/daemon.json', JSON.stringify({
        'registry-mirrors': ['https://mirror.gcr.io']
      }));
    }
    
    // Start docker daemon in background
    const dockerProcess = spawn('dockerd', [], {
      stdio: ['ignore', '/tmp/dockerd.log', '/tmp/dockerd.log'],
      detached: true
    });
    dockerProcess.unref();
    
    // Wait for docker to start
    let dockerStarted = false;
    for (let i = 0; i < 15; i++) {
      if (runCommand('docker info')) {
        dockerStarted = true;
        break;
      }
      execSync('sleep 1');
    }
    
    if (dockerStarted) {
      log('Docker-Daemon laeuft');
    } else {
      log('WARNUNG: Docker-Daemon nicht gestartet');
    }
  } catch (error) {
    log('WARNUNG: Docker-Daemon nicht gestartet');
  }
}

log('Fertig. Versionen:');
console.log('[sandbox-setup]   node ' + (runCommand('node --version') || ''));
console.log('[sandbox-setup]   ' + (runCommand('python3 --version') || ''));

if (commandExists('ffmpeg')) {
  console.log('[sandbox-setup]   ' + (runCommand('ffmpeg -version 2>/dev/null | head -1') || ''));
}
if (commandExists('convert')) {
  console.log('[sandbox-setup]   ' + (runCommand('convert -version 2>/dev/null | head -1') || ''));
}
if (commandExists('gimp')) {
  console.log('[sandbox-setup]   ' + (runCommand('gimp --version 2>/dev/null | head -1') || ''));
}
if (commandExists('blender')) {
  console.log('[sandbox-setup]   ' + (runCommand('blender --version 2>/dev/null | head -1') || ''));
}

process.exit(0);
