#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "65dc31c699762310a21afbafafee54673adf79f301675fa9ae976819717ce2d8", "source_sha256": "a77f5c2629fe7fafac268cfbf2f0b3e77a194322aee8f9c06967eb6c33db043e", "target_language": "ruby"}
# openclaw-maintenance.sh — portiert nach ruby
# Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'open3'

OPENCLAW_BIN = ENV.fetch('OPENCLAW_BIN') { File.join(ENV['HOME'], '.local', 'bin', 'openclaw') }

unless File.executable?(OPENCLAW_BIN)
  STDERR.puts "ERROR: OpenClaw binary not found: #{OPENCLAW_BIN}"
  exit 1
end

# Display version information
stdout, stderr, status = Open3.capture3("#{OPENCLAW_BIN} --version")
raise "Failed to get version: #{stderr}" unless status.success?
puts "Using OpenClaw: #{stdout.chomp}"

# === 1. Service-/Config-Drift ===
puts "=== 1. Service-/Config-Drift ==="
system("#{OPENCLAW_BIN} doctor") || raise("doctor command failed")

# === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
puts "=== 2. Plugin-Stage ==="
system("#{OPENCLAW_BIN} plugins registry --refresh") || raise("plugins registry command failed")

if ENV.fetch('RUN_PLUGIN_UPDATE', '0') == '1'
  system("#{OPENCLAW_BIN} plugins update --all") || raise("plugins update command failed")
else
  puts "Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable."
end

# === 3. Tasks ===
puts "=== 3. Tasks ==="
system("#{OPENCLAW_BIN} tasks maintenance --apply") || raise("tasks maintenance command failed")

# === 4. Sessions – alle Agents auf einmal ===
puts "=== 4. Sessions ==="
system("#{OPENCLAW_BIN} sessions cleanup --enforce --all-agents") || raise("sessions cleanup command failed")

# === 5. Memory – status/index decken alle Agents ab ===
puts "=== 5. Memory status/index ==="
system("#{OPENCLAW_BIN} memory status --deep --fix") || raise("memory status command failed")
system("#{OPENCLAW_BIN} memory index --force") || raise("memory index command failed")

# === 6. Memory promote – MUSS pro Agent ===
puts "=== 6. Memory promote ==="
%w[main knecht docs ops-hub cron].each do |agent|
  system("#{OPENCLAW_BIN} memory promote --apply --agent #{agent}") || raise("memory promote for agent #{agent} failed")
end

# === 7. Secrets ===
puts "=== 7. Secrets ==="
system("#{OPENCLAW_BIN} secrets reload") || raise("secrets reload command failed")
