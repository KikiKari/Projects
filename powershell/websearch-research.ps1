#!/usr/bin/env pwsh
# websearch-research.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/websearch-research.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

# Web Search Script: Deep Research für Incidents
# Verwendung: ./websearch-research.sh "Beschreibung des Problems"

param(
    [Parameter(Mandatory=$true)]
    [string]$QUERY,
    
    [string]$OUTPUT_DIR = "./research"
)

if (-not $QUERY) {
    Write-Host "Verwendung: $PSCommandPath `"Problem Beschreibung`" [OUTPUT_DIR]"
    exit 1
}

# Erstelle das Ausgabeverzeichnis, falls es nicht existiert
if (-not (Test-Path -Path $OUTPUT_DIR)) {
    New-Item -ItemType Directory -Path $OUTPUT_DIR | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OUTPUT_FILE = Join-Path $OUTPUT_DIR "incident_$timestamp.md"

# Schreibe Header in die Markdown-Datei
"# Incident Research" | Out-File -FilePath $OUTPUT_FILE -Encoding UTF8
"Datum: $(Get-Date)" | Out-File -FilePath $OUTPUT_FILE -Append -Encoding UTF8
"Query: $QUERY" | Out-File -FilePath $OUTPUT_FILE -Append -Encoding UTF8
"" | Out-File -FilePath $OUTPUT_FILE -Append -Encoding UTF8

# 1. EXA für schnelle Recherche
"## 1. Schnelle Recherche (EXA)" | Out-File -FilePath $OUTPUT_FILE -Append -Encoding UTF8

try {
    $headers = @{
        Authorization = "Bearer $env:OPENROUTER_API_KEY"
        "Content-Type" = "application/json"
    }
    
    $body_exa = @{
        model = "openai/gpt-5.6-terra"
        messages = @(@{ role = "user"; content = $QUERY })
        plugins = @(@{ id = "web"; engine = "exa"; max_results = 5 })
    } | ConvertTo-Json -Depth 10
    
    $response_exa = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" -Method Post -Headers $headers -Body $body_exa
    ($response_exa.choices[0].message.content ?? "Keine Ergebnisse") | Out-File -FilePath $OUTPUT_FILE -Append -Encoding UTF8
} catch {
    "Keine Ergebnisse" | Out-File -FilePath $OUTPUT_FILE -Append -Encoding UTF8
}

"" | Out-File -FilePath $OUTPUT_FILE -Append -Encoding UTF8
"---" | Out-File -FilePath $OUTPUT_FILE -Append -Encoding UTF8

# 2. Verifizierte Quellen (Perplexity) falls verfügbar
"## 2. Verifizierte Fakten (Perplexity)" | Out-File -FilePath $OUTPUT_FILE -Append -Encoding UTF8

try {
    $body_perplexity = @{
        model = "perplexity/sonar:online"
        messages = @(@{ role = "user"; content = "$QUERY troubleshooting" })
    } | ConvertTo-Json -Depth 10
    
    $response_perplexity = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" -Method Post -Headers $headers -Body $body_perplexity
    ($response_perplexity.choices[0].message.content ?? "Keine Ergebnisse") | Out-File -FilePath $OUTPUT_FILE -Append -Encoding UTF8
} catch {
    "Keine Ergebnisse" | Out-File -FilePath $OUTPUT_FILE -Append -Encoding UTF8
}

"" | Out-File -FilePath $OUTPUT_FILE -Append -Encoding UTF8
"Gespeichert in: $OUTPUT_FILE" | Write-Host
