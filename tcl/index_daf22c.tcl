#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "6f70a3e43faba5bcd8e7bf7d47eeb778289eccc073801ce9cb12cee1390afad7", "source_sha256": "daf22c296c801d3d533083361cc59fbdc22e5bfe528aa4bad1973b54cc5448a4", "target_language": "tcl"}
# index.css — portiert nach tcl
# Quelle: css, OpenClaw@main:src/index.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

proc writeCSS {filename} {
    set cssContent {
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
    }

    # Entferne fuehrende Leerzeilen und einruecken
    set lines [split $cssContent \n]
    set trimmedLines {}
    
    foreach line $lines {
        # Entferne fuehrende Leerzeichen von jeder Zeile
        lappend trimmedLines [string trimleft $line]
    }
    
    # Entferne erste und letzte leere Zeile
    set trimmedLines [lrange $trimmedLines 1 end-1]
    
    set finalContent [join $trimmedLines \n]
    
    set fileHandle [open $filename w]
    puts -nonewline $fileHandle $finalContent
    close $fileHandle
}

# Hauptprogramm
if {$argc != 1} {
    puts "Verwendung: [info script] <dateiname>"
    exit 1
}

set outputFile [lindex $argv 0]
writeCSS $outputFile
