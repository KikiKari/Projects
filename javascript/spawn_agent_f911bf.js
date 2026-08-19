#!/usr/bin/env node
// spawn_agent.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:skills/sub-agents-utils/scripts/spawn_agent.py
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

/**
 * Sub-Agent spawner - Einfache CLI für sessions_spawn
 */

const fs = require('fs');
const path = require('path');

const WORKSPACE = '/home/openclaw/.openclaw/workspace';

// Füge WORKSPACE zum Modulsuchpfad hinzu
if (!module.paths.includes(WORKSPACE)) {
    module.paths.unshift(WORKSPACE);
}

// Lade openclaw_models Modul
let configuredModels;
let ModelConfigError;

try {
    const openclawModels = require('openclaw_models');
    configuredModels = openclawModels.configured_models || openclawModels.configuredModels;
    ModelConfigError = openclawModels.ModelConfigError;
} catch (error) {
    console.error(`Modellkonfiguration kann nicht geladen werden: ${error.message}`);
    process.exit(1);
}

// Verfügbare Modelle
let MODELS;
try {
    MODELS = configuredModels();
} catch (exc) {
    console.error(`Modellkonfiguration kann nicht geladen werden: ${exc.message}`);
    process.exit(1);
}

class SubAgentSpawner {
    /**
     * Hilft beim Spawnen von Sub-Agents
     */
    
    static getSpawnConfig({
        task,
        label = null,
        model = null,
        thinking = null,
        timeout = null,
        thread = false,
        mode = "run"
    } = {}) {
        /**
         * Erstellt Konfiguration für sessions_spawn
         */
        
        const config = {
            task: task
        };
        
        if (label) {
            config.label = label;
        }
        if (model && MODELS.includes(model)) {
            config.model = model;
        }
        if (thinking) {
            config.thinking = thinking;
        }
        if (timeout) {
            config.runTimeoutSeconds = timeout;
        }
        if (thread) {
            config.thread = true;
            if (mode === "run") {
                config.mode = "session"; // thread requires session mode
            }
        } else {
            config.mode = mode;
        }
        
        return config;
    }
    
    static printSpawnCommand(config) {
        /**
         * Gibt das equivalente Tool-Kommando aus
         */
        console.log("\n🛠️  Tool-Aufruf:");
        console.log("=".repeat(50));
        console.log("sessions_spawn(");
        for (const [key, value] of Object.entries(config)) {
            if (typeof value === 'string') {
                console.log(`    ${key}="${value}"`);
            } else {
                console.log(`    ${key}=${value}`);
            }
        }
        console.log(")");
        console.log("=".repeat(50));
    }
    
    static printSlashCommand(config) {
        /**
         * Gibt das equivalente Slash-Kommando aus
         */
        const task = config.task || "";
        const label = config.label || "agent";
        const model = config.model || "";
        
        let cmd = `/subagents spawn ${label} "${task}"`;
        if (model) {
            cmd += ` --model ${model}`;
        }
        if (config.thinking) {
            cmd += ` --thinking ${config.thinking}`;
        }
        
        console.log("\n💬 Slash Command:");
        console.log("=".repeat(50));
        console.log(cmd);
        console.log("=".repeat(50));
    }
}

function main() {
    const { Command } = require('commander');
    const program = new Command();
    
    program
        .description("Sub-Agent Spawn Helper")
        .option('-t, --task <task>', 'Aufgabenbeschreibung', '')
        .option('-l, --label <label>', 'Optionaler Label')
        .option('-m, --model <model>', 'KI-Modell', MODELS)
        .option('--thinking <level>', 'Thinking Level', ['low', 'medium', 'high'])
        .option('--timeout <seconds>', 'Timeout in Sekunden', 900)
        .option('--thread', 'Thread-Binding aktivieren')
        .option('--mode <mode>', 'Run mode', 'run', ['run', 'session'])
        .option('-o, --output <format>', 'Output format', 'tool', ['tool', 'slash', 'json'])
        .addHelpText('afterAll', `
Beispiele:
  spawn_agent.js -t "Analyze logs" 
  spawn_agent.js -t "Code review" -m openrouter/anthropic/claude-haiku-4.5 --timeout 1800
  spawn_agent.js -t "Batch process" -l "batch-worker" --thread
        `);
    
    program.parse();
    
    const options = program.opts();
    
    if (!options.task) {
        console.error("Fehler: --task ist erforderlich");
        process.exit(1);
    }
    
    const spawner = SubAgentSpawner;
    const config = spawner.getSpawnConfig({
        task: options.task,
        label: options.label,
        model: options.model,
        thinking: options.thinking,
        timeout: parseInt(options.timeout),
        thread: options.thread,
        mode: options.mode
    });
    
    console.log("✅ Sub-Agent Konfiguration:");
    console.log(JSON.stringify(config, null, 2));
    
    if (options.output === "tool") {
        spawner.printSpawnCommand(config);
    } else if (options.output === "slash") {
        spawner.printSlashCommand(config);
    } else if (options.output === "json") {
        console.log("\n📄 JSON:");
        console.log(JSON.stringify(config));
        
        // Speichere als Datei
        const outputDir = "/tmp";
        const fileName = `subagent_${config.label || 'spawn'}.json`;
        const outputPath = path.join(outputDir, fileName);
        
        fs.writeFileSync(outputPath, JSON.stringify(config, null, 2));
        console.log(`💾 Gespeichert: ${outputPath}`);
    }
}

if (require.main === module) {
    main();
}

module.exports = { SubAgentSpawner };
