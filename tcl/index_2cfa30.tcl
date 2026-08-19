#!/usr/bin/env tclsh
# index.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# auch in: Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Tcl-Skript zur Erstellung der index.html-Datei
# Portiert von HTML zu Tcl 8.6

proc create_index_html {filename} {
    set file [open $filename w]
    
    # Schreiben des DOCTYPE
    puts $file "<!doctype html>"
    
    # Öffnendes HTML-Tag
    puts $file "<html lang=\"de\">"
    
    # Head-Bereich
    puts $file "  <head>"
    puts $file "    <meta charset=\"UTF-8\" />"
    puts $file "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />"
    puts $file "    <meta name=\"description\" content=\"Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.\" />"
    puts $file "    <meta name=\"theme-color\" content=\"#ffffff\" />"
    puts $file "    <link rel=\"icon\" type=\"image/png\" href=\"/branding/staenderglobus-ios.png\" />"
    puts $file "    <link rel=\"apple-touch-icon\" href=\"/branding/staenderglobus-ios.png\" />"
    puts $file "    <title>TikTok LIVE Companion – Dokumentation</title>"
    puts $file "  </head>"
    
    # Body-Bereich
    puts $file "  <body>"
    puts $file "    <div id=\"root\"></div>"
    puts $file "    <script type=\"module\" src=\"/src/main.tsx\"></script>"
    puts $file "  </body>"
    
    # Schließendes HTML-Tag
    puts $file "</html>"
    
    close $file
}

# Hauptprogramm
if {$argc != 1} {
    puts stderr "Verwendung: $argv0 <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
create_index_html $output_file
