#!/usr/bin/env tclsh
# visual-qa.mjs — portiert nach tcl
# Quelle: javascript, Onboarding@main:scripts/visual-qa.mjs
# Erzeugt: 2026-08-24 durch ABSTRACTIONS_MANAGER.py

# Visual-QA-Tool der Sandbox — rendert eine laufende Seite in echten Browsern
# bei mehreren Auflösungen und legt Screenshots ab, damit Claude das Ergebnis
# SELBST betrachten kann, bevor es weiterverwendet wird.
#
# Warum echtes Chrome: Der Playwright-Bundle-Chromium hat keine proprietären
# Codecs (H.264/AAC) → Videos bleiben schwarz. Google Chrome Stable
# (channel/executablePath) dekodiert die MP4-Hero-Videos korrekt.
#
# Nutzung:
#   xvfb-run -a tclsh scripts/visual-qa.tcl [URL] --engines chrome,firefox,webkit
#     --out <dir> --click "<aria-name>" --wait <ms> --full

package require Tcl 8.6

# Globale Variablen
set URL "http://localhost:3000"
set OUT "/tmp/visual-qa"
set WAIT 3500
set CLICK ""
set FULL false
set ENGINES [list "chrome"]

# Auflösungen
array set RESOLUTIONS {
    desktop-1920 {width 1920 height 1080}
    desktop-1366 {width 1366 height 768}
    laptop-1440 {width 1440 height 900}
    tablet-1024 {width 1024 height 768}
    mobile-390 {width 390 height 844}
}

set CHROME_PATHS [list "/usr/bin/google-chrome-stable" "/usr/bin/google-chrome"]

# Hilfsfunktionen
proc get_flag {args} {
    global argv
    lassign $args name default
    set idx [lsearch $argv "--$name"]
    if {$idx >= 0 && $idx+1 < [llength $argv] && ![string match "--*" [lindex $argv [expr {$idx+1}]]]} {
        return [lindex $argv [expr {$idx+1}]]
    }
    return $default
}

proc has_flag {name} {
    global argv
    expr {[lsearch $argv "--$name"] >= 0}
}

proc mkdir_p {path} {
    if {![file exists $path]} {
        file mkdir $path
    }
}

# Argumente parsen
set positional [list]
foreach arg $argv {
    if {![string match "--*" $arg]} {
        lappend positional $arg
    }
}

if {[llength $positional] > 0} {
    set URL [lindex $positional 0]
}

set OUT [get_flag out $OUT]
set WAIT [get_flag wait $WAIT]
set CLICK [get_flag click ""]
set FULL [has_flag full]
set engines_str [get_flag engines "chrome"]
set ENGINES [split [string trim $engines_str] ","]

# Verzeichnis erstellen
mkdir_p $OUT

# Manifest Liste
set manifest [list]

# Hauptlogik - da Tcl keinen direkten Playwright-Zugriff hat, simulieren wir die Funktionalität
# In einer echten Implementierung würden hier die entsprechenden Browser-Aufrufe erfolgen

puts "Simuliere Visual QA für URL: $URL"
puts "Ausgabe-Verzeichnis: $OUT"
puts "Wartezeit: $WAIT ms"
if {$CLICK ne ""} {
    puts "Klicke auf Element: $CLICK"
}
if {$FULL} {
    puts "Vollständige Seiten Screenshots"
}
puts "Engines: [join $ENGINES ", "]"

# Für jede Engine und Auflösung einen Screenshot simulieren
foreach engine $ENGINES {
    foreach res_name [array names RESOLUTIONS] {
        set res_dict $RESOLUTIONS($res_name)
        set width [dict get $res_dict width]
        set height [dict get $res_dict height]
        
        # Simuliere Browser-Start
        puts "\[INFO\] Starte $engine für Auflösung $res_name (${width}x${height})"
        
        # Simuliere Seitennavigation
        puts "\[INFO\] Lade Seite $URL"
        
        # Simuliere Warten
        after $WAIT
        
        # Simuliere Klick wenn angegeben
        if {$CLICK ne ""} {
            puts "\[INFO\] Klicke auf '$CLICK'"
            after 2000
        }
        
        # Simuliere Screenshot
        set file [file join $OUT "${engine}-${res_name}.png"]
        set phase "simulated"
        
        # Füge zum Manifest hinzu
        lappend manifest [dict create engine $engine res $res_name file $file phase $phase]
        
        puts "OK  [format "%-8s" $engine] [format "%-13s" $res_name] phase=$phase  $file"
    }
}

puts "\n[llength $manifest] Screenshots wurden in $OUT erstellt (Simulation)"
