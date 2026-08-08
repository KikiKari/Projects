#!/usr/bin/env pwsh
# abstractions-publish-gateway-cron.sh — portiert nach powershell
# Quelle: shell, Projects@clawhub:clawhub/Scripts/abstractions-publish-gateway-cron.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Wrapper für Linux-crontab - setzt sauberes Environment
$env:HOME = "/home/openclaw"
$env:PATH = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

$LOG_DIR = "/home/openclaw/.openclaw/logs/abstractions-publish-gateway"
if (!(Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR -Force
}
$CRON_LOG = "$LOG_DIR/linux-cron.log"

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logEntry = @"

===== CRON START $timestamp =====
"@

Add-Content -Path $CRON_LOG -Value $logEntry

try {
    & "/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh"
    $exitCode = $LASTEXITCODE
} catch {
    $exitCode = 1
}

$endTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$endLogEntry = @"
===== CRON END (exit $exitCode) =====
"@

Add-Content -Path $CRON_LOG -Value $endLogEntry
