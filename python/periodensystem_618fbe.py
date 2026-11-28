#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "ba2a9d5260640dfdd62a4480e28c4703f92be3da62065611f19686dd6cb395d7", "source_sha256": "618fbec1aa70b1376cdfa3b8809f339c78f591a33e1ef35fb84ee21ffcdc97cf", "target_language": "python"}
# periodensystem.css — portiert nach python
# Quelle: css, Projects@abstractions:css/periodensystem.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import sys

def generate_css():
    """Generates the complete CSS content as a string"""
    
    # Base styles
    css = """/* abstraction-provenance: {"artifact_sha256": "57a7240136c3ce381e11df3125a02154266008c65c09f97475511fe273d71a65", "source_sha256": "dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb", "target_language": "css"} */
/* periodensystem.html — portiert nach css */
/* Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html */
/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */

* { box-sizing: border-box; margin: 0; padding: 0; }
:root {
  --bg: #fafaf7;
  --surface: #ffffff;
  --border: rgba(0,0,0,0.12);
  --text: #1a1a1a;
  --text-muted: #666;
}
"""
    
    # Dark mode media query
    css += """@media (prefers-color-scheme: dark) {
  :root {
    --bg: #1a1a1a;
    --surface: #242424;
    --border: rgba(255,255,255,0.15);
    --text: #f0f0f0;
    --text-muted: #aaa;
  }
}
"""
    
    # Body and typography
    css += """body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
  background: var(--bg);
  color: var(--text);
  padding: 24px;
  max-width: 1100px;
  margin: 0 auto;
  line-height: 1.5;
}
h1 { font-size: 22px; font-weight: 500; margin-bottom: 4px; }
.subtitle { color: var(--text-muted); font-size: 14px; margin-bottom: 20px; }
"""
    
    # Detail section
    css += """.detail {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 16px 20px;
  min-height: 110px;
  display: flex;
  align-items: center;
  gap: 20px;
  margin-bottom: 16px;
}
.detail-empty {
  color: var(--text-muted);
  font-size: 14px;
  text-align: center;
  width: 100%;
}
"""
    
    # Symbol box and info
    css += """.symbol-box {
  font-size: 40px;
  font-weight: 500;
  line-height: 1;
  width: 80px;
  height: 80px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  flex-shrink: 0;
}
.info-name { font-size: 20px; font-weight: 500; margin-bottom: 8px; }
.info-meta {
  font-size: 13px;
  color: var(--text-muted);
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 4px 24px;
}
.info-meta b { font-weight: 500; color: var(--text); margin-left: 6px; }
"""
    
    # Grid layout
    css += """.grid {
  display: grid;
  grid-template-columns: repeat(18, minmax(0, 1fr));
  gap: 3px;
}
.fgrid { margin-top: 8px; }
"""
    
    # Cell styling
    css += """.cell {
  aspect-ratio: 1;
  border-radius: 4px;
  padding: 3px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-family: inherit;
  line-height: 1;
  transition: transform 0.12s ease;
  border: 0;
  position: relative;
  overflow: hidden;
}
.cell:hover { transform: scale(1.18); z-index: 5; box-shadow: 0 2px 8px rgba(0,0,0,0.15); }
.cell:focus-visible { outline: 2px solid var(--text); outline-offset: 1px; }
.cell.active { outline: 2px solid var(--text); outline-offset: 1px; z-index: 4; }
.cell .num { font-size: 9px; opacity: 0.75; align-self: flex-start; line-height: 1; padding-left: 2px; }
.cell .sym { font-size: 14px; font-weight: 500; margin-top: 2px; }
"""
    
    # Marker cells
    css += """.cell-marker {
  cursor: default;
  font-size: 9px;
  font-weight: 500;
  border: 1px dashed currentColor;
  background: transparent !important;
}
.cell-marker:hover { transform: none; box-shadow: none; }
"""
    
    # Category colors - light mode
    categories_light = {
        'cat-am': ('#FCEBEB', '#501313'),
        'cat-em': ('#FAEEDA', '#412402'),
        'cat-tm': ('#E6F1FB', '#042C53'),
        'cat-ptm': ('#F1EFE8', '#2C2C2A'),
        'cat-hm': ('#E1F5EE', '#04342C'),
        'cat-nm': ('#EAF3DE', '#173404'),
        'cat-h': ('#EEEDFE', '#26215C'),
        'cat-eg': ('#FBEAF0', '#4B1528'),
        'cat-la': ('#FAECE7', '#4A1B0C'),
        'cat-ac': ('#F5C4B3', '#4A1B0C')
    }
    
    for cat, (bg, color) in categories_light.items():
        css += f".{cat} {{ background: {bg}; color: {color}; }}\n"
    
    # Category colors - dark mode
    css += """@media (prefers-color-scheme: dark) {
"""
    
    categories_dark = {
        'cat-am': ('#791F1F', '#F7C1C1'),
        'cat-em': ('#633806', '#FAC775'),
        'cat-tm': ('#0C447C', '#B5D4F4'),
        'cat-ptm': ('#444441', '#D3D1C7'),
        'cat-hm': ('#085041', '#9FE1CB'),
        'cat-nm': ('#27500A', '#C0DD97'),
        'cat-h': ('#3C3489', '#CECBF6'),
        'cat-eg': ('#72243E', '#F4C0D1'),
        'cat-la': ('#712B13', '#F5C4B3'),
        'cat-ac': ('#993C1D', '#F5C4B3')
    }
    
    for cat, (bg, color) in categories_dark.items():
        css += f"  .{cat} {{ background: {bg}; color: {color}; }}\n"
    
    css += "}\n"
    
    # Legend
    css += """.legend {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 8px 16px;
  margin-top: 24px;
  font-size: 12px;
  color: var(--text-muted);
}
.legend-item { display: flex; align-items: center; gap: 8px; }
.legend-swatch { width: 14px; height: 14px; border-radius: 3px; flex-shrink: 0; }
"""
    
    return css

def main():
    if len(sys.argv) != 2:
        print("Usage: python periodensystem.py <output_file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    css_content = generate_css()
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(css_content)

if __name__ == "__main__":
    main()
