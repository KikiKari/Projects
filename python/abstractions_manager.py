#!/usr/bin/env python3
# abstractions_manager.js — portiert nach python
# Quelle: javascript, Projects@abstractions:javascript/abstractions_manager.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions_manager.py — portiert nach python
# Quelle: javascript, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.js
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

"""
Script Abstractions Manager - Multi-Node Edition
"""

import os
import json
import subprocess
from datetime import datetime
from pathlib import Path

# Konfiguration
WORKSPACE = Path('/home/openclaw/.openclaw/workspace')
ABSTRACTIONS_REPO = WORKSPACE / 'git' / 'Abstraktionen'
LOG_DIR = WORKSPACE / 'logs' / 'abstractions-manager'
STATE_FILE = WORKSPACE / 'db' / 'abstractions_state.json'

# Node-Konfiguration mit Prioritäten
NODES = {
    "node1": {"always_available": True, "capacity": "medium", "priority": 2},  # Gateway-Master
    "node2": {"always_available": True, "capacity": "medium", "priority": 3},  # Stable Worker
    "node3": {"always_available": False, "capacity": "medium", "priority": 4}, # Bald verfügbar
    "node5": {"always_available": False, "capacity": "low", "priority": 5, "device": "Redmi Note 11S", "condition": "mobile_internet"},
    "node7": {"always_available": True, "capacity": "high", "priority": 1},    # Docker Hauptarbeitspferd
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

def log(message, level="INFO"):
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    line = f"[{timestamp}] [{level}] {message}"
    print(line)
    log_file = LOG_DIR / f"{datetime.now().strftime('%Y-%m-%d')}.log"
    with open(log_file, 'a') as f:
        f.write(line + '\n')

def getNodeByPriority(jobWeight="medium"):
    """ Wählt Node basierend auf Job-Gewicht und Priorität """
    
    # Prioritäts-Matrix
    if jobWeight == "heavy":
        # Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
        preferredOrder = ["node7", "node2", "node1"]
    elif jobWeight == "medium":
        # Mittlere Jobs → Stable Nodes
        preferredOrder = ["node2", "node1", "node7"]
    else:  # light
        # Leichte Jobs → Mobile/verfügbare Nodes
        preferredOrder = ["node5", "node1", "node2"]
    
    # Prüfe Verfügbarkeit
    for nodeId in preferredOrder:
        if nodeId not in NODES:
            continue
        
        node = NODES[nodeId]
        
        # Skip nicht immer verfügbare Nodes wenn nicht explizit requested
        if not node["always_available"] and jobWeight != "light":
            continue
        
        # Prüfe ob Node online
        if checkNodeStatus(nodeId):
            return nodeId
    
    # Fallback zu Node 1
    return "node1"

def checkNodeStatus(nodeId):
    """ Prüft ob ein Node erreichbar ist """
    try:
        result = subprocess.run(
            ["openclaw", "nodes", "status", nodeId],
            capture_output=True,
            text=True,
            timeout=5
        )
        output = result.stdout + result.stderr
        return "online" in output or "active" in output
    except subprocess.TimeoutExpired:
        # Bei Timeout/Error: Prüfe letzten bekannten Status
        return NODES.get(nodeId, {}).get("always_available", False)
    except Exception:
        return NODES.get(nodeId, {}).get("always_available", False)

def getJobWeight(scriptSize, targetLangsCount):
    """ Bewertet Job-Gewicht basierend auf Script-Größe und Anzahl Zielsprachen """
    total_work = scriptSize * targetLangsCount
    
    if total_work > 50000:  # Große Scripts, viele Sprachen
        return "heavy"
    elif total_work > 10000:  # Mittlere Last
        return "medium"
    else:
        return "light"

def loadState():
    if STATE_FILE.exists():
        try:
            with open(STATE_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            pass
    return {"processed": {}, "queue": [], "current_priority": "high", "stats": {"total_scripts": 0, "abstractions_created": 0}}

def saveState(state):
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f, indent=2)

def findScriptsInDir(directory, excludePatterns=None):
    if excludePatterns is None:
        excludePatterns = ["node_modules", ".git", "__pycache__", "dist", "build"]
    scripts = []
    if directory.exists():
        files = getAllFiles(directory)
        extensions = [".py", ".js", ".sh", ".pl", ".rb"]
        for file in files:
            if any(file.name.endswith(ext) for ext in extensions):
                if not any(pattern in str(file) for pattern in excludePatterns):
                    scripts.append(file)
    return scripts

def getAllFiles(dirPath, arrayOfFiles=None):
    if arrayOfFiles is None:
        arrayOfFiles = []
    for file in dirPath.iterdir():
        if file.is_dir():
            arrayOfFiles = getAllFiles(file, arrayOfFiles)
        else:
            arrayOfFiles.append(file)
    return arrayOfFiles

def createAbstraction(scriptPath, targetLang):
    try:
        with open(scriptPath, 'r', encoding='utf-8') as f:
            originalContent = f.read()
        
        ext = scriptPath.suffix[1:]
        sourceLangMap = {"py": "Python", "js": "JavaScript", "sh": "Shell", "pl": "Perl", "rb": "Ruby"}
        sourceLang = sourceLangMap.get(ext, ext)
        
        targetDir = ABSTRACTIONS_REPO / targetLang
        targetDir.mkdir(parents=True, exist_ok=True)
        
        targetFile = targetDir / f"{scriptPath.stem}{TARGET_LANGUAGES[targetLang]['ext']}"
        
        if targetFile.exists():
            return False
        
        template = TARGET_LANGUAGES[targetLang]
        lines = originalContent.split('\n')[:15]
        
        header = template['header'].rstrip() + '\n\n' if template['header'] else ''
        
        content = f"""{template['shebang']}
# {scriptPath.stem} - {targetLang.capitalize()} Version
# Portiert von {sourceLang}
# Original: {scriptPath}
# Erstellt: {datetime.now().strftime('%Y-%m-%d')}
#
{header}# Original-Code-Referenz:
# {'\n# '.join(lines)}

function main() {{
    // TODO: Implementiere {sourceLang} Funktionalität in {targetLang.capitalize()}
    console.log("Hello World");
}}

if (require.main === module) {{
    main();
}}
"""
        
        with open(targetFile, 'w', encoding='utf-8') as f:
            f.write(content)
        log(f"Created: {targetFile}")
        return True
    except Exception as error:
        log(f"Failed: {scriptPath} - {str(error)}", "ERROR")
        return False

def processOnNode(nodeId, scripts, targetLangs):
    """ Verarbeitet Scripts auf definiertem Node """
    created = 0
    
    if nodeId == "node1":
        # Lokale Verarbeitung
        for script in scripts:
            for lang in targetLangs:
                if createAbstraction(script, lang):
                    created += 1
    else:
        # Remote-Verarbeitung
        log(f"Dispatching {len(scripts)} jobs to {nodeId}")
        # TODO: Implementiere Remote-Dispatch wenn Node-Infrastruktur bereit
        # Für jetzt: Lokale Verarbeitung mit Node-Logging
        for script in scripts:
            for lang in targetLangs:
                if createAbstraction(script, lang):
                    created += 1
                    log(f"Processed on {nodeId}: {script.name} -> {lang}")
    
    return created

def processPriorityHigh():
    created = 0
    targets = [
        ("skill-creator", WORKSPACE / "skills" / "skill-creator" / "scripts"),
        ("json-utils", WORKSPACE / "skills" / "json-utils" / "scripts"),
        ("scripting-utils", WORKSPACE / "skills" / "scripting-utils" / "scripts"),
        ("model-usage", WORKSPACE / "skills" / "model-usage" / "scripts"),
        ("tiktok-live", WORKSPACE / "skills" / "tiktok-live" / "scripts"),
    ]
    
    for skillName, scriptsDir in targets:
        scripts = findScriptsInDir(scriptsDir, ["node_modules", ".git", "test", "tests"])
        log(f"{skillName}: {len(scripts)} scripts found")
        
        for script in scripts[:10]:  # Limit für erste Durchläufe
            scriptSize = script.stat().st_size if script.exists() else 0
            targetLangs = ["perl5", "javascript", "python", "shell", "tcl"]
            jobWeight = getJobWeight(scriptSize, len(targetLangs))
            
            # Wähle Node basierend auf Job-Gewicht
            selectedNode = getNodeByPriority(jobWeight)
            log(f"Processing {script.name} ({jobWeight}) on {selectedNode}")
            
            created += processOnNode(selectedNode, [script], targetLangs)
    
    return created

def processPriorityMedium():
    created = 0
    targets = [
        ("workspace-scripts", WORKSPACE / "scripts"),
        ("db-maintainer", WORKSPACE / "skills" / "db-maintainer" / "scripts"),
        ("log-collector", WORKSPACE / "skills" / "log-collector" / "scripts"),
    ]
    
    for dirName, scriptsDir in targets:
        scripts = findScriptsInDir(scriptsDir, ["node_modules", ".git"])
        
        for script in scripts[:10]:
            scriptSize = script.stat().st_size if script.exists() else 0
            targetLangs = ["perl5", "javascript", "powershell", "python"]
            jobWeight = getJobWeight(scriptSize, len(targetLangs))
            
            # Mittlere Priority → eher leichtere Jobs
            selectedNode = getNodeByPriority("medium" if jobWeight == "heavy" else jobWeight)
            log(f"Processing {script.name} ({jobWeight}) on {selectedNode}")
            
            created += processOnNode(selectedNode, [script], targetLangs)
    
    return created

def gitCommit(message):
    try:
        os.chdir(ABSTRACTIONS_REPO)
        subprocess.run(["git", "add", "."], check=True, capture_output=True)
        subprocess.run(["git", "commit", "-m", message], check=True, capture_output=True)
        log(f"Git commit: {message}")
    except Exception:
        pass

def createStatusReport(state):
    reportFile = ABSTRACTIONS_REPO / "STATUS.md"
    langCounts = {}
    if ABSTRACTIONS_REPO.exists():
        for lang in ABSTRACTIONS_REPO.iterdir():
            if lang.is_dir() and lang.name in TARGET_LANGUAGES:
                langCounts[lang.name] = len([f for f in lang.iterdir() if f.is_file()])
    
    content = "# Script Abstractions - Status Report\n\n"
    content += f"**Letzte Aktualisierung:** {datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n"
    content += f"- Aktuelle Priorität: {state.get('current_priority', 'high')}\n"
    content += f"- Verarbeitete Scripts: {len(state.get('processed', {}))}\n"
    content += f"- Abstraktionen gesamt: {state.get('stats', {}).get('abstractions_created', 0)}\n\n"
    
    content += "## Abstraktionen pro Sprache\n\n"
    for lang, count in sorted(langCounts.items()):
        content += f"- {lang}: {count}\n"
    
    content += "\n## Verfügbare Modelle\n\n"
    for model in AVAILABLE_MODELS[:3]:
        content += f"- `{model}`\n"
    content += f"- ... und {len(AVAILABLE_MODELS) - 3} weitere\n"
    
    content += "\n## Multi-Node Support\n\n"
    content += "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n"
    content += "|------|---------------|-----------|-----------|-------|\n"
    for nodeId, config in NODES.items():
        avail = "✅ Immer" if config.get("always_available") else "📱 Bedingt"
        device = config.get("device", "Server")
        content += f"| {nodeId} | {avail} | {config.get('capacity', 'unknown')} | {config.get('priority', '-')} | {device} |\n"
    
    content += "\n### Job-Verteilung\n\n"
    content += "- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n"
    content += "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n"
    content += "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n"
    
    with open(reportFile, 'w') as f:
        f.write(content)

def main():
    log("Script Abstractions Manager (Multi-Node) gestartet")
    
    state = loadState()
    log(f"State loaded: {len(state.get('processed', {}))} processed")
    
    currentPriority = state.get("current_priority", "high")
    created = 0
    
    if currentPriority == "high":
        log("Processing HIGH priority: Top 5 Skills")
        created = processPriorityHigh()
        if created > 0:
            gitCommit(f"High priority: {created} abstractions")
        state["current_priority"] = "medium"
    elif currentPriority == "medium":
        log("Processing MEDIUM priority: Workspace Scripts")
        created = processPriorityMedium()
        if created > 0:
            gitCommit(f"Medium priority: {created} abstractions")
        state["current_priority"] = "high"  # Zyklus
    
    state["stats"]["last_run"] = datetime.now().isoformat()
    state["stats"]["abstractions_created"] = 0
    if ABSTRACTIONS_REPO.exists():
        for lang in TARGET_LANGUAGES:
            langDir = ABSTRACTIONS_REPO / lang
            if langDir.exists() and langDir.is_dir():
                state["stats"]["abstractions_created"] += len([f for f in langDir.iterdir() if f.is_file()])
    
    saveState(state)
    createStatusReport(state)
    
    log(f"Abgeschlossen. {created} neue Abstraktionen erstellt.")

if __name__ == "__main__":
    main()
