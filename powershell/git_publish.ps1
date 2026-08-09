#!/usr/bin/env pwsh
# git_publish.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
# auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Git Publish Agent - Automatisierte Skill-Veröffentlichung

.DESCRIPTION
Dieses Skript ermöglicht das automatische Committen und Veröffentlichen von Skills
über Git und ClawHub. Es unterstützt sowohl einzelne Skills als auch Batch-Operationen.
#>

param(
    [string]$Skill,
    [switch]$All,
    [switch]$NoPublish,
    [string]$Message
)

# Konfiguration
$SKILLS_DIR = Join-Path $env:USERPROFILE ".openclaw" "workspace" "skills"

function Invoke-GitCommit {
    param(
        [string]$SkillPath,
        [string]$CommitMessage
    )
    
    if (-not $CommitMessage) {
        $timestamp = Get-Date -Format "o"
        $skillName = Split-Path $SkillPath -Leaf
        $CommitMessage = "[skill] Auto-update $skillName - $timestamp"
    }
    
    # Gehe zum übergeordneten Verzeichnis von SKILLS_DIR
    $parentDir = Split-Path $SKILLS_DIR -Parent
    
    # Füge Skill zum Git-Index hinzu
    & git add $SkillPath 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Fehler beim Hinzufügen des Skills zum Git-Index"
        return $false
    }
    
    # Erstelle Commit
    $result = & git commit -m $CommitMessage 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Commit fehlgeschlagen oder keine Änderungen vorhanden"
        return $false
    }
    
    Write-Host "Commit erfolgreich erstellt"
    return $true
}

function Invoke-ClawHubPublish {
    param([string]$SkillName)
    
    $skillPath = Join-Path $SKILLS_DIR $SkillName
    
    # Veröffentliche auf ClawHub
    $result = & clawhub publish $skillPath --slug $SkillName --version "1.0.0" 2>&1
    $success = ($LASTEXITCODE -eq 0)
    
    return @{
        Success = $success
        Output = ($result -join "`n")
    }
}

function Invoke-BatchPublish {
    # Prüfe Git-Status
    $statusResult = & git status --short $SKILLS_DIR 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Git-Status konnte nicht abgerufen werden"
        return
    }
    
    # Extrahiere geänderte Skills
    $changed = @()
    foreach ($line in $statusResult) {
        if ($line.Trim() -and $line.Contains("skills/")) {
            $parts = $line.Split("skills/", 2)[1].Split("/")[0]
            if ($parts -and $changed -notcontains $parts) {
                $changed += $parts
            }
        }
    }
    
    Write-Host "Geänderte Skills: $($changed -join ', ')"
    
    # Veröffentliche mit Begrenzung (max. 5 pro Batch)
    for ($i = 0; $i -lt [Math]::Min($changed.Count, 5); $i++) {
        $skill = $changed[$i]
        
        if ($i -gt 0) {
            Write-Host "Warte 15min wegen Rate-Limit..."
            # In real: Start-Sleep -Seconds 900
        }
        
        Write-Host "Veröffentliche $skill..."
        $commitOk = Invoke-GitCommit -SkillPath (Join-Path $SKILLS_DIR $skill)
        
        if ($commitOk) {
            $publishResult = Invoke-ClawHubPublish -SkillName $skill
            $symbol = if ($publishResult.Success) { "✓" } else { "✗" }
            Write-Host "  $symbol $($publishResult.Output)"
        }
    }
}

# Hauptlogik
if ($Skill) {
    $skillPath = Join-Path $SKILLS_DIR $Skill
    
    if ($NoPublish) {
        Invoke-GitCommit -SkillPath $skillPath -CommitMessage $Message
    } else {
        Invoke-GitCommit -SkillPath $skillPath -CommitMessage $Message
        $publishResult = Invoke-ClawHubPublish -SkillName $Skill
        Write-Host $publishResult.Output
    }
} elseif ($All) {
    Invoke-BatchPublish
} else {
    Write-Host "Verwendung: --Skill <Name> oder --All"
}
