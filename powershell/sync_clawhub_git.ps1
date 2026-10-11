#!/usr/bin/env pwsh
# sync_clawhub_git.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:scripts/sync_clawhub_git.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

<#
Bidirektionale ClawHub ↔ Git Synchronisation
#>

# Konfiguration
$CLAWHUB_DIR = [System.IO.Path]::Combine($env:HOME, ".openclaw", "workspace", "skills")
$GIT_DIR = [System.IO.Path]::Combine($env:HOME, ".openclaw", "workspace", "git", "skills")
$BACKUP_DIR = [System.IO.Path]::Combine($env:HOME, ".openclaw", "workspace", "backups", "sync")
$LOG_FILE = [System.IO.Path]::Combine($env:HOME, ".openclaw", "workspace", "logs", "sync-agent.log")

# Erstelle Verzeichnisse
New-Item -ItemType Directory -Path $GIT_DIR -Force | Out-Null
New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
New-Item -ItemType Directory -Path ([System.IO.Path]::GetDirectoryName($LOG_FILE)) -Force | Out-Null

# Logging
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    Write-Host $entry
    Add-Content -Path $LOG_FILE -Value $entry
}

# Validierung
function Test-Skill {
    param([System.IO.DirectoryInfo]$SkillDir)
    <#
    Prüft Skill-Struktur - SKILL.md required, scripts/ optional
    #>
    $skillMdPath = Join-Path $SkillDir.FullName "SKILL.md"
    if (-not (Test-Path $skillMdPath)) {
        Write-Log -Message "Validation failed: $($SkillDir.Name) missing SKILL.md" -Level "ERROR"
        return $false
    }
    return $true
}

# Backup
function New-Backup {
    param(
        [System.IO.DirectoryInfo]$Source,
        [string]$SkillName
    )
    <#
    Erstellt Backup eines Skills
    #>
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $BACKUP_DIR "${SkillName}_${timestamp}"
    
    # Backup verzeichnis löschen falls es existiert
    if (Test-Path $backupPath) {
        try {
            Remove-Item -Path $backupPath -Recurse -Force
            Write-Log -Message "Removed existing backup: $backupPath"
        } catch {
            Write-Log -Message "Failed to remove existing backup ${backupPath}: $_" -Level "ERROR"
            return $false
        }
    }
    
    try {
        Copy-Item -Path $Source.FullName -Destination $backupPath -Recurse -Force
        Write-Log -Message "Backup created: $backupPath"
        return $true
    } catch {
        Write-Log -Message "Backup failed: $_" -Level "ERROR"
        return $false
    }
}

# Hash-Vergleich
function Get-FileHashSha256 {
    param([string]$FilePath)
    <#
    SHA256-Hash einer Datei
    #>
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    try {
        $stream = [System.IO.File]::OpenRead($FilePath)
        $hashBytes = $hasher.ComputeHash($stream)
        $stream.Close()
        return [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
    } finally {
        $hasher.Dispose()
    }
}

# Sync Richtung ClawHub → Git
function Sync-ToGit {
    param(
        [string]$SkillName,
        [bool]$DryRun = $true
    )
    <#
    Synchronisiert ClawHub Skill zu Git
    #>
    $source = Join-Path $CLAWHUB_DIR $SkillName
    $target = Join-Path $GIT_DIR $SkillName
    
    if (-not (Test-Skill -SkillDir (Get-Item $source))) {
        return $false
    }
    
    # Backup vor Änderungen (nur wenn target existiert)
    if (-not $DryRun -and (Test-Path $target)) {
        New-Backup -Source (Get-Item $target) -SkillName $SkillName | Out-Null
    }
    
    # Änderungen erkennen
    $changes = @()
    $sourceDirInfo = Get-Item $source
    $files = Get-ChildItem -Path $source -Recurse -File
    
    foreach ($file in $files) {
        $relPath = $file.FullName.Substring($source.Length + 1)
        $tgtFile = Join-Path $target $relPath
        
        # Vergleich
        if (-not (Test-Path $tgtFile)) {
            $changes += "ADD $relPath"
        } else {
            $srcHash = Get-FileHashSha256 -FilePath $file.FullName
            $tgtHash = Get-FileHashSha256 -FilePath $tgtFile
            if ($srcHash -ne $tgtHash) {
                $changes += "UPDATE $relPath"
            }
        }
    }
    
    # Dry-Run Report
    if ($DryRun) {
        Write-Log -Message "DRY-RUN: $SkillName - $($changes.Count) changes"
        foreach ($change in $changes) {
            Write-Log -Message "  $change"
        }
        return $true
    }
    
    # Echte Synchronisation
    Write-Log -Message "SYNC: $SkillName - Applying $($changes.Count) changes"
    if (Test-Path $target) {
        # Lösche Zielverzeichnis und kopiere neu
        Remove-Item -Path $target -Recurse -Force
    }
    Copy-Item -Path $source -Destination $target -Recurse -Force
    Write-Log -Message "SYNC: $SkillName - Complete"
    return $true
}

# Sync Richtung Git → ClawHub
function Sync-ToClawHub {
    param(
        [string]$SkillName,
        [bool]$DryRun = $true
    )
    <#
    Synchronisiert Git Skill zu ClawHub
    #>
    $source = Join-Path $GIT_DIR $SkillName
    $target = Join-Path $CLAWHUB_DIR $SkillName
    
    if (-not (Test-Skill -SkillDir (Get-Item $source))) {
        return $false
    }
    
    # Backup vor Änderungen (nur wenn target existiert)
    if (-not $DryRun -and (Test-Path $target)) {
        New-Backup -Source (Get-Item $target) -SkillName $SkillName | Out-Null
    }
    
    # Änderungen erkennen (gleiche Logik wie oben)
    $changes = @()
    $sourceDirInfo = Get-Item $source
    $files = Get-ChildItem -Path $source -Recurse -File
    
    foreach ($file in $files) {
        $relPath = $file.FullName.Substring($source.Length + 1)
        $tgtFile = Join-Path $target $relPath
        
        # Vergleich
        if (-not (Test-Path $tgtFile)) {
            $changes += "ADD $relPath"
        } else {
            $srcHash = Get-FileHashSha256 -FilePath $file.FullName
            $tgtHash = Get-FileHashSha256 -FilePath $tgtFile
            if ($srcHash -ne $tgtHash) {
                $changes += "UPDATE $relPath"
            }
        }
    }
    
    # Dry-Run Report
    if ($DryRun) {
        Write-Log -Message "DRY-RUN: $SkillName - $($changes.Count) changes"
        foreach ($change in $changes) {
            Write-Log -Message "  $change"
        }
        return $true
    }
    
    # Echte Synchronisation
    Write-Log -Message "SYNC: $SkillName - Applying $($changes.Count) changes"
    if (Test-Path $target) {
        # Lösche Zielverzeichnis und kopiere neu
        Remove-Item -Path $target -Recurse -Force
    }
    Copy-Item -Path $source -Destination $target -Recurse -Force
    Write-Log -Message "SYNC: $SkillName - Complete"
    return $true
}

# Hauptfunktion
function Main {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Skill,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('to-git', 'to-clawhub')]
        [string]$Direction,
        
        [switch]$DryRun,
        
        [switch]$Force
    )
    
    Write-Log -Message "Starting sync: $Skill ($Direction)"
    
    $success = $false
    if ($Direction -eq 'to-git') {
        $success = Sync-ToGit -SkillName $Skill -DryRun $DryRun.IsPresent
    } else {
        $success = Sync-ToClawHub -SkillName $Skill -DryRun $DryRun.IsPresent
    }
    
    if (-not $success) {
        Write-Log -Message "Sync failed" -Level "ERROR"
        exit 1
    }
    
    Write-Log -Message "Sync completed"
}

# Parameter Parsing
$paramDefs = @{
    'skill' = @{ Type = 'string'; Mandatory = $true }
    'direction' = @{ Type = 'string'; Values = @('to-git', 'to-clawhub'); Mandatory = $true }
    'dry-run' = @{ Type = 'switch' }
    'force' = @{ Type = 'switch' }
}

$params = @{}
for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = $args[$i]
    if ($arg.StartsWith('--')) {
        $key = $arg.Substring(2)
        if ($paramDefs.ContainsKey($key)) {
            $def = $paramDefs[$key]
            if ($def.Type -eq 'switch') {
                $params[$key] = $true
            } else {
                $i++
                if ($i -lt $args.Count) {
                    $value = $args[$i]
                    if ($def.Values -and $def.Values -notcontains $value) {
                        Write-Error "Invalid value '$value' for parameter '--$key'. Valid values: $($def.Values -join ', ')"
                        exit 1
                    }
                    $params[$key] = $value
                } else {
                    Write-Error "Missing value for parameter '--$key'"
                    exit 1
                }
            }
        } else {
            Write-Error "Unknown parameter '$arg'"
            exit 1
        }
    }
}

# Check mandatory parameters
foreach ($param in $paramDefs.GetEnumerator()) {
    if ($param.Value.Mandatory -and -not $params.ContainsKey($param.Key)) {
        Write-Error "Missing required parameter '--$($param.Key)'"
        exit 1
    }
}

# Call main function with parsed parameters
Main -Skill $params['skill'] -Direction $params['direction'] -DryRun:$params['dry-run'] -Force:$params['force']
