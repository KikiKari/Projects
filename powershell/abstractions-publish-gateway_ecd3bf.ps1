#!/usr/bin/env pwsh
# abstractions-publish-gateway.py — portiert nach powershell
# Quelle: python, Projects@abstractions:python/abstractions-publish-gateway.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.

# Define the path to the actual script
$scriptPath = '/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh'

# Check if the script exists
if (-not (Test-Path $scriptPath)) {
    Write-Error "Error: Script not found at $scriptPath"
    exit 1
}

# Execute the script with all passed arguments
try {
    $result = & $scriptPath @args
    exit $LASTEXITCODE
} catch {
    Write-Error "Error executing script: $_"
    exit 1
}
