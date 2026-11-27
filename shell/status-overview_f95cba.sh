#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "3bfd12412fe54a5b23766b31d06f1dac8876ab4a3697e2fda67f1db1fd00291f", "source_sha256": "f95cba00197f4650dddde02431fe14a0ca1baea932052e66b16f5778582e944f", "target_language": "shell"}
# status-overview.css — portiert nach shell
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Parameter: Ausgabedatei
output_file="${1:-}"

if [[ -z "$output_file" ]]; then
  echo "Fehler: Keine Ausgabedatei angegeben." >&2
  echo "Aufruf: $0 <ausgabedatei>" >&2
  exit 1
fi

# Erzeuge die CSS-Struktur programmatisch
{
  echo "*{box-sizing:border-box}"
  echo "html,body{margin:0;min-height:100%;background:#101015;color:#fff;font:14px system-ui,sans-serif}"
  echo "body{display:flex;flex-direction:column;height:100vh}"
  echo "header{display:flex;gap:1em;align-items:baseline;padding:0 12px}"
  echo "h1{font-size:17px;margin:8px 0}"
  echo "header p{font-size:12px;color:#bbb;margin:0}"
  echo "main{flex:1;min-height:0;display:grid;grid-template-columns:repeat(3,minmax(0,1fr));grid-template-rows:repeat(3,minmax(0,1fr));gap:4px;padding:0}"
  echo ".tile{min-width:0;min-height:0;display:flex;flex-direction:column;background:#202026;border:1px solid #393940}"
  echo ".tile h2{font-size:13px;margin:3px 8px}"
  echo ".tile video{min-height:0;width:100%;flex:1;object-fit:contain;background:#000}"
  echo ".tile p{font-size:11px;margin:3px 8px;color:#ddd}"
  echo ""
  echo "main.grid2{grid-template-columns:repeat(2,minmax(0,1fr));grid-template-rows:repeat(2,minmax(0,1fr))}"
  echo ".tile[hidden]{display:none}"
} > "$output_file"

echo "CSS erfolgreich in '$output_file' geschrieben."
