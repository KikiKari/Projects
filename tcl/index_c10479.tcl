#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "2d2ebebd19cd177a06bf21fa3b3559f9cfb9a4b8a1f191069ddc3d4ca4d8104c", "source_sha256": "c10479f79ca5554fe399cf2f5d70fb5b32e837c1c7a846eb7dd7c9e9e5319c66", "target_language": "tcl"}
# index.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/index.html
# auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:site/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

proc generateHTML {filename} {
    set fp [open $filename w]
    
    puts $fp "<!doctype html>"
    puts $fp "<html lang=\"de\">"
    puts $fp "  <head>"
    puts $fp "    <meta charset=\"UTF-8\" />"
    puts $fp "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />"
    puts $fp "    <meta name=\"description\" content=\"Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.\" />"
    puts $fp "    <meta name=\"theme-color\" content=\"#ffffff\" />"
    puts $fp "    <link rel=\"icon\" type=\"image/png\" href=\"/branding/staenderglobus-ios.png\" />"
    puts $fp "    <link rel=\"apple-touch-icon\" href=\"/branding/staenderglobus-ios.png\" />"
    puts $fp "    <title>TikTok LIVE Companion – Dokumentation</title>"
    puts $fp "  </head>"
    puts $fp "  <body>"
    puts $fp "    <div id=\"root\"></div>"
    puts $fp "    <script type=\"module\" src=\"/src/main.tsx\"></script>"
    puts $fp "  </body>"
    puts $fp "</html>"
    
    close $fp
}

# Prüfe Kommandozeilenargumente
if {$argc != 1} {
    puts stderr "Verwendung: $argv0 <ausgabedatei>"
    exit 1
}

set outputFile [lindex $argv 0]
generateHTML $outputFile
