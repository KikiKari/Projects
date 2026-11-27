#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "2526ad1b51b0f1ab6aae05fb470c4a2d3ffbf21cda077b1c8b7273e7cf7217ad", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "shell"}
# offscreen.html — portiert nach shell
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Prüfe, ob ein Parameter übergeben wurde
if [ $# -eq 0 ]; then
    echo "Fehler: Kein Ausgabepfad angegeben" >&2
    exit 1
fi

# Speichere den übergebenen Pfad
output_path="$1"

# Erzeuge das HTML-Dokument
cat > "$output_path" << 'EOF'
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>TikTok LIVE Companion Sprachausgabe</title>
</head>
<body>
  <script src="offscreen.js"></script>
</body>
</html>
EOF

echo "HTML-Dokument erfolgreich erstellt: $output_path"
