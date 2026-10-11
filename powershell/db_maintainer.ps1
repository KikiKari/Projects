#!/usr/bin/env pwsh
# db_maintainer.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/db_maintainer.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Database Maintainer Sub-Agent
.DESCRIPTION
Automated database maintenance with 30min checks, hourly backups (3 days retention),
band tree command execution for important/openclaw-tree.txt
#>

$WORKSPACE = "/home/openclaw/.openclaw/workspace"
$DB_DIR = Join-Path $WORKSPACE "db"
$BACKUP_DIR = Join-Path $DB_DIR "backups"
$LOG_DIR = Join-Path $WORKSPACE "logs" "db-maintainer"
$IMPORTANT_DIR = Join-Path $WORKSPACE "important"

# Verzeichnisse erstellen
if (!(Test-Path $BACKUP_DIR)) { New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null }
if (!(Test-Path $LOG_DIR)) { New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null }

class Logger {
    [string]$logFile
    
    Logger() {
        $today = Get-Date -Format "yyyy-MM-dd"
        $this.logFile = Join-Path $script:LOG_DIR "$today.log"
    }
    
    [void]Log([string]$level, [string]$message) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $line = "[$timestamp] [$level] $message"
        Write-Host $line
        Add-Content -Path $this.logFile -Value $line
    }
    
    [void]Info([string]$msg) { $this.Log("INFO", $msg) }
    [void]Warn([string]$msg) { $this.Log("WARN", $msg) }
    [void]Error([string]$msg) { $this.Log("ERROR", $msg) }
}

class DatabaseMaintainer {
    [Logger]$logger
    [string]$stateFile
    [int]$retentionDays = 3
    
    DatabaseMaintainer() {
        $this.logger = [Logger]::new()
        $this.stateFile = Join-Path $script:DB_DIR "maintainer_state.json"
    }
    
    [hashtable]LoadState() {
        if (Test-Path $this.stateFile) {
            $content = Get-Content -Path $this.stateFile -Raw
            return $content | ConvertFrom-Json -AsHashtable
        }
        return @{
            last_check = $null
            last_backup = $null
            last_tree_update = $null
            file_hashes = @{}
        }
    }
    
    [void]SaveState([hashtable]$state) {
        $state | ConvertTo-Json -Depth 10 | Set-Content -Path $this.stateFile
    }
    
    [string]GetFileHash([string]$filepath) {
        try {
            $hash = Get-FileHash -Path $filepath -Algorithm MD5
            return $hash.Hash.ToLower()
        } catch {
            return $null
        }
    }
    
    [string]RunTreeCommand() {
        try {
            $result = & tree -a -L 8 $script:WORKSPACE 2>&1
            if ($LASTEXITCODE -eq 0) {
                $this.logger.Info("tree -a -L 8 erfolgreich ausgeführt")
                return ($result | Out-String).Trim()
            } else {
                $this.logger.Error("tree command fehlgeschlagen: $result")
                return $null
            }
        } catch {
            $this.logger.Error("tree command Exception: $_")
            return $null
        }
    }
    
    [bool]UpdateTreeFile([string]$treeOutput) {
        if (-not $treeOutput) {
            return $false
        }
        
        $treeFile = Join-Path $script:IMPORTANT_DIR "openclaw-tree.txt"
        
        # Header mit Timestamp
        $header = "# OpenClaw Workspace Tree`n# Generiert: $(Get-Date -Format o)`n# Befehl: tree -a -L 8 $script:WORKSPACE`n# Diese Datei wird automatisch von db-maintainer aktualisiert`n`n"
        
        try {
            $header + $treeOutput | Set-Content -Path $treeFile -Encoding UTF8
            $this.logger.Info("openclaw-tree.txt aktualisiert: $treeFile")
            return $true
        } catch {
            $this.logger.Error("Fehler beim Schreiben von openclaw-tree.txt: $_")
            return $false
        }
    }
    
    [array]ScanDocumentations() {
        $docs = @()
        
        $patterns = @("*.md", "**/*.md")
        foreach ($pattern in $patterns) {
            $files = Get-ChildItem -Path $script:WORKSPACE -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue
            
            foreach ($file in $files) {
                $relativePath = $file.FullName.Replace($script:WORKSPACE, "").TrimStart("\").TrimStart("/")
                
                if ($relativePath -notlike "db/backups*" -and $relativePath -notlike "*node_modules*") {
                    $docs += @{
                        path = $relativePath
                        hash = $this.GetFileHash($file.FullName)
                        mtime = $file.LastWriteTime.ToUniversalTime().ToFileTimeUtc()
                    }
                }
            }
        }
        
        return $docs
    }
    
    [hashtable]CheckForChanges() {
        $state = $this.LoadState()
        $currentDocs = $this.ScanDocumentations()
        
        $changes = @()
        $currentHashes = @{}
        
        foreach ($doc in $currentDocs) {
            $path = $doc.path
            $currentHashes[$path] = $doc.hash
            
            if (-not $state.file_hashes.ContainsKey($path)) {
                $changes += "NEW: $path"
            } elseif ($state.file_hashes[$path] -ne $doc.hash) {
                $changes += "CHANGED: $path"
            }
        }
        
        # Prüfe auf gelöschte Dateien
        foreach ($oldPath in $state.file_hashes.Keys) {
            if (-not $currentHashes.ContainsKey($oldPath)) {
                $changes += "DELETED: $oldPath"
            }
        }
        
        return @{ changes = $changes; hashes = $currentHashes }
    }
    
    [bool]UpdateDatabases() {
        try {
            # Update docs.db
            $scriptPath = Join-Path $script:WORKSPACE "scripts" "update_docs_db.py"
            $result = & python3 $scriptPath 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $this.logger.Info("docs.db aktualisiert")
                return $true
            } else {
                $this.logger.Error("DB-Update fehlgeschlagen: $result")
                return $false
            }
        } catch {
            $this.logger.Error("DB-Update Exception: $_")
            return $false
        }
    }
    
    [bool]UpdateTreeDbV2() {
        try {
            $scriptPath = Join-Path $script:WORKSPACE "scripts" "tree_indexer_v2.py"
            $result = & python3 $scriptPath 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $this.logger.Info("tree.db v2 aktualisiert")
                return $true
            } else {
                $this.logger.Error("Tree-DB v2 fehlgeschlagen: $result")
                return $false
            }
        } catch {
            $this.logger.Error("Tree-DB v2 Exception: $_")
            return $false
        }
    }
    
    [string]CreateBackup() {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
        
        foreach ($dbName in @("docs.db", "tree.db")) {
            $source = Join-Path $script:DB_DIR $dbName
            if (Test-Path $source) {
                $backupName = "${timestamp}_${dbName}.bak"
                $backupPath = Join-Path $script:BACKUP_DIR $backupName
                Copy-Item -Path $source -Destination $backupPath -Force
                $this.logger.Info("Backup erstellt: $backupName")
            }
        }
        
        return $timestamp
    }
    
    [void]CleanupOldBackups() {
        $cutoff = (Get-Date).AddDays(-$this.retentionDays)
        $deleted = 0
        
        foreach ($dbName in @("docs.db", "tree.db")) {
            $backups = Get-ChildItem -Path $script:BACKUP_DIR -Filter "*_${dbName}.bak" -File
            
            foreach ($backup in $backups) {
                try {
                    # Extrahiere Datum aus filename (Format: YYYY-MM-DD_HH-MM)
                    $parts = $backup.Name.Split("_")
                    $dateStr = $parts[0]
                    $timeStr = $parts[1]
                    $backupTime = [DateTime]::ParseExact("${dateStr}_${timeStr}", "yyyy-MM-dd_HH-mm", $null)
                    
                    if ($backupTime -lt $cutoff) {
                        Remove-Item -Path $backup.FullName -Force
                        $deleted++
                        $this.logger.Info("Altes Backup gelöscht: $($backup.Name)")
                    }
                } catch {
                    $this.logger.Warn("Konnte Backup-Datum nicht parsen: $($backup.Name)")
                }
            }
        }
        
        if ($deleted -eq 0) {
            $this.logger.Info("Keine alten Backups zum Löschen")
        } else {
            $this.logger.Info("$deleted alte Backups gelöscht (< 3 Tage)")
        }
    }
    
    [void]RunCycle() {
        $this.logger.Info("=" * 60)
        $this.logger.Info("DB MAINTAINER CYCLE START")
        $this.logger.Info("=" * 60)
        
        $state = $this.LoadState()
        
        # 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
        $this.logger.Info("Führe tree -a -L 8 aus...")
        $treeOutput = $this.RunTreeCommand()
        if ($treeOutput) {
            $this.UpdateTreeFile($treeOutput) | Out-Null
            $state.last_tree_update = (Get-Date).ToString("o")
        }
        
        # 2. tree.db aktualisieren (intern v2)
        $this.logger.Info("Aktualisiere tree.db v2...")
        $this.UpdateTreeDbV2() | Out-Null
        
        # 3. Änderungen prüfen
        $this.logger.Info("Prüfe auf Dokumentations-Änderungen...")
        $checkResult = $this.CheckForChanges()
        $changes = $checkResult.changes
        $currentHashes = $checkResult.hashes
        
        if ($changes.Count -gt 0) {
            $this.logger.Info("$($changes.Count) Änderungen gefunden:")
            for ($i = 0; $i -lt [Math]::Min(10, $changes.Count); $i++) {
                $this.logger.Info("  - $($changes[$i])")
            }
            if ($changes.Count -gt 10) {
                $this.logger.Info("  ... und $($changes.Count - 10) weitere")
            }
            
            # 4. docs.db aktualisieren
            $this.logger.Info("Aktualisiere docs.db...")
            if ($this.UpdateDatabases()) {
                $state.last_check = (Get-Date).ToString("o")
                $state.file_hashes = $currentHashes
            }
        } else {
            $this.logger.Info("Keine Dokumentations-Änderungen gefunden")
        }
        
        # 5. Prüfe ob Backup fällig (stündlich)
        $lastBackup = $state.last_backup
        
        if ($lastBackup) {
            $lastBackupTime = [DateTime]::Parse($lastBackup)
            $doBackup = (Get-Date) - $lastBackupTime -ge [TimeSpan]::FromHours(1)
        } else {
            $doBackup = $true
        }
        
        if ($doBackup) {
            $this.logger.Info("Erstelle stündliches Backup...")
            $timestamp = $this.CreateBackup()
            $state.last_backup = (Get-Date).ToString("o")
            
            # 6. Alte Backups aufräumen (3 Tage Retention)
            $this.logger.Info("Räume alte Backups auf (3 Tage Retention)...")
            $this.CleanupOldBackups()
        } else {
            $this.logger.Info("Backup nicht nötig (letztes < 1h)")
        }
        
        $this.SaveState($state)
        
        $this.logger.Info("=" * 60)
        $this.logger.Info("DB MAINTAINER CYCLE END")
        $this.logger.Info("=" * 60)
    }
}

function Main() {
    $maintainer = [DatabaseMaintainer]::new()
    
    try {
        $maintainer.RunCycle()
    } catch {
        $maintainer.logger.Error("CRITICAL ERROR: $_")
        exit 1
    }
}

Main
