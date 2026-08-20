#!/usr/bin/env bash
# sync_git_to_clawhub.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:scripts/sync_git_to_clawhub.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Sync die aktiven Skill-Repositories zu ClawHub.

# shellcheck source=/home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.sh
source /home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.sh

# Nur aktive Skill-Repositories synchronisieren.
git_repos=("sub-agents-utils" "multi-nodes-utils")

# Check if in git/
git_path="/home/openclaw/.openclaw/workspace/git"
for repo in "${git_repos[@]}"; do
    if [[ -d "$git_path/$repo" ]]; then
        log "Syncing $repo from Git to ClawHub..."
        sync_to_clawhub "$repo" false
        log "✅ $repo synced to ClawHub"
    fi
done
