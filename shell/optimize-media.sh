#!/bin/bash
# optimize-media.mjs — portiert nach shell
# Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Bestimme das Verzeichnis des Skripts und gehe zum Zielverzeichnis
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEDIA_DIR="$SCRIPT_DIR/../public/media"

# Prüfe, ob das Verzeichnis existiert
if [[ ! -d "$MEDIA_DIR" ]]; then
  echo "Fehler: Verzeichnis $MEDIA_DIR existiert nicht." >&2
  exit 1
fi

# Verarbeite alle PNG-Dateien im Verzeichnis
for file in "$MEDIA_DIR"/*.png; do
  # Überspringe, wenn keine PNG-Dateien gefunden wurden
  [[ -e "$file" ]] || continue

  # Extrahiere den Basisnamen ohne Erweiterung
  stem="${file%.png}"

  # Konvertiere zu WebP
  if command -v cwebp >/dev/null 2>&1; then
    cwebp -q 84 "$file" -o "${stem}.webp"
  else
    echo "Warnung: cwebp nicht gefunden, überspringe WebP-Konvertierung für $file" >&2
  fi

  # Konvertiere zu AVIF
  if command -v avifenc >/dev/null 2>&1; then
    avifenc --min 20 --max 40 --minalpha 20 --maxalpha 40 "$file" "${stem}.avif"
  else
    echo "Warnung: avifenc nicht gefunden, überspringe AVIF-Konvertierung für $file" >&2
  fi
done

echo "WebP- und AVIF-Derivate erzeugt."
