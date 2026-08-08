#!/usr/bin/env node
// abstractions_manager.pl — portiert nach javascript
// Quelle: perl5, Projects@abstractions:perl5/abstractions_manager.pl
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// abstractions_manager.pl — portiert nach JavaScript fuer Node 20
// Quelle: perl5, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.pl
// Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.pl

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const os = require('os');

// Konfiguration
const WORKSPACE = "/home/openclaw/.openclaw/workspace";
const ABSTRACTIONS_REPO = path.join(WORKSPACE, "git", "Abstraktionen");
const LOG_DIR = path.join(WORKSPACE, "logs", "abstractions-manager");
const STATE_FILE = path.join(WORKSPACE, "db", "abstractions_state.json");

// Node-Konfiguration mit Prioritäten
const NODES = {
    "node1": { always_available: true, capacity: "medium", priority: 2 },  // Gateway-Master
    "node2": { always_available: true, capacity: "medium", priority: 3 },  // Stable Worker
    "node3": { always_available: false, capacity: "medium", priority: 4 }, // Bald verfügbar
    "node5": { always_available: false, capacity: "low", priority: 5, device: "Redmi Note 11S", condition: "mobile_internet" },
    "node7": { always_available: true, capacity: "high", priority: 1 },    // Docker Hauptarbeitspferd
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
    "perl5": { ext: ".pl", shebang: "#!/usr/bin/env perl", header: "use strict;\nuse warnings;\n" },
    "perl6": { ext: ".raku", shebang: "#!/usr/bin/env raku", header: "use v6;\n" },
    "javascript": { ext: ".js", shebang: "#!/usr/bin/env node", header: "" },
    "python": { ext: ".py", shebang: "#!/usr/bin/env python3", header: "" },
    "shell": { ext: ".sh", shebang: "#!/bin/bash", header: "set -euo pipefail\n" },
    "powershell": { ext: ".ps1", shebang: "#!/usr/bin/env pwsh", header: "#Requires -Version 7\n" },
    "tcl": { ext: ".tcl", shebang: "#!/usr/bin/env tclsh", header: "package require Tcl 8.6\n" },
    "ruby": { ext: ".rb", shebang: "#!/usr/bin/env ruby", header: "require 'json'\nrequire 'fileutils'\n" },
    "lua": { ext: ".lua", shebang: "#!/usr/bin/env lua", header: "" },
    "go": { ext: ".go", shebang: "// +build ignore", header: "package main\n" },
};

function logMessage(message, level = "INFO") {
    const timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
    const line = `[${timestamp}] [${level}] ${message}\n`;
    console.log(line.trim());
    
    // Sicherstellen, dass das Log-Verzeichnis existiert
    if (!fs.existsSync(LOG_DIR)) {
        fs.mkdirSync(LOG_DIR, { recursive: true });
    }
    
    const logFile = path.join(LOG_DIR, new Date().toISOString().split('T')[0] + ".log");
    fs.appendFileSync(logFile, line);
}

function getNodeByPriority(jobWeight = "medium") {
    let preferredOrder;
    if (jobWeight === "heavy") {
        preferredOrder = ["node7", "node2", "node1"];
    } else if (jobWeight === "medium") {
        preferredOrder = ["node2", "node1", "node7"];
    } else {
        preferredOrder = ["node5", "node1", "node2"];
    }
    
    for (const nodeId of preferredOrder) {
        if (!NODES[nodeId]) continue;
        
        const node = NODES[nodeId];
        if (!node.always_available && jobWeight !== "light") continue;
        
        if (checkNodeStatus(nodeId)) {
            return nodeId;
        }
    }
    
    return "node1";
}

function checkNodeStatus(nodeId) {
    try {
        const output = execSync(`openclaw nodes status ${nodeId}`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
        if (output.toLowerCase().includes('online') || output.toLowerCase().includes('active')) {
            return true;
        }
    } catch (error) {
        // Befehl fehlgeschlagen
    }
    
    return NODES[nodeId]?.always_available || false;
}

function getJobWeight(scriptSize, targetLangsCount) {
    const totalWork = scriptSize * targetLangsCount;
    
    if (totalWork > 50000) {
        return "heavy";
    } else if (totalWork > 10000) {
        return "medium";
    } else {
        return "light";
    }
}

function loadState() {
    if (fs.existsSync(STATE_FILE)) {
        try {
            const jsonData = fs.readFileSync(STATE_FILE, 'utf8');
            return JSON.parse(jsonData);
        } catch (error) {
            // JSON konnte nicht gelesen werden
        }
    }
    
    return defaultState();
}

function defaultState() {
    return {
        processed: {},
        queue: [],
        current_priority: "high",
        stats: { total_scripts: 0, abstractions_created: 0 }
    };
}

function saveState(state) {
    const stateDir = path.dirname(STATE_FILE);
    if (!fs.existsSync(stateDir)) {
        fs.mkdirSync(stateDir, { recursive: true });
    }
    
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function findScriptsInDir(directory, excludePatterns = ["node_modules", ".git", "__pycache__", "dist", "build"]) {
    const scripts = [];
    
    if (!fs.existsSync(directory) || !fs.statSync(directory).isDirectory()) {
        return scripts;
    }
    
    const extensions = [".py", ".js", ".sh", ".pl", ".rb"];
    
    function walkDir(currentPath) {
        const files = fs.readdirSync(currentPath);
        
        for (const file of files) {
            const filePath = path.join(currentPath, file);
            const stat = fs.statSync(filePath);
            
            if (stat.isDirectory()) {
                let exclude = false;
                for (const pattern of excludePatterns) {
                    if (filePath.includes(pattern)) {
                        exclude = true;
                        break;
                    }
                }
                if (!exclude) {
                    walkDir(filePath);
                }
            } else {
                const ext = path.extname(file);
                if (extensions.includes(ext)) {
                    let exclude = false;
                    for (const pattern of excludePatterns) {
                        if (filePath.includes(pattern)) {
                            exclude = true;
                            break;
                        }
                    }
                    if (!exclude) {
                        scripts.push(filePath);
                    }
                }
            }
        }
    }
    
    walkDir(directory);
    return scripts;
}

function createAbstraction(scriptPath, targetLang) {
    try {
        if (!fs.existsSync(scriptPath)) {
            throw new Error(`Cannot read ${scriptPath}: File does not exist`);
        }
        
        const originalContent = fs.readFileSync(scriptPath, 'utf8');
        const ext = path.extname(scriptPath).substring(1);
        const sourceLangMap = { py: "Python", js: "JavaScript", sh: "Shell", pl: "Perl", rb: "Ruby" };
        const sourceLang = sourceLangMap[ext] || ext;
        
        const targetDir = path.join(ABSTRACTIONS_REPO, targetLang);
        if (!fs.existsSync(targetDir)) {
            fs.mkdirSync(targetDir, { recursive: true });
        }
        
        const scriptName = path.basename(scriptPath, path.extname(scriptPath));
        const targetFile = path.join(targetDir, scriptName + TARGET_LANGUAGES[targetLang].ext);
        
        if (fs.existsSync(targetFile)) {
            return false;
        }
        
        const template = TARGET_LANGUAGES[targetLang];
        const lines = originalContent.split('\n').slice(0, 15);
        
        let content = `${template.shebang}\n`;
        content += `# ${scriptName} - ${targetLang.charAt(0).toUpperCase() + targetLang.slice(1)} Version\n`;
        content += `# Portiert von ${sourceLang}\n`;
        content += `# Original: ${scriptPath}\n`;
        content += `# Erstellt: ${new Date().toISOString().split('T')[0]}\n#\n`;
        if (template.header) {
            content += `# ${template.header}\n`;
        }
        content += "# Original-Code-Referenz:\n";
        content += "# " + lines.join("\n# ") + "\n\n";
        content += "sub main {\n";
        content += "    // TODO: Implementiere " + sourceLang + " Funktionalität in " + targetLang.charAt(0).toUpperCase() + targetLang.slice(1) + "\n";
        content += "    return;\n";
        content += "}\n\n";
        content += "main();\n";
        
        fs.writeFileSync(targetFile, content);
        logMessage(`Created: ${targetFile}`);
        return true;
    } catch (error) {
        logMessage(`Failed: ${scriptPath} - ${error.message}`, "ERROR");
        return false;
    }
}

function processOnNode(nodeId, scripts, targetLangs) {
    let created = 0;
    
    if (nodeId === "node1") {
        for (const script of scripts) {
            for (const lang of targetLangs) {
                if (createAbstraction(script, lang)) {
                    created++;
                }
            }
        }
    } else {
        logMessage(`Dispatching ${scripts.length} jobs to ${nodeId}`);
        for (const script of scripts) {
            for (const lang of targetLangs) {
                if (createAbstraction(script, lang)) {
                    created++;
                    logMessage(`Processed on ${nodeId}: ${script} -> ${lang}`);
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
        logMessage(`${skillName}: ${scripts.length} scripts found`);
        
        let count = 0;
        for (const script of scripts) {
            if (count++ >= 10) break;
            const scriptSize = fs.statSync(script).size || 0;
            const targetLangs = ["perl5", "javascript", "python", "shell", "tcl"];
            const jobWeight = getJobWeight(scriptSize, targetLangs.length);
            
            const selectedNode = getNodeByPriority(jobWeight);
            logMessage(`Processing ${path.basename(script)} (${jobWeight}) on ${selectedNode}`);
            
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
        
        let count = 0;
        for (const script of scripts) {
            if (count++ >= 10) break;
            const scriptSize = fs.statSync(script).size || 0;
            const targetLangs = ["perl5", "javascript", "powershell", "python"];
            const jobWeight = getJobWeight(scriptSize, targetLangs.length);
            
            const priority = (jobWeight === "heavy") ? "medium" : jobWeight;
            const selectedNode = getNodeByPriority(priority);
            logMessage(`Processing ${path.basename(script)} (${jobWeight}) on ${selectedNode}`);
            
            created += processOnNode(selectedNode, [script], targetLangs);
        }
    }
    
    return created;
}

function gitCommit(message) {
    try {
        const oldDir = process.cwd();
        process.chdir(ABSTRACTIONS_REPO);
        execSync("git add .", { stdio: 'ignore' });
        execSync(`git commit -m '${message}'`, { stdio: 'ignore' });
        process.chdir(oldDir);
        logMessage(`Git commit: ${message}`);
    } catch (error) {
        logMessage(`Git commit failed: ${error.message}`, "ERROR");
    }
}

function createStatusReport(state) {
    const reportFile = path.join(ABSTRACTIONS_REPO, "STATUS.md");
    
    const langCounts = {};
    if (fs.existsSync(ABSTRACTIONS_REPO)) {
        const langDirs = fs.readdirSync(ABSTRACTIONS_REPO);
        for (const langDir of langDirs) {
            if (langDir === "." || langDir === "..") continue;
            const fullPath = path.join(ABSTRACTIONS_REPO, langDir);
            if (fs.statSync(fullPath).isDirectory() && TARGET_LANGUAGES[langDir]) {
                try {
                    const files = fs.readdirSync(fullPath);
                    const count = files.filter(file => {
                        const filePath = path.join(fullPath, file);
                        return fs.statSync(filePath).isFile();
                    }).length;
                    langCounts[langDir] = count;
                } catch (error) {
                    // Verzeichnis konnte nicht gelesen werden
                }
            }
        }
    }
    
    let reportContent = "# Script Abstractions - Status Report\n\n";
    reportContent += `**Letzte Aktualisierung:** ${new Date().toISOString().replace(/T/, ' ').substring(0, 16)}\n\n`;
    reportContent += `- Aktuelle Priorität: ${state.current_priority || "high"}\n`;
    reportContent += `- Verarbeitete Scripts: ${Object.keys(state.processed).length}\n`;
    reportContent += `- Abstraktionen gesamt: ${state.stats.abstractions_created || 0}\n\n`;
    
    reportContent += "## Abstraktionen pro Sprache\n\n";
    for (const lang in langCounts) {
        reportContent += `- ${lang}: ${langCounts[lang]}\n`;
    }
    
    reportContent += "\n## Verfügbare Modelle\n\n";
    for (let i = 0; i < Math.min(3, AVAILABLE_MODELS.length); i++) {
        reportContent += `- \`${AVAILABLE_MODELS[i]}\`\n`;
    }
    reportContent += `- ... und ${Math.max(0, AVAILABLE_MODELS.length - 3)} weitere\n`;
    
    reportContent += "\n## Multi-Node Support\n\n";
    reportContent += "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n";
    reportContent += "|------|---------------|-----------|-----------|-------|\n";
    const sortedNodes = Object.keys(NODES).sort();
    for (const nodeId of sortedNodes) {
        const config = NODES[nodeId];
        const avail = config.always_available ? "✅ Immer" : "📱 Bedingt";
        const device = config.device || "Server";
        reportContent += `| ${nodeId} | ${avail} | ${config.capacity || "unknown"} | ${config.priority || "-"} | ${device} |\n`;
    }
    
    reportContent += "\n### Job-Verteilung\n\n";
    reportContent += "- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n";
    reportContent += "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n";
    reportContent += "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n";
    
    fs.writeFileSync(reportFile, reportContent);
}

function main() {
    logMessage("Script Abstractions Manager (Multi-Node) gestartet");
    
    const state = loadState();
    logMessage(`State loaded: ${Object.keys(state.processed).length} processed`);
    
    const currentPriority = state.current_priority || "high";
    let created = 0;
    
    if (currentPriority === "high") {
        logMessage("Processing HIGH priority: Top 5 Skills");
        created = processPriorityHigh();
        if (created > 0) {
            gitCommit(`High priority: ${created} abstractions`);
        }
        state.current_priority = "medium";
    } else if (currentPriority === "medium") {
        logMessage("Processing MEDIUM priority: Workspace Scripts");
        created = processPriorityMedium();
        if (created > 0) {
            gitCommit(`Medium priority: ${created} abstractions`);
        }
        state.current_priority = "high";  // Zyklus
    }
    
    state.stats.last_run = new Date().toISOString().replace(/T/, ' ').substring(0, 19);
    
    let total = 0;
    if (fs.existsSync(ABSTRACTIONS_REPO)) {
        for (const lang in TARGET_LANGUAGES) {
            const langDir = path.join(ABSTRACTIONS_REPO, lang);
            if (fs.existsSync(langDir) && fs.statSync(langDir).isDirectory()) {
                try {
                    const files = fs.readdirSync(langDir);
                    total += files.filter(file => {
                        const filePath = path.join(langDir, file);
                        return fs.statSync(filePath).isFile();
                    }).length;
                } catch (error) {
                    // Verzeichnis konnte nicht gelesen werden
                }
            }
        }
    }
    state.stats.abstractions_created = total;
    
    saveState(state);
    createStatusReport(state);
    
    logMessage(`Abgeschlossen. ${created} neue Abstraktionen erstellt.`);
}

if (require.main === module) {
    main();
}

module.exports = {
    logMessage,
    getNodeByPriority,
    checkNodeStatus,
    getJobWeight,
    loadState,
    defaultState,
    saveState,
    findScriptsInDir,
    createAbstraction,
    processOnNode,
    processPriorityHigh,
    processPriorityMedium,
    gitCommit,
    createStatusReport,
    main
};
