#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "e65178f2c2a96e42d93391ff477b8e85602c8938f46c53f856c0bc9d398ac2ae", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "shell"}
# index.html — portiert nach shell
# Quelle: html, Projects@Program-Derivation:public/index.html
# auch in: Projects@Vision-Check:public/index.html
# auch in: Projects@Weather-Check:public/index.html
# auch in: Projects@abstractions:public/index.html
# auch in: 5 weiteren Fundstellen
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Prüfe, ob ein Dateiname übergeben wurde
if [ $# -ne 1 ]; then
    echo "Verwendung: $0 <dateiname>" >&2
    exit 1
fi

datei="$1"

# Erstelle das HTML-Dokument
{
    echo '<!DOCTYPE html>'
    echo '<html lang="de">'
    echo '<head>'
    echo '<meta charset="utf-8">'
    echo '<meta name="viewport" content="width=device-width, initial-scale=1">'
    echo '<meta http-equiv="refresh" content="0; url=3d.html">'
    echo '<title>Weiterleitung zur 3D-Ansicht</title>'
    echo '<link rel="canonical" href="3d.html">'
    echo '<script>location.replace('"'"'3d.html'"'"');</script>'
    echo '</head>'
    echo '<body>'
    echo '<p><a href="3d.html">3D-Ansicht öffnen</a></p>'
    echo '</body>'
    echo '</html>'
} > "$datei"
