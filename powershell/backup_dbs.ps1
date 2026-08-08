#!/usr/bin/env pwsh
# backup_dbs.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway2:tmp/backup_dbs.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Backup docs.db and tree.db with timestamp into /workspace/db/backups
#>
$workspace = $env:OPENCLAW_WORKSPACE
if (-not $workspace) {
    $workspace = "/workspace"
}
$backupDir = Join-Path $workspace "db/backups"
# Ensure backupDir exists
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
foreach ($dbName in @("docs.db", "tree.db")) {
    $src = Join-Path $workspace $dbName
    if (Test-Path -Path $src -PathType Leaf) {
        $dest = Join-Path $backupDir "${timestamp}_${dbName}.bak"
        Copy-Item -Path $src -Destination $dest
        Write-Output "Backup created: $dest"
    } else {
        Write-Output "Source db not found: $src"
    }
}
