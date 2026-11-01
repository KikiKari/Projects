#!/bin/bash
# status-overview.html — portiert nach shell
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
# Erzeugt: 2026-11-01 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Parameter prüfen
if [ $# -ne 1 ]; then
    echo "Aufruf: $0 <Ausgabedatei>" >&2
    exit 1
fi

ausgabedatei="$1"

# HTML-Dokument generieren
cat > "$ausgabedatei" << 'EOF'
<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>STATUS-Overview</title>
<link rel="stylesheet" href="status-overview.css">
</head>
<body>
<main id="grid" aria-label="LIVE-Übersicht"></main>
<script src="vendor-mpegts.js"></script>
<script src="status-overview-player.js"></script>
</body>
</html>
EOF
