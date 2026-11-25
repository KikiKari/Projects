#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "8eedbcd7949ff02d72d1757f66c68407bd14e9fc3ad49d7fcc072faae785c77c", "source_sha256": "1b01ca0f5943b16d3905faf557953600ee54f15ecf1dc18c1461585eba94d376", "target_language": "ruby"}
# abstractions-manager-cron.sh — portiert nach ruby
# Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

require 'fileutils'
require 'open3'

# Set the PATH environment variable
ENV['PATH'] = "/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin"

# Load environment variables from .env file
env_file = '/home/openclaw/.openclaw/.env'
if File.exist?(env_file)
  File.readlines(env_file).each do |line|
    next if line.strip.empty? || line.start_with?('#')
    key, value = line.split('=', 2).map(&:strip)
    ENV[key] = value
  end
end

# Check if OPENROUTER_API_KEY is set
abort("OPENROUTER_API_KEY fehlt") unless ENV['OPENROUTER_API_KEY']

# Set GITHUB_TOKEN with fallbacks
ENV['GITHUB_TOKEN'] ||= ENV['GH_TOKEN'] || ENV['GH_ACCESS_TOKEN']

# Define the lock file and script path
lock_file = '/home/openclaw/.openclaw/locks/abstractions-manager.lock'
script_path = '/home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py'

# Attempt to acquire a non-blocking lock
File.open(lock_file, 'w') do |f|
  if f.flock(File::LOCK_NB | File::LOCK_EX)
    # Lock acquired, execute the Python script
    Open3.popen3("python3 #{script_path} #{ARGV.join(' ')}") do |stdin, stdout, stderr, wait_thr|
      stdin.close
      puts stdout.read
      puts stderr.read
      exit_status = wait_thr.value
      exit exit_status.exitstatus
    end
  else
    # Lock not acquired, exit with status 0
    exit 0
  end
end
