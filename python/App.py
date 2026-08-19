#!/usr/bin/env python3
# App.css — portiert nach python
# Quelle: css, OpenClaw@main:src/App.css
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import sys
from pathlib import Path

def generate_css():
    """Generate the CSS content as a string."""
    css_parts = []
    
    # Root styles
    css_parts.append(":root {")
    css_parts.append("  color-scheme: dark;")
    css_parts.append("  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif;")
    css_parts.append("  background: #0b1020;")
    css_parts.append("  color: #eef2ff;")
    css_parts.append("}")
    css_parts.append("")
    
    # Universal selector
    css_parts.append("* {")
    css_parts.append("  box-sizing: border-box;")
    css_parts.append("}")
    css_parts.append("")
    
    # Body styles
    css_parts.append("body {")
    css_parts.append("  margin: 0;")
    css_parts.append("  min-width: 320px;")
    css_parts.append("  min-height: 100vh;")
    css_parts.append("  background:")
    css_parts.append("    radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem),")
    css_parts.append("    radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem),")
    css_parts.append("    linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%);")
    css_parts.append("}")
    css_parts.append("")
    
    # Page shell
    css_parts.append(".page-shell {")
    css_parts.append("  min-height: 100vh;")
    css_parts.append("  display: grid;")
    css_parts.append("  place-items: center;")
    css_parts.append("  padding: 2rem;")
    css_parts.append("}")
    css_parts.append("")
    
    # Hero card
    css_parts.append(".hero-card {")
    css_parts.append("  width: min(100%, 56rem);")
    css_parts.append("  padding: clamp(2rem, 6vw, 4.5rem);")
    css_parts.append("  border: 1px solid rgba(148, 163, 184, 0.28);")
    css_parts.append("  border-radius: 2rem;")
    css_parts.append("  background: rgba(15, 23, 42, 0.72);")
    css_parts.append("  box-shadow: 0 2rem 6rem rgba(0, 0, 0, 0.35);")
    css_parts.append("  backdrop-filter: blur(18px);")
    css_parts.append("}")
    css_parts.append("")
    
    # Eyebrow
    css_parts.append(".eyebrow {")
    css_parts.append("  margin: 0 0 1rem;")
    css_parts.append("  color: #67e8f9;")
    css_parts.append("  font-size: 0.8rem;")
    css_parts.append("  font-weight: 700;")
    css_parts.append("  letter-spacing: 0.18em;")
    css_parts.append("  text-transform: uppercase;")
    css_parts.append("}")
    css_parts.append("")
    
    # Heading
    css_parts.append("h1 {")
    css_parts.append("  margin: 0;")
    css_parts.append("  max-width: 12ch;")
    css_parts.append("  font-size: clamp(2.75rem, 8vw, 6rem);")
    css_parts.append("  line-height: 0.95;")
    css_parts.append("  letter-spacing: -0.06em;")
    css_parts.append("}")
    css_parts.append("")
    
    # Lead paragraph
    css_parts.append(".lead {")
    css_parts.append("  margin: 1.5rem 0 0;")
    css_parts.append("  max-width: 42rem;")
    css_parts.append("  color: #cbd5e1;")
    css_parts.append("  font-size: clamp(1.05rem, 2vw, 1.35rem);")
    css_parts.append("  line-height: 1.65;")
    css_parts.append("}")
    css_parts.append("")
    
    # Link grid container
    css_parts.append(".link-grid {")
    css_parts.append("  display: grid;")
    css_parts.append("  gap: 0.85rem;")
    css_parts.append("  margin-top: 2rem;")
    css_parts.append("}")
    css_parts.append("")
    
    # Link grid items
    css_parts.append(".link-grid a {")
    css_parts.append("  display: flex;")
    css_parts.append("  align-items: center;")
    css_parts.append("  justify-content: space-between;")
    css_parts.append("  gap: 1rem;")
    css_parts.append("  padding: 1rem 1.15rem;")
    css_parts.append("  border: 1px solid rgba(148, 163, 184, 0.25);")
    css_parts.append("  border-radius: 1rem;")
    css_parts.append("  color: #f8fafc;")
    css_parts.append("  text-decoration: none;")
    css_parts.append("  background: rgba(255, 255, 255, 0.06);")
    css_parts.append("}")
    css_parts.append("")
    
    # Link hover and focus states
    css_parts.append(".link-grid a:hover,")
    css_parts.append(".link-grid a:focus-visible {")
    css_parts.append("  border-color: rgba(103, 232, 249, 0.75);")
    css_parts.append("  outline: none;")
    css_parts.append("  background: rgba(103, 232, 249, 0.12);")
    css_parts.append("}")
    
    return "\n".join(css_parts)

def main():
    """Main function to write CSS to file or stdout."""
    if len(sys.argv) > 1:
        output_file = Path(sys.argv[1])
        output_file.write_text(generate_css(), encoding='utf-8')
    else:
        print(generate_css())

if __name__ == "__main__":
    main()
