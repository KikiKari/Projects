#!/usr/bin/env tclsh
# offscreen.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion:release/0.7.1/tiktok-live-companion-extension-0.7.1/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:release/0.7.1/tiktok-live-companion-extension-0.7.1/offscreen.html
# auch in: 2 weiteren Fundstellen
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 Skript zur Erzeugung der offscreen.html Datei
# Erzeugt ein HTML-Dokument mit UTF-8 Kodierung, deutscher Spracheinstellung
# und bindet die JavaScript-Datei offscreen.js ein

# Prüfe Kommandozeilenparameter
if {$argc != 1} {
    puts stderr "Aufruf: [info script] <ausgabedatei>"
    exit 1
}

set dateiname [lindex $argv 0]

# Erzeuge das HTML-Dokument
set htmlInhalt {<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>TikTok LIVE Companion Sprachausgabe</title>
</head>
<body>
  <script src="offscreen.js"></script>
</body>
</html>
}

# Schreibe in Datei
if {[catch {open $dateiname w} datei]} {
    puts stderr "Fehler beim Öffnen der Datei '$dateiname': $datei"
    exit 1
}

# Stelle sicher, dass UTF-8 korrekt geschrieben wird
puts $datei $htmlInhalt
close $datei

# Erfolgsmeldung
puts "HTML-Datei erfolgreich erstellt: $dateiname"
