#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "c80bfbd4ac0a1606249ae3ee96ad715cc7516a193a1d35703090ed75519196bc", "source_sha256": "47d390b58fc734629c213c66e58cb7f0c68bbd896bac294215d12289e5e21c07", "target_language": "python"}
# gateway-styles.css — portiert nach python
# Quelle: css, OpenClaw@main:examples/gateway-styles.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import sys
from pathlib import Path

def generate_css():
    """Generate the complete CSS content as a structured string."""
    
    # CSS content organized by sections for clarity
    css_parts = []
    
    # Base reset and root variables
    css_parts.append("/* OpenClaw Gateway Dashboard */\n")
    css_parts.append("*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }\n")
    
    css_parts.append(":root {\n")
    css_parts.append("  --bg:       #0d1117;\n")
    css_parts.append("  --surface:  #161b22;\n")
    css_parts.append("  --border:   #30363d;\n")
    css_parts.append("  --text:     #e6edf3;\n")
    css_parts.append("  --muted:    #8b949e;\n")
    css_parts.append("  --green:    #3fb950;\n")
    css_parts.append("  --yellow:   #d29922;\n")
    css_parts.append("  --red:      #f85149;\n")
    css_parts.append("  --accent:   #58a6ff;\n")
    css_parts.append("}\n")
    
    # Body styles
    css_parts.append("body {\n")
    css_parts.append("  background: var(--bg);\n")
    css_parts.append("  color: var(--text);\n")
    css_parts.append("  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif;\n")
    css_parts.append("  min-height: 100vh;\n")
    css_parts.append("}\n")
    
    # Header styles
    css_parts.append("header {\n")
    css_parts.append("  display: flex;\n")
    css_parts.append("  align-items: center;\n")
    css_parts.append("  gap: 1rem;\n")
    css_parts.append("  padding: 1.25rem 2rem;\n")
    css_parts.append("  border-bottom: 1px solid var(--border);\n")
    css_parts.append("  background: var(--surface);\n")
    css_parts.append("}\n")
    
    css_parts.append("header h1 { font-size: 1.25rem; color: var(--accent); }\n")
    
    # Badge styles
    css_parts.append(".badge {\n")
    css_parts.append("  padding: .25rem .75rem;\n")
    css_parts.append("  border-radius: 999px;\n")
    css_parts.append("  font-size: .75rem;\n")
    css_parts.append("  font-weight: 600;\n")
    css_parts.append("  background: var(--border);\n")
    css_parts.append("  color: var(--muted);\n")
    css_parts.append("}\n")
    
    css_parts.append(".badge.ok    { background: #1a3a2a; color: var(--green); }\n")
    css_parts.append(".badge.warn  { background: #3a2e0a; color: var(--yellow); }\n")
    css_parts.append(".badge.error { background: #3a1010; color: var(--red); }\n")
    
    # Main content
    css_parts.append("main { padding: 2rem; max-width: 960px; margin: 0 auto; }\n")
    
    # Grid layout
    css_parts.append(".grid {\n")
    css_parts.append("  display: grid;\n")
    css_parts.append("  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));\n")
    css_parts.append("  gap: 1rem;\n")
    css_parts.append("  margin-bottom: 2rem;\n")
    css_parts.append("}\n")
    
    # Card styles
    css_parts.append(".card {\n")
    css_parts.append("  background: var(--surface);\n")
    css_parts.append("  border: 1px solid var(--border);\n")
    css_parts.append("  border-radius: 8px;\n")
    css_parts.append("  padding: 1.25rem;\n")
    css_parts.append("  position: relative;\n")
    css_parts.append("}\n")
    
    css_parts.append(".card h2   { font-size: 1rem; margin-bottom: .25rem; }\n")
    css_parts.append(".card .endpoint { font-size: .8rem; color: var(--muted); }\n")
    
    # Status dot
    css_parts.append(".status-dot {\n")
    css_parts.append("  position: absolute;\n")
    css_parts.append("  top: 1.25rem;\n")
    css_parts.append("  right: 1.25rem;\n")
    css_parts.append("  width: 10px;\n")
    css_parts.append("  height: 10px;\n")
    css_parts.append("  border-radius: 50%;\n")
    css_parts.append("  background: var(--border);\n")
    css_parts.append("}\n")
    
    css_parts.append(".status-dot.green { background: var(--green); box-shadow: 0 0 6px var(--green); }\n")
    css_parts.append(".status-dot.red   { background: var(--red);   box-shadow: 0 0 6px var(--red); }\n")
    
    # Metrics section
    css_parts.append(".metrics h2 { font-size: 1rem; margin-bottom: 1rem; }\n")
    
    # Table styles
    css_parts.append("table {\n")
    css_parts.append("  width: 100%;\n")
    css_parts.append("  border-collapse: collapse;\n")
    css_parts.append("  font-size: .875rem;\n")
    css_parts.append("}\n")
    
    css_parts.append("th, td {\n")
    css_parts.append("  padding: .625rem 1rem;\n")
    css_parts.append("  text-align: left;\n")
    css_parts.append("  border-bottom: 1px solid var(--border);\n")
    css_parts.append("}\n")
    
    css_parts.append("th { color: var(--muted); font-weight: 500; }\n")
    css_parts.append("tr:last-child td { border-bottom: none; }\n")
    
    return "".join(css_parts)

def main():
    """Main function to write CSS to file specified by command line argument."""
    if len(sys.argv) != 2:
        print("Usage: python gateway_styles.py <output_file>")
        sys.exit(1)
        
    output_path = Path(sys.argv[1])
    css_content = generate_css()
    
    try:
        output_path.write_text(css_content, encoding='utf-8')
    except Exception as e:
        print(f"Error writing to file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
