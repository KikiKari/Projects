#!/bin/bash
# ops-hub-heartbeat.js — portiert nach shell
# Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
# auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Aktualisiere den Statusbericht mit aktueller Zeit
statusPath="$(dirname "$(dirname "$0")")/docs/ops-hub/status.md"

function updateHeartbeat() {
  local content
  if ! content=$(<"$statusPath"); then
    echo "❌ Konnte status.md nicht lesen: $?" >&2
    return
  fi

  local now
  now=$(date +"%d.%m.%Y, %H:%M:%S")
  local updated
  updated=$(echo "$content" | sed -E "s/(Letzter Heartbeat:) [^$]*/\1 $now/")

  if echo "$updated" >"$statusPath"; then
    echo "✅ Heartbeat aktualisiert: $now"
  else
    echo "❌ Konnte status.md nicht schreiben: $?" >&2
  fi
}

updateHeartbeat
