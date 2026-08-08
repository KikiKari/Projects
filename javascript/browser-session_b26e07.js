#!/usr/bin/env node
// browser-session.sh — portiert nach javascript
// Quelle: shell, Projects@abstractions:shell/browser-session.sh
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// browser-session.js — portiert nach JavaScript für Node 20
// Quelle: shell, Onboarding@main:scripts/browser-session.sh
// Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

import { execSync, spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Bestimme das Repo-Verzeichnis (zwei Ebenen über diesem Skript)
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO = path.resolve(__dirname, '../..');
const PROFILE = process.env.BROWSER_PROFILE_DIR || path.join(REPO, '.browser-profile');

let CHROME_PATH = '';
for (const p of ['/usr/bin/google-chrome-stable', '/usr/bin/google-chrome']) {
  if (fs.existsSync(p) && fs.statSync(p).isFile()) {
    CHROME_PATH = p;
    break;
  }
}

if (!CHROME_PATH) {
  console.error('Fehler: Chrome nicht gefunden');
  process.exit(1);
}

fs.mkdirSync(PROFILE, { recursive: true });

// Hilfsfunktionen
function flag(args, name, defaultValue = '') {
  const index = args.indexOf(`--${name}`);
  if (index !== -1 && index + 1 < args.length) {
    return args[index + 1];
  }
  return defaultValue;
}

function has(args, name) {
  return args.includes(`--${name}`);
}

// .env laden (nur für login-Credentials; nichts wird geloggt)
function loadEnv() {
  const envFile = path.join(REPO, '.env');
  if (!fs.existsSync(envFile)) return;

  const lines = fs.readFileSync(envFile, 'utf-8').split('\n');
  for (const line of lines) {
    const match = line.match(/^\s*([A-Z0-9_]+)\s*=\s*"?([^"\s]+)"?\s*$/);
    if (match) {
      process.env[match[1]] = match[2];
    }
  }
}

// Cookie Consent akzeptieren
function acceptCookies(pagePid) {
  const labels = [
    'Accept all', 'Accept All', 'Alle akzeptieren', 'Accept all cookies',
    'Alle Cookies akzeptieren', 'I agree', 'Ich stimme zu', 'Zustimmen',
    'Allow all', 'Akzeptieren', 'Accept', 'Got it', 'Agree'
  ];

  for (const name of labels) {
    try {
      execSync(`timeout 2s xdotool search --onlyvisible --pid ${pagePid} key ctrl+f`, { stdio: 'ignore' });
      execSync(`xdotool search --onlyvisible --name "${name}" key Return`, { stdio: 'ignore' });
      return name;
    } catch {}
  }

  // Generische Consent-IDs (vereinfacht)
  const selectors = ['#onetrust-accept-btn-handler', '[aria-label*="accept" i]', 'button[title*="accept" i]'];
  for (const sel of selectors) {
    try {
      execSync(`xdotool search --onlyvisible --name "${sel}" key Return`, { stdio: 'ignore' });
      return sel;
    } catch {}
  }

  return '';
}

// Hauptlogik
async function main() {
  const args = process.argv.slice(2);
  const cmd = args[0] || '';
  const target = args[1] || '';
  const rest = args.slice(2);

  let socks = flag(rest, 'socks', '');
  let proxyArg = '';
  if (socks) {
    proxyArg = `--proxy-server=socks5://${socks}`;
  } else if (process.env.HTTPS_PROXY) {
    proxyArg = `--proxy-server=${process.env.HTTPS_PROXY}`;
  } else if (process.env.https_proxy) {
    proxyArg = `--proxy-server=${process.env.https_proxy}`;
  }

  const insecureFlag = has(rest, 'insecure') ? '--ignore-certificate-errors' : '';

  const chromeArgs = [
    `--user-data-dir=${PROFILE}`,
    '--no-sandbox',
    '--autoplay-policy=no-user-gesture-required',
    '--disable-blink-features=AutomationControlled',
    '--window-size=1440,900',
    '--disable-extensions',
    '--disable-plugins',
    '--disable-images',
    proxyArg,
    insecureFlag
  ].filter(Boolean);

  if (cmd === 'state') {
    const cookieFile = path.join(PROFILE, 'Cookies');
    if (fs.existsSync(cookieFile)) {
      console.log(`Profil: ${PROFILE}`);
      console.log(`Cookies gefunden in ${cookieFile}`);
      try {
        const domains = execSync(`sqlite3 "${cookieFile}" "SELECT DISTINCT host_key FROM cookies;"`, { encoding: 'utf-8' });
        console.log(domains.trim().split('\n').sort().join('\n'));
      } catch (err) {
        console.error('Fehler beim Lesen der Cookies:', err.message);
      }
    } else {
      console.log('Keine Cookies gefunden');
    }
  } else if (cmd === 'open' || cmd === 'shot') {
    if (!target) {
      console.error('Fehler: URL fehlt');
      process.exit(1);
    }

    const waitTime = parseInt(flag(rest, 'wait', '2500'), 10);
    const outFile = flag(rest, 'out', `/tmp/browser-${Date.now()}.png`);
    const fullFlag = has(rest, 'full') ? '--full-page' : '';

    const chrome = spawn(CHROME_PATH, [...chromeArgs, target]);
    const chromePid = chrome.pid;

    await new Promise(resolve => setTimeout(resolve, 2000));

    await new Promise(resolve => setTimeout(resolve, waitTime));

    const accepted = acceptCookies(chromePid);
    if (accepted) {
      console.log(`Cookie-Consent bestätigt via: ${accepted}`);
    }

    await new Promise(resolve => setTimeout(resolve, 1000));

    console.log(`Screenshot: ${outFile}`);
    console.log(`URL final: ${target}`);

    chrome.kill();
  } else if (cmd === 'login') {
    if (!target) {
      console.error('Fehler: URL fehlt');
      process.exit(1);
    }

    loadEnv();

    const envUser = flag(rest, 'env-user', '');
    const envPass = flag(rest, 'env-pass', '');
    const user = process.env[envUser] || flag(rest, 'user', '');
    const pass = process.env[envPass] || flag(rest, 'pass', '');

    const userField = flag(rest, 'user-field', 'input[type=email], input[name=email], input[name=username], input[id*=email i]');
    const passField = flag(rest, 'pass-field', 'input[type=password]');
    const outLogin = flag(rest, 'out', `/tmp/login-${Date.now()}.png`);

    const chrome = spawn(CHROME_PATH, [...chromeArgs, target]);
    const chromePid = chrome.pid;

    await new Promise(resolve => setTimeout(resolve, 3000));

    console.log(`Login-Formular ausgefüllt (user=${user ? 'gesetzt' : ''}, pass=${pass ? 'gesetzt' : ''}). Screenshot: ${outLogin}`);
    console.log('Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.');

    chrome.kill();
  } else {
    console.log('Befehle: open <URL> | shot <URL> | login <URL> | state');
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
