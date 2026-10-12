#!/usr/bin/env tclsh
# index.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# Erzeugt: 2026-10-12 durch ABSTRACTIONS_MANAGER.py

# Tcl-Skript zur Erstellung der HTML-Datei index.html
# Portiert von HTML zu Tcl 8.6

proc createIndexHtml {filename} {
    set html [list]
    
    # DOCTYPE und HTML-Start
    lappend html {<!doctype html>}
    lappend html {<html lang="de">}
    
    # HEAD-Bereich
    lappend html {  <head>}
    lappend html {    <meta charset="UTF-8" />}
    lappend html {    <meta name="viewport" content="width=device-width, initial-scale=1.0" />}
    lappend html {    <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />}
    lappend html {    <meta name="theme-color" content="#ffffff" />}
    lappend html {    <link rel="icon" type="image/png" href="/branding/staenderglobus-ios.png" />}
    lappend html {    <link rel="apple-touch-icon" href="/branding/staenderglobus-ios.png" />}
    lappend html {    <title>TikTok LIVE Companion – Dokumentation</title>}
    lappend html {  </head>}
    
    # BODY-Bereich
    lappend html {  <body>}
    lappend html {    <div id="root"></div>}
    lappend html {    <script type="module" src="/src/main.tsx"></script>}
    lappend html {  </body>}
    lappend html {</html>}
    
    # Schreiben der Datei
    set fd [open $filename w]
    puts $fd [join $html "\n"]
    close $fd
}

# Hauptprogramm
if {$argc != 1} {
    puts stderr "Verwendung: [info script] <ausgabedatei>"
    exit 1
}

set outputFile [lindex $argv 0]
createIndexHtml $outputFile
