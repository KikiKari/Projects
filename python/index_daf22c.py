#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "7d6ea2578e361d79995335cb6b5c5a5e90bca6e75ab7bc0b1313639f556d337f", "source_sha256": "daf22c296c801d3d533083361cc59fbdc22e5bfe528aa4bad1973b54cc5448a4", "target_language": "python"}
# index.css — portiert nach python
# Quelle: css, OpenClaw@main:src/index.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import sys

def generate_css():
    """Generate the CSS content as a string."""
    css_content = """body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
"""
    return css_content

def write_css_to_file(filename):
    """Write the generated CSS to a file."""
    css_content = generate_css()
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(css_content)

def main():
    if len(sys.argv) != 2:
        print("Usage: python script.py <output_filename>")
        sys.exit(1)
    
    output_filename = sys.argv[1]
    write_css_to_file(output_filename)
    print(f"CSS file '{output_filename}' has been generated.")

if __name__ == "__main__":
    main()
