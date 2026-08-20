#!/usr/bin/env pwsh
# sync_status.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/sync_status.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/sync_status.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

<#
Sync Status - Zeigt Status aller Skills
#>

# Import sync functions
$scriptPath = "/home/openclaw/.openclaw/workspace/scripts"
if ($env:PATH -notlike "*$scriptPath*") {
    $env:PATH += ":$scriptPath"
}

# Try to load the Get-FileHash function from external script
try {
    . "/home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.ps1"
} catch {
    # Fallback implementation if external script is not available
    function Get-FileHashFallback {
        param(
            [string]$Path
        )
        $hash = Get-FileHash -Path $Path -Algorithm SHA256
        return $hash.Hash
    }
    Set-Alias -Name Get-FileHash -Value Get-FileHashFallback -Scope Global
}

$CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills"
$GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills"
$STATE_FILE = "/home/openclaw/.openclaw/workspace/db/sync_state.json"

function Check-SkillStatus {
    param(
        [string]$SkillName
    )
    
    $clawhubPath = Join-Path $CLAWHUB_DIR $SkillName
    $gitPath = Join-Path $GIT_DIR $SkillName
    
    $status = @{
        name = $SkillName
        in_clawhub = Test-Path $clawhubPath -PathType Container
        in_git = Test-Path $gitPath -PathType Container
        has_git_repo = if (Test-Path $gitPath -PathType Container) { Test-Path (Join-Path $gitPath ".git") } else { $false }
        status = "unknown"
        last_modified = @{}
    }
    
    # Status bestimmen
    if ($status.in_clawhub -and -not $status.in_git) {
        $status.status = "only_clawhub"
    } elseif ($status.in_git -and -not $status.in_clawhub) {
        $status.status = "only_git"
    } elseif ($status.in_clawhub -and $status.in_git) {
        # Timestamps vergleichen
        try {
            $clawhubFiles = Get-ChildItem -Path $clawhubPath -Recurse -File | Where-Object { $_.Name -notlike ".*" }
            $gitFiles = Get-ChildItem -Path $gitPath -Recurse -File | Where-Object { $_.FullName -notlike "*.git*" -and $_.Name -notlike ".*" }
            
            if ($clawhubFiles.Count -gt 0) {
                $clawhubLatest = ($clawhubFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
                $status.last_modified.clawhub = $clawhubLatest.ToString('yyyy-MM-dd HH:mm:ss')
            }
            
            if ($gitFiles.Count -gt 0) {
                $gitLatest = ($gitFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
                $status.last_modified.git = $gitLatest.ToString('yyyy-MM-dd HH:mm:ss')
            }
            
            if ($null -ne $clawhubLatest -and $null -ne $gitLatest) {
                $timeDiff = [Math]::Abs(($clawhubLatest - $gitLatest).TotalSeconds)
                
                if ($timeDiff -lt 60) {
                    $status.status = "synced"
                } elseif ($clawhubLatest -gt $gitLatest) {
                    $status.status = "clawhub_newer"
                } else {
                    $status.status = "git_newer"
                }
            } else {
                $status.status = "error"
            }
        } catch {
            $status.status = "error"
        }
    }
    
    return $status
}

function Main {
    Write-Host ("=" * 80)
    Write-Host "ClawHub ↔ Git Sync Status"
    Write-Host ("=" * 80)
    Write-Host "Zeitpunkt: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host ""
    
    # Alle Skills finden
    $allSkills = @{}
    
    if (Test-Path $CLAWHUB_DIR) {
        Get-ChildItem -Path $CLAWHUB_DIR -Directory | Where-Object { !$_.Name.StartsWith('.') } | ForEach-Object {
            $allSkills[$_.Name] = $true
        }
    }
    
    if (Test-Path $GIT_DIR) {
        Get-ChildItem -Path $GIT_DIR -Directory | Where-Object { !$_.Name.StartsWith('.') } | ForEach-Object {
            $allSkills[$_.Name] = $true
        }
    }
    
    # Status-Kategorien
    $categories = @{
        synced = @()
        clawhub_newer = @()
        git_newer = @()
        only_clawhub = @()
        only_git = @()
        error = @()
    }
    
    # Status für jeden Skill prüfen
    $sortedSkills = $allSkills.Keys | Sort-Object
    foreach ($skill in $sortedSkills) {
        $status = Check-SkillStatus -SkillName $skill
        $categories[$status.status] += $status
    }
    
    # Ausgabe
    Write-Host "📊 Gesamt: $($allSkills.Count) Skills`n"
    
    # Synchronisiert
    if ($categories.synced.Count -gt 0) {
        Write-Host "✅ Synchronisiert ($($categories.synced.Count))"
        foreach ($s in $categories.synced) {
            Write-Host "   - $($s.name)"
        }
        Write-Host ""
    }
    
    # ClawHub neuer
    if ($categories.clawhub_newer.Count -gt 0) {
        Write-Host "🔄 ClawHub neuer ($($categories.clawhub_newer.Count))"
        foreach ($s in $categories.clawhub_newer) {
            Write-Host "   - $($s.name) (ClawHub: $($s.last_modified.clawhub))"
        }
        Write-Host ""
    }
    
    # Git neuer
    if ($categories.git_newer.Count -gt 0) {
        Write-Host "🔄 Git neuer ($($categories.git_newer.Count))"
        foreach ($s in $categories.git_newer) {
            Write-Host "   - $($s.name) (Git: $($s.last_modified.git))"
        }
        Write-Host ""
    }
    
    # Nur in ClawHub
    if ($categories.only_clawhub.Count -gt 0) {
        Write-Host "📦 Nur in ClawHub ($($categories.only_clawhub.Count))"
        foreach ($s in $categories.only_clawhub) {
            Write-Host "   - $($s.name)"
        }
        Write-Host ""
    }
    
    # Nur in Git
    if ($categories.only_git.Count -gt 0) {
        Write-Host "📁 Nur in Git ($($categories.only_git.Count))"
        foreach ($s in $categories.only_git) {
            Write-Host "   - $($s.name)"
        }
        Write-Host ""
    }
    
    # Fehler
    if ($categories.error.Count -gt 0) {
        Write-Host "❌ Fehler ($($categories.error.Count))"
        foreach ($s in $categories.error) {
            Write-Host "   - $($s.name)"
        }
        Write-Host ""
    }
    
    # State-File Info
    if (Test-Path $STATE_FILE) {
        try {
            $stateContent = Get-Content -Path $STATE_FILE -Raw | ConvertFrom-Json
            $lastRuns = $stateContent.PSObject.Properties.Name -contains "last_sync" ? ($stateContent.last_sync.PSObject.Properties.Name) : @()
            if ($lastRuns.Count -gt 0) {
                $lastRun = $lastRuns | Sort-Object | Select-Object -Last 1
                Write-Host "📅 Letzter automatischer Sync: $lastRun"
            }
        } catch {
            # Ignore errors when reading state file
        }
    }
    
    Write-Host ("=" * 80)
}

Main
