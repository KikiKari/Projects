#!/usr/bin/env tclsh8.6
# ABSTRACTIONS_MANAGER.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:ABSTRACTIONS_MANAGER.py
# auch in: OpenClaw@gateway2:skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Compatibility entry point for the canonical Abstractions Manager.

package require fileutil

set CANONICAL_MANAGER "/home/openclaw/.openclaw/workspace/abstraction-manager/ABSTRACTIONS_MANAGER.py"

if {![file isfile $CANONICAL_MANAGER]} {
    puts stderr "Kanonischer Abstraction-Manager fehlt: $CANONICAL_MANAGER"
    exit 1
}

# Execute the Python script using the Python interpreter
if {[catch {exec python3 $CANONICAL_MANAGER} result]} {
    puts stderr $result
    exit 1
} else {
    puts $result
}
