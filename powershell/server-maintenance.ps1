#!/usr/bin/env pwsh
# server-maintenance.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/server-maintenance.sh
# auch in: OpenClaw@gateway2:scripts/server-maintenance.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Server Maintenance Script
# RAM: 8GB, Uhr: Europe/Berlin

$LOG_FILE = "/var/log/server-maintenance.log"
$DATE = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$HOST = hostname

function Write-Log {
    param([string]$Message)
    $logEntry = "[$DATE] $Message"
    Write-Output $logEntry
    Add-Content -Path $LOG_FILE -Value $logEntry
}

Write-Log "=== Server Maintenance Check ==="

# 1. APT Update Check
Write-Log "Checking for updates..."
try {
    apt update -qq 2>&1 | Select-Object -Last 5 | ForEach-Object { Write-Log $_ }
    $UPDATES = (apt list --upgradable 2>$null | Measure-Object).Count
    if ($UPDATES -gt 1) {
        Write-Log "⚠️ $UPDATES packages can be upgraded"
    }
} catch {
    Write-Log "Error checking for updates: $_"
}

# 2. RAM Check (8GB total)
Write-Log "Checking RAM usage..."
$RAM_TOTAL = 8192  # 8GB in MB
$RAM_USED = (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1024 - (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024
$RAM_USED = [Math]::Round($RAM_USED)
$RAM_PERCENT = [Math]::Round(($RAM_USED * 100) / $RAM_TOTAL)
Write-Log "RAM: ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PERCENT}%)"
if ($RAM_PERCENT -gt 90) {
    Write-Log "🔴 WARNING: RAM usage > 90%!"
} elseif ($RAM_PERCENT -gt 80) {
    Write-Log "🟡 WARNING: RAM usage > 80%"
}

# 3. Disk Space Check
Write-Log "Checking disk space..."
$diskInfo = Get-PSDrive -Name "/"
$diskUsed = $diskInfo.Used / 1GB
$diskFree = $diskInfo.Free / 1GB
$diskTotal = $diskInfo.Used / 1GB + $diskFree / 1GB
$diskPercent = [Math]::Round(($diskInfo.Used / ($diskInfo.Used + $diskInfo.Free)) * 100)
Write-Log "Disk: $([Math]::Round($diskUsed, 2))GB / $([Math]::Round($diskTotal, 2))GB ($diskPercent% used)"
if ($diskPercent -gt 90) {
    Write-Log "🔴 WARNING: Disk > 90%!"
} elseif ($diskPercent -gt 80) {
    Write-Log "🟡 WARNING: Disk > 80%"
}

# 4. NTP Check
Write-Log "Checking NTP sync..."
try {
    $ntpStatus = timedatectl status 2>$null
    if ($ntpStatus -match "NTP synchronized: yes") {
        Write-Log "✅ NTP synchronized"
    } else {
        Write-Log "⚠️ NTP not synchronized"
    }
} catch {
    Write-Log "⚠️ NTP check failed: $_"
}

# 5. OpenClaw Gateway Status
Write-Log "Checking OpenClaw Gateway..."
try {
    $serviceStatus = systemctl is-active openclaw-gateway 2>$null
    if ($serviceStatus -eq "active") {
        Write-Log "✅ OpenClaw Gateway running"
    } else {
        Write-Log "🔴 OpenClaw Gateway NOT running!"
        systemctl restart openclaw-gateway 2>$null
    }
} catch {
    Write-Log "🔴 OpenClaw Gateway NOT running!"
    try {
        systemctl restart openclaw-gateway 2>$null
    } catch {
        Write-Log "Failed to restart OpenClaw Gateway: $_"
    }
}

# 6. Load Average
try {
    $LOAD = uptime | ForEach-Object { ($_ -split "load average:")[1].Trim().Split(',')[0].Trim() }
    Write-Log "Load Average: $LOAD"
} catch {
    Write-Log "Could not determine load average: $_"
}

Write-Log "=== Maintenance Complete ==="
Write-Log ""
