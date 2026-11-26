#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "363ba69fd74d5de0ffe3f8d697d3e1644c86b3ab3634ba70293ea81c4366f844", "source_sha256": "daf22c296c801d3d533083361cc59fbdc22e5bfe528aa4bad1973b54cc5448a4", "target_language": "shell"}
# index.css — portiert nach shell
# Quelle: css, OpenClaw@main:src/index.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Function to generate the CSS content
generate_css() {
    cat <<'EOF'
body {
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
EOF
}

# Check if output file parameter is provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <output_file>" >&2
    exit 1
fi

# Generate CSS and write to specified file
generate_css > "$1"
