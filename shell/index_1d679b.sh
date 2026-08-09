#!/bin/bash
# index.html — portiert nach shell
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# auch in: Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Parameter: Ausgabedatei
output_file="${1:-}"

if [[ -z "$output_file" ]]; then
  echo "Fehler: Keine Ausgabedatei angegeben." >&2
  echo "Aufruf: $0 <ausgabedatei>" >&2
  exit 1
fi

# Erzeuge das HTML-Dokument
cat > "$output_file" << 'EOF'
<!doctype html>
<html lang="de">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.7.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />
    <meta name="theme-color" content="#ffffff" />
    <title>TikTok LIVE Companion – Dokumentation</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

echo "HTML-Dokument erfolgreich in '$output_file' geschrieben."
