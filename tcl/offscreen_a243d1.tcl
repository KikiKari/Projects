#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "df48231d93ba44ea3776744fa0ae8b94a44eff1ef6448ecdd2ae60c6a3cb94db", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "tcl"}
# offscreen.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 Script zur Erzeugung der offscreen.html Datei
# Dieses Skript generiert dynamisch das HTML-Dokument

proc createOffscreenHtml {filename} {
    # Oeffne die Zieldatei zum Schreiben
    set fh [open $filename w]
    
    # Schreibe die HTML-Struktur
    puts $fh "<!doctype html>"
    puts $fh "<html lang=\"de\">"
    puts $fh "<head>"
    puts $fh "  <meta charset=\"utf-8\">"
    puts $fh "  <title>TikTok LIVE Companion Sprachausgabe</title>"
    puts $fh "</head>"
    puts $fh "<body>"
    puts $fh "  <script src=\"offscreen.js\"></script>"
    puts $fh "</body>"
    puts $fh "</html>"
    
    # Schliesse die Datei
    close $fh
}

# Hauptprogramm
if {$argc != 1} {
    puts stderr "Verwendung: [info script] <dateiname>"
    exit 1
}

set outputFile [lindex $argv 0]
createOffscreenHtml $outputFile
