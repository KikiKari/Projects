#!/usr/bin/env pwsh
# generate-elevenlabs.mjs — portiert nach powershell
# Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

$key = $env:ELEVENLABS_API_KEY
$voiceId = if ($env:ELEVENLABS_VOICE_ID) { $env:ELEVENLABS_VOICE_ID } else { "JBFqnCBsd6RMkjVDRZzb" }

if (-not $key) {
    throw "ELEVENLABS_API_KEY fehlt."
}

$text = "Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden."

$body = @{
    text = $text
    model_id = "eleven_multilingual_v2"
    voice_settings = @{
        stability = 0.58
        similarity_boost = 0.72
        style = 0.18
        use_speaker_boost = $true
    }
} | ConvertTo-Json

$headers = @{
    "xi-api-key" = $key
    "Content-Type" = "application/json"
}

$response = Invoke-WebRequest -Uri "https://api.elevenlabs.io/v1/text-to-speech/$voiceId?output_format=mp3_44100_128" -Method POST -Headers $headers -Body $body

if ($response.StatusCode -ne 200) {
    throw "ElevenLabs fehlgeschlagen: $($response.StatusCode)"
}

$projectRoot = Join-Path $PSScriptRoot ".."
$audioDir = Join-Path $projectRoot "public" "audio"
$outputFile = Join-Path $audioDir "project-narration.mp3"
$resultFile = Join-Path $projectRoot "media-production" "elevenlabs-result.json"

if (-not (Test-Path $audioDir)) {
    New-Item -ItemType Directory -Path $audioDir -Force | Out-Null
}

[byte[]]$audioBytes = [System.Convert]::FromBase64String($response.Content)
[IO.File]::WriteAllBytes($outputFile, $audioBytes)

$result = @{
    model = "eleven_multilingual_v2"
    voiceId = $voiceId
    characters = $text.Length
    text = $text
    output = "public/audio/project-narration.mp3"
} | ConvertTo-Json -Depth 10

Set-Content -Path $resultFile -Value $result

Write-Host "ElevenLabs abgeschlossen: $($text.Length) Zeichen."
