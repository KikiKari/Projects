#!/usr/bin/env pwsh
# install_cron.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
# auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Installiert den DB-Maintainer als Cron-Job
#>

# Cron-Job Definition
$CRON_JOB = @"
# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1
"@

function Install-CronJob {
    $workspace = [System.IO.Path]::Combine("/home/openclaw/.openclaw", "workspace")
    $cronFile = [System.IO.Path]::Combine($workspace, "crons", "db-maintainer.cron")
    
    # Erstelle Verzeichnis falls es nicht existiert
    $cronDir = [System.IO.Path]::GetDirectoryName($cronFile)
    if (!(Test-Path $cronDir)) {
        New-Item -ItemType Directory -Path $cronDir -Force | Out-Null
    }
    
    # Schreibe Cron-Datei
    Set-Content -Path $cronFile -Value $CRON_JOB
    
    Write-Host "✅ Cron-Job installiert: $cronFile"
    Write-Host "   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron"
    
    # Auch in OpenClaw cron registrieren
    $jobsJson = [System.IO.Path]::Combine($workspace, ".openclaw", "cron", "jobs.json")
    if (Test-Path $jobsJson) {
        $jobs = Get-Content -Path $jobsJson -Raw | ConvertFrom-Json
        
        # Erstelle oder aktualisiere den db-maintainer Eintrag
        $jobs | Add-Member -NotePropertyName 'db-maintainer' -NotePropertyValue @{
            schedule = '*/30 * * * *'
            command = 'python3 skills/db-maintainer/scripts/db_maintainer.py'
            enabled = $true
        } -Force
        
        # Konvertiere zurück zu JSON und speichere
        $jobs | ConvertTo-Json -Depth 10 | Set-Content -Path $jobsJson
        
        Write-Host "✅ In OpenClaw cron registriert"
    }
}

# Hauptausführung
Install-CronJob
