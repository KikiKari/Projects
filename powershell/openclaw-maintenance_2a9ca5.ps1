#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "0cf23c28184f437c5fc115bd17204b2f3c6634e3213ffd1e66920ab8ae97debb", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "powershell"}
# openclaw-maintenance.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# === 1. Service-/Config-Drift ===
openclaw doctor

# === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
openclaw plugins registry --refresh
openclaw plugins update --all

# === 3. Tasks ===
openclaw tasks maintenance --apply

# === 4. Sessions – alle Agents auf einmal ===
openclaw sessions cleanup --enforce --all-agents

# === 5. Memory – status/index decken alle Agents ab ===
openclaw memory status --deep --fix
openclaw memory index --force

# === 6. Memory promote – MUSS pro Agent ===
$AGENTS = @("main", "knecht", "docs", "ops-hub", "cron")
foreach ($AGENT in $AGENTS) {
  openclaw memory promote --apply --agent "$AGENT"
}

# === 7. Secrets ===
openclaw secrets reload
