#!/bin/bash
# run_sync_agent.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:scripts/run_sync_agent.py
# Erzeugt: 2026-11-04 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Sandbox-Wrapper für sync_agent.py: mappt hartcodierte Host-Pfade auf /workspace.

# Füge Pfade zum Python-Suchpfad hinzu
export PYTHONPATH="/workspace/scripts:/workspace/skills/clawhub-git-sync-agent/scripts:$PYTHONPATH"

# Setze Umgebungsvariablen für sync_agent
export CLAWHUB_DIR="/workspace/skills"
export GIT_DIR="/workspace/git/skills"
export STATE_FILE="/workspace/db/sync_state.json"

# Führe sync_agent.py aus
python3 -c "
import sys
sys.path.insert(0, '/workspace/scripts')
sys.path.insert(0, '/workspace/skills/clawhub-git-sync-agent/scripts')
import sync_agent
sync_agent.CLAWHUB_DIR = '/workspace/skills'
sync_agent.GIT_DIR = '/workspace/git/skills'
sync_agent.STATE_FILE = '/workspace/db/sync_state.json'
sync_agent.main()
" "$@"
