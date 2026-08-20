#!/usr/bin/env tclsh
# sync_git_to_clawhub.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:scripts/sync_git_to_clawhub.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# Sync die aktiven Skill-Repositories zu ClawHub.

# Füge das Script-Verzeichnis zum Pfad hinzu
lappend auto_path /home/openclaw/.openclaw/workspace/scripts

# Lade das sync_clawhub_git Modul
source /home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.tcl

# Nur aktive Skill-Repositories synchronisieren.
set git_repos [list \
    "sub-agents-utils" \
    "multi-nodes-utils" \
]

# Check if in git/
set git_path "/home/openclaw/.openclaw/workspace/git"
foreach repo $git_repos {
    if {[file exists "$git_path/$repo"]} {
        log "Syncing $repo from Git to ClawHub..."
        sync_to_clawhub $repo
        log "✅ $repo synced to ClawHub"
    }
}
