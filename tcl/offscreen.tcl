#!/usr/bin/env tclsh
# offscreen.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 Skript zur Erzeugung der offscreen.html
# Dieses Skript generiert das HTML-Dokument dynamisch

# Hauptfunktion zur Erstellung der HTML-Datei
proc createOffscreenHtml {filename} {
    # Öffnen der Zieldatei zum Schreiben
    set fh [open $filename w]
    
    # Schreiben des DOCTYPE
    puts $fh "<!doctype html>"
    
    # Öffnendes HTML-Tag mit Sprachattribut
    puts $fh "<html lang=\"de\">"
    
    # Kopfbereich
    puts $fh "<head>"
    puts $fh "  <meta charset=\"utf-8\">"
    puts $fh "  <title>TikTok LIVE Companion Sprachausgabe</title>"
    puts $fh "</head>"
    
    # Body-Bereich
    puts $fh "<body>"
    puts $fh "  <script src=\"offscreen.js\"></script>"
    puts $fh "</body>"
    
    # Schließendes HTML-Tag
    puts $fh "</html>"
    
    # Schließen der Datei
    close $fh
}

# Prüfung auf Kommandozeilenparameter
if {$argc != 1} {
    puts stderr "Verwendung: [info script] <zielverzeichnis/Dateiname>"
    exit 1
}

# Ausführen der Hauptfunktion mit dem übergebenen Dateinamen
createOffscreenHtml [lindex $argv 0]
