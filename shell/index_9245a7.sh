#!/bin/bash
# index.html — portiert nach shell
# Quelle: html, Projects@Program-Derivation:public/index.html
# auch in: Projects@Vision-Check:public/index.html
# auch in: Projects@Weather-Check:public/index.html
# auch in: Projects@abstractions:public/index.html
# auch in: 5 weiteren Fundstellen
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Prüfe, ob ein Dateiname übergeben wurde
if [ $# -ne 1 ]; then
    echo "Verwendung: $0 <dateiname>" >&2
    exit 1
fi

DATEI="$1"

# Erstelle die HTML-Struktur
{
    echo '<!DOCTYPE html>'
    echo '<html lang="de">'
    echo '<head>'
    echo '<meta charset="utf-8">'
    echo '<meta name="viewport" content="width=device-width, initial-scale=1">'
    echo '<meta http-equiv="refresh" content="0; url=3d.html">'
    echo '<title>Weiterleitung zur 3D-Ansicht</title>'
    echo '<link rel="canonical" href="3d.html">'
    echo '<script>location.replace("3d.html");</script>'
    echo '</head>'
    echo '<body>'
    echo '<p><a href="3d.html">3D-Ansicht öffnen</a></p>'
    echo '</body>'
    echo '</html>'
} > "$DATEI"

echo "HTML-Datei '$DATEI' erfolgreich erstellt."
