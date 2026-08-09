#!/bin/bash
# generate-wavespeed.mjs — portiert nach shell
# Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Prüfe, ob WAVESPEED_API_KEY gesetzt ist
if [[ -z "${WAVESPEED_API_KEY:-}" ]]; then
  echo "WAVESPEED_API_KEY fehlt." >&2
  exit 1
fi

# Verzeichnisse festlegen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEDIA_PRODUCTION_DIR="$(dirname "$SCRIPT_DIR")/media-production"
RAW_DIR="$MEDIA_PRODUCTION_DIR/raw"
PUBLIC_DIR="$(dirname "$SCRIPT_DIR")/public/media"
RESULT_FILE="$MEDIA_PRODUCTION_DIR/wavespeed-results.json"
JOBS_FILE="$MEDIA_PRODUCTION_DIR/wavespeed-jobs.json"

# Verzeichnisse erstellen
mkdir -p "$RAW_DIR"
mkdir -p "$PUBLIC_DIR"

# Log-Datei initialisieren
if [[ ! -f "$RESULT_FILE" ]]; then
  echo "[]" > "$RESULT_FILE"
fi

# Jobs laden
if [[ ! -f "$JOBS_FILE" ]]; then
  echo "Fehler: $JOBS_FILE nicht gefunden." >&2
  exit 1
fi

# Anzahl der Jobs zählen
job_count=$(jq -r 'length' "$JOBS_FILE")

# Für jeden Job iterieren
for ((i = 0; i < job_count; i++)); do
  job_id=$(jq -r ".[$i].id" "$JOBS_FILE")
  output_name=$(jq -r ".[$i].output" "$JOBS_FILE")
  prompt=$(jq -r ".[$i].prompt" "$JOBS_FILE")
  aspect_ratio=$(jq -r ".[$i].aspectRatio" "$JOBS_FILE")

  raw_path="$RAW_DIR/${job_id}.png"
  target_path="$PUBLIC_DIR/${output_name}.png"

  # Prüfen, ob die Datei bereits existiert
  if [[ -f "$raw_path" ]]; then
    # Prüfen, ob der Eintrag bereits im Log existiert
    if ! jq -e --arg id "$job_id" 'any(.[]; .id == $id)' "$RESULT_FILE" > /dev/null; then
      # Eintrag hinzufügen
      jq --arg id "$job_id" --arg output "$(basename "$target_path")" \
        '. += [{"id": $id, "requestId": "completed-before-resume", "model": "google/nano-banana-2/edit", "resolution": "4k", "plannedCostUsd": 0.14, "output": $output}]' \
        "$RESULT_FILE" > "$RESULT_FILE.tmp" && mv "$RESULT_FILE.tmp" "$RESULT_FILE"
    fi
    echo "Übersprungen: $job_id ist bereits vorhanden."
    continue
  fi

  # Bilder sammeln
  image_count=$(jq -r ".[$i].images | length" "$JOBS_FILE")
  image_json="["
  for ((j = 0; j < image_count; j++)); do
    image=$(jq -r ".[$i].images[$j]" "$JOBS_FILE")
    if [[ "$image" =~ ^https?:|^data: ]]; then
      image_json+="$image"
    else
      # Relativer Pfad zu absolutem Pfad
      image_path="$SCRIPT_DIR/../$image"
      if [[ ! -f "$image_path" ]]; then
        echo "Bild nicht gefunden: $image_path" >&2
        exit 1
      fi
      # In base64 kodieren
      base64_data=$(base64 -i "$image_path" | tr -d '\n')
      image_json+="\"data:image/png;base64,$base64_data\""
    fi
    if (( j < image_count - 1 )); then
      image_json+=","
    fi
  done
  image_json+="]"

  # JSON-Body erstellen
  json_body=$(jq -n \
    --arg prompt "$prompt" \
    --argjson images "$image_json" \
    --arg aspect_ratio "$aspect_ratio" \
    '{
      prompt: $prompt,
      images: $images,
      aspect_ratio: $aspect_ratio,
      resolution: "4k",
      output_format: "png",
      enable_web_search: false,
      enable_image_search: false,
      enable_sync_mode: false,
      enable_base64_output: false
    }')

  # Anfrage senden
  response=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Authorization: Bearer $WAVESPEED_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$json_body" \
    "https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit")

  http_code=$(echo "$response" | tail -n1)
  response_body=$(echo "$response" | head -n -1)

  if [[ "$http_code" -ne 200 ]]; then
    echo "WaveSpeed submit fehlgeschlagen: $http_code $response_body" >&2
    exit 1
  fi

  # Request-ID extrahieren
  request_id=$(echo "$response_body" | jq -r '.data.id // .id')

  # Polling bis zur Fertigstellung
  result=""
  for attempt in {1..90}; do
    sleep 4
    poll_response=$(curl -s -H "Authorization: Bearer $WAVESPEED_API_KEY" \
      "https://api.wavespeed.ai/api/v3/predictions/${request_id}/result")
    status=$(echo "$poll_response" | jq -r '.data.status // "unknown"')
    if [[ "$status" == "completed" ]]; then
      result="$poll_response"
      break
    elif [[ "$status" == "failed" ]]; then
      echo "WaveSpeed job fehlgeschlagen: $job_id" >&2
      exit 1
    fi
  done

  if [[ -z "$result" ]]; then
    echo "Timeout beim Warten auf Ergebnis für Job $job_id" >&2
    exit 1
  fi

  # Bild-URL extrahieren
  image_url=$(echo "$result" | jq -r '.data.outputs[0] // empty')
  if [[ -z "$image_url" ]]; then
    echo "Kein Output für $job_id" >&2
    exit 1
  fi

  # Bild herunterladen
  curl -s "$image_url" -o "$raw_path"
  cp "$raw_path" "$target_path"

  # Log aktualisieren
  jq --arg id "$job_id" --arg requestId "$request_id" --arg output "$(basename "$target_path")" \
    '. += [{"id": $id, "requestId": $requestId, "model": "google/nano-banana-2/edit", "resolution": "4k", "plannedCostUsd": 0.14, "output": $output}]' \
    "$RESULT_FILE" > "$RESULT_FILE.tmp" && mv "$RESULT_FILE.tmp" "$RESULT_FILE"

  echo "Abgeschlossen: $job_id"
done

# Abschlussmeldung
log_length=$(jq 'length' "$RESULT_FILE")
cost=$(echo "$log_length * 0.14" | bc -l)
printf "WaveSpeed abgeschlossen: %d Assets, geplante Basiskosten \$%.2f.\n" "$log_length" "$cost"
