#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "08429a4cca26f23738d85db45481980657e416aed6baa338ecf29431ec397b88", "source_sha256": "a137d03b3b37332439a1592831d60479ff86315c7e6d6ed7da0fb799db0f13f7", "target_language": "ruby"}
# find-sessions.sh — portiert nach ruby
# Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/find-sessions.sh
# auch in: OpenClaw@gateway2:skills/tmux/scripts/find-sessions.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'optparse'
require 'fileutils'

def usage
  puts <<~USAGE
    Usage: find-sessions.rb [-L socket-name|-S socket-path|-A] [-q pattern]

    List tmux sessions on a socket (default tmux socket if none provided).

    Options:
      -L, --socket       tmux socket name (passed to tmux -L)
      -S, --socket-path  tmux socket path (passed to tmux -S)
      -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR
      -q, --query        case-insensitive substring to filter session names
      -h, --help         show this help
  USAGE
  exit 0
end

socket_name = ""
socket_path = ""
query = ""
scan_all = false
socket_dir = ENV['CLAWDBOT_TMUX_SOCKET_DIR'] || "#{ENV['TMPDIR'] || '/tmp'}/clawdbot-tmux-sockets"

OptionParser.new do |opts|
  opts.on('-L', '--socket SOCKET', 'tmux socket name') { |s| socket_name = s }
  opts.on('-S', '--socket-path PATH', 'tmux socket path') { |s| socket_path = s }
  opts.on('-A', '--all', 'scan all sockets') { scan_all = true }
  opts.on('-q', '--query QUERY', 'filter session names') { |s| query = s }
  opts.on('-h', '--help', 'show help') { usage }
end.parse!

if scan_all && (!socket_name.empty? || !socket_path.empty?)
  STDERR.puts "Cannot combine --all with -L or -S"
  exit 1
end

if !socket_name.empty? && !socket_path.empty?
  STDERR.puts "Use either -L or -S, not both"
  exit 1
end

def command_exists?(command)
  system("which #{command} > /dev/null 2>&1")
end

unless command_exists?('tmux')
  STDERR.puts "tmux not found in PATH"
  exit 1
end

def list_sessions(label, tmux_args)
  tmux_cmd = ['tmux'] + tmux_args
  
  sessions_raw = `#{tmux_cmd.join(' ')} list-sessions -F '\#{session_name}\t\#{session_attached}\t\#{session_created_string}' 2>/dev/null`
  
  unless $?.success?
    STDERR.puts "No tmux server found on #{label}"
    return false
  end
  
  sessions = sessions_raw.strip.split("\n")
  
  if !@query.empty?
    sessions.select! { |line| line.downcase.include?(@query.downcase) }
  end
  
  if sessions.empty?
    puts "No sessions found on #{label}"
    return true
  end
  
  puts "Sessions on #{label}:"
  sessions.each do |line|
    parts = line.split("\t")
    name = parts[0]
    attached = parts[1]
    created = parts[2]
    
    attached_label = (attached == "1") ? "attached" : "detached"
    puts "  - #{name} (#{attached_label}, started #{created})"
  end
  
  true
end

@query = query

if scan_all
  unless Dir.exist?(socket_dir)
    STDERR.puts "Socket directory not found: #{socket_dir}"
    exit 1
  end
  
  sockets = Dir.children(socket_dir).map { |f| File.join(socket_dir, f) }.select { |f| File.socket?(f) }
  
  if sockets.empty?
    STDERR.puts "No sockets found under #{socket_dir}"
    exit 1
  end
  
  exit_code = 0
  sockets.each do |sock|
    success = list_sessions("socket path '#{sock}'", ['-S', sock])
    exit_code = 1 unless success
  end
  exit exit_code
end

tmux_cmd = []
socket_label = "default socket"

if !socket_name.empty?
  tmux_cmd += ['-L', socket_name]
  socket_label = "socket name '#{socket_name}'"
elsif !socket_path.empty?
  tmux_cmd += ['-S', socket_path]
  socket_label = "socket path '#{socket_path}'"
end

list_sessions(socket_label, tmux_cmd)
