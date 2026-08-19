#!/bin/bash
# index.css — portiert nach shell
# Quelle: css, OpenClaw@main:src/index.css
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Prüfe, ob ein Parameter übergeben wurde
if [ $# -ne 1 ]; then
    echo "Verwendung: $0 <ausgabedatei>"
    exit 1
fi

# Speichere den übergebenen Parameter in einer Variable
ausgabedatei="$1"

# Erstelle die CSS-Datei mit dem gewünschten Inhalt
cat > "$ausgabedatei" << 'EOF'
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

echo "CSS-Datei wurde erfolgreich erstellt: $ausgabedatei"
