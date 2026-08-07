#!/usr/bin/env node
// abstractions_manager.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.py
// Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

/**
 * Script Abstractions Manager - Multi-Node Edition
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Konfiguration
const WORKSPACE = path.join('/home/openclaw/.openclaw/workspace');
const ABSTRACTIONS_REPO = path.join(WORKSPACE, 'git', 'Abstraktionen');
const LOG_DIR = path.join(WORKSPACE, 'logs', 'abstractions-manager');
const STATE_FILE = path.join(WORKSPACE, 'db', 'abstractions_state.json');

// Node-Konfiguration mit Prioritäten
const NODES = {
    "node1": {"always_available": true, "capacity": "medium", "priority": 2},  // Gateway-Master
    "node2": {"always_available": true, "capacity": "medium", "priority": 3},  // Stable Worker
    "node3": {"always_available": false, "capacity": "medium", "priority": 4}, // Bald verfügbar
    "node5": {"always_available": false, "capacity": "low", "priority": 5, "device": "Redmi Note 11S", "condition": "mobile_internet"},
    "node7": {"always_available": true, "capacity": "high", "priority": 1},    // Docker Hauptarbeitspferd
};

const AVAILABLE_MODELS = [
    "openrouter/moonshotai/kimi-k2.5",
    "openrouter/openai/gpt-4o",
    "openrouter/anthropic/claude-3-5-sonnet-20241022",
    "openrouter/google/gemini-2.0-flash-001",
    "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1",
    "openrouter/qwen/qwen-2.5-coder-32b-instruct",
];

const TARGET_LANGUAGES = {
    "perl5": {"ext": ".pl", "shebang": "#!/usr/bin/env perl", "header": "use strict;\nuse warnings;\n"},
    "perl6": {"ext": ".raku", "shebang": "#!/usr/bin/env raku", "header": "use v6;\n"},
    "javascript": {"ext": ".js", "shebang": "#!/usr/bin/env node", "header": ""},
    "python": {"ext": ".py", "shebang": "#!/usr/bin/env python3", "header": ""},
    "shell": {"ext": ".sh", "shebang": "#!/bin/bash", "header": "set -euo pipefail\n"},
    "powershell": {"ext": ".ps1", "shebang": "#!/usr/bin/env pwsh", "header": "#Requires -Version 7\n"},
    "tcl": {"ext": ".tcl", "shebang": "#!/usr/bin/env tclsh", "header": "package require Tcl 8.6\n"},
    "ruby": {"ext": ".rb", "shebang": "#!/usr/bin/env ruby", "header": "require 'json'\nrequire 'fileutils'\n"},
    "lua": {"ext": ".lua", "shebang": "#!/usr/bin/env lua", "header": ""},
    "go": {"ext": ".go", "shebang": "// +build ignore", "header": "package main\n"},
};

function log(message, level = "INFO") {
    fs.mkdirSync(LOG_DIR, { recursive: true });
    const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
    const line = `[${timestamp}] [${level}] ${message}`;
    console.log(line);
    const logFile = path.join(LOG_DIR, `${new Date().toISOString().substring(0, 10)}.log`);
    fs.appendFileSync(logFile, line + '\n');
}

function getNodeByPriority(jobWeight = "medium") {
    /** Wählt Node basierend auf Job-Gewicht und Priorität */
    
    // Prioritäts-Matrix
    let preferredOrder;
    if (jobWeight === "heavy") {
        // Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
        preferredOrder = ["node7", "node2", "node1"];
    } else if (jobWeight === "medium") {
        // Mittlere Jobs → Stable Nodes
        preferredOrder = ["node2", "node1", "node7"];
    } else {  // light
        // Leichte Jobs → Mobile/verfügbare Nodes
        preferredOrder = ["node5", "node1", "node2"];
    }
    
    // Prüfe Verfügbarkeit
    for (const nodeId of preferredOrder) {
        if (!NODES[nodeId]) {
            continue;
        }
        
        const node = NODES[nodeId];
        
        // Skip nicht immer verfügbare Nodes wenn nicht explizit requested
        if (!node.always_available && jobWeight !== "light") {
            continue;
        }
        
        // Prüfe ob Node online
        if (checkNodeStatus(nodeId)) {
            return nodeId;
        }
    }
    
    // Fallback zu Node 1
    return "node1";
}

function checkNodeStatus(nodeId) {
    /** Prüft ob ein Node erreichbar ist */
    try {
        const result = execSync(`openclaw nodes status ${nodeId}`, {
            timeout: 5000,
            encoding: 'utf-8'
        });
        return result.includes("online") || result.includes("active");
    } catch (error) {
        // Bei Timeout/Error: Prüfe letzten bekannten Status
        return NODES[nodeId]?.always_available || false;
    }
}

function getJobWeight(scriptSize, targetLangsCount) {
    /** Bewertet Job-Gewicht basierend auf Script-Größe und Anzahl Zielsprachen */
    const totalWork = scriptSize * targetLangsCount;
    
    if (totalWork > 50000) {  // Große Scripts, viele Sprachen
        return "heavy";
    } else if (totalWork > 10000) {  // Mittlere Last
        return "medium";
    } else {
        return "light";
    }
}

function loadState() {
    if (fs.existsSync(STATE_FILE)) {
        try {
            return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
        } catch (error) {
            // ignore error
        }
    }
    return {"processed": {}, "queue": [], "current_priority": "high", "stats": {"total_scripts": 0, "abstractions_created": 0}};
}

function saveState(state) {
    fs.mkdirSync(path.dirname(STATE_FILE), { recursive: true });
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function findScriptsInDir(directory, excludePatterns = null) {
    if (excludePatterns === null) {
        excludePatterns = ["node_modules", ".git", "__pycache__", "dist", "build"];
    }
    const scripts = [];
    if (fs.existsSync(directory)) {
        const files = getAllFiles(directory);
        const extensions = [".py", ".js", ".sh", ".pl", ".rb"];
        for (const file of files) {
            if (extensions.some(ext => file.endsWith(ext))) {
                if (!excludePatterns.some(pattern => file.includes(pattern))) {
                    scripts.push(file);
                }
            }
        }
    }
    return scripts;
}

function getAllFiles(dirPath, arrayOfFiles = []) {
    const files = fs.readdirSync(dirPath);
    for (const file of files) {
        const filePath = path.join(dirPath, file);
        if (fs.statSync(filePath).isDirectory()) {
            arrayOfFiles = getAllFiles(filePath, arrayOfFiles);
        } else {
            arrayOfFiles.push(filePath);
        }
    }
    return arrayOfFiles;
}

function createAbstraction(scriptPath, targetLang) {
    try {
        const originalContent = fs.readFileSync(scriptPath, 'utf8');
        
        const ext = path.extname(scriptPath).substring(1);
        const sourceLangMap = {"py": "Python", "js": "JavaScript", "sh": "Shell", "pl": "Perl", "rb": "Ruby"};
        const sourceLang = sourceLangMap[ext] || ext;
        
        const targetDir = path.join(ABSTRACTIONS_REPO, targetLang);
        fs.mkdirSync(targetDir, { recursive: true });
        
        const targetFile = path.join(targetDir, `${path.basename(scriptPath, path.extname(scriptPath))}${TARGET_LANGUAGES[targetLang].ext}`);
        
        if (fs.existsSync(targetFile)) {
            return false;
        }
        
        const template = TARGET_LANGUAGES[targetLang];
        const lines = originalContent.split('\n').slice(0, 15);
        
        const content = `${template.shebang}
# ${path.basename(scriptPath, path.extname(scriptPath))} - ${targetLang.charAt(0).toUpperCase() + targetLang.slice(1)} Version
# Portiert von ${sourceLang}
# Original: ${scriptPath}
# Erstellt: ${new Date().toISOString().substring(0, 10)}
#
${template.header ? template.header.trim() + '\n\n' : ''}
# Original-Code-Referenz:
# ${lines.join('\n# ')}

function main() {
    // TODO: Implementiere ${sourceLang} Funktionalität in ${targetLang.charAt(0).toUpperCase() + targetLang.slice(1)}
    console.log("Hello World");
}

if (require.main === module) {
    main();
}
`;
        
        fs.writeFileSync(targetFile, content);
        log(`Created: ${targetFile}`);
        return true;
    } catch (error) {
        log(`Failed: ${scriptPath} - ${error.message}`, "ERROR");
        return false;
    }
}

function processOnNode(nodeId, scripts, targetLangs) {
    /** Verarbeitet Scripts auf definiertem Node */
    let created = 0;
    
    if (nodeId === "node1") {
        // Lokale Verarbeitung
        for (const script of scripts) {
            for (const lang of targetLangs) {
                if (createAbstraction(script, lang)) {
                    created++;
                }
            }
        }
    } else {
        // Remote-Verarbeitung
        log(`Dispatching ${scripts.length} jobs to ${nodeId}`);
        // TODO: Implementiere Remote-Dispatch wenn Node-Infrastruktur bereit
        // Für jetzt: Lokale Verarbeitung mit Node-Logging
        for (const script of scripts) {
            for (const lang of targetLangs) {
                if (createAbstraction(script, lang)) {
                    created++;
                    log(`Processed on ${nodeId}: ${path.basename(script)} -> ${lang}`);
                }
            }
        }
    }
    
    return created;
}

function processPriorityHigh() {
    let created = 0;
    const targets = [
        ["skill-creator", path.join(WORKSPACE, "skills", "skill-creator", "scripts")],
        ["json-utils", path.join(WORKSPACE, "skills", "json-utils", "scripts")],
        ["scripting-utils", path.join(WORKSPACE, "skills", "scripting-utils", "scripts")],
        ["model-usage", path.join(WORKSPACE, "skills", "model-usage", "scripts")],
        ["tiktok-live", path.join(WORKSPACE, "skills", "tiktok-live", "scripts")],
    ];
    
    for (const [skillName, scriptsDir] of targets) {
        const scripts = findScriptsInDir(scriptsDir, ["node_modules", ".git", "test", "tests"]);
        log(`${skillName}: ${scripts.length} scripts found`);
        
        for (const script of scripts.slice(0, 10)) {  // Limit für erste Durchläufe
            const scriptSize = fs.existsSync(script) ? fs.statSync(script).size : 0;
            const targetLangs = ["perl5", "javascript", "python", "shell", "tcl"];
            const jobWeight = getJobWeight(scriptSize, targetLangs.length);
            
            // Wähle Node basierend auf Job-Gewicht
            const selectedNode = getNodeByPriority(jobWeight);
            log(`Processing ${path.basename(script)} (${jobWeight}) on ${selectedNode}`);
            
            created += processOnNode(selectedNode, [script], targetLangs);
        }
    }
    
    return created;
}

function processPriorityMedium() {
    let created = 0;
    const targets = [
        ["workspace-scripts", path.join(WORKSPACE, "scripts")],
        ["db-maintainer", path.join(WORKSPACE, "skills", "db-maintainer", "scripts")],
        ["log-collector", path.join(WORKSPACE, "skills", "log-collector", "scripts")],
    ];
    
    for (const [dirName, scriptsDir] of targets) {
        const scripts = findScriptsInDir(scriptsDir, ["node_modules", ".git"]);
        
        for (const script of scripts.slice(0, 10)) {
            const scriptSize = fs.existsSync(script) ? fs.statSync(script).size : 0;
            const targetLangs = ["perl5", "javascript", "powershell", "python"];
            const jobWeight = getJobWeight(scriptSize, targetLangs.length);
            
            // Mittlere Priority → eher leichtere Jobs
            const selectedNode = getNodeByPriority(jobWeight === "heavy" ? "medium" : jobWeight);
            log(`Processing ${path.basename(script)} (${jobWeight}) on ${selectedNode}`);
            
            created += processOnNode(selectedNode, [script], targetLangs);
        }
    }
    
    return created;
}

function gitCommit(message) {
    try {
        process.chdir(ABSTRACTIONS_REPO);
        execSync("git add .", { stdio: 'ignore' });
        execSync(`git commit -m "${message}"`, { stdio: 'ignore' });
        log(`Git commit: ${message}`);
    } catch (error) {
        // ignore error
    }
}

function createStatusReport(state) {
    const reportFile = path.join(ABSTRACTIONS_REPO, "STATUS.md");
    const langCounts = {};
    if (fs.existsSync(ABSTRACTIONS_REPO)) {
        for (const lang of fs.readdirSync(ABSTRACTIONS_REPO)) {
            const langDir = path.join(ABSTRACTIONS_REPO, lang);
            if (fs.statSync(langDir).isDirectory() && TARGET_LANGUAGES[lang]) {
                langCounts[lang] = fs.readdirSync(langDir).filter(f => fs.statSync(path.join(langDir, f)).isFile()).length;
            }
        }
    }
    
    let content = "# Script Abstractions - Status Report\n\n";
    content += `**Letzte Aktualisierung:** ${new Date().toISOString().replace('T', ' ').substring(0, 16)}\n\n`;
    content += `- Aktuelle Priorität: ${state.current_priority || "high"}\n`;
    content += `- Verarbeitete Scripts: ${Object.keys(state.processed).length}\n`;
    content += `- Abstraktionen gesamt: ${state.stats.abstractions_created}\n\n`;
    
    content += "## Abstraktionen pro Sprache\n\n";
    for (const [lang, count] of Object.entries(langCounts).sort()) {
        content += `- ${lang}: ${count}\n`;
    }
    
    content += "\n## Verfügbare Modelle\n\n";
    for (const model of AVAILABLE_MODELS.slice(0, 3)) {
        content += `- \`${model}\`\n`;
    }
    content += `- ... und ${AVAILABLE_MODELS.length - 3} weitere\n`;
    
    content += "\n## Multi-Node Support\n\n";
    content += "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n";
    content += "|------|---------------|-----------|-----------|-------|\n";
    for (const [nodeId, config] of Object.entries(NODES)) {
        const avail = config.always_available ? "✅ Immer" : "📱 Bedingt";
        const device = config.device || "Server";
        content += `| ${nodeId} | ${avail} | ${config.capacity || "unknown"} | ${config.priority || "-"} | ${device} |\n`;
    }
    
    content += "\n### Job-Verteilung\n\n";
    content += "- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n";
    content += "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n";
    content += "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n";
    
    fs.writeFileSync(reportFile, content);
}

function main() {
    log("Script Abstractions Manager (Multi-Node) gestartet");
    
    const state = loadState();
    log(`State loaded: ${Object.keys(state.processed).length} processed`);
    
    const currentPriority = state.current_priority || "high";
    let created = 0;
    
    if (currentPriority === "high") {
        log("Processing HIGH priority: Top 5 Skills");
        created = processPriorityHigh();
        if (created > 0) {
            gitCommit(`High priority: ${created} abstractions`);
        }
        state.current_priority = "medium";
    } else if (currentPriority === "medium") {
        log("Processing MEDIUM priority: Workspace Scripts");
        created = processPriorityMedium();
        if (created > 0) {
            gitCommit(`Medium priority: ${created} abstractions`);
        }
        state.current_priority = "high";  // Zyklus
    }
    
    state.stats.last_run = new Date().toISOString();
    state.stats.abstractions_created = 0;
    if (fs.existsSync(ABSTRACTIONS_REPO)) {
        for (const lang of Object.keys(TARGET_LANGUAGES)) {
            const langDir = path.join(ABSTRACTIONS_REPO, lang);
            if (fs.existsSync(langDir) && fs.statSync(langDir).isDirectory()) {
                state.stats.abstractions_created += fs.readdirSync(langDir).filter(f => fs.statSync(path.join(langDir, f)).isFile()).length;
            }
        }
    }
    
    saveState(state);
    createStatusReport(state);
    
    log(`Abgeschlossen. ${created} neue Abstraktionen erstellt.`);
}

main();
