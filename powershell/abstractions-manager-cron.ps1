#!/usr/bin/env pwsh
# abstractions-manager-cron.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

$env:PATH = "/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin"

# Load environment variables from file
Get-Content /home/openclaw/.openclaw/.env | ForEach-Object {
    if ($_ -match '^(.*)=(.*)$') {
        $envName = $matches[1]
        $envValue = $matches[2] -replace '^"(.*)"$', '$1'  # Remove surrounding quotes if present
        Set-Item "env:$envName" $envValue
    }
}

# Check if OPENROUTER_API_KEY is set
if (-not $env:OPENROUTER_API_KEY) {
    Write-Error "OPENROUTER_API_KEY fehlt"
    exit 1
}

# Set GITHUB_TOKEN with fallback values
if (-not $env:GITHUB_TOKEN) {
    $env:GITHUB_TOKEN = $env:GH_TOKEN ?? $env:GH_ACCESS_TOKEN ?? ""
}

# Create lock directory if it doesn't exist
$lockDir = Split-Path "/home/openclaw/.openclaw/locks/abstractions-manager.lock" -Parent
if (-not (Test-Path $lockDir)) {
    New-Item -ItemType Directory -Path $lockDir | Out-Null
}

# Try to acquire lock and execute command
try {
    $lockFile = [System.IO.File]::Open("/home/openclaw/.openclaw/locks/abstractions-manager.lock", "OpenOrCreate", "ReadWrite")
    
    try {
        $lockFile.Lock(0, 1)
        
        # Execute the Python script with all arguments passed to this script
        & /usr/bin/python3 /home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py @args
        
        # Exit with the exit code of the Python script
        exit $LASTEXITCODE
    }
    finally {
        $lockFile.Unlock()
        $lockFile.Close()
    }
}
catch [System.IO.IOException] {
    # Lock file is already locked by another process
    exit 0
}
