#!/usr/bin/env node
// browser-session.py — portiert nach javascript
// Quelle: python, Projects@abstractions:python/browser-session.py
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

/**
 * Persistente Browser-Sitzung der Sandbox.
 *
 * Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
 * Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
 * speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
 * Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.
 *
 * Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).
 *
 * Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
 *   xvfb-run -a node browser-session.js open <URL>          // öffnen, Cookies akzeptieren, Screenshot
 *   xvfb-run -a node browser-session.js login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
 *   xvfb-run -a node browser-session.js shot <URL> [--out file.png] [--wait ms] [--full]
 *   xvfb-run -a node browser-session.js state               // gespeicherte Cookies auflisten (Domains)
 *
 * Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { program } from 'commander';
import { chromium } from 'playwright';

// Konstanten
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO = path.resolve(__dirname, '..');
const PROFILE = process.env.BROWSER_PROFILE_DIR || path.join(REPO, '.browser-profile');
const CHROME_PATHS = ['/usr/bin/google-chrome-stable', '/usr/bin/google-chrome'];
let CHROME = null;
for (const p of CHROME_PATHS) {
  if (fs.existsSync(p)) {
    CHROME = p;
    break;
  }
}

function loadEnv() {
  /** Lade .env Datei (nur für login-Credentials; nichts wird geloggt) */
  const envFile = path.join(REPO, '.env');
  if (!fs.existsSync(envFile)) {
    return {};
  }

  const envVars = {};
  const content = fs.readFileSync(envFile, 'utf-8');
  const lines = content.split('\n');

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#')) {
      const match = trimmed.split('=');
      if (match.length === 2) {
        const key = match[0].trim();
        let value = match[1].trim();
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.slice(1, -1);
        }
        envVars[key] = value;
      }
    }
  }
  return envVars;
}

async function acceptCookies(page) {
  /** Häufige Cookie-Consent-Buttons klicken (mehrsprachig, best effort). */
  const labels = [
    "Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
    "Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
    "Allow all", "Akzeptieren", "Accept", "Got it", "Agree",
  ];

  for (const name of labels) {
    try {
      const btn = page.getByRole('button', { name, exact: false }).first();
      if (await btn.isVisible({ timeout: 800 })) {
        await btn.click({ timeout: 1500 });
        return name;
      }
    } catch (e) {
      // Ignoriere Fehler
    }
  }

  // Generische Consent-IDs
  const selectors = ["#onetrust-accept-btn-handler", "[aria-label*='accept' i]", "button[title*='accept' i]"];
  for (const sel of selectors) {
    try {
      const el = page.locator(sel).first();
      if (await el.isVisible({ timeout: 500 })) {
        await el.click({ timeout: 1500 });
        return sel;
      }
    } catch (e) {
      // Ignoriere Fehler
    }
  }

  return null;
}

program
  .description('Browser Session Manager')
  .option('--user-field <selector>', 'CSS-Selektor für Benutzerfeld', 'input[type=email], input[name=email], input[name=username], input[id*=email i]')
  .option('--pass-field <selector>', 'CSS-Selektor für Passwortfeld', 'input[type=password]')
  .option('--env-user <var>', 'Umgebungsvariable für Benutzername', '')
  .option('--env-pass <var>', 'Umgebungsvariable für Passwort', '')
  .option('--user <username>', 'Benutzername', '')
  .option('--pass <password>', 'Passwort', '')
  .option('--out <file>', 'Ausgabedatei für Screenshot')
  .option('--wait <ms>', 'Wartezeit in ms', '2500')
  .option('--full', 'Vollständiger Screenshot')
  .option('--socks <proxy>', 'SOCKS5 Proxy Server')
  .option('--insecure', 'Ignoriere HTTPS Fehler');

program
  .command('state')
  .description('gespeicherte Cookies auflisten (Domains)')
  .action(async () => {
    await runCommand('state');
  });

program
  .command('open <url>')
  .description('öffnen, Cookies akzeptieren, Screenshot')
  .action(async (url) => {
    await runCommand('open', url);
  });

program
  .command('shot <url>')
  .description('Screenshot einer Seite')
  .action(async (url) => {
    await runCommand('shot', url);
  });

program
  .command('login <url>')
  .description('Login-Seite öffnen und Formular ausfüllen')
  .action(async (url) => {
    await runCommand('login', url);
  });

async function runCommand(command, url) {
  // Erstelle Profil-Verzeichnis
  fs.mkdirSync(PROFILE, { recursive: true });

  // Proxy-Konfiguration
  let proxyServer = null;
  if (program.opts().socks) {
    proxyServer = `socks5://${program.opts().socks}`;
  } else {
    proxyServer = process.env.HTTPS_PROXY || process.env.https_proxy;
  }

  // Starte den Browser mit persistentem Kontext
  const context = await chromium.launchPersistentContext(
    PROFILE,
    {
      headless: false,
      executablePath: CHROME,
      viewport: { width: 1440, height: 900 },
      acceptDownloads: true,
      ignoreHTTPSErrors: program.opts().insecure,
      proxy: proxyServer ? { server: proxyServer, bypass: 'localhost,127.0.0.1,::1' } : undefined,
      args: proxyServer ?
        [
          '--no-sandbox',
          '--autoplay-policy=no-user-gesture-required',
          '--disable-blink-features=AutomationControlled',
          '--ssl-version-max=tls1.2'
        ] :
        [
          '--no-sandbox',
          '--autoplay-policy=no-user-gesture-required',
          '--disable-blink-features=AutomationControlled'
        ]
    }
  );

  try {
    const page = context.pages().length > 0 ? context.pages()[0] : await context.newPage();

    if (command === 'state') {
      const cookies = await context.cookies();
      const domains = [...new Set(cookies.map(c => c.domain))].sort();
      console.log(`Profil: ${PROFILE}`);
      console.log(`${cookies.length} Cookies über ${domains.length} Domains:`);
      for (const domain of domains) {
        console.log(`  ${domain}`);
      }
    } else if (command === 'open' || command === 'shot') {
      if (!url) {
        throw new Error('URL fehlt');
      }

      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
      await page.waitForTimeout(parseInt(program.opts().wait));

      const accepted = await acceptCookies(page);
      if (accepted) {
        console.log(`Cookie-Consent bestätigt via: ${accepted}`);
      }

      await page.waitForTimeout(1000);

      const outFile = program.opts().out || `/tmp/browser-${Date.now()}.png`;
      await page.screenshot({ path: outFile, fullPage: program.opts().full });
      console.log(`Screenshot: ${outFile}`);
      console.log(`URL final: ${page.url()}`);
    } else if (command === 'login') {
      if (!url) {
        throw new Error('URL fehlt');
      }

      const env = loadEnv();
      const user = env[program.opts().envUser] || program.opts().user;
      const password = env[program.opts().envPass] || program.opts().pass;

      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
      await page.waitForTimeout(2500);
      await acceptCookies(page);

      if (user) {
        await page.locator(program.opts().userField).first().fill(user, { timeout: 8000 });
      }

      if (password) {
        await page.locator(program.opts().passField).first().fill(password, { timeout: 8000 });
      }

      const outFile = program.opts().out || `/tmp/login-${Date.now()}.png`;
      await page.screenshot({ path: outFile });
      console.log(`Login-Formular ausgefüllt (user=${user ? 'gesetzt' : '-'}, pass=${password ? 'gesetzt' : '-'}). Screenshot: ${outFile}`);
      console.log('Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.');
    } else {
      console.log('Befehle: open <URL> | shot <URL> | login <URL> | state');
    }
  } finally {
    await context.close(); // Profil (Cookies) bleibt auf Platte erhalten
  }
}

program.parse(process.argv);
