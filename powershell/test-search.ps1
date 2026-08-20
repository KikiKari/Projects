#!/usr/bin/env pwsh
# test-search.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-search.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-search.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-search.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-search.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

if (-not $env:PERPLEXITY_API_KEY) {
    Write-Error "PERPLEXITY_API_KEY is required"
    exit 1
}

$query = if ($args.Count -gt 0) { $args[0] } else { "Perplexity API Platform" }
$max_results = if ($env:PERPLEXITY_MAX_RESULTS) { $env:PERPLEXITY_MAX_RESULTS } else { 3 }
$max_tokens_per_page = if ($env:PERPLEXITY_MAX_TOKENS_PER_PAGE) { $env:PERPLEXITY_MAX_TOKENS_PER_PAGE } else { 256 }

$tempDir = if ($env:TMPDIR) { $env:TMPDIR } else { "/tmp" }
$out = Join-Path $tempDir "perplexity-search-test.json"

$body = @{
    query = $query
    max_results = [int]$max_results
    max_tokens_per_page = [int]$max_tokens_per_page
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri 'https://api.perplexity.ai/search' `
        -Method POST `
        -Headers @{
            "Authorization" = "Bearer $env:PERPLEXITY_API_KEY"
            "Content-Type" = "application/json"
        } `
        -Body $body `
        -OutFile $out `
        -PassThru

    $code = $response.StatusCode
} catch {
    if ($_.Exception.Response) {
        $code = $_.Exception.Response.StatusCode.value__
    } else {
        throw
    }
}

Write-Output "search_http=$code"

$result = Get-Content $out | ConvertFrom-Json

$firstItem = $null
if ($result.results) {
    $items = $result.results
} elseif ($result.data) {
    $items = $result.data
} else {
    $items = @()
}

if ($items.Count -gt 0) {
    $firstItem = $items[0]
}

$output = @{
    keys = $result.PSObject.Properties.Name
    result_count = $items.Count
    first = $firstItem
} | ConvertTo-Json

Write-Output $output
