#!/usr/bin/env pwsh
# sync_agent.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/clawhub-git-sync-agent/scripts/sync_agent.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Permanenter ClawHub ↔ Git Sync Agent
.DESCRIPTION
Multi-Node fähig, stündliche Ausführung
#>

param(
    [switch]$DryRun
)

# Import sync functions
$scriptPath = "/home/openclaw/.openclaw/workspace/scripts"
$env:PYTHONPATH = $scriptPath
$syncScript = Join-Path $scriptPath "sync_clawhub_git.py"

# Prüfe ob Python verfügbar ist
try {
    $pythonCmd = Get-Command python3 -ErrorAction Stop
} catch {
    try {
        $pythonCmd = Get-Command python -ErrorAction Stop
    } catch {
        Write-Error "Python nicht gefunden"
        exit 1
    }
}

function Invoke-PythonFunction {
    param(
        [string]$FunctionName,
        [object[]]$Arguments = @()
    )
    
    $jsonArgs = $Arguments | ConvertTo-Json -Compress
    $scriptBlock = @"
import sys
import json
sys.path.append('$scriptPath')
from sync_clawhub_git import $FunctionName
args = json.loads('$jsonArgs')
result = $FunctionName(*args) if args else $FunctionName()
print(json.dumps(result))
"@
    
    $result = & $pythonCmd -c $scriptBlock 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Fehler beim Aufruf von Python-Funktion: $FunctionName"
    }
    return $result | ConvertFrom-Json
}

function Invoke-SyncToGit {
    param([string]$SkillName, [bool]$DryRunParam)
    return Invoke-PythonFunction -FunctionName "sync_to_git" -Arguments @($SkillName, $DryRunParam)
}

function Invoke-SyncToClawhub {
    param([string]$SkillName, [bool]$DryRunParam)
    return Invoke-PythonFunction -FunctionName "sync_to_clawhub" -Arguments @($SkillName, $DryRunParam)
}

function Invoke-ValidateSkill {
    param([string]$Path)
    return Invoke-PythonFunction -FunctionName "validate_skill" -Arguments @($Path)
}

function Get-FileHashPython {
    param([string]$FilePath)
    return Invoke-PythonFunction -FunctionName "get_file_hash" -Arguments @($FilePath)
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    # Auch an Python-log weiterleiten
    $null = Invoke-PythonFunction -FunctionName "log" -Arguments @($Message, $Level)
}

function Get-AllSkills {
    $clawhubSkills = @()
    $gitSkills = @()
    
    if (Test-Path $CLAWHUB_DIR) {
        Get-ChildItem -Path $CLAWHUB_DIR -Directory | Where-Object {
            (-not $_.Name.StartsWith('.') -and -not $_.Name.StartsWith('_')) -and 
            (Test-Path (Join-Path $_.FullName "SKILL.md") -PathType Leaf)
        } | ForEach-Object {
            $clawhubSkills += $_.Name
        }
    }
    
    if (Test-Path $GIT_DIR) {
        Get-ChildItem -Path $GIT_DIR -Directory | Where-Object {
            (-not $_.Name.StartsWith('.') -and -not $_.Name.StartsWith('_')) -and 
            (Test-Path (Join-Path $_.FullName "SKILL.md") -PathType Leaf)
        } | ForEach-Object {
            $gitSkills += $_.Name
        }
    }
    
    return ($clawhubSkills + $gitSkills) | Sort-Object -Unique
}

function Initialize-GitRepo {
    param([string]$SkillPath, [string]$SkillName)
    
    $gitDir = Join-Path $SkillPath ".git"
    if (-not (Test-Path $gitDir)) {
        Push-Location $SkillPath
        try {
            $null = git init 2>$null
            $null = git add . 2>$null
            $null = git commit -m "Initial commit: $SkillName skill" 2>$null
            Write-Log "Git initialized for $SkillName"
        } finally {
            Pop-Location
        }
    }
}

function Backup-SkillDir {
    param([string]$SkillPath, [string]$SkillName)
    
    if (-not (Test-Path $SkillPath)) {
        return
    }
    
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $backupDir = Join-Path $BACKUP_ROOT $timestamp
    
    if (-not (Test-Path $backupDir)) {
        $null = New-Item -ItemType Directory -Path $backupDir -Force
    }
    
    $archiveName = "${SkillName}_${timestamp}.tar.gz"
    $archivePath = Join-Path $backupDir $archiveName
    
    # Erstelle tar.gz Archiv
    $tempDir = [System.IO.Path]::GetTempPath()
    $tempArchive = Join-Path $tempDir ([System.IO.Path]::GetRandomFileName())
    
    try {
        # Erstelle tar
        $null = tar -czf "$tempArchive.tar.gz" -C $SkillPath . 2>$null
        Move-Item "$tempArchive.tar.gz" $archivePath -Force
        Write-Log "Backup created for $SkillName at $archivePath"
    } catch {
        Write-Log "Failed to create backup for $SkillName" "ERROR"
    }
}

function Get-Hashes {
    param([string]$SkillDir)
    
    $hashes = @{}
    Get-ChildItem -Path $SkillDir -Recurse -File | Where-Object {
        $_.FullName -notlike "*.git*"
    } | ForEach-Object {
        $relativePath = $_.FullName.Replace("$SkillDir\", "").Replace("\", "/")
        $hash = Get-FileHashPython -FilePath $_.FullName
        $hashes[$relativePath] = $hash
    }
    return $hashes
}

function Sync-SkillBidirectional {
    param([string]$SkillName, [bool]$DryRunParam)
    
    $clawhubPath = Join-Path $CLAWHUB_DIR $SkillName
    $gitPath = Join-Path $GIT_DIR $SkillName
    
    # Fall 1: Nur in ClawHub → zu Git
    if ((Test-Path $clawhubPath) -and -not (Test-Path $gitPath)) {
        Write-Log "NEW in ClawHub: $SkillName → syncing to Git"
        if (-not $DryRunParam) {
            Backup-SkillDir -SkillPath $clawhubPath -SkillName "${SkillName}_clawhub"
        }
        if (Invoke-SyncToGit -SkillName $SkillName -DryRunParam $DryRunParam) {
            if (-not $DryRunParam) {
                Initialize-GitRepo -SkillPath $gitPath -SkillName $SkillName
            }
            return "synced_to_git"
        }
    }
    # Fall 2: Nur in Git → zu ClawHub
    elseif ((Test-Path $gitPath) -and -not (Test-Path $clawhubPath)) {
        Write-Log "NEW in Git: $SkillName → syncing to ClawHub"
        if (-not $DryRunParam) {
            Backup-SkillDir -SkillPath $gitPath -SkillName "${SkillName}_git"
        }
        if (Invoke-SyncToClawhub -SkillName $SkillName -DryRunParam $DryRunParam) {
            return "synced_to_clawhub"
        }
    }
    # Fall 3: In beiden vorhanden → Vergleiche Timestamps
    elseif ((Test-Path $clawhubPath) -and (Test-Path $gitPath)) {
        # Stelle sicher, dass beide als gültige Skills validiert werden
        if (-not (Invoke-ValidateSkill -Path $clawhubPath)) {
            Write-Log "Validation failed for ClawHub skill: $SkillName" "ERROR"
            return "error"
        }
        if (-not (Invoke-ValidateSkill -Path $gitPath)) {
            Write-Log "Validation failed for Git skill: $SkillName" "ERROR"
            return "error"
        }
        
        # Berechne Hashes für clawhub und git
        $clawhubHashes = Get-Hashes -SkillDir $clawhubPath
        $gitHashes = Get-Hashes -SkillDir $gitPath
        
        $hashesEqual = $true
        if ($clawhubHashes.Count -ne $gitHashes.Count) {
            $hashesEqual = $false
        } else {
            foreach ($key in $clawhubHashes.Keys) {
                if (-not $gitHashes.ContainsKey($key) -or $clawhubHashes[$key] -ne $gitHashes[$key]) {
                    $hashesEqual = $false
                    break
                }
            }
        }
        
        if (-not $hashesEqual) {
            Write-Log "Content difference detected for: $SkillName"
            
            $clawhubInfo = Get-Item $clawhubPath
            $gitInfo = Get-Item $gitPath
            $direction = if ($clawhubInfo.LastWriteTime -ge $gitInfo.LastWriteTime) { "to-git" } else { "to-clawhub" }
            
            Write-Log "UPDATE: $SkillName → syncing $direction"
            if (-not $DryRunParam) {
                Backup-SkillDir -SkillPath $clawhubPath -SkillName "${SkillName}_clawhub"
                Backup-SkillDir -SkillPath $gitPath -SkillName "${SkillName}_git"
            }
            
            if ($direction -eq "to-git") {
                if (Invoke-SyncToGit -SkillName $SkillName -DryRunParam $DryRunParam) {
                    if (-not $DryRunParam) {
                        Push-Location $gitPath
                        try {
                            $null = git add . 2>$null
                            $commitMsg = "Sync from ClawHub content diff: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
                            $null = git commit -m $commitMsg 2>$null
                        } finally {
                            Pop-Location
                        }
                    }
                    return "updated_git"
                } else {
                    Write-Log "Failed to sync $SkillName to Git after content diff" "ERROR"
                    return "error"
                }
            } else {
                if (Invoke-SyncToClawhub -SkillName $SkillName -DryRunParam $DryRunParam) {
                    return "updated_clawhub"
                } else {
                    Write-Log "Failed to sync $SkillName to ClawHub after content diff" "ERROR"
                    return "error"
                }
            }
        } else {
            Write-Log "Content is identical for: $SkillName"
            return "no_change"
        }
    }
    
    return "no_change"
}

function Load-State {
    if (Test-Path $STATE_FILE) {
        $content = Get-Content $STATE_FILE -Raw
        if ($content) {
            return $content | ConvertFrom-Json
        }
    }
    return @{
        sync_history = @()
        pending = @()
    }
}

function Save-State {
    param([object]$State)
    
    $stateDir = Split-Path $STATE_FILE -Parent
    if (-not (Test-Path $stateDir)) {
        $null = New-Item -ItemType Directory -Path $stateDir -Force
    }
    
    $State | ConvertTo-Json -Depth 10 | Set-Content $STATE_FILE
}

# Konstanten
$CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills"
$GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills"
$STATE_FILE = "/home/openclaw/.openclaw/workspace/db/sync_state.json"
$BACKUP_ROOT = "/home/openclaw/.openclaw/workspace/backups/sync_agent"

# Hauptfunktion
Write-Log "=== ClawHub ↔ Git Sync Agent gestartet ==="

$state = Load-State
$allSkills = Get-AllSkills
Write-Log "Gefundene Skills: $($allSkills.Count)"

$results = @{
    synced_to_git = @()
    synced_to_clawhub = @()
    updated_git = @()
    updated_clawhub = @()
    no_change = @()
    errors = @()
}

foreach ($skill in ($allSkills | Sort-Object)) {
    try {
        $result = Sync-SkillBidirectional -SkillName $skill -DryRunParam $DryRun
        $results[$result] += $skill
    } catch {
        Write-Log "ERROR syncing $skill`: $($_.Exception.Message)" "ERROR"
        $results["errors"] += $skill
    }
}

# Zusammenfassung
Write-Log "`n=== SYNC ZUSAMMENFASSUNG ==="
Write-Log "Neu in Git: $($results.synced_to_git.Count) - $($results.synced_to_git -join ', ')"
Write-Log "Neu in ClawHub: $($results.synced_to_clawhub.Count) - $($results.synced_to_clawhub -join ', ')"
Write-Log "Git aktualisiert: $($results.updated_git.Count) - $($results.updated_git -join ', ')"
Write-Log "ClawHub aktualisiert: $($results.updated_clawhub.Count) - $($results.updated_clawhub -join ', ')"
Write-Log "Keine Änderung: $($results.no_change.Count)"
Write-Log "Fehler: $($results.errors.Count) - $($results.errors -join ', ')"

# Ein Dry-Run bleibt vollständig nicht-mutierend (abgesehen vom Audit-Log).
if (-not $DryRun) {
    if (-not $state.sync_history) {
        $state.sync_history = @()
    }
    
    $historyEntry = @{
        timestamp = (Get-Date).ToString("o")
        results = $results
    }
    $state.sync_history += $historyEntry
    
    # Nur letzte 100 Einträge behalten
    if ($state.sync_history.Count -gt 100) {
        $state.sync_history = $state.sync_history | Select-Object -Last 100
    }
    
    Save-State -State $state
}

Write-Log "=== Sync Agent beendet ===`n"
