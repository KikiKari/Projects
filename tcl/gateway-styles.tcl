#!/usr/bin/env tclsh
# gateway-styles.css — portiert nach tcl
# Quelle: css, OpenClaw@main:examples/gateway-styles.css
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# OpenClaw Gateway Dashboard CSS Generator

proc generateCSS {} {
    set css ""

    # Universal selector
    append css "*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }\n\n"

    # Root variables
    append css ":root {\n"
    append css "  --bg:       #0d1117;\n"
    append css "  --surface:  #161b22;\n"
    append css "  --border:   #30363d;\n"
    append css "  --text:     #e6edf3;\n"
    append css "  --muted:    #8b949e;\n"
    append css "  --green:    #3fb950;\n"
    append css "  --yellow:   #d29922;\n"
    append css "  --red:      #f85149;\n"
    append css "  --accent:   #58a6ff;\n"
    append css "}\n\n"

    # Body styles
    append css "body {\n"
    append css "  background: var(--bg);\n"
    append css "  color: var(--text);\n"
    append css "  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif;\n"
    append css "  min-height: 100vh;\n"
    append css "}\n\n"

    # Header styles
    append css "header {\n"
    append css "  display: flex;\n"
    append css "  align-items: center;\n"
    append css "  gap: 1rem;\n"
    append css "  padding: 1.25rem 2rem;\n"
    append css "  border-bottom: 1px solid var(--border);\n"
    append css "  background: var(--surface);\n"
    append css "}\n\n"

    append css "header h1 { font-size: 1.25rem; color: var(--accent); }\n\n"

    # Badge styles
    append css ".badge {\n"
    append css "  padding: .25rem .75rem;\n"
    append css "  border-radius: 999px;\n"
    append css "  font-size: .75rem;\n"
    append css "  font-weight: 600;\n"
    append css "  background: var(--border);\n"
    append css "  color: var(--muted);\n"
    append css "}\n"
    append css ".badge.ok    { background: #1a3a2a; color: var(--green); }\n"
    append css ".badge.warn  { background: #3a2e0a; color: var(--yellow); }\n"
    append css ".badge.error { background: #3a1010; color: var(--red); }\n\n"

    # Main styles
    append css "main { padding: 2rem; max-width: 960px; margin: 0 auto; }\n\n"

    # Grid styles
    append css ".grid {\n"
    append css "  display: grid;\n"
    append css "  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));\n"
    append css "  gap: 1rem;\n"
    append css "  margin-bottom: 2rem;\n"
    append css "}\n\n"

    # Card styles
    append css ".card {\n"
    append css "  background: var(--surface);\n"
    append css "  border: 1px solid var(--border);\n"
    append css "  border-radius: 8px;\n"
    append css "  padding: 1.25rem;\n"
    append css "  position: relative;\n"
    append css "}\n\n"

    append css ".card h2   { font-size: 1rem; margin-bottom: .25rem; }\n"
    append css ".card .endpoint { font-size: .8rem; color: var(--muted); }\n\n"

    # Status dot styles
    append css ".status-dot {\n"
    append css "  position: absolute;\n"
    append css "  top: 1.25rem;\n"
    append css "  right: 1.25rem;\n"
    append css "  width: 10px;\n"
    append css "  height: 10px;\n"
    append css "  border-radius: 50%;\n"
    append css "  background: var(--border);\n"
    append css "}\n"
    append css ".status-dot.green { background: var(--green); box-shadow: 0 0 6px var(--green); }\n"
    append css ".status-dot.red   { background: var(--red);   box-shadow: 0 0 6px var(--red); }\n\n"

    # Metrics styles
    append css ".metrics h2 { font-size: 1rem; margin-bottom: 1rem; }\n\n"

    # Table styles
    append css "table {\n"
    append css "  width: 100%;\n"
    append css "  border-collapse: collapse;\n"
    append css "  font-size: .875rem;\n"
    append css "}\n"
    append css "th, td {\n"
    append css "  padding: .625rem 1rem;\n"
    append css "  text-align: left;\n"
    append css "  border-bottom: 1px solid var(--border);\n"
    append css "}\n"
    append css "th { color: var(--muted); font-weight: 500; }\n"
    append css "tr:last-child td { border-bottom: none; }\n"

    return $css
}

# Main execution
if {$argc != 1} {
    puts "Usage: $argv0 <output-file>"
    exit 1
}

set outputFile [lindex $argv 0]
set cssContent [generateCSS]

# Write to file
if {[catch {open $outputFile w} fileId]} {
    puts "Error: Could not open file $outputFile for writing"
    exit 1
}

puts -nonewline $fileId $cssContent
close $fileId

puts "CSS file generated successfully: $outputFile"
