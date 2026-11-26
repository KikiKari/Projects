#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "91db19a8c3b65736460e456a1f3e5b98e30d3085d4d19251100fcbbafdd638f5", "source_sha256": "4112b3dbe78c8a495b73f6feaebe05ada553911d2e25f6bd1e2e4d704a6ac1b6", "target_language": "lua"}
-- generate-elevenlabs.mjs — portiert nach lua
-- Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local json = require("cjson")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local io = require("io")
local os = require("os")

-- Hilfsfunktion zur Erstellung von Verzeichnissen (rekursiv)
local function mkdir(path)
  local sep = package.config:sub(1,1)
  local dirs = {}
  for dir in path:gmatch("[^"..sep.."]+") do
    table.insert(dirs, dir)
  end
  local current_path = sep == '\\' and "" or "/"
  for i, dir in ipairs(dirs) do
    current_path = current_path .. dir .. sep
    if sep == '\\' then
      os.execute('mkdir "' .. current_path .. '"')
    else
      os.execute("mkdir -p " .. current_path)
    end
  end
end

-- Umgebungsvariablen
local key = os.getenv("ELEVENLABS_API_KEY")
local voiceId = os.getenv("ELEVENLABS_VOICE_ID") or "JBFqnCBsd6RMkjVDRZzb"

if not key then
  error("ELEVENLABS_API_KEY fehlt.")
end

local text = "Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden."

-- API-Aufruf vorbereiten
local url = "https://api.elevenlabs.io/v1/text-to-speech/" .. voiceId .. "?output_format=mp3_44100_128"
local postData = json.encode({
  text = text,
  model_id = "eleven_multilingual_v2",
  voice_settings = {
    stability = 0.58,
    similarity_boost = 0.72,
    style = 0.18,
    use_speaker_boost = true
  }
})

local headers = {
  ["xi-api-key"] = key,
  ["Content-Type"] = "application/json",
  ["Content-Length"] = tostring(#postData)
}

-- Antwort speichern
local response_body = {}

-- HTTP-Anfrage senden
local res, code, headers, status = https.request{
  url = url,
  method = "POST",
  headers = headers,
  source = ltn12.source.string(postData),
  sink = ltn12.sink.table(response_body)
}

if code ~= 200 then
  error("ElevenLabs fehlgeschlagen: " .. tostring(code))
end

-- Verzeichnisse erstellen
mkdir("public/audio")
mkdir("media-production")

-- Audio-Datei speichern
local audio_file = io.open("public/audio/project-narration.mp3", "wb")
audio_file:write(table.concat(response_body))
audio_file:close()

-- JSON-Ergebnis speichern
local result_data = {
  model = "eleven_multilingual_v2",
  voiceId = voiceId,
  characters = #text,
  text = text,
  output = "public/audio/project-narration.mp3"
}

local json_file = io.open("media-production/elevenlabs-result.json", "w")
json_file:write(json.encode(result_data))
json_file:close()

print("ElevenLabs abgeschlossen: " .. #text .. " Zeichen.")
