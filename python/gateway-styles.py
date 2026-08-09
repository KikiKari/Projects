#!/usr/bin/env python3
# gateway-styles.css — portiert nach python
# Quelle: css, OpenClaw@main:examples/gateway-styles.css
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import sys
from pathlib import Path

def generate_css():
    """Generate the CSS content as a structured document"""
    
    # Define variables
    variables = {
        'bg': '#0d1117',
        'surface': '#161b22',
        'border': '#30363d',
        'text': '#e6edf3',
        'muted': '#8b949e',
        'green': '#3fb950',
        'yellow': '#d29922',
        'red': '#f85149',
        'accent': '#58a6ff'
    }
    
    # Build CSS content
    css_parts = []
    
    # Header comment
    css_parts.append("/* OpenClaw Gateway Dashboard */\n")
    
    # Universal selector
    css_parts.append("*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }\n")
    
    # Root variables
    css_parts.append(":root {\n")
    for name, value in variables.items():
        css_parts.append(f"  --{name}:       {value};\n")
    css_parts.append("}\n")
    
    # Body styles
    css_parts.append("body {\n")
    css_parts.append("  background: var(--bg);\n")
    css_parts.append("  color: var(--text);\n")
    css_parts.append('  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;\n')
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
    
    # Main styles
    css_parts.append("main { padding: 2rem; max-width: 960px; margin: 0 auto; }\n")
    
    # Grid styles
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
    
    # Status dot styles
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
    
    # Metrics styles
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
    if len(sys.argv) != 2:
        print("Usage: python gateway_styles.py <output_file>")
        sys.exit(1)
    
    output_file = Path(sys.argv[1])
    css_content = generate_css()
    
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(css_content)
        print(f"CSS file written to {output_file}")
    except Exception as e:
        print(f"Error writing file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
