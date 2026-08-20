#!/usr/bin/env pwsh
# test-contextualized-embeddings.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-contextualized-embeddings.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

if (-not $env:PERPLEXITY_API_KEY) {
    Write-Error "PERPLEXITY_API_KEY is required"
    exit 1
}

$out = Join-Path ([System.IO.Path]::GetTempPath()) "perplexity-contextualized-embeddings-test.json"

$payload = @{
    input = @(@(
        "OpenClaw can route web search through Perplexity."
        "The Perplexity MCP server exposes search and reasoning tools."
        "Contextualized embeddings improve document chunk retrieval."
    ))
    model = "pplx-embed-context-v1-4b"
} | ConvertTo-Json -Compress

try {
    $response = Invoke-WebRequest -Uri "https://api.perplexity.ai/v1/contextualizedembeddings" `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $env:PERPLEXITY_API_KEY"
            "Content-Type" = "application/json"
        } `
        -Body $payload `
        -OutFile $out `
        -PassThru
    $code = $response.StatusCode
} catch {
    if ($_.Exception.Response) {
        $code = $_.Exception.Response.StatusCode.value__
        # Save the response body even in case of error
        $_.Exception.Response.GetResponseStream() | ForEach-Object {
            $reader = New-Object System.IO.StreamReader($_)
            $reader.ReadToEnd() | Set-Content $out
        }
    } else {
        throw
    }
}

Write-Output "contextualized_embeddings_http=$code"

# Process output with custom object transformation
$json = Get-Content $out | ConvertFrom-Json
$result = [PSCustomObject]@{
    keys = $json.PSObject.Properties.Name
    model = if ($json.PSObject.Properties.Name -contains "model") { $json.model } else { $null }
    document_count = if ($json.PSObject.Properties.Name -contains "data") { @($json.data).Count } else { 0 }
    first_chunk_count = if ($json.PSObject.Properties.Name -contains "data" -and $json.data.Count -gt 0 -and $json.data[0].PSObject.Properties.Name -contains "data") { @($json.data[0].data).Count } else { 0 }
    error = if ($json.PSObject.Properties.Name -contains "error") { $json.error } else { $null }
}
$result | ConvertTo-Json
