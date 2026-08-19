#!/usr/bin/env tclsh
# secret-scan.mjs — portiert nach tcl
# Quelle: javascript, Onboarding@main:scripts/secret-scan.mjs
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6

# Globale Variablen
set root [file normalize [file dirname [file dirname [info script]]]]
set skipped [dict create \
    node_modules {} \
    .next {} \
    .git {} \
    .pytest_cache {} \
    __pycache__ {} \
    "media-production/raw" {} \
    "media-production/private" {} \
]
set patterns [list \
    {sk-(?:proj|svcacct|ant|or-v1|admin)-[A-Za-z0-9_-]{20,}} \
    {(?:nvapi|lin_api|ntn|vcp)_[A-Za-z0-9_-]{20,}} \
    {ELEVENLABS_API_KEY\s*=\s*["']?[A-Za-z0-9]{20,}} \
    {WAVESPEED_API_KEY\s*=\s*["']?[A-Za-z0-9]{20,}} \
]
set findings [list]

# Hilfsfunktion zur Überprüfung, ob ein Pfad übersprungen werden soll
proc should_skip {rel} {
    global skipped
    set parts [split $rel "/"]
    
    # Prüfe auf direkte Übereinstimmung oder Präfix
    foreach skip [dict keys $skipped] {
        if {$rel eq $skip || [string first "$skip/" $rel] == 0 || [lsearch -exact $parts $skip] != -1} {
            return 1
        }
    }
    
    return 0
}

# Rekursive Funktion zum Durchlaufen des Verzeichnisbaums
proc walk {dir {relative ""}} {
    global root skipped patterns findings
    
    # Hole alle Einträge im Verzeichnis
    if {[catch {glob -directory $dir -types {d f l} -- *} entries]} {
        return
    }
    
    foreach entry $entries {
        set basename [file tail $entry]
        set rel [expr {$relative eq "" ? $basename : "$relative/$basename"}]
        
        # Überspringe bestimmte Dateien/Verzeichnisse
        if {$basename eq ".env" || 
            ([string first ".env." $basename] == 0 && $basename ne ".env.example") ||
            [should_skip $rel]} {
            continue
        }
        
        # Prüfe, ob es ein Verzeichnis ist
        if {[file isdirectory $entry]} {
            walk $entry $rel
        } elseif {[file exists $entry] && [file size $entry] < 2000000} {
            # Lese Dateiinhalt
            if {![catch {open $entry r} fh]} {
                set content [read $fh]
                close $fh
                
                # Prüfe auf Muster
                foreach pattern $patterns {
                    if {[regexp $pattern $content]} {
                        lappend findings $rel
                        break
                    }
                }
            }
        }
    }
}

# Hauptausführung
walk $root

# Entferne Duplikate
if {[llength $findings] > 0} {
    set unique_findings [lsort -unique $findings]
    puts stderr "Secret-Scan fehlgeschlagen: [join $unique_findings ", "]"
    exit 1
}

puts "Secret-Scan bestanden."
