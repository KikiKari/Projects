#!/usr/bin/env pwsh
# test-embeddings.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-embeddings.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-embeddings.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-embeddings.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-embeddings.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

if (-not $env:PERPLEXITY_API_KEY) {
    Write-Error "PERPLEXITY_API_KEY is required"
    exit 1
}

$out = Join-Path ([System.IO.Path]::GetTempPath()) "perplexity-embeddings-test.json"

$payload = @{
    input = @(
        "Scientists explore the universe driven by curiosity."
        "Curiosity compels us to seek explanations, not just observations."
        "Historical discoveries began with curious questions."
        "The pursuit of knowledge distinguishes human curiosity from mere stimulus response."
        "Philosophy examines the nature of curiosity."
    )
    model = "pplx-embed-v1-4b"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "https://api.perplexity.ai/v1/embeddings" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $($env:PERPLEXITY_API_KEY)"
            "Content-Type" = "application/json"
        } `
        -Body $payload `
        -OutFile $out `
        -PassThru
    $code = $response.StatusCode
} catch {
    if ($_.Exception.Response) {
        $code = $_.Exception.Response.StatusCode.value__
        # Save error response body to file for processing
        $_.Exception.Response.GetResponseStream() | ForEach-Object {
            $reader = New-Object System.IO.StreamReader($_)
            $reader.ReadToEnd() | Set-Content $out
        }
    } else {
        Write-Error "Request failed: $($_.Exception.Message)"
        exit 1
    }
}

Write-Output "embeddings_http=$code"

# Process the JSON output
$result = Get-Content $out | ConvertFrom-Json

$output = [ordered]@{
    keys = $result.PSObject.Properties.Name
    model = if ($result.PSObject.Properties.Name -contains "model") { $result.model } else { $null }
    item_count = if ($result.PSObject.Properties.Name -contains "data") { @($result.data).Count } else { 0 }
    first_dim = if ($result.PSObject.Properties.Name -contains "data" -and $result.data.Count -gt 0 -and $result.data[0].PSObject.Properties.Name -contains "embedding") { @($result.data[0].embedding).Count } else { 0 }
    error = if ($result.PSObject.Properties.Name -contains "error") { $result.error } else { $null }
}

# Convert to JSON and output
ConvertTo-Json $output
