#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "8bf29ad337f9cabda89c2b12aaa737b25fda047a1fe61c963eed466b38313829", "source_sha256": "76a9327ec4d8b7b9abcabfcbbbf89350cb4a3a4fdc0c949a0b343fe059dc87a8", "target_language": "tcl"}
# abstractions-manager.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6

# Execute the cron script with all arguments passed to this script
exec /home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh {*}$argv
