#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "d966d716dfa81dcb9dcda92f07686c10f97ad5519944dfb61dfc7ef7dd06b96c", "source_sha256": "7fc810e8bcb817cb81407c2ad604d4bd70dce9f3ff8cb2bbfbcacfec00febd1c", "target_language": "tcl"}
# status-overview.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Tcl-Script zur Erzeugung der status-overview.html
# Portiert von HTML zu Tcl 8.6

proc create_status_overview {filename} {
    set fp [open $filename w]
    
    puts $fp "<!doctype html>"
    puts $fp "<html lang=\"de\">"
    puts $fp "<head>"
    puts $fp "  <meta charset=\"utf-8\">"
    puts $fp "  <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
    puts $fp "  <title>STATUS-Overview</title>"
    puts $fp "  <link rel=\"stylesheet\" href=\"status-overview.css\">"
    puts $fp "</head>"
    puts $fp "<body>"
    puts $fp "  <main id=\"grid\" aria-label=\"LIVE-Übersicht\"></main>"
    puts $fp "  <script src=\"vendor-mpegts.js\"></script>"
    puts $fp "  <script src=\"status-overview-player.js\"></script>"
    puts $fp "</body>"
    puts $fp "</html>"
    
    close $fp
}

# Hauptprogramm - prüft Kommandozeilenparameter
if {$argc != 1} {
    puts stderr "Aufruf: [info script] <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
create_status_overview $output_file
