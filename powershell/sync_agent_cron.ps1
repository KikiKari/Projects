#!/usr/bin/env pwsh
# sync_agent_cron.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:scripts/sync_agent_cron.py
# auch in: OpenClaw@gateway2:scripts/sync_agent_cron.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

<#
ClawHub ↔ Git Sync Agent - Cron Version mit Dry-Run + Auto-Sync
#>

$ErrorActionPreference = "Stop"

# Pfade definieren
$CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills"
$GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills"
$LOG_FILE = "/home/openclaw/.openclaw/workspace/logs/sync-agent.log"
$SCRIPT_DIR = "/home/openclaw/.openclaw/workspace/scripts"

# Lade externe Funktionen
. "$SCRIPT_DIR/sync_clawhub_git.ps1"

function Get-FileModificationTime {
    param([string]$Path)
    
    try {
        $files = Get-ChildItem -Path $Path -Recurse -File -Force | Where-Object { $_.FullName -notlike "*/.git/*" -and $_.Name -ne ".git" }
        if ($files.Count -eq 0) { return 0 }
        $latest = ($files | Measure-Object -Property LastWriteTime -Maximum).Maximum
        return [double](Get-Date $latest -UFormat %s)
    } catch {
        return 0
    }
}

function Write-ToLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[${timestamp}] [$Level] $Message"
    Write-Host $entry
    Add-Content -Path $LOG_FILE -Value $entry
}

# Überschreibe Log-Funktion
$logFunction = ${function:Write-ToLog}
Set-Item function:global:log -Value $logFunction

Write-ToLog ("=" * 70)
Write-ToLog "CLAWHUB ↔ GIT SYNC AGENT - CRON LAUF"
Write-ToLog "Zeitstempel: $((Get-Date).ToString('o'))"
Write-ToLog ("=" * 70)

# Hole Skill-Verzeichnisse
$clawhubSkills = @()
$gitSkills = @()

if (Test-Path $CLAWHUB_DIR) {
    $clawhubSkills = Get-ChildItem -Path $CLAWHUB_DIR -Directory | 
                     Where-Object { !$_.Name.StartsWith(".") } | 
                     ForEach-Object { $_.Name }
}

if (Test-Path $GIT_DIR) {
    $gitSkills = Get-ChildItem -Path $GIT_DIR -Directory | 
                 Where-Object { !$_.Name.StartsWith(".") } | 
                 ForEach-Object { $_.Name }
}

# Konvertiere zu Sets für Mengenoperationen
$clawhubSet = New-Object System.Collections.Generic.HashSet[string]($clawhubSkills)
$gitSet = New-Object System.Collections.Generic.HashSet[string]($gitSkills)

# DRY-RUN: Erkenne Änderungen
Write-ToLog ""
Write-ToLog "[DRY-RUN] Analysiere Änderungen..."

$changesDetected = @{
    new_in_clawhub = @()
    new_in_git = @()
    clawhub_newer = @()
    git_newer = @()
    synced = @()
}

# 1. Neue Skills
$newInClawhub = $clawhubSkills | Where-Object { $gitSkills -notcontains $_ }
$newInGit = $gitSkills | Where-Object { $clawhubSkills -notcontains $_ }

$changesDetected.new_in_clawhub = $newInClawhub | Sort-Object
$changesDetected.new_in_git = $newInGit | Sort-Object

# 2. Existierende prüfen
$inBoth = $clawhubSkills | Where-Object { $gitSkills -contains $_ } | Sort-Object

foreach ($skill in $inBoth) {
    $cMtime = Get-FileModificationTime "$CLAWHUB_DIR/$skill"
    $gMtime = Get-FileModificationTime "$GIT_DIR/$skill"
    $diff = $cMtime - $gMtime
    
    if ([Math]::Abs($diff) -gt 60) {
        if ($diff -gt 0) {
            $changesDetected.clawhub_newer += ,@($skill, $diff)
        } else {
            $changesDetected.git_newer += ,@($skill, [Math]::Abs($diff))
        }
    } else {
        $changesDetected.synced += $skill
    }
}

# Report
$totalChanges = $newInClawhub.Count + $newInGit.Count + $changesDetected.clawhub_newer.Count + $changesDetected.git_newer.Count
Write-ToLog "Neu in ClawHub: $($newInClawhub.Count)"
Write-ToLog "Neu in Git: $($newInGit.Count)"
Write-ToLog "ClawHub neuer: $($changesDetected.clawhub_newer.Count)"
Write-ToLog "Git neuer: $($changesDetected.git_newer.Count)"
Write-ToLog "Synchron: $($changesDetected.synced.Count)"

if ($totalChanges -eq 0) {
    Write-ToLog ""
    Write-ToLog "✅ Keine Änderungen erkannt. Sync nicht nötig."
    Write-ToLog ("=" * 70)
    exit 0
}

Write-ToLog ""
Write-ToLog "🔄 $totalChanges Änderungen erkannt - starte Synchronisation..."

# ECHTE SYNCHRONISATION
$results = @{
    synced_to_git = @()
    synced_to_clawhub = @()
    up_to_date = @()
    errors = @()
}

# 1. NEU in ClawHub → zu Git
foreach ($skill in $newInClawhub) {
    try {
        if (Validate-Skill "$CLAWHUB_DIR/$skill") {
            Write-ToLog "→ Synchronisiere $skill zu Git..."
            if (Sync-ToGit -Skill $skill -DryRun $false) {
                $gitPath = "$GIT_DIR/$skill"
                Push-Location $gitPath
                git init -q 2>$null
                git add . -f 2>$null
                git commit -m "Initial: $skill" -q 2>$null
                Pop-Location
                
                $results.synced_to_git += $skill
                Write-ToLog "  ✓ $skill synchronisiert"
            }
        } else {
            $results.errors += "$skill (invalid)"
        }
    } catch {
        Write-ToLog "  ✗ ERROR: $skill - $_" "ERROR"
        $results.errors += "$skill"
    }
}

# 2. NEU in Git → zu ClawHub
foreach ($skill in $newInGit) {
    try {
        if (Validate-Skill "$GIT_DIR/$skill") {
            Write-ToLog "→ Synchronisiere $skill zu ClawHub..."
            if (Sync-ToClawHub -Skill $skill -DryRun $false) {
                $results.synced_to_clawhub += $skill
                Write-ToLog "  ✓ $skill synchronisiert"
            }
        } else {
            $results.errors += "$skill (invalid)"
        }
    } catch {
        Write-ToLog "  ✗ ERROR: $skill - $_" "ERROR"
        $results.errors += "$skill"
    }
}

# 3. Updates
foreach ($item in $changesDetected.clawhub_newer) {
    $skill = $item[0]
    $diff = $item[1]
    
    try {
        Write-ToLog "→ Update $skill (ClawHub +$([Math]::Round($diff))s neuer)..."
        if (Sync-ToGit -Skill $skill -DryRun $false) {
            $gitPath = "$GIT_DIR/$skill"
            Push-Location $gitPath
            git add . -f 2>$null
            $dt = Get-Date -Format "yyyy-MM-dd HH:mm"
            git commit -m "Sync from ClawHub: $dt" -q 2>$null
            Pop-Location
            
            $results.synced_to_git += $skill
            Write-ToLog "  ✓ $skill aktualisiert"
        }
    } catch {
        Write-ToLog "  ✗ ERROR: $skill - $_" "ERROR"
        $results.errors += "$skill"
    }
}

foreach ($item in $changesDetected.git_newer) {
    $skill = $item[0]
    $diff = $item[1]
    
    try {
        Write-ToLog "→ Update $skill (Git +$([Math]::Round($diff))s neuer)..."
        if (Sync-ToClawHub -Skill $skill -DryRun $false) {
            $results.synced_to_clawhub += $skill
            Write-ToLog "  ✓ $skill aktualisiert"
        }
    } catch {
        Write-ToLog "  ✗ ERROR: $skill - $_" "ERROR"
        $results.errors += "$skill"
    }
}

$results.up_to_date = $changesDetected.synced

# ZUSAMMENFASSUNG
Write-ToLog ""
Write-ToLog ("=" * 70)
Write-ToLog "SYNCHRONISATION ABGESCHLOSSEN"
Write-ToLog ("=" * 70)
Write-ToLog "Zu Git synchronisiert:     $($results.synced_to_git.Count)"
Write-ToLog "Zu ClawHub synchronisiert: $($results.synced_to_clawhub.Count)"
Write-ToLog "Bereits aktuell:           $($results.up_to_date.Count)"
Write-ToLog "Fehler:                    $($results.errors.Count)"
if ($results.errors.Count -gt 0) {
    Write-ToLog "  Fehlerhafte: $($results.errors -join ', ')"
}
Write-ToLog ("=" * 70)

# State speichern
$STATE_FILE = "/home/openclaw/.openclaw/workspace/db/sync_state.json"
$stateDir = Split-Path $STATE_FILE -Parent
if (!(Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}

$state = @{
    last_run = (Get-Date).ToString("o")
    results = $results
    changes_detected = @{ }
}

# Konvertiere changes_detected für JSON-Kompatibilität
foreach ($key in $changesDetected.Keys) {
    if ($changesDetected[$key] -is [array]) {
        $state.changes_detected[$key] = $changesDetected[$key].Count
    } else {
        $state.changes_detected[$key] = $changesDetected[$key]
    }
}

$state | ConvertTo-Json -Depth 10 | Set-Content $STATE_FILE
Write-ToLog "State gespeichert: $STATE_FILE"
