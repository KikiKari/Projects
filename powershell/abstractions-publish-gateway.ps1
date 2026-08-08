#!/usr/bin/env pwsh
# abstractions-publish-gateway.js — portiert nach powershell
# Quelle: javascript, Projects@abstractions:javascript/abstractions-publish-gateway.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.sh — portiert nach javascript
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.

$scriptPath = "/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh"

try {
    # Start the script with all arguments passed to this script
    $process = Start-Process -FilePath $scriptPath -ArgumentList $args -NoNewWindow -PassThru -Wait
    exit $process.ExitCode
}
catch {
    Write-Error "Failed to start script: $($_.Exception.Message)"
    exit 1
}
