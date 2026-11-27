#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "1e6777d9335cf8d6ba64abf7b356c7e9d226d1275c4ac62925a59ba0aac274c6", "source_sha256": "7fc810e8bcb817cb81407c2ad604d4bd70dce9f3ff8cb2bbfbcacfec00febd1c", "target_language": "shell"}
# status-overview.html — portiert nach shell
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

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

echo "HTML-Dokument wurde erfolgreich in '$output_file' geschrieben."
