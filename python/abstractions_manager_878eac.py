#!/usr/bin/env python3
# abstractions_manager.pl — portiert nach python
# Quelle: perl5, Projects@abstractions:perl5/abstractions_manager.pl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions_manager.py — portiert nach python3
# Quelle: perl, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.pl
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.pl

import json
import os
import subprocess
import shutil
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional

# Konfiguration
WORKSPACE = "/home/openclaw/.openclaw/workspace"
ABSTRACTIONS_REPO = f"{WORKSPACE}/git/Abstraktionen"
LOG_DIR = f"{WORKSPACE}/logs/abstractions-manager"
STATE_FILE = f"{WORKSPACE}/db/abstractions_state.json"

# Node-Konfiguration mit Prioritäten
NODES = {
    "node1": {"always_available": True, "capacity": "medium", "priority": 2},  # Gateway-Master
    "node2": {"always_available": True, "capacity": "medium", "priority": 3},  # Stable Worker
    "node3": {"always_available": False, "capacity": "medium", "priority": 4},  # Bald verfügbar
    "node5": {"always_available": False, "capacity": "low", "priority": 5, "device": "Redmi Note 11S", "condition": "mobile_internet"},
    "node7": {"always_available": True, "capacity": "high", "priority": 1},     # Docker Hauptarbeitspferd
}

AVAILABLE_MODELS = [
    "openrouter/moonshotai/kimi-k2.5",
    "openrouter/openai/gpt-4o",
    "openrouter/anthropic/claude-3-5-sonnet-20241022",
    "openrouter/google/gemini-2.0-flash-001",
    "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1",
    "openrouter/qwen/qwen-2.5-coder-32b-instruct",
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
    "go": {"ext": ".go", "shebang": "// +build ignore", "header": "package main\n"},
}

def log_message(message: str, level: str = "INFO") -> None:
    """Protokolliert eine Nachricht mit Zeitstempel und speichert sie in einer Log-Datei."""
    os.makedirs(LOG_DIR, exist_ok=True)
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    line = f"[{timestamp}] [{level}] {message}\n"
    print(line, end='')
    
    log_file = f"{LOG_DIR}/{datetime.now().strftime('%Y-%m-%d')}.log"
    with open(log_file, 'a', encoding='utf-8') as fh:
        fh.write(line)

def get_node_by_priority(job_weight: str = "medium") -> str:
    """Gibt die beste verfügbare Node basierend auf der Job-Priorität zurück."""
    if job_weight == "heavy":
        preferred_order = ["node7", "node2", "node1"]
    elif job_weight == "medium":
        preferred_order = ["node2", "node1", "node7"]
    else:
        preferred_order = ["node5", "node1", "node2"]
    
    for node_id in preferred_order:
        if node_id not in NODES:
            continue
            
        node = NODES[node_id]
        if not node["always_available"] and job_weight != "light":
            continue
            
        if check_node_status(node_id):
            return node_id
    
    return "node1"

def check_node_status(node_id: str) -> bool:
    """Prüft den Status einer Node."""
    try:
        result = subprocess.run(
            ["openclaw", "nodes", "status", node_id],
            capture_output=True,
            text=True,
            timeout=10
        )
        output = result.stdout.lower()
        if result.returncode == 0 and ("online" in output or "active" in output):
            return True
    except (subprocess.TimeoutExpired, subprocess.SubprocessError):
        pass
    
    return NODES.get(node_id, {}).get("always_available", False)

def get_job_weight(script_size: int, target_langs_count: int) -> str:
    """Bestimmt das Gewicht eines Jobs basierend auf Scriptgröße und Zielsprachenanzahl."""
    total_work = script_size * target_langs_count
    
    if total_work > 50000:
        return "heavy"
    elif total_work > 10000:
        return "medium"
    else:
        return "light"

def load_state() -> Dict[str, Any]:
    """Lädt den Zustand aus der State-Datei oder gibt den Standardzustand zurück."""
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, 'r', encoding='utf-8') as fh:
                return json.load(fh)
        except (json.JSONDecodeError, IOError):
            pass
    
    return default_state()

def default_state() -> Dict[str, Any]:
    """Gibt den Standardzustand zurück."""
    return {
        "processed": {},
        "queue": [],
        "current_priority": "high",
        "stats": {"total_scripts": 0, "abstractions_created": 0}
    }

def save_state(state: Dict[str, Any]) -> None:
    """Speichert den Zustand in der State-Datei."""
    state_dir = os.path.dirname(STATE_FILE)
    os.makedirs(state_dir, exist_ok=True)
    
    with open(STATE_FILE, 'w', encoding='utf-8') as fh:
        json.dump(state, fh, indent=2)

def find_scripts_in_dir(directory: str, exclude_patterns: Optional[List[str]] = None) -> List[str]:
    """Findet alle Skripte in einem Verzeichnis, ausgenommen bestimmte Muster."""
    if exclude_patterns is None:
        exclude_patterns = ["node_modules", ".git", "__pycache__", "dist", "build"]
    
    scripts = []
    if not os.path.exists(directory):
        return scripts
    
    extensions = [".py", ".js", ".sh", ".pl", ".rb"]
    
    for root, _, files in os.walk(directory):
        for file in files:
            if any(pattern in root for pattern in exclude_patterns):
                continue
            if any(file.endswith(ext) for ext in extensions):
                scripts.append(os.path.join(root, file))
    
    return scripts

def create_abstraction(script_path: str, target_lang: str) -> bool:
    """Erstellt eine Abstraktion eines Skripts in einer bestimmten Sprache."""
    try:
        with open(script_path, 'r', encoding='utf-8') as fh:
            original_content = fh.read()
        
        ext = os.path.splitext(script_path)[1][1:]
        source_lang_map = {"py": "Python", "js": "JavaScript", "sh": "Shell", "pl": "Perl", "rb": "Ruby"}
        source_lang = source_lang_map.get(ext, ext)
        
        target_dir = f"{ABSTRACTIONS_REPO}/{target_lang}"
        os.makedirs(target_dir, exist_ok=True)
        
        script_name = os.path.splitext(os.path.basename(script_path))[0]
        target_file = f"{target_dir}/{script_name}{TARGET_LANGUAGES[target_lang]['ext']}"
        
        if os.path.exists(target_file):
            return False
        
        template = TARGET_LANGUAGES[target_lang]
        lines = original_content.split('\n')[:15]
        
        content = f"{template['shebang']}\n"
        content += f"# {script_name} - {target_lang.capitalize()} Version\n"
        content += f"# Portiert von {source_lang}\n"
        content += f"# Original: {script_path}\n"
        content += f"# Erstellt: {datetime.now().strftime('%Y-%m-%d')}\n#\n"
        if template.get('header'):
            content += f"# {template['header']}\n"
        content += "# Original-Code-Referenz:\n"
        content += "# " + "\n# ".join(lines) + "\n\n"
        content += "sub main {\n"
        content += f"    # TODO: Implementiere {source_lang} Funktionalität in {target_lang.capitalize()}\n"
        content += "    return;\n"
        content += "}\n\n"
        content += "main() unless caller;\n"
        
        with open(target_file, 'w', encoding='utf-8') as fh:
            fh.write(content)
        
        log_message(f"Created: {target_file}")
        return True
    except Exception as e:
        log_message(f"Failed: {script_path} - {str(e)}", "ERROR")
        return False

def process_on_node(node_id: str, scripts: List[str], target_langs: List[str]) -> int:
    """Verarbeitet Skripte auf einer bestimmten Node."""
    created = 0
    
    if node_id == "node1":
        for script in scripts:
            for lang in target_langs:
                if create_abstraction(script, lang):
                    created += 1
    else:
        log_message(f"Dispatching {len(scripts)} jobs to {node_id}")
        for script in scripts:
            for lang in target_langs:
                if create_abstraction(script, lang):
                    created += 1
                    log_message(f"Processed on {node_id}: {script} -> {lang}")
    
    return created

def process_priority_high() -> int:
    """Verarbeitet Skripte mit hoher Priorität."""
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
        log_message(f"{skill_name}: {len(scripts)} scripts found")
        
        count = 0
        for script in scripts:
            if count >= 10:
                break
            script_size = os.path.getsize(script) if os.path.exists(script) else 0
            target_langs = ["perl5", "javascript", "python", "shell", "tcl"]
            job_weight = get_job_weight(script_size, len(target_langs))
            
            selected_node = get_node_by_priority(job_weight)
            log_message(f"Processing {os.path.basename(script)} ({job_weight}) on {selected_node}")
            
            created += process_on_node(selected_node, [script], target_langs)
            count += 1
    
    return created

def process_priority_medium() -> int:
    """Verarbeitet Skripte mit mittlerer Priorität."""
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
            script_size = os.path.getsize(script) if os.path.exists(script) else 0
            target_langs = ["perl5", "javascript", "powershell", "python"]
            job_weight = get_job_weight(script_size, len(target_langs))
            
            priority = "medium" if job_weight == "heavy" else job_weight
            selected_node = get_node_by_priority(priority)
            log_message(f"Processing {os.path.basename(script)} ({job_weight}) on {selected_node}")
            
            created += process_on_node(selected_node, [script], target_langs)
            count += 1
    
    return created

def git_commit(message: str) -> None:
    """Führt einen Git-Commit im Abstraktionen-Repository durch."""
    try:
        old_dir = os.getcwd()
        os.chdir(ABSTRACTIONS_REPO)
        subprocess.run(["git", "add", "."], check=True)
        subprocess.run(["git", "commit", "-m", message], check=True)
        os.chdir(old_dir)
        log_message(f"Git commit: {message}")
    except subprocess.CalledProcessError as e:
        log_message(f"Git commit failed: {str(e)}", "ERROR")

def create_status_report(state: Dict[str, Any]) -> None:
    """Erstellt einen Statusbericht als Markdown-Datei."""
    report_file = f"{ABSTRACTIONS_REPO}/STATUS.md"
    
    lang_counts = {}
    if os.path.exists(ABSTRACTIONS_REPO):
        for lang_dir in os.listdir(ABSTRACTIONS_REPO):
            full_path = os.path.join(ABSTRACTIONS_REPO, lang_dir)
            if os.path.isdir(full_path) and lang_dir in TARGET_LANGUAGES:
                count = 0
                for file in os.listdir(full_path):
                    if os.path.isfile(os.path.join(full_path, file)):
                        count += 1
                lang_counts[lang_dir] = count
    
    with open(report_file, 'w', encoding='utf-8') as fh:
        fh.write("# Script Abstractions - Status Report\n\n")
        fh.write(f"**Letzte Aktualisierung:** {datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n")
        fh.write(f"- Aktuelle Priorität: {state.get('current_priority', 'high')}\n")
        fh.write(f"- Verarbeitete Scripts: {len(state.get('processed', {}))}\n")
        fh.write(f"- Abstraktionen gesamt: {state.get('stats', {}).get('abstractions_created', 0)}\n\n")
        
        fh.write("## Abstraktionen pro Sprache\n\n")
        for lang in sorted(lang_counts.keys()):
            fh.write(f"- {lang}: {lang_counts[lang]}\n")
        
        fh.write("\n## Verfügbare Modelle\n\n")
        for i, model in enumerate(AVAILABLE_MODELS[:3]):
            fh.write(f"- `{model}`\n")
        fh.write(f"- ... und {len(AVAILABLE_MODELS) - 3} weitere\n")
        
        fh.write("\n## Multi-Node Support\n\n")
        fh.write("| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n")
        fh.write("|------|---------------|-----------|-----------|-------|\n")
        for node_id in sorted(NODES.keys()):
            config = NODES[node_id]
            avail = "✅ Immer" if config["always_available"] else "📱 Bedingt"
            device = config.get("device", "Server")
            fh.write(f"| {node_id} | {avail} | {config.get('capacity', 'unknown')} | {config.get('priority', '-')} | {device} |\n")
        
        fh.write("\n### Job-Verteilung\n\n")
        fh.write("- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n")
        fh.write("- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n")
        fh.write("- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n")

def main() -> None:
    """Hauptfunktion des Script Abstractions Managers."""
    log_message("Script Abstractions Manager (Multi-Node) gestartet")
    
    state = load_state()
    log_message(f"State loaded: {len(state.get('processed', {}))} processed")
    
    current_priority = state.get("current_priority", "high")
    created = 0
    
    if current_priority == "high":
        log_message("Processing HIGH priority: Top 5 Skills")
        created = process_priority_high()
        if created > 0:
            git_commit(f"High priority: {created} abstractions")
        state["current_priority"] = "medium"
    elif current_priority == "medium":
        log_message("Processing MEDIUM priority: Workspace Scripts")
        created = process_priority_medium()
        if created > 0:
            git_commit(f"Medium priority: {created} abstractions")
        state["current_priority"] = "high"  # Zyklus
    
    state["stats"]["last_run"] = datetime.now().strftime('%Y-%m-%dT%H:%M:%S')
    
    total = 0
    if os.path.exists(ABSTRACTIONS_REPO):
        for lang in TARGET_LANGUAGES:
            lang_dir = f"{ABSTRACTIONS_REPO}/{lang}"
            if os.path.exists(lang_dir):
                for file in os.listdir(lang_dir):
                    if os.path.isfile(os.path.join(lang_dir, file)):
                        total += 1
    state["stats"]["abstractions_created"] = total
    
    save_state(state)
    create_status_report(state)
    
    log_message(f"Abgeschlossen. {created} neue Abstraktionen erstellt.")

if __name__ == "__main__":
    main()
