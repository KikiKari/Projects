#!/usr/bin/env tclsh8.6
# abstractions-manager.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Setzen der Optionen für strikte Fehlerbehandlung
# set -euo pipefail wird durch Tcl's standard error handling ersetzt

# Ausführen des externen Skripts mit allen Argumenten
exec /home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh {*}$argv
