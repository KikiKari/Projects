#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "0b9393b1c8041d9d6e7d4ac93dbbd68a589f3f0b9c9e73063695a2493fecbfad", "source_sha256": "5d90ebcd250a3cb80a0de664d94397af7ec03343d9d9fa64a28a9a11ad880754", "target_language": "powershell"}
# check_conflicts.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Check Conflicts - Erkennt Sync-Konflikte
#>

# Import sync functions
$env:PYTHONPATH = "/home/openclaw/.openclaw/workspace/scripts"
$syncScriptPath = "/home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.py"

function Get-FileHashCustom {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
    return $hash.Hash
}

$CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills"
$GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills"

function Check-Conflicts {
    <#
    .SYNOPSIS
    Prüft auf Konflikte zwischen ClawHub und Git
    #>
    
    $conflicts = @()
    
    # Alle Skills die in beiden Orten existieren
    $commonSkills = @()
    if (Test-Path $CLAWHUB_DIR -PathType Container -and Test-Path $GIT_DIR -PathType Container) {
        $clawhubSkills = Get-ChildItem -Path $CLAWHUB_DIR -Directory | ForEach-Object { $_.Name }
        $gitSkills = Get-ChildItem -Path $GIT_DIR -Directory | ForEach-Object { $_.Name }
        $commonSkills = Compare-Object -ReferenceObject $clawhubSkills -DifferenceObject $gitSkills -IncludeEqual -ExcludeDifferent | 
                        Where-Object { $_.SideIndicator -eq "==" } | ForEach-Object { $_.InputObject }
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
            $relPath = $_.FullName.Replace($clawhubPath, "").TrimStart("\")
            $clawhubFiles[$relPath] = $_.FullName
        }
        
        # Git Dateien
        $gitFiles = @{}
        Get-ChildItem -Path $gitPath -Recurse -File | Where-Object { $_.FullName -notlike "*.git*" } | ForEach-Object {
            $relPath = $_.FullName.Replace($gitPath, "").TrimStart("\")
            $gitFiles[$relPath] = $_.FullName
        }
        
        # Vergleiche gemeinsame Dateien
        $commonFiles = $clawhubFiles.Keys | Where-Object { $gitFiles.ContainsKey($_) }
        foreach ($relPath in $commonFiles) {
            $clawhubFile = $clawhubFiles[$relPath]
            $gitFile = $gitFiles[$relPath]
            
            if ((Get-FileHashCustom -FilePath $clawhubFile) -ne (Get-FileHashCustom -FilePath $gitFile)) {
                $clawhubInfo = Get-Item $clawhubFile
                $gitInfo = Get-Item $gitFile
                
                $clawhubMtime = $clawhubInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
                $gitMtime = $gitInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
                
                $newer = if ($clawhubInfo.LastWriteTime -gt $gitInfo.LastWriteTime) { "clawhub" } else { "git" }
                
                $skillConflicts += @{
                    "file" = $relPath
                    "clawhub_modified" = $clawhubMtime
                    "git_modified" = $gitMtime
                    "newer" = $newer
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
            Write-Host "`n📦 Skill: $($conflict.skill)"
            Write-Host ("-" * 40)
            
            foreach ($fileConflict in $conflict.conflicts) {
                Write-Host "  📄 $($fileConflict.file)"
                Write-Host "     ClawHub: $($fileConflict.clawhub_modified)"
                Write-Host "     Git:     $($fileConflict.git_modified)"
                Write-Host "     Neuer:   $($fileConflict.newer.ToUpper())"
                Write-Host ""
            }
        }
        
        Write-Host ("=" * 80)
        Write-Host "Gesamt: $($conflicts.Count) Skills mit Konflikten"
        Write-Host "`nNutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen."
    }
    else {
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

Main
