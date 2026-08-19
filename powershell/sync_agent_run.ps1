#!/usr/bin/env pwsh
# sync_agent_run.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:scripts/sync_agent_run.py
# auch in: OpenClaw@gateway2:scripts/sync_agent_run.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

<#
ClawHub ↔ Git Sync Agent - Produktionslauf
#>

# Füge das Verzeichnis zum Suchpfad hinzu (ähnlich wie sys.path.append)
$env:PYTHONPATH += ":/home/openclaw/.openclaw/workspace/scripts"

# Importieren der benötigten Funktionen aus dem Python-Skript (Annahme: Diese sind in PowerShell verfügbar)
# Da PowerShell keine direkte Übersetzung dieser Python-Funktionen hat, müssen wir sie selbst implementieren

function Get-FileModificationTime {
    param (
        [string]$Path
    )
    try {
        $files = Get-ChildItem -Path $Path -Recurse -File | Where-Object { $_.FullName -notlike "*.git*" }
        if ($files.Count -eq 0) {
            return 0
        }
        $latestFile = ($files | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
        return [DateTimeOffset]::new($latestFile.LastWriteTime).ToUnixTimeSeconds()
    } catch {
        return 0
    }
}

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Out-Host
}

function Validate-Skill {
    param (
        [string]$SkillPath
    )
    # Implementierung abhängig von der Logik in validate_skill
    # Hier wird angenommen, dass es eine einfache Prüfung ist
    Test-Path -Path "$SkillPath/skill.json"
}

function Sync-ToGit {
    param (
        [string]$SkillName,
        [bool]$DryRun = $false
    )
    # Implementierung abhängig von der Logik in sync_to_git
    # Hier wird angenommen, dass es eine einfache Kopie ist
    $source = Join-Path "/home/openclaw/.openclaw/workspace/skills" $SkillName
    $destination = Join-Path "/home/openclaw/.openclaw/workspace/git/skills" $SkillName
    
    if (-not $DryRun) {
        Copy-Item -Path $source -Destination $destination -Recurse -Force
    }
    return $true
}

function Sync-ToClawHub {
    param (
        [string]$SkillName,
        [bool]$DryRun = $false
    )
    # Implementierung abhängig von der Logik in sync_to_clawhub
    # Hier wird angenommen, dass es eine einfache Kopie ist
    $source = Join-Path "/home/openclaw/.openclaw/workspace/git/skills" $SkillName
    $destination = Join-Path "/home/openclaw/.openclaw/workspace/skills" $SkillName
    
    if (-not $DryRun) {
        Copy-Item -Path $source -Destination $destination -Recurse -Force
    }
    return $true
}

$CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills"
$GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills"

Write-Log ("=" * 70)
Write-Log "CLAWHUB ↔ GIT SYNC AGENT - PRODUKTIONS-LAUF"
Write-Log "Zeitstempel: $(Get-Date -Format o)"
Write-Log ("=" * 70)

$clawhubSkills = Get-ChildItem -Path $CLAWHUB_DIR -Directory | Where-Object { !$_.Name.StartsWith('.') }
$gitSkills = Get-ChildItem -Path $GIT_DIR -Directory | Where-Object { !$_.Name.StartsWith('.') }

$results = @{
    synced_to_git       = @()
    synced_to_clawhub   = @()
    up_to_date          = @()
    errors              = @()
}

# 1. NEU in ClawHub → zu Git syncen
Write-Log ""
Write-Log "[PHASE 1] ClawHub → Git Synchronisation"
Write-Log ("-" * 40)

$newInClawhub = Compare-Object -ReferenceObject $clawhubSkills.Name -DifferenceObject $gitSkills.Name -PassThru | Where-Object { $_.SideIndicator -eq "<=" } | Sort-Object
foreach ($skill in $newInClawhub) {
    try {
        $skillPath = Join-Path $CLAWHUB_DIR $skill
        if (Validate-Skill -SkillPath $skillPath) {
            Write-Log "-> Synchronisiere $skill zu Git..."
            if (Sync-ToGit -SkillName $skill -DryRun $false) {
                # Git init
                $gitPath = Join-Path $GIT_DIR $skill
                Set-Location $gitPath
                git init --quiet 2>$null
                git add . --force 2>$null
                $dt = Get-Date -Format "yyyy-MM-dd HH:mm"
                git commit -m "Initial: $skill" --quiet 2>$null
                $results.synced_to_git += $skill
                Write-Log "  ✓ $skill synchronisiert & Git initialisiert"
            } else {
                $results.errors += "$skill (sync failed)"
            }
        } else {
            $results.errors += "$skill (invalid)"
        }
    } catch {
        Write-Log "  ✗ ERROR: $skill - $_" "ERROR"
        $results.errors += "$skill (exception)"
    }
}

# 2. In beiden - prüfe Änderungen
Write-Log ""
Write-Log "[PHASE 2] Prüfe existierende Skills auf Änderungen"
Write-Log ("-" * 40)

$inBoth = Compare-Object -ReferenceObject $clawhubSkills.Name -DifferenceObject $gitSkills.Name -IncludeEqual -ExcludeDifferent | ForEach-Object { $_.InputObject } | Sort-Object
foreach ($skill in $inBoth) {
    try {
        $cMtime = Get-FileModificationTime -Path (Join-Path $CLAWHUB_DIR $skill)
        $gMtime = Get-FileModificationTime -Path (Join-Path $GIT_DIR $skill)
        $diff = $cMtime - $gMtime

        if ([Math]::Abs($diff) -gt 60) {
            if ($diff -gt 0) {
                Write-Log "-> $skill`: ClawHub neuer (+$([Math]::Floor($diff))s) → sync zu Git"
                if (Sync-ToGit -SkillName $skill -DryRun $false) {
                    $gitPath = Join-Path $GIT_DIR $skill
                    Set-Location $gitPath
                    git add . --force 2>$null
                    $dt = Get-Date -Format "yyyy-MM-dd HH:mm"
                    git commit -m "Sync from ClawHub: $dt" --quiet 2>$null
                    $results.synced_to_git += $skill
                } else {
                    $results.errors += "$skill (update failed)"
                }
            } else {
                Write-Log "-> $skill`: Git neuer (+$([Math]::Floor([Math]::Abs($diff)))s) → sync zu ClawHub"
                if (Sync-ToClawHub -SkillName $skill -DryRun $false) {
                    $results.synced_to_clawhub += $skill
                } else {
                    $results.errors += "$skill (update failed)"
                }
            }
        } else {
            $results.up_to_date += $skill
        }
    } catch {
        Write-Log "  ✗ ERROR: $skill - $_" "ERROR"
        $results.errors += "$skill (exception)"
    }
}

# ZUSAMMENFASSUNG
Write-Log ""
Write-Log ("=" * 70)
Write-Log "SYNCHRONISATION ABGESCHLOSSEN"
Write-Log ("=" * 70)
Write-Log "Zu Git synchronisiert:     $($results.synced_to_git.Count)"
if ($results.synced_to_git.Count -gt 0) {
    Write-Log "  $($results.synced_to_git -join ', ')"
}
Write-Log "Zu ClawHub synchronisiert: $($results.synced_to_clawhub.Count)"
if ($results.synced_to_clawhub.Count -gt 0) {
    Write-Log "  $($results.synced_to_clawhub -join ', ')"
}
Write-Log "Bereits aktuell:           $($results.up_to_date.Count)"
Write-Log "Fehler:                    $($results.errors.Count)"
if ($results.errors.Count -gt 0) {
    Write-Log "  $($results.errors -join ', ')"
}
Write-Log ("=" * 70)

# Speichere State
$STATE_FILE = "/home/openclaw/.openclaw/workspace/db/sync_state.json"
$stateDir = Split-Path $STATE_FILE -Parent
if (!(Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}
$state = @{
    last_run = (Get-Date).ToString("o")
    results = $results
}
$state | ConvertTo-Json -Depth 3 | Set-Content -Path $STATE_FILE
Write-Log "State gespeichert: $STATE_FILE"
