#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "33465db500ae681e37d992d4f20b0a6356b484d2be4e075b05a07a535f23a000", "source_sha256": "08fdd65a33a6ec90261b4ce48be82ca8338400da1b321dfc70a57bedabfa45aa", "target_language": "shell"}
# App.css — portiert nach shell
# Quelle: css, OpenClaw@main:src/App.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Prüfe, ob ein Dateiname übergeben wurde
if [[ $# -ne 1 ]]; then
    echo "Verwendung: $0 <ausgabedatei>"
    exit 1
fi

output_file="$1"

# Funktion zum Schreiben von CSS-Regeln
write_rule() {
    local selector="$1"
    shift
    local properties=("$@")
    
    echo "$selector {" >> "$output_file"
    for prop in "${properties[@]}"; do
        echo "  $prop;" >> "$output_file"
    done
    echo "}" >> "$output_file"
    echo "" >> "$output_file"
}

# Leere die Ausgabedatei oder erstelle sie
> "$output_file"

# Root-Definitionen
echo ":root {" >> "$output_file"
echo "  color-scheme: dark;" >> "$output_file"
echo "  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif;" >> "$output_file"
echo "  background: #0b1020;" >> "$output_file"
echo "  color: #eef2ff;" >> "$output_file"
echo "}" >> "$output_file"
echo "" >> "$output_file"

# Universelle Regel
echo "* {" >> "$output_file"
echo "  box-sizing: border-box;" >> "$output_file"
echo "}" >> "$output_file"
echo "" >> "$output_file"

# Body-Stil
echo "body {" >> "$output_file"
echo "  margin: 0;" >> "$output_file"
echo "  min-width: 320px;" >> "$output_file"
echo "  min-height: 100vh;" >> "$output_file"
echo "  background:" >> "$output_file"
echo "    radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem)," >> "$output_file"
echo "    radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem)," >> "$output_file"
echo "    linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%);" >> "$output_file"
echo "}" >> "$output_file"
echo "" >> "$output_file"

# Page Shell
write_rule ".page-shell" \
    "min-height: 100vh" \
    "display: grid" \
    "place-items: center" \
    "padding: 2rem"

# Hero Card
write_rule ".hero-card" \
    "width: min(100%, 56rem)" \
    "padding: clamp(2rem, 6vw, 4.5rem)" \
    "border: 1px solid rgba(148, 163, 184, 0.28)" \
    "border-radius: 2rem" \
    "background: rgba(15, 23, 42, 0.72)" \
    "box-shadow: 0 2rem 6rem rgba(0, 0, 0, 0.35)" \
    "backdrop-filter: blur(18px)"

# Eyebrow
write_rule ".eyebrow" \
    "margin: 0 0 1rem" \
    "color: #67e8f9" \
    "font-size: 0.8rem" \
    "font-weight: 700" \
    "letter-spacing: 0.18em" \
    "text-transform: uppercase"

# Überschrift h1
echo "h1 {" >> "$output_file"
echo "  margin: 0;" >> "$output_file"
echo "  max-width: 12ch;" >> "$output_file"
echo "  font-size: clamp(2.75rem, 8vw, 6rem);" >> "$output_file"
echo "  line-height: 0.95;" >> "$output_file"
echo "  letter-spacing: -0.06em;" >> "$output_file"
echo "}" >> "$output_file"
echo "" >> "$output_file"

# Lead Text
write_rule ".lead" \
    "margin: 1.5rem 0 0" \
    "max-width: 42rem" \
    "color: #cbd5e1" \
    "font-size: clamp(1.05rem, 2vw, 1.35rem)" \
    "line-height: 1.65"

# Link Grid Container
echo ".link-grid {" >> "$output_file"
echo "  display: grid;" >> "$output_file"
echo "  gap: 0.85rem;" >> "$output_file"
echo "  margin-top: 2rem;" >> "$output_file"
echo "}" >> "$output_file"
echo "" >> "$output_file"

# Link Grid Elemente
echo ".link-grid a {" >> "$output_file"
echo "  display: flex;" >> "$output_file"
echo "  align-items: center;" >> "$output_file"
echo "  justify-content: space-between;" >> "$output_file"
echo "  gap: 1rem;" >> "$output_file"
echo "  padding: 1rem 1.15rem;" >> "$output_file"
echo "  border: 1px solid rgba(148, 163, 184, 0.25);" >> "$output_file"
echo "  border-radius: 1rem;" >> "$output_file"
echo "  color: #f8fafc;" >> "$output_file"
echo "  text-decoration: none;" >> "$output_file"
echo "  background: rgba(255, 255, 255, 0.06);" >> "$output_file"
echo "}" >> "$output_file"
echo "" >> "$output_file"

# Hover & Focus für Links
echo ".link-grid a:hover," >> "$output_file"
echo ".link-grid a:focus-visible {" >> "$output_file"
echo "  border-color: rgba(103, 232, 249, 0.75);" >> "$output_file"
echo "  outline: none;" >> "$output_file"
echo "  background: rgba(103, 232, 249, 0.12);" >> "$output_file"
echo "}" >> "$output_file"
echo "" >> "$output_file"
