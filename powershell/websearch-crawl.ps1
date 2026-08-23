#!/usr/bin/env pwsh
# websearch-crawl.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/websearch-crawl.sh
# auch in: OpenClaw@gateway2:scripts/websearch-crawl.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Web Search Script: Website Crawling mit Firecrawl
.DESCRIPTION
Startet einen Crawlvorgang auf einer Webseite über die Firecrawl-API und speichert das Ergebnis.
.PARAMETER WebsiteUrl
Die URL der zu crawlenden Webseite.
.PARAMETER OutputDir
Das Ausgabeverzeichnis für die Crawldaten (Standard: ./crawled).
.EXAMPLE
./websearch-crawl.ps1 https://beispiel.de ./ergebnisse
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$WebsiteUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "./crawled"
)

# API-Key ermitteln
$firecrawlApiKey = $env:FIRECRAWL_API_KEY
if (-not $firecrawlApiKey) {
    $openclawEnvPath = "$env:USERPROFILE/.openclaw/openclaw.env"
    if (Test-Path $openclawEnvPath) {
        $content = Get-Content $openclawEnvPath
        foreach ($line in $content) {
            if ($line -match 'OPENROUTER') {
                $firecrawlApiKey = ($line -split '"')[1]
                break
            }
        }
    }
}

if (-not $firecrawlApiKey) {
    Write-Error "FIRECRAWL_API_KEY nicht gefunden"
    exit 1
}

# Ausgabeverzeichnis erstellen
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Write-Host "Crawling $WebsiteUrl..."

# Crawl starten
$headers = @{
    "Authorization" = "Bearer $firecrawlApiKey"
    "Content-Type" = "application/json"
}

$body = @{
    url = $WebsiteUrl
    limit = 100
    scrapeOptions = @{
        formats = @("markdown")
    }
} | ConvertTo-Json

try {
    $crawlResponse = Invoke-RestMethod -Uri "https://api.firecrawl.dev/v1/crawl" -Method Post -Headers $headers -Body $body
} catch {
    Write-Error "Fehler beim Starten des Crawls: $_"
    exit 1
}

$crawlId = $crawlResponse.id
if (-not $crawlId) {
    Write-Error "Fehler: Crawl konnte nicht gestartet werden"
    $crawlResponse | ConvertTo-Json
    exit 1
}

Write-Host "Crawl ID: $crawlId"

# Status prüfen
while ($true) {
    try {
        $statusResponse = Invoke-RestMethod -Uri "https://api.firecrawl.dev/v1/crawl/$crawlId" -Headers $headers
    } catch {
        Write-Error "Fehler beim Abrufen des Status: $_"
        exit 1
    }
    
    $status = $statusResponse.status
    if (-not $status) { $status = "unknown" }
    
    Write-Host "Status: $status"
    
    if ($status -eq "completed") {
        $outputFile = Join-Path $OutputDir "$(Get-Date -Format 'yyyyMMdd')_crawl.json"
        $statusResponse | ConvertTo-Json -Depth 10 | Set-Content $outputFile
        Write-Host "Gespeichert in $OutputDir"
        break
    } elseif ($status -eq "failed") {
        Write-Error "Crawl fehlgeschlagen"
        exit 1
    }
    
    Start-Sleep -Seconds 5
}
