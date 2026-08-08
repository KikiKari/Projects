#!/usr/bin/env bash
# TelegramMonitorCompanion.ps1 — portiert nach shell
# Quelle: powershell, Projects@Telegram-Monitor:TelegramMonitorCompanion.ps1
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Telegram Monitor Companion — Starter
#
# Startet den lokalen Monitor im Hintergrund (kein Konsolenfenster), wartet,
# bis der Port wirklich antwortet, und oeffnet die Oberflaeche als eigenes
# Fenster ohne Adressleiste. Laeuft der Monitor schon, wird er nicht erneut
# gestartet — dann wird nur das Fenster geoeffnet.
#
# Aufruf:
#   ./TelegramMonitorCompanion.sh              starten und oeffnen
#   ./TelegramMonitorCompanion.sh -Stop        beenden
#   ./TelegramMonitorCompanion.sh -Status      nachsehen, ob er laeuft
#   ./TelegramMonitorCompanion.sh -Port 9000   anderer Port
#   ./TelegramMonitorCompanion.sh -Console     mit sichtbarem Fenster (Fehlersuche)

# Standardwerte
Port=8765
Interval=120
Stop=false
Status=false
Console=false
NoBrowser=false

# Parameter parsen
while [[ $# -gt 0 ]]; do
  case $1 in
    -Port)     Port="$2"; shift 2 ;;
    -Interval) Interval="$2"; shift 2 ;;
    -Stop)     Stop=true; shift ;;
    -Status)   Status=true; shift ;;
    -Console)  Console=true; shift ;;
    -NoBrowser) NoBrowser=true; shift ;;
    *)         echo "Unbekannter Parameter: $1"; exit 1 ;;
  esac
done

Root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PidFile="$Root/data/companion.pid"
LogFile="$Root/data/companion.log"
Url="http://127.0.0.1:$Port"

Write-Step() {
  echo "  $1"
}

Test-Monitor() {
  if command -v curl >/dev/null 2>&1; then
    if curl -s -o /dev/null -w "%{http_code}" --max-time 2 "$Url/api/status" | grep -q "200"; then
      return 0
    fi
  elif command -v wget >/dev/null 2>&1; then
    if wget -q -O /dev/null --server-response --timeout=2 "$Url/api/status" 2>&1 | grep -q "HTTP/.* 200"; then
      return 0
    fi
  fi
  return 1
}

Get-MonitorProcess() {
  if [[ ! -f "$PidFile" ]]; then
    return 1
  fi
  local pid
  pid=$(head -n 1 "$PidFile" 2>/dev/null) || return 1
  if [[ -z "$pid" ]]; then
    return 1
  fi
  if kill -0 "$pid" 2>/dev/null; then
    echo "$pid"
    return 0
  else
    return 1
  fi
}

# ---------------------------------------------------------------- beenden ---
if [[ "$Stop" == true ]]; then
  if pid=$(Get-MonitorProcess); then
    kill "$pid"
    Write-Step "Monitor beendet (PID $pid)."
  else
    Write-Step 'Es lief kein Monitor aus diesem Starter.'
  fi
  rm -f "$PidFile"
  exit 0
fi

# ----------------------------------------------------------------- Status ---
if [[ "$Status" == true ]]; then
  if Test-Monitor; then
    if pid=$(Get-MonitorProcess); then
      Write-Step "Monitor laeuft auf $Url  (PID $pid)."
    else
      Write-Step "Monitor laeuft auf $Url."
    fi
  else
    Write-Step "Auf $Url antwortet nichts."
  fi
  exit 0
fi

# ------------------------------------------------------------------ Start ---
echo ""
echo '  Telegram Monitor Companion'
echo '  --------------------------'

# Python suchen
exe=""
pre=()
for cmd in "python3" "python" "py"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    exe="$cmd"
    break
  fi
done

if [[ -z "$exe" ]]; then
  echo ""
  echo "  Python wurde nicht gefunden." >&2
  echo "  Herunterladen: https://www.python.org/downloads/"
  echo "  Beim Installieren \"Add python.exe to PATH\" ankreuzen."
  echo ""
  read -rp "  Eingabetaste zum Schliessen"
  exit 1
fi

Write-Step "Python: $exe"

if Test-Monitor; then
  Write-Step "Monitor laeuft bereits auf $Url — wird nicht erneut gestartet."
else
  mkdir -p "$(dirname "$PidFile")"
  
  args=("server.py" "--port" "$Port" "--poll-interval" "$Interval" "--no-browser")
  
  if [[ "$Console" == true ]]; then
    "$exe" "${args[@]}" &
    proc_pid=$!
  else
    # Ohne Fenster, Ausgabe in die Protokolldatei
    "$exe" "${args[@]}" >"$LogFile" 2>"$LogFile.err" &
    proc_pid=$!
  fi
  
  echo "$proc_pid" >"$PidFile"
  Write-Step "Gestartet (PID $proc_pid), warte auf Antwort ..."
  
  ok=false
  for i in {1..40}; do
    sleep 0.5
    if Test-Monitor; then
      ok=true
      break
    fi
    if ! kill -0 "$proc_pid" 2>/dev/null; then
      break
    fi
  done
  
  if [[ "$ok" == false ]]; then
    echo ""
    echo "  Der Monitor hat nicht geantwortet." >&2
    if [[ -f "$LogFile.err" ]]; then
      echo "  Letzte Zeilen der Fehlerausgabe:"
      tail -n 15 "$LogFile.err" | while read -r line; do
        echo "    $line"
      done
    fi
    echo ""
    echo "  Nochmal mit sichtbarem Fenster:  ./TelegramMonitorCompanion.sh -Console"
    read -rp "  Eingabetaste zum Schliessen"
    exit 1
  fi
  Write-Step 'Antwortet.'
fi

if [[ "$NoBrowser" == true ]]; then
  Write-Step "Bereit: $Url"
  exit 0
fi

# Als eigenes Fenster oeffnen (App-Modus), sonst normaler Tab
if command -v xdg-open >/dev/null 2>&1; then
  # Linux
  if command -v google-chrome >/dev/null 2>&1; then
    google-chrome "--app=$Url" 2>/dev/null &
    Write-Step 'Als eigenes Fenster geoeffnet (Chrome).'
  elif command -v chromium-browser >/dev/null 2>&1; then
    chromium-browser "--app=$Url" 2>/dev/null &
    Write-Step 'Als eigenes Fenster geoeffnet (Chromium).'
  elif command -v firefox >/dev/null 2>&1; then
    firefox "--new-window" "$Url" 2>/dev/null &
    Write-Step 'Als eigenes Fenster geoeffnet (Firefox).'
  else
    xdg-open "$Url" 2>/dev/null &
    Write-Step 'Im Standardbrowser geoeffnet.'
  fi
elif command -v open >/dev/null 2>&1; then
  # macOS
  open "$Url" 2>/dev/null &
  Write-Step 'Im Standardbrowser geoeffnet (macOS).'
else
  # Fallback
  if command -v sensible-browser >/dev/null 2>&1; then
    sensible-browser "$Url" 2>/dev/null &
    Write-Step 'Im Standardbrowser geoeffnet.'
  else
    Write-Step "Kein Browser gefunden, oeffne manuell: $Url"
  fi
fi

echo ""
echo "  Laeuft im Hintergrund auf $Url"
echo "  Beenden:  ./TelegramMonitorCompanion.sh -Stop"
echo ""
