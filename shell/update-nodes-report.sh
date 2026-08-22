#!/bin/bash
# update-nodes-report.js — portiert nach shell
# Quelle: javascript, OpenClaw@gateway1:scripts/update-nodes-report.js
# auch in: OpenClaw@gateway2:scripts/update-nodes-report.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Pfade
DASHBOARD_PATH="$(dirname "$0")/../dashboards/nodes-overview.md"

# Farbcodes für Konsole
C_GREEN=$'\e[32m'
C_YELLOW=$'\e[33m'
C_RED=$'\e[31m'
C_BLUE=$'\e[34m'
C_RESET=$'\e[0m'

getNodeStatus() {
  if command -v openclaw >/dev/null 2>&1; then
    openclaw nodes status --json 2>/dev/null || echo "[]"
  else
    echo "[]" >&2
  fi
}

updateDashboard() {
  local nodes_json="$1"
  local now
  now=$(TZ=Europe/Berlin date '+%d.%m.%Y, %H:%M:%S')

  # Manuelle Ergänzung statischer Konfigurationen (da nicht alle Infos über CLI)
  declare -A NODE_CONFIG=(
    [1]="Gateway|Ubuntu 22.04|152.53.145.65|10.10.0.1|–|Gateway"
    [2]="Netcup Server|Ubuntu 22.04|78.46.123.10|10.10.0.2|–|Node"
    [3]="xNetX VPS|Debian 11|5.45.105.20|–|Port 18794|Node"
    [4]="Webhosting|Shared Linux|–|–|–|–"
    [5]="Redmi Note 11|Android|–|10.10.0.5|–|Node"
    [6]="Lenovo (Win)|Windows 11|–|–|–|Node"
  )

  local rows=()
  local nodeId cfg name os ip wg tunnel mode

  for nodeId in "${!NODE_CONFIG[@]}"; do
    IFS='|' read -r name os ip wg tunnel mode <<< "${NODE_CONFIG[$nodeId]}"

    local node_match=""
    case "$nodeId" in
      1) node_match=$(echo "$nodes_json" | jq -r '.[] | select(.name == "Gateway") | .nodeId // empty' 2>/dev/null) ;;
      2) node_match=$(echo "$nodes_json" | jq -r '.[] | select(.name | contains("Netcup")) | .nodeId // empty' 2>/dev/null) ;;
      3) node_match=$(echo "$nodes_json" | jq -r '.[] | select(.name | contains("xNetX")) | .nodeId // empty' 2>/dev/null) ;;
      5) node_match=$(echo "$nodes_json" | jq -r '.[] | select(.name | contains("Redmi")) | .nodeId // empty' 2>/dev/null) ;;
      *) node_match=$(echo "$nodes_json" | jq -r ".[] | select(.nodeId == \"$nodeId\") | .nodeId // empty" 2>/dev/null) ;;
    esac

    local status_vpn="⚠️"
    local last_check="–"
    if [[ -n "$node_match" ]]; then
      local status
      status=$(echo "$nodes_json" | jq -r ".[] | select(.nodeId == \"$node_match\" or (.name // \"\") | contains(\"$(echo "$name" | cut -d' ' -f1)\")) | .status // \"unknown\"" 2>/dev/null)
      if [[ "$status" == "paired" ]]; then
        status_vpn="✅"
      else
        status_vpn="🔴"
      fi
      local last_seen
      last_seen=$(echo "$nodes_json" | jq -r ".[] | select(.nodeId == \"$node_match\" or (.name // \"\") | contains(\"$(echo "$name" | cut -d' ' -f1)\")) | .lastSeen // empty" 2>/dev/null)
      if [[ -n "$last_seen" && "$last_seen" != "null" ]]; then
        last_check=$(TZ=Europe/Berlin date -d "@$last_seen" '+%d.%m.%Y, %H:%M:%S' 2>/dev/null || echo "Invalid")
      fi
    fi

    local status_ssh="❌"
    if [[ "$tunnel" != "–" ]]; then
      status_ssh="✅"
    fi

    local ssh_key="❌"
    case "$nodeId" in
      1) ssh_key="Local (id_ed25519)" ;;
      2|3) ssh_key="❌ (Pending)" ;;
    esac

    rows+=("| $nodeId    | $name | $os | $ip | $mode       | $wg             | $tunnel | $status_vpn | $status_ssh | $ssh_key | $last_check |")
  done

  local table_rows
  printf -v table_rows '%s\n' "${rows[@]}"

  cat > "$DASHBOARD_PATH" <<EOF
# Nodes Overview (Network Status)

| Node | Name          | OS           | IP             | Mode       | Primär WG IP       | Sekundär/SSH Tunnel | StatusVPN | StatusSSH | SSH Key (Deployed) | Letzter Check       |
|------|---------------|--------------|----------------|------------|--------------------|---------------------|-----------|-----------|---------------------|---------------------|
$table_rows

> 💡 **Legende:** 
> - **Primär WG IP**: Die WireGuard-VPN-IP des Nodes
> - **Sekundär/SSH Tunnel**: Fallback-Mechanismus (z. B. Reverse-Tunnel)
> - **StatusVPN**: Verbunden über OpenClaw/WireGuard
> - **StatusSSH**: SSH-Zugriff via Reverse-Tunnel aktiv
> - **SSH Key (Deployed)**: Zeigt an, ob der Gateway-Schlüssel (\`id_ed25519\`) auf dem Ziel bereitgestellt ist
> - Letzter Stand: **$now CET**

*Größe: ~1.8 KB | Automatisch aktualisiert via \`update-nodes-report.sh\`*
EOF

  echo "${C_GREEN}✅ Dashboard aktualisiert:${C_RESET} $DASHBOARD_PATH"
}

# Hauptausführung
echo "${C_BLUE}🔄 Aktualisiere Nodes-Übersicht...${C_RESET}"
NODES_JSON=$(getNodeStatus)
updateDashboard "$NODES_JSON"
