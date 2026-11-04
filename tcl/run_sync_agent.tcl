#!/usr/bin/env tclsh8.6
# run_sync_agent.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:scripts/run_sync_agent.py
# Erzeugt: 2026-11-04 durch ABSTRACTIONS_MANAGER.py

# Sandbox-Wrapper für sync_agent.py: mappt hartcodierte Host-Pfade auf /workspace.

# Füge Pfade zum Suchpfad hinzu
lappend auto_path "/workspace/scripts"
lappend auto_path "/workspace/skills/clawhub-git-sync-agent/scripts"

# Lade das sync_agent Modul
package require sync_agent

# Setze die globalen Variablen
set WS "/workspace"
set ::sync_agent::CLAWHUB_DIR [file join $WS "skills"]
set ::sync_agent::GIT_DIR [file join $WS "git" "skills"]
set ::sync_agent::STATE_FILE [file join $WS "db" "sync_state.json"]

# Hauptprogramm aufrufen
sync_agent::main
