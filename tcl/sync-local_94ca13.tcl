#!/usr/bin/env tclsh8.6
# sync-local.sh — portiert nach tcl
# Quelle: shell, Onboarding@main:scripts/sync-local.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Tcl-Äquivalent zu sync-local.ps1 — inkrementeller Git-Sync für den Dev-Stack.
# Nutzung: scripts/sync-local.tcl [--branch <name>] [--interval <s>] [--once]

package require Tcl 8.6

set BRANCH "claude/onboarding-persistent-sandbox-vjfmcx"
set INTERVAL 20
set COMPOSE_FILE "docker-compose.dev.yml"
set ONCE 0

# Argumente parsen
for {set i 0} {$i < $argc} {} {
    set arg [lindex $argv $i]
    incr i
    switch -- $arg {
        --branch {
            if {$i >= $argc} {
                puts stderr "Fehler: --branch benötigt einen Wert"
                exit 1
            }
            set BRANCH [lindex $argv $i]
            incr i
        }
        --interval {
            if {$i >= $argc} {
                puts stderr "Fehler: --interval benötigt einen Wert"
                exit 1
            }
            set INTERVAL [lindex $argv $i]
            incr i
        }
        --once {
            set ONCE 1
        }
        default {
            puts stderr "Unbekannte Option: $arg"
            exit 1
        }
    }
}

# Arbeitsverzeichnis wechseln
set script_dir [file dirname [lindex $argv 0]]
if {$script_dir eq ""} {
    set script_dir "."
}
cd [file join $script_dir ".."]

proc log {msg} {
    set time [clock format [clock seconds] -format "%H:%M:%S"]
    puts "\[$time\] $msg"
}

proc compose {args} {
    global COMPOSE_FILE
    if {[catch {exec docker compose -f $COMPOSE_FILE {*}$args} result]} {
        log "WARNUNG: docker compose [join $args " "] fehlgeschlagen"
    } else {
        return $result
    }
}

# Aktuellen Branch ermitteln
set current [exec git rev-parse --abbrev-ref HEAD]
if {$current ne $::BRANCH} {
    log "Wechsle von '$current' auf '$::BRANCH' …"
    exec git fetch origin $::BRANCH
    if {[catch {exec git switch $::BRANCH}]} {
        exec git switch -c $::BRANCH --track "origin/$::BRANCH"
    }
}

log "Sync aktiv: origin/$::BRANCH -> [pwd] (Intervall ${::INTERVAL}s, Compose: $COMPOSE_FILE)"

while {true} {
    if {[catch {exec git fetch origin $::BRANCH --quiet}]} {
        log "Fetch fehlgeschlagen (Netzwerk?) — nächster Versuch in ${::INTERVAL}s"
    } else {
        set local_rev [exec git rev-parse HEAD]
        set remote_rev [exec git rev-parse "origin/$::BRANCH"]
        if {$local_rev ne $remote_rev} {
            if {[catch {exec git merge-base --is-ancestor $local_rev $remote_rev}]} {
                log "ACHTUNG: Lokaler Stand von origin/$::BRANCH abgewichen — kein automatischer Merge, bitte manuell auflösen."
            } else {
                set changed [exec git diff --name-only "$local_rev..$remote_rev"]
                exec git merge --ff-only $remote_rev --quiet
                set local_short [string range $local_rev 0 6]
                set remote_short [string range $remote_rev 0 6]
                set changed_lines [llength [split $changed "\n"]]
                if {$changed_lines > 0 && [string index $changed end] eq ""} {
                    incr changed_lines -1
                }
                log "Aktualisiert $local_short -> $remote_short ($changed_lines Datei(en))"

                set needs_none 1
                foreach file [split $changed "\n"] {
                    if {$file eq $::COMPOSE_FILE} {
                        log "Compose-Datei geändert — erzeuge Dev-Stack neu …"
                        compose up -d
                        set needs_none 0
                    }
                    if {[regexp {^backend/(Dockerfile|requirements.*\.txt)$} $file]} {
                        log "Backend-Dependencies/Dockerfile geändert — baue nur das Backend neu …"
                        compose up -d --build backend
                        set needs_none 0
                    }
                    if {[regexp {^(package\.json|package-lock\.json)$} $file]} {
                        log "Frontend-Dependencies geändert — starte Frontend neu (npm install läuft im Container) …"
                        compose restart frontend
                        set needs_none 0
                    }
                }
                if {$needs_none} {
                    log "Nur Quellcode/Assets — Hot-Reload übernimmt, kein Build nötig."
                }
            }
        }
    }
    if {$::ONCE} break
    after [expr {$::INTERVAL * 1000}]
}
