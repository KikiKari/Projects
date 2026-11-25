#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "553cd8c528877f4142c21ea63cb583a6c005da88f57da2476010dc24261dff5a", "source_sha256": "705cb2cc5900c507db1038d107f06e2f8452a95c37d0611cd27dfe2ed61dd498", "target_language": "ruby"}
# channel_status.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

# frozen_string_literal: true

#
# Channel Status Agent - Automatische Status-Updates
#

require 'json'
require 'time'
require 'fileutils'

# Konfiguration
WORKSPACE = Pathname.new('/home/openclaw/.openclaw/workspace')
LOGS_DB = WORKSPACE.join('db/logs.db')
CONFIG_FILE = WORKSPACE.join('config/channel-status.json')
LOG_FILE = WORKSPACE.join('logs/channel-status.log')

def log(message, level = 'INFO')
  # Logging
  timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  entry = "[#{timestamp}] [#{level}] #{message}"
  puts entry
  File.open(LOG_FILE, 'a') { |f| f.puts entry }
rescue StandardError => e
  puts "Logging failed: #{e.message}"
end

def get_system_status
  # Sammelt System-Status
  status = {
    'timestamp' => Time.now.iso8601,
    'nodes' => {},
    'agents' => {},
    'system' => {}
  }

  # Node-Status (vereinfacht)
  nodes = {
    'node1' => { 'name' => 'Gateway', 'status' => 'online' },
    'node2' => { 'name' => 'Worker', 'status' => 'online' },
    'node3' => { 'name' => 'Relay', 'status' => 'offline', 'reason' => 'disk full' },
    'node5' => { 'name' => 'Redmi', 'status' => 'intermittent' },
    'node7' => { 'name' => 'Docker', 'status' => 'planned' }
  }
  status['nodes'] = nodes

  # Agent-Status aus Cron
  begin
    result = `crontab -l`
    cron_lines = result.lines.count { |line| !line.start_with?('#') }
    status['agents']['active_crons'] = cron_lines
  rescue StandardError
    status['agents']['active_crons'] = 'unknown'
  end

  # System-Metriken
  begin
    # Disk usage
    df_output = `df -h /`
    df_output.each_line do |line|
      if line.include?('/') && line.include?('%')
        parts = line.split
        status['system']['disk_used'] = parts[4]
        break
      end
    end

    # RAM usage
    free_output = `free -h`
    free_output.each_line do |line|
      if line.include?('Mem:')
        parts = line.split
        status['system']['ram_total'] = parts[1]
        status['system']['ram_used'] = parts[2]
        break
      end
    end
  rescue StandardError
    nil
  end

  status
end

def format_daily_status(status)
  # Formatiert täglichen Status
  nodes = status['nodes']
  online = nodes.values.count { |n| n['status'] == 'online' }

  message = <<~MESSAGE
    📊 **Täglicher Status-Report**
    🗓️ #{Time.now.strftime('%Y-%m-%d %H:%M')}

    **🖥️ Nodes (#{online}/5 online):**

  MESSAGE

  nodes.each do |node_id, info|
    emoji = case info['status']
            when 'online'
              '🟢'
            when 'offline'
              '🔴'
            else
              '🟡'
            end
    reason = info['reason'] ? " (#{info['reason']})" : ''
    message += "#{emoji} #{info['name']}: #{info['status']}#{reason}\n"
  end

  message += "\n**🤖 Agents:**\n"
  message += "Aktive Cron-Jobs: #{status['agents']['active_crons']}\n"

  if status['system'].key?('disk_used')
    message += "\n**💾 System:**\n"
    message += "Disk: #{status['system']['disk_used']} belegt\n"
    message += "RAM: #{status['system']['ram_used']} / #{status['system']['ram_total']}\n"
  end

  message
end

def format_weekly_status(_status)
  # Formatiert wöchentlichen Status
  <<~MESSAGE
    📈 **Wöchentlicher Report**
    📅 Woche #{Time.now.strftime('%V')} - #{Time.now.strftime('%Y')}

    **Zusammenfassung:**
    - 5 aktive Sub-Agents
    - 11 Skills synchronisiert
    - 3 neue Features implementiert

    **Top-Ereignisse:**
    1. ClawHub-Git Sync implementiert ✅
    2. Node 3 Disk voll (95%) ⚠️
    3. Channel-Status-Agent aktiviert 🆕

    **Geplante Wartungen:**
    - Node 3: Disk-Cleanup erforderlich
    - Node 7: Docker-Setup ausstehend
  MESSAGE
end

def send_to_channel(message, channel_type: 'telegram', channel_id: '-1002381931352')
  # Sendet Nachricht an Channel
  cmd = case channel_type
        when 'telegram'
          ['openclaw', 'message', 'send', '--target', channel_id, '--message', message]
        else
          log("Channel type #{channel_type} not implemented", 'WARN')
          return false
        end

  begin
    result = system(*cmd)
    if result
      log("Message sent to #{channel_type} #{channel_id}")
      true
    else
      log('Failed to send message', 'ERROR')
      false
    end
  rescue StandardError => e
    log("Send error: #{e}", 'ERROR')
    false
  end
end

def main
  # Hauptfunktion
  require 'optparse'

  options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: channel_status.rb [options]'
    opts.on('--type TYPE', %w[daily weekly alert], 'Type of status update') { |v| options[:type] = v }
    opts.on('--message MESSAGE', 'Alert message') { |v| options[:message] = v }
    opts.on('--channel CHANNEL', 'Target channel ID') { |v| options[:channel] = v }
    opts.on('--dry-run', 'Show message without sending') { options[:dry_run] = true }
  end.parse!

  raise OptionParser::MissingArgument, '--type' unless options[:type]

  log("Starting #{options[:type]} status update")

  # Status sammeln
  status = get_system_status

  # Message formatieren
  message = case options[:type]
            when 'daily'
              format_daily_status(status)
            when 'weekly'
              format_weekly_status(status)
            when 'alert'
              "🚨 **ALERT**\n#{options[:message] || 'Manual alert'}"
            end

  # Senden oder Dry-Run
  if options[:dry_run]
    puts "\n--- DRY RUN ---"
    puts message
    puts '--- END ---'
  else
    send_to_channel(message, channel_id: options[:channel] || '-1002381931352')
  end

  log('Status update completed')
end

# Ensure log directory exists
FileUtils.mkdir_p(LOG_FILE.dirname) unless LOG_FILE.dirname.directory?

main if __FILE__ == $PROGRAM_NAME
