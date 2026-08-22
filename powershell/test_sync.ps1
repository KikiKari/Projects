#!/usr/bin/env pwsh
# test_sync.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:scripts/test_sync.py
# auch in: OpenClaw@gateway2:scripts/test_sync.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Test für Sync-Script
#>

# Füge das Verzeichnis zum PowerShell-Modulpfad hinzu
$env:PSModulePath += ";/home/openclaw/.openclaw/workspace/scripts"

# Importiere das benötigte Modul (entsprechend dem Python-Skript)
# In PowerShell könnte dies ein eigenes Skript oder Modul sein
# Wir gehen davon aus, dass sync_clawhub_git.ps1 existiert
. "/home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.ps1"

# Test: db-maintainer ClawHub → Git (DRY-RUN)
Write-Output "=== TEST: db-maintainer sync (DRY-RUN) ==="
$skill = "db-maintainer"
$result = sync_to_git -Skill $skill -DryRun

# Gib das Ergebnis aus
if ($result) {
    Write-Output "Result: SUCCESS"
} else {
    Write-Output "Result: FAILED"
}

Write-Output "`n=== LOG-Inhalt ==="
try {
    $logContent = Get-Content -Path "/home/openclaw/.openclaw/workspace/logs/sync.log" -ErrorAction Stop
    Write-Output $logContent
} catch {
    Write-Output "Fehler beim Lesen der Logdatei: $_"
}
