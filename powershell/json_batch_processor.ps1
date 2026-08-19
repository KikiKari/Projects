#!/usr/bin/env pwsh
# json_batch_processor.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON).
#>

param(
    [Parameter(Mandatory=$true)]
    [string[]]$Inputs,
    
    [switch]$Jsonl,
    
    [switch]$Repair = $true,
    
    [int]$Workers = 4,
    
    [string]$Output,
    
    [switch]$Summary
)

# Globale Variablen
$HAS_PYDANTIC = $false
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$jsonProcessorPath = Join-Path $scriptDir "json_processor.ps1"

# Importiere json_processor.ps1 falls vorhanden
if (Test-Path $jsonProcessorPath) {
    . $jsonProcessorPath
} else {
    Write-Error "json_processor.ps1 nicht gefunden!"
    exit 1
}

class BatchResult {
    [int]$Index
    [string]$Source
    [bool]$Success
    [object]$Data
    [string]$Error
    
    BatchResult([int]$index, [string]$source, [bool]$success, [object]$data, [string]$error) {
        $this.Index = $index
        $this.Source = $source
        $this.Success = $success
        $this.Data = $data
        $this.Error = $error
    }
    
    [hashtable]ToDict() {
        return @{
            index = $this.Index
            source = $this.Source
            success = $this.Success
            data = $this.Data
            error = $this.Error
        }
    }
}

function Read-Jsonl {
    param(
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$FilePath
    )
    
    <#
    .SYNOPSIS
    Liest JSON-Lines (NDJSON) Datei Zeile für Zeile.
    #>
    
    $lineNum = 0
    foreach ($line in Get-Content $FilePath.FullName) {
        $lineNum++
        $line = $line.Trim()
        if (-not $line) { continue }
        
        try {
            $obj = $line | ConvertFrom-Json
            $obj
        } catch {
            [BatchResult]::new($lineNum, "$($FilePath.Name):$lineNum", $false, $null, "JSON decode error: $($_.Exception.Message)")
        }
    }
}

function Process-Batch {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Inputs,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$Processor,
        
        [int]$MaxWorkers = 4
    )
    
    <#
    .SYNOPSIS
    Verarbeitet eine Liste von Inputs parallel.
    #>
    
    $results = @()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxWorkers)
    $runspacePool.Open()
    $jobs = @()
    
    for ($i = 0; $i -lt $Inputs.Count; $i++) {
        $inp = $Inputs[$i]
        $idx = $i
        
        $ps = [PowerShell]::Create()
        $ps.RunspacePool = $runspacePool
        $null = $ps.AddScript($Processor.ToString())
        $null = $ps.AddParameter('InputObject', $inp)
        $null = $ps.AddParameter('Index', $idx)
        
        $job = @{
            Instance = $ps
            Result = $ps.BeginInvoke()
        }
        $jobs += $job
    }
    
    foreach ($job in $jobs) {
        try {
            $result = $job.Instance.EndInvoke($job.Result)
            $results += $result
        } catch {
            $idx = $jobs.IndexOf($job)
            $results += [BatchResult]::new($idx, "$($Inputs[$idx])", $false, $null, "Unexpected error: $($_.Exception.Message)")
        }
    }
    
    $runspacePool.Close()
    $runspacePool.Dispose()
    
    # Sortiere nach Index
    $results = $results | Sort-Object { $_.Index }
    return $results
}

function Process-FileBatch {
    param(
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo[]]$FilePaths,
        
        [bool]$Repair = $true,
        
        [type]$ValidateModel = $null,
        
        [int]$MaxWorkers = 4
    )
    
    <#
    .SYNOPSIS
    Verarbeitet mehrere JSON-Dateien im Batch.
    #>
    
    $processorScript = {
        param($path, $idx)
        
        try {
            $content = [System.IO.File]::ReadAllText($path.FullName, [System.Text.Encoding]::UTF8)
            
            if ($ValidateModel -and $HAS_PYDANTIC) {
                $data = ParseAndValidate -Content $content -Model $ValidateModel -Repair $Repair
            } else {
                $data = ParseJson -Content $content -Repair $Repair
            }
            
            return [BatchResult]::new($idx, $path.FullName, $true, $data, $null)
        } catch [JSONProcessingError] {
            return [BatchResult]::new($idx, $path.FullName, $false, $null, $_.Exception.Message)
        } catch {
            return [BatchResult]::new($idx, $path.FullName, $false, $null, "$($_.Exception.GetType().Name): $($_.Exception.Message)")
        }
    }
    
    $results = Process-Batch -Inputs $FilePaths -Processor $processorScript -MaxWorkers $MaxWorkers
    return $results
}

function Process-JsonlFile {
    param(
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$FilePath,
        
        [bool]$Repair = $true,
        
        [type]$ValidateModel = $null
    )
    
    <#
    .SYNOPSIS
    Verarbeitet eine JSON-Lines Datei.
    #>
    
    $results = @()
    $lineNum = 0
    
    foreach ($line in Get-Content $FilePath.FullName) {
        $lineNum++
        $line = $line.Trim()
        if (-not $line) { continue }
        
        try {
            if ($ValidateModel -and $HAS_PYDANTIC) {
                $data = ParseAndValidate -Content $line -Model $ValidateModel -Repair $Repair
            } else {
                $data = ParseJson -Content $line -Repair $Repair
            }
            
            $results += [BatchResult]::new($lineNum, "$($FilePath.Name):$lineNum", $true, $data, $null)
        } catch [JSONProcessingError] {
            $results += [BatchResult]::new($lineNum, "$($FilePath.Name):$lineNum", $false, $null, $_.Exception.Message)
        }
    }
    
    return $results
}

function Write-Jsonl {
    param(
        [Parameter(Mandatory=$true)]
        [BatchResult[]]$Results,
        
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$OutputPath,
        
        [bool]$OnlySuccessful = $true
    )
    
    <#
    .SYNOPSIS
    Schreibt BatchResult-Liste als JSON-Lines.
    #>
    
    $streamWriter = New-Object System.IO.StreamWriter($OutputPath.FullName, $false, [System.Text.Encoding]::UTF8)
    
    try {
        foreach ($result in $Results) {
            if ($OnlySuccessful -and -not $result.Success) {
                continue
            }
            $json = $result.ToDict() | ConvertTo-Json -Compress
            $streamWriter.WriteLine($json)
        }
    } finally {
        $streamWriter.Close()
    }
}

function Main {
    $allResults = @()
    
    if ($Jsonl) {
        # JSON-Lines Modus
        foreach ($inputPath in $Inputs) {
            $results = Process-JsonlFile -FilePath (Get-Item $inputPath) -Repair $Repair
            $allResults += $results
        }
    } else {
        # Standard JSON Batch
        $filePaths = $Inputs | ForEach-Object { Get-Item $_ }
        $allResults = Process-FileBatch -FilePaths $filePaths -Repair $Repair -MaxWorkers $Workers
    }
    
    # Ausgabe
    $successful = ($allResults | Where-Object { $_.Success }).Count
    $failed = $allResults.Count - $successful
    
    if ($Summary) {
        Write-Host "Processed: $($allResults.Count)"
        Write-Host "Successful: $successful"
        Write-Host "Failed: $failed"
    } else {
        foreach ($result in $allResults) {
            if ($result.Success) {
                $result.Data | ConvertTo-Json -Depth 10
            } else {
                Write-Error "ERROR [$($result.Source)]: $($result.Error)"
            }
        }
    }
    
    # Optional: JSONL Output
    if ($Output) {
        Write-Jsonl -Results $allResults -OutputPath (Get-Item $Output) -OnlySuccessful $false
        Write-Warning "`nResults written to: $Output"
    }
    
    # Exit code
    if ($failed -gt 0) {
        exit 1
    } else {
        exit 0
    }
}

Main
