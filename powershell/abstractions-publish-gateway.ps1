#!/usr/bin/env pwsh
# abstractions-publish-gateway.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.
& /home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh @args
