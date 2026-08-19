#!/usr/bin/env node
// sandbox-vpn.sh — portiert nach javascript
// Quelle: shell, Onboarding@main:scripts/sandbox-vpn.sh
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

// Bringt die Sandbox reproduzierbar in das Tailscale-Tailnet des Nutzers —
// als Brücke am Agent-MITM-Proxy vorbei (sauberer Egress via SOCKS5) und mit
// Tailscale-SSH, damit die eigenen Geräte des Nutzers in die Sandbox kommen.
//
// Nutzt den WIEDERVERWENDBAREN Auth-Key aus der .env (nichts committet).
// userspace-networking: verändert NICHT die Host-Routen/den Agent-Proxy dieser
// Session; stellt einen SOCKS5-Proxy auf localhost:1055 bereit.
//
// Aufruf: scripts/sandbox-vpn.js   (idempotent; No-op ohne Auth-Key/tailscale)

import { spawn, execSync } from 'child_process';
import { promises as fs } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const projectRoot = join(__dirname, '..');

function log(message) {
  console.log(`[sandbox-vpn] ${message}`);
}

async function readAuthKey() {
  try {
    const envContent = await fs.readFile(join(projectRoot, '.env'), 'utf8');
    const match = envContent.match(/^TAILSCALE_AUTH_KEY="(.*)"/m);
    return match ? match[1] : '';
  } catch (error) {
    return '';
  }
}

function commandExists(command) {
  try {
    execSync(`command -v ${command}`, { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

function isTailscaleRunning() {
  try {
    execSync('tailscale status', { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

function isSandboxInTailnet() {
  try {
    const output = execSync('tailscale status', { encoding: 'utf8' });
    return output.includes('claude-sandbox');
  } catch {
    return false;
  }
}

function getTailscaleIP() {
  try {
    const output = execSync('tailscale ip -4', { encoding: 'utf8' });
    return output.split('\n')[0].trim();
  } catch {
    return null;
  }
}

async function main() {
  process.chdir(projectRoot);
  
  // Auth-Key aus .env lesen
  const key = await readAuthKey();
  if (!key) {
    log("kein TAILSCALE_AUTH_KEY in .env — überspringe VPN");
    process.exit(0);
  }

  // Tailscale installieren, falls nicht vorhanden
  if (!commandExists('tailscale')) {
    log("installiere Tailscale …");
    try {
      execSync('curl -fsSL https://tailscale.com/install.sh | sh', { stdio: 'ignore' });
    } catch (error) {
      log("WARNUNG: Tailscale-Install fehlgeschlagen");
      process.exit(0);
    }
  }

  // tailscaled im userspace-Modus starten
  if (!isTailscaleRunning()) {
    log("starte tailscaled (userspace, SOCKS5 localhost:1055) …");
    
    // Verzeichnis erstellen
    try {
      await fs.mkdir('/var/lib/tailscale', { recursive: true });
    } catch (error) {
      // Ignorieren, falls Berechtigungen fehlen
    }

    // tailscaled im Hintergrund starten
    const tailscaled = spawn('tailscaled', [
      '--tun=userspace-networking',
      '--socks5-server=localhost:1055',
      '--outbound-http-proxy-listen=localhost:1056',
      '--statedir=/var/lib/tailscale'
    ], {
      detached: true,
      stdio: 'ignore'
    });
    
    tailscaled.unref();
    
    // Warten bis der Dienst gestartet ist
    await new Promise(resolve => setTimeout(resolve, 4000));
  }

  // Ins Tailnet, mit Tailscale-SSH aktiviert
  if (!isSandboxInTailnet()) {
    log("tailscale up (hostname=claude-sandbox, --ssh) …");
    try {
      execSync(
        `tailscale up --authkey="${key}" --hostname=claude-sandbox --ssh --accept-routes`,
        { stdio: 'ignore' }
      );
    } catch (error) {
      log("WARNUNG: tailscale up fehlgeschlagen");
    }
  } else {
    try {
      execSync('tailscale set --ssh', { stdio: 'ignore' });
    } catch (error) {
      // Fehler ignorieren
    }
  }

  if (isTailscaleRunning()) {
    const ip = getTailscaleIP();
    log(`im Tailnet: claude-sandbox ${ip || '?'} · SSH aktiv · SOCKS5 localhost:1055`);
  }

  process.exit(0);
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});
