#!/bin/bash
# offscreen.html — portiert nach shell
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion:release/0.7.1/tiktok-live-companion-extension-0.7.1/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
# auch in: Projects@TikTok-Live-Companion-Android:release/0.7.1/tiktok-live-companion-extension-0.7.1/offscreen.html
# auch in: 2 weiteren Fundstellen
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Parameter prüfen
if [[ $# -ne 1 ]]; then
  echo "Verwendung: $0 <ausgabedatei>" >&2
  exit 1
fi

ausgabedatei="$1"

# HTML-Dokument generieren
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
