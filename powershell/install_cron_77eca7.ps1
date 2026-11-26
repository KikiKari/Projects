#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "93b457952030508385f735749a6d506e47b860b51e64a932f5eb131e7282731f", "source_sha256": "77eca70a7a8f9c0ff8dc240b14d8c37999854c241e031b8167e1fcd650cbd334", "target_language": "powershell"}
# install_cron.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
# auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Installiert den DB-Maintainer als Cron-Job
#>

$CRON_JOB = @"
# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1
"@

function Install-CronJob {
    $workspace = [System.IO.Path]::Combine("/home/openclaw/.openclaw", "workspace")
    $cronFile = [System.IO.Path]::Combine($workspace, "crons", "db-maintainer.cron")
    
    # Erstelle das Verzeichnis falls es nicht existiert
    $cronDir = [System.IO.Path]::GetDirectoryName($cronFile)
    if (-not (Test-Path $cronDir)) {
        New-Item -ItemType Directory -Path $cronDir -Force | Out-Null
    }
    
    # Schreibe die Cron-Job Definition in die Datei
    [System.IO.File]::WriteAllText($cronFile, $CRON_JOB.Trim())
    
    Write-Host "✅ Cron-Job installiert: $cronFile"
    Write-Host "   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron"
    
    # Auch in OpenClaw cron registrieren
    $jobsJson = [System.IO.Path]::Combine($workspace, ".openclaw", "cron", "jobs.json")
    if (Test-Path $jobsJson) {
        $jobs = Get-Content $jobsJson | ConvertFrom-Json
        
        # Falls jobs kein Hashtable ist, konvertiere es
        if ($jobs -is [PSCustomObject]) {
            $jobs = $jobs | ConvertTo-Hashtable
        }
        
        $jobs['db-maintainer'] = @{
            schedule = '*/30 * * * *'
            command = 'python3 skills/db-maintainer/scripts/db_maintainer.py'
            enabled = $true
        }
        
        $jobs | ConvertTo-Json -Depth 10 | Set-Content $jobsJson
        
        Write-Host "✅ In OpenClaw cron registriert"
    }
}

# Hilfsfunktion um PSCustomObject in Hashtable zu konvertieren
function ConvertTo-Hashtable {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [PSCustomObject]$InputObject
    )
    
    process {
        if ($null -eq $InputObject) { return $null }
        
        $hashtable = @{}
        $InputObject.PSObject.Properties | ForEach-Object {
            $value = $_.Value
            if ($value -is [PSCustomObject]) {
                $hashtable[$_.Name] = $value | ConvertTo-Hashtable
            } elseif ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) {
                $array = @()
                foreach ($item in $value) {
                    if ($item -is [PSCustomObject]) {
                        $array += ,$item | ConvertTo-Hashtable
                    } else {
                        $array += $item
                    }
                }
                $hashtable[$_.Name] = $array
            } else {
                $hashtable[$_.Name] = $value
            }
        }
        return $hashtable
    }
}

# Hauptausführung
Install-CronJob
