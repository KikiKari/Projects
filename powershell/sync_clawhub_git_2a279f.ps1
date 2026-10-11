#!/usr/bin/env pwsh
# sync_clawhub_git.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway2:scripts/sync_clawhub_git.py
# auch in: Projects@clawhub:clawhub/Skills/sync_clawhub_git.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

<#
Bidirektionale ClawHub ↔ Git Synchronisation
#>

# Konfiguration
# Resolve paths relative to this repository so the helper works both in the
# hosted workspace and in environments without a /workspace mount.
$WORKSPACE_ROOT = (Resolve-Path "$PSScriptRoot/..").Path
$CLAWHUB_DIR = Join-Path $WORKSPACE_ROOT "skills"
$GIT_DIR = Join-Path $WORKSPACE_ROOT "git/skills"
$BACKUP_DIR = Join-Path $WORKSPACE_ROOT "backups/sync"
$LOG_FILE = Join-Path $WORKSPACE_ROOT "logs/sync-agent.log"
$IGNORED_NAMES = @(".git", ".clawhub", "node_modules", "__pycache__", ".pytest_cache")
$RESERVED_SKILL_NAMES = @("github-clones", "skills", "backups", ".restore", "git", "Abstraktionen")
$PRESERVED_TARGET_NAMES = $IGNORED_NAMES

# Erstelle Verzeichnisse
New-Item -ItemType Directory -Path $GIT_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $LOG_FILE -Parent) -Force | Out-Null

# Logging
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[${timestamp}] [$Level] $Message"
    Write-Host $entry
    Add-Content -Path $LOG_FILE -Value $entry
}

# Validierung
function Test-Skill {
    param([string]$SkillDir)
    
    $skillName = Split-Path $SkillDir -Leaf
    if ($RESERVED_SKILL_NAMES -contains $skillName) {
        Write-Log "Validation failed: ${skillName} is reserved and must not be synced as a skill" "ERROR"
        return $false
    }
    if (-not (Test-Path (Join-Path $SkillDir "SKILL.md"))) {
        Write-Log "Validation failed: ${skillName} missing SKILL.md" "ERROR"
        return $false
    }
    return $true
}

function Test-IgnoredPath {
    param([string]$Path)
    $parts = $Path -split '[\\/]'
    foreach ($part in $parts) {
        if ($IGNORED_NAMES -contains $part -or $part -like "__pycache__*") {
            return $true
        }
    }
    return $Path.EndsWith(".pyc")
}

function Test-GeneratedDuplicatePath {
    param([string]$Root, [string]$RelPath)
    $parts = $RelPath -split '[\\/]'
    if ($parts.Count -eq 0) {
        return $false
    }
    if ($parts[0] -eq (Split-Path $Root -Leaf)) {
        return $true
    }
    for ($i = 1; $i -lt $parts.Count; $i++) {
        if ($parts[$i] -eq $parts[$i-1]) {
            return $true
        }
    }
    return $false
}

function Get-SyncFiles {
    param([string]$Root)
    $files = @()
    $stack = @($Root)
    
    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        $items = Get-ChildItem -Path $current -Force -ErrorAction SilentlyContinue
        
        foreach ($item in $items) {
            if ($IGNORED_NAMES -contains $item.Name -or $item.Name -like "__pycache__*") {
                continue
            }
            
            $relPath = Resolve-Path $item.FullName -Relative -ErrorAction SilentlyContinue
            if ($relPath.StartsWith(".\")) {
                $relPath = $relPath.Substring(2)
            }
            
            if (Test-IgnoredPath $relPath) {
                continue
            }
            
            if (Test-GeneratedDuplicatePath $Root $relPath) {
                continue
            }
            
            if ($item.PSIsContainer) {
                $stack.Push($item.FullName)
            } else {
                if ($item.Name -eq "SKILL.md" -and $relPath -ne "SKILL.md") {
                    continue
                }
                if ($item.Extension -eq ".pyc") {
                    continue
                }
                $files += [PSCustomObject]@{
                    FullName = $item.FullName
                    RelativePath = $relPath
                }
            }
        }
    }
    return $files
}

function Reset-SyncTarget {
    param([string]$Target)
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
    
    $children = Get-ChildItem -Path $Target -Force -ErrorAction SilentlyContinue
    foreach ($child in $children) {
        if ($PRESERVED_TARGET_NAMES -contains $child.Name) {
            continue
        }
        if ($child.PSIsContainer -and -not $child.LinkType) {
            Remove-Item -Path $child.FullName -Recurse -Force
        } else {
            Remove-Item -Path $child.FullName -Force
        }
    }
}

function Copy-SyncFiles {
    param([string]$Source, [string]$Target)
    Reset-SyncTarget $Target
    
    $syncFiles = Get-SyncFiles $Source
    foreach ($file in $syncFiles) {
        $destFile = Join-Path $Target $file.RelativePath
        $destDir = Split-Path $destFile -Parent
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        Copy-Item -Path $file.FullName -Destination $destFile -Force
    }
}

# Backup
function Create-Backup {
    param([string]$Source, [string]$SkillName)
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $BACKUP_DIR "${SkillName}_${timestamp}"
    
    # Backup verzeichnis löschen falls es existiert
    if (Test-Path $backupPath) {
        try {
            Remove-Item -Path $backupPath -Recurse -Force
            Write-Log "Removed existing backup: $backupPath"
        } catch {
            Write-Log "Failed to remove existing backup ${backupPath}: $_" "ERROR"
            return $false
        }
    }
    
    try {
        Copy-Item -Path $Source -Destination $backupPath -Recurse -Force
        Write-Log "Backup created: $backupPath"
        return $true
    } catch {
        Write-Log "Backup failed: $_" "ERROR"
        return $false
    }
}

# Hash-Vergleich
function Get-FileHash {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath -PathType Leaf)) {
        return ""
    }
    try {
        return (Get-FileHash $FilePath -Algorithm SHA256).Hash.ToLower()
    } catch {
        Write-Log "Failed to hash ${FilePath}: $_" "ERROR"
        return ""
    }
}

# Sync Richtung ClawHub → Git
function Sync-ToGit {
    param([string]$SkillName, [bool]$DryRun = $true)
    $source = Join-Path $CLAWHUB_DIR $SkillName
    $target = Join-Path $GIT_DIR $SkillName
    
    if (-not (Test-Skill $source)) {
        return $false
    }
    
    # Backup vor Änderungen (nur wenn target existiert)
    if (-not $DryRun -and (Test-Path $target)) {
        Create-Backup $target $SkillName
    }
    
    # Änderungen erkennen
    $changes = @()
    $syncFiles = Get-SyncFiles $source
    foreach ($file in $syncFiles) {
        $tgtFile = Join-Path $target $file.RelativePath
        if (-not (Test-Path $tgtFile)) {
            $changes += "ADD $($file.RelativePath)"
        } else {
            $srcHash = Get-FileHash $file.FullName
            $tgtHash = Get-FileHash $tgtFile
            if ($srcHash -ne $tgtHash) {
                $changes += "UPDATE $($file.RelativePath)"
            }
        }
    }
    
    # Dry-Run Report
    if ($DryRun) {
        Write-Log "DRY-RUN: ${SkillName} - $($changes.Count) changes"
        foreach ($change in $changes) {
            Write-Log "  $change"
        }
        return $true
    }
    
    # Echte Synchronisation
    Write-Log "SYNC: ${SkillName} - Applying $($changes.Count) changes"
    Copy-SyncFiles $source $target
    Write-Log "SYNC: ${SkillName} - Complete"
    return $true
}

# Sync Richtung Git → ClawHub
function Sync-ToClawHub {
    param([string]$SkillName, [bool]$DryRun = $true)
    $source = Join-Path $GIT_DIR $SkillName
    $target = Join-Path $CLAWHUB_DIR $SkillName
    
    if (-not (Test-Skill $source)) {
        return $false
    }
    
    # Backup vor Änderungen (nur wenn target existiert)
    if (-not $DryRun -and (Test-Path $target)) {
        Create-Backup $target $SkillName
    }
    
    # Änderungen erkennen (gleiche Logik wie oben)
    $changes = @()
    $syncFiles = Get-SyncFiles $source
    foreach ($file in $syncFiles) {
        $tgtFile = Join-Path $target $file.RelativePath
        if (-not (Test-Path $tgtFile)) {
            $changes += "ADD $($file.RelativePath)"
        } else {
            $srcHash = Get-FileHash $file.FullName
            $tgtHash = Get-FileHash $tgtFile
            if ($srcHash -ne $tgtHash) {
                $changes += "UPDATE $($file.RelativePath)"
            }
        }
    }
    
    # Dry-Run Report
    if ($DryRun) {
        Write-Log "DRY-RUN: ${SkillName} - $($changes.Count) changes"
        foreach ($change in $changes) {
            Write-Log "  $change"
        }
        return $true
    }
    
    # Echte Synchronisation
    Write-Log "SYNC: ${SkillName} - Applying $($changes.Count) changes"
    Copy-SyncFiles $source $target
    Write-Log "SYNC: ${SkillName} - Complete"
    return $true
}

# Hauptfunktion
function Main {
    param(
        [Parameter(Mandatory=$true)][string]$Skill,
        [Parameter(Mandatory=$true)][ValidateSet('to-git','to-clawhub')][string]$Direction,
        [switch]$DryRun,
        [switch]$Force
    )
    
    Write-Log "Starting sync: ${Skill} (${Direction})"
    
    $success = $false
    if ($Direction -eq 'to-git') {
        $success = Sync-ToGit $Skill $DryRun.IsPresent
    } else {
        $success = Sync-ToClawHub $Skill $DryRun.IsPresent
    }
    
    if (-not $success) {
        Write-Log "Sync failed" "ERROR"
        exit 1
    }
    
    Write-Log "Sync completed"
}

# Parameter parsing
$skill = $null
$direction = $null
$dryRun = $false
$force = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        "--skill" { 
            $i++
            if ($i -lt $args.Count) { $skill = $args[$i] }
        }
        "--direction" { 
            $i++
            if ($i -lt $args.Count) { $direction = $args[$i] }
        }
        "--dry-run" { $dryRun = $true }
        "--force" { $force = $true }
    }
}

if (-not $skill -or -not $direction) {
    Write-Host "Usage: sync_clawhub_git.ps1 --skill <skill_name> --direction <to-git|to-clawhub> [--dry-run] [--force]"
    exit 1
}

Main -Skill $skill -Direction $direction -DryRun:$dryRun -Force:$force
