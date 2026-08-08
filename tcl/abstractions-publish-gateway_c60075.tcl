#!/usr/bin/env tclsh8.6
# abstractions-publish-gateway.ps1 — portiert nach tcl
# Quelle: powershell, Projects@abstractions:powershell/abstractions-publish-gateway.ps1
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.
exec /home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh {*}$argv
