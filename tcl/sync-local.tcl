#!/usr/bin/env tclsh
# sync-local.ps1 — portiert nach tcl
# Quelle: powershell, Onboarding@main:scripts/sync-local.ps1
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# SYNOPSIS
#   Hält den lokalen Dev-Stack (docker-compose.dev.yml) inkrementell mit GitHub synchron.
#
# DESCRIPTION
#   Pollt origin/<Branch> und zieht neue Commits per Fast-Forward. Danach entscheidet
#   der Diff, was nötig ist:
#     - nur Quellcode geändert            -> nichts tun, Hot-Reload übernimmt
#     - package.json / package-lock.json  -> Frontend-Container neu starten
#                                            (Entrypoint installiert Dependencies nur
#                                            bei geändertem Lockfile-Hash nach)
#     - backend/Dockerfile, requirements* -> Backend-Image gezielt neu bauen
#     - docker-compose.dev.yml            -> Dev-Stack neu erzeugen
#   Es wird nie „blind" der ganze Branch neu gebaut.
#
# EXAMPLE
#   tclsh scripts/sync-local.tcl                # Dauerbetrieb, 20-s-Intervall
#   tclsh scripts/sync-local.tcl -once          # genau ein Sync-Durchlauf
#   tclsh scripts/sync-local.tcl -branch main   # anderen Branch verfolgen

package require Tcl 8.6

# Default-Werte
set branch "claude/onboarding-persistent-sandbox-vjfmcx"
set intervalSeconds 20
set composeFile "docker-compose.dev.yml"
set once false

# Kommandozeilenargumente parsen
for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    switch -exact -- $arg {
        -branch {
            incr i
            set branch [lindex $argv $i]
        }
        -intervalseconds {
            incr i
            set intervalSeconds [lindex $argv $i]
        }
        -composefile {
            incr i
            set composeFile [lindex $argv $i]
        }
        -once {
            set once true
        }
        default {
            puts stderr "Unbekanntes Argument: $arg"
            exit 1
        }
    }
}

# Repository-Root bestimmen und dorthin wechseln
set scriptDir [file dirname [info script]]
set repoRoot [file normalize [file join $scriptDir ".."]]
cd $repoRoot

proc log {msg} {
    set timestamp [clock format [clock seconds] -format "%H:%M:%S"]
    puts "\[$timestamp\] $msg"
    flush stdout
}

proc invokeCompose {args} {
    global composeFile
    set cmd [list docker compose -f $composeFile {*}$args]
    if {[catch {exec {*}$cmd} result]} {
        log "WARNUNG: docker compose [join $args " "] fehlgeschlagen: $result"
    }
}

# Sicherstellen, dass der Ziel-Branch ausgecheckt ist.
if {[catch {exec git rev-parse --abbrev-ref HEAD} current]} {
    error "Konnte aktuellen Branch nicht ermitteln: $current"
}
set current [string trim $current]

if {$current ne $branch} {
    log "Wechsle von '$current' auf '$branch' …"
    if {[catch {exec git fetch origin $branch}]} {
        error "Fetch von origin/$branch fehlgeschlagen"
    }
    if {[catch {exec git switch $branch}]} {
        if {[catch {exec git switch -c $branch --track "origin/$branch"}]} {
            error "Branch '$branch' konnte nicht ausgecheckt werden."
        }
    }
}

log "Sync aktiv: origin/$branch -> $repoRoot (Intervall ${intervalSeconds}s, Compose: $composeFile)"

while {true} {
    if {[catch {exec git fetch origin $branch --quiet}]} {
        log "Fetch fehlgeschlagen (Netzwerk?) — nächster Versuch in ${intervalSeconds}s"
    } else {
        if {[catch {exec git rev-parse HEAD} local]} {
            error "Konnte lokalen HEAD nicht ermitteln: $local"
        }
        set local [string trim $local]
        
        if {[catch {exec git rev-parse "origin/$branch"} remote]} {
            error "Konnte Remote HEAD nicht ermitteln: $remote"
        }
        set remote [string trim $remote]

        if {$local ne $remote} {
            if {[catch {exec git merge-base --is-ancestor $local $remote}]} {
                log "ACHTUNG: Lokaler Stand ist von origin/$branch abgewichen (lokale Commits?). Kein automatischer Merge — bitte manuell auflösen."
            } else {
                if {[catch {exec git diff --name-only "$local..$remote"} changed]} {
                    error "Diff fehlgeschlagen: $changed"
                }
                set changedList [split [string trim $changed] "\n"]
                if {[catch {exec git merge --ff-only $remote --quiet}]} {
                    error "Fast-forward Merge fehlgeschlagen"
                }
                log [format "Aktualisiert %s -> %s (%d Datei(en))" [string range $local 0 6] [string range $remote 0 6] [llength $changedList]]

                set frontendDeps [list]
                set backendImage [list]
                set composeChanged [list]

                foreach file $changedList {
                    if {$file in {"package.json" "package-lock.json"}} {
                        lappend frontendDeps $file
                    }
                    if {[regexp {^backend/(Dockerfile|requirements.*\.txt)$} $file]} {
                        lappend backendImage $file
                    }
                    if {$file eq $composeFile} {
                        lappend composeChanged $file
                    }
                }

                if {[llength $composeChanged] > 0} {
                    log "Compose-Datei geändert — erzeuge Dev-Stack neu …"
                    invokeCompose up -d
                }
                if {[llength $backendImage] > 0} {
                    log "Backend-Dependencies/Dockerfile geändert — baue nur das Backend neu …"
                    invokeCompose up -d --build backend
                }
                if {[llength $frontendDeps] > 0} {
                    log "Frontend-Dependencies geändert — starte Frontend neu (npm install läuft im Container) …"
                    invokeCompose restart frontend
                }
                if {![llength $composeChanged] && ![llength $backendImage] && ![llength $frontendDeps]} {
                    log "Nur Quellcode/Assets — Hot-Reload übernimmt, kein Build nötig."
                }
            }
        }
    }

    if {$once} {break}
    after [expr {$intervalSeconds * 1000}]
}
