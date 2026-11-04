#!/usr/bin/env pwsh
# run_sync_agent.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway2:scripts/run_sync_agent.py
# Erzeugt: 2026-11-04 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Sandbox-Wrapper für sync_agent.py: mappt hartcodierte Host-Pfade auf /workspace.
#>

# Füge Pfade zum Python-Suchpfad hinzu
$env:PYTHONPATH = "/workspace/scripts:/workspace/skills/clawhub-git-sync-agent/scripts:$($env:PYTHONPATH)"

# Setze Umgebungsvariablen für das Skript
$env:CLAWHUB_DIR = "/workspace/skills"
$env:GIT_DIR = "/workspace/git/skills"
$env:STATE_FILE = "/workspace/db/sync_state.json"

# Führe das Python-Skript aus
python3 -c @"
import sys
sys.path.insert(0, '/workspace/scripts')
sys.path.insert(0, '/workspace/skills/clawhub-git-sync-agent/scripts')
import sync_agent
sync_agent.CLAWHUB_DIR = '/workspace/skills'
sync_agent.GIT_DIR = '/workspace/git/skills'
sync_agent.STATE_FILE = '/workspace/db/sync_state.json'
if __name__ == '__main__':
    sync_agent.main()
"@
