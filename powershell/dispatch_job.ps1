#!/usr/bin/env pwsh
# dispatch_job.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Job Dispatcher - Verteilt Jobs auf passende Nodes
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Job,
    
    [string]$Langs = "perl5",
    
    [ValidateSet("light", "medium", "heavy")]
    [string]$Weight,
    
    [switch]$Execute
)

function Get-JobWeightBytes {
    param(
        [System.IO.FileInfo]$ScriptPath,
        [int]$TargetLangsCount
    )
    <#
    .SYNOPSIS
    Arbeitsvolumen: Dateigröße × Anzahl der Zielsprachen.
    #>
    return $ScriptPath.Length * $TargetLangsCount
}

# Node-Konfiguration
$NODES = @{
    "node1" = @{always_available = $true; capacity = "medium"; priority = 3; description = "Gateway"}
    "node2" = @{always_available = $false; capacity = "high"; priority = 1; description = "ARM Server"}
    "node3" = @{always_available = $false; capacity = "medium"; priority = 4; description = "AMD Server"}
    "node4" = @{always_available = $false; capacity = "low"; priority = 5; device = "Redmi Note 11S"}
    "node5" = @{always_available = $false; capacity = "high"; priority = 2; device = "Lenovo"}
    "node6" = @{always_available = $false; device = "Lenovo (Docker)"}
}

$NODE_NAMES = @{
    "node2" = @("openclaw-node2", "arm64-node", "v2202604104722449961", "v2202604104722449961.taild25fea.ts.net", "100.82.198.122")
    "node3" = @("openclaw-node3", "openclaw-node3.taild25fea.ts.net", "100.73.154.125")
    "node4" = @("openclaw-node4", "redmi-note-11s", "redmi-note-11s.taild25fea.ts.net", "100.94.134.39")
    "node5" = @("openclaw-node5", "windows node (lenovo-7)")
    "node6" = @("openclaw-node6")
}

function Fetch-NodeStatus {
    <#
    .SYNOPSIS
    Return mapped OpenClaw connection states; $null indicates lookup failure.
    #>
    try {
        $result = & openclaw nodes status --json
        $payload = $result | ConvertFrom-Json
        if ($null -eq $payload -or $payload.nodes -isnot [array]) {
            return $null
        }
        $states = @{}
        foreach ($node in $NODE_NAMES.Keys) {
            $states[$node] = $false
        }
        foreach ($item in $payload.nodes) {
            if ($item -isnot [PSCustomObject]) {
                continue
            }
            $names = @($item.displayName, $item.nodeId, $item.remoteIp) | ForEach-Object { ($_ -split '\s+')[0].ToLower() }
            foreach ($node in $NODE_NAMES.Keys) {
                $aliases = $NODE_NAMES[$node]
                $found = $false
                foreach ($alias in $aliases) {
                    if ($names -contains $alias.ToLower()) {
                        $found = $true
                        break
                    }
                }
                if ($found -and $item.connected -eq $true) {
                    $states[$node] = $true
                }
            }
        }
        $states["node1"] = $true  # successful Gateway status request
        return $states
    } catch {
        return $null
    }
}

class JobDispatcher {
    <#
    .SYNOPSIS
    Dispatches jobs to appropriate nodes based on weight
    #>
    
    [string] GetJobWeight([System.IO.FileInfo]$scriptPath, [int]$targetLangsCount = 1) {
        <#
        .SYNOPSIS
        Bewertet Job-Gewicht
        #>
        if (-not (Test-Path $scriptPath)) {
            return "medium"
        }
        
        $totalWork = Get-JobWeightBytes -ScriptPath $scriptPath -TargetLangsCount $targetLangsCount
        
        if ($totalWork -gt 50000) {  # > 50KB
            return "heavy"
        } elseif ($totalWork -gt 10000) {  # > 10KB
            return "medium"
        } else {
            return "light"
        }
    }
    
    [string] SelectNode([string]$jobWeight) {
        <#
        .SYNOPSIS
        Wählt besten Node basierend auf Job-Gewicht
        #>
        $preferred = @()
        switch ($jobWeight) {
            "heavy" { $preferred = @("node1", "node2", "node5", "node6") }
            "medium" { $preferred = @("node1", "node2", "node3", "node6") }
            "light" { $preferred = @("node2", "node1", "node3", "node4") }
            Default { throw "Unknown job weight: $jobWeight" }
        }

        $states = Fetch-NodeStatus
        foreach ($node_id in $preferred) {
            if ($null -ne $states -and $states[$node_id] -eq $true) {
                return $node_id
            }
        }
        return $null  # no verified reachable node
    }

    [bool] CheckNodeAvailable([string]$node_id) {
        <#
        .SYNOPSIS
        Use the live connection state rather than static availability.
        #>
        $states = Fetch-NodeStatus
        return ($null -ne $states -and $states[$node_id] -eq $true)
    }

    [string] ExecuteTranslation([hashtable]$job, [scriptblock]$transport) {
        return Execute-Translation -Job $job -Transport $transport
    }

    [bool] CheckMobileOnline() {
        <#
        .SYNOPSIS
        Check Node4 (Redmi).
        #>
        return $this.CheckNodeAvailable("node4")
    }

    [hashtable] Dispatch([System.IO.FileInfo]$jobScript, [string[]]$targetLangs, [string]$sourceText, [string]$sourceLanguage) {
        <#
        .SYNOPSIS
        Dispatched Job und gibt Info zurück
        #>
        if ($null -eq $targetLangs) {
            $targetLangs = @("perl5")
        }
        
        $weight = $this.GetJobWeight($jobScript, $targetLangs.Count)
        $selectedNode = $this.SelectNode($weight)
        $translationJobs = @()
        
        foreach ($language in $targetLangs) {
            $job = @{
                job_id = [guid]::NewGuid().ToString()
                source = $jobScript.FullName
                target_language = $language
                selected_node = $selectedNode
            }
            
            if ($null -ne $sourceText) {
                $job["source_text"] = $sourceText
            }
            if ($null -ne $sourceLanguage) {
                $job["source_language"] = $sourceLanguage
            }
            $translationJobs += $job
        }
        
        return @{
            job = $jobScript.FullName
            weight = $weight
            selected_node = $selectedNode
            target_langs = $targetLangs
            translation_jobs = $translationJobs
            status = if ($selectedNode) { "selected" } else { "unavailable" }
        }
    }
}

function Execute-Translation {
    param(
        [hashtable]$Job,
        [scriptblock]$Transport
    )
    <#
    .SYNOPSIS
    Execute via a supplied transport and verify its result belongs to the job.
    #>
    if (-not $Job.selected_node -or $null -eq $Transport) {
        throw "no verified node or authorized translation transport"
    }
    $response = & $Transport $Job
    if ($response -isnot [hashtable] -and $response -isnot [PSCustomObject]) {
        throw "invalid transport response"
    }
    
    foreach ($key in @("job_id", "selected_node", "target_language")) {
        if ($response.$key -ne $Job.$key) {
            throw "transport response does not match job"
        }
    }
    
    $code = $response.code
    if ($response.status -ne "ok" -or $null -eq $code -or $code.Trim() -eq "") {
        throw "translation did not complete with code"
    }
    return $code
}

function Dispatch-AbstractionJob {
    param(
        [System.IO.FileInfo]$JobScript,
        [string[]]$TargetLangs
    )
    <#
    .SYNOPSIS
    Erstellt eine Node-Auswahl und je (Skript, Sprache) einen Auftrag.
    #>
    $dispatcher = [JobDispatcher]::new()
    return $dispatcher.Dispatch($JobScript, $TargetLangs, $null, $null)
}

# Main execution
try {
    $jobPath = Get-Item $Job
    if (-not (Test-Path $jobPath)) {
        Write-Host "❌ Job not found: $jobPath" -ForegroundColor Red
        exit 1
    }
    
    $dispatcher = [JobDispatcher]::new()
    $targetLangs = $Langs.Split(",")
    
    # Determine weight
    if ($Weight) {
        $weight = $Weight
    } else {
        $weight = $dispatcher.GetJobWeight($jobPath, $targetLangs.Count)
    }
    
    # Select node
    $selectedNode = $dispatcher.SelectNode($weight)
    
    # Output
    Write-Host "📦 Job Dispatch Information" -ForegroundColor Yellow
    Write-Host ("=" * 50)
    Write-Host "Job: $($jobPath.FullName)"
    Write-Host "Size: $($jobPath.Length) bytes"
    Write-Host "Target langs: $($targetLangs -join ', ')"
    Write-Host "Job weight: $weight"
    Write-Host "Selected node: $selectedNode"
    Write-Host ("=" * 50)
    
    if ($Execute) {
        Write-Error "Translation dispatch on $selectedNode is not implemented."
        exit 1
    } else {
        Write-Host "`n💡 To execute: $($MyInvocation.MyCommand.Name) --job $Job --execute" -ForegroundColor Green
    }
    exit 0
} catch {
    Write-Error $_.Exception.Message
    exit 1
}
