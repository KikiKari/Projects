#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "64300a26f739c8697996eed0e09399ce0ee78452b1294ece87be46082351ed9b", "source_sha256": "0ea45de4496e55f73aa9b10188cc6a04921d74e1cadbe0ac04a948d0f2772243", "target_language": "powershell"}
# node_health.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway2:skills/node-health-monitor/scripts/node_health.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Node Health Monitor - Multi-Node Gesundheitsüberwachung
#>

# Konfiguration
$WORKSPACE = [System.IO.Path]::Combine($env:HOME, ".openclaw", "workspace")
$HEALTH_DB = [System.IO.Path]::Combine($WORKSPACE, "db", "health.db")
$LOG_FILE = [System.IO.Path]::Combine($WORKSPACE, "logs", "node-health.log")

# Node-Definitionen
$NODES = @{
    "node1" = @{
        "name" = "Node 1"
        "host" = "localhost"
        "user" = "openclaw"
        "critical" = $true
    }
    "node2" = @{
        "name" = "Node 2"
        "host" = "10.10.0.2"
        "user" = "root"
        "ssh_key" = "~/.ssh/id_rsa"
        "ssh_opts" = "-o ConnectTimeout=10 -o BatchMode=yes"
    }
    "node3" = @{
        "name" = "Node 3"
        "host" = "localhost"
        "user" = "root"
        "port" = 18794
        "ssh_opts" = "-p 18794 -o ConnectTimeout=10 -o BatchMode=yes"
        "disk_warning" = 85
    }
    "node5" = @{
        "name" = "Redmi"
        "host" = "192.168.1.x"
        "user" = "openclaw"
        "optional" = $true
    }
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    Write-Output $entry
    
    $logDir = Split-Path $LOG_FILE -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $LOG_FILE -Value $entry
}

function Test-Ping {
    param(
        [string]$Host,
        [int]$Timeout = 10
    )
    try {
        if ($IsWindows) {
            $result = Test-Connection -ComputerName $Host -Count 1 -TimeoutSeconds $Timeout -Quiet
        } else {
            $result = Test-Connection -HostName $Host -Count 1 -TimeoutSeconds $Timeout -Quiet
        }
        return $result
    } catch {
        return $false
    }
}

function Test-Ssh {
    param([hashtable]$NodeConfig)
    
    $host = $NodeConfig["host"]
    $user = if ($NodeConfig.ContainsKey("user")) { $NodeConfig["user"] } else { "root" }
    $sshOpts = if ($NodeConfig.ContainsKey("ssh_opts")) { $NodeConfig["ssh_opts"] } else { "" }
    $port = if ($NodeConfig.ContainsKey("port")) { $NodeConfig["port"] } else { $null }
    
    $cmd = @("ssh")
    if ($sshOpts) {
        $cmd += $sshOpts.Split(" ")
    }
    if ($port) {
        $cmd += @("-p", "$port")
    }
    $cmd += @("-o", "ConnectTimeout=10", "-o", "BatchMode=yes", "$user@$host", "echo", '"OK"')
    
    try {
        $result = & $cmd[0] $cmd[1..($cmd.Length-1)] 2>$null
        return ($LASTEXITCODE -eq 0 -and $result -match "OK")
    } catch {
        return $false
    }
}

function Get-NodeMetrics {
    param([hashtable]$NodeConfig)
    
    $host = $NodeConfig["host"]
    $user = if ($NodeConfig.ContainsKey("user")) { $NodeConfig["user"] } else { "root" }
    
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
            $metrics["available"] = $true
            
            foreach ($line in $result) {
                if ($line -match ":") {
                    $parts = $line.Split(":", 2)
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
        Write-Log "Error checking $($NodeConfig['name']): $_" "ERROR"
    }
    
    return $metrics
}

function Check-Alerts {
    param(
        [string]$NodeId,
        [hashtable]$NodeConfig,
        [hashtable]$Metrics
    )
    
    $alerts = @()
    
    # Verfügbarkeit
    if (-not $Metrics["available"]) {
        if (-not $NodeConfig.ContainsKey("optional") -or -not $NodeConfig["optional"]) {
            $alerts += @{
                "level" = "CRITICAL"
                "message" = "Node $($NodeConfig['name']) nicht erreichbar!"
            }
        }
    } else {
        # CPU
        if ($Metrics["cpu"] -and $Metrics["cpu"] -gt 90) {
            $alerts += @{
                "level" = "WARNING"
                "message" = "Node $($NodeConfig['name']): CPU bei $($Metrics['cpu'].ToString('F1'))%"
            }
        }
        
        # RAM
        if ($Metrics["ram"] -and $Metrics["ram"] -gt 90) {
            $alerts += @{
                "level" = "WARNING"
                "message" = "Node $($NodeConfig['name']): RAM bei $($Metrics['ram'].ToString('F1'))%"
            }
        }
        
        # Disk
        $diskThreshold = if ($NodeConfig.ContainsKey("disk_warning")) { $NodeConfig["disk_warning"] } else { 85 }
        if ($Metrics["disk"] -and $Metrics["disk"] -gt $diskThreshold) {
            $level = if ($Metrics["disk"] -gt 95) { "CRITICAL" } else { "WARNING" }
            $alerts += @{
                "level" = $level
                "message" = "Node $($NodeConfig['name']): Disk bei $($Metrics['disk'])%"
            }
        }
        
        # Gateway
        if ($NodeConfig.ContainsKey("critical") -and $NodeConfig["critical"] -and 
            $Metrics.ContainsKey("gateway_status") -and $Metrics["gateway_status"] -eq "inactive") {
            $alerts += @{
                "level" = "CRITICAL"
                "message" = "Node $($NodeConfig['name']): OpenClaw Gateway nicht aktiv!"
            }
        }
    }
    
    return $alerts
}

function Send-Alert {
    param([hashtable]$Alert)
    
    try {
        $scriptPath = [System.IO.Path]::Combine($WORKSPACE, "skills", "channel-status-agent", "scripts", "channel_status.py")
        $cmd = @("python3", $scriptPath, "--type", "alert", "--message", "$($Alert['level']): $($Alert['message'])")
        & $cmd[0] $cmd[1..($cmd.Length-1)] 2>$null
        Write-Log "Alert sent: $($Alert['message'])"
    } catch {
        Write-Log "Failed to send alert: $_" "ERROR"
    }
}

function Main {
    param(
        [string]$Node = "all",
        [string]$Check = "all",
        [switch]$Alert
    )
    
    # Nodes bestimmen
    if ($Node -eq "all") {
        $nodesToCheck = $NODES.GetEnumerator() | Sort-Object Name
    } else {
        if ($NODES.ContainsKey($Node)) {
            $nodesToCheck = @([System.Collections.DictionaryEntry]::new($Node, $NODES[$Node]))
        } else {
            Write-Log "Unknown node: $Node" "ERROR"
            exit 1
        }
    }
    
    # Health-Checks durchführen
    $allAlerts = @()
    
    foreach ($entry in $nodesToCheck) {
        $nodeId = $entry.Key
        $nodeConfig = $entry.Value
        Write-Log "Checking $($nodeConfig['name']) ($nodeId)"
        
        # Ping
        if ($Check -eq "ping" -or $Check -eq "all") {
            if ($nodeConfig["host"] -ne "localhost") {
                $pingOk = Test-Ping -Host $nodeConfig["host"]
                Write-Log "  Ping: $(if ($pingOk) { 'OK' } else { 'FAILED' })"
            }
        }
        
        # SSH
        if ($Check -eq "ssh" -or $Check -eq "all") {
            $sshOk = Test-Ssh -NodeConfig $nodeConfig
            Write-Log "  SSH: $(if ($sshOk) { 'OK' } else { 'FAILED' })"
        }
        
        # Metriken
        if ($Check -eq "metrics" -or $Check -eq "all") {
            $metrics = Get-NodeMetrics -NodeConfig $nodeConfig
            
            if ($metrics["available"]) {
                if ($metrics["cpu"] -ne $null) {
                    Write-Log "  CPU: $($metrics['cpu'].ToString('F1'))%"
                } else {
                    Write-Log "  CPU: N/A"
                }
                
                if ($metrics["ram"] -ne $null) {
                    Write-Log "  RAM: $($metrics['ram'].ToString('F1'))%"
                } else {
                    Write-Log "  RAM: N/A"
                }
                
                if ($metrics["disk"] -ne $null) {
                    Write-Log "  Disk: $($metrics['disk'])%"
                } else {
                    Write-Log "  Disk: N/A"
                }
                
                if ($metrics["load"] -ne $null) {
                    Write-Log "  Load: $($metrics['load'])"
                } else {
                    Write-Log "  Load: N/A"
                }
            } else {
                Write-Log "  Metrics: UNAVAILABLE"
            }
            
            # Alerts prüfen
            $alerts = Check-Alerts -NodeId $nodeId -NodeConfig $nodeConfig -Metrics $metrics
            $allAlerts += $alerts
        }
    }
    
    # Alerts senden
    if ($Alert -and $allAlerts.Count -gt 0) {
        Write-Log "`nSending $($allAlerts.Count) alerts..."
        foreach ($alert in $allAlerts) {
            Send-Alert -Alert $alert
        }
    } elseif ($allAlerts.Count -gt 0) {
        Write-Log "`n$($allAlerts.Count) alerts found (use --alert to send)"
    } else {
        Write-Log "`nAll nodes healthy!"
    }
}

# Parameter parsing
$nodeParam = "all"
$checkParam = "all"
$alertParam = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        "--node" {
            $i++
            if ($i -lt $args.Count) {
                $nodeParam = $args[$i]
            }
        }
        "--check" {
            $i++
            if ($i -lt $args.Count) {
                $checkParam = $args[$i]
            }
        }
        "--alert" {
            $alertParam = $true
        }
    }
}

Main -Node $nodeParam -Check $checkParam -Alert:$alertParam
