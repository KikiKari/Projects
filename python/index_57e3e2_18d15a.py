#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "ed13afbe9f92d3cccb3d3ad5170b452ff15c39b5ba0816ac903510b82fcf8095", "source_sha256": "18d15a289b831c9da96c808e0cc1de4dae7bf3dfc35a804a239a992cd82cde89", "target_language": "python"}
# index_57e3e2.css — portiert nach python
# Quelle: css, Projects@abstractions:css/index_57e3e2.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import sys
from pathlib import Path

def generate_css():
    """Generate the CSS content programmatically"""
    
    # Root variables
    css_parts = []
    
    # Comments
    css_parts.append("/* abstraction-provenance: {\"artifact_sha256\": \"a05439af4536c91ed01734c3151c3870ffe206fc2433d74fe3db29d4666579ca\", \"source_sha256\": \"57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c\", \"target_language\": \"css\"} */")
    css_parts.append("/* index.html — portiert nach css */")
    css_parts.append("/* Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html */")
    css_parts.append("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */")
    css_parts.append("")
    
    # Root
    css_parts.append(":root {")
    css_parts.append("  color-scheme: light;")
    css_parts.append("}")
    css_parts.append("")
    
    # Universal selector
    css_parts.append("* {")
    css_parts.append("  box-sizing: border-box;")
    css_parts.append("}")
    css_parts.append("")
    
    # Body
    css_parts.append("body {")
    css_parts.append("  margin: 0;")
    css_parts.append("  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif;")
    css_parts.append("  background: #f7f7f5;")
    css_parts.append("  color: #1d1c1a;")
    css_parts.append("}")
    css_parts.append("")
    
    # Wrap
    css_parts.append(".wrap {")
    css_parts.append("  max-width: 880px;")
    css_parts.append("  margin: 0 auto;")
    css_parts.append("  padding: 20px 16px 60px;")
    css_parts.append("}")
    css_parts.append("")
    
    # Headings
    css_parts.append("h1 {")
    css_parts.append("  font-size: 22px;")
    css_parts.append("  margin: 0 0 2px;")
    css_parts.append("}")
    css_parts.append("")
    
    # Sub
    css_parts.append(".sub {")
    css_parts.append("  color: #6b6a66;")
    css_parts.append("  font-size: 13px;")
    css_parts.append("  margin-bottom: 16px;")
    css_parts.append("}")
    css_parts.append("")
    
    # Bar
    css_parts.append(".bar {")
    css_parts.append("  display: flex;")
    css_parts.append("  gap: 10px;")
    css_parts.append("  align-items: center;")
    css_parts.append("  margin-bottom: 16px;")
    css_parts.append("  flex-wrap: wrap;")
    css_parts.append("}")
    css_parts.append("")
    
    # Buttons
    css_parts.append("button {")
    css_parts.append("  font-size: 13px;")
    css_parts.append("  font-weight: 600;")
    css_parts.append("  padding: 7px 13px;")
    css_parts.append("  border: 1px solid #d9d8d3;")
    css_parts.append("  border-radius: 8px;")
    css_parts.append("  background: #fff;")
    css_parts.append("  cursor: pointer;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append("button:hover {")
    css_parts.append("  background: #f2f1ec;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append("button.primary {")
    css_parts.append("  background: #1d1c1a;")
    css_parts.append("  color: #fff;")
    css_parts.append("  border-color: #1d1c1a;")
    css_parts.append("}")
    css_parts.append("")
    
    # Note
    css_parts.append(".note {")
    css_parts.append("  background: #fffdf4;")
    css_parts.append("  border: 1px solid #f0e9c8;")
    css_parts.append("  border-radius: 10px;")
    css_parts.append("  padding: 12px 14px;")
    css_parts.append("  font-size: 13px;")
    css_parts.append("  color: #4a4734;")
    css_parts.append("  margin-bottom: 16px;")
    css_parts.append("  line-height: 1.5;")
    css_parts.append("}")
    css_parts.append("")
    
    # Section
    css_parts.append(".section {")
    css_parts.append("  background: #fff;")
    css_parts.append("  border: 1px solid #e8e7e3;")
    css_parts.append("  border-radius: 12px;")
    css_parts.append("  margin-bottom: 14px;")
    css_parts.append("  overflow: hidden;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append(".section > h2 {")
    css_parts.append("  font-size: 15px;")
    css_parts.append("  margin: 0;")
    css_parts.append("  padding: 13px 16px;")
    css_parts.append("  border-bottom: 1px solid #efeee9;")
    css_parts.append("  display: flex;")
    css_parts.append("  align-items: center;")
    css_parts.append("  gap: 9px;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append(".section > h2 .badge {")
    css_parts.append("  margin-left: auto;")
    css_parts.append("  font-size: 12px;")
    css_parts.append("  font-weight: 600;")
    css_parts.append("  background: #efeee9;")
    css_parts.append("  color: #5a5852;")
    css_parts.append("  padding: 2px 9px;")
    css_parts.append("  border-radius: 20px;")
    css_parts.append("}")
    css_parts.append("")
    
    # Body class
    css_parts.append(".body {")
    css_parts.append("  padding: 8px 16px 14px;")
    css_parts.append("  font-size: 14px;")
    css_parts.append("}")
    css_parts.append("")
    
    # Muted
    css_parts.append(".muted {")
    css_parts.append("  color: #8a8884;")
    css_parts.append("}")
    css_parts.append("")
    
    # Error
    css_parts.append(".err {")
    css_parts.append("  color: #c0392b;")
    css_parts.append("}")
    css_parts.append("")
    
    # Key-value pairs
    css_parts.append(".kv {")
    css_parts.append("  display: flex;")
    css_parts.append("  justify-content: space-between;")
    css_parts.append("  padding: 4px 0;")
    css_parts.append("  border-bottom: 1px solid #f4f3ee;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append(".kv:last-child {")
    css_parts.append("  border: none;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append(".kv .k {")
    css_parts.append("  color: #6b6a66;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append(".kv .v {")
    css_parts.append("  font-weight: 600;")
    css_parts.append("}")
    css_parts.append("")
    
    # Links
    css_parts.append("a {")
    css_parts.append("  color: #2b5cc4;")
    css_parts.append("  text-decoration: none;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append("a:hover {")
    css_parts.append("  text-decoration: underline;")
    css_parts.append("}")
    css_parts.append("")
    
    # Modal
    css_parts.append("/* settings modal */")
    css_parts.append(".modal {")
    css_parts.append("  position: fixed;")
    css_parts.append("  inset: 0;")
    css_parts.append("  background: rgba(0, 0, 0, .35);")
    css_parts.append("  display: none;")
    css_parts.append("  align-items: flex-start;")
    css_parts.append("  justify-content: center;")
    css_parts.append("  padding: 40px 16px;")
    css_parts.append("  overflow: auto;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append(".modal.open {")
    css_parts.append("  display: flex;")
    css_parts.append("}")
    css_parts.append("")
    
    # Card
    css_parts.append(".card {")
    css_parts.append("  background: #fff;")
    css_parts.append("  border-radius: 14px;")
    css_parts.append("  max-width: 560px;")
    css_parts.append("  width: 100%;")
    css_parts.append("  padding: 20px;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append(".card h3 {")
    css_parts.append("  margin: 0 0 4px;")
    css_parts.append("  font-size: 17px;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append(".card p.hint {")
    css_parts.append("  margin: 0 0 16px;")
    css_parts.append("  font-size: 12px;")
    css_parts.append("  color: #8a8884;")
    css_parts.append("}")
    css_parts.append("")
    
    # Field
    css_parts.append(".field {")
    css_parts.append("  margin-bottom: 12px;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append(".field label {")
    css_parts.append("  display: block;")
    css_parts.append("  font-size: 12px;")
    css_parts.append("  font-weight: 600;")
    css_parts.append("  color: #5a5852;")
    css_parts.append("  margin-bottom: 3px;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append(".field input {")
    css_parts.append("  width: 100%;")
    css_parts.append("  font-size: 13px;")
    css_parts.append("  padding: 7px 9px;")
    css_parts.append("  border: 1px solid #d9d8d3;")
    css_parts.append("  border-radius: 7px;")
    css_parts.append("  font-family: ui-monospace, Menlo, monospace;")
    css_parts.append("}")
    css_parts.append("")
    
    css_parts.append(".field .desc {")
    css_parts.append("  font-size: 11px;")
    css_parts.append("  color: #a8a6a1;")
    css_parts.append("  margin-top: 2px;")
    css_parts.append("}")
    css_parts.append("")
    
    # Actions
    css_parts.append(".actions {")
    css_parts.append("  display: flex;")
    css_parts.append("  gap: 10px;")
    css_parts.append("  justify-content: flex-end;")
    css_parts.append("  margin-top: 8px;")
    css_parts.append("}")
    css_parts.append("")
    
    # Warning
    css_parts.append(".warn {")
    css_parts.append("  background: #fdf3f3;")
    css_parts.append("  border: 1px solid #f3d9d9;")
    css_parts.append("  color: #9a3b3b;")
    css_parts.append("  border-radius: 8px;")
    css_parts.append("  padding: 10px 12px;")
    css_parts.append("  font-size: 12px;")
    css_parts.append("  margin-bottom: 14px;")
    css_parts.append("}")
    
    return "\n".join(css_parts)

def main():
    """Main function to write CSS to file"""
    if len(sys.argv) != 2:
        print("Usage: python script.py <output_file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    css_content = generate_css()
    
    # Write to file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(css_content)

if __name__ == "__main__":
    main()
