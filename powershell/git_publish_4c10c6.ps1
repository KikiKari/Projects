#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "64148fc652bb86cb3f98dabb9118bad1f0741ea1a14751c9150dff13301356b7", "source_sha256": "4c10c6b6fd911cb95da119f761f402073d1a836cab6b40a9f3b989536d5df5ec", "target_language": "powershell"}
# git_publish.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
# auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Git Publish Agent - Automatisierte Skill-Veröffentlichung
#>

param(
    [string]$Skill,
    [switch]$All,
    [switch]$NoPublish,
    [string]$Message
)

$SKILLS_DIR = Join-Path $env:USERPROFILE ".openclaw/workspace/skills"

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
    
    Push-Location (Split-Path $SKILLS_DIR -Parent)
    try {
        git add $SkillPath
        $result = git commit -m $CommitMessage 2>&1
        return $LASTEXITCODE -eq 0
    } finally {
        Pop-Location
    }
}

function Invoke-ClawHubPublish {
    param([string]$SkillName)
    
    $skillPath = Join-Path $SKILLS_DIR $SkillName
    $output = clawhub publish $skillPath --slug $SkillName --version "1.0.0" 2>&1
    $success = $LASTEXITCODE -eq 0
    return @{
        Success = $success
        Output = $output
    }
}

function Invoke-BatchPublish {
    $statusOutput = git status --short $SKILLS_DIR 2>&1
    $changed = @()
    
    foreach ($line in $statusOutput) {
        $lineStr = $line.ToString().Trim()
        if ($lineStr -and $lineStr.Contains("skills/")) {
            $parts = $lineStr.Split("skills/")
            if ($parts.Count -gt 1) {
                $skillPart = $parts[1].Split("/")[0]
                if ($changed -notcontains $skillPart) {
                    $changed += $skillPart
                }
            }
        }
    }
    
    Write-Host "Changed skills: $($changed -join ', ')"
    
    $batchLimit = [Math]::Min(5, $changed.Count)
    for ($i = 0; $i -lt $batchLimit; $i++) {
        $skill = $changed[$i]
        if ($i -gt 0) {
            Write-Host "Waiting 15min for rate limit..."
            # In real: Start-Sleep -Seconds 900
        }
        
        Write-Host "Publishing $skill..."
        $commitOk = Invoke-GitCommit -SkillPath (Join-Path $SKILLS_DIR $skill) -CommitMessage $Message
        if ($commitOk) {
            if (-not $NoPublish) {
                $pubResult = Invoke-ClawHubPublish -SkillName $skill
                $statusChar = if ($pubResult.Success) { "✓" } else { "✗" }
                Write-Host "  $statusChar $($pubResult.Output)"
            }
        }
    }
}

function Main {
    if ($Skill) {
        $skillPath = Join-Path $SKILLS_DIR $Skill
        if ($NoPublish) {
            Invoke-GitCommit -SkillPath $skillPath -CommitMessage $Message | Out-Null
        } else {
            Invoke-GitCommit -SkillPath $skillPath -CommitMessage $Message | Out-Null
            if (-not $?) {
                Write-Error "Git commit failed"
                return
            }
            $pubResult = Invoke-ClawHubPublish -SkillName $Skill
            Write-Host "$($pubResult.Output)"
        }
    } elseif ($All) {
        Invoke-BatchPublish
    } else {
        Write-Host "Use --skill <name> or --all"
    }
}

Main
