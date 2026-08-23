#!/usr/bin/env pwsh
# websearch-research.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway2:scripts/websearch-research.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

# Web Search Script: Deep Research für Incidents
# Verwendung: ./websearch-research.ps1 "Beschreibung des Problems"

param(
    [Parameter(Mandatory=$true)]
    [string]$Query,
    
    [string]$OutputDir = "./research"
)

if (-not $env:OPENROUTER_API_KEY) {
    Write-Host "Fehler: OPENROUTER_API_KEY Umgebungsvariable nicht gesetzt"
    exit 1
}

# Erstelle Ausgabeverzeichnis
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFile = Join-Path $OutputDir "incident_$timestamp.md"

# Initialisiere Ausgabedatei
"# Incident Research" | Set-Content $outputFile
"Datum: $(Get-Date)" | Add-Content $outputFile
"Query: $Query" | Add-Content $outputFile
"" | Add-Content $outputFile

Write-Host "Starte Recherche..."

# 1. EXA für schnelle Recherche
"## 1. Schnelle Recherche (EXA)" | Add-Content $outputFile

$bodyExa = @{
    model = "openai/gpt-5.4-mini"
    messages = @(@{role="user"; content=$Query})
    plugins = @(@{id="web"; engine="exa"; max_results=5})
} | ConvertTo-Json -Depth 10

try {
    $responseExa = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" `
        -Method Post `
        -Headers @{Authorization="Bearer $($env:OPENROUTER_API_KEY)"} `
        -ContentType "application/json" `
        -Body $bodyExa
    
    $contentExa = if ($responseExa.choices[0].message.content) { 
        $responseExa.choices[0].message.content 
    } else { 
        "Keine Ergebnisse" 
    }
    $contentExa | Add-Content $outputFile
}
catch {
    "Keine Ergebnisse (Fehler: $($_.Exception.Message))" | Add-Content $outputFile
}

"" | Add-Content $outputFile
"---" | Add-Content $outputFile

# 2. Verifizierte Quellen (Perplexity) falls verfügbar
"## 2. Verifizierte Fakten (Perplexity)" | Add-Content $outputFile

$bodyPerplexity = @{
    model = "perplexity/sonar:online"
    messages = @(@{role="user"; content="$Query troubleshooting"})
} | ConvertTo-Json -Depth 10

try {
    $responsePerplexity = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" `
        -Method Post `
        -Headers @{Authorization="Bearer $($env:OPENROUTER_API_KEY)"} `
        -ContentType "application/json" `
        -Body $bodyPerplexity
    
    $contentPerplexity = if ($responsePerplexity.choices[0].message.content) { 
        $responsePerplexity.choices[0].message.content 
    } else { 
        "Keine Ergebnisse" 
    }
    $contentPerplexity | Add-Content $outputFile
}
catch {
    "Keine Ergebnisse (Fehler: $($_.Exception.Message))" | Add-Content $outputFile
}

"" | Add-Content $outputFile
"Gespeichert in: $outputFile" | Add-Content $outputFile

Write-Host "Recherche abgeschlossen!"
