#!/usr/bin/env pwsh
# test-agent.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-agent.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-agent.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-agent.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-agent.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

if (-not $env:PERPLEXITY_API_KEY) {
    Write-Error "PERPLEXITY_API_KEY is required"
    exit 1
}

$prompt = if ($args.Count -gt 0) { $args[0] } else { "Compare recent open-source LLMs in terms of performance, licensing, and practical use." }
$tmpdir = if ($env:TMPDIR) { $env:TMPDIR } else { "/tmp" }
$out = Join-Path $tmpdir "perplexity-agent-test.json"

$body = @{
    preset = "fast-search"
    input = $prompt
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "https://api.perplexity.ai/v1/agent" `
        -Method Post `
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
        Write-Error "Request failed: $($_.Exception.Message)"
        exit 1
    }
}

Write-Output "agent_http=$code"

$resp = Get-Content $out | ConvertFrom-Json
$output = @{
    keys = ($resp | Get-Member -MemberType NoteProperty).Name
    id = if ($resp.id) { $resp.id } else { $null }
    status = if ($resp.status) { $resp.status } else { $null }
    output_count = if ($resp.output) { ($resp.output | Measure-Object).Count } else { 0 }
    error = if ($resp.error) { $resp.error } else { $null }
}
$output | ConvertTo-Json
