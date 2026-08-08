#!/usr/bin/env pwsh
# abstractions-publish-gateway.sh — portiert nach powershell
# Quelle: shell, Projects@clawhub:clawhub/Scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Pusht den Stand von workspace/git/Abstraktionen/ auf den
# gateway{1,2}-abstractions-Branch.
#
# Exit-Codes:
#   0 = Erfolg (gepusht ODER nichts zu tun)
#   1 = Unerwarteter Branch
#   2 = Secret im Diff gefunden
#   3 = Git-Operation fehlgeschlagen
#   4 = Repo-Pfad nicht erreichbar oder kein Git-Repo

$ErrorActionPreference = "Stop"

$ABSTRACTIONS_REPO = "/home/openclaw/.openclaw/workspace/git/Abstraktionen"
$LOG_DIR = "/home/openclaw/.openclaw/logs/abstractions-publish-gateway"
$null = New-Item -ItemType Directory -Path $LOG_DIR -Force
$LOG_FILE = Join-Path $LOG_DIR "$(Get-Date -Format 'yyyy-MM-dd').log"

function Log {
    param([string]$msg)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine = "[$ts] $msg"
    Add-Content -Path $LOG_FILE -Value $logLine
    Write-Output $logLine
}

# --- Schritt 1: Repo erreichbar? ---
try {
    Set-Location -Path $ABSTRACTIONS_REPO -ErrorAction Stop
} catch {
    Log "STATUS=error CODE=4 REASON=repo-unreachable PATH=$ABSTRACTIONS_REPO"
    exit 4
}

if (-not (Test-Path ".git")) {
    Log "STATUS=error CODE=4 REASON=not-a-git-repo PATH=$ABSTRACTIONS_REPO"
    exit 4
}

# --- Schritt 2: Branch ermitteln ---
try {
    $BRANCH = git branch --show-current 2>$null
    if ($BRANCH -ne "gateway1-abstractions" -and $BRANCH -ne "gateway2-abstractions") {
        Log "STATUS=error CODE=1 REASON=unexpected-branch BRANCH=$BRANCH"
        exit 1
    }
    Log "STATUS=info STEP=branch-detected BRANCH=$BRANCH"
} catch {
    Log "STATUS=error CODE=3 REASON=git-branch-failed"
    exit 3
}

# --- Schritt 3: Hat sich was geändert? ---
$STATUS_OUTPUT = git status --porcelain 2>$null
if ([string]::IsNullOrWhiteSpace($STATUS_OUTPUT)) {
    Log "STATUS=skip REASON=no-changes BRANCH=$BRANCH"
    exit 0
}

$CHANGED_COUNT = ($STATUS_OUTPUT -split "`n" | Where-Object { $_.Trim() -ne "" }).Count
Log "STATUS=info STEP=changes-detected COUNT=$CHANGED_COUNT BRANCH=$BRANCH"

# --- Schritt 4: Secret-Scan auf geänderte Dateien ---
$SECRET_PATTERNS = @(
    'sk-[A-Za-z0-9]{20,}'
    'ghp_[A-Za-z0-9]{30,}'
    'github_pat_[A-Za-z0-9_]{30,}'
    'ntn_[A-Za-z0-9]{30,}'
    'secret_[A-Za-z0-9]{30,}'
    'tvly-[A-Za-z0-9-]{20,}'
    'nvapi-[A-Za-z0-9]{30,}'
    'tskey-[A-Za-z0-9-]{20,}'
    'xoxb-[A-Za-z0-9-]{20,}'
    'xapp-[A-Za-z0-9-]{20,}'
    'AIza[A-Za-z0-9_-]{30,}'
)

$SECRET_HITS = @()

foreach ($line in $STATUS_OUTPUT) {
    $file_path = $line.Substring(3).Trim()
    if (Test-Path $file_path -PathType Leaf) {
        $content = Get-Content -Path $file_path -Raw
        foreach ($pattern in $SECRET_PATTERNS) {
            if ($content -match $pattern) {
                $matched = $matches[0]
                $displayMatch = if ($matched.Length -gt 10) { $matched.Substring(0, 10) } else { $matched }
                $SECRET_HITS += "$file_path[$displayMatch...]"
                break
            }
        }
    }
}

if ($SECRET_HITS.Count -gt 0) {
    $hitsStr = ($SECRET_HITS -join " ")
    Log "STATUS=error CODE=2 REASON=secrets-found HITS=$hitsStr"
    exit 2
}
Log "STATUS=info STEP=secret-scan-clean"

# --- Schritt 5: Stage + Commit ---
try {
    git add -A 2>&1 | Add-Content -Path $LOG_FILE
    if ($LASTEXITCODE -ne 0) {
        Log "STATUS=error CODE=3 REASON=git-add-failed"
        exit 3
    }
} catch {
    Log "STATUS=error CODE=3 REASON=git-add-failed"
    exit 3
}

$COMMIT_MSG = "auto: abstractions-sync $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
try {
    git commit -m "$COMMIT_MSG" 2>&1 | Add-Content -Path $LOG_FILE
    if ($LASTEXITCODE -ne 0) {
        $statusCheck = git status --porcelain 2>$null
        if (-not [string]::IsNullOrWhiteSpace($statusCheck)) {
            Log "STATUS=error CODE=3 REASON=git-commit-failed"
            exit 3
        } else {
            Log "STATUS=skip REASON=nothing-staged-after-add"
            exit 0
        }
    }
} catch {
    Log "STATUS=error CODE=3 REASON=git-commit-failed"
    exit 3
}

try {
    $COMMIT_HASH = git log -1 --format="%h"
    Log "STATUS=info STEP=commit-created HASH=$COMMIT_HASH MSG=`"$COMMIT_MSG`""
} catch {
    Log "STATUS=error CODE=3 REASON=git-log-failed"
    exit 3
}

# --- Schritt 6: Push ---
try {
    git push 2>&1 | Add-Content -Path $LOG_FILE
    if ($LASTEXITCODE -ne 0) {
        Log "STATUS=error CODE=3 REASON=git-push-failed BRANCH=$BRANCH HASH=$COMMIT_HASH"
        exit 3
    }
} catch {
    Log "STATUS=error CODE=3 REASON=git-push-failed BRANCH=$BRANCH HASH=$COMMIT_HASH"
    exit 3
}

# --- Erfolg ---
Log "STATUS=ok BRANCH=$BRANCH COUNT=$CHANGED_COUNT HASH=$COMMIT_HASH"
Write-Output ""
Write-Output "=== SUMMARY ==="
Write-Output "Branch:  $BRANCH"
Write-Output "Files:   $CHANGED_COUNT"
Write-Output "Commit:  $COMMIT_HASH"
Write-Output "Status:  OK - gepusht nach origin/$BRANCH"
exit 0
