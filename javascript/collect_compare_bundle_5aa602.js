#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "da8f4d315eee4abe576828f3f58c1c476e7e857fb031851ecf235659e3973012", "source_sha256": "5aa602a80e57cbc63f54485d4cd66e205c54bd9f32bc03434218ff9bd388b3ab", "target_language": "javascript"}
// collect_compare_bundle.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
// auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import { execSync } from 'child_process';
import path from 'path';

const ROOT = "/home/openclaw/.openclaw";
const OUT_DIR = path.join(ROOT, "workspace", "vscode", "compare");
const TRANSFER_DIR = path.join(OUT_DIR, "transfer");
const MD_FILE = path.join(OUT_DIR, "local-gateway-config.md");
const TREE_FILE = path.join(OUT_DIR, "tree.txt");
const BACKUP_FILE = "/home/openclaw/openclaw-backup.tar.gz";

const NOW_LOCAL = new Date().toLocaleString('de-DE', { timeZoneName: 'short' });
const NOW_UTC = new Date().toISOString().replace(/\.\d+Z$/, 'Z');
const HOST = execSync('hostname -f 2>/dev/null || hostname', { encoding: 'utf8' }).trim();

const OPENCLAW_JSON = path.join(ROOT, "openclaw.json");
const EXEC_APPROVALS_JSON = path.join(ROOT, "exec-approvals.json");
const GATEWAY_SYSTEMD_ENV = path.join(ROOT, "gateway.systemd.env");
const DOT_ENV = path.join(ROOT, ".env");
const CONFIG_DIR = path.join(ROOT, ".config");
const AGENTS_DIR = path.join(ROOT, "agents");

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.mkdirSync(TRANSFER_DIR, { recursive: true });

try {
  execSync('which tree', { stdio: 'ignore' });
} catch (error) {
  console.error("Fehler: 'tree' ist nicht installiert.");
  process.exit(1);
}

function appendFileVerbatim(label, filePath, lang = 'text') {
  let content = '';
  
  content += '\n';
  content += `## ${label}\n`;
  content += '\n';
  content += `Pfad: \`${filePath}\`\n`;
  content += '\n';
  content += `\`\`\`${lang}\n`;
  
  try {
    if (fs.existsSync(filePath)) {
      content += fs.readFileSync(filePath, 'utf8');
    } else {
      content += `[FEHLT] ${filePath}\n`;
    }
  } catch (err) {
    content += `[FEHLT] ${filePath}\n`;
  }
  
  content += '\n';
  content += '```\n';
  
  fs.appendFileSync(MD_FILE, content);
}

function appendEnvVerbatim() {
  let content = '';
  
  content += '\n';
  content += '## Umgebungsvariablen (env)\n';
  content += '\n';
  content += '```text\n';
  
  for (const [key, value] of Object.entries(process.env)) {
    content += `${key}=${value}\n`;
  }
  
  content += '```\n';
  
  fs.appendFileSync(MD_FILE, content);
}

function appendDirFilesVerbatim(section, dir) {
  let content = '';
  
  content += '\n';
  content += `## ${section}\n`;
  content += '\n';
  
  if (!fs.existsSync(dir)) {
    content += `[FEHLT] ${dir}\n`;
    fs.appendFileSync(MD_FILE, content);
    return;
  }
  
  content += `Basisverzeichnis: \`${dir}\`\n`;
  fs.appendFileSync(MD_FILE, content);
  
  const files = getAllFiles(dir);
  
  for (const file of files) {
    let fileContent = '';
    
    fileContent += '\n';
    fileContent += `### Datei: \`${file}\`\n`;
    fileContent += '\n';
    fileContent += '```text\n';
    
    try {
      fileContent += fs.readFileSync(file, 'utf8');
    } catch (err) {
      fileContent += '[FEHLER BEIM LESEN]\n';
    }
    
    fileContent += '\n';
    fileContent += '```\n';
    
    fs.appendFileSync(MD_FILE, fileContent);
  }
}

function getAllFiles(dirPath) {
  let results = [];
  
  try {
    const list = fs.readdirSync(dirPath);
    list.sort();
    
    for (const item of list) {
      const itemPath = path.join(dirPath, item);
      const stat = fs.statSync(itemPath);
      
      if (stat.isDirectory()) {
        results = results.concat(getAllFiles(itemPath));
      } else {
        results.push(itemPath);
      }
    }
  } catch (err) {
    // Ignore errors and continue
  }
  
  return results;
}

// Write initial content to MD file
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

execSync(`tree -a -L 6 "${ROOT}" > "${TREE_FILE}"`);

execSync(`openclaw backup create --output "${BACKUP_FILE}" --verify`);
fs.copyFileSync(BACKUP_FILE, path.join(OUT_DIR, path.basename(BACKUP_FILE)));

console.log("OK");
console.log("Erzeugt:");
console.log(`- ${MD_FILE}`);
console.log(`- ${TREE_FILE}`);
console.log(`- ${BACKUP_FILE}`);
console.log(`- ${TRANSFER_DIR} (leer)`);
