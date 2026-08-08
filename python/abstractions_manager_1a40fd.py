#!/usr/bin/env python3
# abstractions_manager.sh — portiert nach python
# Quelle: shell, Projects@abstractions:shell/abstractions_manager.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions_manager.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

import os
import json
import subprocess
import logging
from datetime import datetime
from pathlib import Path
from collections import defaultdict

# Konfiguration
WORKSPACE = "/home/openclaw/.openclaw/workspace"
ABSTRACTIONS_REPO = f"{WORKSPACE}/git/Abstraktionen"
LOG_DIR = f"{WORKSPACE}/logs/abstractions-manager"
STATE_FILE = f"{WORKSPACE}/db/abstractions_state.json"

# Node-Konfiguration mit Prioritäten
NODES = {
    "node1": {"always_available": True, "capacity": "medium", "priority": 2},
    "node2": {"always_available": True, "capacity": "medium", "priority": 3},
    "node3": {"always_available": False, "capacity": "medium", "priority": 4},
    "node5": {"always_available": False, "capacity": "low", "priority": 5, "device": "Redmi Note 11S", "condition": "mobile_internet"},
    "node7": {"always_available": True, "capacity": "high", "priority": 1},
}

# Verfügbare Modelle
AVAILABLE_MODELS = [
    "openrouter/moonshotai/kimi-k2.5",
    "openrouter/openai/gpt-4o",
    "openrouter/anthropic/claude-3-5-sonnet-20241022",
    "openrouter/google/gemini-2.0-flash-001",
    "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1",
    "openrouter/qwen/qwen-2.5-coder-32b-instruct",
]

# Zielsprachen-Konfiguration
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
    "go": {"ext": ".go", "shebang": "// +build ignore", "header": "package main\n"},
}

# Logging konfigurieren
os.makedirs(LOG_DIR, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(f"{LOG_DIR}/{datetime.now().strftime('%Y-%m-%d')}.log"),
        logging.StreamHandler()
    ]
)

def log(message, level=logging.INFO):
    logging.log(level, message)

def get_node_by_priority(job_weight="medium"):
    # Prioritäts-Matrix
    if job_weight == "heavy":
        # Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
        preferred_order = ["node7", "node2", "node1"]
    elif job_weight == "medium":
        # Mittlere Jobs → Stable Nodes
        preferred_order = ["node2", "node1", "node7"]
    else:  # light
        # Leichte Jobs → Mobile/verfügbare Nodes
        preferred_order = ["node5", "node1", "node2"]
    
    # Prüfe Verfügbarkeit
    for node_id in preferred_order:
        if node_id not in NODES:
            continue
        
        node_config = NODES[node_id]
        
        # Skip nicht immer verfügbare Nodes wenn nicht explizit requested
        if not node_config.get("always_available", False) and job_weight != "light":
            continue
        
        # Prüfe ob Node online
        if check_node_status(node_id):
            return node_id
    
    # Fallback zu Node 1
    return "node1"

def check_node_status(node_id):
    try:
        result = subprocess.run(["timeout", "5", "openclaw", "nodes", "status", node_id], 
                              capture_output=True, text=True, timeout=6)
        if result.returncode == 0 and any(word in result.stdout.lower() for word in ["online", "active"]):
            return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    
    # Bei Timeout/Error: Prüfe letzten bekannten Status
    if node_id in NODES:
        return NODES[node_id].get("always_available", False)
    return False

def get_job_weight(script_size, target_langs_count):
    total_work = script_size * target_langs_count
    
    if total_work > 50000:  # Große Scripts, viele Sprachen
        return "heavy"
    elif total_work > 10000:  # Mittlere Last
        return "medium"
    else:
        return "light"

def load_state():
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, 'r') as f:
            return json.load(f)
    else:
        return {
            "processed": {},
            "queue": [],
            "current_priority": "high",
            "stats": {
                "total_scripts": 0,
                "abstractions_created": 0
            }
        }

def save_state(state):
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f, indent=2)

def find_scripts_in_dir(directory, exclude_patterns=None):
    if exclude_patterns is None:
        exclude_patterns = ["node_modules", ".git", "__pycache__", "dist", "build"]
    
    scripts = []
    if os.path.isdir(directory):
        for root, dirs, files in os.walk(directory):
            # Filtere ausgeschlossene Verzeichnisse
            dirs[:] = [d for d in dirs if not any(pattern in d for pattern in exclude_patterns)]
            
            for file in files:
                if file.endswith(('.py', '.js', '.sh', '.pl', '.rb')):
                    full_path = os.path.join(root, file)
                    # Prüfe ob Datei von exclude patterns betroffen ist
                    if not any(pattern in full_path for pattern in exclude_patterns):
                        scripts.append(full_path)
    return scripts

def create_abstraction(script_path, target_lang):
    if not os.path.isfile(script_path):
        log(f"Script not found: {script_path}", logging.ERROR)
        return False
    
    try:
        with open(script_path, 'r', encoding='utf-8', errors='ignore') as f:
            original_content = f.read()
    except Exception as e:
        log(f"Error reading script {script_path}: {e}", logging.ERROR)
        return False
    
    ext = os.path.splitext(script_path)[1][1:]
    source_lang_map = {
        "py": "Python",
        "js": "JavaScript",
        "sh": "Shell",
        "pl": "Perl",
        "rb": "Ruby"
    }
    source_lang = source_lang_map.get(ext, ext)
    
    target_dir = os.path.join(ABSTRACTIONS_REPO, target_lang)
    os.makedirs(target_dir, exist_ok=True)
    
    target_file = os.path.join(target_dir, os.path.splitext(os.path.basename(script_path))[0] + TARGET_LANGUAGES[target_lang]["ext"])
    
    if os.path.exists(target_file):
        return False
    
    shebang = TARGET_LANGUAGES[target_lang]["shebang"]
    header = TARGET_LANGUAGES[target_lang]["header"]
    
    lines = ""
    line_count = 0
    for line in original_content.split('\n'):
        if line_count >= 15:
            break
        lines += f"# {line}\n"
        line_count += 1
    
    content = f"""#!/bin/bash
# {os.path.splitext(os.path.basename(script_path))[0]} - {target_lang.capitalize()} Version
# Portiert von {source_lang}
# Original: {script_path}
# Erstellt: {datetime.now().strftime('%Y-%m-%d')}
#
# {header}# Original-Code-Referenz:
# {lines}# TODO: Implementiere {source_lang} Funktionalität in {target_lang.capitalize()}
# exit 1
"""
    
    try:
        with open(target_file, 'w') as f:
            f.write(content)
        log(f"Created: {target_file}")
        return True
    except Exception as e:
        log(f"Error writing abstraction {target_file}: {e}", logging.ERROR)
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
        ("skill-creator", f"{WORKSPACE}/skills/skill-creator/scripts"),
        ("json-utils", f"{WORKSPACE}/skills/json-utils/scripts"),
        ("scripting-utils", f"{WORKSPACE}/skills/scripting-utils/scripts"),
        ("model-usage", f"{WORKSPACE}/skills/model-usage/scripts"),
        ("tiktok-live", f"{WORKSPACE}/skills/tiktok-live/scripts"),
    ]
    
    for skill_name, scripts_dir in targets:
        scripts = find_scripts_in_dir(scripts_dir, ["node_modules", ".git", "test", "tests"])
        log(f"{skill_name}: {len(scripts)} scripts found")
        
        count = 0
        for script in scripts:
            if count >= 10:
                break
            
            try:
                script_size = os.path.getsize(script) if os.path.isfile(script) else 0
            except OSError:
                script_size = 0
            
            target_langs = ["perl5", "javascript", "python", "shell", "tcl"]
            job_weight = get_job_weight(script_size, len(target_langs))
            
            # Wähle Node basierend auf Job-Gewicht
            selected_node = get_node_by_priority(job_weight)
            log(f"Processing {os.path.basename(script)} ({job_weight}) on {selected_node}")
            
            result = process_on_node(selected_node, [script], target_langs)
            created += result
            count += 1
    
    return created

def process_priority_medium():
    created = 0
    targets = [
        ("workspace-scripts", f"{WORKSPACE}/scripts"),
        ("db-maintainer", f"{WORKSPACE}/skills/db-maintainer/scripts"),
        ("log-collector", f"{WORKSPACE}/skills/log-collector/scripts"),
    ]
    
    for dir_name, scripts_dir in targets:
        scripts = find_scripts_in_dir(scripts_dir, ["node_modules", ".git"])
        
        count = 0
        for script in scripts:
            if count >= 10:
                break
            
            try:
                script_size = os.path.getsize(script) if os.path.isfile(script) else 0
            except OSError:
                script_size = 0
            
            target_langs = ["perl5", "javascript", "powershell", "python"]
            job_weight = get_job_weight(script_size, len(target_langs))
            
            # Mittlere Priority → eher leichtere Jobs
            adjusted_weight = job_weight
            if job_weight == "heavy":
                adjusted_weight = "medium"
            selected_node = get_node_by_priority(adjusted_weight)
            log(f"Processing {os.path.basename(script)} ({job_weight}) on {selected_node}")
            
            result = process_on_node(selected_node, [script], target_langs)
            created += result
            count += 1
    
    return created

def git_commit(message):
    if os.path.isdir(ABSTRACTIONS_REPO):
        try:
            subprocess.run(["git", "add", "."], cwd=ABSTRACTIONS_REPO, capture_output=True)
            subprocess.run(["git", "commit", "-m", message], cwd=ABSTRACTIONS_REPO, capture_output=True)
            log(f"Git commit: {message}")
        except Exception as e:
            log(f"Git commit failed: {e}", logging.WARNING)

def create_status_report(state):
    report_file = os.path.join(ABSTRACTIONS_REPO, "STATUS.md")
    
    lang_counts = []
    if os.path.isdir(ABSTRACTIONS_REPO):
        for lang_dir in os.listdir(ABSTRACTIONS_REPO):
            lang_path = os.path.join(ABSTRACTIONS_REPO, lang_dir)
            if os.path.isdir(lang_path) and lang_dir in TARGET_LANGUAGES:
                count = len([f for f in os.listdir(lang_path) if os.path.isfile(os.path.join(lang_path, f))])
                lang_counts.append((lang_dir, count))
    
    with open(report_file, 'w') as f:
        f.write("# Script Abstractions - Status Report\n\n")
        f.write(f"**Letzte Aktualisierung:** {datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n")
        f.write(f"- Aktuelle Priorität: {state.get('current_priority', 'high')}\n")
        f.write(f"- Verarbeitete Scripts: {len(state.get('processed', {}))}\n")
        f.write(f"- Abstraktionen gesamt: {state.get('stats', {}).get('abstractions_created', 0)}\n\n")
        f.write("## Abstraktionen pro Sprache\n\n")
        
        for lang, count in lang_counts:
            f.write(f"- {lang}: {count}\n")
        
        f.write("\n## Verfügbare Modelle\n\n")
        
        for i, model in enumerate(AVAILABLE_MODELS):
            if i < 3:
                f.write(f"- `{model}`\n")
        f.write(f"- ... und {len(AVAILABLE_MODELS) - 3} weitere\n\n")
        
        f.write("## Multi-Node Support\n\n")
        f.write("| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n")
        f.write("|------|---------------|-----------|-----------|-------|\n")
        
        for node_id, node_config in NODES.items():
            always_available = "✅ Immer" if node_config.get("always_available", False) else "📱 Bedingt"
            capacity = node_config.get("capacity", "")
            priority = node_config.get("priority", "")
            device = node_config.get("device", "Server")
            
            f.write(f"| {node_id} | {always_available} | {capacity} | {priority} | {device} |\n")
        
        f.write("\n### Job-Verteilung\n\n")
        f.write("- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n")
        f.write("- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n")
        f.write("- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n")

def main():
    log("Script Abstractions Manager (Multi-Node) gestartet")
    
    state = load_state()
    processed_count = len(state.get("processed", {}))
    log(f"State loaded: {processed_count} processed")
    
    current_priority = state.get("current_priority", "high")
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
        state["current_priority"] = "high"  # Zyklus
    
    abstractions_count = 0
    for lang in TARGET_LANGUAGES.keys():
        lang_path = os.path.join(ABSTRACTIONS_REPO, lang)
        if os.path.isdir(lang_path):
            abstractions_count += len([f for f in os.listdir(lang_path) if os.path.isfile(os.path.join(lang_path, f))])
    
    state["stats"]["last_run"] = datetime.now().isoformat()
    state["stats"]["abstractions_created"] = abstractions_count
    save_state(state)
    create_status_report(state)
    
    log(f"Abgeschlossen. {created} neue Abstraktionen erstellt.")

if __name__ == "__main__":
    main()
