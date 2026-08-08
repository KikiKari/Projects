#!/usr/bin/env python3
# abstractions_manager.tcl — portiert nach python
# Quelle: tcl, Projects@abstractions:tcl/abstractions_manager.tcl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions_manager.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Script Abstractions Manager - Multi-Node Edition

import os
import json
import subprocess
import glob
import shutil
import time
from datetime import datetime

# Konfiguration
WORKSPACE = "/home/openclaw/.openclaw/workspace"
ABSTRACTIONS_REPO = os.path.join(WORKSPACE, "git", "Abstraktionen")
LOG_DIR = os.path.join(WORKSPACE, "logs", "abstractions-manager")
STATE_FILE = os.path.join(WORKSPACE, "db", "abstractions_state.json")

# Node-Konfiguration mit Prioritäten
NODES = {
    "node1": {"always_available": True, "capacity": "medium", "priority": 2},
    "node2": {"always_available": True, "capacity": "medium", "priority": 3},
    "node3": {"always_available": False, "capacity": "medium", "priority": 4},
    "node5": {"always_available": False, "capacity": "low", "priority": 5, "device": "Redmi Note 11S", "condition": "mobile_internet"},
    "node7": {"always_available": True, "capacity": "high", "priority": 1}
}

AVAILABLE_MODELS = [
    "openrouter/moonshotai/kimi-k2.5",
    "openrouter/openai/gpt-4o",
    "openrouter/anthropic/claude-3-5-sonnet-20241022",
    "openrouter/google/gemini-2.0-flash-001",
    "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1",
    "openrouter/qwen/qwen-2.5-coder-32b-instruct"
]

TARGET_LANGUAGES = {
    "perl5": {"ext": ".pl", "shebang": "#!/usr/bin/env perl", "header": "use strict;\nuse warnings;\n"},
    "perl6": {"ext": ".raku", "shebang": "#!/usr/bin/env raku", "header": "use v6;\n"},
    "javascript": {"ext": ".js", "shebang": "#!/usr/bin/env node", "header": ""},
    "python": {"ext": ".py", "shebang": "#!/usr/bin/env python3", "header": ""},
    "shell": {"ext": ".sh", "shebang": "#!/bin/bash", "header": "set -euo pipefail\n"},
    "powershell": {"ext": ".ps1", "shebang": "#!/usr/bin/env pwsh", "header": "#Requires -Version 7\n"},
    "tcl": {"ext": ".tcl", "shebang": "#!/usr/bin/env tclsh", "header": "package require Tcl 8.6\n"},
    "ruby": {"ext": ".rb", "shebang": "#!/usr/bin/env ruby", "header": "require 'json'\nrequire 'fileutils'\n"},
    "lua": {"ext": ".lua", "shebang": "#!/usr/bin/env lua", "header": ""},
    "go": {"ext": ".go", "shebang": "// +build ignore", "header": "package main\n"}
}

def log(message, level="INFO"):
    os.makedirs(LOG_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{timestamp}] [{level}] {message}"
    print(line)
    log_file = os.path.join(LOG_DIR, datetime.now().strftime("%Y-%m-%d") + ".log")
    with open(log_file, "a") as f:
        f.write(line + "\n")

def get_node_by_priority(job_weight="medium"):
    # Prioritäts-Matrix
    if job_weight == "heavy":
        # Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
        preferred_order = ["node7", "node2", "node1"]
    elif job_weight == "medium":
        # Mittlere Jobs → Stable Nodes
        preferred_order = ["node2", "node1", "node7"]
    else:
        # light
        # Leichte Jobs → Mobile/verfügbare Nodes
        preferred_order = ["node5", "node1", "node2"]
    
    # Prüfe Verfügbarkeit
    for node_id in preferred_order:
        if node_id not in NODES:
            continue
        
        node = NODES[node_id]
        
        # Skip nicht immer verfügbare Nodes wenn nicht explizit requested
        if not node.get("always_available", False) and job_weight != "light":
            continue
        
        # Prüfe ob Node online
        if check_node_status(node_id):
            return node_id
    
    # Fallback zu Node 1
    return "node1"

def check_node_status(node_id):
    try:
        result = subprocess.check_output(["openclaw", "nodes", "status", node_id], stderr=subprocess.STDOUT, text=True)
        result_lower = result.lower()
        return "online" in result_lower or "active" in result_lower
    except subprocess.CalledProcessError:
        # Bei Timeout/Error: Prüfe letzten bekannten Status
        if node_id in NODES:
            node = NODES[node_id]
            return node.get("always_available", False)
        return False
    except FileNotFoundError:
        # openclaw command not found
        if node_id in NODES:
            node = NODES[node_id]
            return node.get("always_available", False)
        return False

def get_job_weight(script_size, target_langs_count):
    total_work = script_size * target_langs_count
    
    if total_work > 50000:
        # Große Scripts, viele Sprachen
        return "heavy"
    elif total_work > 10000:
        # Mittlere Last
        return "medium"
    else:
        return "light"

def load_state():
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r") as f:
                content = f.read()
                state = json.loads(content)
                return state
        except Exception:
            # ignore error
            pass
    
    return {"processed": {}, "queue": [], "current_priority": "high", "stats": {"total_scripts": 0, "abstractions_created": 0}}

def save_state(state):
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)

def find_scripts_in_dir(directory, exclude_patterns=None):
    if exclude_patterns is None:
        exclude_patterns = ["node_modules", ".git", "__pycache__", "dist", "build"]
    
    scripts = []
    if os.path.exists(directory):
        for ext in ["*.py", "*.js", "*.sh", "*.pl", "*.rb"]:
            for script in glob.glob(os.path.join(directory, ext)):
                exclude = False
                for pattern in exclude_patterns:
                    if pattern in script:
                        exclude = True
                        break
                if not exclude:
                    scripts.append(script)
    return scripts

def create_abstraction(script_path, target_lang):
    if not os.path.exists(script_path):
        return False
    
    with open(script_path, "r") as f:
        original_content = f.read()
    
    ext = os.path.splitext(script_path)[1][1:]
    source_lang_map = {"py": "Python", "js": "JavaScript", "sh": "Shell", "pl": "Perl", "rb": "Ruby"}
    source_lang = source_lang_map.get(ext, ext)
    
    target_dir = os.path.join(ABSTRACTIONS_REPO, target_lang)
    os.makedirs(target_dir, exist_ok=True)
    
    target_file = os.path.join(target_dir, os.path.splitext(os.path.basename(script_path))[0] + TARGET_LANGUAGES[target_lang]["ext"])
    
    if os.path.exists(target_file):
        return False
    
    lines = original_content.split("\n")[:15]
    header_lines = ""
    for line in lines:
        header_lines += f"# {line}\n"
    
    content = f"{TARGET_LANGUAGES[target_lang]['shebang']}\n# {os.path.splitext(os.path.basename(script_path))[0]} - {target_lang.title()} Version\n# Portiert von {source_lang}\n# Original: {script_path}\n# Erstellt: {datetime.now().strftime('%Y-%m-%d')}\n#\n"
    
    if TARGET_LANGUAGES[target_lang]["header"]:
        content += f"# {TARGET_LANGUAGES[target_lang]['header']}\n"
    
    content += f"\n# Original-Code-Referenz:\n# {header_lines}\nproc main {{\n    # TODO: Implementiere {source_lang} Funktionalität in {target_lang.title()}\n    return\n}}\n\nif {{\"[info script]\" eq \"[file normalize $argv0]\"}} {{\n    main\n}}\n"
    
    try:
        with open(target_file, "w") as f:
            f.write(content)
        log(f"Created: {target_file}")
        return True
    except Exception:
        return False

def process_on_node(node_id, scripts, target_langs):
    created = 0
    
    if node_id == "node1":
        # Lokale Verarbeitung
        for script in scripts:
            for lang in target_langs:
                if create_abstraction(script, lang):
                    created += 1
    else:
        # Remote-Verarbeitung
        log(f"Dispatching {len(scripts)} jobs to {node_id}")
        # TODO: Implementiere Remote-Dispatch wenn Node-Infrastruktur bereit
        # Für jetzt: Lokale Verarbeitung mit Node-Logging
        for script in scripts:
            for lang in target_langs:
                if create_abstraction(script, lang):
                    created += 1
                    log(f"Processed on {node_id}: {os.path.basename(script)} -> {lang}")
    
    return created

def process_priority_high():
    created = 0
    targets = [
        ("skill-creator", os.path.join(WORKSPACE, "skills", "skill-creator", "scripts")),
        ("json-utils", os.path.join(WORKSPACE, "skills", "json-utils", "scripts")),
        ("scripting-utils", os.path.join(WORKSPACE, "skills", "scripting-utils", "scripts")),
        ("model-usage", os.path.join(WORKSPACE, "skills", "model-usage", "scripts")),
        ("tiktok-live", os.path.join(WORKSPACE, "skills", "tiktok-live", "scripts"))
    ]
    
    for skill_name, scripts_dir in targets:
        scripts = find_scripts_in_dir(scripts_dir, ["node_modules", ".git", "test", "tests"])
        log(f"{skill_name}: {len(scripts)} scripts found")
        
        count = 0
        for script in scripts:
            if count >= 10:
                break
            if not os.path.exists(script):
                continue
            
            script_size = os.path.getsize(script)
            target_langs = ["perl5", "javascript", "python", "shell", "tcl"]
            job_weight = get_job_weight(script_size, len(target_langs))
            
            # Wähle Node basierend auf Job-Gewicht
            selected_node = get_node_by_priority(job_weight)
            log(f"Processing {os.path.basename(script)} ({job_weight}) on {selected_node}")
            
            created += process_on_node(selected_node, [script], target_langs)
            count += 1
    
    return created

def process_priority_medium():
    created = 0
    targets = [
        ("workspace-scripts", os.path.join(WORKSPACE, "scripts")),
        ("db-maintainer", os.path.join(WORKSPACE, "skills", "db-maintainer", "scripts")),
        ("log-collector", os.path.join(WORKSPACE, "skills", "log-collector", "scripts"))
    ]
    
    for dir_name, scripts_dir in targets:
        scripts = find_scripts_in_dir(scripts_dir, ["node_modules", ".git"])
        
        count = 0
        for script in scripts:
            if count >= 10:
                break
            if not os.path.exists(script):
                continue
            
            script_size = os.path.getsize(script)
            target_langs = ["perl5", "javascript", "powershell", "python"]
            job_weight = get_job_weight(script_size, len(target_langs))
            
            # Mittlere Priority → eher leichtere Jobs
            selected_priority = "medium"
            if job_weight == "heavy":
                selected_priority = "medium"
            else:
                selected_priority = job_weight
            selected_node = get_node_by_priority(selected_priority)
            log(f"Processing {os.path.basename(script)} ({job_weight}) on {selected_node}")
            
            created += process_on_node(selected_node, [script], target_langs)
            count += 1
    
    return created

def git_commit(message):
    try:
        subprocess.run(["git", "add", "."], cwd=ABSTRACTIONS_REPO, check=True)
        subprocess.run(["git", "commit", "-m", message], cwd=ABSTRACTIONS_REPO, check=True)
        log(f"Git commit: {message}")
    except subprocess.CalledProcessError:
        # ignore error
        pass

def create_status_report(state):
    report_file = os.path.join(ABSTRACTIONS_REPO, "STATUS.md")
    lang_counts = {}
    
    if os.path.exists(ABSTRACTIONS_REPO):
        for lang_dir in glob.glob(os.path.join(ABSTRACTIONS_REPO, "*")):
            if os.path.isdir(lang_dir):
                lang_name = os.path.basename(lang_dir)
                if lang_name in TARGET_LANGUAGES:
                    count = len(glob.glob(os.path.join(lang_dir, "*")))
                    lang_counts[lang_name] = count
    
    with open(report_file, "w") as f:
        f.write("# Script Abstractions - Status Report\n\n")
        f.write(f"**Letzte Aktualisierung:** {datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n")
        f.write(f"- Aktuelle Priorität: {state['current_priority']}\n\n")
        f.write(f"- Verarbeitete Scripts: {len(state['processed'])}\n\n")
        f.write(f"- Abstraktionen gesamt: {state['stats']['abstractions_created']}\n\n")
        f.write("## Abstraktionen pro Sprache\n\n")
        
        for lang in sorted(lang_counts.keys()):
            count = lang_counts[lang]
            f.write(f"- {lang}: {count}\n")
        
        f.write("\n## Verfügbare Modelle\n\n")
        count = 0
        for model in AVAILABLE_MODELS:
            if count < 3:
                f.write(f"- `{model}`\n")
            count += 1
        if len(AVAILABLE_MODELS) > 3:
            f.write(f"- ... und {len(AVAILABLE_MODELS) - 3} weitere\n")
        
        f.write("\n## Multi-Node Support\n\n")
        f.write("| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n")
        f.write("|------|---------------|-----------|-----------|-------|\n")
        
        # Sort nodes by priority
        sorted_nodes = sorted([(config["priority"], node_id) for node_id, config in NODES.items()])
        
        for _, node_id in sorted_nodes:
            if node_id in NODES:
                config = NODES[node_id]
                avail = "✅ Immer" if config.get("always_available", False) else "📱 Bedingt"
                device = config.get("device", "Server")
                f.write(f"| {node_id} | {avail} | {config['capacity']} | {config['priority']} | {device} |\n")
        
        f.write("\n### Job-Verteilung\n\n")
        f.write("- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n")
        f.write("- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n")
        f.write("- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n")

def main():
    log("Script Abstractions Manager (Multi-Node) gestartet")
    
    state = load_state()
    log(f"State loaded: {len(state['processed'])} processed")
    
    current_priority = state["current_priority"]
    created = 0
    
    if current_priority == "high":
        log("Processing HIGH priority: Top 5 Skills")
        created = process_priority_high()
        if created > 0:
            git_commit(f"High priority: {created} abstractions")
        state["current_priority"] = "medium"
    elif current_priority == "medium":
        log("Processing MEDIUM priority: Workspace Scripts")
        created = process_priority_medium()
        if created > 0:
            git_commit(f"Medium priority: {created} abstractions")
        state["current_priority"] = "high"
    
    state["stats"]["last_run"] = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    
    # Count abstractions
    total_count = 0
    for lang in TARGET_LANGUAGES.keys():
        lang_dir = os.path.join(ABSTRACTIONS_REPO, lang)
        if os.path.exists(lang_dir):
            total_count += len(glob.glob(os.path.join(lang_dir, "*")))
    state["stats"]["abstractions_created"] = total_count
    
    save_state(state)
    create_status_report(state)
    
    log(f"Abgeschlossen. {created} neue Abstraktionen erstellt.")

if __name__ == "__main__":
    main()
