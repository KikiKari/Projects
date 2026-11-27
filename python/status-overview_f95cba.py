#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "12a604e482c675613d060c939b84b3a5e51bec1a20dcf2e9e099d81799bbf3c8", "source_sha256": "f95cba00197f4650dddde02431fe14a0ca1baea932052e66b16f5778582e944f", "target_language": "python"}
# status-overview.css — portiert nach python
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import sys

def generate_css():
    """Generates the complete CSS content as a string."""
    css_parts = []
    
    # Universal selector and base styles
    css_parts.append("*{box-sizing:border-box}")
    css_parts.append("html,body{margin:0;min-height:100%;background:#101015;color:#fff;font:14px system-ui,sans-serif}")
    css_parts.append("body{display:flex;flex-direction:column;height:100vh}")
    
    # Header styles
    css_parts.append("header{display:flex;gap:1em;align-items:baseline;padding:0 12px}")
    css_parts.append("h1{font-size:17px;margin:8px 0}")
    css_parts.append("header p{font-size:12px;color:#bbb;margin:0}")
    
    # Main grid layout
    css_parts.append("main{flex:1;min-height:0;display:grid;grid-template-columns:repeat(3,minmax(0,1fr));grid-template-rows:repeat(3,minmax(0,1fr));gap:4px;padding:0}")
    
    # Tile component styles
    css_parts.append(".tile{min-width:0;min-height:0;display:flex;flex-direction:column;background:#202026;border:1px solid #393940}")
    css_parts.append(".tile h2{font-size:13px;margin:3px 8px}")
    css_parts.append(".tile video{min-height:0;width:100%;flex:1;object-fit:contain;background:#000}")
    css_parts.append(".tile p{font-size:11px;margin:3px 8px;color:#ddd}")
    
    # Alternative grid layout
    css_parts.append("main.grid2{grid-template-columns:repeat(2,minmax(0,1fr));grid-template-rows:repeat(2,minmax(0,1fr))}")
    
    # Hidden attribute handling
    css_parts.append(".tile[hidden]{display:none}")
    
    return "".join(css_parts)

def write_css_to_file(filename):
    """Writes the generated CSS to the specified file."""
    css_content = generate_css()
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(css_content)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <output_filename>")
        sys.exit(1)
    
    output_filename = sys.argv[1]
    write_css_to_file(output_filename)
