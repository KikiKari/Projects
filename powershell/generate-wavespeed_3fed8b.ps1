#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "48db403dffbb65fa014df68958a39e9e3bd3cf6c1be5ddaeb6789a4817cc162f", "source_sha256": "3fed8b6be2b9b8639b55bcaf18c09c0395ac005ab02c27f2dff26ca20b5d5825", "target_language": "powershell"}
# generate-wavespeed.mjs — portiert nach powershell
# Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

$key = $env:WAVESPEED_API_KEY
if (-not $key) {
    throw "WAVESPEED_API_KEY fehlt."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$jobsPath = Join-Path $scriptDir "..\media-production\wavespeed-jobs.json"
$rawDir = Join-Path $scriptDir "..\media-production\raw"
$publicDir = Join-Path $scriptDir "..\public\media"
$resultUrl = Join-Path $scriptDir "..\media-production\wavespeed-results.json"

# Create directories if they don't exist
New-Item -ItemType Directory -Path $rawDir -Force | Out-Null
New-Item -ItemType Directory -Path $publicDir -Force | Out-Null

# Load jobs and results
$jobs = Get-Content -Raw -Path $jobsPath | ConvertFrom-Json
$log = if (Test-Path $resultUrl) { Get-Content -Raw -Path $resultUrl | ConvertFrom-Json } else { @() }

foreach ($job in $jobs) {
    $rawPath = Join-Path $rawDir "$($job.id).png"
    $targetPath = Join-Path $publicDir "$($job.output).png"
    
    # Check if file already exists
    if (Test-Path $rawPath) {
        $existsInLog = $false
        foreach ($entry in $log) {
            if ($entry.id -eq $job.id) {
                $existsInLog = $true
                break
            }
        }
        
        if (-not $existsInLog) {
            $outputName = Split-Path -Leaf $targetPath
            $log += [PSCustomObject]@{
                id = $job.id
                requestId = "completed-before-resume"
                model = "google/nano-banana-2/edit"
                resolution = "4k"
                plannedCostUsd = 0.14
                output = $outputName
            }
            $log | ConvertTo-Json -Depth 10 | Set-Content -Path $resultUrl
        }
        
        Write-Host "Übersprungen: $($job.id) ist bereits vorhanden."
        continue
    }
    
    # Process images
    $images = @()
    foreach ($image in $job.images) {
        if ($image -match "^https?:|^data:") {
            $images += $image
        } else {
            $imagePath = Resolve-Path (Join-Path $scriptDir "..\$image")
            $bytes = [System.IO.File]::ReadAllBytes($imagePath)
            $base64 = [System.Convert]::ToBase64String($bytes)
            $images += "data:image/png;base64,$base64"
        }
    }
    
    # Submit job to WaveSpeed API
    $body = @{
        prompt = $job.prompt
        images = $images
        aspect_ratio = $job.aspectRatio
        resolution = "4k"
        output_format = "png"
        enable_web_search = $false
        enable_image_search = $false
        enable_sync_mode = $false
        enable_base64_output = $false
    } | ConvertTo-Json -Compress
    
    $headers = @{
        Authorization = "Bearer $key"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit" -Method Post -Headers $headers -Body $body
    } catch {
        throw "WaveSpeed submit fehlgeschlagen: $($_.Exception.Message)"
    }
    
    $requestId = if ($response.data.id) { $response.data.id } else { $response.id }
    
    # Poll for completion
    $result = $null
    for ($attempt = 0; $attempt -lt 90; $attempt++) {
        Start-Sleep -Seconds 4
        
        try {
            $pollResponse = Invoke-RestMethod -Uri "https://api.wavespeed.ai/api/v3/predictions/$requestId/result" -Headers @{Authorization = "Bearer $key"}
            $result = $pollResponse
            
            if ($result.data.status -eq "completed") {
                break
            }
            
            if ($result.data.status -eq "failed") {
                throw "WaveSpeed job fehlgeschlagen: $($job.id)"
            }
        } catch {
            throw "Fehler beim Abfragen des Status: $($_.Exception.Message)"
        }
    }
    
    # Download and save the result
    $imageUrl = $result.data.outputs[0]
    if (-not $imageUrl) {
        throw "Kein Output für $($job.id)"
    }
    
    try {
        $imageBytes = Invoke-WebRequest -Uri $imageUrl -UseBasicParsing
        [System.IO.File]::WriteAllBytes($rawPath, $imageBytes.Content)
        [System.IO.File]::WriteAllBytes($targetPath, $imageBytes.Content)
    } catch {
        throw "Fehler beim Herunterladen des Bildes: $($_.Exception.Message)"
    }
    
    # Update log
    $outputName = Split-Path -Leaf $targetPath
    $logEntry = [PSCustomObject]@{
        id = $job.id
        requestId = $requestId
        model = "google/nano-banana-2/edit"
        resolution = "4k"
        plannedCostUsd = 0.14
        output = $outputName
    }
    $log += $logEntry
    
    $log | ConvertTo-Json -Depth 10 | Set-Content -Path $resultUrl
    Write-Host "Abgeschlossen: $($job.id)"
}

# Save final log and display summary
$log | ConvertTo-Json -Depth 10 | Set-Content -Path $resultUrl
$totalAssets = $log.Count
$cost = $totalAssets * 0.14
Write-Host "WaveSpeed abgeschlossen: $totalAssets Assets, geplante Basiskosten `$$('{0:F2}' -f $cost)."
