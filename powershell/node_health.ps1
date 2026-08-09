#!/usr/bin/env pwsh
# node_health.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/node-health-monitor/scripts/node_health.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

<#
Node Health Monitor - Multi-Node Gesundheitsüberwachung
#>

# Konfiguration
$WORKSPACE = "/home/openclaw/.openclaw/workspace"
$HEALTH_DB = "$WORKSPACE/db/health.db"
$LOG_FILE = "$WORKSPACE/logs/node-health.log"

# Node-Definitionen
$NODES = @{
    "node1" = @{
        "name" = "Gateway"
        "host" = "localhost"
        "user" = "openclaw"
        "critical" = $true
    }
    "node2" = @{
        "name" = "Worker"
        "host" = "100.92.155.34"
        "user" = "root"
        "ssh_key" = "~/.ssh/id_rsa"
    }
    "node3" = @{
        "name" = "Relay"
        "host" = "185.242.xxx.xxx"
        "user" = "root"
        "disk_warning" = 85
    }
    "node5" = @{
        "name" = "Redmi"
        "host" = "192.168.1.x"
        "user" = "openclaw"
        "optional" = $true
    }
}

function Log-Message {
    param(
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$level] $message"
    Write-Host $entry
    $logDir = Split-Path $LOG_FILE -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $LOG_FILE -Value $entry
}

function Check-Ping {
    param(
        [string]$host,
        [int]$timeout = 5
    )
    try {
        if ($IsWindows) {
            $result = Test-Connection -ComputerName $host -Count 1 -TimeoutSeconds $timeout -Quiet
        } else {
            $result = Test-Connection -ComputerName $host -Count 1 -TimeoutSeconds $timeout -Quiet
        }
        return $result
    } catch {
        return $false
    }
}

function Check-SSH {
    param(
        [hashtable]$nodeConfig
    )
    $host = $nodeConfig["host"]
    $user = if ($nodeConfig.ContainsKey("user")) { $nodeConfig["user"] } else { "root" }
    
    $cmd = "ssh -o ConnectTimeout=10 -o BatchMode=yes ${user}@${host} echo 'OK'"
    
    try {
        $result = Invoke-Expression $cmd 2>$null
        return ($LASTEXITCODE -eq 0 -and $result -match "OK")
    } catch {
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
        "timestamp" = (Get-Date).ToString("o")
        "available" = $false
        "cpu" = $null
        "ram" = $null
        "disk" = $null
        "load" = $null
    }
    
    # SSH-Command für alle Metriken
    $cmd = @"
ssh -o ConnectTimeout=10 ${user}@${host} '
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
            $metrics["available"] = $true
            
            foreach ($line in $result) {
                if ($line -match ":") {
                    $parts = $line -split ":", 2
                    $key = $parts[0]
                    $value = $parts[1]
                    
                    switch ($key) {
                        "CPU" { 
                            if ([double]::TryParse($value, [ref]$null)) {
                                $metrics["cpu"] = [double]$value
                            }
                        }
                        "RAM" { 
                            if ([double]::TryParse($value, [ref]$null)) {
                                $metrics["ram"] = [double]$value
                            }
                        }
                        "DISK" { 
                            if ([int]::TryParse($value, [ref]$null)) {
                                $metrics["disk"] = [int]$value
                            }
                        }
                        "LOAD" { 
                            if ([double]::TryParse($value, [ref]$null)) {
                                $metrics["load"] = [double]$value
                            }
                        }
                        "GATEWAY" { 
                            $metrics["gateway_status"] = $value
                        }
                    }
                }
            }
        }
    } catch {
        Log-Message "Error checking $($nodeConfig['name']): $($_.Exception.Message)" "ERROR"
    }
    
    return $metrics
}

function Check-Alerts {
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
                "level" = "CRITICAL"
                "message" = "Node $($nodeConfig['name']) nicht erreichbar!"
            }
        }
    } else {
        # CPU
        if ($null -ne $metrics["cpu"] -and $metrics["cpu"] -gt 90) {
            $alerts += @{
                "level" = "WARNING"
                "message" = "Node $($nodeConfig['name']): CPU bei $($metrics['cpu'].ToString('F1'))%"
            }
        }
        
        # RAM
        if ($null -ne $metrics["ram"] -and $metrics["ram"] -gt 90) {
            $alerts += @{
                "level" = "WARNING"
                "message" = "Node $($nodeConfig['name']): RAM bei $($metrics['ram'].ToString('F1'))%"
            }
        }
        
        # Disk
        $diskThreshold = if ($nodeConfig.ContainsKey("disk_warning")) { $nodeConfig["disk_warning"] } else { 85 }
        if ($null -ne $metrics["disk"] -and $metrics["disk"] -gt $diskThreshold) {
            $level = if ($metrics["disk"] -gt 95) { "CRITICAL" } else { "WARNING" }
            $alerts += @{
                "level" = $level
                "message" = "Node $($nodeConfig['name']): Disk bei $($metrics['disk'])%"
            }
        }
        
        # Gateway
        if ($nodeConfig.ContainsKey("critical") -and $nodeConfig["critical"] -and 
            $metrics.ContainsKey("gateway_status") -and $metrics["gateway_status"] -eq "inactive") {
            $alerts += @{
                "level" = "CRITICAL"
                "message" = "Node $($nodeConfig['name']): OpenClaw Gateway nicht aktiv!"
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
        $cmd = "python3", "$WORKSPACE/skills/channel-status-agent/scripts/channel_status.py", 
               "--type", "alert", "--message", "$($alert['level']): $($alert['message'])"
        & $cmd 2>$null | Out-Null
        Log-Message "Alert sent: $($alert['message'])"
    } catch {
        Log-Message "Failed to send alert: $($_.Exception.Message)" "ERROR"
    }
}

function Main {
    param(
        [string]$node = "all",
        [string]$check = "all",
        [switch]$alert
    )
    
    # Nodes bestimmen
    if ($node -eq "all") {
        $nodesToCheck = $NODES.GetEnumerator() | Sort-Object Name
    } else {
        if ($NODES.ContainsKey($node)) {
            $nodesToCheck = @([PSCustomObject]@{Key=$node; Value=$NODES[$node]})
        } else {
            Log-Message "Unknown node: $node" "ERROR"
            exit 1
        }
    }
    
    # Health-Checks durchführen
    $allAlerts = @()
    
    foreach ($nodeEntry in $nodesToCheck) {
        $nodeId = $nodeEntry.Key
        $nodeConfig = $nodeEntry.Value
        Log-Message "Checking $($nodeConfig['name']) ($nodeId)"
        
        # Ping
        if ($check -eq "ping" -or $check -eq "all") {
            if ($nodeConfig["host"] -ne "localhost") {
                $pingOk = Check-Ping -host $nodeConfig["host"]
                Log-Message "  Ping: $(if ($pingOk) { 'OK' } else { 'FAILED' })"
            }
        }
        
        # SSH
        if ($check -eq "ssh" -or $check -eq "all") {
            $sshOk = Check-SSH -nodeConfig $nodeConfig
            Log-Message "  SSH: $(if ($sshOk) { 'OK' } else { 'FAILED' })"
        }
        
        # Metriken
        if ($check -eq "metrics" -or $check -eq "all") {
            $metrics = Get-NodeMetrics -nodeConfig $nodeConfig
            
            if ($metrics["available"]) {
                Log-Message "  CPU: $(if ($null -ne $metrics['cpu']) { "$($metrics['cpu'].ToString('F1'))%" } else { 'N/A' })"
                Log-Message "  RAM: $(if ($null -ne $metrics['ram']) { "$($metrics['ram'].ToString('F1'))%" } else { 'N/A' })"
                Log-Message "  Disk: $(if ($null -ne $metrics['disk']) { "$($metrics['disk'])%" } else { 'N/A' })"
                Log-Message "  Load: $(if ($null -ne $metrics['load']) { $metrics['load'] } else { 'N/A' })"
            } else {
                Log-Message "  Metrics: UNAVAILABLE"
            }
            
            # Alerts prüfen
            $alerts = Check-Alerts -nodeId $nodeId -nodeConfig $nodeConfig -metrics $metrics
            $allAlerts += $alerts
        }
    }
    
    # Alerts senden
    if ($alert -and $allAlerts.Count -gt 0) {
        Log-Message "`nSending $($allAlerts.Count) alerts..."
        foreach ($alertItem in $allAlerts) {
            Send-Alert -alert $alertItem
        }
    } elseif ($allAlerts.Count -gt 0) {
        Log-Message "`n$($allAlerts.Count) alerts found (use --alert to send)"
    } else {
        Log-Message "`nAll nodes healthy!"
    }
}

# Parameter parsing
$node = "all"
$check = "all"
$alert = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        "--node" { 
            if ($i + 1 -lt $args.Count) { 
                $node = $args[$i + 1]
                $i++
            }
        }
        "--check" { 
            if ($i + 1 -lt $args.Count) { 
                $check = $args[$i + 1]
                $i++
            }
        }
        "--alert" { 
            $alert = $true
        }
        "-h" { 
            Write-Host "Node Health Monitor"
            Write-Host "Usage: node_health.ps1 [--node NODE] [--check CHECK] [--alert]"
            Write-Host "  --node NODE     Node ID oder 'all' (default: all)"
            Write-Host "  --check CHECK   Check type: ping, ssh, metrics, all (default: all)"
            Write-Host "  --alert         Sende Alerts"
            exit 0
        }
    }
}

Main -node $node -check $check -alert:$alert
