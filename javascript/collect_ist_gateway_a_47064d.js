#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "ad8690045c366f14c25b682df076a67c06273f56b845db60de44f95a88a413af", "source_sha256": "47064dbc7b32c01d57d42222f8cc3ac7caf9c8d82b98029dc5fc6ecb0d32f2c9", "target_language": "javascript"}
// collect_ist_gateway_a.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import os from 'os';
import path from 'path';
import { execSync } from 'child_process';

const BASE_DIR = path.join(os.homedir(), '.openclaw');
const OUT_DIR = path.join(BASE_DIR, 'workspace', 'vscode');
const NOW_UTC = new Date().toISOString().replace('T', ' ').slice(0, -1);
const NOW_LOCAL = new Date().toLocaleString('de-DE', { timeZone: Intl.DateTimeZone.getDefault() });
const TS = new Date().toISOString().slice(0, 19).replace(/[-:]/g, '').replace('T', '-');

fs.mkdirSync(OUT_DIR, { recursive: true });

const IST_FILE = path.join(OUT_DIR, 'IST-ZUSTAND_GATEWAY-A_NODE1.md');
const INV_FILE = path.join(OUT_DIR, 'ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md');
const CFG_FILE = path.join(OUT_DIR, 'OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md');
const ENV_FILE = path.join(OUT_DIR, 'ENV-STATUS_GATEWAY-A_NODE1.md');
const RUN_FILE = path.join(OUT_DIR, `RUN-${TS}.md`);

const OPENCLAW_JSON = path.join(BASE_DIR, 'openclaw.json');
const ENV_DOT = path.join(BASE_DIR, '.env');
const ENV_SYSTEMD = path.join(BASE_DIR, 'gateway.systemd.env');
const VSCODE_DIR = path.join(BASE_DIR, '.vscode');

let HOSTNAME_FQDN = '';
try {
  HOSTNAME_FQDN = os.hostname();
} catch (e) {
  HOSTNAME_FQDN = os.hostname();
}
const HOSTNAME_SHORT = os.hostname();
const ARCH = process.arch;
const KERNEL = os.release();
let OS_PRETTY = '';
try {
  const osRelease = fs.readFileSync('/etc/os-release', 'utf8');
  const prettyLine = osRelease.split('\n').find(line => line.startsWith('PRETTY_NAME='));
  if (prettyLine) {
    OS_PRETTY = prettyLine.split('=')[1].replace(/"/g, '');
  }
} catch (e) {
  OS_PRETTY = '';
}

let IPV4_ALL = '';
try {
  const interfaces = os.networkInterfaces();
  for (const name in interfaces) {
    for (const iface of interfaces[name]) {
      if (!iface.internal && iface.family === 'IPv4') {
        IPV4_ALL += iface.address + ' ';
      }
    }
  }
  IPV4_ALL = IPV4_ALL.trim();
} catch (e) {
  IPV4_ALL = '';
}

let PUBLIC_IP = '';
try {
  PUBLIC_IP = execSync('curl -4 -s --max-time 4 ifconfig.me', { encoding: 'utf8', timeout: 4000 }).trim();
} catch (e) {
  PUBLIC_IP = '';
}
if (!PUBLIC_IP) PUBLIC_IP = '(nicht ermittelt)';

let TAILSCALE_IP = '';
try {
  TAILSCALE_IP = execSync('tailscale ip -4', { encoding: 'utf8' }).split('\n')[0];
} catch (e) {
  TAILSCALE_IP = '';
}
if (!TAILSCALE_IP) TAILSCALE_IP = '(nicht ermittelt)';

let OPENCLAW_VER = '';
try {
  OPENCLAW_VER = execSync('openclaw --version', { encoding: 'utf8' }).trim();
} catch (e) {
  OPENCLAW_VER = '';
}
if (!OPENCLAW_VER) OPENCLAW_VER = '(nicht ermittelt)';

let NODE_VER = process.version;
if (!NODE_VER) NODE_VER = '(nicht ermittelt)';

const istContent = `# IST-Zustand: Gateway A / Node 1

Stand (lokal): ${NOW_LOCAL}  
Stand (UTC): ${NOW_UTC}

## 1) Identitaet & System

- Gateway: **A**
- Node: **1**
- Hostname (short): \`${HOSTNAME_SHORT}\`
- Hostname (FQDN): \`${HOSTNAME_FQDN}\`
- Architektur: \`${ARCH}\`
- Kernel: \`${KERNEL}\`
- OS: \`${OS_PRETTY}\`
- IPv4 (lokal): \`${IPV4_ALL}\`
- Public IPv4: \`${PUBLIC_IP}\`
- Tailscale IPv4: \`${TAILSCALE_IP}\`
- OpenClaw Version: \`${OPENCLAW_VER}\`
- Node.js Version: \`${NODE_VER}\`

## 2) Arbeitsverzeichnisse

- Basis: \`${BASE_DIR}\`
- Funktionell VSCode: \`${VSCODE_DIR}\`
- Workspace Doku: \`${OUT_DIR}\`

## 3) Kernartefakte (Existenz)

- \`${OPENCLAW_JSON}\`: ${fs.existsSync(OPENCLAW_JSON) ? 'vorhanden' : 'fehlt'}
- \`${ENV_DOT}\`: ${fs.existsSync(ENV_DOT) ? 'vorhanden' : 'fehlt'}
- \`${ENV_SYSTEMD}\`: ${fs.existsSync(ENV_SYSTEMD) ? 'vorhanden' : 'fehlt'}
- \`${path.join(BASE_DIR, 'plugins', 'installs.json')}\`: ${fs.existsSync(path.join(BASE_DIR, 'plugins', 'installs.json')) ? 'vorhanden' : 'fehlt'}
- \`${path.join(BASE_DIR, 'plugin-skills')}\`: ${fs.existsSync(path.join(BASE_DIR, 'plugin-skills')) ? 'vorhanden' : 'fehlt'}`;

fs.writeFileSync(IST_FILE, istContent);

let invContent = '# Artefakt-Inventar: Gateway A / Node 1\n\n';
invContent += `Stand: ${NOW_LOCAL}\n\n`;
invContent += '## Top-Level in ~/.openclaw\n\n```\n';
try {
  const baseDirItems = fs.readdirSync(BASE_DIR);
  invContent += baseDirItems.join('\n');
} catch (e) {
  // ignore
}
invContent += '\n```\n\n## ~/.openclaw/.vscode\n\n```\n';
try {
  if (fs.existsSync(VSCODE_DIR)) {
    const vscodeItems = fs.readdirSync(VSCODE_DIR);
    invContent += vscodeItems.join('\n');
  } else {
    invContent += '(nicht vorhanden)';
  }
} catch (e) {
  invContent += '(nicht vorhanden)';
}
invContent += '\n```\n\n## plugin-skills/\n\n```\n';
try {
  if (fs.existsSync(path.join(BASE_DIR, 'plugin-skills'))) {
    const skillItems = fs.readdirSync(path.join(BASE_DIR, 'plugin-skills'));
    invContent += skillItems.join('\n');
  } else {
    invContent += '(nicht vorhanden)';
  }
} catch (e) {
  invContent += '(nicht vorhanden)';
}
invContent += '\n```\n\n## openclaw.json Backups\n\n```\n';
try {
  const backupFiles = fs.readdirSync(BASE_DIR).filter(f => f.startsWith('openclaw.json.bak'));
  if (backupFiles.length > 0) {
    invContent += backupFiles.join('\n');
  } else {
    invContent += '(keine gefunden)';
  }
} catch (e) {
  invContent += '(keine gefunden)';
}
invContent += '\n```';

fs.writeFileSync(INV_FILE, invContent);

let cfgContent = '# OpenClaw Config Snapshot: Gateway A / Node 1\n\n';
cfgContent += `Stand: ${NOW_LOCAL}\n\n`;
cfgContent += '## Schluesselpositionen (grep)\n\n```\n';
try {
  if (fs.existsSync(OPENCLAW_JSON)) {
    const content = fs.readFileSync(OPENCLAW_JSON, 'utf8');
    const lines = content.split('\n');
    lines.forEach((line, index) => {
      if (line.match(/"gateway"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"/)) {
        cfgContent += `${index + 1}: ${line}\n`;
      }
    });
  } else {
    cfgContent += 'openclaw.json fehlt';
  }
} catch (e) {
  cfgContent += 'openclaw.json fehlt';
}
cfgContent += '```\n\n## Ausschnitt gateway/session/auth\n\n```json\n';
try {
  if (fs.existsSync(OPENCLAW_JSON)) {
    const content = fs.readFileSync(OPENCLAW_JSON, 'utf8');
    const lines = content.split('\n');
    const start = 579;
    const end = 779;
    for (let i = start; i <= Math.min(end, lines.length - 1); i++) {
      cfgContent += lines[i] + '\n';
    }
  } else {
    cfgContent += '{ "error": "openclaw.json fehlt" }';
  }
} catch (e) {
  cfgContent += '{ "error": "openclaw.json fehlt" }';
}
cfgContent += '```';

fs.writeFileSync(CFG_FILE, cfgContent);

let envContent = '# ENV-Status: Gateway A / Node 1\n\n';
envContent += `Stand: ${NOW_LOCAL}\n\n`;
envContent += '## Dateien\n\n```\n';
try {
  if (fs.existsSync(ENV_DOT)) {
    const stat = fs.statSync(ENV_DOT);
    envContent += `-rw-r--r-- 1 ${process.env.USER} ${process.env.USER} ${stat.size} ${stat.mtime.toISOString()} ${ENV_DOT}\n`;
  }
  if (fs.existsSync(ENV_SYSTEMD)) {
    const stat = fs.statSync(ENV_SYSTEMD);
    envContent += `-rw-r--r-- 1 ${process.env.USER} ${process.env.USER} ${stat.size} ${stat.mtime.toISOString()} ${ENV_SYSTEMD}\n`;
  }
} catch (e) {
  // ignore
}
envContent += '```\n\n## .env (vollstaendig)\n\n```dotenv\n';
try {
  if (fs.existsSync(ENV_DOT)) {
    envContent += fs.readFileSync(ENV_DOT, 'utf8');
  } else {
    envContent += '# .env fehlt';
  }
} catch (e) {
  envContent += '# .env fehlt';
}
envContent += '```\n\n## gateway.systemd.env (vollstaendig)\n\n```dotenv\n';
try {
  if (fs.existsSync(ENV_SYSTEMD)) {
    envContent += fs.readFileSync(ENV_SYSTEMD, 'utf8');
  } else {
    envContent += '# gateway.systemd.env fehlt';
  }
} catch (e) {
  envContent += '# gateway.systemd.env fehlt';
}
envContent += '```';

fs.writeFileSync(ENV_FILE, envContent);

const runContent = `# Laufprotokoll Gateway A / Node 1

- Zeit (lokal): ${NOW_LOCAL}
- Zeit (UTC): ${NOW_UTC}
- Script: ${process.argv[1]}

## Erzeugte Dateien

- ${path.basename(IST_FILE)}
- ${path.basename(INV_FILE)}
- ${path.basename(CFG_FILE)}
- ${path.basename(ENV_FILE)}`;

fs.writeFileSync(RUN_FILE, runContent);

console.log('OK: IST-Zustand erfasst.');
try {
  const files = fs.readdirSync(OUT_DIR);
  files.forEach(file => console.log('- ' + file));
} catch (e) {
  // ignore
}
