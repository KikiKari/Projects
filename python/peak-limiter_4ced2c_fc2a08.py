#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "5ceabf83b8f3d542ae5b63bbd4a64c29b75af0f9c1736e74d0053ef01e5ff649", "source_sha256": "fc2a08fec30e381e2f112d375f3c1136b4730cdaa58967167750a5dc9b65532d", "target_language": "python"}
# peak-limiter_4ced2c.css — portiert nach python
# Quelle: css, Projects@abstractions:css/peak-limiter_4ced2c.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import sys
from pathlib import Path

def generate_css():
    """Generate the CSS content as a string."""
    css_content = [
        "/* abstraction-provenance: {\"artifact_sha256\": \"c86160b4782bbdd4341a998965a2c305098b3c29f36c24b5c96324073afc4800\", \"source_sha256\": \"4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0\", \"target_language\": \"css\"} */",
        "/* peak-limiter.html — portiert nach css */",
        "/* Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html */",
        "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */",
        "",
        "body {",
        "  font: 16px system-ui;",
        "  max-width: 1000px;",
        "  margin: 40px auto;",
        "  padding: 20px;",
        "}",
        "",
        "pre {",
        "  white-space: pre-wrap;",
        "}",
        "",
        "button {",
        "  padding: 12px;",
        "}"
    ]
    return "\n".join(css_content)

def write_css_to_file(filename):
    """Write the generated CSS to a file."""
    css_content = generate_css()
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(css_content)

def main():
    if len(sys.argv) != 2:
        print("Usage: {} <output_file>".format(sys.argv[0]))
        sys.exit(1)
    
    output_file = sys.argv[1]
    write_css_to_file(output_file)
    print(f"CSS file written to {output_file}")

if __name__ == "__main__":
    main()
