#!/usr/bin/env tcl
# abstraction-provenance: {"artifact_sha256": "98b3ca3110c08bb87a3cb05e28b76057775d4b51a6e4fcad68621bc3d0e25343", "source_sha256": "78b518f6f68bf0f05a573239d113470b3f5a9440be7cff5f80bc8576462525c3", "target_language": "tcl"}
# node-monitor.css — portiert nach tcl
# Quelle: css, Projects@abstractions:css/node-monitor.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# Erzeugt node-monitor.css aus strukturierten Daten
# Portierung eines CSS-Dokuments nach Tcl 8.6

proc write_css {filename} {
    set css_data [dict create \
        root [dict create \
            bg "#0d1117" \
            surface "#161b22" \
            border "#30363d" \
            text "#e6edf3" \
            green "#3fb950" \
            red "#f85149" \
            accent "#58a6ff" \
        ] \
    ]

    set f [open $filename w]
    
    puts $f "/* abstraction-provenance: {\"artifact_sha256\": \"37bc702d7c4046193f78406172db9f9b81e5951260071773ee3519d55f802128\", \"source_sha256\": \"ed59efd19fa280b88488d50ce98f4213a84c5f833eacd98c7cb448f570c805fe\", \"target_language\": \"css\"} */"
    puts $f "/* node-monitor.html — portiert nach css */"
    puts $f "/* Quelle: html, OpenClaw@main:examples/node-monitor.html */"
    puts $f "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */"
    puts $f ""
    
    # :root Regel
    puts $f ":root {"
    set root_vars [dict get $css_data root]
    dict for {name value} $root_vars {
        puts $f "  --$name: $value;"
    }
    puts $f "}"
    puts $f ""
    
    # Universelle Regel
    puts $f "* {"
    puts $f "  box-sizing: border-box;"
    puts $f "  margin: 0;"
    puts $f "  padding: 0;"
    puts $f "}"
    puts $f ""
    
    # body Regel
    puts $f "body {"
    puts $f "  background: var(--bg);"
    puts $f "  color: var(--text);"
    puts $f "  font-family: -apple-system, sans-serif;"
    puts $f "  padding: 1.5rem;"
    puts $f "}"
    puts $f ""
    
    # h1 Regel
    puts $f "h1 {"
    puts $f "  color: var(--accent);"
    puts $f "  margin-bottom: 1rem;"
    puts $f "  font-size: 1.2rem;"
    puts $f "}"
    puts $f ""
    
    # canvas Regel
    puts $f "canvas {"
    puts $f "  display: block;"
    puts $f "  border: 1px solid var(--border);"
    puts $f "  border-radius: 8px;"
    puts $f "  background: var(--surface);"
    puts $f "}"
    puts $f ""
    
    # #log Regeln
    puts $f "#log {"
    puts $f "  margin-top: 1rem;"
    puts $f "  height: 140px;"
    puts $f "  overflow-y: auto;"
    puts $f "  background: var(--surface);"
    puts $f "  border: 1px solid var(--border);"
    puts $f "  border-radius: 8px;"
    puts $f "  padding: .75rem;"
    puts $f "  font-size: .78rem;"
    puts $f "  font-family: monospace;"
    puts $f "  color: #8b949e;"
    puts $f "}"
    puts $f ""
    
    puts $f "#log .err {"
    puts $f "  color: var(--red);"
    puts $f "}"
    puts $f ""
    
    puts $f "#log .ok {"
    puts $f "  color: var(--green);"
    puts $f "}"
    
    close $f
}

# Hauptprogramm
if {$argc != 1} {
    puts stderr "Aufruf: [info script] <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
write_css $output_file
