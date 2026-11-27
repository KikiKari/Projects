#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "3584d89e90585ad3774600f1f025e3ddec93c97c26c3da1673f4039eaa853726", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "tcl"}
# index.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Tcl-Skript zur Erstellung der index.html-Datei
# Portiert von HTML zu Tcl 8.6

proc createIndexHtml {filename} {
    set htmlContent {}

    # Doctype und HTML-Struktur
    append htmlContent "<!doctype html>\n"
    append htmlContent "<html lang=\"de\">\n"
    append htmlContent "  <head>\n"
    
    # Meta-Tags
    append htmlContent "    <meta charset=\"UTF-8\" />\n"
    append htmlContent "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n"
    append htmlContent "    <meta name=\"description\" content=\"Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.\" />\n"
    append htmlContent "    <meta name=\"theme-color\" content=\"#ffffff\" />\n"
    
    # Links
    append htmlContent "    <link rel=\"icon\" type=\"image/png\" href=\"/branding/staenderglobus-ios.png\" />\n"
    append htmlContent "    <link rel=\"apple-touch-icon\" href=\"/branding/staenderglobus-ios.png\" />\n"
    
    # Titel
    append htmlContent "    <title>TikTok LIVE Companion – Dokumentation</title>\n"
    append htmlContent "  </head>\n"
    append htmlContent "  <body>\n"
    
    # Body-Inhalt
    append htmlContent "    <div id=\"root\"></div>\n"
    append htmlContent "    <script type=\"module\" src=\"/src/main.tsx\"></script>\n"
    append htmlContent "  </body>\n"
    append htmlContent "</html>\n"

    # Schreiben in Datei
    set fileHandle [open $filename w]
    puts -nonewline $fileHandle $htmlContent
    close $fileHandle
}

# Hauptprogramm
if {$argc != 1} {
    puts "Verwendung: [info script] <ausgabedatei>"
    exit 1
}

set outputFile [lindex $argv 0]
createIndexHtml $outputFile
