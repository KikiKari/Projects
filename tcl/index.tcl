#!/usr/bin/env tclsh
# index.css — portiert nach tcl
# Quelle: css, OpenClaw@main:src/index.css
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

proc generateCSS {filename} {
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
    
    # Normalize the CSS content by trimming leading/trailing whitespace
    set cssContent [string trim $cssContent]
    
    # Write to file
    set fileId [open $filename "w"]
    puts -nonewline $fileId $cssContent
    close $fileId
}

# Main execution
if {$argc != 1} {
    puts "Usage: $argv0 <output_filename>"
    exit 1
}

set outputFile [lindex $argv 0]
generateCSS $outputFile
