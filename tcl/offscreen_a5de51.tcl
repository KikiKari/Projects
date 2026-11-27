#!/usr/bin/tclsh
# abstraction-provenance: {"artifact_sha256": "ea0df83a4375ebd8f59e378aaeb946b34d5c85f3d57d5d99c7b0fe9aa3ac9b19", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "tcl"}
# offscreen.html — portiert nach tcl
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Tcl-Script zum Erstellen der HTML-Struktur von offscreen.html
# Aufruf: tclsh offscreen.tcl <Ausgabedatei>

# Prüfe Aufrufparameter
if {$argc != 1} {
    puts "Aufruf: [info script] <Ausgabedatei>"
    exit 1
}

set dateiname [lindex $argv 0]

# Öffne Datei zum Schreiben
if {[catch {open $dateiname w} datei]} {
    puts "Fehler beim Öffnen der Datei '$dateiname': $datei"
    exit 1
}

# Schreibe HTML-Struktur
puts $datei "<!doctype html>"
puts $datei "<html lang=\"de\">"
puts $datei "<head>"
puts $datei "  <meta charset=\"utf-8\">"
puts $datei "  <title>TikTok LIVE Companion Sprachausgabe</title>"
puts $datei "</head>"
puts $datei "<body>"
puts $datei "  <script src=\"offscreen.js\"></script>"
puts $datei "</body>"
puts $datei "</html>"

# Schließe Datei
close $datei

# Erfolgsmeldung
puts "HTML-Datei erfolgreich erstellt: $dateiname"
