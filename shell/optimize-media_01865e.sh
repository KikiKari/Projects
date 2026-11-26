#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "e50bc3d3273d2de98b21bfa4a2e35bf51bd0344573eec3c1c2fd948a2be226db", "source_sha256": "01865e120d0e52b50fea21a5f976ac63af413e6829f861a5d31d7898bd4dbaf4", "target_language": "shell"}
# optimize-media.mjs — portiert nach shell
# Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Directory containing the media files
directory="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/public/media"

# Check if the directory exists
if [[ ! -d "$directory" ]]; then
    echo "Directory $directory does not exist."
    exit 1
fi

# Process each PNG file in the directory
for file in "$directory"/*.png; do
    # Skip if no files match the pattern
    [[ -e "$file" ]] || continue

    # Get the base name without extension
    stem="${file%.png}"

    # Convert to WebP with quality 84
    convert "$file" -quality 84 "${stem}.webp"

    # Convert to AVIF with quality 58
    convert "$file" -quality 58 "${stem}.avif"
done

echo "WebP- und AVIF-Derivate erzeugt."
