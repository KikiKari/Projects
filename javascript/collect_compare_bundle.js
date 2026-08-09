#!/usr/bin/env node
// collect_compare_bundle.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
// auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const ROOT = "/home/openclaw/.openclaw";
const OUT_DIR = path.join(ROOT, "workspace/vscode/compare");
const TRANSFER_DIR = path.join(OUT_DIR, "transfer");
const MD_FILE = path.join(OUT_DIR, "local-gateway-config.md");
const TREE_FILE = path.join(OUT_DIR, "tree.txt");
const BACKUP_FILE = "/home/openclaw/openclaw-backup.tar.gz";

const NOW_LOCAL = new Date().toLocaleString('de-DE', { timeZoneName: 'short' });
const NOW_UTC = new Date().toISOString().replace(/\.\d+Z$/, 'Z');
const HOST = (() => {
  try {
    return execSync('hostname -f', { encoding: 'utf8' }).trim();
  } catch {
    return execSync('hostname', { encoding: 'utf8' }).trim();
  }
})();

const OPENCLAW_JSON = path.join(ROOT, "openclaw.json");
const EXEC_APPROVALS_JSON = path.join(ROOT, "exec-approvals.json");
const GATEWAY_SYSTEMD_ENV = path.join(ROOT, "gateway.systemd.env");
const DOT_ENV = path.join(ROOT, ".env");
const CONFIG_DIR = path.join(ROOT, ".config");
const AGENTS_DIR = path.join(ROOT, "agents");

// Stelle sicher, dass die Verzeichnisse existieren
fs.mkdirSync(OUT_DIR, { recursive: true });
fs.mkdirSync(TRANSFER_DIR, { recursive: true });

// Prüfe ob 'tree' verfügbar ist
try {
  execSync('which tree', { stdio: 'ignore' });
} catch {
  console.error("Fehler: 'tree' ist nicht installiert.");
  process.exit(1);
}

function appendFileVerbatim(label, filePath, lang = 'text') {
  let content = '\n';
  content += `## ${label}\n\n`;
  content += `Pfad: \`${filePath}\`\n\n`;
  content += `\`\`\`${lang}\n`;
  
  if (fs.existsSync(filePath)) {
    content += fs.readFileSync(filePath, 'utf8');
  } else {
    content += `[FEHLT] ${filePath}\n`;
  }
  
  content += '\n```\n';
  fs.appendFileSync(MD_FILE, content);
}

function appendEnvVerbatim() {
  let content = '\n';
  content += '## Umgebungsvariablen (env)\n\n';
  content += '```text\n';
  content += Object.entries(process.env)
    .map(([key, value]) => `${key}=${value}`)
    .join('\n');
  content += '\n```\n';
  fs.appendFileSync(MD_FILE, content);
}

function appendDirFilesVerbatim(section, dir) {
  let content = '\n';
  content += `## ${section}\n\n`;
  
  if (!fs.existsSync(dir)) {
    content += `[FEHLT] ${dir}\n`;
    fs.appendFileSync(MD_FILE, content);
    return;
  }
  
  content += `Basisverzeichnis: \`${dir}\`\n`;
  fs.appendFileSync(MD_FILE, content);
  
  function walkDirectory(directory) {
    const entries = fs.readdirSync(directory, { withFileTypes: true });
    
    // Sortiere Einträge: Verzeichnisse zuerst, dann Dateien, beide alphabetisch
    entries.sort((a, b) => {
      if (a.isDirectory() && !b.isDirectory()) return -1;
      if (!a.isDirectory() && b.isDirectory()) return 1;
      return a.name.localeCompare(b.name);
    });
    
    for (const entry of entries) {
      const fullPath = path.join(directory, entry.name);
      
      if (entry.isDirectory()) {
        walkDirectory(fullPath);
      } else {
        let fileContent = '\n';
        fileContent += `### Datei: \`${fullPath}\`\n\n`;
        fileContent += '```text\n';
        fileContent += fs.readFileSync(fullPath, 'utf8');
        fileContent += '\n```\n';
        fs.appendFileSync(MD_FILE, fileContent);
      }
    }
  }
  
  walkDirectory(dir);
}

// Initialisiere die Markdown-Datei
let initialContent = `# Lokaler Gateway-Konfigurationsstand

Generiert: ${NOW_LOCAL}
UTC: ${NOW_UTC}
Host: ${HOST}

Diese Datei enthaelt den lokalen Stand mit unveraenderten Inhalten.
`;

fs.writeFileSync(MD_FILE, initialContent);

appendFileVerbatim("openclaw.json", OPENCLAW_JSON, "json");
appendFileVerbatim("exec-approvals.json", EXEC_APPROVALS_JSON, "json");
appendFileVerbatim("gateway.systemd.env", GATEWAY_SYSTEMD_ENV, "dotenv");
appendFileVerbatim(".env", DOT_ENV, "dotenv");
appendEnvVerbatim();
appendDirFilesVerbatim(".config (alle Dateien rekursiv)", CONFIG_DIR);
appendDirFilesVerbatim("agents (alle Dateien rekursiv)", AGENTS_DIR);

// Erzeuge Baumstruktur und Backup
execSync(`tree -a -L 6 "${ROOT}" > "${TREE_FILE}"`, { stdio: 'inherit' });

execSync(`openclaw backup create --output "${BACKUP_FILE}" --verify`, { stdio: 'inherit' });
fs.copyFileSync(BACKUP_FILE, path.join(OUT_DIR, path.basename(BACKUP_FILE)));

console.log("OK");
console.log("Erzeugt:");
console.log(`- ${MD_FILE}`);
console.log(`- ${TREE_FILE}`);
console.log(`- ${BACKUP_FILE}`);
console.log(`- ${TRANSFER_DIR} (leer)`);
