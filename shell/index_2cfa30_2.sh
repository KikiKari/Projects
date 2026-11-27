#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "00cf52cb80e0002d72e269e99c90b27325ae8927c4f641b16e6884d94c731020", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "shell"}
# index.html — portiert nach shell
# Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Überprüfe, ob ein Parameter übergeben wurde
if [[ $# -ne 1 ]]; then
    echo "Verwendung: $0 <ausgabedatei>" >&2
    exit 1
fi

# Speichere den übergebenen Dateinamen
output_file="$1"

# Erzeuge das HTML-Dokument
{
    echo '<!doctype html>'
    echo '<html lang="de">'
    echo '  <head>'
    echo '    <meta charset="UTF-8" />'
    echo '    <meta name="viewport" content="width=device-width, initial-scale=1.0" />'
    echo '    <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />'
    echo '    <meta name="theme-color" content="#ffffff" />'
    echo '    <link rel="icon" type="image/png" href="/branding/staenderglobus-ios.png" />'
    echo '    <link rel="apple-touch-icon" href="/branding/staenderglobus-ios.png" />'
    echo '    <title>TikTok LIVE Companion – Dokumentation</title>'
    echo '  </head>'
    echo '  <body>'
    echo '    <div id="root"></div>'
    echo '    <script type="module" src="/src/main.tsx"></script>'
    echo '  </body>'
    echo '</html>'
} > "$output_file"

echo "HTML-Dokument erfolgreich in '$output_file' erstellt."
