#!/usr/bin/env pwsh
# check_conflicts.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Check Conflicts - Erkennt Sync-Konflikte
#>

# Import sync functions
$syncScriptPath = Join-Path $env:HOME ".openclaw/workspace/scripts/sync_clawhub_git.ps1"
if (Test-Path $syncScriptPath) {
    . $syncScriptPath
} else {
    Write-Error "Sync script not found at $syncScriptPath"
    exit 1
}

$CLAWHUB_DIR = Join-Path $env:HOME ".openclaw/workspace/skills"
$GIT_DIR = Join-Path $env:HOME ".openclaw/workspace/git/skills"

function Get-FileHashCustom {
    param(
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        return $null
    }
    
    $hash = Get-FileHash -Path $Path -Algorithm SHA256
    return $hash.Hash
}

function Check-Conflicts {
    <#
    .SYNOPSIS
    Prüft auf Konflikte zwischen ClawHub und Git
    #>
    
    $conflicts = @()
    
    # Alle Skills die in beiden Orten existieren
    $commonSkills = @()
    if ((Test-Path $CLAWHUB_DIR) -and (Test-Path $GIT_DIR)) {
        $clawhubSkills = Get-ChildItem -Path $CLAWHUB_DIR -Directory | ForEach-Object { $_.Name }
        $gitSkills = Get-ChildItem -Path $GIT_DIR -Directory | ForEach-Object { $_.Name }
        
        $clawhubSkillsSet = New-Object System.Collections.Generic.HashSet[string]
        $clawhubSkills | ForEach-Object { [void]$clawhubSkillsSet.Add($_) }
        
        $commonSkills = $gitSkills | Where-Object { $clawhubSkillsSet.Contains($_) }
    }
    
    Write-Host "Prüfe $($commonSkills.Count) Skills auf Konflikte...`n"
    
    foreach ($skill in ($commonSkills | Sort-Object)) {
        $clawhubPath = Join-Path $CLAWHUB_DIR $skill
        $gitPath = Join-Path $GIT_DIR $skill
        
        # Alle Dateien vergleichen
        $skillConflicts = @()
        
        # ClawHub Dateien
        $clawhubFiles = @{}
        Get-ChildItem -Path $clawhubPath -Recurse -File | Where-Object { $_.FullName -notlike "*.git*" } | ForEach-Object {
            $relPath = Resolve-Path -Relative -Path $_.FullName -RelativeBasePath $clawhubPath
            if ($relPath.StartsWith(".\")) {
                $relPath = $relPath.Substring(2)
            }
            $clawhubFiles[$relPath] = $_.FullName
        }
        
        # Git Dateien
        $gitFiles = @{}
        Get-ChildItem -Path $gitPath -Recurse -File | Where-Object { $_.FullName -notlike "*.git*" } | ForEach-Object {
            $relPath = Resolve-Path -Relative -Path $_.FullName -RelativeBasePath $gitPath
            if ($relPath.StartsWith(".\")) {
                $relPath = $relPath.Substring(2)
            }
            $gitFiles[$relPath] = $_.FullName
        }
        
        # Vergleiche gemeinsame Dateien
        $commonFiles = $clawhubFiles.Keys | Where-Object { $gitFiles.ContainsKey($_) }
        
        foreach ($relPath in $commonFiles) {
            $clawhubFile = $clawhubFiles[$relPath]
            $gitFile = $gitFiles[$relPath]
            
            if ((Get-FileHashCustom -Path $clawhubFile) -ne (Get-FileHashCustom -Path $gitFile)) {
                $clawhubItem = Get-Item $clawhubFile
                $gitItem = Get-Item $gitFile
                
                $clawhubMtime = $clawhubItem.LastWriteTime
                $gitMtime = $gitItem.LastWriteTime
                
                $skillConflicts += @{
                    "file" = $relPath
                    "clawhub_modified" = $clawhubMtime.ToString('yyyy-MM-dd HH:mm:ss')
                    "git_modified" = $gitMtime.ToString('yyyy-MM-dd HH:mm:ss')
                    "newer" = if ($clawhubMtime -gt $gitMtime) { "clawhub" } else { "git" }
                }
            }
        }
        
        if ($skillConflicts.Count -gt 0) {
            $conflicts += @{
                "skill" = $skill
                "conflicts" = $skillConflicts
            }
        }
    }
    
    # Ausgabe
    if ($conflicts.Count -gt 0) {
        Write-Host "⚠️  KONFLIKTE GEFUNDEN:"
        Write-Host ("=" * 80)
        
        foreach ($conflict in $conflicts) {
            Write-Host "`n📦 Skill: $($conflict['skill'])"
            Write-Host ("-" * 40)
            
            foreach ($fileConflict in $conflict['conflicts']) {
                Write-Host "  📄 $($fileConflict['file'])"
                Write-Host "     ClawHub: $($fileConflict['clawhub_modified'])"
                Write-Host "     Git:     $($fileConflict['git_modified'])"
                Write-Host "     Neuer:   $($fileConflict['newer'].ToUpper())"
                Write-Host ""
            }
        }
        
        Write-Host ("=" * 80)
        Write-Host "Gesamt: $($conflicts.Count) Skills mit Konflikten"
        Write-Host "`nNutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen."
    } else {
        Write-Host "✅ Keine Konflikte gefunden!"
        Write-Host "Alle gemeinsamen Skills sind synchron."
    }
}

function Main {
    <#
    .SYNOPSIS
    Hauptfunktion
    #>
    Check-Conflicts
}

# Skript ausführen
Main
