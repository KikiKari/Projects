#!/usr/bin/env tclsh
# index.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# auch in: Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

proc writeHtml {filename} {
    set fp [open $filename w]
    
    puts $fp {<!doctype html>}
    puts $fp {<html lang="de">}
    puts $fp {  <head>}
    puts $fp {    <meta charset="UTF-8" />}
    puts $fp {    <meta name="viewport" content="width=device-width, initial-scale=1.0" />}
    puts $fp {    <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.7.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />}
    puts $fp {    <meta name="theme-color" content="#ffffff" />}
    puts $fp {    <title>TikTok LIVE Companion – Dokumentation</title>}
    puts $fp {  </head>}
    puts $fp {  <body>}
    puts $fp {    <div id="root"></div>}
    puts $fp {    <script type="module" src="/src/main.tsx"></script>}
    puts $fp {  </body>}
    puts $fp {</html>}
    
    close $fp
}

if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}

writeHtml [lindex $argv 0]
