#!/bin/bash
# offscreen.html — portiert nach shell
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Prüfe, ob ein Parameter übergeben wurde
if [ $# -eq 0 ]; then
    echo "Fehler: Kein Ausgabepfad angegeben" >&2
    exit 1
fi

# Speichere den übergebenen Pfad
output_path="$1"

# Erzeuge das HTML-Dokument strukturiert
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
