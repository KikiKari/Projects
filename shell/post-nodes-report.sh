#!/bin/bash
# post-nodes-report.js — portiert nach shell
# Quelle: javascript, OpenClaw@gateway1:scripts/post-nodes-report.js
# auch in: OpenClaw@gateway2:scripts/post-nodes-report.js
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Pfade
DASHBOARD_PATH="$(dirname "$0")/../dashboards/nodes-overview.md"
REPORT_LOG="$(dirname "$0")/../logs/nodes-report.log"

# Farbcodes
C_green=$'\e[32m'
C_yellow=$'\e[33m'
C_red=$'\e[31m'
C_reset=$'\e[0m'

post_report() {
  local content
  if ! content=$(cat "$DASHBOARD_PATH" 2>/dev/null); then
    echo "${C_red}❌ Fehler beim Lesen der Dashboard-Datei:${C_reset}" >&2
    return 1
  fi

  # Nachricht über OpenClaw message senden
  local escaped_content
  escaped_content=$(printf '%s' "$content" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g; s/^/"/; s/\(.\)$/\\1"/')
  local message_cmd=(openclaw message send --target=main --message "$escaped_content")

  if output=$("${message_cmd[@]}" 2>&1); then
    echo "${C_green}✅ Report erfolgreich im 'main'-Channel gepostet.${C_reset}"
    echo "[${C_reset}] Report posted." >> "$REPORT_LOG"
  else
    echo "${C_red}❌ Fehler beim Senden der Nachricht:${C_reset} $output" >&2
    echo "[${C_reset}] Failed to post: $output" >> "$REPORT_LOG"
  fi
}

# Hauptausführung
echo "${C_yellow}📤 Sende Nodes-Übersicht in 'main'...${C_reset}"
post_report
