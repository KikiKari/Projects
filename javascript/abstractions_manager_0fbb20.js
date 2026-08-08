#!/usr/bin/env node
// abstractions_manager.tcl — portiert nach javascript
// Quelle: tcl, Projects@abstractions:tcl/abstractions_manager.tcl
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// abstractions_manager.tcl — portiert nach JavaScript
// Quelle: tcl, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.tcl
// Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.tcl

// Script Abstractions Manager - Multi-Node Edition

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';

// Konfiguration
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const WORKSPACE = path.join(process.env.HOME, '.openclaw', 'workspace');
const ABSTRACTIONS_REPO = path.join(WORKSPACE, 'git', 'Abstraktionen');
const LOG_DIR = path.join(WORKSPACE, 'logs', 'abstractions-manager');
const STATE_FILE = path.join(WORKSPACE, 'db', 'abstractions_state.json');

// Node-Konfiguration mit Prioritäten
const NODES = {
    node1: { always_available: true, capacity: 'medium', priority: 2 },
    node2: { always_available: true, capacity: 'medium', priority: 3 },
    node3: { always_available: false, capacity: 'medium', priority: 4 },
    node5: { always_available: false, capacity: 'low', priority: 5, device: 'Redmi Note 11S', condition: 'mobile_internet' },
    node7: { always_available: true, capacity: 'high', priority: 1 }
};

const AVAILABLE_MODELS = [
    'openrouter/moonshotai/kimi-k2.5',
    'openrouter/openai/gpt-4o',
    'openrouter/anthropic/claude-3-5-sonnet-20241022',
    'openrouter/google/gemini-2.0-flash-001',
    'openrouter/nvidia/llama-3.3-nemotron-super-49b-v1',
    'openrouter/qwen/qwen-2.5-coder-32b-instruct'
];

const TARGET_LANGUAGES = {
    perl5: { ext: '.pl', shebang: '#!/usr/bin/env perl', header: 'use strict;\nuse warnings;\n' },
    perl6: { ext: '.raku', shebang: '#!/usr/bin/env raku', header: 'use v6;\n' },
    javascript: { ext: '.js', shebang: '#!/usr/bin/env node', header: '' },
    python: { ext: '.py', shebang: '#!/usr/bin/env python3', header: '' },
    shell: { ext: '.sh', shebang: '#!/bin/bash', header: 'set -euo pipefail\n' },
    powershell: { ext: '.ps1', shebang: '#!/usr/bin/env pwsh', header: '#Requires -Version 7\n' },
    tcl: { ext: '.tcl', shebang: '#!/usr/bin/env tclsh', header: 'package require Tcl 8.6\n' },
    ruby: { ext: '.rb', shebang: '#!/usr/bin/env ruby', header: "require 'json'\nrequire 'fileutils'\n" },
    lua: { ext: '.lua', shebang: '#!/usr/bin/env lua', header: '' },
    go: { ext: '.go', shebang: '// +build ignore', header: 'package main\n' }
};

function log(message, level = 'INFO') {
    fs.mkdirSync(LOG_DIR, { recursive: true });
    const timestamp = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const line = `[${timestamp}] [${level}] ${message}`;
    console.log(line);
    const log_file = path.join(LOG_DIR, `${new Date().toISOString().slice(0, 10)}.log`);
    fs.appendFileSync(log_file, line + '\n');
}

function get_node_by_priority(job_weight = 'medium') {
    let preferred_order;
    if (job_weight === 'heavy') {
        // Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
        preferred_order = ['node7', 'node2', 'node1'];
    } else if (job_weight === 'medium') {
        // Mittlere Jobs → Stable Nodes
        preferred_order = ['node2', 'node1', 'node7'];
    } else {
        // light
        // Leichte Jobs → Mobile/verfügbare Nodes
        preferred_order = ['node5', 'node1', 'node2'];
    }

    // Prüfe Verfügbarkeit
    for (const node_id of preferred_order) {
        if (!NODES[node_id]) continue;

        const node = NODES[node_id];

        // Skip nicht immer verfügbare Nodes wenn nicht explizit requested
        if (!node.always_available && job_weight !== 'light') continue;

        // Prüfe ob Node online
        if (check_node_status(node_id)) {
            return node_id;
        }
    }

    // Fallback zu Node 1
    return 'node1';
}

function check_node_status(node_id) {
    try {
        const result = execSync(`openclaw nodes status ${node_id}`, { encoding: 'utf-8' });
        return result.toLowerCase().includes('online') || result.toLowerCase().includes('active');
    } catch (error) {
        // Bei Timeout/Error: Prüfe letzten bekannten Status
        if (NODES[node_id] && NODES[node_id].always_available !== undefined) {
            return NODES[node_id].always_available;
        }
        return false;
    }
}

function get_job_weight(script_size, target_langs_count) {
    const total_work = script_size * target_langs_count;

    if (total_work > 50000) {
        // Große Scripts, viele Sprachen
        return 'heavy';
    } else if (total_work > 10000) {
        // Mittlere Last
        return 'medium';
    } else {
        return 'light';
    }
}

function load_state() {
    if (fs.existsSync(STATE_FILE)) {
        try {
            const content = fs.readFileSync(STATE_FILE, 'utf-8');
            const state = JSON.parse(content);
            return state;
        } catch (error) {
            // ignore error
        }
    }

    return {
        processed: {},
        queue: [],
        current_priority: 'high',
        stats: {
            total_scripts: 0,
            abstractions_created: 0
        }
    };
}

function save_state(state) {
    fs.mkdirSync(path.dirname(STATE_FILE), { recursive: true });
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function find_scripts_in_dir(directory, exclude_patterns = []) {
    if (exclude_patterns.length === 0) {
        exclude_patterns = ['node_modules', '.git', '__pycache__', 'dist', 'build'];
    }

    const scripts = [];
    if (fs.existsSync(directory)) {
        const exts = ['*.py', '*.js', '*.sh', '*.pl', '*.rb'];
        for (const ext of exts) {
            try {
                const files = fs.readdirSync(directory)
                    .filter(file => file.endsWith(ext.replace('*', '')))
                    .map(file => path.join(directory, file));
                for (const script of files) {
                    let exclude = false;
                    for (const pattern of exclude_patterns) {
                        if (script.includes(pattern)) {
                            exclude = true;
                            break;
                        }
                    }
                    if (!exclude) {
                        scripts.push(script);
                    }
                }
            } catch (error) {
                // ignore error
            }
        }
    }
    return scripts;
}

function create_abstraction(script_path, target_lang) {
    if (!fs.existsSync(script_path)) {
        return false;
    }

    const original_content = fs.readFileSync(script_path, 'utf-8');
    const ext = path.extname(script_path).substring(1);
    const source_lang_map = { py: 'Python', js: 'JavaScript', sh: 'Shell', pl: 'Perl', rb: 'Ruby' };
    const source_lang = source_lang_map[ext] || ext;

    const target_dir = path.join(ABSTRACTIONS_REPO, target_lang);
    fs.mkdirSync(target_dir, { recursive: true });

    const target_file = path.join(target_dir, path.basename(script_path, path.extname(script_path)) + TARGET_LANGUAGES[target_lang].ext);

    if (fs.existsSync(target_file)) {
        return false;
    }

    const lines = original_content.split('\n').slice(0, 15);
    const header_lines = lines.map(line => `# ${line}`).join('\n');

    let content = `${TARGET_LANGUAGES[target_lang].shebang}\n`;
    content += `# ${path.basename(script_path, path.extname(script_path))} - ${target_lang.charAt(0).toUpperCase() + target_lang.slice(1)} Version\n`;
    content += `# Portiert von ${source_lang}\n`;
    content += `# Original: ${script_path}\n`;
    content += `# Erstellt: ${new Date().toISOString().slice(0, 10)}\n#\n`;

    if (TARGET_LANGUAGES[target_lang].header && TARGET_LANGUAGES[target_lang].header !== '') {
        content += `# ${TARGET_LANGUAGES[target_lang].header}\n`;
    }

    content += '\n# Original-Code-Referenz:\n';
    content += `# ${header_lines}\n`;
    content += 'function main() {\n';
    content += `    // TODO: Implementiere ${source_lang} Funktionalität in ${target_lang.charAt(0).toUpperCase() + target_lang.slice(1)}\n`;
    content += '    return;\n';
    content += '}\n\n';
    content += 'if (import.meta.url === `file://${process.argv[1]}`) {\n';
    content += '    main();\n';
    content += '}\n';

    fs.writeFileSync(target_file, content);
    log(`Created: ${target_file}`);
    return true;
}

function process_on_node(node_id, scripts, target_langs) {
    let created = 0;

    if (node_id === 'node1') {
        // Lokale Verarbeitung
        for (const script of scripts) {
            for (const lang of target_langs) {
                if (create_abstraction(script, lang)) {
                    created++;
                }
            }
        }
    } else {
        // Remote-Verarbeitung
        log(`Dispatching ${scripts.length} jobs to ${node_id}`);
        // TODO: Implementiere Remote-Dispatch wenn Node-Infrastruktur bereit
        // Für jetzt: Lokale Verarbeitung mit Node-Logging
        for (const script of scripts) {
            for (const lang of target_langs) {
                if (create_abstraction(script, lang)) {
                    created++;
                    log(`Processed on ${node_id}: ${path.basename(script)} -> ${lang}`);
                }
            }
        }
    }

    return created;
}

function process_priority_high() {
    let created = 0;
    const targets = [
        ['skill-creator', path.join(WORKSPACE, 'skills', 'skill-creator', 'scripts')],
        ['json-utils', path.join(WORKSPACE, 'skills', 'json-utils', 'scripts')],
        ['scripting-utils', path.join(WORKSPACE, 'skills', 'scripting-utils', 'scripts')],
        ['model-usage', path.join(WORKSPACE, 'skills', 'model-usage', 'scripts')],
        ['tiktok-live', path.join(WORKSPACE, 'skills', 'tiktok-live', 'scripts')]
    ];

    for (const [skill_name, scripts_dir] of targets) {
        const scripts = find_scripts_in_dir(scripts_dir, ['node_modules', '.git', 'test', 'tests']);
        log(`${skill_name}: ${scripts.length} scripts found`);

        let count = 0;
        for (const script of scripts) {
            if (count >= 10) break;
            if (!fs.existsSync(script)) continue;

            const script_size = fs.statSync(script).size;
            const target_langs = ['perl5', 'javascript', 'python', 'shell', 'tcl'];
            const job_weight = get_job_weight(script_size, target_langs.length);

            // Wähle Node basierend auf Job-Gewicht
            const selected_node = get_node_by_priority(job_weight);
            log(`Processing ${path.basename(script)} (${job_weight}) on ${selected_node}`);

            created += process_on_node(selected_node, [script], target_langs);
            count++;
        }
    }

    return created;
}

function process_priority_medium() {
    let created = 0;
    const targets = [
        ['workspace-scripts', path.join(WORKSPACE, 'scripts')],
        ['db-maintainer', path.join(WORKSPACE, 'skills', 'db-maintainer', 'scripts')],
        ['log-collector', path.join(WORKSPACE, 'skills', 'log-collector', 'scripts')]
    ];

    for (const [dir_name, scripts_dir] of targets) {
        const scripts = find_scripts_in_dir(scripts_dir, ['node_modules', '.git']);

        let count = 0;
        for (const script of scripts) {
            if (count >= 10) break;
            if (!fs.existsSync(script)) continue;

            const script_size = fs.statSync(script).size;
            const target_langs = ['perl5', 'javascript', 'powershell', 'python'];
            const job_weight = get_job_weight(script_size, target_langs.length);

            // Mittlere Priority → eher leichtere Jobs
            let selected_priority = 'medium';
            if (job_weight === 'heavy') {
                selected_priority = 'medium';
            } else {
                selected_priority = job_weight;
            }
            const selected_node = get_node_by_priority(selected_priority);
            log(`Processing ${path.basename(script)} (${job_weight}) on ${selected_node}`);

            created += process_on_node(selected_node, [script], target_langs);
            count++;
        }
    }

    return created;
}

function git_commit(message) {
    try {
        process.chdir(ABSTRACTIONS_REPO);
        execSync('git add .');
        execSync(`git commit -m "${message}"`);
        log(`Git commit: ${message}`);
    } catch (error) {
        // ignore error
    }
}

function create_status_report(state) {
    const report_file = path.join(ABSTRACTIONS_REPO, 'STATUS.md');
    const lang_counts = {};

    if (fs.existsSync(ABSTRACTIONS_REPO)) {
        const lang_dirs = fs.readdirSync(ABSTRACTIONS_REPO)
            .filter(item => fs.statSync(path.join(ABSTRACTIONS_REPO, item)).isDirectory());
        for (const lang_name of lang_dirs) {
            if (TARGET_LANGUAGES[lang_name]) {
                const lang_dir = path.join(ABSTRACTIONS_REPO, lang_name);
                const files = fs.readdirSync(lang_dir)
                    .filter(file => fs.statSync(path.join(lang_dir, file)).isFile());
                lang_counts[lang_name] = files.length;
            }
        }
    }

    let content = '# Script Abstractions - Status Report\n\n';
    content += `**Letzte Aktualisierung:** ${new Date().toISOString().slice(0, 16).replace('T', ' ')}\n\n`;
    content += `- Aktuelle Priorität: ${state.current_priority}\n\n`;
    content += `- Verarbeitete Scripts: ${Object.keys(state.processed).length}\n\n`;
    content += `- Abstraktionen gesamt: ${state.stats.abstractions_created}\n\n`;
    content += '## Abstraktionen pro Sprache\n\n';

    const sorted_langs = Object.keys(lang_counts).sort();
    for (const lang of sorted_langs) {
        const count = lang_counts[lang];
        content += `- ${lang}: ${count}\n`;
    }

    content += '\n## Verfügbare Modelle\n\n';
    let count = 0;
    for (const model of AVAILABLE_MODELS) {
        if (count < 3) {
            content += `- \`${model}\`\n`;
        }
        count++;
    }
    if (AVAILABLE_MODELS.length > 3) {
        content += `- ... und ${AVAILABLE_MODELS.length - 3} weitere\n`;
    }

    content += '\n## Multi-Node Support\n\n';
    content += '| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n';
    content += '|------|---------------|-----------|-----------|-------|\n';

    // Sort nodes by priority
    const sorted_nodes = Object.entries(NODES)
        .sort((a, b) => a[1].priority - b[1].priority);

    for (const [node_id, config] of sorted_nodes) {
        const avail = config.always_available ? '✅ Immer' : '📱 Bedingt';
        const device = config.device || 'Server';
        content += `| ${node_id} | ${avail} | ${config.capacity} | ${config.priority} | ${device} |\n`;
    }

    content += '\n### Job-Verteilung\n\n';
    content += '- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n';
    content += '- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n';
    content += '- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n';

    fs.writeFileSync(report_file, content);
}

function main() {
    log('Script Abstractions Manager (Multi-Node) gestartet');

    const state = load_state();
    log(`State loaded: ${Object.keys(state.processed).length} processed`);

    const current_priority = state.current_priority;
    let created = 0;

    if (current_priority === 'high') {
        log('Processing HIGH priority: Top 5 Skills');
        created = process_priority_high();
        if (created > 0) {
            git_commit(`High priority: ${created} abstractions`);
        }
        state.current_priority = 'medium';
    } else if (current_priority === 'medium') {
        log('Processing MEDIUM priority: Workspace Scripts');
        created = process_priority_medium();
        if (created > 0) {
            git_commit(`Medium priority: ${created} abstractions`);
        }
        state.current_priority = 'high';
    }

    state.stats.last_run = new Date().toISOString().slice(0, 19).replace('T', ' ');

    // Count abstractions
    let total_count = 0;
    for (const lang in TARGET_LANGUAGES) {
        const lang_dir = path.join(ABSTRACTIONS_REPO, lang);
        if (fs.existsSync(lang_dir)) {
            const files = fs.readdirSync(lang_dir)
                .filter(file => fs.statSync(path.join(lang_dir, file)).isFile());
            total_count += files.length;
        }
    }
    state.stats.abstractions_created = total_count;

    save_state(state);
    create_status_report(state);

    log(`Abgeschlossen. ${created} neue Abstraktionen erstellt.`);
}

main();
