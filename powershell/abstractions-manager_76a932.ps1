#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "d4550af867dd8fb7a097de11f66b97774513d0fcc9ce38171452efcfadfce25a", "source_sha256": "76a9327ec4d8b7b9abcabfcbbbf89350cb4a3a4fdc0c949a0b343fe059dc87a8", "target_language": "powershell"}
# abstractions-manager.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

& "/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh" @args
exit $LASTEXITCODE
