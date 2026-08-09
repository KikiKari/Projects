#!/usr/bin/env tclsh8.6
# ABSTRACTIONS_MANAGER.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Skill-Einstieg fuer den kanonischen Abstractions Manager.

set KANONISCHER_MANAGER "/home/openclaw/.openclaw/workspace/abstractions/ABSTRACTIONS_MANAGER.py"

if {![file isfile $KANONISCHER_MANAGER]} {
    puts stderr "Kanonischer Abstractions Manager fehlt: $KANONISCHER_MANAGER"
    exit 1
}

# Führe das Python-Skript aus
if {[catch {exec python3 $KANONISCHER_MANAGER} result]} {
    puts stderr $result
    exit 1
}
