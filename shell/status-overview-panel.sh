#!/bin/bash
# status-overview-panel.css — portiert nach shell
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview-panel.css
# Erzeugt: 2026-11-01 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Ziel: Erzeuge CSS-Inhalt strukturiert und schreibe ihn in eine Datei.

# Prüfe, ob ein Parameter übergeben wurde
if [ $# -ne 1 ]; then
    echo "Verwendung: $0 <ausgabedatei>"
    exit 1
fi

output_file="$1"

# Funktion zum Schreiben einer Regel
write_rule() {
    local selector="$1"
    shift
    local properties=("$@")

    echo "$selector {" >> "$output_file"
    for prop in "${properties[@]}"; do
        echo "  $prop;" >> "$output_file"
    done
    echo "}" >> "$output_file"
}

# Leere die Ausgabedatei oder erstelle sie
> "$output_file"

# Schreibe die CSS-Regeln
write_rule ".overview-row" \
    "display:grid" \
    "grid-template-columns:24px minmax(0,1fr) 11px 22px auto" \
    "gap:7px" \
    "align-items:center" \
    "margin:6px 0"

write_rule ".overview-row input" \
    "min-width:0" \
    "width:100%"

write_rule ".overview-state" \
    "width:11px" \
    "height:11px" \
    "border-radius:50%" \
    "background:#888"

write_rule ".overview-state.online" \
    "background:var(--good)" \
    "box-shadow:0 0 0 3px color-mix(in srgb, var(--good) 15%, transparent)"

write_rule ".overview-state.offline" \
    "background:var(--bad)" \
    "box-shadow:0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent)"

write_rule ".overview-state.checking, .overview-state.error" \
    "background:var(--warn)"

write_rule ".overview-count" \
    "font-size:11px" \
    "text-align:center" \
    "font-variant-numeric:tabular-nums"

write_rule ".overview-actions" \
    "display:grid" \
    "grid-template-columns:44px repeat(2,minmax(0,1fr))" \
    "gap:6px" \
    "align-items:stretch"

write_rule ".overview-actions button" \
    "min-width:0" \
    "padding:8px 2px" \
    "font-size:11px" \
    "white-space:nowrap"

write_rule "#overview-rows" \
    "display:flex" \
    "flex-direction:column"

write_rule ".monitor-settings > label:not(.option-row)" \
    "display:block" \
    "margin:12px 0"

write_rule ".monitor-settings .option-row input" \
    "appearance:auto" \
    "width:13px" \
    "height:13px" \
    "min-width:13px" \
    "background:none"

write_rule ".overview-link" \
    "padding:8px 0" \
    "border-bottom:1px solid #bbb" \
    "overflow-wrap:anywhere"

write_rule ".overview-link p" \
    "margin:4px 0"

write_rule ".overview-row .overview-retry" \
    "width:24px" \
    "min-width:24px" \
    "height:26px" \
    "min-height:26px" \
    "padding:0" \
    "background-image:var(--icon-reset)" \
    "background-size:20px" \
    "background-position:center" \
    "background-repeat:no-repeat"

write_rule ".top-setting input" \
    "appearance:auto" \
    "-webkit-appearance:checkbox" \
    "width:13px" \
    "height:13px" \
    "min-width:13px" \
    "background:none"

write_rule ".overview-visually-hidden" \
    "position:absolute" \
    "width:1px" \
    "height:1px" \
    "padding:0" \
    "margin:-1px" \
    "overflow:hidden" \
    "clip:rect(0,0,0,0)" \
    "white-space:nowrap" \
    "border:0"

write_rule ".overview-row[hidden]" \
    "display:none"
