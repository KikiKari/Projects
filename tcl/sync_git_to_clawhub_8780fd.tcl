#!/usr/bin/env tclsh
# sync_git_to_clawhub.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:scripts/sync_git_to_clawhub.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# Sync die 4 Git-Repos zu ClawHub

# Füge das Script-Verzeichnis zum Pfad hinzu
lappend auto_path /home/openclaw/.openclaw/workspace/scripts
package require sync_clawhub_git

# Die 4 Git-Repos die zu ClawHub müssen
set git_repos [list \
    "abstractions-utils" \
    "sub-agents-utils" \
    "multi-nodes-utils" \
    "Abstraktionen" \
]

# Check if in git/
set git_path "/home/openclaw/.openclaw/workspace/git"
foreach repo $git_repos {
    if {[file exists "$git_path/$repo"]} {
        sync_clawhub_git::log "Syncing $repo from Git to ClawHub..."
        # Rename für sync function
        if {$repo eq "Abstraktionen"} {
            continue  ;# Skip - ist kein Skill
        }
        sync_clawhub_git::sync_to_clawhub $repo 0
        sync_clawhub_git::log "✅ $repo synced to ClawHub"
    }
}
