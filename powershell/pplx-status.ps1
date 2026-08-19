#!/usr/bin/env pwsh
# pplx-status.sh — portiert nach powershell
# Quelle: shell, OpenClaw@main:scripts/pplx-tools/pplx-status.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Quick status of the codespace Perplexity daemon session.
$ErrorActionPreference = 'Stop'
$CFG = if ($env:PERPLEXITY_CONFIG_DIR) { $env:PERPLEXITY_CONFIG_DIR } else { Join-Path $HOME '.perplexity-mcp' }
$PROFILE = if ($env:PERPLEXITY_PROFILE) { $env:PERPLEXITY_PROFILE } else { 'codespace' }
$STAT = Join-Path $CFG 'profiles' $PROFILE 'daemon-status.json'
if (Test-Path $STAT) {
  Get-Content $STAT | ConvertFrom-Json | ConvertTo-Json -Depth 100
} else {
  Write-Output "no daemon-status.json at $STAT"
}
Write-Output "--- recent auth lines ---"
$logfile = Join-Path $CFG 'daemon.log'
if (Test-Path $logfile) {
  Select-String -Path $logfile -Pattern 'Authenticated as user|Account tier|Injected .* cookies|Reinit requested|not-logged-in' -CaseSensitive:$false | 
    ForEach-Object { $_.Line } | 
    Select-Object -Last 6
}
