#!/usr/bin/env pwsh
# db_maintainer.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Database Maintainer Sub-Agent
.DESCRIPTION
Automated database maintenance with 30min checks, hourly backups (3 days retention),
band tree command execution for important/openclaw-tree.txt
#>

param()

# Konfiguration
$WORKSPACE = $env:OPENCLAW_WORKSPACE ?? (Resolve-Path "$PSScriptRoot/..").Path
$DB_DIR = $WORKSPACE
$BACKUP_DIR = Join-Path $WORKSPACE "db/backups"
$LOG_DIR = Join-Path $WORKSPACE "logs/db-maintainer"
$IMPORTANT_DIR = Join-Path $WORKSPACE "important"

# Verzeichnisse erstellen
@($BACKUP_DIR, $LOG_DIR, $IMPORTANT_DIR) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

class Logger {
    <#
    .SYNOPSIS
    Einfacher Logger mit Datei-Ausgabe
    #>
    
    [string]$LogFilePath
    
    Logger() {
        $today = Get-Date -Format "yyyy-MM-dd"
        $this.LogFilePath = Join-Path $script:LOG_DIR "$today.log"
    }
    
    [void] Log([string]$Level, [string]$Message) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $line = "[$timestamp] [$Level] $Message"
        Write-Host $line
        Add-Content -Path $this.LogFilePath -Value $line
    }
    
    [void] Info([string]$Msg) { $this.Log("INFO", $Msg) }
    [void] Warn([string]$Msg) { $this.Log("WARN", $Msg) }
    [void] Error([string]$Msg) { $this.Log("ERROR", $Msg) }
}

class DatabaseMaintainer {
    [Logger]$Logger
    [string]$StateFile
    [int]$RetentionDays = 3
    
    DatabaseMaintainer() {
        $this.Logger = [Logger]::new()
        $this.StateFile = Join-Path $script:DB_DIR "maintainer_state.json"
    }
    
    [hashtable] LoadState() {
        <#
        .SYNOPSIS
        Lädt letzten Check-Zustand
        #>
        if (Test-Path $this.StateFile) {
            $content = Get-Content -Path $this.StateFile -Raw
            if ($content) {
                return $content | ConvertFrom-Json -AsHashtable
            }
        }
        return @{
            last_check = $null
            last_backup = $null
            last_tree_update = $null
            file_hashes = @{}
        }
    }
    
    [void] SaveState([hashtable]$State) {
        <#
        .SYNOPSIS
        Speichert aktuellen Zustand
        #>
        $State | ConvertTo-Json -Depth 10 | Set-Content -Path $this.StateFile
    }
    
    [string] GetFileHash([string]$FilePath) {
        <#
        .SYNOPSIS
        Berechnet MD5-Hash einer Datei
        #>
        try {
            $stream = [System.IO.File]::OpenRead($FilePath)
            $hash = [System.Security.Cryptography.MD5]::Create().ComputeHash($stream)
            $stream.Close()
            return [BitConverter]::ToString($hash).Replace("-", "").ToLower()
        } catch {
            return $null
        }
    }
    
    [string] PythonTreeFallback([int]$MaxDepth = 8) {
        <#
        .SYNOPSIS
        Reiner Python-Fallback, falls das 'tree'-Binary fehlt (z.B. Sandbox).
        #>
        $root = $script:WORKSPACE
        $lines = @($root)
        
        function WalkDirectory([string]$DirPath, [string]$Prefix, [int]$Depth) {
            if ($Depth -gt $MaxDepth) { return }
            
            try {
                $entries = Get-ChildItem -Path $DirPath -Force | Sort-Object { 
                    if ($_.PSIsContainer) { "0" } else { "1" }
                    $_.Name 
                }
            } catch {
                return
            }
            
            for ($i = 0; $i -lt $entries.Count; $i++) {
                $entry = $entries[$i]
                $connector = if ($i -eq $entries.Count - 1) { "└── " } else { "├── " }
                $lines.Add("$Prefix$connector$($entry.Name)")
                
                if ($entry.PSIsContainer -and -not $entry.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
                    $extension = if ($i -eq $entries.Count - 1) { "    " } else { "│   " }
                    WalkDirectory $entry.FullName "$Prefix$extension" ($Depth + 1)
                }
            }
        }
        
        $linesList = [System.Collections.Generic.List[string]]::new()
        $linesList.AddRange($lines)
        WalkDirectory $root "" 1
        return ($linesList -join "`n") + "`n"
    }
    
    [string] RunTreeCommand() {
        <#
        .SYNOPSIS
        Führt tree -a -L 8 auf workspace aus und gibt Ergebnis zurück
        #>
        try {
            $result = Start-Process -FilePath "tree" -ArgumentList "-a", "-L", "8", $script:WORKSPACE -NoNewWindow -PassThru -Wait -RedirectStandardOutput "$env:TEMP\tree_output.txt" -RedirectStandardError "$env:TEMP\tree_error.txt"
            if ($result.ExitCode -eq 0) {
                $output = Get-Content "$env:TEMP\tree_output.txt" -Raw
                $this.Logger.Info("tree -a -L 8 erfolgreich ausgeführt")
                return $output
            } else {
                $errorText = Get-Content "$env:TEMP\tree_error.txt" -Raw
                $this.Logger.Warn("tree command fehlgeschlagen: $($errorText.Trim()) – nutze Python-Fallback")
                return $this.PythonTreeFallback()
            }
        } catch [System.Management.Automation.CommandNotFoundException] {
            $this.Logger.Warn("tree-Binary nicht installiert – nutze Python-Fallback")
            return $this.PythonTreeFallback()
        } catch {
            $this.Logger.Error("tree command Exception: $($_.Exception.Message)")
            return $null
        }
    }
    
    [bool] UpdateTreeFile([string]$TreeOutput) {
        <#
        .SYNOPSIS
        Schreibt tree-output in important/openclaw-tree.txt
        #>
        if (-not $TreeOutput) {
            return $false
        }
        
        $treeFile = Join-Path $script:IMPORTANT_DIR "openclaw-tree.txt"
        
        # Header mit Timestamp
        $header = @"
# OpenClaw Workspace Tree
# Generiert: $(Get-Date -Format o)
# Befehl: tree -a -L 8 $($script:WORKSPACE)
# Diese Datei wird automatisch von db-maintainer aktualisiert

"@
        
        try {
            $header + $TreeOutput | Set-Content -Path $treeFile -Encoding UTF8
            $this.Logger.Info("openclaw-tree.txt aktualisiert: $treeFile")
            return $true
        } catch {
            $this.Logger.Error("Fehler beim Schreiben von openclaw-tree.txt: $($_.Exception.Message)")
            return $false
        }
    }
    
    [array] ScanDocumentations() {
        <#
        .SYNOPSIS
        Scannt alle .md Dateien auf Änderungen
        #>
        $docs = @()
        
        Get-ChildItem -Path $script:WORKSPACE -Include "*.md" -Recurse -File | Where-Object {
            $_.FullName -notlike "*db/backups*" -and 
            $_.FullName -notlike "*node_modules*"
        } | ForEach-Object {
            $relativePath = $_.FullName.Replace($script:WORKSPACE, "").TrimStart("\")
            $docs += @{
                path = $relativePath
                hash = $this.GetFileHash($_.FullName)
                mtime = $_.LastWriteTimeUtc.ToFileTimeUtc()
            }
        }
        
        return $docs
    }
    
    [hashtable] CheckForChanges() {
        <#
        .SYNOPSIS
        Prüft auf Änderungen seit letztem Lauf
        #>
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
        
        return @{
            Changes = $changes
            CurrentHashes = $currentHashes
        }
    }
    
    [bool] UpdateDatabases() {
        <#
        .SYNOPSIS
        Führt DB-Update-Scripts aus
        #>
        try {
            $scriptPath = Join-Path $script:WORKSPACE "scripts/update_docs_db.py"
            $process = Start-Process -FilePath "python3" -ArgumentList $scriptPath -NoNewWindow -PassThru -Wait -RedirectStandardOutput "$env:TEMP\docs_db_output.txt" -RedirectStandardError "$env:TEMP\docs_db_error.txt"
            
            if ($process.ExitCode -eq 0) {
                $this.Logger.Info("docs.db aktualisiert")
                return $true
            } else {
                $errorText = Get-Content "$env:TEMP\docs_db_error.txt" -Raw
                $this.Logger.Error("DB-Update fehlgeschlagen: $errorText")
                return $false
            }
        } catch {
            $this.Logger.Error("DB-Update Exception: $($_.Exception.Message)")
            return $false
        }
    }
    
    [bool] UpdateTreeDbV2() {
        <#
        .SYNOPSIS
        Führt tree_indexer_v2.py aus
        #>
        try {
            $scriptPath = Join-Path $script:WORKSPACE "scripts/tree_indexer_v2.py"
            $process = Start-Process -FilePath "python3" -ArgumentList $scriptPath -NoNewWindow -PassThru -Wait -RedirectStandardOutput "$env:TEMP\tree_db_v2_output.txt" -RedirectStandardError "$env:TEMP\tree_db_v2_error.txt"
            
            if ($process.ExitCode -eq 0) {
                $this.Logger.Info("tree.db v2 aktualisiert")
                return $true
            } else {
                $errorText = Get-Content "$env:TEMP\tree_db_v2_error.txt" -Raw
                $this.Logger.Error("Tree-DB v2 fehlgeschlagen: $errorText")
                return $false
            }
        } catch {
            $this.Logger.Error("Tree-DB v2 Exception: $($_.Exception.Message)")
            return $false
        }
    }
    
    [string] CreateBackup() {
        <#
        .SYNOPSIS
        Erstellt Backup beider Datenbanken
        #>
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
        
        @("docs.db", "tree.db") | ForEach-Object {
            $source = Join-Path $script:DB_DIR $_
            if (Test-Path $source) {
                $backupName = "${timestamp}_$_"
                $backupPath = Join-Path $script:BACKUP_DIR "$backupName.bak"
                Copy-Item -Path $source -Destination $backupPath
                $this.Logger.Info("Backup erstellt: $backupName")
            }
        }
        
        return $timestamp
    }
    
    [void] CleanupOldBackups() {
        <#
        .SYNOPSIS
        Löscht Backups älter als 3 Tage
        #>
        $cutoff = (Get-Date).AddDays(-$this.RetentionDays)
        $deleted = 0
        
        @("docs.db", "tree.db") | ForEach-Object {
            $dbName = $_
            $backups = Get-ChildItem -Path $script:BACKUP_DIR -Filter "*_$dbName.bak"
            
            foreach ($backup in $backups) {
                # Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
                try {
                    $parts = $backup.Name -split "_"
                    $dateStr = $parts[0]
                    $timeStr = $parts[1].Split(".")[0]
                    $backupTime = [DateTime]::ParseExact("${dateStr}_${timeStr}", "yyyy-MM-dd_HH-mm", $null)
                    
                    if ($backupTime -lt $cutoff) {
                        Remove-Item -Path $backup.FullName
                        $deleted++
                        $this.Logger.Info("Altes Backup gelöscht: $($backup.Name)")
                    }
                } catch {
                    $this.Logger.Warn("Konnte Backup-Datum nicht parsen: $($backup.Name)")
                }
            }
        }
        
        if ($deleted -eq 0) {
            $this.Logger.Info("Keine alten Backups zum Löschen")
        } else {
            $this.Logger.Info("$deleted alte Backups gelöscht (< 3 Tage)")
        }
    }
    
    [void] RunCycle() {
        <#
        .SYNOPSIS
        Ein kompletter Wartungszyklus
        #>
        $this.Logger.Info(("=" * 60))
        $this.Logger.Info("DB MAINTAINER CYCLE START")
        $this.Logger.Info(("=" * 60))
        
        $state = $this.LoadState()
        
        # 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
        $this.Logger.Info("Führe tree -a -L 8 aus...")
        $treeOutput = $this.RunTreeCommand()
        if ($treeOutput) {
            $this.UpdateTreeFile($treeOutput)
            $state.last_tree_update = (Get-Date).ToString("o")
        }
        
        # 2. tree.db aktualisieren (intern v2)
        $this.Logger.Info("Aktualisiere tree.db v2...")
        $this.UpdateTreeDbV2()
        
        # 3. Änderungen prüfen
        $this.Logger.Info("Prüfe auf Dokumentations-Änderungen...")
        $changesResult = $this.CheckForChanges()
        $changes = $changesResult.Changes
        $currentHashes = $changesResult.CurrentHashes
        
        if ($changes.Count -gt 0) {
            $this.Logger.Info("$($changes.Count) Änderungen gefunden:")
            $changes | Select-Object -First 10 | ForEach-Object {
                $this.Logger.Info("  - $_")
            }
            if ($changes.Count -gt 10) {
                $this.Logger.Info("  ... und $($changes.Count - 10) weitere")
            }
            
            # 4. docs.db aktualisieren
            $this.Logger.Info("Aktualisiere docs.db...")
            if ($this.UpdateDatabases()) {
                $state.last_check = (Get-Date).ToString("o")
                $state.file_hashes = $currentHashes
            }
        } else {
            $this.Logger.Info("Keine Dokumentations-Änderungen gefunden")
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
            $this.Logger.Info("Erstelle stündliches Backup...")
            $timestamp = $this.CreateBackup()
            $state.last_backup = (Get-Date).ToString("o")
            
            # 6. Alte Backups aufräumen (3 Tage Retention)
            $this.Logger.Info("Räume alte Backups auf (3 Tage Retention)...")
            $this.CleanupOldBackups()
        } else {
            $this.Logger.Info("Backup nicht nötig (letztes < 1h)")
        }
        
        $this.SaveState($state)
        
        $this.Logger.Info(("=" * 60))
        $this.Logger.Info("DB MAINTAINER CYCLE END")
        $this.Logger.Info(("=" * 60))
    }
}

function Main() {
    <#
    .SYNOPSIS
    Hauptfunktion
    #>
    $maintainer = [DatabaseMaintainer]::new()
    
    try {
        $maintainer.RunCycle()
    } catch {
        $maintainer.Logger.Error("CRITICAL ERROR: $($_.Exception.Message)")
        exit 1
    }
}

Main
