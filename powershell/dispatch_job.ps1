#!/usr/bin/env pwsh
# dispatch_job.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-11-17 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Job Dispatcher - Verteilt Jobs auf passende Nodes
#>

# Node-Konfiguration
$NODES = @{
    "node1" = @{ always_available = $true; capacity = "medium"; priority = 2 }
    "node2" = @{ always_available = $true; capacity = "medium"; priority = 3 }
    "node3" = @{ always_available = $false; capacity = "medium"; priority = 4 }
    "node5" = @{ always_available = $false; capacity = "low"; priority = 5; device = "Redmi Note 11S" }
    "node7" = @{ always_available = $true; capacity = "high"; priority = 1 }
}

class JobDispatcher {
    <#
    .SYNOPSIS
    Bewertet Job-Gewicht
    #>
    [string] GetJobWeight([System.IO.FileInfo]$scriptPath, [int]$targetLangsCount = 1) {
        if (-not (Test-Path $scriptPath)) {
            return "medium"
        }
        
        $scriptSize = (Get-Item $scriptPath).Length
        $totalWork = $scriptSize * $targetLangsCount
        
        if ($totalWork -gt 50000) {  # > 50KB
            return "heavy"
        } elseif ($totalWork -gt 10000) {  # > 10KB
            return "medium"
        } else {
            return "light"
        }
    }
    
    <#
    .SYNOPSIS
    Wählt besten Node basierend auf Job-Gewicht
    #>
    [string] SelectNode([string]$jobWeight) {
        [string[]]$preferred = @()
        
        if ($jobWeight -eq "heavy") {
            # Schwere Jobs → Node 7 (Docker), dann Node 2, dann Node 1
            $preferred = @("node7", "node2", "node1")
        } elseif ($jobWeight -eq "medium") {
            # Mittlere Jobs → Stable Nodes
            $preferred = @("node2", "node1", "node7")
        } else {  # light
            # Leichte Jobs → Mobile/verfügbare Nodes
            $preferred = @("node5", "node1", "node2")
        }
        
        # Prüfe Verfügbarkeit
        foreach ($nodeId in $preferred) {
            if ($this.CheckNodeAvailable($nodeId)) {
                return $nodeId
            }
        }
        
        # Fallback
        return "node1"
    }
    
    <#
    .SYNOPSIS
    Prüft ob Node erreichbar ist
    #>
    [bool] CheckNodeAvailable([string]$nodeId) {
        if (-not $script:NODES.ContainsKey($nodeId)) {
            return $false
        }
        
        $node = $script:NODES[$nodeId]
        
        # Nicht immer-verfügbare Nodes nur wenn explizit requested
        if (-not $node.always_available) {
            # Für light-jobs prüfen wir ob online
            if ($nodeId -eq "node5") {  # Redmi
                return $this.CheckMobileOnline()
            }
            return $false
        }
        
        # Für immer-verfügbare Nodes: prüfe ob wirklich online
        try {
            $result = Start-Process -FilePath "openclaw" -ArgumentList "nodes", "status", $nodeId -NoNewWindow -PassThru -Wait -RedirectStandardOutput $null -RedirectStandardError $null
            return $result.ExitCode -eq 0
        } catch {
            return $node.always_available
        }
    }
    
    <#
    .SYNOPSIS
    Prüft ob Redmi (Node 5) Internet hat
    #>
    [bool] CheckMobileOnline() {
        try {
            $output = & openclaw nodes status node5 2>$null
            $result = Start-Process -FilePath "openclaw" -ArgumentList "nodes", "status", "node5" -NoNewWindow -PassThru -Wait -RedirectStandardOutput $null -RedirectStandardError $null
            return ($result.ExitCode -eq 0) -and ($output -like "*online*")
        } catch {
            return $false
        }
    }
    
    <#
    .SYNOPSIS
    Dispatched Job und gibt Info zurück
    #>
    [hashtable] Dispatch([System.IO.FileInfo]$jobScript, [string[]]$targetLangs = @("perl5")) {
        $weight = $this.GetJobWeight($jobScript, $targetLangs.Count)
        $selectedNode = $this.SelectNode($weight)
        
        return @{
            job = $jobScript.FullName
            weight = $weight
            selected_node = $selectedNode
            target_langs = $targetLangs
            status = "dispatched"
        }
    }
}

function Main {
    param()
    
    # Parameter parsing
    $jobPath = ""
    $langs = "perl5"
    $weight = ""
    $execute = $false
    
    # Simple argument parsing since PowerShell doesn't have argparse equivalent built-in
    for ($i = 0; $i -lt $args.Count; $i++) {
        switch ($args[$i]) {
            {($_ -eq "--job") -or ($_ -eq "-j")} {
                $i++
                if ($i -lt $args.Count) { $jobPath = $args[$i] }
            }
            {($_ -eq "--langs") -or ($_ -eq "-l")} {
                $i++
                if ($i -lt $args.Count) { $langs = $args[$i] }
            }
            {($_ -eq "--weight") -or ($_ -eq "-w")} {
                $i++
                if ($i -lt $args.Count) { $weight = $args[$i] }
            }
            {($_ -eq "--execute") -or ($_ -eq "-x")} {
                $execute = $true
            }
        }
    }
    
    if ([string]::IsNullOrEmpty($jobPath)) {
        Write-Host "❌ Job path is required"
        exit 1
    }
    
    $jobPathInfo = Get-Item $jobPath -ErrorAction SilentlyContinue
    if (-not $jobPathInfo) {
        Write-Host "❌ Job not found: $jobPath"
        exit 1
    }
    
    $dispatcher = [JobDispatcher]::new()
    $targetLangsArray = $langs.Split(",")
    
    # Determine weight
    if ([string]::IsNullOrEmpty($weight)) {
        $weight = $dispatcher.GetJobWeight($jobPathInfo, $targetLangsArray.Count)
    }
    
    # Select node
    $selectedNode = $dispatcher.SelectNode($weight)
    
    # Output
    Write-Host "📦 Job Dispatch Information"
    Write-Host ("=" * 50)
    Write-Host "Job: $($jobPathInfo.FullName)"
    Write-Host "Size: $($jobPathInfo.Length) bytes"
    Write-Host "Target langs: $($targetLangsArray -join ', ')"
    Write-Host "Job weight: $weight"
    Write-Host "Selected node: $selectedNode"
    Write-Host ("=" * 50)
    
    if ($execute) {
        Write-Host "`n🚀 Executing on $selectedNode..."
        # TODO: Implement remote execution
        Write-Host "(Remote execution not yet implemented)"
    } else {
        Write-Host "`n💡 To execute: $($MyInvocation.MyCommand.Path) --job $jobPath --execute"
    }
}

Main @args
