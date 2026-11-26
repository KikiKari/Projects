#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "05ae62d459d6ca2e58da9d092c1c5c624427fb04b3b2420472aa79ae668155d6", "source_sha256": "4112b3dbe78c8a495b73f6feaebe05ada553911d2e25f6bd1e2e4d704a6ac1b6", "target_language": "powershell"}
# generate-elevenlabs.mjs — portiert nach powershell
# Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

$key = $env:ELEVENLABS_API_KEY
$voiceId = if ($env:ELEVENLABS_VOICE_ID) { $env:ELEVENLABS_VOICE_ID } else { "JBFqnCBsd6RMkjVDRZzb" }
if (-not $key) { throw "ELEVENLABS_API_KEY fehlt." }
$text = "Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden."

$headers = @{
    "xi-api-key" = $key
    "Content-Type" = "application/json"
}

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

$response = Invoke-WebRequest -Uri "https://api.elevenlabs.io/v1/text-to-speech/$voiceId?output_format=mp3_44100_128" -Method POST -Headers $headers -Body $body

if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
    throw "ElevenLabs fehlgeschlagen: $($response.StatusCode)"
}

$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path (Split-Path $scriptPath -Parent) -Parent
$audioDir = Join-Path $projectRoot "public" "audio"
$outputFile = Join-Path $audioDir "project-narration.mp3"

if (!(Test-Path $audioDir)) {
    New-Item -ItemType Directory -Path $audioDir -Force | Out-Null
}

[byte[]]$audioBytes = [System.Convert]::FromBase64String($response.Content)
[System.IO.File]::WriteAllBytes($outputFile, $audioBytes)

$resultData = @{
    model = "eleven_multilingual_v2"
    voiceId = $voiceId
    characters = $text.Length
    text = $text
    output = "public/audio/project-narration.mp3"
}

$mediaProductionDir = Join-Path $projectRoot "media-production"
if (!(Test-Path $mediaProductionDir)) {
    New-Item -ItemType Directory -Path $mediaProductionDir -Force | Out-Null
}

$resultFile = Join-Path $mediaProductionDir "elevenlabs-result.json"
$resultData | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFile -Encoding UTF8

Write-Host "ElevenLabs abgeschlossen: $($text.Length) Zeichen."
