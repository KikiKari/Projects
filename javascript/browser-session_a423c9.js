#!/usr/bin/env node
// browser-session.ps1 — portiert nach javascript
// Quelle: powershell, Projects@abstractions:powershell/browser-session.ps1
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// browser-session.js — portiert nach JavaScript für Node 20
// Quelle: powershell, browser-session.ps1
// Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

/**
 * SYNOPSIS
 * Persistente Browser-Sitzung der Sandbox.
 *
 * DESCRIPTION
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
import playwright from 'playwright';
import dotenv from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Hilfsfunktionen für Parameterverarbeitung
function getFlagValue(args, name, defaultValue = null) {
    const index = args.indexOf(`--${name}`);
    if (index !== -1 && index + 1 < args.length) {
        return args[index + 1];
    }
    return defaultValue;
}

function hasFlag(args, name) {
    return args.includes(`--${name}`);
}

// Umgebungsvariablen laden
function loadEnv(repoPath) {
    const envPath = path.join(repoPath, '.env');
    const result = {};
    if (fs.existsSync(envPath)) {
        const content = fs.readFileSync(envPath, 'utf-8');
        const lines = content.split('\n');
        for (const line of lines) {
            const match = line.match(/^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?\s*$/);
            if (match) {
                result[match[1]] = match[2];
            }
        }
    }
    return result;
}

// Cookie Consent akzeptieren
async function acceptCookies(page) {
    const labels = [
        "Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
        "Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
        "Allow all", "Akzeptieren", "Accept", "Got it", "Agree"
    ];

    for (const name of labels) {
        try {
            const btn = await page.getByRole('button', { name }).first();
            if (await btn.isVisible({ timeout: 800 })) {
                await btn.click({ timeout: 1500 });
                return name;
            }
        } catch (err) {
            // Ignoriere Fehler
        }
    }

    // Generische Consent-IDs
    const selectors = [
        "#onetrust-accept-btn-handler",
        "[aria-label*='accept' i]",
        "button[title*='accept' i]"
    ];
    for (const sel of selectors) {
        try {
            const el = await page.locator(sel).first();
            if (await el.isVisible({ timeout: 500 })) {
                await el.click({ timeout: 1500 });
                return sel;
            }
        } catch (err) {
            // Ignoriere Fehler
        }
    }
    return null;
}

// Hauptskript
async function main() {
    const args = process.argv.slice(2);
    const cmd = args[0];
    const target = args[1];

    // Pfad-Konfiguration
    const scriptPath = __filename;
    const REPO = path.resolve(__dirname, '..', '..');
    const PROFILE_DIR = process.env.BROWSER_PROFILE_DIR || path.join(REPO, '.browser-profile');

    // Profil-Verzeichnis erstellen
    if (!fs.existsSync(PROFILE_DIR)) {
        fs.mkdirSync(PROFILE_DIR, { recursive: true });
    }

    // Chrome-Pfad finden
    const CHROME_PATHS = [
        '/usr/bin/google-chrome-stable',
        '/usr/bin/google-chrome'
    ];
    let CHROME = null;
    for (const p of CHROME_PATHS) {
        if (fs.existsSync(p)) {
            CHROME = p;
            break;
        }
    }

    // Proxy-Konfiguration
    let PROXY = getFlagValue(args, 'socks', null);
    if (PROXY) {
        PROXY = `socks5://${PROXY}`;
    } else {
        PROXY = process.env.HTTPS_PROXY || process.env.https_proxy || null;
    }

    // Browser-Kontext starten
    const browserArgs = [
        '--no-sandbox',
        '--autoplay-policy=no-user-gesture-required',
        '--disable-blink-features=AutomationControlled'
    ];

    if (PROXY) {
        browserArgs.push('--ssl-version-max=tls1.2');
    }

    const browser = await playwright.chromium.launchPersistentContext(PROFILE_DIR, {
        headless: false,
        executablePath: CHROME,
        viewport: { width: 1440, height: 900 },
        acceptDownloads: true,
        ignoreHTTPSErrors: hasFlag(args, 'insecure'),
        proxy: PROXY ? { server: PROXY, bypass: 'localhost,127.0.0.1,::1' } : undefined,
        args: browserArgs
    });

    const page = browser.pages().length > 0 ? browser.pages()[0] : await browser.newPage();

    try {
        if (cmd === 'state') {
            const cookies = await browser.cookies();
            const domains = [...new Set(cookies.map(c => c.domain))].sort();
            console.log(`Profil: ${PROFILE_DIR}`);
            console.log(`${cookies.length} Cookies über ${domains.length} Domains:`);
            domains.forEach(domain => console.log(`  ${domain}`));
        } else if (cmd === 'open' || cmd === 'shot') {
            if (!target) throw new Error('URL fehlt');
            await page.goto(target, { waitUntil: 'domcontentloaded', timeout: 60000 });
            const waitTime = parseInt(getFlagValue(args, 'wait', '2500'), 10);
            await new Promise(resolve => setTimeout(resolve, waitTime));
            const accepted = await acceptCookies(page);
            if (accepted) console.log(`Cookie-Consent bestätigt via: ${accepted}`);
            await new Promise(resolve => setTimeout(resolve, 1000));
            const out = getFlagValue(args, 'out', path.join('/tmp', `browser-${Date.now()}.png`));
            await page.screenshot({
                path: out,
                fullPage: hasFlag(args, 'full')
            });
            console.log(`Screenshot: ${out}`);
            console.log(`URL final: ${page.url()}`);
        } else if (cmd === 'login') {
            if (!target) throw new Error('URL fehlt');
            const envVars = loadEnv(REPO);
            const user = envVars[getFlagValue(args, 'env-user', '')] || getFlagValue(args, 'user', '');
            const pass = envVars[getFlagValue(args, 'env-pass', '')] || getFlagValue(args, 'pass', '');
            await page.goto(target, { waitUntil: 'domcontentloaded', timeout: 60000 });
            await new Promise(resolve => setTimeout(resolve, 2500));
            await acceptCookies(page);
            if (user) {
                const uf = getFlagValue(args, 'user-field', 'input[type=email], input[name=email], input[name=username], input[id*=email i]');
                const userField = await page.locator(uf).first();
                await userField.fill(user, { timeout: 8000 });
            }
            if (pass) {
                const pf = getFlagValue(args, 'pass-field', 'input[type=password]');
                const passField = await page.locator(pf).first();
                await passField.fill(pass, { timeout: 8000 });
            }
            const out = getFlagValue(args, 'out', path.join('/tmp', `login-${Date.now()}.png`));
            await page.screenshot({ path: out });
            const userSet = user.length > 0 ? 'gesetzt' : '-';
            const passSet = pass.length > 0 ? 'gesetzt' : '-';
            console.log(`Login-Formular ausgefüllt (user=${userSet}, pass=${passSet}). Screenshot: ${out}`);
            console.log('Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.');
        } else {
            console.log('Befehle: open <URL> | shot <URL> | login <URL> | state');
        }
    } finally {
        await browser.close(); // Profil (Cookies) bleibt auf Platte erhalten
    }
}

main().catch(err => {
    console.error(err);
    process.exit(1);
});
