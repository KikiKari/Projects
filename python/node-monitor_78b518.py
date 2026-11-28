#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "d030d8c0792de952a90703cb69741fb2267b79d502d81827622b87e91e4ccf01", "source_sha256": "78b518f6f68bf0f05a573239d113470b3f5a9440be7cff5f80bc8576462525c3", "target_language": "python"}
# node-monitor.css — portiert nach python
# Quelle: css, Projects@abstractions:css/node-monitor.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

import sys
import argparse


def generate_css():
    """Generates the CSS content as a string."""
    css_content = """\
:root {{
  --bg: #0d1117;
  --surface: #161b22;
  --border: #30363d;
  --text: #e6edf3;
  --green: #3fb950;
  --red: #f85149;
  --accent: #58a6ff;
}}

* {{
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}}

body {{
  background: var(--bg);
  color: var(--text);
  font-family: -apple-system, sans-serif;
  padding: 1.5rem;
}}

h1 {{
  color: var(--accent);
  margin-bottom: 1rem;
  font-size: 1.2rem;
}}

canvas {{
  display: block;
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--surface);
}}

#log {{
  margin-top: 1rem;
  height: 140px;
  overflow-y: auto;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: .75rem;
  font-size: .78rem;
  font-family: monospace;
  color: #8b949e;
}}

#log .err {{
  color: var(--red);
}}

#log .ok {{
  color: var(--green);
}}
"""
    return css_content


def write_css_to_file(filename):
    """Writes the generated CSS to a specified file."""
    css_content = generate_css()
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(css_content)


def main():
    parser = argparse.ArgumentParser(description="Generate node-monitor.css file.")
    parser.add_argument("output_file", help="The path to the output CSS file.")
    args = parser.parse_args()

    write_css_to_file(args.output_file)
    print(f"CSS file written to {args.output_file}")


if __name__ == "__main__":
    main()
