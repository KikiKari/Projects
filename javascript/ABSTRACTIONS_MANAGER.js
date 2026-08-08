#!/usr/bin/env node
// ABSTRACTIONS_MANAGER.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:abstraction-manager/ABSTRACTIONS_MANAGER.py
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
const winston = require('winston');

// ---------------------------------------------------------------------------
// Konfiguration
// ---------------------------------------------------------------------------

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

const AVAILABLE_MODELS = [
  'openrouter/moonshotai/kimi-k2.5',
  'openrouter/openai/gpt-4o',
  'openrouter/anthropic/claude-3-5-sonnet-20241022',
  'openrouter/google/gemini-2.0-flash-001',
  'openrouter/nvidia/llama-3.3-nemotron-super-49b-v1',
  'openrouter/qwen/qwen-2.5-coder-32b-instruct',
];

const TARGET_LANGUAGES = {
  perl5: {
    ext: '.pl',
    shebang: '#!/usr/bin/env perl',
    header: 'use strict;\nuse warnings;\n',
    main_block: (
      'sub main {{\n' +
      '    # TODO: Implementiere {source_lang} Funktionalität in Perl 5\n' +
      '}}\n\n' +
      'main();\n'
    ),
  },
  perl6: {
    ext: '.raku',
    shebang: '#!/usr/bin/env raku',
    header: 'use v6;\n',
    main_block: (
      'sub MAIN() {{\n' +
      '    # TODO: Implementiere {source_lang} Funktionalität in Raku\n' +
      '}}\n'
    ),
  },
  javascript: {
    ext: '.js',
    shebang: '#!/usr/bin/env node',
    header: "'use strict';\n",
    main_block: (
      'function main() {{\n' +
      '    // TODO: Implementiere {source_lang} Funktionalität in JavaScript\n' +
      '}}\n\n' +
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
      'main() {{\n' +
      '    # TODO: Implementiere {source_lang} Funktionalität in Bash\n' +
      '}}\n\n' +
      'main "$@"\n'
    ),
  },
  powershell: {
    ext: '.ps1',
    shebang: '#!/usr/bin/env pwsh',
    header: '#Requires -Version 7\n',
    main_block: (
      'function Main {{\n' +
      '    # TODO: Implementiere {source_lang} Funktionalität in PowerShell\n' +
      '}}\n\n' +
      'Main\n'
    ),
  },
  tcl: {
    ext: '.tcl',
    shebang: '#!/usr/bin/env tclsh',
    header: 'package require Tcl 8.6\n',
    main_block: (
      'proc main {{}} {{\n' +
      '    # TODO: Implementiere {source_lang} Funktionalität in Tcl\n' +
      '}}\n\n' +
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
      'func main() {{\n' +
      '    // TODO: Implementiere {source_lang} Funktionalität in Go\n' +
      '    _ = fmt.Println\n' +
      '}}\n'
    ),
  },
};

// ---------------------------------------------------------------------------
// Logging-Setup (einmalig konfiguriert, nicht pro Aufruf geöffnet)
// ---------------------------------------------------------------------------

function setupLogger() {
  const logLevelName = process.env.ABSTRACTIONS_LOG_LEVEL || 'info';
  const logLevel = winston.levelMap[logLevelName.toLowerCase()] || 'info';

  if (!fs.existsSync(LOG_DIR)) {
    fs.mkdirSync(LOG_DIR, { recursive: true });
  }

  const logger = winston.createLogger({
    level: logLevel,
    format: winston.format.combine(
      winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
      winston.format.printf(({ timestamp, level, message }) => {
        return `${timestamp} | ${level.padEnd(8)} | ${message}`;
      })
    ),
    transports: [
      new winston.transports.Console(),
      new winston.transports.File({
        filename: path.join(LOG_DIR, `${new Date().toISOString().split('T')[0]}.log`),
        maxsize: 10 * 1024 * 1024, // 10 MB
        maxFiles: 7,
        tailable: true,
      }),
    ],
  });

  return logger;
}

const logger = setupLogger();

// ---------------------------------------------------------------------------
// State-Management
// ---------------------------------------------------------------------------

function loadState() {
  const defaultState = {
    processed: {},
    queue: [],
    current_priority: 'high',
    stats: { total_scripts: 0, abstractions_created: 0 },
  };

  if (!fs.existsSync(STATE_FILE)) {
    return defaultState;
  }

  try {
    const data = fs.readFileSync(STATE_FILE, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    logger.error(`State-File konnte nicht geparst werden (${STATE_FILE}): ${error.message}`);
    return defaultState;
  }
}

function saveState(state) {
  const dir = path.dirname(STATE_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  const tmpPath = path.join(dir, `.abstractions_state_${Date.now()}.tmp`);
  try {
    fs.writeFileSync(tmpPath, JSON.stringify(state, null, 2), 'utf8');
    fs.renameSync(tmpPath, STATE_FILE);
    logger.debug(`State atomar gespeichert: ${STATE_FILE}`);
  } catch (error) {
    logger.error(`State konnte nicht gespeichert werden: ${error.message}`);
    try {
      fs.unlinkSync(tmpPath);
    } catch (unlinkError) {
      // Ignore unlink errors
    }
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
    const stdoutLower = result.stdout.toLowerCase();
    return result.status === 0 && (
      stdoutLower.includes('online') || stdoutLower.includes('active')
    );
  } catch (error) {
    if (error.code === 'ETIMEDOUT') {
      logger.warning(`Timeout beim Status-Check von ${nodeId} — verwende always_available`);
    } else if (error.code === 'ENOENT') {
      logger.warning(`'openclaw'-Binary nicht gefunden — verwende always_available für ${nodeId}`);
    } else {
      logger.warning(`OSError beim Status-Check von ${nodeId}: ${error.message} — verwende always_available`);
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
    light:  ['node5', 'node1', 'node2'],
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

  logger.warning(`Kein passender Node gefunden für Gewicht '${jobWeight}' — Fallback node1`);
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

  function walkDir(currentPath) {
    const entries = fs.readdirSync(currentPath, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(currentPath, entry.name);
      if (entry.isDirectory()) {
        if (!excludePatterns.some(pattern => fullPath.includes(pattern))) {
          walkDir(fullPath);
        }
      } else if (['.py', '.js', '.sh', '.pl', '.rb'].includes(path.extname(entry.name))) {
        if (!excludePatterns.some(pattern => fullPath.includes(pattern))) {
          scripts.push(fullPath);
        }
      }
    }
  }

  walkDir(directory);
  return scripts;
}

function buildStubContent(scriptPath, targetLang, sourceLang, template) {
  const today = new Date().toISOString().split('T')[0];

  let originalLines = [];
  try {
    const content = fs.readFileSync(scriptPath, 'utf8');
    originalLines = content.split('\n').slice(0, 15);
  } catch (error) {
    logger.warning(`Originaldatei konnte nicht gelesen werden: ${error.message}`);
  }

  const commentChar = ['go', 'javascript'].includes(targetLang) ? '//' : '#';
  const originalPreview = originalLines.map(line => `${commentChar} ${line}`).join('\n');

  const mainBlock = template.main_block.replace(/{source_lang}/g, sourceLang);

  return [
    template.shebang,
    `${commentChar} ${path.basename(scriptPath, path.extname(scriptPath))} - ${targetLang.charAt(0).toUpperCase() + targetLang.slice(1)} Version`,
    `${commentChar} Portiert von ${sourceLang}`,
    `${commentChar} Original: ${scriptPath}`,
    `${commentChar} Erstellt: ${today}`,
    '',
    template.header,
    `${commentChar} Original-Code-Referenz:`,
    originalPreview,
    '',
    mainBlock
  ].join('\n');
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
  const sourceLang = extMap[path.extname(scriptPath).substring(1)] || path.extname(scriptPath).substring(1).toUpperCase();

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
    const tmpPath = path.join(targetDir, `.stub_${Date.now()}${template.ext}`);
    fs.writeFileSync(tmpPath, content, 'utf8');
    fs.renameSync(tmpPath, targetFile);
    logger.info(`Erstellt: ${targetFile}`);
    return true;
  } catch (error) {
    logger.error(`Stub konnte nicht geschrieben werden (${targetFile}): ${error.message}`);
    try {
      fs.unlinkSync(tmpPath);
    } catch (unlinkError) {
      // Ignore unlink errors
    }
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
    ['skill-creator',   path.join(WORKSPACE, 'skills', 'skill-creator',   'scripts')],
    ['json-utils',      path.join(WORKSPACE, 'skills', 'json-utils',       'scripts')],
    ['scripting-utils', path.join(WORKSPACE, 'skills', 'scripting-utils',  'scripts')],
    ['model-usage',     path.join(WORKSPACE, 'skills', 'model-usage',      'scripts')],
    ['tiktok-live',     path.join(WORKSPACE, 'skills', 'tiktok-live',      'scripts')],
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
    ['db-maintainer',     path.join(WORKSPACE, 'skills', 'db-maintainer',  'scripts')],
    ['log-collector',     path.join(WORKSPACE, 'skills', 'log-collector',   'scripts')],
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
  const repoStr = ABSTRACTIONS_REPO;
  try {
    execSync(`git -C "${repoStr}" add .`, { stdio: 'pipe' });
    execSync(`git -C "${repoStr}" commit -m "${message}"`, { stdio: 'pipe' });
    logger.info(`Git commit erfolgreich: ${message}`);
  } catch (error) {
    if (error.message.includes('ENOENT')) {
      logger.error("'git'-Binary nicht gefunden — Commit übersprungen");
    } else {
      logger.warning(`Git-Befehl fehlgeschlagen: ${error.message}`);
    }
  }
}

// ---------------------------------------------------------------------------
// Status-Report
// ---------------------------------------------------------------------------

function createStatusReport(state) {
  if (!fs.existsSync(ABSTRACTIONS_REPO)) {
    logger.warning(`Abstractions-Repo existiert nicht: ${ABSTRACTIONS_REPO}`);
    return;
  }

  const langCounts = {};
  for (const lang of Object.keys(TARGET_LANGUAGES)) {
    const langDir = path.join(ABSTRACTIONS_REPO, lang);
    if (fs.existsSync(langDir) && fs.statSync(langDir).isDirectory()) {
      const files = fs.readdirSync(langDir).filter(file => fs.statSync(path.join(langDir, file)).isFile());
      langCounts[lang] = files.length;
    }
  }

  const reportFile = path.join(ABSTRACTIONS_REPO, 'STATUS.md');
  try {
    const now = new Date().toISOString().replace('T', ' ').substring(0, 16);
    let content = '# Script Abstractions - Status Report\n\n';
    content += `**Letzte Aktualisierung:** ${now}\n\n`;
    content += `- Aktuelle Priorität: ${state.current_priority || 'high'}\n`;
    content += `- Verarbeitete Scripts: ${Object.keys(state.processed || {}).length}\n`;
    content += `- Abstraktionen gesamt: ${state.stats?.abstractions_created || 0}\n\n`;

    content += '## Abstraktionen pro Sprache\n\n';
    for (const [lang, count] of Object.entries(langCounts).sort()) {
      content += `- ${lang}: ${count}\n`;
    }

    content += '\n## Verfügbare Modelle\n\n';
    for (let i = 0; i < Math.min(AVAILABLE_MODELS.length, 3); i++) {
      content += `- \`${AVAILABLE_MODELS[i]}\`\n`;
    }
    content += `- ... und ${Math.max(0, AVAILABLE_MODELS.length - 3)} weitere\n`;

    content += '\n## Multi-Node Support\n\n';
    content += '| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n';
    content += '|------|---------------|-----------|-----------|-------|\n';
    for (const [nodeId, cfg] of Object.entries(NODES)) {
      const avail = cfg.always_available ? '✅ Immer' : '📱 Bedingt';
      const device = cfg.device || 'Server';
      content += `| ${nodeId} | ${avail} | ${cfg.capacity || 'unknown'} | ${cfg.priority || '-'} | ${device} |\n`;
    }

    content += '\n### Job-Verteilung\n\n';
    content += '- **Heavy Jobs** (>50 KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n';
    content += '- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n';
    content += '- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n';

    fs.writeFileSync(reportFile, content, 'utf8');
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

  const currentPriority = state.current_priority || 'high';
  let created = 0;

  if (currentPriority === 'high') {
    logger.info('Verarbeite HIGH-Priorität: Top 5 Skills');
    created = processPriorityHigh();
    if (created > 0) {
      gitCommit(`High priority: ${created} abstractions`);
    }
    state.current_priority = 'medium';
  } else if (currentPriority === 'medium') {
    logger.info('Verarbeite MEDIUM-Priorität: Workspace Scripts');
    created = processPriorityMedium();
    if (created > 0) {
      gitCommit(`Medium priority: ${created} abstractions`);
    }
    state.current_priority = 'high'; // Zyklus zurücksetzen
  }

  state.stats.last_run = new Date().toISOString();
  
  // Count abstractions
  let totalAbstractions = 0;
  for (const lang of Object.keys(TARGET_LANGUAGES)) {
    const langDir = path.join(ABSTRACTIONS_REPO, lang);
    if (fs.existsSync(langDir) && fs.statSync(langDir).isDirectory()) {
      const files = fs.readdirSync(langDir).filter(file => fs.statSync(path.join(langDir, file)).isFile());
      totalAbstractions += files.length;
    }
  }
  state.stats.abstractions_created = totalAbstractions;

  saveState(state);
  createStatusReport(state);

  logger.info(`Abgeschlossen. ${created} neue Abstraktionen erstellt.`);
}

main();
