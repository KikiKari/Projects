#!/usr/bin/env pwsh
# build_artifact.py — portiert nach powershell
# Quelle: python, Projects@Telegram-Monitor:build_artifact.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Baut aus web/artifact_template.html + data/latest.json die fertige
Uebersichtsseite telegram-monitor-uebersicht.html (eine Datei, offline nutzbar).

.DESCRIPTION
  python cli.py scan --json > /tmp/scan.json     # optional: frische Daten
  python build_artifact.py

#>

param(
    [string]$DataPath = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$TemplatePath = Join-Path $ScriptDir "web" "artifact_template.html"
$DefaultDataPath = Join-Path $ScriptDir "data" "latest.json"
$OutPath = Join-Path (Split-Path -Parent $ScriptDir) "telegram-monitor-uebersicht.html"

if (-not $DataPath) {
    $DataPath = $DefaultDataPath
}

function Build-Artifact {
    param(
        [string]$dataPath = $DataPath,
        [string]$outPath = $OutPath
    )
    
    $tpl = Get-Content -Path $TemplatePath -Encoding Utf8 -Raw
    $data = Get-Content -Path $dataPath -Encoding Utf8 -Raw | ConvertFrom-Json
    $payload = $data | ConvertTo-Json -Depth 100 -EscapeHandling EscapeNonAscii
    # Replace </ with <\/ to prevent script tag termination
    $payload = $payload -replace "</", "<\/"
    $html = $tpl -replace "/\*__DATA__\*/\{\}", $payload
    Set-Content -Path $outPath -Value $html -Encoding Utf8
    
    return $outPath
}

$path = Build-Artifact
$size = (Get-Item $path).Length
Write-Output "geschrieben: $path ($size Bytes)"
