#!/usr/bin/env pwsh
# channel_status.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

<#
Channel Status Agent - Automatische Status-Updates
#>

# Konfiguration
$WORKSPACE = [System.IO.Path]::Combine($env:HOME, ".openclaw", "workspace")
$LOGS_DB = [System.IO.Path]::Combine($WORKSPACE, "db", "logs.db")
$CONFIG_FILE = [System.IO.Path]::Combine($WORKSPACE, "config", "channel-status.json")
$LOG_FILE = [System.IO.Path]::Combine($WORKSPACE, "logs", "channel-status.log")

function Write-Log {
    param(
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "[$timestamp] [$level] $message"
    Write-Output $entry
    Add-Content -Path $LOG_FILE -Value $entry
}

function Get-SystemStatus {
    $status = @{
        timestamp = (Get-Date).ToString("o")
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
        $cronResult = crontab -l 2>$null
        $cronLines = ($cronResult | Where-Object { $_ -notmatch "^#" } | Measure-Object).Count
        $status.agents.active_crons = $cronLines
    }
    catch {
        $status.agents.active_crons = "unknown"
    }

    # System-Metriken
    try {
        # Disk usage
        $dfOutput = df -h /
        foreach ($line in $dfOutput) {
            if ($line -match "/" -and $line -match "%") {
                $parts = -split $line
                $status.system.disk_used = $parts[4]
                break
            }
        }

        # RAM usage
        $freeOutput = free -h
        foreach ($line in $freeOutput) {
            if ($line -match "Mem:") {
                $parts = -split $line
                $status.system.ram_total = $parts[1]
                $status.system.ram_used = $parts[2]
                break
            }
        }
    }
    catch {
        # Ignoriere Fehler
    }

    return $status
}

function Format-DailyStatus {
    param($status)
    $nodes = $status.nodes
    $online = ($nodes.Values | Where-Object { $_.status -eq "online" } | Measure-Object).Count

    $message = "📊 **Täglicher Status-Report**
🗓️ $((Get-Date).ToString('yyyy-MM-dd HH:mm'))

**🖥️ Nodes ($online/5 online):**
"

    foreach ($node in $nodes.GetEnumerator()) {
        $emoji = switch ($node.Value.status) {
            "online" { "🟢" }
            "offline" { "🔴" }
            default { "🟡" }
        }
        $message += "$emoji $($node.Value.name): $($node.Value.status)"
        if ($node.Value.ContainsKey("reason")) {
            $message += " ($($node.Value.reason))"
        }
        $message += "`n"
    }

    $message += "`n**🤖 Agents:**`n"
    $message += "Aktive Cron-Jobs: $($status.agents.active_crons)`n"

    if ($status.system.ContainsKey("disk_used")) {
        $message += "`n**💾 System:**`n"
        $message += "Disk: $($status.system.disk_used) belegt`n"
        $message += "RAM: $($status.system.ram_used) / $($status.system.ram_total)`n"
    }

    return $message
}

function Format-WeeklyStatus {
    param($status)
    $message = "📈 **Wöchentlicher Report**
📅 Woche $((Get-Date).ToString('yyyy-\KW')) - $((Get-Date).Year)

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
    return $message
}

function Send-ToChannel {
    param(
        [string]$message,
        [string]$channelType = "telegram",
        [string]$channelId = "-1002381931352"
    )

    if ($channelType -eq "telegram") {
        $cmd = @("openclaw", "message", "send", "--target", $channelId, "--message", $message)
    }
    else {
        Write-Log "Channel type $channelType not implemented" "WARN"
        return $false
    }

    try {
        $result = & $cmd[0] $cmd[1..($cmd.Length-1)] 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Message sent to $channelType $channelId"
            return $true
        }
        else {
            Write-Log "Failed to send: $result" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Send error: $_" "ERROR"
        return $false
    }
}

function Main {
    param(
        [Parameter(Mandatory=$true)][ValidateSet("daily", "weekly", "alert")][string]$Type,
        [string]$Message,
        [string]$Channel = "-1002381931352",
        [switch]$DryRun
    )

    Write-Log "Starting $Type status update"

    # Status sammeln
    $status = Get-SystemStatus

    # Message formatieren
    switch ($Type) {
        "daily" { $message = Format-DailyStatus $status }
        "weekly" { $message = Format-WeeklyStatus $status }
        "alert" { $message = "🚨 **ALERT**`n$(if ($Message) { $Message } else { 'Manual alert' })" }
    }

    # Senden oder Dry-Run
    if ($DryRun) {
        Write-Output "`n--- DRY RUN ---"
        Write-Output $message
        Write-Output "--- END ---"
    }
    else {
        Send-ToChannel $message -channelId $Channel | Out-Null
    }

    Write-Log "Status update completed"
}

# Hauptprogramm
$ErrorActionPreference = "Stop"

# Erstelle Log-Verzeichnis falls nicht vorhanden
$logfileDir = Split-Path $LOG_FILE -Parent
if (!(Test-Path $logfileDir)) {
    New-Item -ItemType Directory -Path $logfileDir | Out-Null
}

# Parameter parsen
$paramType = $null
$paramMessage = $null
$paramChannel = "-1002381931352"
$dryRun = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        "--type" { $paramType = $args[++$i] }
        "--message" { $paramMessage = $args[++$i] }
        "--channel" { $paramChannel = $args[++$i] }
        "--dry-run" { $dryRun = $true }
    }
}

if (!$paramType) {
    Write-Error "Parameter --type ist erforderlich"
    exit 1
}

Main -Type $paramType -Message $paramMessage -Channel $paramChannel -DryRun:$dryRun
