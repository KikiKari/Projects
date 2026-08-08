#!/usr/bin/env tclsh8.6
# abgleich.sh — portiert nach tcl
# Quelle: shell, Projects@abstractions:abstractions/abgleich.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Haelt den Abstraktions-Bestand im Container aktuell.
#
# Alle zwoelf Stunden wird der oeffentliche Branch Projects@abstractions nach
# /home/openclaw/.openclaw/workspace/git/Abstraktionen geholt. Das Repository
# ist oeffentlich, es wird kein Token gebraucht — der Container liest nur.
#
# Erzeugt wird hier nichts: das Portieren laeuft in GitHub Actions, weil dort
# der Schluessel liegt und der Lauf auch dann stattfindet, wenn dieser Rechner
# aus ist. Ein Lauf von Hand ist trotzdem moeglich:
#
#   docker exec -e OPENROUTER_API_KEY=... abstractions-manager \
#       python abstractions/ABSTRACTIONS_MANAGER.py --anzahl 5

package require fileutil
package require cmdline

# Hilfsfunktion fuer Datum/Uhrzeit
proc zeitstempel {} {
    return [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S" -gmt true]
}

# Logging-Funktion
proc melde {args} {
    puts "[zeitstempel] | abgleich | [join $args]"
}

# Hauptabgleich-Funktion
proc abgleichen {ziel herkunft branch} {
    # Pruefe ob .git Verzeichnis existiert
    if {![file exists "$ziel/.git"]} {
        melde "Erstabgleich nach $ziel"
        file mkdir $ziel
        if {[catch {exec git init -q $ziel} result]} {
            melde "Fehler bei git init: $result"
            return
        }
        if {[catch {exec git -C $ziel remote add herkunft $herkunft} result]} {
            melde "Fehler beim Einrichten des Remotes: $result"
            return
        }
    }
    
    # Fetch versuchen
    if {[catch {exec git -C $ziel fetch -q --depth 1 herkunft $branch 2>@1} result]} {
        melde "Abgleich fehlgeschlagen — vorheriger Stand bleibt bestehen"
        return
    }
    
    # Checkout des Branches
    if {[catch {exec git -C $ziel checkout -q -f -B $branch FETCH_HEAD} result]} {
        melde "Fehler beim Checkout: $result"
        return
    }
    
    # Hole Commit-Hash
    if {[catch {exec git -C $ziel rev-parse --short HEAD} stand]} {
        set stand "unbekannt"
    }
    
    # Zaehle Dateien
    set anzahl 0
    if {[catch {
        set files [glob -nocomplain -directory $ziel -types f *.js *.pl *.ps1 *.py *.sh *.tcl]
        # Filtere .git Verzeichnis heraus
        set filtered_files {}
        foreach f $files {
            if {![string match "*/.git/*" $f] && ![string match ".git/*" [file tail [file dirname $f]]]} {
                lappend filtered_files $f
            }
        }
        set anzahl [llength $filtered_files]
    } result]} {
        set anzahl 0
    }
    
    melde "Stand $stand, $anzahl Erzeugnisse"
}

# Konfiguration
set wurzel [expr {[info exists env(ABSTRACTIONS_WORKSPACE)] ? $env(ABSTRACTIONS_WORKSPACE) : "/home/openclaw/.openclaw/workspace"}]
set ziel "$wurzel/git/Abstraktionen"
set herkunft "https://github.com/KikiKari/Projects.git"
set branch "abstractions"
set takt [expr {[info exists env(ABGLEICH_TAKT)] ? $env(ABGLEICH_TAKT) : 43200}]

melde "Start, Takt ${takt}s"

# Endlosschleife
while {1} {
    abgleichen $ziel $herkunft $branch
    after [expr {$takt * 1000}]
}
