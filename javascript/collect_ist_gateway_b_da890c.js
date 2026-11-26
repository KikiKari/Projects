#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "ae79564ef3861dd7b409a510a45633cdb36ad0e3e8a51fde987286ab7428bf91", "source_sha256": "da890cc26fb848b78b6a85373d6cfa4e08f6e7c2002921e1c0247960b8b361d7", "target_language": "javascript"}
// collect_ist_gateway_b.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import os from 'os';
import path from 'path';
import { execSync } from 'child_process';

const BASE_DIR = path.join(os.homedir(), '.openclaw');
const OUT_DIR = path.join(BASE_DIR, 'workspace', 'vscode');

const now = new Date();
const NOW_UTC = now.toISOString().replace(/\.\d+Z$/, 'Z');
const NOW_LOCAL = now.toLocaleString('de-DE') + ' ' + Intl.DateTimeFormat().resolvedOptions().timeZone;
const TS = now.toISOString().slice(0, 19).replace(/[:T]/g, '');

fs.mkdirSync(OUT_DIR, { recursive: true });

const IST_FILE = path.join(OUT_DIR, 'IST-ZUSTAND_GATEWAY-B_NODE7.md');
const INV_FILE = path.join(OUT_DIR, 'ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md');
const CFG_FILE = path.join(OUT_DIR, 'OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md');
const ENV_FILE = path.join(OUT_DIR, 'ENV-STATUS_GATEWAY-B_NODE7.md');
const RUN_FILE = path.join(OUT_DIR, `RUN-${TS}.md`);

const OPENCLAW_JSON = path.join(BASE_DIR, 'openclaw.json');
const ENV_DOT = path.join(BASE_DIR, '.env');
const ENV_SYSTEMD = path.join(BASE_DIR, 'gateway.systemd.env');
const VSCODE_DIR = path.join(BASE_DIR, '.vscode');

let HOSTNAME_FQDN = '';
try {
  HOSTNAME_FQDN = execSync('hostname -f', { encoding: 'utf8' }).trim();
} catch {
  HOSTNAME_FQDN = os.hostname();
}
const HOSTNAME_SHORT = os.hostname();
const ARCH = process.arch;
const KERNEL = os.release();
let OS_PRETTY = '';
try {
  const osRelease = fs.readFileSync('/etc/os-release', 'utf8');
  const match = osRelease.match(/^PRETTY_NAME=(.*)$/m);
  if (match) {
    OS_PRETTY = match[1].replace(/"/g, '');
  }
} catch {}

const IPV4_ALL = Object.values(os.networkInterfaces())
  .flat()
  .filter(iface => iface.family === 'IPv4' && !iface.internal)
  .map(iface => iface.address)
  .join(' ');

let PUBLIC_IP = '';
try {
  PUBLIC_IP = execSync('curl -4 -s --max-time 4 ifconfig.me', { encoding: 'utf8' }).trim();
} catch {}
if (!PUBLIC_IP) PUBLIC_IP = '(nicht ermittelt)';

let TAILSCALE_IP = '';
try {
  TAILSCALE_IP = execSync('tailscale ip -4', { encoding: 'utf8' }).split('\n')[0];
} catch {}
if (!TAILSCALE_IP) TAILSCALE_IP = '(nicht ermittelt)';

let OPENCLAW_VER = '';
try {
  OPENCLAW_VER = execSync('openclaw --version', { encoding: 'utf8' }).trim();
} catch {}
if (!OPENCLAW_VER) OPENCLAW_VER = '(nicht ermittelt)';

let NODE_VER = process.version;
if (!NODE_VER) NODE_VER = '(nicht ermittelt)';

const istContent = `# IST-Zustand: Gateway B / Node 7

Stand (lokal): ${NOW_LOCAL}  
Stand (UTC): ${NOW_UTC}

## 1) Identität & System

- Gateway: **B**
- Node: **7**
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
- \`${path.join(BASE_DIR, 'plugins/installs.json')}\`: ${fs.existsSync(path.join(BASE_DIR, 'plugins/installs.json')) ? 'vorhanden' : 'fehlt'}
- \`${path.join(BASE_DIR, 'plugin-skills')}\`: ${fs.existsSync(path.join(BASE_DIR, 'plugin-skills')) ? 'vorhanden' : 'fehlt'}

## 4) Hinweis

Diese Datei wird bei jedem Lauf neu geschrieben.
Zusätzlich wird ein Laufprotokoll als \`RUN-*.md\` erzeugt.`;

fs.writeFileSync(IST_FILE, istContent);

let invContent = `# Artefakt-Inventar: Gateway B / Node 7

Stand: ${NOW_LOCAL}

## Top-Level in ~/.openclaw

\`\`\`text
`;
try {
  const baseDirItems = fs.readdirSync(BASE_DIR);
  invContent += baseDirItems.join('\n');
} catch {}
invContent += `
\`\`\`

## ~/.openclaw/.vscode

\`\`\`text
`;
if (fs.existsSync(VSCODE_DIR)) {
  try {
    const vscodeItems = fs.readdirSync(VSCODE_DIR);
    invContent += vscodeItems.join('\n');
  } catch {}
} else {
  invContent += '(nicht vorhanden)';
}
invContent += `
\`\`\`

## plugin-skills/

\`\`\`text
`;
if (fs.existsSync(path.join(BASE_DIR, 'plugin-skills'))) {
  try {
    const skillsItems = fs.readdirSync(path.join(BASE_DIR, 'plugin-skills'));
    invContent += skillsItems.join('\n');
  } catch {}
} else {
  invContent += '(nicht vorhanden)';
}
invContent += `
\`\`\`

## openclaw.json Backups

\`\`\`text
`;
try {
  const backupFiles = fs.readdirSync(BASE_DIR).filter(f => f.startsWith('openclaw.json.bak'));
  if (backupFiles.length > 0) {
    invContent += backupFiles.join('\n');
  } else {
    invContent += '(keine gefunden)';
  }
} catch {
  invContent += '(keine gefunden)';
}
invContent += `
\`\`\``;

fs.writeFileSync(INV_FILE, invContent);

let cfgContent = `# OpenClaw Config Snapshot: Gateway B / Node 7

Stand: ${NOW_LOCAL}

## Schlüsselpositionen (grep)

\`\`\`text
`;
if (fs.existsSync(OPENCLAW_JSON)) {
  try {
    const content = fs.readFileSync(OPENCLAW_JSON, 'utf8');
    const lines = content.split('\n');
    lines.forEach((line, index) => {
      if (line.match(/"gateway"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"/)) {
        cfgContent += `${index + 1}: ${line}\n`;
      }
    });
  } catch {}
} else {
  cfgContent += 'openclaw.json fehlt\n';
}
cfgContent += `\`\`\`

## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)

\`\`\`json
`;
if (fs.existsSync(OPENCLAW_JSON)) {
  try {
    const content = fs.readFileSync(OPENCLAW_JSON, 'utf8');
    const lines = content.split('\n').slice(579, 780);
    cfgContent += lines.join('\n');
  } catch {
    cfgContent += '{ "error": "Lesefehler" }\n';
  }
} else {
  cfgContent += '{ "error": "openclaw.json fehlt" }\n';
}
cfgContent += `\`\`\``;

fs.writeFileSync(CFG_FILE, cfgContent);

let envContent = `# ENV-Status: Gateway B / Node 7

Stand: ${NOW_LOCAL}

## Dateien

\`\`\`text
`;
try {
  const stat1 = fs.statSync(ENV_DOT);
  const stat2 = fs.statSync(ENV_SYSTEMD);
  envContent += `${stat1.mode.toString(8)} ${stat1.uid} ${stat1.gid} ${ENV_DOT}\n`;
  envContent += `${stat2.mode.toString(8)} ${stat2.uid} ${stat2.gid} ${ENV_SYSTEMD}\n`;
} catch {}
envContent += `\`\`\`

## .env (vollständig, ungefiltert)

\`\`\`dotenv
`;
if (fs.existsSync(ENV_DOT)) {
  envContent += fs.readFileSync(ENV_DOT, 'utf8');
} else {
  envContent += '# .env fehlt\n';
}
envContent += `\`\`\`

## gateway.systemd.env (vollständig, ungefiltert)

\`\`\`dotenv
`;
if (fs.existsSync(ENV_SYSTEMD)) {
  envContent += fs.readFileSync(ENV_SYSTEMD, 'utf8');
} else {
  envContent += '# gateway.systemd.env fehlt\n';
}
envContent += `\`\`\``;

fs.writeFileSync(ENV_FILE, envContent);

const runContent = `# Laufprotokoll Gateway B / Node 7

- Zeit (lokal): ${NOW_LOCAL}
- Zeit (UTC): ${NOW_UTC}
- Script: ${process.argv[1]}

## Erzeugte Dateien

- ${path.basename(IST_FILE)}
- ${path.basename(INV_FILE)}
- ${path.basename(CFG_FILE)}
- ${path.basename(ENV_FILE)}

`;

fs.writeFileSync(RUN_FILE, runContent);

console.log('OK: IST-Zustand erfasst.');
console.log(`Ausgabeordner: ${OUT_DIR}`);
console.log('Dateien:');
try {
  const files = fs.readdirSync(OUT_DIR);
  files.forEach(file => console.log(`- ${file}`));
} catch {}
