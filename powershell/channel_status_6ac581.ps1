#!/usr/bin/env pwsh
# channel_status.sh — portiert nach powershell
# Quelle: shell, Projects@abstractions:shell/channel_status.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Channel Status Agent - Automatische Status-Updates

# Konfiguration
$WORKSPACE = "$env:USERPROFILE\.openclaw\workspace"
$LOGS_DB = "$WORKSPACE\db\logs.db"
$CONFIG_FILE = "$WORKSPACE\config\channel-status.json"
$LOG_FILE = "$WORKSPACE\logs\channel-status.log"

# Logging
function Log {
    param(
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$level] $message"
    Write-Output $entry
    Add-Content -Path $LOG_FILE -Value $entry
}

# Sammelt System-Status
function Get-SystemStatus {
    $timestamp = Get-Date -Format "o"
    $status = @{
        timestamp = $timestamp
        nodes = @{
            node1 = @{name = "Gateway"; status = "online"}
            node2 = @{name = "Worker"; status = "online"}
            node3 = @{name = "Relay"; status = "offline"; reason = "disk full"}
            node5 = @{name = "Redmi"; status = "intermittent"}
            node7 = @{name = "Docker"; status = "planned"}
        }
        agents = @{}
        system = @{}
    }

    # Agent-Status aus geplanten Aufgaben
    try {
        $scheduledTasks = Get-ScheduledTask | Where-Object State -eq "Ready" | Measure-Object
        $status.agents.active_crons = $scheduledTasks.Count
    } catch {
        $status.agents.active_crons = "unknown"
    }

    # System-Metriken
    $diskInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskUsedPercent = [math]::Round((($diskInfo.Size - $diskInfo.FreeSpace) / $diskInfo.Size) * 100, 2)
    $status.system.disk_used = "$diskUsedPercent%"

    $memory = Get-WmiObject -Class Win32_PhysicalMemory
    $totalMemory = ($memory | Measure-Object -Property Capacity -Sum).Sum / 1GB
    $status.system.ram_total = "{0:F1} GB" -f $totalMemory

    $os = Get-WmiObject -Class Win32_OperatingSystem
    $freeMemory = $os.FreePhysicalMemory / 1MB
    $usedMemory = ($totalMemory * 1024) - $freeMemory
    $status.system.ram_used = "{0:F1} GB" -f ($usedMemory / 1024)

    return $status | ConvertTo-Json -Depth 10
}

# Formatiert täglichen Status
function Format-DailyStatus {
    param([string]$statusJson)
    
    $status = $statusJson | ConvertFrom-Json
    $message = "📊 **Täglicher Status-Report**`n"
    $message += (Get-Date -Format "🗓️ yyyy-MM-dd HH:mm") + "`n`n"
    
    $onlineNodes = ($status.nodes.PSObject.Properties | Where-Object { $_.Value.status -eq "online" }).Count
    $message += "**🖥️ Nodes ($onlineNodes/5 online):**`n"
    
    foreach ($node in $status.nodes.PSObject.Properties) {
        $nodeData = $node.Value
        switch ($nodeData.status) {
            "online" { $emoji = "🟢" }
            "offline" { $emoji = "🔴" }
            default { $emoji = "🟡" }
        }
        $message += "$emoji $($nodeData.name): $($nodeData.status)"
        if ($nodeData.reason) {
            $message += " ($($nodeData.reason))"
        }
        $message += "`n"
    }
    
    $message += "`n**🤖 Agents:**`n"
    $message += "Aktive Cron-Jobs: $($status.agents.active_crons)`n"
    
    if ($status.system.disk_used) {
        $message += "`n**💾 System:**`n"
        $message += "Disk: $($status.system.disk_used) belegt`n"
        $message += "RAM: $($status.system.ram_used) / $($status.system.ram_total)`n"
    }
    
    return $message
}

# Formatiert wöchentlichen Status
function Format-WeeklyStatus {
    $message = "📈 **Wöchentlicher Report**`n"
    $message += (Get-Date -UFormat "📅 Woche %V - %Y") + "`n`n"
    
    $message += "**Zusammenfassung:**`n"
    $message += "- 5 aktive Sub-Agents`n"
    $message += "- 11 Skills synchronisiert`n"
    $message += "- 3 neue Features implementiert`n`n"
    
    $message += "**Top-Ereignisse:**`n"
    $message += "1. ClawHub-Git Sync implementiert ✅`n"
    $message += "2. Node 3 Disk voll (95%) ⚠️`n"
    $message += "3. Channel-Status-Agent aktiviert 🆕`n`n"
    
    $message += "**Geplante Wartungen:**`n"
    $message += "- Node 3: Disk-Cleanup erforderlich`n"
    $message += "- Node 7: Docker-Setup ausstehend`n"
    
    return $message
}

# Sendet Nachricht an Channel
function Send-ToChannel {
    param(
        [string]$message,
        [string]$channelType = "telegram",
        [string]$channelId = "-1002381931352"
    )
    
    if ($channelType -eq "telegram") {
        $cmd = "openclaw message send --target $channelId --message `"$message`""
    } else {
        Log "Channel type $channelType not implemented" "WARN"
        return $false
    }
    
    try {
        Invoke-Expression $cmd | Out-Null
        Log "Message sent to $channelType $channelId"
        return $true
    } catch {
        Log "Failed to send message" "ERROR"
        return $false
    }
}

# Hauptfunktion
function Main {
    param(
        [string]$type,
        [string]$message,
        [string]$channel = "-1002381931352",
        [switch]$dryRun
    )
    
    if (-not $type) {
        Write-Error "Fehler: --type ist erforderlich"
        exit 1
    }
    
    Log "Starting $type status update"
    
    # Status sammeln
    $status = Get-SystemStatus
    
    # Message formatieren
    $formattedMessage = ""
    switch ($type) {
        "daily" {
            $formattedMessage = Format-DailyStatus $status
        }
        "weekly" {
            $formattedMessage = Format-WeeklyStatus
        }
        "alert" {
            $formattedMessage = "🚨 **ALERT**`n$(if ($message) { $message } else { 'Manual alert' })"
        }
        default {
            Write-Error "Unbekannter Typ: $type"
            exit 1
        }
    }
    
    # Senden oder Dry-Run
    if ($dryRun) {
        Write-Output ""
        Write-Output "--- DRY RUN ---"
        Write-Output $formattedMessage
        Write-Output "--- END ---"
        Write-Output ""
    } else {
        Send-ToChannel $formattedMessage "telegram" $channel
    }
    
    Log "Status update completed"
}

# Sicherstellen, dass das Log-Verzeichnis existiert
$null = New-Item -ItemType Directory -Path (Split-Path $LOG_FILE) -Force

# Argumente parsen
$argType = $null
$argMessage = $null
$argChannel = "-1002381931352"
$dryRun = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        "--type" {
            $argType = $args[++$i]
        }
        "--message" {
            $argMessage = $args[++$i]
        }
        "--channel" {
            $argChannel = $args[++$i]
        }
        "--dry-run" {
            $dryRun = $true
        }
        default {
            Write-Error "Unbekannte Option: $($args[$i])"
            exit 1
        }
    }
}

# Hauptfunktion aufrufen
Main -type $argType -message $argMessage -channel $argChannel -dryRun:$dryRun
