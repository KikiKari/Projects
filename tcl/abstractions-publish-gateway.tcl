#!/usr/bin/env tclsh
# abstractions-publish-gateway.js — portiert nach tcl
# Quelle: javascript, Projects@abstractions:javascript/abstractions-publish-gateway.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.sh — portiert nach javascript
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.

# Funktion zum Ausführen eines externen Skripts mit Argumenten
proc runScript {scriptPath args} {
    # Erstelle den vollständigen Befehl mit dem Skript und den Argumenten
    set cmd [concat [list exec $scriptPath] $args]
    
    # Führe das Skript aus und leite Ein-/Ausgabe weiter
    if {[catch {eval $cmd} result]} {
        puts stderr "Failed to start script: $result"
        exit 1
    }
    
    # Rückgabewert des Skripts
    return $result
}

# Pfad zum Skript
set scriptPath "/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh"

# Extrahiere die Argumente (ohne den Namen des Skripts selbst)
set argvWithoutScript [lrange $argv 0 end]

# Führe das Skript mit den übergebenen Argumenten aus
set exitCode [runScript $scriptPath {*}$argvWithoutScript]

# Beende das Programm mit dem Rückgabewert des Skripts
exit $exitCode
