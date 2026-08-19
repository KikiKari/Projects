#!/usr/bin/env tclsh
# index.html — portiert nach tcl
# Quelle: html, Projects@Program-Derivation:public/index.html
# auch in: Projects@Vision-Check:public/index.html
# auch in: Projects@Weather-Check:public/index.html
# auch in: Projects@abstractions:public/index.html
# auch in: 5 weiteren Fundstellen
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Tcl-Skript zur Erzeugung der HTML-Datei index.html
# Das Skript erwartet einen Parameter: den Namen der Ausgabedatei

if {$argc != 1} {
    puts stderr "Aufruf: [info script] <ausgabedatei>"
    exit 1
}

set dateiname [lindex $argv 0]
set datei [open $dateiname w]

puts $datei "<!DOCTYPE html>"
puts $datei "<html lang=\"de\">"
puts $datei "<head>"
puts $datei "<meta charset=\"utf-8\">"
puts $datei "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
puts $datei "<meta http-equiv=\"refresh\" content=\"0; url=3d.html\">"
puts $datei "<title>Weiterleitung zur 3D-Ansicht</title>"
puts $datei "<link rel=\"canonical\" href=\"3d.html\">"
puts $datei "<script>location.replace('3d.html');</script>"
puts $datei "</head>"
puts $datei "<body>"
puts $datei "<p><a href=\"3d.html\">3D-Ansicht öffnen</a></p>"
puts $datei "</body>"
puts $datei "</html>"

close $datei
