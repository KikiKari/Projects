#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "d50f78983e69f91e3a8c7e1342e800c589184ee30021b95341237acb3d7ceb91", "source_sha256": "4112b3dbe78c8a495b73f6feaebe05ada553911d2e25f6bd1e2e4d704a6ac1b6", "target_language": "shell"}
# generate-elevenlabs.mjs — portiert nach shell
# Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Prüfe ob ELEVENLABS_API_KEY gesetzt ist
if [[ -z "${ELEVENLABS_API_KEY:-}" ]]; then
  echo "ELEVENLABS_API_KEY fehlt." >&2
  exit 1
fi

# Setze Standard-Wert für voiceId falls nicht gesetzt
: "${ELEVENLABS_VOICE_ID:=JBFqnCBsd6RMkjVDRZzb}"

# Textinhalt
text="Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden."

# API-Aufruf an ElevenLabs
url="https://api.elevenlabs.io/v1/text-to-speech/${ELEVENLABS_VOICE_ID}?output_format=mp3_44100_128"
response_file="$(mktemp)"
header_file="$(mktemp)"

# JSON-Daten für den Request erstellen
request_data=$(jq -n --arg txt "$text" '{
  text: $txt,
  model_id: "eleven_multilingual_v2",
  voice_settings: {
    stability: 0.58,
    similarity_boost: 0.72,
    style: 0.18,
    use_speaker_boost: true
  }
}')

# Führe den API-Aufruf durch
http_status=$(curl -s -w "%{http_code}" -o "$response_file" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$request_data" \
  "$url")

# Prüfe ob der Request erfolgreich war
if [[ "$http_status" -ge 400 ]]; then
  echo "ElevenLabs fehlgeschlagen: $http_status" >&2
  rm -f "$response_file" "$header_file"
  exit 1
fi

# Erstelle Zielverzeichnis
mkdir -p "../public/audio/"

# Schreibe Audiodatei
mv "$response_file" "../public/audio/project-narration.mp3"

# Erstelle JSON-Resultatdatei
result_json="../media-production/elevenlabs-result.json"
mkdir -p "$(dirname "$result_json")"

jq -n \
  --arg model "eleven_multilingual_v2" \
  --arg voiceId "$ELEVENLABS_VOICE_ID" \
  --arg text "$text" \
  --arg output "public/audio/project-narration.mp3" \
  '{
    model: $model,
    voiceId: $voiceId,
    characters: ($text | length),
    text: $text,
    output: $output
  }' > "$result_json"

# Gebe Erfolgsmeldung aus
echo "ElevenLabs abgeschlossen: $(wc -c <<< "$text") Zeichen."
