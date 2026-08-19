#!/usr/bin/env python3
# index.css — portiert nach python
# Quelle: css, OpenClaw@main:src/index.css
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import sys
from pathlib import Path

def generate_css():
    """Generate the CSS content as a structured document."""
    css_rules = {
        'body': {
            'margin': '0',
            'font-family': "-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif",
            '-webkit-font-smoothing': 'antialiased',
            '-moz-osx-font-smoothing': 'grayscale'
        },
        'code': {
            'font-family': "source-code-pro, Menlo, Monaco, Consolas, 'Courier New', monospace"
        }
    }
    
    # Build CSS output
    output = []
    for selector, properties in css_rules.items():
        output.append(f"{selector} {{")
        for prop, value in properties.items():
            output.append(f"  {prop}: {value};")
        output.append("}")
        output.append("")  # Empty line after each rule
    
    return '\n'.join(output[:-1])  # Remove last empty line

def main(output_file=None):
    """Main function to write CSS to file or stdout."""
    css_content = generate_css()
    
    if output_file:
        Path(output_file).write_text(css_content)
    else:
        print(css_content)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        main(sys.argv[1])
    else:
        main()
