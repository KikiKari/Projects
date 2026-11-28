#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "6d27496d9f2b0240cf6b685689b7a7e662f59bf7dc6954e0b353d473b6f9b7ed", "source_sha256": "a19d3a3ec8b016d9d04f485dc499f8ad715431708b02863f2ac58f3208061edd", "target_language": "python"}
# peak-limiter.css — portiert nach python
# Quelle: css, Projects@abstractions:css/peak-limiter.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import sys
from pathlib import Path

def generate_css():
    """Generates the peak-limiter.css content programmatically"""
    css_rules = []
    
    # Add comments
    css_rules.append("/* abstraction-provenance: {\"artifact_sha256\": \"3f2b97b726a0a4643711dc1dc285df9b75511cc4f35fbe168e178bf60aeaa00d\", \"source_sha256\": \"162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b\", \"target_language\": \"css\"} */")
    css_rules.append("/* peak-limiter.html — portiert nach css */")
    css_rules.append("/* Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html */")
    css_rules.append("/* auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html */")
    css_rules.append("/* auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html */")
    css_rules.append("/* auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html */")
    css_rules.append("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */")
    css_rules.append("")
    
    # Body rule
    css_rules.append("body {")
    css_rules.append("  font: 16px system-ui;")
    css_rules.append("  max-width: 1000px;")
    css_rules.append("  margin: 40px auto;")
    css_rules.append("  padding: 20px;")
    css_rules.append("}")
    css_rules.append("")
    
    # Pre rule
    css_rules.append("pre {")
    css_rules.append("  white-space: pre-wrap;")
    css_rules.append("}")
    css_rules.append("")
    
    # Button rule
    css_rules.append("button {")
    css_rules.append("  padding: 12px;")
    css_rules.append("}")
    
    return "\n".join(css_rules)

def main(output_file):
    """Main function to write CSS to output file"""
    css_content = generate_css()
    Path(output_file).write_text(css_content, encoding='utf-8')

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 peak-limiter.py <output-file>")
        sys.exit(1)
    
    main(sys.argv[1])
