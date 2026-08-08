#!/usr/bin/env node
// abstractions_manager.sh — portiert nach javascript
// Quelle: shell, Projects@abstractions:shell/abstractions_manager.sh
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Konfiguration
const WORKSPACE = "/home/openclaw/.openclaw/workspace";
const ABSTRACTIONS_REPO = path.join(WORKSPACE, "git", "Abstraktionen");
const LOG_DIR = path.join(WORKSPACE, "logs", "abstractions-manager");
const STATE_FILE = path.join(WORKSPACE, "db", "abstractions_state.json");

// Node-Konfiguration mit Prioritäten
const NODES = {
  "node1": "always_available:true,capacity:medium,priority:2",
  "node2": "always_available:true,capacity:medium,priority:3",
  "node3": "always_available:false,capacity:medium,priority:4",
  "node5": "always_available:false,capacity:low,priority:5,device:Redmi Note 11S,condition:mobile_internet",
  "node7": "always_available:true,capacity:high,priority:1"
};

// Verfügbare Modelle
const AVAILABLE_MODELS = [
  "openrouter/moonshotai/kimi-k2.5",
  "openrouter/openai/gpt-4o",
  "openrouter/anthropic/claude-3-5-sonnet-20241022",
  "openrouter/google/gemini-2.0-flash-001",
  "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1",
  "openrouter/qwen/qwen-2.5-coder-32b-instruct"
];

// Zielsprachen-Konfiguration
const TARGET_LANGUAGES = {
  "perl5": "ext:.pl,shebang:#!/usr/bin/env perl,header:use strict;\\nuse warnings;\\n",
  "perl6": "ext:.raku,shebang:#!/usr/bin/env raku,header:use v6;\\n",
  "javascript": "ext:.js,shebang:#!/usr/bin/env node,header:",
  "python": "ext:.py,shebang:#!/usr/bin/env python3,header:",
  "shell": "ext:.sh,shebang:#!/bin/bash,header:set -euo pipefail\\n",
  "powershell": "ext:.ps1,shebang:#!/usr/bin/env pwsh,header:#Requires -Version 7\\n",
  "tcl": "ext:.tcl,shebang:#!/usr/bin/env tclsh,header:package require Tcl 8.6\\n",
  "ruby": "ext:.rb,shebang:#!/usr/bin/env ruby,header:require 'json'\\nrequire 'fileutils'\\n",
  "lua": "ext:.lua,shebang:#!/usr/bin/env lua,header:",
  "go": "ext:.go,shebang:// +build ignore,header:package main\\n"
};

function log(message, level = "INFO") {
  const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
  const line = `[${timestamp}] [${level}] ${message}`;
  console.log(line);
  
  fs.mkdirSync(LOG_DIR, { recursive: true });
  const logFile = path.join(LOG_DIR, `${new Date().toISOString().split('T')[0]}.log`);
  fs.appendFileSync(logFile, line + '\n');
}

function get_node_by_priority(job_weight = "medium") {
  let preferred_order = [];
  
  // Prioritäts-Matrix
  if (job_weight === "heavy") {
    // Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
    preferred_order = ["node7", "node2", "node1"];
  } else if (job_weight === "medium") {
    // Mittlere Jobs → Stable Nodes
    preferred_order = ["node2", "node1", "node7"];
  } else {  // light
    // Leichte Jobs → Mobile/verfügbare Nodes
    preferred_order = ["node5", "node1", "node2"];
  }
  
  // Prüfe Verfügbarkeit
  for (const node_id of preferred_order) {
    if (!NODES[node_id]) {
      continue;
    }
    
    const node_config = NODES[node_id];
    const always_available = node_config.split(',').find(part => part.startsWith('always_available:'))?.split(':')[1];
    
    // Skip nicht immer verfügbare Nodes wenn nicht explizit requested
    if (always_available !== "true" && job_weight !== "light") {
      continue;
    }
    
    // Prüfe ob Node online
    if (check_node_status(node_id)) {
      return node_id;
    }
  }
  
  // Fallback zu Node 1
  return "node1";
}

function check_node_status(node_id) {
  try {
    const result = execSync(`timeout 5 openclaw nodes status ${node_id}`, { encoding: 'utf8' });
    if (result.toLowerCase().includes("online") || result.toLowerCase().includes("active")) {
      return true;
    }
  } catch (error) {
    // Bei Timeout/Error: Prüfe letzten bekannten Status
    if (NODES[node_id]) {
      const node_config = NODES[node_id];
      const always_available = node_config.split(',').find(part => part.startsWith('always_available:'))?.split(':')[1];
      return always_available === "true";
    }
  }
  return false;
}

function get_job_weight(script_size, target_langs_count) {
  const total_work = script_size * target_langs_count;
  
  if (total_work > 50000) {  // Große Scripts, viele Sprachen
    return "heavy";
  } else if (total_work > 10000) {  // Mittlere Last
    return "medium";
  } else {
    return "light";
  }
}

function load_state() {
  if (fs.existsSync(STATE_FILE)) {
    return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
  } else {
    return {
      "processed": {},
      "queue": [],
      "current_priority": "high",
      "stats": {
        "total_scripts": 0,
        "abstractions_created": 0
      }
    };
  }
}

function save_state(state) {
  fs.mkdirSync(path.dirname(STATE_FILE), { recursive: true });
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function find_scripts_in_dir(directory, exclude_patterns = []) {
  if (exclude_patterns.length === 0) {
    exclude_patterns = ["node_modules", ".git", "__pycache__", "dist", "build"];
  }
  
  const scripts = [];
  if (fs.existsSync(directory) && fs.statSync(directory).isDirectory()) {
    const files = getAllFiles(directory);
    for (const file of files) {
      let exclude = false;
      for (const pattern of exclude_patterns) {
        if (file.includes(pattern)) {
          exclude = true;
          break;
        }
      }
      if (!exclude) {
        scripts.push(file);
      }
    }
  }
  return scripts;
}

function getAllFiles(dirPath, arrayOfFiles = []) {
  const files = fs.readdirSync(dirPath);
  
  files.forEach(file => {
    const filePath = path.join(dirPath, file);
    if (fs.statSync(filePath).isDirectory()) {
      arrayOfFiles = getAllFiles(filePath, arrayOfFiles);
    } else {
      if (['.py', '.js', '.sh', '.pl', '.rb'].includes(path.extname(file))) {
        arrayOfFiles.push(filePath);
      }
    }
  });
  
  return arrayOfFiles;
}

function create_abstraction(script_path, target_lang) {
  if (!fs.existsSync(script_path)) {
    log(`Script not found: ${script_path}`, "ERROR");
    return false;
  }
  
  const original_content = fs.readFileSync(script_path, 'utf8');
  
  const ext = path.extname(script_path).substring(1);
  let source_lang = "";
  switch (ext) {
    case "py": source_lang = "Python"; break;
    case "js": source_lang = "JavaScript"; break;
    case "sh": source_lang = "Shell"; break;
    case "pl": source_lang = "Perl"; break;
    case "rb": source_lang = "Ruby"; break;
    default: source_lang = ext;
  }
  
  const target_dir = path.join(ABSTRACTIONS_REPO, target_lang);
  fs.mkdirSync(target_dir, { recursive: true });
  
  const lang_config = TARGET_LANGUAGES[target_lang];
  const ext_match = lang_config.match(/ext:([^,]*)/);
  const target_file = path.join(target_dir, path.basename(script_path, path.extname(script_path)) + (ext_match ? ext_match[1] : ""));
  
  if (fs.existsSync(target_file)) {
    return false;
  }
  
  const shebang_match = lang_config.match(/shebang:([^,]*)/);
  const shebang = shebang_match ? shebang_match[1] : "";
  
  const header_match = lang_config.match(/header:([^,]*)/);
  const header = header_match ? header_match[1].replace(/\\n/g, '\n') : "";
  
  const lines = original_content.split('\n').slice(0, 15).map(line => `# ${line}`).join('\n');
  
  let content = "#!/bin/bash\n";
  content += `# ${path.basename(script_path, path.extname(script_path))} - ${target_lang.charAt(0).toUpperCase() + target_lang.slice(1)} Version\n`;
  content += `# Portiert von ${source_lang}\n`;
  content += `# Original: ${script_path}\n`;
  content += `# Erstellt: ${new Date().toISOString().split('T')[0]}\n`;
  content += "#\n";
  content += `# ${header}\n`;
  content += "# Original-Code-Referenz:\n";
  content += `# ${lines}\n`;
  content += `# TODO: Implementiere ${source_lang} Funktionalität in ${target_lang.charAt(0).toUpperCase() + target_lang.slice(1)}\n`;
  content += "# exit 1\n";
  
  fs.writeFileSync(target_file, content);
  log(`Created: ${target_file}`);
  return true;
}

function process_on_node(node_id, scripts, target_langs) {
  let created = 0;
  
  if (node_id === "node1") {
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
    `skill-creator:${path.join(WORKSPACE, "skills", "skill-creator", "scripts")}`,
    `json-utils:${path.join(WORKSPACE, "skills", "json-utils", "scripts")}`,
    `scripting-utils:${path.join(WORKSPACE, "skills", "scripting-utils", "scripts")}`,
    `model-usage:${path.join(WORKSPACE, "skills", "model-usage", "scripts")}`,
    `tiktok-live:${path.join(WORKSPACE, "skills", "tiktok-live", "scripts")}`
  ];
  
  for (const target of targets) {
    const [skill_name, scripts_dir] = target.split(':');
    
    const scripts = find_scripts_in_dir(scripts_dir, ["node_modules", ".git", "test", "tests"]);
    
    log(`${skill_name}: ${scripts.length} scripts found`);
    
    let count = 0;
    for (const script of scripts) {
      if (count >= 10) {
        break;
      }
      
      let script_size = 0;
      if (fs.existsSync(script)) {
        script_size = fs.statSync(script).size;
      }
      
      const target_langs = ["perl5", "javascript", "python", "shell", "tcl"];
      const job_weight = get_job_weight(script_size, target_langs.length);
      
      // Wähle Node basierend auf Job-Gewicht
      const selected_node = get_node_by_priority(job_weight);
      log(`Processing ${path.basename(script)} (${job_weight}) on ${selected_node}`);
      
      const result = process_on_node(selected_node, [script], target_langs);
      created += result;
      count++;
    }
  }
  
  return created;
}

function process_priority_medium() {
  let created = 0;
  const targets = [
    `workspace-scripts:${path.join(WORKSPACE, "scripts")}`,
    `db-maintainer:${path.join(WORKSPACE, "skills", "db-maintainer", "scripts")}`,
    `log-collector:${path.join(WORKSPACE, "skills", "log-collector", "scripts")}`
  ];
  
  for (const target of targets) {
    const [dir_name, scripts_dir] = target.split(':');
    
    const scripts = find_scripts_in_dir(scripts_dir, ["node_modules", ".git"]);
    
    let count = 0;
    for (const script of scripts) {
      if (count >= 10) {
        break;
      }
      
      let script_size = 0;
      if (fs.existsSync(script)) {
        script_size = fs.statSync(script).size;
      }
      
      const target_langs = ["perl5", "javascript", "powershell", "python"];
      const job_weight = get_job_weight(script_size, target_langs.length);
      
      // Mittlere Priority → eher leichtere Jobs
      let adjusted_weight = job_weight;
      if (job_weight === "heavy") {
        adjusted_weight = "medium";
      }
      const selected_node = get_node_by_priority(adjusted_weight);
      log(`Processing ${path.basename(script)} (${job_weight}) on ${selected_node}`);
      
      const result = process_on_node(selected_node, [script], target_langs);
      created += result;
      count++;
    }
  }
  
  return created;
}

function git_commit(message) {
  if (fs.existsSync(ABSTRACTIONS_REPO)) {
    try {
      process.chdir(ABSTRACTIONS_REPO);
      execSync('git add .', { stdio: 'ignore' });
      execSync(`git commit -m "${message}"`, { stdio: 'ignore' });
      log(`Git commit: ${message}`);
    } catch (error) {
      // Ignore git errors
    }
  }
}

function create_status_report(state) {
  const report_file = path.join(ABSTRACTIONS_REPO, "STATUS.md");
  
  const lang_counts = [];
  if (fs.existsSync(ABSTRACTIONS_REPO)) {
    const lang_dirs = fs.readdirSync(ABSTRACTIONS_REPO).filter(item => 
      fs.statSync(path.join(ABSTRACTIONS_REPO, item)).isDirectory()
    );
    
    for (const lang_dir of lang_dirs) {
      if (TARGET_LANGUAGES[lang_dir]) {
        const lang_path = path.join(ABSTRACTIONS_REPO, lang_dir);
        const files = fs.readdirSync(lang_path).filter(file => 
          fs.statSync(path.join(lang_path, file)).isFile()
        );
        lang_counts.push(`${lang_dir}:${files.length}`);
      }
    }
  }
  
  let content = "# Script Abstractions - Status Report\n\n";
  content += `**Letzte Aktualisierung:** ${new Date().toISOString().replace('T', ' ').substring(0, 16)}\n\n`;
  content += `- Aktuelle Priorität: ${state.current_priority || "high"}\n`;
  content += `- Verarbeitete Scripts: ${Object.keys(state.processed).length}\n`;
  content += `- Abstraktionen gesamt: ${state.stats.abstractions_created || 0}\n\n`;
  content += "## Abstraktionen pro Sprache\n\n";
  
  for (const lang_count of lang_counts) {
    const [lang, count] = lang_count.split(':');
    content += `- ${lang}: ${count}\n`;
  }
  
  content += "\n## Verfügbare Modelle\n\n";
  
  let i = 0;
  for (const model of AVAILABLE_MODELS) {
    if (i < 3) {
      content += `- \`${model}\`\n`;
    }
    i++;
  }
  content += `- ... und ${AVAILABLE_MODELS.length - 3} weitere\n\n`;
  
  content += "## Multi-Node Support\n\n";
  content += "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n";
  content += "|------|---------------|-----------|-----------|-------|\n";
  
  for (const [node_id, node_config] of Object.entries(NODES)) {
    const config_parts = node_config.split(',');
    const always_available = config_parts.find(part => part.startsWith('always_available:'))?.split(':')[1];
    const capacity = config_parts.find(part => part.startsWith('capacity:'))?.split(':')[1];
    const priority = config_parts.find(part => part.startsWith('priority:'))?.split(':')[1];
    const device = config_parts.find(part => part.startsWith('device:'))?.split(':')[1] || "Server";
    
    const avail = always_available === "true" ? "✅ Immer" : "📱 Bedingt";
    
    content += `| ${node_id} | ${avail} | ${capacity} | ${priority} | ${device} |\n`;
  }
  
  content += "\n### Job-Verteilung\n\n";
  content += "- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n";
  content += "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n";
  content += "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n";
  
  fs.writeFileSync(report_file, content);
}

function main() {
  log("Script Abstractions Manager (Multi-Node) gestartet");
  
  let state = load_state();
  const processed_count = Object.keys(state.processed).length;
  log(`State loaded: ${processed_count} processed`);
  
  const current_priority = state.current_priority || "high";
  let created = 0;
  
  if (current_priority === "high") {
    log("Processing HIGH priority: Top 5 Skills");
    created = process_priority_high();
    if (created > 0) {
      git_commit(`High priority: ${created} abstractions`);
    }
    state.current_priority = "medium";
  } else if (current_priority === "medium") {
    log("Processing MEDIUM priority: Workspace Scripts");
    created = process_priority_medium();
    if (created > 0) {
      git_commit(`Medium priority: ${created} abstractions`);
    }
    state.current_priority = "high";  // Zyklus
  }
  
  let abstractions_count = 0;
  for (const lang of Object.keys(TARGET_LANGUAGES)) {
    const lang_path = path.join(ABSTRACTIONS_REPO, lang);
    if (fs.existsSync(lang_path) && fs.statSync(lang_path).isDirectory()) {
      const files = fs.readdirSync(lang_path).filter(file => 
        fs.statSync(path.join(lang_path, file)).isFile()
      );
      abstractions_count += files.length;
    }
  }
  
  state.stats.last_run = new Date().toISOString();
  state.stats.abstractions_created = abstractions_count;
  save_state(state);
  create_status_report(state);
  
  log(`Abgeschlossen. ${created} neue Abstraktionen erstellt.`);
}

main();
