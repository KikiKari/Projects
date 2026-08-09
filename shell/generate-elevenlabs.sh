#!/bin/bash
# generate-elevenlabs.mjs — portiert nach shell
# Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Prüfe Umgebungsvariablen
if [[ -z "${ELEVENLABS_API_KEY:-}" ]]; then
  echo "ELEVENLABS_API_KEY fehlt." >&2
  exit 1
fi

VOICE_ID="${ELEVENLABS_VOICE_ID:-JBFqnCBsd6RMkjVDRZzb}"
TEXT="Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden."
OUTPUT_DIR="../public/audio"
OUTPUT_FILE="$OUTPUT_DIR/project-narration.mp3"
LOG_FILE="../media-production/elevenlabs-result.json"

# Erstelle Ausgabeverzeichnis
mkdir -p "$OUTPUT_DIR"

# API-Aufruf
RESPONSE_FILE=$(mktemp)
HTTP_STATUS=$(curl -s -w "%{http_code}" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"$TEXT\",\"model_id\":\"eleven_multilingual_v2\",\"voice_settings\":{\"stability\":0.58,\"similarity_boost\":0.72,\"style\":0.18,\"use_speaker_boost\":true}}" \
  "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID?output_format=mp3_44100_128" \
  -o "$RESPONSE_FILE")

# Prüfe HTTP-Status
if [[ "$HTTP_STATUS" -ge 400 ]]; then
  echo "ElevenLabs fehlgeschlagen: $HTTP_STATUS" >&2
  rm -f "$RESPONSE_FILE"
  exit 1
fi

# Schreibe Audio-Datei
mv "$RESPONSE_FILE" "$OUTPUT_FILE"

# Erstelle Log-Datei
CHAR_COUNT=${#TEXT}
cat > "$LOG_FILE" <<EOF
{
  "model": "eleven_multilingual_v2",
  "voiceId": "$VOICE_ID",
  "characters": $CHAR_COUNT,
  "text": "$TEXT",
  "output": "public/audio/project-narration.mp3"
}
EOF

echo "ElevenLabs abgeschlossen: $CHAR_COUNT Zeichen."
