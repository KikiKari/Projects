#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "3cce01b1c1a55853a5f6cb821dbfb0a8a97d3a252979e21842012aa986bb4155", "source_sha256": "735fe4b2c74b10f265f715cd4e85d574f46a7132d2e592703b5e712888470105", "target_language": "tcl"}
# index.html — portiert nach tcl
# Quelle: html, OpenClaw@main:index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Tcl-Skript zur Erzeugung der index.html-Datei
# Portiert von HTML zu Tcl 8.6

proc write_index_html {filename} {
    set fp [open $filename w]
    
    # DOCTYPE und HTML-Grundstruktur
    puts $fp "<!DOCTYPE html>"
    puts $fp "<html lang=\"de\">"
    
    # HEAD-Bereich
    puts $fp "  <head>"
    puts $fp "    <meta charset=\"utf-8\" />"
    puts $fp "    <link rel=\"icon\" href=\"/favicon.ico\" />"
    puts $fp "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />"
    puts $fp "    <meta name=\"theme-color\" content=\"#0b1020\" />"
    puts $fp "    <meta"
    puts $fp "      name=\"description\""
    puts $fp "      content=\"OpenClaw Startseite für Repository, Dokumentation und Frontend-Branch.\""
    puts $fp "    />"
    puts $fp "    <link rel=\"apple-touch-icon\" href=\"/logo192.png\" />"
    
    # Kommentarblock
    puts $fp "    <!--"
    puts $fp "      manifest.json provides metadata used when your web app is installed on a"
    puts $fp "      user's mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/"
    puts $fp "    -->"
    
    puts $fp "    <link rel=\"manifest\" href=\"/manifest.json\" />"
    puts $fp "    <title>OpenClaw</title>"
    puts $fp "  </head>"
    
    # BODY-Bereich
    puts $fp "  <body>"
    puts $fp "    <noscript>You need to enable JavaScript to run this app.</noscript>"
    puts $fp "    <div id=\"root\"></div>"
    
    # Zweiter Kommentarblock
    puts $fp "    <!--"
    puts $fp "      This HTML file is a template."
    puts $fp "      If you open it directly in the browser, you will see an empty page."
    puts $fp ""
    puts $fp "      You can add webfonts, meta tags, or analytics to this file."
    puts $fp "      The build step will place the bundled scripts into the <body> tag."
    puts $fp ""
    puts $fp "      To begin the development, run \`npm start\` or \`yarn start\`."
    puts $fp "      To create a production bundle, use \`npm run build\` or \`yarn build\`."
    puts $fp "    -->"
    
    puts $fp "  </body>"
    
    # SCRIPT-Tag
    puts $fp "  <script type=\"module\" src=\"/src/index.jsx\"></script>"
    
    # Abschluss des HTML-Dokuments
    puts $fp "</html>"
    
    close $fp
}

# Hauptprogramm - prüft Kommandozeilenargumente
if {$argc != 1} {
    puts stderr "Aufruf: [info script] <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
write_index_html $output_file
