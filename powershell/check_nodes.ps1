#!/usr/bin/env pwsh
# check_nodes.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
# auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Node-Status Checker - Prüft Verfügbarkeit aller Nodes
#>

# Node-Konfiguration (sollte aus config file geladen werden)
$NODES = @{
    "node1" = @{
        "always_available" = $true
        "capacity" = "medium"
        "priority" = 2
        "description" = "Gateway-Master"
    }
    "node2" = @{
        "always_available" = $true
        "capacity" = "medium"
        "priority" = 3
        "description" = "Stable Worker"
    }
    "node3" = @{
        "always_available" = $false
        "capacity" = "medium"
        "priority" = 4
        "description" = "Bald verfügbar (nach Reorganisation)"
    }
    "node5" = @{
        "always_available" = $false
        "capacity" = "low"
        "priority" = 5
        "device" = "Redmi Note 11S"
        "description" = "Mobile (bei Internet verfügbar)"
    }
    "node7" = @{
        "always_available" = $true
        "capacity" = "high"
        "priority" = 1
        "description" = "Docker Hauptarbeitspferd (bald verfügbar)"
    }
}

function Check-NodeStatus {
    param(
        [string]$NodeId
    )
    
    try {
        $result = Start-Process -FilePath "openclaw" -ArgumentList "nodes", "status", $NodeId -NoNewWindow -PassThru -Wait -RedirectStandardOutput "$env:TEMP\stdout.txt" -RedirectStandardError "$env:TEMP\stderr.txt"
        $stdout = Get-Content "$env:TEMP\stdout.txt" -ErrorAction SilentlyContinue
        $stderr = Get-Content "$env:TEMP\stderr.txt" -ErrorAction SilentlyContinue
        
        $isOnline = $result.ExitCode -eq 0 -and (
            ($stdout -join "`n").ToLower().Contains("online") -or 
            ($stdout -join "`n").ToLower().Contains("active")
        )
        
        return @{
            "id" = $NodeId
            "online" = $isOnline
            "available" = if ($NODES[$NodeId]["always_available"] -ne $null) { $NODES[$NodeId]["always_available"] } else { $false }
            "response" = if ($stdout) { ($stdout -join "`n").Substring(0, [Math]::Min(100, ($stdout -join "`n").Length)) } else { "No response" }
        }
    } catch {
        return @{
            "id" = $NodeId
            "online" = $false
            "available" = if ($NODES[$NodeId]["always_available"] -ne $null) { $NODES[$NodeId]["always_available"] } else { $false }
            "response" = "Error: $($_.Exception.Message)"
        }
    }
}

function Print-Table {
    param(
        [array]$NodesStatus
    )
    
    Write-Host ""
    Write-Host ("=" * 90)
    Write-Host ("{0,-8} {1,-12} {2,-12} {3,-10} {4,-10} {5}" -f "Node", "Status", "Verfügbar", "Kapazität", "Priorität", "Gerät/Beschreibung")
    Write-Host ("=" * 90)
    
    foreach ($status in $NodesStatus) {
        $nodeId = $status["id"]
        $config = $NODES[$nodeId]
        
        $statusIcon = if ($status["online"]) { "🟢 Online" } else { "🔴 Offline" }
        $availIcon = if ($status["available"]) { "✅ Immer" } else { "📱 Bedingt" }
        $capacity = if ($config["capacity"]) { $config["capacity"] } else { "unknown" }
        $priority = if ($config["priority"]) { $config["priority"] } else { "-" }
        $device = if ($config["device"]) { $config["device"] } elseif ($config["description"]) { $config["description"] } else { "" }
        
        Write-Host ("{0,-8} {1,-12} {2,-12} {3,-10} {4,-10} {5}" -f $nodeId, $statusIcon, $availIcon, $capacity, $priority, $device)
    }
    
    Write-Host ("=" * 90)
    Write-Host ""
    Write-Host ("Geprüft am: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
}

function Print-Json {
    param(
        [array]$NodesStatus
    )
    
    $output = @{
        "timestamp" = (Get-Date).ToString("o")
        "nodes" = @{}
    }
    
    foreach ($status in $NodesStatus) {
        $nodeId = $status["id"]
        $output["nodes"][$nodeId] = @{
            "status" = $status
            "config" = $NODES[$nodeId]
        }
    }
    
    $output | ConvertTo-Json -Depth 3
}

function Main {
    param(
        [string]$Format = "table",
        [string]$Save
    )
    
    Write-Host "🔍 Prüfe Node-Status..."
    
    # Prüfe alle Nodes
    $nodesStatus = @()
    $sortedNodeIds = $NODES.Keys | Sort-Object
    
    foreach ($nodeId in $sortedNodeIds) {
        Write-Host "  → $nodeId..." -NoNewline
        $status = Check-NodeStatus -NodeId $nodeId
        $nodesStatus += $status
        if ($status["online"]) {
            Write-Host " ✓"
        } else {
            Write-Host " ✗"
        }
    }
    
    # Ausgabe
    if ($Format -eq "table") {
        Print-Table -NodesStatus $nodesStatus
    } else {
        Print-Json -NodesStatus $nodesStatus
    }
    
    # Speichern
    if ($Save) {
        $output = @{
            "timestamp" = (Get-Date).ToString("o")
            "nodes" = @{}
        }
        
        foreach ($s in $nodesStatus) {
            $output["nodes"][$s["id"]] = $s
        }
        
        $output | ConvertTo-Json -Depth 3 | Out-File -FilePath $Save -Encoding UTF8
        Write-Host ""
        Write-Host ("💾 Gespeichert: $Save")
    }
    
    # Zusammenfassung
    $onlineCount = ($nodesStatus | Where-Object { $_["online"] }).Count
    Write-Host ""
    Write-Host ("📊 Zusammenfassung: $onlineCount/{0} Nodes online" -f $nodesStatus.Count)
}

# Parameter parsing
$format = "table"
$save = $null

for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        { $_ -in "--format", "-f" } {
            $i++
            if ($i -lt $args.Count) {
                $format = $args[$i]
            }
        }
        { $_ -in "--save", "-s" } {
            $i++
            if ($i -lt $args.Count) {
                $save = $args[$i]
            }
        }
    }
}

Main -Format $format -Save $save
