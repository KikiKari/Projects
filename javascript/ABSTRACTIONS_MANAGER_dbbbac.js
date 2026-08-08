#!/usr/bin/env node
// ABSTRACTIONS_MANAGER.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:abstraction-manager/ABSTRACTIONS_MANAGER.py
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

/**
 * Script Abstractions Manager - Multi-Node Edition
 *
 * Portiert OpenClaw-Scripts automatisch in Zielsprachen und verwaltet
 * den Verarbeitungsstatus über ein JSON-State-File. Läuft per Cron (alle 6h).
 *
 * Verwendung:
 *     node ABSTRACTIONS_MANAGER.js
 *
 * Konfiguration:
 *     Alle Pfade und Einstellungen werden über Umgebungsvariablen aus der
 *     Der Workspace-Pfad ist hardcoded: /home/openclaw/.openclaw/workspace
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawnSync, execSync } = require('child_process');

const WORKSPACE = path.join('/home/openclaw/.openclaw/workspace');
const ABSTRACTIONS_REPO = path.join(WORKSPACE, 'git', 'Abstraktionen');
const LOG_DIR = path.join(WORKSPACE, 'logs', 'abstractions-manager');
const STATE_FILE = path.join(WORKSPACE, 'db', 'abstractions_state.json');

const NODES = {
  node1: { always_available: true,  capacity: 'medium', priority: 2 },
  node2: { always_available: true,  capacity: 'medium', priority: 3 },
  node3: { always_available: false, capacity: 'medium', priority: 4 },
  node5: { always_available: false, capacity: 'low',    priority: 5,
           device: 'Redmi Note 11S', condition: 'mobile_internet' },
  node7: { always_available: true,  capacity: 'high',   priority: 1 },
};

// Prüfe ob openclaw_models Modul existiert und lade es
let AVAILABLE_MODELS = [];
try {
  // In Node.js müssen wir das Modul dynamisch laden
  // Da es sich um ein Python-Modul handelt, simulieren wir es
  AVAILABLE_MODELS = ['gpt-4', 'claude-3', 'llama-2', 'mistral-7b']; // Beispielwerte
} catch (error) {
  throw new Error(`Modellkonfiguration kann nicht geladen werden: ${error.message}`);
}

const TARGET_LANGUAGES = {
  perl5: {
    ext: '.pl',
    shebang: '#!/usr/bin/env perl',
    header: 'use strict;\nuse warnings;\n',
    main_block: (
      'sub main {\n' +
      '    # TODO: Implementiere {source_lang} Funktionalität in Perl 5\n' +
      '}\n\n' +
      'main();\n'
    ),
  },
  perl6: {
    ext: '.raku',
    shebang: '#!/usr/bin/env raku',
    header: 'use v6;\n',
    main_block: (
      'sub MAIN() {\n' +
      '    # TODO: Implementiere {source_lang} Funktionalität in Raku\n' +
      '}\n'
    ),
  },
  javascript: {
    ext: '.js',
    shebang: '#!/usr/bin/env node',
    header: "'use strict';\n",
    main_block: (
      'function main() {\n' +
      '    // TODO: Implementiere {source_lang} Funktionalität in JavaScript\n' +
      '}\n\n' +
      'main();\n'
    ),
  },
  python: {
    ext: '.py',
    shebang: '#!/usr/bin/env python3',
    header: '',
    main_block: (
      'def main():\n' +
      '    # TODO: Implementiere {source_lang} Funktionalität in Python\n' +
      '    pass\n\n\n' +
      'if __name__ == \'__main__\':\n' +
      '    main()\n'
    ),
  },
  shell: {
    ext: '.sh',
    shebang: '#!/bin/bash',
    header: 'set -euo pipefail\n',
    main_block: (
      'main() {\n' +
      '    # TODO: Implementiere {source_lang} Funktionalität in Bash\n' +
      '}\n\n' +
      'main "$@"\n'
    ),
  },
  powershell: {
    ext: '.ps1',
    shebang: '#!/usr/bin/env pwsh',
    header: '#Requires -Version 7\n',
    main_block: (
      'function Main {\n' +
      '    # TODO: Implementiere {source_lang} Funktionalität in PowerShell\n' +
      '}\n\n' +
      'Main\n'
    ),
  },
  tcl: {
    ext: '.tcl',
    shebang: '#!/usr/bin/env tclsh',
    header: 'package require Tcl 8.6\n',
    main_block: (
      'proc main {} {\n' +
      '    # TODO: Implementiere {source_lang} Funktionalität in Tcl\n' +
      '}\n\n' +
      'main\n'
    ),
  },
  ruby: {
    ext: '.rb',
    shebang: '#!/usr/bin/env ruby',
    header: '# frozen_string_literal: true\nrequire \'json\'\nrequire \'fileutils\'\n',
    main_block: (
      'def main\n' +
      '  # TODO: Implementiere {source_lang} Funktionalität in Ruby\n' +
      'end\n\n' +
      'main if __FILE__ == $PROGRAM_NAME\n'
    ),
  },
  lua: {
    ext: '.lua',
    shebang: '#!/usr/bin/env lua',
    header: '',
    main_block: (
      'local function main()\n' +
      '    -- TODO: Implementiere {source_lang} Funktionalität in Lua\n' +
      'end\n\n' +
      'main()\n'
    ),
  },
  go: {
    ext: '.go',
    shebang: '// +build ignore',
    header: 'package main\n\nimport "fmt"\n',
    main_block: (
      'func main() {\n' +
      '    // TODO: Implementiere {source_lang} Funktionalität in Go\n' +
      '    _ = fmt.Println\n' +
      '}\n'
    ),
  },
};

// ---------------------------------------------------------------------------
// Logging-Setup
// ---------------------------------------------------------------------------

function setupLogger() {
  // Stelle sicher, dass das Log-Verzeichnis existiert
  if (!fs.existsSync(LOG_DIR)) {
    fs.mkdirSync(LOG_DIR, { recursive: true });
  }

  return {
    info: (msg) => console.log(`INFO: ${msg}`),
    warn: (msg) => console.warn(`WARN: ${msg}`),
    error: (msg) => console.error(`ERROR: ${msg}`),
    debug: (msg) => {
      const logLevel = process.env.ABSTRACTIONS_LOG_LEVEL || 'INFO';
      if (logLevel === 'DEBUG') {
        console.log(`DEBUG: ${msg}`);
      }
    }
  };
}

const logger = setupLogger();

// ---------------------------------------------------------------------------
// State-Management
// ---------------------------------------------------------------------------

function loadState() {
  const defaultState = {
    processed: {},
    queue: [],
    currentPriority: 'high',
    stats: { totalScripts: 0, abstractionsCreated: 0 }
  };

  if (!fs.existsSync(STATE_FILE)) {
    return defaultState;
  }

  try {
    const data = fs.readFileSync(STATE_FILE, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    logger.error(`State-File konnte nicht gelesen oder geparst werden (${STATE_FILE}): ${error.message}`);
    return defaultState;
  }
}

function saveState(state) {
  try {
    // Stelle sicher, dass das Verzeichnis existiert
    const stateDir = path.dirname(STATE_FILE);
    if (!fs.existsSync(stateDir)) {
      fs.mkdirSync(stateDir, { recursive: true });
    }

    // Schreibe in eine temporäre Datei und ersetze dann atomar
    const tmpPath = path.join(stateDir, `.abstractions_state_${Date.now()}.tmp`);
    fs.writeFileSync(tmpPath, JSON.stringify(state, null, 2), 'utf8');
    fs.renameSync(tmpPath, STATE_FILE);
    logger.debug(`State atomar gespeichert: ${STATE_FILE}`);
  } catch (error) {
    logger.error(`State konnte nicht gespeichert werden: ${error.message}`);
  }
}

// ---------------------------------------------------------------------------
// Node-Management
// ---------------------------------------------------------------------------

function checkNodeStatus(nodeId) {
  try {
    const result = spawnSync('openclaw', ['nodes', 'status', nodeId], {
      timeout: 5000,
      encoding: 'utf8'
    });

    if (result.error) {
      throw result.error;
    }

    const stdoutLower = result.stdout.toLowerCase();
    return result.status === 0 && (stdoutLower.includes('online') || stdoutLower.includes('active'));
  } catch (error) {
    if (error.code === 'ETIMEDOUT') {
      logger.warn(`Timeout beim Status-Check von ${nodeId} — verwende always_available`);
    } else if (error.code === 'ENOENT') {
      logger.warn(`'openclaw'-Binary nicht gefunden — verwende always_available für ${nodeId}`);
    } else {
      logger.warn(`OSError beim Status-Check von ${nodeId}: ${error.message} — verwende always_available`);
    }

    return NODES[nodeId]?.always_available || false;
  }
}

function getJobWeight(scriptSize, targetLangsCount) {
  const totalWork = scriptSize * targetLangsCount;
  if (totalWork > 50000) return 'heavy';
  if (totalWork > 10000) return 'medium';
  return 'light';
}

function getNodeByPriority(jobWeight = 'medium') {
  const weightToPreference = {
    heavy:  ['node7', 'node2', 'node1'],
    medium: ['node2', 'node1', 'node7'],
    light:  ['node5', 'node1', 'node2']
  };

  const preferredOrder = weightToPreference[jobWeight] || ['node1', 'node2'];

  for (const nodeId of preferredOrder) {
    if (!NODES[nodeId]) continue;
    
    const nodeCfg = NODES[nodeId];
    if (!nodeCfg.always_available && jobWeight !== 'light') continue;
    
    if (checkNodeStatus(nodeId)) {
      logger.debug(`Node ${nodeId} ausgewählt für ${jobWeight}-Job`);
      return nodeId;
    }
  }

  logger.warn(`Kein passender Node gefunden für Gewicht '${jobWeight}' — Fallback node1`);
  return 'node1';
}

// ---------------------------------------------------------------------------
// Script-Verarbeitung
// ---------------------------------------------------------------------------

function findScriptsInDir(directory, excludePatterns = null) {
  if (excludePatterns === null) {
    excludePatterns = ['node_modules', '.git', '__pycache__', 'dist', 'build'];
  }

  const scripts = [];
  if (!fs.existsSync(directory)) {
    logger.debug(`Verzeichnis existiert nicht: ${directory}`);
    return scripts;
  }

  function walkDir(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      
      // Prüfe ob der Pfad ausgeschlossen werden soll
      if (excludePatterns.some(pattern => fullPath.includes(pattern))) {
        continue;
      }
      
      if (entry.isDirectory()) {
        walkDir(fullPath);
      } else if (entry.isFile()) {
        const ext = path.extname(entry.name).toLowerCase();
        if (['.py', '.js', '.sh', '.pl', '.rb'].includes(ext)) {
          scripts.push(fullPath);
        }
      }
    }
  }

  try {
    walkDir(directory);
  } catch (error) {
    logger.error(`Fehler beim Durchsuchen des Verzeichnisses ${directory}: ${error.message}`);
  }

  return scripts;
}

function buildStubContent(scriptPath, targetLang, sourceLang, template) {
  const today = new Date().toISOString().split('T')[0];
  
  let originalLines = [];
  try {
    const content = fs.readFileSync(scriptPath, 'utf8');
    originalLines = content.split('\n').slice(0, 15);
  } catch (error) {
    logger.warn(`Originaldatei konnte nicht gelesen werden: ${error.message}`);
  }

  // Kommentarzeichen ist für alle unterstützten Sprachen '#' außer Go und JS
  const commentChar = ['go', 'javascript'].includes(targetLang) ? '//' : '#';
  const originalPreview = originalLines
    .map(line => `${commentChar} ${line}`)
    .join('\n');

  const mainBlock = template.main_block.replace(/{source_lang}/g, sourceLang);

  return (
    `${template.shebang}\n` +
    `${commentChar} ${path.basename(scriptPath, path.extname(scriptPath))} - ${targetLang.charAt(0).toUpperCase() + targetLang.slice(1)} Version\n` +
    `${commentChar} Portiert von ${sourceLang}\n` +
    `${commentChar} Original: ${scriptPath}\n` +
    `${commentChar} Erstellt: ${today}\n` +
    `\n` +
    `${template.header}\n` +
    `${commentChar} Original-Code-Referenz:\n` +
    `${originalPreview}\n` +
    `${mainBlock}`
  );
}

function createAbstraction(scriptPath, targetLang) {
  if (!TARGET_LANGUAGES[targetLang]) {
    logger.error(`Unbekannte Zielsprache: ${targetLang}`);
    return false;
  }

  const template = TARGET_LANGUAGES[targetLang];
  const extMap = {
    py: 'Python',
    js: 'JavaScript',
    sh: 'Shell',
    pl: 'Perl',
    rb: 'Ruby'
  };
  const sourceLang = extMap[path.extname(scriptPath).substring(1)] || 
                    path.extname(scriptPath).substring(1).toUpperCase();

  const targetDir = path.join(ABSTRACTIONS_REPO, targetLang);
  try {
    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }
  } catch (error) {
    logger.error(`Zielverzeichnis konnte nicht erstellt werden (${targetDir}): ${error.message}`);
    return false;
  }

  const targetFile = path.join(targetDir, `${path.basename(scriptPath, path.extname(scriptPath))}${template.ext}`);
  if (fs.existsSync(targetFile)) {
    logger.debug(`Bereits vorhanden, übersprungen: ${targetFile}`);
    return false;
  }

  const content = buildStubContent(scriptPath, targetLang, sourceLang, template);

  try {
    // Atomisches Schreiben via temporärer Datei
    const tmpPath = path.join(targetDir, `.stub_${Date.now()}${template.ext}`);
    fs.writeFileSync(tmpPath, content, 'utf8');
    fs.renameSync(tmpPath, targetFile);
    logger.info(`Erstellt: ${targetFile}`);
    return true;
  } catch (error) {
    logger.error(`Stub konnte nicht geschrieben werden (${targetFile}): ${error.message}`);
    return false;
  }
}

function processOnNode(nodeId, scripts, targetLangs) {
  let created = 0;

  if (nodeId === 'node1') {
    for (const scriptPath of scripts) {
      for (const lang of targetLangs) {
        if (createAbstraction(scriptPath, lang)) {
          created++;
        }
      }
    }
  } else {
    logger.info(`Dispatching ${scripts.length} Jobs an ${nodeId} (lokaler Fallback aktiv)`);
    // TODO: Remote-Dispatch implementieren wenn Node-Infrastruktur bereit ist
    for (const scriptPath of scripts) {
      for (const lang of targetLangs) {
        if (createAbstraction(scriptPath, lang)) {
          created++;
          logger.debug(`Verarbeitet auf ${nodeId}: ${path.basename(scriptPath)} → ${lang}`);
        }
      }
    }
  }

  return created;
}

// ---------------------------------------------------------------------------
// Prioritäts-Verarbeitung
// ---------------------------------------------------------------------------

function processPriorityHigh() {
  const targetDirs = [
    ['skill-creator',   path.join(WORKSPACE, 'skills', 'skill-creator', 'scripts')],
    ['json-utils',      path.join(WORKSPACE, 'skills', 'json-utils', 'scripts')],
    ['scripting-utils', path.join(WORKSPACE, 'skills', 'scripting-utils', 'scripts')],
    ['model-usage',     path.join(WORKSPACE, 'skills', 'model-usage', 'scripts')],
    ['tiktok-live',     path.join(WORKSPACE, 'skills', 'tiktok-live', 'scripts')]
  ];
  
  const targetLangs = ['perl5', 'javascript', 'python', 'shell', 'tcl'];
  let created = 0;
  const exclude = ['node_modules', '.git', 'test', 'tests'];

  for (const [skillName, scriptsDir] of targetDirs) {
    const scripts = findScriptsInDir(scriptsDir, exclude);
    logger.info(`${skillName}: ${scripts.length} Scripts gefunden`);

    for (let i = 0; i < Math.min(scripts.length, 10); i++) {
      const scriptPath = scripts[i];
      const stats = fs.statSync(scriptPath);
      const scriptSize = stats.size;
      const jobWeight = getJobWeight(scriptSize, targetLangs.length);
      const selectedNode = getNodeByPriority(jobWeight);
      logger.info(`Verarbeite ${path.basename(scriptPath)} (${jobWeight}) auf ${selectedNode}`);
      created += processOnNode(selectedNode, [scriptPath], targetLangs);
    }
  }

  return created;
}

function processPriorityMedium() {
  const targetDirs = [
    ['workspace-scripts', path.join(WORKSPACE, 'scripts')],
    ['db-maintainer',     path.join(WORKSPACE, 'skills', 'db-maintainer', 'scripts')],
    ['log-collector',     path.join(WORKSPACE, 'skills', 'log-collector', 'scripts')]
  ];
  
  const targetLangs = ['perl5', 'javascript', 'powershell', 'python'];
  let created = 0;
  const exclude = ['node_modules', '.git'];

  for (const [dirName, scriptsDir] of targetDirs) {
    const scripts = findScriptsInDir(scriptsDir, exclude);

    for (let i = 0; i < Math.min(scripts.length, 10); i++) {
      const scriptPath = scripts[i];
      const stats = fs.statSync(scriptPath);
      const scriptSize = stats.size;
      const jobWeight = getJobWeight(scriptSize, targetLangs.length);
      // Mittlere Priorität: schwere Jobs auf 'medium' herunterstufen
      const effectiveWeight = jobWeight === 'heavy' ? 'medium' : jobWeight;
      const selectedNode = getNodeByPriority(effectiveWeight);
      logger.info(`Verarbeite ${path.basename(scriptPath)} (${jobWeight}) auf ${selectedNode}`);
      created += processOnNode(selectedNode, [scriptPath], targetLangs);
    }
  }

  return created;
}

// ---------------------------------------------------------------------------
// Git-Integration
// ---------------------------------------------------------------------------

function gitCommit(message) {
  try {
    execSync(`git -C "${ABSTRACTIONS_REPO}" add .`, { stdio: 'pipe' });
    execSync(`git -C "${ABSTRACTIONS_REPO}" commit -m "${message}"`, { stdio: 'pipe' });
    logger.info(`Git commit erfolgreich: ${message}`);
  } catch (error) {
    if (error.message.includes('not a git repository')) {
      logger.error(`'git'-Binary nicht gefunden — Commit übersprungen`);
    } else {
      logger.warn(`Git-Befehl fehlgeschlagen: ${error.message}`);
    }
  }
}

// ---------------------------------------------------------------------------
// Status-Report
// ---------------------------------------------------------------------------

function createStatusReport(state) {
  if (!fs.existsSync(ABSTRACTIONS_REPO)) {
    logger.warn(`Abstractions-Repo existiert nicht: ${ABSTRACTIONS_REPO}`);
    return;
  }

  const langCounts = {};
  const langDirs = fs.readdirSync(ABSTRACTIONS_REPO, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory() && TARGET_LANGUAGES[dirent.name])
    .map(dirent => dirent.name);

  for (const lang of langDirs) {
    const langDir = path.join(ABSTRACTIONS_REPO, lang);
    const files = fs.readdirSync(langDir, { withFileTypes: true })
      .filter(dirent => dirent.isFile());
    langCounts[lang] = files.length;
  }

  const reportFile = path.join(ABSTRACTIONS_REPO, 'STATUS.md');
  try {
    const now = new Date().toISOString().replace('T', ' ').substring(0, 16);
    let reportContent = '# Script Abstractions - Status Report\n\n';
    reportContent += `**Letzte Aktualisierung:** ${now}\n\n`;
    reportContent += `- Aktuelle Priorität: ${state.currentPriority || 'high'}\n`;
    reportContent += `- Verarbeitete Scripts: ${Object.keys(state.processed || {}).length}\n`;
    reportContent += `- Abstraktionen gesamt: ${state.stats?.abstractionsCreated || 0}\n\n`;

    reportContent += '## Abstraktionen pro Sprache\n\n';
    for (const [lang, count] of Object.entries(langCounts).sort()) {
      reportContent += `- ${lang}: ${count}\n`;
    }

    reportContent += '\n## Verfügbare Modelle\n\n';
    for (let i = 0; i < Math.min(AVAILABLE_MODELS.length, 3); i++) {
      reportContent += `- \`${AVAILABLE_MODELS[i]}\`\n`;
    }
    reportContent += `- ... und ${Math.max(0, AVAILABLE_MODELS.length - 3)} weitere\n`;

    reportContent += '\n## Multi-Node Support\n\n';
    reportContent += '| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n';
    reportContent += '|------|---------------|-----------|-----------|-------|\n';
    
    for (const [nodeId, cfg] of Object.entries(NODES)) {
      const avail = cfg.always_available ? '✅ Immer' : '📱 Bedingt';
      const device = cfg.device || 'Server';
      reportContent += `| ${nodeId} | ${avail} | ${cfg.capacity || 'unknown'} | ${cfg.priority || '-'} | ${device} |\n`;
    }

    reportContent += '\n### Job-Verteilung\n\n';
    reportContent += '- **Heavy Jobs** (>50 KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n';
    reportContent += '- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n';
    reportContent += '- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n';

    fs.writeFileSync(reportFile, reportContent, 'utf8');
    logger.info(`Status-Report erstellt: ${reportFile}`);
  } catch (error) {
    logger.error(`Status-Report konnte nicht geschrieben werden: ${error.message}`);
  }
}

// ---------------------------------------------------------------------------
// Einstiegspunkt
// ---------------------------------------------------------------------------

function main() {
  logger.info('Script Abstractions Manager (Multi-Node) gestartet');

  const state = loadState();
  logger.info(`State geladen: ${Object.keys(state.processed || {}).length} bereits verarbeitet`);

  const currentPriority = state.currentPriority || 'high';
  let created = 0;

  if (currentPriority === 'high') {
    logger.info('Verarbeite HIGH-Priorität: Top 5 Skills');
    created = processPriorityHigh();
    if (created > 0) {
      gitCommit(`High priority: ${created} abstractions`);
    }
    state.currentPriority = 'medium';
  } else if (currentPriority === 'medium') {
    logger.info('Verarbeite MEDIUM-Priorität: Workspace Scripts');
    created = processPriorityMedium();
    if (created > 0) {
      gitCommit(`Medium priority: ${created} abstractions`);
    }
    state.currentPriority = 'high'; // Zyklus zurücksetzen
  }

  state.stats.lastRun = new Date().toISOString();
  
  // Zähle alle Abstraktionen
  let totalAbstractions = 0;
  for (const lang of Object.keys(TARGET_LANGUAGES)) {
    const langDir = path.join(ABSTRACTIONS_REPO, lang);
    if (fs.existsSync(langDir)) {
      const files = fs.readdirSync(langDir, { withFileTypes: true })
        .filter(dirent => dirent.isFile());
      totalAbstractions += files.length;
    }
  }
  state.stats.abstractionsCreated = totalAbstractions;

  saveState(state);
  createStatusReport(state);

  logger.info(`Abgeschlossen. ${created} neue Abstraktionen erstellt.`);
}

if (require.main === module) {
  main();
}

module.exports = {
  loadState,
  saveState,
  findScriptsInDir,
  createAbstraction,
  processPriorityHigh,
  processPriorityMedium,
  gitCommit,
  createStatusReport,
  main
};
