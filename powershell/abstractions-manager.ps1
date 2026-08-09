#!/usr/bin/env pwsh
# abstractions-manager.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

& "$HOME/.openclaw/scripts/abstractions-manager-cron.sh" @args
