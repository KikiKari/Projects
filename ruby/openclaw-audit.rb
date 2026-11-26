#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "f28002f419595e534bdf8ccbbc16bc83ec5e87c22ca2531131dd73617d2e884e", "source_sha256": "e51b94641336291974fe14bf4bb7299a75ec7dcce49e1d413282c8043e9f09f1", "target_language": "ruby"}
# openclaw-audit.sh — portiert nach ruby
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# OpenClaw read-only audit/diagnostic sweep
# Output: openclaw-audit-YYYY-MM-DD.log im selben Verzeichnis wie dieses Script

require 'pathname'
require 'date'
require 'open3'

script_dir = Pathname.new(__FILE__).dirname.expand_path
date_stamp = DateTime.now.strftime('%Y-%m-%d')
out = script_dir.join("openclaw-audit-#{date_stamp}.log")

oc = ['openclaw', '--no-color']

File.open(out, 'w') do |file|
  file.puts "================================================================"
  file.puts "OpenClaw audit run"
  file.puts "Started:  #{DateTime.now.iso8601}"
  file.puts "Host:     #{`hostname`.chomp}"
  file.puts "User:     #{`whoami`.chomp}"
  
  version_output, version_status = Open3.capture2e('openclaw', '--version')
  version = version_status.success? ? version_output.chomp : 'unknown'
  file.puts "Version:  #{version}"
  
  file.puts "Output:   #{out}"
  file.puts "================================================================"
end

def run_cmd(title, out, *cmd)
  File.open(out, 'a') do |file|
    file.puts
    file.puts "----------------------------------------------------------------"
    file.puts "### #{title}"
    file.puts "### $ #{cmd.join(' ')}"
    file.puts "### #{DateTime.now.iso8601}"
    file.puts "----------------------------------------------------------------"
    
    stdout_stderr, wait_thr = Open3.capture2e(*cmd)
    file.puts stdout_stderr
    file.puts "[exit: #{wait_thr.value.exitstatus}]"
  end
end

run_cmd("tasks audit --severity error", out, *oc, 'tasks', 'audit', '--severity', 'error')
run_cmd("secrets audit", out, *oc, 'secrets', 'audit')
run_cmd("security audit", out, *oc, 'security', 'audit')
run_cmd("plugins doctor", out, *oc, 'plugins', 'doctor')
run_cmd("plugins deps", out, *oc, 'plugins', 'deps')
run_cmd("plugins registry", out, *oc, 'plugins', 'registry')
run_cmd("skills check", out, *oc, 'skills', 'check')
run_cmd("hooks check", out, *oc, 'hooks', 'check')
run_cmd("gateway status --deep", out, *oc, 'gateway', 'status', '--deep')
run_cmd("channels status --probe", out, *oc, 'channels', 'status', '--probe')
run_cmd("memory status --deep", out, *oc, 'memory', 'status', '--deep')
run_cmd("sessions --all-agents", out, *oc, 'sessions', '--all-agents')
run_cmd("tasks list", out, *oc, 'tasks', 'list')
run_cmd("cron list", out, *oc, 'cron', 'list')

File.open(out, 'a') do |file|
  file.puts
  file.puts "================================================================"
  file.puts "Audit complete: #{DateTime.now.iso8601}"
  file.puts "================================================================"
end

puts "Audit complete. Output: #{out}"
