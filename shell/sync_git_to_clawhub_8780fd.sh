#!/bin/bash
# sync_git_to_clawhub.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:scripts/sync_git_to_clawhub.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Sync die 4 Git-Repos zu ClawHub

# Füge das Script-Verzeichnis zum Pfad hinzu
export PYTHONPATH="/home/openclaw/.openclaw/workspace/scripts:$PYTHONPATH"

# Die 4 Git-Repos die zu ClawHub müssen
git_repos=("abstractions-utils" "sub-agents-utils" "multi-nodes-utils" "Abstraktionen")

# Check if in git/
git_path="/home/openclaw/.openclaw/workspace/git"

for repo in "${git_repos[@]}"; do
    if [ -d "$git_path/$repo" ]; then
        echo "Syncing $repo from Git to ClawHub..."
        
        # Rename für sync function
        if [ "$repo" = "Abstraktionen" ]; then
            continue  # Skip - ist kein Skill
        fi
        
        python3 -c "
import sys
sys.path.append('/home/openclaw/.openclaw/workspace/scripts')
from sync_clawhub_git import sync_to_clawhub
sync_to_clawhub('$repo', dry_run=False)
"
        echo "✅ $repo synced to ClawHub"
    fi
done
