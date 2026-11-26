#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "0bb850cf686e6b2ed62b824c923d67869d036c0b8b0bc8258aa39288ed9d29d3", "source_sha256": "748c0fc07a58caf07d4983d358cf0e1ce57c4e180b87ae617d598f53c61efcec", "target_language": "powershell"}
# dispatch_job.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

<#
Job Dispatcher - Verteilt Jobs auf passende Nodes
#>

function Get-JobWeightBytes {
    param(
        [System.IO.FileInfo]$ScriptPath,
        [int]$TargetLangsCount
    )
    <# Arbeitsvolumen: Dateigröße × Anzahl der Zielsprachen. #>
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
    <# Return mapped OpenClaw connection states; $null indicates lookup failure. #>
    try {
        $result = & openclaw nodes status --json 2>$null | Out-String
        $payload = $result | ConvertFrom-Json
        if ($null -eq $payload -or $payload.PSObject.Properties.Name -notcontains "nodes") {
            return $null
        }
        $states = @{}
        foreach ($node in $NODE_NAMES.Keys) {
            $states[$node] = $false
        }
        foreach ($item in $payload.nodes) {
            if ($null -eq $item) { continue }
            $names = @(
                if ($item.PSObject.Properties.Name -contains "displayName") { $item.displayName.ToString().ToLower() }
                if ($item.PSObject.Properties.Name -contains "nodeId") { $item.nodeId.ToString().ToLower() }
                if ($item.PSObject.Properties.Name -contains "remoteIp") { $item.remoteIp.ToString().ToLower() }
            ) | Sort-Object -Unique
            
            foreach ($node in $NODE_NAMES.Keys) {
                $aliases = $NODE_NAMES[$node]
                $matchFound = $false
                foreach ($alias in $aliases) {
                    if ($names -contains $alias.ToLower()) {
                        $matchFound = $true
                        break
                    }
                }
                if ($matchFound -and $item.connected -eq $true) {
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
    <# Dispatches jobs to appropriate nodes based on weight #>
    
    [string] GetJobWeight([System.IO.FileInfo]$scriptPath, [int]$targetLangsCount = 1) {
        <# Bewertet Job-Gewicht #>
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
        <# Wählt besten Node basierend auf Job-Gewicht #>
        $preferred = @()
        switch ($jobWeight) {
            "heavy" { $preferred = @("node1", "node2", "node5", "node6") }
            "medium" { $preferred = @("node1", "node2", "node3", "node6") }
            "light" { $preferred = @("node2", "node1", "node3", "node4") }
            default { throw "Unknown job weight: $jobWeight" }
        }

        $states = Fetch-NodeStatus
        foreach ($node_id in $preferred) {
            if ($null -ne $states -and $states.ContainsKey($node_id) -and $states[$node_id]) {
                return $node_id
            }
        }
        return $null  # no verified reachable node
    }

    [bool] CheckNodeAvailable([string]$nodeId) {
        <# Use the live connection state rather than static availability. #>
        $states = Fetch-NodeStatus
        return ($null -ne $states -and $states.ContainsKey($nodeId) -and $states[$nodeId])
    }

    [string] ExecuteTranslation([hashtable]$job, [scriptblock]$transport) {
        return Execute-Translation -Job $job -Transport $transport
    }

    [bool] CheckMobileOnline() {
        <# Check Node4 (Redmi). #>
        return $this.CheckNodeAvailable("node4")
    }

    [hashtable] Dispatch([System.IO.FileInfo]$jobScript, [array]$targetLangs = @(), [string]$sourceText = $null, [string]$sourceLanguage = $null) {
        <# Dispatched Job und gibt Info zurück #>
        if ($null -eq $targetLangs -or $targetLangs.Count -eq 0) {
            $targetLangs = @("perl5")
        }
        
        $weight = $this.GetJobWeight($jobScript, $targetLangs.Count)
        $selectedNode = $this.SelectNode($weight)
        $translationJobs = @()
        foreach ($language in $targetLangs) {
            $job = @{
                job_id = [System.Guid]::NewGuid().ToString()
                source = $jobScript.FullName
                target_language = $language
                selected_node = $selectedNode
            }
            if ($null -ne $sourceText) {
                $job.source_text = $sourceText
            }
            if ($null -ne $sourceLanguage) {
                $job.source_language = $sourceLanguage
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
    <# Execute via a supplied transport and verify its result belongs to the job. #>
    if (-not $Job.selected_node -or $null -eq $Transport) {
        throw "no verified node or authorized translation transport"
    }
    $response = & $Transport $Job
    if ($null -eq $response -or $response.GetType().Name -ne "Hashtable") {
        throw "invalid transport response"
    }
    foreach ($key in @("job_id", "selected_node", "target_language")) {
        if ($response[$key] -ne $Job[$key]) {
            throw "transport response does not match job"
        }
    }
    $code = $response.code
    if ($response.status -ne "ok" -or $null -eq $code -or $code.Trim().Length -eq 0) {
        throw "translation did not complete with code"
    }
    return $code
}

function Dispatch-AbstractionJob {
    param(
        [System.IO.FileInfo]$JobScript,
        [array]$TargetLangs
    )
    <# Erstellt eine Node-Auswahl und je (Skript, Sprache) einen Auftrag. #>
    $dispatcher = [JobDispatcher]::new()
    return $dispatcher.Dispatch($JobScript, $TargetLangs)
}

function Main {
    param(
        [string]$Job,
        [string]$Langs = "perl5",
        [ValidateSet("light", "medium", "heavy")]
        [string]$Weight,
        [switch]$Execute
    )
    
    $jobPath = Get-Item $Job -ErrorAction SilentlyContinue
    if (-not $jobPath) {
        Write-Host "❌ Job not found: $Job" -ForegroundColor Red
        exit 1
    }
    
    $dispatcher = [JobDispatcher]::new()
    $targetLangs = $Langs.Split(",")
    
    # Determine weight
    if ($PSBoundParameters.ContainsKey('Weight')) {
        $weight = $Weight
    } else {
        $weight = $dispatcher.GetJobWeight($jobPath, $targetLangs.Count)
    }
    
    # Select node
    $selectedNode = $dispatcher.SelectNode($weight)
    
    # Output
    Write-Host "📦 Job Dispatch Information"
    Write-Host ("=" * 50)
    Write-Host "Job: $($jobPath.FullName)"
    Write-Host "Size: $($jobPath.Length) bytes"
    Write-Host "Target langs: $(($targetLangs -join ', '))"
    Write-Host "Job weight: $weight"
    Write-Host "Selected node: $selectedNode"
    Write-Host ("=" * 50)
    
    if ($Execute) {
        Write-Error "Translation dispatch on $selectedNode is not implemented."
        return 1
    } else {
        Write-Host "`n💡 To execute: $($MyInvocation.MyCommand.Path) --Job '$Job' --Execute"
    }
    return 0
}

# Command line argument parsing
if ($MyInvocation.InvocationName -ne '.') {
    $params = @{}
    
    # Parse command line arguments manually since we can't use Parameter() outside functions
    for ($i = 0; $i -lt $args.Count; $i++) {
        $arg = $args[$i]
        switch ($arg) {
            {$_ -in "--job", "-j"} {
                $i++
                $params.Job = $args[$i]
            }
            {$_ -in "--langs", "-l"} {
                $i++
                $params.Langs = $args[$i]
            }
            {$_ -in "--weight", "-w"} {
                $i++
                $params.Weight = $args[$i]
            }
            {$_ -in "--execute", "-x"} {
                $params.Execute = $true
            }
        }
    }
    
    if (-not $params.ContainsKey('Job')) {
        Write-Host "Usage: $($MyInvocation.MyCommand.Name) --job JOB_FILE [--langs LANGS] [--weight WEIGHT] [--execute]"
        exit 1
    }
    
    $exitCode = Main @params
    exit $exitCode
}
