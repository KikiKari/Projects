#!/usr/bin/env pwsh
# sync_git_to_clawhub.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:scripts/sync_git_to_clawhub.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Sync die aktiven Skill-Repositories zu ClawHub.
#>

# Füge das Verzeichnis zum Suchpfad hinzu (PowerShell verwendet Module)
$env:PSModulePath += [System.IO.Path]::PathSeparator + "/home/openclaw/.openclaw/workspace/scripts"

# Importiere das benötigte Modul (entspricht dem Python import)
Import-Module sync_clawhub_git -Force

# Nur aktive Skill-Repositories synchronisieren.
$git_repos = @(
    "sub-agents-utils",
    "multi-nodes-utils"
)

# Check if in git/
$git_path = "/home/openclaw/.openclaw/workspace/git"
foreach ($repo in $git_repos) {
    $repoPath = Join-Path $git_path $repo
    if (Test-Path $repoPath) {
        log "Syncing $repo from Git to ClawHub..."
        sync_to_clawhub $repo -dry_run $false
        log "✅ $repo synced to ClawHub"
    }
}
