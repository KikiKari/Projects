#!/usr/bin/env tclsh8.6
# abstractions-manager-cron.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

# set -eo pipefail
if {[catch {set env(PATH) "/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin"}]} {
    exit 1
}

# set -a
# . /home/openclaw/.openclaw/.env
if {[catch {source /home/openclaw/.openclaw/.env}]} {
    # Wenn die Datei nicht gefunden wird, setzen wir zumindest die Variablen
    if {![info exists env(OPENROUTER_API_KEY)]} {
        puts stderr "OPENROUTER_API_KEY fehlt"
        exit 1
    }
}

# set +a

# : "${OPENROUTER_API_KEY:?OPENROUTER_API_KEY fehlt}"
if {![info exists env(OPENROUTER_API_KEY)] || $env(OPENROUTER_API_KEY) eq ""} {
    puts stderr "OPENROUTER_API_KEY fehlt"
    exit 1
}

# export GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-${GH_ACCESS_TOKEN:-}}}"
if {![info exists env(GITHUB_TOKEN)] || $env(GITHUB_TOKEN) eq ""} {
    if {[info exists env(GH_TOKEN)] && $env(GH_TOKEN) ne ""} {
        set env(GITHUB_TOKEN) $env(GH_TOKEN)
    } elseif {[info exists env(GH_ACCESS_TOKEN)] && $env(GH_ACCESS_TOKEN) ne ""} {
        set env(GITHUB_TOKEN) $env(GH_ACCESS_TOKEN)
    }
}

# exec /usr/bin/flock --nonblock \
#   /home/openclaw/.openclaw/locks/abstractions-manager.lock \
#   /usr/bin/python3 \
#   /home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py \
#   "$@"
set lockfile "/home/openclaw/.openclaw/locks/abstractions-manager.lock"
set python_script "/home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py"

# Prüfen ob flock verfügbar ist
if {[catch {exec which flock}]} {
    puts stderr "flock nicht gefunden"
    exit 1
}

# Versuchen das Lock zu erhalten und das Python-Skript auszuführen
if {[catch {
    # flock mit nonblock Option ausführen
    set cmd [list exec flock --nonblock $lockfile python3 $python_script]
    
    # Argumente hinzufügen
    foreach arg $argv {
        lappend cmd $arg
    }
    
    # Befehl ausführen
    exec {*}$cmd
} result]} {
    # Fehler beim Ausführen behandeln
    if {[string match "*flock*" $result]} {
        # Lock konnte nicht erhalten werden
        exit 1
    } else {
        # Anderer Fehler
        puts stderr $result
        exit 1
    }
}
