#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "d8491c377d87ba7d897d250f570c3a82e91d43b7033ce53a95cc9e64e728bda3", "source_sha256": "5a841c728d9c1585b5c3191e88fdd38cf887a0d51560ce803b8c0172412bef3d", "target_language": "powershell"}
# check_nodes.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
# auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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

function Check-NodeStatus($NodeId) {
    <#
    .SYNOPSIS
    Prüft Status eines einzelnen Nodes
    #>
    try {
        $result = Start-Process -FilePath "openclaw" -ArgumentList "nodes", "status", $NodeId -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\stdout.txt" -RedirectStandardError "$env:TEMP\stderr.txt"
        
        $output = Get-Content "$env:TEMP\stdout.txt" -ErrorAction SilentlyContinue
        $isOnline = ($result.ExitCode -eq 0) -and (($output -like "*online*") -or ($output -like "*active*"))
        
        return @{
            id = $NodeId
            online = $isOnline
            available = if ($NODES[$NodeId]["always_available"] -ne $null) { $NODES[$NodeId]["always_available"] } else { $false }
            response = if ($output) { $output.Substring(0, [Math]::Min(100, $output.Length)) } else { "No response" }
        }
    } catch {
        return @{
            id = $NodeId
            online = $false
            available = if ($NODES[$NodeId]["always_available"] -ne $null) { $NODES[$NodeId]["always_available"] } else { $false }
            response = "Error: $_"
        }
    }
}

function Print-Table($NodesStatus) {
    <#
    .SYNOPSIS
    Gibt Node-Status als Tabelle aus
    #>
    Write-Host ""
    Write-Host ("=" * 90)
    Write-Host $("Node".PadRight(8) + "Status".PadRight(12) + "Verfügbar".PadRight(12) + "Kapazität".PadRight(10) + "Priorität".PadRight(10) + "Gerät/Beschreibung")
    Write-Host ("=" * 90)
    
    foreach ($status in $NodesStatus) {
        $nodeId = $status.id
        $config = $NODES[$nodeId]
        
        $statusIcon = if ($status.online) { "🟢 Online" } else { "🔴 Offline" }
        $availIcon = if ($status.available) { "✅ Immer" } else { "📱 Bedingt" }
        $capacity = if ($config.capacity) { $config.capacity } else { "unknown" }
        $priority = if ($config.priority) { $config.priority } else { "-" }
        $device = if ($config.device) { $config.device } elseif ($config.description) { $config.description } else { "" }
        
        Write-Host $($nodeId.PadRight(8) + $statusIcon.PadRight(12) + $availIcon.PadRight(12) + $capacity.PadRight(10) + $priority.ToString().PadRight(10) + $device)
    }
    
    Write-Host ("=" * 90)
    Write-Host $("`nGeprüft am: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))")
}

function Print-Json($NodesStatus) {
    <#
    .SYNOPSIS
    Gibt Node-Status als JSON aus
    #>
    $output = @{
        timestamp = (Get-Date).ToString("o")
        nodes = @{}
    }
    
    foreach ($status in $NodesStatus) {
        $nodeId = $status.id
        $output.nodes[$nodeId] = @{
            status = $status
            config = $NODES[$nodeId]
        }
    }
    
    ConvertTo-Json $output -Depth 10
}

function Main {
    param(
        [string]$Format = "table",
        [string]$Save
    )
    
    Write-Host "🔍 Prüfe Node-Status..."
    
    # Prüfe alle Nodes
    $nodesStatus = @()
    $sortedKeys = ($NODES.Keys | Sort-Object)
    
    foreach ($nodeId in $sortedKeys) {
        Write-Host "  → $nodeId..." -NoNewline
        $status = Check-NodeStatus $nodeId
        $nodesStatus += $status
        Write-Host $(if ($status.online) { "✓" } else { "✗" })
    }
    
    # Ausgabe
    if ($Format -eq "table") {
        Print-Table $nodesStatus
    } else {
        Print-Json $nodesStatus
    }
    
    # Speichern
    if ($Save) {
        $output = @{
            timestamp = (Get-Date).ToString("o")
            nodes = @{}
        }
        
        foreach ($s in $nodesStatus) {
            $output.nodes[$s.id] = $s
        }
        
        $output | ConvertTo-Json -Depth 10 | Out-File $Save
        Write-Host "`n💾 Gespeichert: $Save"
    }
    
    # Zusammenfassung
    $onlineCount = ($nodesStatus | Where-Object { $_.online }).Count
    Write-Host "`n📊 Zusammenfassung: $onlineCount/$($nodesStatus.Count) Nodes online"
}

# Parameter parsing
$format = "table"
$save = $null

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = $args[$i]
    if ($arg -eq "--format" -or $arg -eq "-f") {
        $i++
        if ($i -lt $args.Count) {
            $format = $args[$i]
        }
    } elseif ($arg -eq "--save" -or $arg -eq "-s") {
        $i++
        if ($i -lt $args.Count) {
            $save = $args[$i]
        }
    } elseif ($arg -match "^--format=(.*)$" -or $arg -match "^-f(.*)$") {
        $format = $matches[1]
    } elseif ($arg -match "^--save=(.*)$" -or $arg -match "^-s(.*)$") {
        $save = $matches[1]
    }
}

Main -Format $format -Save $save
