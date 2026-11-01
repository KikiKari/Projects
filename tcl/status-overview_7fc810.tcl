#!/usr/bin/tclsh
# status-overview.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
# Erzeugt: 2026-11-01 durch ABSTRACTIONS_MANAGER.py

# Tcl-Skript zur Erzeugung der status-overview.html
# Portiert von HTML zu Tcl 8.6

proc generate_status_overview {filename} {
    # Oeffne Datei zum Schreiben
    set fd [open $filename w]
    
    # Schreibe den HTML-Inhalt strukturiert
    puts $fd "<!doctype html>"
    puts $fd "<html lang=\"de\">"
    puts $fd "<head>"
    puts $fd "<meta charset=\"utf-8\">"
    puts $fd "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
    puts $fd "<title>STATUS-Overview</title>"
    puts $fd "<link rel=\"stylesheet\" href=\"status-overview.css\">"
    puts $fd "</head>"
    puts $fd "<body>"
    puts $fd "<main id=\"grid\" aria-label=\"LIVE-Übersicht\"></main>"
    puts $fd "<script src=\"vendor-mpegts.js\"></script>"
    puts $fd "<script src=\"status-overview-player.js\"></script>"
    puts $fd "</body>"
    puts $fd "</html>"
    
    # Schliesse Datei
    close $fd
}

# Hauptprogramm
if {$argc != 1} {
    puts "Aufruf: $argv0 <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
generate_status_overview $output_file
