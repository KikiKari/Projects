#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "667507434bf0916960dd65ce79df052272ff50ec3e3822ac1338268aadae66d9", "source_sha256": "a77f5c2629fe7fafac268cfbf2f0b3e77a194322aee8f9c06967eb6c33db043e", "target_language": "powershell"}
# openclaw-maintenance.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

$OPENCLAW_BIN = if ($env:OPENCLAW_BIN) { $env:OPENCLAW_BIN } else { Join-Path $env:HOME ".local/bin/openclaw" }

if (-not (Test-Path $OPENCLAW_BIN -PathType Leaf)) {
    Write-Error "ERROR: OpenClaw binary not found: $OPENCLAW_BIN"
    exit 1
}

Write-Output "Using OpenClaw: $( & $OPENCLAW_BIN --version )"

# === 1. Service-/Config-Drift ===
& $OPENCLAW_BIN doctor

# === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
& $OPENCLAW_BIN plugins registry --refresh
if (($env:RUN_PLUGIN_UPDATE -eq "1")) {
    & $OPENCLAW_BIN plugins update --all
} else {
    Write-Output "Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable."
}

# === 3. Tasks ===
& $OPENCLAW_BIN tasks maintenance --apply

# === 4. Sessions – alle Agents auf einmal ===
& $OPENCLAW_BIN sessions cleanup --enforce --all-agents

# === 5. Memory – status/index decken alle Agents ab ===
& $OPENCLAW_BIN memory status --deep --fix
& $OPENCLAW_BIN memory index --force

# === 6. Memory promote – MUSS pro Agent ===
foreach ($AGENT in @("main", "knecht", "docs", "ops-hub", "cron")) {
    & $OPENCLAW_BIN memory promote --apply --agent $AGENT
}

# === 7. Secrets ===
& $OPENCLAW_BIN secrets reload
