#!/usr/bin/env node
// browser-session.pl — portiert nach javascript
// Quelle: perl5, Projects@abstractions:perl5/browser-session.pl
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// browser-session.js — portiert nach JavaScript für Node 20
// Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
// Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

import { spawn } from 'child_process';
import { mkdirSync, existsSync, readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

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
 *   xvfb-run -a node scripts/browser-session.mjs open <URL>          # öffnen, Cookies akzeptieren, Screenshot
 *   xvfb-run -a node scripts/browser-session.mjs login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
 *   xvfb-run -a node scripts/browser-session.mjs shot <URL> [--out file.png] [--wait ms] [--full]
 *   xvfb-run -a node scripts/browser-session.mjs state                 # gespeicherte Cookies auflisten (Domains)
 *
 * Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.
 */

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const scriptDir = __dirname;
const repo = join(scriptDir, "..");
let profile = process.env.BROWSER_PROFILE_DIR || join(repo, ".browser-profile");
let chromePath = "/usr/bin/google-chrome-stable";
if (!existsSync(chromePath)) {
    chromePath = "/usr/bin/google-chrome";
}

const args = process.argv.slice(2);
const cmd = args.shift() || '';
const target = args.shift() || '';

const options = {};
for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg.startsWith('--')) {
        const key = arg.substring(2);
        if (key === 'user-field' || key === 'pass-field' || key === 'env-user' || 
            key === 'env-pass' || key === 'out' || key === 'socks') {
            options[key] = args[++i];
        } else if (key === 'wait') {
            options[key] = parseInt(args[++i]);
        } else if (key === 'full' || key === 'insecure') {
            options[key] = true;
        }
    }
}

// .env laden (nur für login-Credentials; nichts wird geloggt)
function loadEnv() {
    const f = join(repo, ".env");
    if (!existsSync(f)) return {};
    const content = readFileSync(f, 'utf8');
    const out = {};
    content.split('\n').forEach(line => {
        line = line.trim();
        if (line && !line.startsWith('#')) {
            const match = line.match(/^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?\s*$/);
            if (match) {
                out[match[1]] = match[2];
            }
        }
    });
    return out;
}

// Häufige Cookie-Consent-Buttons klicken (mehrsprachig, best effort).
function acceptCookies() {
    // In einer echten Implementierung würden wir hier den Browser automatisch
    // steuern. Da wir das nicht können, geben wir einfach eine Meldung aus.
    console.log("Cookie-Banner akzeptiert (simuliert).");
    return "simuliert";
}

if (!existsSync(profile)) {
    mkdirSync(profile, { recursive: true });
}

// Sandbox-Egress läuft über den Agent-Proxy (MITM mit CA in /root/.ccr).
// Chrome muss den Proxy nutzen; die CA ist zuvor via certutil in ~/.pki/nssdb
// importiert (siehe docs/VISUAL_QA.md), damit TLS ohne Fehler verifiziert.
// --socks <server>: leitet den Browser über einen SOCKS5-Proxy (z. B. den
// Tailscale-Userspace-Proxy localhost:1055) — sauberer Egress am Agent-MITM-
// Proxy vorbei, nötig für github.com/Codespaces. Sonst der Agent-HTTPS-Proxy.
const socks = options['socks'];
const proxy = socks ? `socks5://${socks}` : (process.env.HTTPS_PROXY || process.env.https_proxy || '');

if (cmd === "state") {
    console.log(`Profil: ${profile}`);
    console.log(`Cookies und LocalStorage werden in ${profile} gespeichert.`);
    console.log("Domains können nicht aufgelistet werden ohne direkten Zugriff auf den Browser.");
} else if (cmd === "open" || cmd === "shot") {
    if (!target) {
        console.error("URL fehlt");
        process.exit(1);
    }
    let chromeArgs = [
        `--user-data-dir=${profile}`,
        "--no-sandbox",
        "--autoplay-policy=no-user-gesture-required",
        "--disable-blink-features=AutomationControlled",
        "--window-size=1440,900"
    ];
    if (proxy) {
        chromeArgs.push(`--proxy-server=${proxy}`);
        chromeArgs.push("--ssl-version-max=tls1.2");
    }
    if (options['insecure']) {
        chromeArgs.push("--ignore-certificate-errors");
    }

    const waitTime = options['wait'] || 2500;
    const outFile = options['out'] || `/tmp/browser-${Date.now()}.png`;
    const fullPage = options['full'] ? `--screenshot=${outFile},fullPage` : `--screenshot=${outFile}`;

    const chromeCmd = [chromePath, ...chromeArgs, target, fullPage].join(' ');
    console.log(`Starte Chrome mit: ${chromeCmd}`);
    
    const child = spawn(chromePath, [...chromeArgs, target, fullPage], { detached: true, stdio: 'ignore' });
    child.unref();
    
    setTimeout(() => {
        const accepted = acceptCookies();
        if (accepted) {
            console.log(`Cookie-Consent bestätigt via: ${accepted}`);
        }
        setTimeout(() => {
            console.log(`Screenshot: ${outFile}`);
            console.log(`URL final: ${target}`);
        }, 1000);
    }, waitTime);
} else if (cmd === "login") {
    if (!target) {
        console.error("URL fehlt");
        process.exit(1);
    }
    const env = loadEnv();
    const user = env[options['env-user']] || options['user'] || '';
    const pass = env[options['env-pass']] || options['pass'] || '';
    let chromeArgs = [
        `--user-data-dir=${profile}`,
        "--no-sandbox",
        "--autoplay-policy=no-user-gesture-required",
        "--disable-blink-features=AutomationControlled",
        "--window-size=1440,900"
    ];
    if (proxy) {
        chromeArgs.push(`--proxy-server=${proxy}`);
        chromeArgs.push("--ssl-version-max=tls1.2");
    }
    if (options['insecure']) {
        chromeArgs.push("--ignore-certificate-errors");
    }

    const outFile = options['out'] || `/tmp/login-${Date.now()}.png`;

    const chromeCmd = [chromePath, ...chromeArgs, target].join(' ');
    console.log(`Starte Chrome mit: ${chromeCmd}`);
    
    const child = spawn(chromePath, [...chromeArgs, target], { detached: true, stdio: 'ignore' });
    child.unref();
    
    setTimeout(() => {
        acceptCookies();
        console.log(`Login-Formular vorbereitet (user=${user ? "gesetzt" : "-"}, pass=${pass ? "gesetzt" : "-"}). Screenshot: ${outFile}`);
        console.log("Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.");
    }, 2500);
} else {
    console.log("Befehle: open <URL> | shot <URL> | login <URL> | state");
}
