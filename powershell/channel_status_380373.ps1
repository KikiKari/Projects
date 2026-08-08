#!/usr/bin/env pwsh
# channel_status.pl — portiert nach powershell
# Quelle: perl5, Projects@abstractions:perl5/channel_status.pl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# channel_status.pl — portiert nach PowerShell 7
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Konfiguration
$WORKSPACE = "$env:HOME/.openclaw/workspace"
$LOGS_DB = "$WORKSPACE/db/logs.db"
$CONFIG_FILE = "$WORKSPACE/config/channel-status.json"
$LOG_FILE = "$WORKSPACE/logs/channel-status.log"

function Log-Message {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    Write-Output $entry
    $logDir = Split-Path $LOG_FILE -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }
    Add-Content -Path $LOG_FILE -Value $entry
}

function Get-SystemStatus {
    $status = @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        nodes = @{}
        agents = @{}
        system = @{}
    }
    
    # Node-Status (vereinfacht)
    $nodes = @{
        node1 = @{name = "Gateway"; status = "online"}
        node2 = @{name = "Worker"; status = "online"}
        node3 = @{name = "Relay"; status = "offline"; reason = "disk full"}
        node5 = @{name = "Redmi"; status = "intermittent"}
        node7 = @{name = "Docker"; status = "planned"}
    }
    $status.nodes = $nodes
    
    # Agent-Status aus Cron
    try {
        $cronOutput = crontab -l 2>$null
        if ($LASTEXITCODE -eq 0) {
            $lines = $cronOutput -split "`n" | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' }
            $status.agents.active_crons = $lines.Count
        } else {
            $status.agents.active_crons = "unknown"
        }
    } catch {
        $status.agents.active_crons = "unknown"
    }
    
    # System-Metriken
    try {
        # Disk usage
        $dfOutput = df -h /
        foreach ($line in $dfOutput) {
            if ($line -match '/' -and $line -match '%') {
                $parts = -split $line
                $status.system.disk_used = $parts[4]
                break
            }
        }
        
        # RAM usage
        $freeOutput = free -h
        foreach ($line in $freeOutput) {
            if ($line -match 'Mem:') {
                $parts = -split $line
                $status.system.ram_total = $parts[1]
                $status.system.ram_used = $parts[2]
                break
            }
        }
    } catch {
        # Ignoriere Fehler bei Systemmetriken
    }
    
    return $status
}

function Format-DailyStatus {
    param([hashtable]$Status)
    $nodes = $Status.nodes
    $online = ($nodes.Values | Where-Object { $_.status -eq "online" }).Count
    
    $message = "📊 **Täglicher Status-Report**`n"
    $message += "🗓️ $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n`n"
    $message += "**🖥️ Nodes ($online/5 online):**`n"
    
    $sortedKeys = $nodes.Keys | Sort-Object
    foreach ($node_id in $sortedKeys) {
        $info = $nodes[$node_id]
        $emoji = if ($info.status -eq "online") { "🟢" } elseif ($info.status -eq "offline") { "🔴" } else { "🟡" }
        $message += "$emoji $($info.name): $($info.status)"
        if ($info.ContainsKey("reason")) {
            $message += " ($($info.reason))"
        }
        $message += "`n"
    }
    
    $message += "`n**🤖 Agents:**`n"
    $message += "Aktive Cron-Jobs: $($Status.agents.active_crons)`n"
    
    if ($Status.system.ContainsKey("disk_used")) {
        $message += "`n**💾 System:**`n"
        $message += "Disk: $($Status.system.disk_used) belegt`n"
        $message += "RAM: $($Status.system.ram_used) / $($Status.system.ram_total)`n"
    }
    
    return $message
}

function Format-WeeklyStatus {
    param([hashtable]$Status)
    $weekNumber = Get-Date -UFormat %V
    $year = Get-Date -UFormat %Y
    $message = "📈 **Wöchentlicher Report**`n"
    $message += "📅 Woche $weekNumber - $year`n`n"
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

function Send-ToChannel {
    param(
        [string]$Message,
        [string]$ChannelType = "telegram",
        [string]$ChannelId = "-1002381931352"
    )
    
    if ($ChannelType -eq "telegram") {
        $cmd = "openclaw", "message", "send", "--target", $ChannelId, "--message", $Message
        try {
            $result = & $cmd 2>&1
            if ($LASTEXITCODE -ne 0) {
                Log-Message "Failed to send: $result" "ERROR"
                return $false
            } else {
                Log-Message "Message sent to $ChannelType $ChannelId"
                return $true
            }
        } catch {
            Log-Message "Failed to send: $_" "ERROR"
            return $false
        }
    } else {
        Log-Message "Channel type $ChannelType not implemented" "WARN"
        return $false
    }
}

function Main {
    param(
        [string]$Type,
        [string]$Message,
        [string]$Channel = "-1002381931352",
        [switch]$DryRun
    )
    
    if (-not $Type) {
        Write-Error "Type is required"
        exit 1
    }
    if ($Type -notin @("daily", "weekly", "alert")) {
        Write-Error "Invalid type: $Type"
        exit 1
    }
    
    Log-Message "Starting $Type status update"
    
    # Status sammeln
    $status = Get-SystemStatus
    
    # Message formatieren
    $formatted_message = ""
    if ($Type -eq 'daily') {
        $formatted_message = Format-DailyStatus $status
    } elseif ($Type -eq 'weekly') {
        $formatted_message = Format-WeeklyStatus $status
    } elseif ($Type -eq 'alert') {
        $formatted_message = "🚨 **ALERT**`n$(if ($Message) { $Message } else { 'Manual alert' })"
    }
    
    # Senden oder Dry-Run
    if ($DryRun) {
        Write-Output "`n--- DRY RUN ---"
        Write-Output $formatted_message
        Write-Output "--- END ---"
    } else {
        Send-ToChannel -Message $formatted_message -ChannelType "telegram" -ChannelId $Channel
    }
    
    Log-Message "Status update completed"
}

# Parameter parsen
$paramType = $null
$paramMessage = $null
$paramChannel = "-1002381931352"
$dryRun = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        "--type" { $paramType = $args[++$i] }
        "-t" { $paramType = $args[++$i] }
        "--message" { $paramMessage = $args[++$i] }
        "-m" { $paramMessage = $args[++$i] }
        "--channel" { $paramChannel = $args[++$i] }
        "-c" { $paramChannel = $args[++$i] }
        "--dry-run" { $dryRun = $true }
        default { 
            if ($args[$i] -like "--type=*") {
                $paramType = $args[$i].Split("=")[1]
            } elseif ($args[$i] -like "--message=*") {
                $paramMessage = $args[$i].Split("=")[1]
            } elseif ($args[$i] -like "--channel=*") {
                $paramChannel = $args[$i].Split("=")[1]
            }
        }
    }
}

Main -Type $paramType -Message $paramMessage -Channel $paramChannel -DryRun:$dryRun
