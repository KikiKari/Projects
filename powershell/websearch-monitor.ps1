#!/usr/bin/env pwsh
# websearch-monitor.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/websearch-monitor.sh
# auch in: OpenClaw@gateway2:scripts/websearch-monitor.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Web Search Script: Server-Monitoring mit Tavily
.DESCRIPTION
Sucht nach aktuellen Informationen zu einem Thema, vorzugsweise mit Tavily CLI, alternativ per SearXNG
.PARAMETER Topic
Das Suchthema (Standard: "Linux kernel security updates")
.EXAMPLE
./websearch-monitor.ps1 "Linux kernel security updates"
#>

param(
    [string]$Topic = "Linux kernel security updates"
)

Write-Host "Prüfe: $Topic"

# Prüfe ob Tavily CLI verfügbar ist
if (Get-Command tvly -ErrorAction SilentlyContinue) {
    try {
        $result = tvly search $Topic --topic news --time-range week --max-results 5 --include-answer advanced 2>$null | ConvertFrom-Json
        if ($result.answer) {
            Write-Output $result.answer
        } else {
            Write-Output "Keine Zusammenfassung verfügbar"
        }
    } catch {
        Write-Output "Keine Zusammenfassung verfügbar"
    }
} else {
    # Fallback zu einfacher Web-Suche
    try {
        $encodedTopic = [System.Web.HttpUtility]::UrlEncode($Topic)
        $response = Invoke-RestMethod -Uri "http://localhost:8888/search?q=$encodedTopic&format=json" -ErrorAction Stop
        if ($response.results) {
            $response.results | Select-Object -First 3 | ForEach-Object {
                Write-Output $_.title
                Write-Output $_.url
            }
        } else {
            Write-Output "SearXNG nicht verfügbar"
        }
    } catch {
        Write-Output "SearXNG nicht verfügbar"
    }
}
