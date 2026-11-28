#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "cc53704f9efc214d893f037e840d925854566904b23e105d2c3042d6a1f2b677", "source_sha256": "470ecd5aad55c517d9e61935d3422a32740607ef531514fee63990c26ee64839", "target_language": "python"}
# kontaktbogen.css — portiert nach python
# Quelle: css, Projects@abstractions:css/kontaktbogen.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import sys
from pathlib import Path

def generate_css():
    """Generate the kontaktbogen.css content"""
    
    css_vars = {
        '--bg': '#FAF8F4',
        '--ink': '#1B1A17',
        '--muted': '#6E6A61',
        '--line': '#E5E1D8',
        '--accent': '#A8542F',
        '--accent-2': '#2E7D7B',
        '--surface': '#fff'
    }
    
    css_rules = []
    
    # Add comment header
    css_rules.append("/* abstraction-provenance: {\"artifact_sha256\": \"450641e159859fa2b6c4bef0c3cf3d2fc42700f880b018b48996ee2e02d23ab2\", \"source_sha256\": \"ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187\", \"target_language\": \"css\"} */")
    css_rules.append("/* kontaktbogen.html — portiert nach css */")
    css_rules.append("/* Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html */")
    css_rules.append("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */")
    css_rules.append("")
    
    # :root rule
    css_rules.append(":root {")
    for var, value in css_vars.items():
        css_rules.append(f"  {var}: {value};")
    css_rules.append("}")
    css_rules.append("")
    
    # Universal selector
    css_rules.append("* {")
    css_rules.append("  box-sizing: border-box;")
    css_rules.append("}")
    css_rules.append("")
    
    # Body rule
    css_rules.append("body {")
    css_rules.append("  margin: 0;")
    css_rules.append("  font-family: 'Hanken Grotesk', system-ui, sans-serif;")
    css_rules.append("  background: var(--bg);")
    css_rules.append("  color: var(--ink);")
    css_rules.append("  line-height: 1.5;")
    css_rules.append("}")
    css_rules.append("")
    
    # Header rules
    css_rules.append("header {")
    css_rules.append("  padding: 2.5rem 2rem 1rem;")
    css_rules.append("  border-bottom: 1px solid var(--line);")
    css_rules.append("  background: var(--surface);")
    css_rules.append("  position: sticky;")
    css_rules.append("  top: 0;")
    css_rules.append("  z-index: 10;")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append("header h1 {")
    css_rules.append("  margin: 0 0 .5rem;")
    css_rules.append("  font-family: 'Newsreader', Georgia, serif;")
    css_rules.append("  font-weight: 400;")
    css_rules.append("  font-size: 2.25rem;")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append("header p {")
    css_rules.append("  margin: .25rem 0;")
    css_rules.append("  color: var(--muted);")
    css_rules.append("  max-width: 80ch;")
    css_rules.append("}")
    css_rules.append("")
    
    # Legend rule
    css_rules.append(".legend {")
    css_rules.append("  display: flex;")
    css_rules.append("  gap: 1rem;")
    css_rules.append("  flex-wrap: wrap;")
    css_rules.append("  margin-top: .75rem;")
    css_rules.append("  font-size: .8125rem;")
    css_rules.append("}")
    css_rules.append("")
    
    # Pill rules
    css_rules.append(".pill {")
    css_rules.append("  padding: .15rem .6rem;")
    css_rules.append("  border-radius: 999px;")
    css_rules.append("  border: 1px solid var(--line);")
    css_rules.append("  background: #fff;")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append(".pill.pflicht {")
    css_rules.append("  border-color: var(--accent);")
    css_rules.append("  color: var(--accent);")
    css_rules.append("  font-weight: 600;")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append(".pill.auswahl {")
    css_rules.append("  border-color: var(--accent-2);")
    css_rules.append("  color: var(--accent-2);")
    css_rules.append("  font-weight: 600;")
    css_rules.append("}")
    css_rules.append("")
    
    # Main rule
    css_rules.append("main {")
    css_rules.append("  padding: 2rem;")
    css_rules.append("  max-width: 1400px;")
    css_rules.append("  margin: 0 auto;")
    css_rules.append("}")
    css_rules.append("")
    
    # Section rules
    css_rules.append("section {")
    css_rules.append("  margin: 2.5rem 0;")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append("section h2 {")
    css_rules.append("  font-family: 'Newsreader', serif;")
    css_rules.append("  font-weight: 400;")
    css_rules.append("  font-size: 1.5rem;")
    css_rules.append("  margin: 0 0 .25rem;")
    css_rules.append("  display: flex;")
    css_rules.append("  align-items: center;")
    css_rules.append("  gap: .75rem;")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append("section .sub {")
    css_rules.append("  color: var(--muted);")
    css_rules.append("  font-size: .875rem;")
    css_rules.append("  margin: 0 0 1.25rem;")
    css_rules.append("}")
    css_rules.append("")
    
    # Grid rule
    css_rules.append(".grid {")
    css_rules.append("  display: grid;")
    css_rules.append("  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));")
    css_rules.append("  gap: 1rem;")
    css_rules.append("}")
    css_rules.append("")
    
    # Card rules
    css_rules.append(".card {")
    css_rules.append("  background: var(--surface);")
    css_rules.append("  border: 1px solid var(--line);")
    css_rules.append("  border-radius: 10px;")
    css_rules.append("  overflow: hidden;")
    css_rules.append("  display: flex;")
    css_rules.append("  flex-direction: column;")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append(".card .imgwrap {")
    css_rules.append("  aspect-ratio: 1;")
    css_rules.append("  background: #f1eee7;")
    css_rules.append("  display: flex;")
    css_rules.append("  align-items: center;")
    css_rules.append("  justify-content: center;")
    css_rules.append("  overflow: hidden;")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append(".card img {")
    css_rules.append("  width: 100%;")
    css_rules.append("  height: 100%;")
    css_rules.append("  object-fit: contain;")
    css_rules.append("  background: #fff;")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append(".card .meta {")
    css_rules.append("  padding: .6rem .75rem .75rem;")
    css_rules.append("  font-size: .78125rem;")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append(".card .name {")
    css_rules.append("  font-family: 'JetBrains Mono', monospace;")
    css_rules.append("  font-size: .6875rem;")
    css_rules.append("  color: var(--muted);")
    css_rules.append("  word-break: break-all;")
    css_rules.append("  line-height: 1.3;")
    css_rules.append("  margin-bottom: .35rem;")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append(".card .dims {")
    css_rules.append("  color: var(--muted);")
    css_rules.append("  font-size: .6875rem;")
    css_rules.append("  margin-bottom: .35rem;")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append(".card .prompt {")
    css_rules.append("  color: var(--ink);")
    css_rules.append("  font-size: .75rem;")
    css_rules.append("  line-height: 1.35;")
    css_rules.append("  font-style: italic;")
    css_rules.append("  border-top: 1px solid var(--line);")
    css_rules.append("  padding-top: .4rem;")
    css_rules.append("  margin-top: .35rem;")
    css_rules.append("  max-height: 5.5em;")
    css_rules.append("  overflow: hidden;")
    css_rules.append("}")
    css_rules.append("")
    
    # Tag rules
    css_rules.append(".tag {")
    css_rules.append("  display: inline-block;")
    css_rules.append("  padding: .1rem .45rem;")
    css_rules.append("  border-radius: 999px;")
    css_rules.append("  font-size: .6875rem;")
    css_rules.append("  background: #F1EEE7;")
    css_rules.append("  color: var(--muted);")
    css_rules.append("  margin-right: .25rem;")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append(".tag.p {")
    css_rules.append("  background: #F1E5DD;")
    css_rules.append("  color: var(--accent);")
    css_rules.append("}")
    css_rules.append("")
    
    css_rules.append(".tag.a {")
    css_rules.append("  background: #DEEDEC;")
    css_rules.append("  color: var(--accent-2);")
    css_rules.append("}")
    
    return "\n".join(css_rules)

def main():
    if len(sys.argv) != 2:
        print("Usage: python script.py <output_file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    css_content = generate_css()
    
    # Write to file
    Path(output_file).write_text(css_content, encoding='utf-8')
    print(f"CSS file written to {output_file}")

if __name__ == "__main__":
    main()
