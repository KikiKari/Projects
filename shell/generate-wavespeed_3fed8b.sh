#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "58461895846a6671d9c548d0210fc75bd06a489a13134888da022e997b8608da", "source_sha256": "3fed8b6be2b9b8639b55bcaf18c09c0395ac005ab02c27f2dff26ca20b5d5825", "target_language": "shell"}
# generate-wavespeed.mjs — portiert nach shell
# Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Prüfe, ob WAVESPEED_API_KEY gesetzt ist
if [[ -z "${WAVESPEED_API_KEY:-}" ]]; then
  echo "Fehler: WAVESPEED_API_KEY ist nicht gesetzt." >&2
  exit 1
fi

# Pfade definieren
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEDIA_PRODUCTION_DIR="$SCRIPT_DIR/../media-production"
RAW_DIR="$MEDIA_PRODUCTION_DIR/raw"
PUBLIC_MEDIA_DIR="$SCRIPT_DIR/../public/media"
JOBS_FILE="$MEDIA_PRODUCTION_DIR/wavespeed-jobs.json"
RESULT_URL="$MEDIA_PRODUCTION_DIR/wavespeed-results.json"

# Verzeichnisse erstellen
mkdir -p "$RAW_DIR" "$PUBLIC_MEDIA_DIR"

# Ergebnisdatei initialisieren, falls sie nicht existiert
if [[ ! -f "$RESULT_URL" ]]; then
  echo "[]" > "$RESULT_URL"
fi

# Lade Jobs aus JSON-Datei
mapfile -t JOBS < <(jq -c '.[]' "$JOBS_FILE")

# Zähler für abgeschlossene Jobs
COMPLETED_COUNT=0

# Iteriere über alle Jobs
for JOB_JSON in "${JOBS[@]}"; do
  JOB_ID=$(echo "$JOB_JSON" | jq -r '.id')
  OUTPUT_NAME=$(echo "$JOB_JSON" | jq -r '.output')
  RAW_PATH="$RAW_DIR/$JOB_ID.png"
  TARGET_PATH="$PUBLIC_MEDIA_DIR/$OUTPUT_NAME.png"

  # Prüfe, ob Bild bereits generiert wurde
  if [[ -f "$RAW_PATH" ]]; then
    if ! jq -e --arg id "$JOB_ID" 'any(.[]; .id == $id)' "$RESULT_URL" >/dev/null; then
      TEMP_LOG=$(mktemp)
      jq --arg id "$JOB_ID" \
         --arg output "$(basename "$TARGET_PATH")" \
         '. += [{"id": $id, "requestId": "completed-before-resume", "model": "google/nano-banana-2/edit", "resolution": "4k", "plannedCostUsd": 0.14, "output": $output}]' \
         "$RESULT_URL" > "$TEMP_LOG" && mv "$TEMP_LOG" "$RESULT_URL"
    fi
    echo "Übersprungen: $JOB_ID ist bereits vorhanden."
    ((COMPLETED_COUNT++))
    continue
  fi

  # Sammle Bilder (Base64 oder URLs)
  IMAGES_JSON=$(echo "$JOB_JSON" | jq -r '.images | map(if test("^https?:|^data:") then . else "file://" + (. | sub("^\\./?"; "../")) end)')

  # Konvertiere lokale Dateien zu Base64
  PROCESSED_IMAGES_JSON=$(echo "$IMAGES_JSON" | jq -c 'map(if test("^file://") then
    (. | sub("^file://"; "")) as $path |
    "data:image/png;base64," + ($path | @base64d)
  else . end)')

  # Erstelle Request Body
  PROMPT=$(echo "$JOB_JSON" | jq -r '.prompt')
  ASPECT_RATIO=$(echo "$JOB_JSON" | jq -r '.aspectRatio')
  REQUEST_BODY=$(jq -n \
    --arg prompt "$PROMPT" \
    --argjson images "$PROCESSED_IMAGES_JSON" \
    --arg aspect_ratio "$ASPECT_RATIO" \
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

  # Sende Anfrage an WaveSpeed API
  RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Authorization: Bearer $WAVESPEED_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$REQUEST_BODY" \
    https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit)

  HTTP_CODE=$(tail -n1 <<< "$RESPONSE")
  RESPONSE_BODY=$(sed '$d' <<< "$RESPONSE")

  if [[ "$HTTP_CODE" != "200" ]]; then
    echo "WaveSpeed submit fehlgeschlagen: $HTTP_CODE $RESPONSE_BODY" >&2
    exit 1
  fi

  REQUEST_ID=$(echo "$RESPONSE_BODY" | jq -r '.data.id // .id')

  # Polling für Ergebnis
  RESULT=""
  ATTEMPTS=0
  while [[ $ATTEMPTS -lt 90 ]]; do
    sleep 4
    POLL_RESPONSE=$(curl -s -H "Authorization: Bearer $WAVESPEED_API_KEY" \
      "https://api.wavespeed.ai/api/v3/predictions/$REQUEST_ID/result")
    
    STATUS=$(echo "$POLL_RESPONSE" | jq -r '.data.status')
    
    if [[ "$STATUS" == "completed" ]]; then
      RESULT="$POLL_RESPONSE"
      break
    elif [[ "$STATUS" == "failed" ]]; then
      echo "WaveSpeed job fehlgeschlagen: $JOB_ID" >&2
      exit 1
    fi
    
    ((ATTEMPTS++))
  done

  if [[ -z "$RESULT" ]]; then
    echo "Zeitüberschreitung beim Warten auf das Ergebnis für Job: $JOB_ID" >&2
    exit 1
  fi

  IMAGE_URL=$(echo "$RESULT" | jq -r '.data.outputs[0]')
  if [[ "$IMAGE_URL" == "null" || -z "$IMAGE_URL" ]]; then
    echo "Kein Output für $JOB_ID" >&2
    exit 1
  fi

  # Lade das Bild herunter und speichere es
  curl -s "$IMAGE_URL" -o "$RAW_PATH"
  cp "$RAW_PATH" "$TARGET_PATH"

  # Aktualisiere Logdatei
  TEMP_LOG=$(mktemp)
  jq --arg id "$JOB_ID" \
     --arg requestId "$REQUEST_ID" \
     --arg output "$(basename "$TARGET_PATH")" \
     '. += [{"id": $id, "requestId": $requestId, "model": "google/nano-banana-2/edit", "resolution": "4k", "plannedCostUsd": 0.14, "output": $output}]' \
     "$RESULT_URL" > "$TEMP_LOG" && mv "$TEMP_LOG" "$RESULT_URL"

  echo "Abgeschlossen: $JOB_ID"
  ((COMPLETED_COUNT++))
done

# Finale Zusammenfassung
TOTAL_COST=$(echo "$COMPLETED_COUNT * 0.14" | bc -l)
printf "WaveSpeed abgeschlossen: %d Assets, geplante Basiskosten \$%.2f.\n" "$COMPLETED_COUNT" "$TOTAL_COST"
