#!/usr/bin/env bash
# visual-qa.mjs — portiert nach shell
# Quelle: javascript, Onboarding@main:scripts/visual-qa.mjs
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Visual-QA-Tool der Sandbox — rendert eine laufende Seite in echten Browsern
# bei mehreren Auflösungen und legt Screenshots ab, damit Claude das Ergebnis
# SELBST betrachten kann, bevor es weiterverwendet wird.
#
# Warum echtes Chrome: Der Playwright-Bundle-Chromium hat keine proprietären
# Codecs (H.264/AAC) → Videos bleiben schwarz. Google Chrome Stable
# (channel/executablePath) dekodiert die MP4-Hero-Videos korrekt.
#
# Nutzung:
#   xvfb-run -a bash visual-qa.sh [URL] [--engines chrome,firefox,webkit]
#     [--out <dir>] [--click "<aria-name>"] [--wait <ms>] [--full]
#
# Auflösungen: Desktop 1920x1080 & 1366x768, Laptop 1440x900,
#              Tablet 1024x768, Mobile 390x844 (iPhone-Klasse).

# Prüfen ob benötigte Tools installiert sind
command -v chromium-browser >/dev/null 2>&1 || command -v google-chrome >/dev/null 2>&1 || {
  echo >&2 "Fehler: Kein unterstützter Browser gefunden (chromium-browser oder google-chrome)"
  exit 1
}
command -v ffmpeg >/dev/null 2>&1 || {
  echo >&2 "Fehler: ffmpeg nicht gefunden"
  exit 1
}
command -v jq >/dev/null 2>&1 || {
  echo >&2 "Fehler: jq nicht gefunden"
  exit 1
}

# Hilfsfunktion zum Parsen von Argumenten
parse_args() {
  local args=("$@")
  local i
  for ((i=0; i<${#args[@]}; i++)); do
    case "${args[i]}" in
      --out)
        OUT="${args[i+1]}"
        ((i++))
        ;;
      --wait)
        WAIT="${args[i+1]}"
        ((i++))
        ;;
      --click)
        CLICK="${args[i+1]}"
        ((i++))
        ;;
      --full)
        FULL="true"
        ;;
      --engines)
        IFS=',' read -ra ENGINES <<< "${args[i+1]}"
        ((i++))
        ;;
      -*)
        # Unbekanntes Flag ignorieren
        ;;
      *)
        if [[ -z "${URL:-}" ]]; then
          URL="${args[i]}"
        fi
        ;;
    esac
  done
}

# Standardwerte setzen
URL="${1:-http://localhost:3000}"
OUT="/tmp/visual-qa"
WAIT="3500"
CLICK=""
FULL="false"
ENGINES=("chrome")

# Argumente parsen
parse_args "$@"

# Ausgabeverzeichnis erstellen
mkdir -p "$OUT"

# Auflösungen definieren
RESOLUTIONS=(
  "desktop-1920:1920x1080"
  "desktop-1366:1366x768"
  "laptop-1440:1440x900"
  "tablet-1024:1024x768"
  "mobile-390:390x844"
)

# Manifest initialisieren
manifest=()

# Browser-Pfade
CHROME_PATHS=(
  "/usr/bin/google-chrome-stable"
  "/usr/bin/google-chrome"
  "/usr/bin/chromium-browser"
)

# Funktion zum Finden eines verfügbaren Browsers
find_chrome() {
  local path
  for path in "${CHROME_PATHS[@]}"; do
    if [[ -x "$path" ]]; then
      echo "$path"
      return
    fi
  done
  return 1
}

# Hauptfunktion für Screenshot-Erstellung
create_screenshots() {
  local engine="$1"
  local chrome_path
  
  # Browser starten
  if [[ "$engine" == "chrome" ]]; then
    chrome_path=$(find_chrome)
    if [[ -z "$chrome_path" ]]; then
      echo "[${engine}] Start fehlgeschlagen: Kein Chrome-Browser gefunden"
      return
    fi
  elif [[ "$engine" == "firefox" ]]; then
    if ! command -v firefox >/dev/null 2>&1; then
      echo "[${engine}] Start fehlgeschlagen: Firefox nicht gefunden"
      return
    fi
  elif [[ "$engine" == "webkit" ]]; then
    echo "[${engine}] WebKit wird nicht unterstützt"
    return
  else
    echo "[${engine}] Unbekannte Engine"
    return
  fi

  # Für jede Auflösung einen Screenshot erstellen
  local res_entry
  for res_entry in "${RESOLUTIONS[@]}"; do
    local res_name="${res_entry%%:*}"
    local resolution="${res_entry#*:}"
    local width="${resolution%x*}"
    local height="${resolution#*x}"
    
    local file="${OUT}/${engine}-${res_name}.png"
    
    # Kommando zusammenbauen
    local cmd=(timeout 60)
    
    if [[ "$engine" == "chrome" ]]; then
      cmd+=("$chrome_path" 
            "--headless=new"
            "--disable-gpu"
            "--no-sandbox"
            "--autoplay-policy=no-user-gesture-required"
            "--window-size=${width},${height}")
      
      # Proxy-Einstellungen hinzufügen falls vorhanden
      if [[ -n "${HTTPS_PROXY:-}" ]] || [[ -n "${https_proxy:-}" ]]; then
        local proxy="${HTTPS_PROXY:-${https_proxy:-}}"
        cmd+=("--proxy-server=$proxy")
      fi
      
      cmd+=("--screenshot=$file")
      
      if [[ "$FULL" == "true" ]]; then
        cmd+=("--full-page")
      fi
      
      cmd+=("$URL")
    elif [[ "$engine" == "firefox" ]]; then
      # Firefox headless screenshot mit ffmpeg/xvfb
      echo "[${engine}/${res_name}] Firefox-Support begrenzt, überspringe"
      continue
    else
      echo "[${engine}/${res_name}] Nicht unterstützte Engine"
      continue
    fi
    
    # Seite laden und warten
    echo "Lade $URL in ${engine}/${res_name}..."
    
    # Prozess starten
    if "${cmd[@]}" 2>/dev/null; then
      # Warten nach dem Laden
      sleep "$((WAIT / 1000))"
      
      # Klick simulieren falls angegeben
      if [[ -n "$CLICK" ]]; then
        echo "[${engine}/${res_name}] Klick-Simulation nicht implementiert"
        # In bash können wir keine interaktiven Elemente anklicken
        # Dies wäre nur mit zusätzlichen Tools wie xdotool möglich
      fi
      
      # Phase extrahieren (vereinfacht)
      local phase="-"
      
      # Zur Manifestliste hinzufügen
      manifest+=("{\"engine\":\"$engine\",\"res\":\"$res_name\",\"file\":\"$file\",\"phase\":\"$phase\"}")
      
      echo "OK  ${engine}$(printf '%*s' $((8 - ${#engine}))) ${res_name}$(printf '%*s' $((13 - ${#res_name}))) phase=${phase}  $file"
    else
      echo "ERR ${engine}/${res_name}: Timeout oder Fehler beim Laden"
    fi
  done
}

# Für jede Engine Screenshots erstellen
for engine in "${ENGINES[@]}"; do
  create_screenshots "$engine"
done

# Zusammenfassung
echo
echo "${#manifest[@]} Screenshots in $OUT"
