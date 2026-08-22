#!/usr/bin/env pwsh
# test_sync_real.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:scripts/test_sync_real.py
# auch in: OpenClaw@gateway2:scripts/test_sync_real.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Test echte Synchronisation
#>

# Füge das Verzeichnis zum Suchpfad hinzu
$env:PYTHONPATH = "/home/openclaw/.openclaw/workspace/scripts"
Import-Module -Name "/home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.py" -Force

# Test: db-maintainer ClawHub → Git (ECHT)
Write-Host "=== TEST: db-maintainer sync (REAL) ==="
$skill = "db-maintainer"
$result = sync_to_git -skill $skill -dry_run $false
Write-Host "Result: $(if ($result) {'SUCCESS'} else {'FAILED'})"

# Prüfe Ergebnis
$target = "/home/openclaw/.openclaw/workspace/git/skills/db-maintainer"
if (Test-Path $target) {
    Write-Host "`n✅ Git-Repo erstellt: $target"
    
    # Rekursiv durch das Verzeichnis navigieren und Struktur anzeigen
    function Get-DirectoryTree {
        param(
            [string]$Path,
            [int]$Depth = 0
        )
        
        $indent = " " * 2 * $Depth
        $subindent = " " * 2 * ($Depth + 1)
        
        Write-Host "${indent}$(Split-Path $Path -Leaf)/"
        
        $items = Get-ChildItem -Path $Path -Force
        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                Get-DirectoryTree -Path $item.FullName -Depth ($Depth + 1)
            } else {
                Write-Host "${subindent}$($item.Name)"
            }
        }
    }
    
    Get-DirectoryTree -Path $target
}
