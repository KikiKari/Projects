#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "b698932d8b3c16b98105e1d40a99ab276ff81dde68390fcddd2279efbc150e1c", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "ruby"}
# openclaw-maintenance.sh — portiert nach ruby
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# === 1. Service-/Config-Drift ===
system('openclaw', 'doctor')

# === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
system('openclaw', 'plugins', 'registry', '--refresh')
system('openclaw', 'plugins', 'update', '--all')

# === 3. Tasks ===
system('openclaw', 'tasks', 'maintenance', '--apply')

# === 4. Sessions – alle Agents auf einmal ===
system('openclaw', 'sessions', 'cleanup', '--enforce', '--all-agents')

# === 5. Memory – status/index decken alle Agents ab ===
system('openclaw', 'memory', 'status', '--deep', '--fix')
system('openclaw', 'memory', 'index', '--force')

# === 6. Memory promote – MUSS pro Agent ===
%w[main knecht docs ops-hub cron].each do |agent|
  system('openclaw', 'memory', 'promote', '--apply', '--agent', agent)
end

# === 7. Secrets ===
system('openclaw', 'secrets', 'reload')
