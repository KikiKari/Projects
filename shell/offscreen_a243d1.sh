#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "a2e6d9fa53fa715caec65588c0199ada7c0e936e2ebeb3be2cd285a08a4846fb", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "shell"}
# offscreen.html — portiert nach shell
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Prüfe, ob ein Parameter übergeben wurde
if [ $# -eq 0 ]; then
    echo "Fehler: Kein Ausgabepfad angegeben" >&2
    echo "Aufruf: $0 <ausgabedatei>" >&2
    exit 1
fi

# Speichere den Ausgabepfad
ausgabedatei="$1"

# Erzeuge das HTML-Dokument
cat > "$ausgabedatei" << 'EOF'
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

echo "HTML-Dokument erfolgreich erstellt: $ausgabedatei"
