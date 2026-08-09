#!/usr/bin/env pwsh
# optimize-media.mjs — portiert nach powershell
# Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# PowerShell 7-Portierung von optimize-media.mjs
# Erzeugt WebP- und AVIF-Derivate aus PNG-Dateien im Verzeichnis ../public/media/

# Basisverzeichnis bestimmen (relativ zum Skript)
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$mediaDirectory = Join-Path $scriptPath ".." "public" "media"

# Überprüfen, ob das Verzeichnis existiert
if (-not (Test-Path $mediaDirectory)) {
    Write-Error "Verzeichnis nicht gefunden: $mediaDirectory"
    exit 1
}

# Alle PNG-Dateien im Verzeichnis durchlaufen
Get-ChildItem -Path $mediaDirectory -Filter "*.png" | ForEach-Object {
    $sourceFile = $_.FullName
    $fileNameWithoutExtension = $_.BaseName
    
    # Ziel-Dateinamen für WebP und AVIF
    $webpFile = Join-Path $mediaDirectory "$fileNameWithoutExtension.webp"
    $avifFile = Join-Path $mediaDirectory "$fileNameWithoutExtension.avif"
    
    # WebP-Konvertierung mit 84% Qualität
    magick convert $sourceFile -quality 84 $webpFile
    
    # AVIF-Konvertierung mit 58% Qualität
    magick convert $sourceFile -quality 58 $avifFile
}

Write-Host "WebP- und AVIF-Derivate erzeugt."
