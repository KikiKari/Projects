#!/usr/bin/env pwsh
# channel_status.js — portiert nach powershell
# Quelle: javascript, Projects@abstractions:javascript/channel_status.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Channel Status Agent - Automatische Status-Updates
#>

# Konfiguration
$WORKSPACE = Join-Path $env:HOME ".openclaw/workspace"
$LOGS_DB = Join-Path $WORKSPACE "db/logs.db"
$CONFIG_FILE = Join-Path $WORKSPACE "config/channel-status.json"
$LOG_FILE = Join-Path $WORKSPACE "logs/channel-status.log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    <# Logging #>
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $entry = "[$timestamp] [$Level] $Message"
    Write-Output $entry
    Add-Content -Path $LOG_FILE -Value $entry
}

function Get-SystemStatus {
    <# Sammelt System-Status #>
    $status = @{
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        nodes = @{}
        agents = @{}
        system = @{}
    }
    
    # Node-Status (vereinfacht)
    $nodes = @{
        "node1" = @{name = "Gateway"; status = "online"}
        "node2" = @{name = "Worker"; status = "online"}
        "node3" = @{name = "Relay"; status = "offline"; reason = "disk full"}
        "node5" = @{name = "Redmi"; status = "intermittent"}
        "node7" = @{name = "Docker"; status = "planned"}
    }
    $status.nodes = $nodes
    
    # Agent-Status aus Cron
    try {
        $cronLines = (crontab -l | Where-Object { $_ -and -not $_.StartsWith("#") }).Count
        $status.agents.active_crons = $cronLines
    } catch {
        $status.agents.active_crons = "unknown"
    }
    
    # System-Metriken
    try {
        # Disk usage
        $df = df -h /
        foreach ($line in $df) {
            if ($line -match "/" -and $line -match "%") {
                $parts = $line -split '\s+'
                $status.system.disk_used = $parts[4]
                break
            }
        }
        
        # RAM usage
        $free = free -h
        foreach ($line in $free) {
            if ($line -match "Mem:") {
                $parts = $line -split '\s+'
                $status.system.ram_total = $parts[1]
                $status.system.ram_used = $parts[2]
                break
            }
        }
    } catch {
        # Ignore errors
    }
    
    return $status
}

function Format-DailyStatus {
    param([hashtable]$Status)
    <# Formatiert täglichen Status #>
    $nodes = $Status.nodes
    $online = ($nodes.Values | Where-Object { $_.status -eq "online" }).Count
    
    $timestamp = (Get-Date).ToString("dd.MM.yyyy HH:mm")
    
    $message = "📊 **Täglicher Status-Report**
🗓️ $timestamp

**🖥️ Nodes ($online/5 online):**
"
    
    foreach ($nodeId in $nodes.Keys) {
        $info = $nodes[$nodeId]
        $emoji = if ($info.status -eq "online") { "🟢" } elseif ($info.status -eq "offline") { "🔴" } else { "🟡" }
        $message += "$emoji $($info.name): $($info.status)"
        if ($info.reason) {
            $message += " ($($info.reason))"
        }
        $message += "`n"
    }
    
    $message += "`n**🤖 Agents:**`n"
    $message += "Aktive Cron-Jobs: $($Status.agents.active_crons)`n"
    
    if ($Status.system.disk_used) {
        $message += "`n**💾 System:**`n"
        $message += "Disk: $($Status.system.disk_used) belegt`n"
        $message += "RAM: $($Status.system.ram_used) / $($Status.system.ram_total)`n"
    }
    
    return $message
}

function Format-WeeklyStatus {
    param([hashtable]$Status)
    <# Formatiert wöchentlichen Status #>
    $now = Get-Date
    $dayOfYear = (Get-Date -Month 1 -Day 1 -Year $now.Year) 
    $weekNumber = [Math]::Ceiling((($now - $dayOfYear).Days + $now.DayOfWeek.value__ + 1) / 7)
    
    return "📈 **Wöchentlicher Report**
📅 Woche $($weekNumber.ToString('00')) - $($now.Year)

**Zusammenfassung:**
- 5 aktive Sub-Agents
- 11 Skills synchronisiert
- 3 neue Features implementiert

**Top-Ereignisse:**
1. ClawHub-Git Sync implementiert ✅
2. Node 3 Disk voll (95%) ⚠️
3. Channel-Status-Agent aktiviert 🆕

**Geplante Wartungen:**
- Node 3: Disk-Cleanup erforderlich
- Node 7: Docker-Setup ausstehend
"
}

function Send-ToChannel {
    param(
        [string]$Message,
        [string]$ChannelType = "telegram",
        [string]$ChannelId = "-1002381931352"
    )
    <# Sendet Nachricht an Channel #>
    if ($ChannelType -eq "telegram") {
        # Nutze OpenClaw message tool
        $cmd = "openclaw message send --target $ChannelId --message `"$($Message.Replace('"', '\"'))`""
    } else {
        Write-Log "Channel type $ChannelType not implemented" "WARN"
        return $false
    }
    
    try {
        Invoke-Expression $cmd | Out-Null
        Write-Log "Message sent to $ChannelType $ChannelId"
        return $true
    } catch {
        Write-Log "Failed to send: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Show-Usage {
    Write-Output "Usage: channel_status.ps1 --type [daily|weekly|alert] [options]"
    Write-Output ""
    Write-Output "Options:"
    Write-Output "  --type        Type of status update (daily, weekly, alert)"
    Write-Output "  --message     Alert message"
    Write-Output "  --channel     Channel ID (default: -1002381931352)"
    Write-Output "  --dry-run     Show message without sending"
    Write-Output "  --help        Show this help"
}

function Main {
    <# Hauptfunktion #>
    $type = $null
    $message = $null
    $channel = "-1002381931352"
    $dryRun = $false
    
    # Parameter parsen
    $i = 0
    while ($i -lt $args.Count) {
        $arg = $args[$i]
        switch ($arg) {
            "--type" {
                $i++
                if ($i -lt $args.Count) {
                    $type = $args[$i]
                }
            }
            "--message" {
                $i++
                if ($i -lt $args.Count) {
                    $message = $args[$i]
                }
            }
            "--channel" {
                $i++
                if ($i -lt $args.Count) {
                    $channel = $args[$i]
                }
            }
            "--dry-run" {
                $dryRun = $true
            }
            "--help" {
                Show-Usage
                return
            }
            default {
                if (-not $type) {
                    $type = $arg
                }
            }
        }
        $i++
    }
    
    if (-not $type) {
        Write-Error "Missing required --type parameter"
        Show-Usage
        return
    }
    
    Write-Log "Starting $type status update"
    
    # Status sammeln
    $status = Get-SystemStatus
    
    # Message formatieren
    switch ($type) {
        "daily" {
            $messageContent = Format-DailyStatus $status
        }
        "weekly" {
            $messageContent = Format-WeeklyStatus $status
        }
        "alert" {
            $alertText = if ($message) { $message } else { "Manual alert" }
            $messageContent = "🚨 **ALERT**`n$alertText"
        }
        default {
            Write-Error "Invalid type: $type"
            return
        }
    }
    
    # Senden oder Dry-Run
    if ($dryRun) {
        Write-Output "`n--- DRY RUN ---"
        Write-Output $messageContent
        Write-Output "--- END ---"
    } else {
        Send-ToChannel $messageContent "telegram" $channel | Out-Null
    }
    
    Write-Log "Status update completed"
}

# Ensure log directory exists
$logDir = Split-Path $LOG_FILE -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

Main @args
