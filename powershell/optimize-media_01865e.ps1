#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "4603526c54fb821ca328ef215882ecd20500ebb9c00b0f3dcd74a8e44cba7a2d", "source_sha256": "01865e120d0e52b50fea21a5f976ac63af413e6829f861a5d31d7898bd4dbaf4", "target_language": "powershell"}
# optimize-media.mjs — portiert nach powershell
# Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# PowerShell 7-Portierung von optimize-media.mjs
# Diese Funktion optimiert PNG-Bilder durch Konvertierung in WebP und AVIF

# Definiere das Verzeichnis relativ zum Skriptverzeichnis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$mediaDirectory = Join-Path $scriptPath ".." "public" "media"

# Überprüfe, ob das Verzeichnis existiert
if (-not (Test-Path $mediaDirectory)) {
    Write-Error "Medienverzeichnis nicht gefunden: $mediaDirectory"
    exit 1
}

# Durchsuche alle PNG-Dateien im Verzeichnis
Get-ChildItem -Path $mediaDirectory -Filter "*.png" | ForEach-Object {
    $sourceFile = $_.FullName
    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    
    # Ziel-Pfade für WebP und AVIF
    $webpTarget = Join-Path $mediaDirectory "$fileNameWithoutExtension.webp"
    $avifTarget = Join-Path $mediaDirectory "$fileNameWithoutExtension.avif"
    
    # Konvertiere zu WebP mit Qualität 84
    magick convert $sourceFile -quality 84 $webpTarget
    
    # Konvertiere zu AVIF mit Qualität 58
    # ImageMagick benötigt möglicherweise ein Plugin für AVIF-Unterstützung
    magick convert $sourceFile -quality 58 $avifTarget
}

Write-Output "WebP- und AVIF-Derivate erzeugt."
