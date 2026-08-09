#!/usr/bin/env tclsh
# openclaw-maintenance.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# === 1. Service-/Config-Drift ===
exec openclaw doctor

# === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
exec openclaw plugins registry --refresh
exec openclaw plugins update --all

# === 3. Tasks ===
exec openclaw tasks maintenance --apply

# === 4. Sessions – alle Agents auf einmal ===
exec openclaw sessions cleanup --enforce --all-agents

# === 5. Memory – status/index decken alle Agents ab ===
exec openclaw memory status --deep --fix
exec openclaw memory index --force

# === 6. Memory promote – MUSS pro Agent ===
foreach AGENT {main knecht docs ops-hub cron} {
  exec openclaw memory promote --apply --agent $AGENT
}

# === 7. Secrets ===
exec openclaw secrets reload
