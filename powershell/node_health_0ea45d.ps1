#!/usr/bin/env pwsh
# node_health.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway2:skills/node-health-monitor/scripts/node_health.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

<#
Node Health Monitor - Multi-Node Gesundheitsüberwachung
#>

# Konfiguration
$WORKSPACE = [System.IO.Path]::Combine($env:HOME, ".openclaw", "workspace")
$HEALTH_DB = [System.IO.Path]::Combine($WORKSPACE, "db", "health.db")
$LOG_FILE = [System.IO.Path]::Combine($WORKSPACE, "logs", "node-health.log")

# Node-Definitionen
$NODES = @{
    node1 = @{
        name = "Node 1"
        host = "localhost"
        user = "openclaw"
        critical = $true
    }
    node2 = @{
        name = "Node 2"
        host = "10.10.0.2"
        user = "root"
        ssh_key = "~/.ssh/id_rsa"
        ssh_opts = "-o ConnectTimeout=10 -o BatchMode=yes"
    }
    node3 = @{
        name = "Node 3"
        host = "localhost"
        user = "root"
        port = 18794
        ssh_opts = "-p 18794 -o ConnectTimeout=10 -o BatchMode=yes"
        disk_warning = 85
    }
    node5 = @{
        name = "Redmi"
        host = "192.168.1.x"
        user = "openclaw"
        optional = $true
    }
}

function Write-Log {
    param(
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$level] $message"
    Write-Output $entry
    $logDir = [System.IO.Path]::GetDirectoryName($LOG_FILE)
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $LOG_FILE -Value $entry
}

function Test-Ping {
    param(
        [string]$host,
        [int]$timeout = 10
    )
    try {
        $result = Test-Connection -ComputerName $host -Count 1 -TimeoutSeconds $timeout -Quiet
        return $result
    }
    catch {
        return $false
    }
}

function Test-SSH {
    param(
        [hashtable]$nodeConfig
    )
    $host = $nodeConfig["host"]
    $user = if ($nodeConfig.ContainsKey("user")) { $nodeConfig["user"] } else { "root" }
    $ssh_opts = if ($nodeConfig.ContainsKey("ssh_opts")) { $nodeConfig["ssh_opts"] } else { "" }
    $port = if ($nodeConfig.ContainsKey("port")) { $nodeConfig["port"] } else { $null }
    
    $cmd = @("ssh")
    if ($ssh_opts) {
        $cmd += $ssh_opts -split '\s+'
    }
    if ($port) {
        $cmd += @("-p", $port)
    }
    $cmd += @("-o", "ConnectTimeout=10", "-o", "BatchMode=yes", "$user@$host", "echo", '"OK"')
    
    try {
        $result = & $cmd 2>$null | Out-String
        return ($LASTEXITCODE -eq 0) -and ($result -match "OK")
    }
    catch {
        return $false
    }
}

function Get-NodeMetrics {
    param(
        [hashtable]$nodeConfig
    )
    $host = $nodeConfig["host"]
    $user = if ($nodeConfig.ContainsKey("user")) { $nodeConfig["user"] } else { "root" }
    
    $metrics = @{
        timestamp = (Get-Date).ToString("o")
        available = $false
        cpu = $null
        ram = $null
        disk = $null
        load = $null
    }
    
    # SSH-Command für alle Metriken
    $cmd = @"
ssh -o ConnectTimeout=10 $user@$host '
    # CPU
    echo "CPU:\$(top -bn1 | grep "Cpu(s)" | awk "{print \$2}" | cut -d"%" -f1)"
    
    # RAM
    echo "RAM:\$(free | grep Mem | awk "{print (\$3/\$2) * 100.0}")"
    
    # Disk
    echo "DISK:\$(df -h / | tail -1 | awk "{print \$5}" | tr -d "%")"
    
    # Load
    echo "LOAD:\$(uptime | awk -F"load average:" "{print \$2}" | awk "{print \$1}" | tr -d ",")"
    
    # Gateway Status
    if command -v openclaw >/dev/null 2>&1; then
        systemctl is-active openclaw-gateway 2>/dev/null || echo "GATEWAY:inactive"
    fi
'
"@
    
    try {
        $result = Invoke-Expression $cmd 2>$null
        if ($LASTEXITCODE -eq 0) {
            $metrics.available = $true
            
            foreach ($line in ($result -split "`n" | Where-Object { $_ -match ":" })) {
                $parts = $line -split ":", 2
                $key = $parts[0]
                $value = $parts[1]
                
                switch ($key) {
                    "CPU" { 
                        if ($value -match '^\d+\.?\d*$') { $metrics.cpu = [float]$value }
                    }
                    "RAM" { 
                        if ($value -match '^\d+\.?\d*$') { $metrics.ram = [float]$value }
                    }
                    "DISK" { 
                        if ($value -match '^\d+$') { $metrics.disk = [int]$value }
                    }
                    "LOAD" { 
                        if ($value -match '^\d+\.?\d*$') { $metrics.load = [float]$value }
                    }
                    "GATEWAY" { 
                        $metrics.gateway_status = $value 
                    }
                }
            }
        }
    }
    catch {
        Write-Log "Error checking $($nodeConfig['name']): $_" "ERROR"
    }
    
    return $metrics
}

function Test-Alerts {
    param(
        [string]$nodeId,
        [hashtable]$nodeConfig,
        [hashtable]$metrics
    )
    $alerts = @()
    
    # Verfügbarkeit
    if (-not $metrics["available"]) {
        if (-not $nodeConfig.ContainsKey("optional") -or -not $nodeConfig["optional"]) {
            $alerts += @{
                level = "CRITICAL"
                message = "Node $($nodeConfig['name']) nicht erreichbar!"
            }
        }
    }
    else {
        # CPU
        if ($metrics["cpu"] -and $metrics["cpu"] -gt 90) {
            $alerts += @{
                level = "WARNING"
                message = "Node $($nodeConfig['name']): CPU bei $($metrics['cpu'].ToString('F1'))%"
            }
        }
        
        # RAM
        if ($metrics["ram"] -and $metrics["ram"] -gt 90) {
            $alerts += @{
                level = "WARNING"
                message = "Node $($nodeConfig['name']): RAM bei $($metrics['ram'].ToString('F1'))%"
            }
        }
        
        # Disk
        $disk_threshold = if ($nodeConfig.ContainsKey("disk_warning")) { $nodeConfig["disk_warning"] } else { 85 }
        if ($metrics["disk"] -and $metrics["disk"] -gt $disk_threshold) {
            $level = if ($metrics["disk"] -gt 95) { "CRITICAL" } else { "WARNING" }
            $alerts += @{
                level = $level
                message = "Node $($nodeConfig['name']): Disk bei $($metrics['disk'])%"
            }
        }
        
        # Gateway
        if ($nodeConfig.ContainsKey("critical") -and $nodeConfig["critical"] -and 
            $metrics.ContainsKey("gateway_status") -and $metrics["gateway_status"] -eq "inactive") {
            $alerts += @{
                level = "CRITICAL"
                message = "Node $($nodeConfig['name']): OpenClaw Gateway nicht aktiv!"
            }
        }
    }
    
    return $alerts
}

function Send-Alert {
    param(
        [hashtable]$alert
    )
    try {
        $cmd = @(
            "python3"
            [System.IO.Path]::Combine($WORKSPACE, "skills", "channel-status-agent", "scripts", "channel_status.py")
            "--type", "alert"
            "--message", "$($alert['level']): $($alert['message'])"
        )
        & $cmd 2>$null | Out-Null
        Write-Log "Alert sent: $($alert['message'])"
    }
    catch {
        Write-Log "Failed to send alert: $_" "ERROR"
    }
}

function Main {
    param(
        [string]$node = "all",
        [string]$check = "all",
        [switch]$alert
    )
    
    # Nodes bestimmen
    if ($node -eq 'all') {
        $nodes_to_check = $NODES.GetEnumerator()
    }
    else {
        if ($NODES.ContainsKey($node)) {
            $nodes_to_check = @([System.Collections.DictionaryEntry]::new($node, $NODES[$node]))
        }
        else {
            Write-Log "Unknown node: $node" "ERROR"
            exit 1
        }
    }
    
    # Health-Checks durchführen
    $all_alerts = @()
    
    foreach ($item in $nodes_to_check) {
        $node_id = $item.Key
        $node_config = $item.Value
        Write-Log "Checking $($node_config['name']) ($node_id)"
        
        # Ping
        if ($check -in @('ping', 'all')) {
            if ($node_config["host"] -ne "localhost") {
                $ping_ok = Test-Ping -host $node_config["host"]
                Write-Log "  Ping: $(if ($ping_ok) { 'OK' } else { 'FAILED' })"
            }
        }
        
        # SSH
        if ($check -in @('ssh', 'all')) {
            $ssh_ok = Test-SSH -nodeConfig $node_config
            Write-Log "  SSH: $(if ($ssh_ok) { 'OK' } else { 'FAILED' })"
        }
        
        # Metriken
        if ($check -in @('metrics', 'all')) {
            $metrics = Get-NodeMetrics -nodeConfig $node_config
            
            if ($metrics["available"]) {
                Write-Log "  CPU: $(if ($metrics['cpu']) { "$('{0:F1}' -f $metrics['cpu'])%" } else { "N/A" })"
                Write-Log "  RAM: $(if ($metrics['ram']) { "$('{0:F1}' -f $metrics['ram'])%" } else { "N/A" })"
                Write-Log "  Disk: $(if ($metrics['disk']) { "$($metrics['disk'])%" } else { "N/A" })"
                Write-Log "  Load: $(if ($metrics['load']) { "$($metrics['load'])" } else { "N/A" })"
            }
            else {
                Write-Log "  Metrics: UNAVAILABLE"
            }
            
            # Alerts prüfen
            $alerts = Test-Alerts -nodeId $node_id -nodeConfig $node_config -metrics $metrics
            $all_alerts += $alerts
        }
    }
    
    # Alerts senden
    if ($alert -and $all_alerts.Count -gt 0) {
        Write-Log "`nSending $($all_alerts.Count) alerts..."
        foreach ($alert_item in $all_alerts) {
            Send-Alert -alert $alert_item
        }
    }
    elseif ($all_alerts.Count -gt 0) {
        Write-Log "`n$($all_alerts.Count) alerts found (use --alert to send)"
    }
    else {
        Write-Log "`nAll nodes healthy!"
    }
}

# Parameter parsing
$param_node = "all"
$param_check = "all"
$param_alert = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        { $_ -in "--node", "-n" } {
            $i++
            if ($i -lt $args.Count) {
                $param_node = $args[$i]
            }
        }
        { $_ -in "--check", "-c" } {
            $i++
            if ($i -lt $args.Count) {
                $param_check = $args[$i]
            }
        }
        "--alert" {
            $param_alert = $true
        }
        "--help" {
            Write-Output "Node Health Monitor"
            Write-Output "Usage: node_health.ps1 [--node NODE] [--check CHECK] [--alert]"
            Write-Output "  --node NODE     Node ID oder 'all' (default: all)"
            Write-Output "  --check CHECK   Check type: ping, ssh, metrics, all (default: all)"
            Write-Output "  --alert         Sende Alerts"
            exit 0
        }
    }
}

Main -node $param_node -check $param_check -alert:$param_alert
