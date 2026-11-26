#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "7eb8584d40c58d49b0f8bc790c1d47146eb4f7ef831cd2aaee17d70a8d470c7d", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "tcl"}
# openclaw-maintenance.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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
