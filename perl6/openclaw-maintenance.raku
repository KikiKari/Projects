#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "89d118e84ecc2287501e7508f203656fa0b08ad2ba953b4a650b15d893befcbe", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "perl6"}
# openclaw-maintenance.sh — portiert nach perl6
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use v6;

# === 1. Service-/Config-Drift ===
run 'openclaw', 'doctor';

# === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
run 'openclaw', 'plugins', 'registry', '--refresh';
run 'openclaw', 'plugins', 'update', '--all';

# === 3. Tasks ===
run 'openclaw', 'tasks', 'maintenance', '--apply';

# === 4. Sessions – alle Agents auf einmal ===
run 'openclaw', 'sessions', 'cleanup', '--enforce', '--all-agents';

# === 5. Memory – status/index decken alle Agents ab ===
run 'openclaw', 'memory', 'status', '--deep', '--fix';
run 'openclaw', 'memory', 'index', '--force';

# === 6. Memory promote – MUSS pro Agent ===
for <main knecht docs ops-hub cron> -> $agent {
    run 'openclaw', 'memory', 'promote', '--apply', '--agent', $agent;
}

# === 7. Secrets ===
run 'openclaw', 'secrets', 'reload';
