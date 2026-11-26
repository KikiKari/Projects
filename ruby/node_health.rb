#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "8185790256f053dbadd3f99642b8cd4964460c153362cb31fc98bdb5c36fa19f", "source_sha256": "8cb73cb9ea3a2ccee09205fcea5d8d2e1f29c369b21a3dfcf948b8029436a339", "target_language": "ruby"}
# node_health.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/node-health-monitor/scripts/node_health.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# frozen_string_literal: true

# Node Health Monitor - Multi-Node Gesundheitsüberwachung

require 'json'
require 'time'
require 'fileutils'

# Konfiguration
WORKSPACE = File.expand_path('/home/openclaw/.openclaw/workspace')
HEALTH_DB = File.join(WORKSPACE, 'db', 'health.db')
LOG_FILE = File.join(WORKSPACE, 'logs', 'node-health.log')

# Node-Definitionen
NODES = {
  'node1' => {
    'name' => 'Gateway',
    'host' => 'localhost',
    'user' => 'openclaw',
    'critical' => true
  },
  'node2' => {
    'name' => 'Worker',
    'host' => '100.92.155.34',
    'user' => 'root',
    'ssh_key' => '~/.ssh/id_rsa'
  },
  'node3' => {
    'name' => 'Relay',
    'host' => '185.242.xxx.xxx',
    'user' => 'root',
    'disk_warning' => 85
  },
  'node5' => {
    'name' => 'Redmi',
    'host' => '192.168.1.x',
    'user' => 'openclaw',
    'optional' => true
  }
}.freeze

def log(message, level = 'INFO')
  # Logging
  timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  entry = "[#{timestamp}] [#{level}] #{message}"
  puts entry
  
  log_dir = File.dirname(LOG_FILE)
  FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)
  
  File.open(LOG_FILE, 'a') do |f|
    f.puts entry
  end
end

def check_ping(host, timeout = 5)
  # Prüft Erreichbarkeit
  begin
    result = system("ping -c 1 -W #{timeout} #{host}", out: '/dev/null', err: '/dev/null')
    result == true
  rescue StandardError
    false
  end
end

def check_ssh(node_config)
  # Prüft SSH-Verbindung
  host = node_config['host']
  user = node_config.fetch('user', 'root')
  
  cmd = ['ssh', '-o', 'ConnectTimeout=10', '-o', 'BatchMode=yes',
         "#{user}@#{host}", 'echo "OK"']
  
  begin
    result = Open3.capture3(*cmd)
    $?.success? && result[0].include?('OK')
  rescue StandardError
    false
  end
end

def get_node_metrics(node_config)
  # Holt Metriken via SSH
  host = node_config['host']
  user = node_config.fetch('user', 'root')
  
  metrics = {
    'timestamp' => Time.now.iso8601,
    'available' => false,
    'cpu' => nil,
    'ram' => nil,
    'disk' => nil,
    'load' => nil
  }
  
  # SSH-Command für alle Metriken
  cmd = <<~CMD
    ssh -o ConnectTimeout=10 #{user}@#{host} '
        # CPU
        echo "CPU:$(top -bn1 | grep "Cpu(s)" | awk "{print \$2}" | cut -d"%" -f1)"
        
        # RAM
        echo "RAM:$(free | grep Mem | awk "{print (\$3/\$2) * 100.0}")"
        
        # Disk
        echo "DISK:$(df -h / | tail -1 | awk "{print \$5}" | tr -d "%")"
        
        # Load
        echo "LOAD:$(uptime | awk -F"load average:" "{print \$2}" | awk "{print \$1}" | tr -d ",")"
        
        # Gateway Status
        if command -v openclaw >/dev/null 2>&1; then
            systemctl is-active openclaw-gateway 2>/dev/null || echo "GATEWAY:inactive"
        fi
    '
  CMD
  
  begin
    stdout, stderr, status = Open3.capture3(cmd, timeout: 15)
    
    if status.success?
      metrics['available'] = true
      
      stdout.strip.split("\n").each do |line|
        next unless line.include?(':')
        
        key, value = line.split(':', 2)
        case key
        when 'CPU'
          metrics['cpu'] = value.to_f
        when 'RAM'
          metrics['ram'] = value.to_f
        when 'DISK'
          metrics['disk'] = value.to_i
        when 'LOAD'
          metrics['load'] = value.to_f
        when 'GATEWAY'
          metrics['gateway_status'] = value
        end
      end
    end
  rescue Timeout::Error
    log("SSH timeout for #{node_config['name']}", 'WARN')
  rescue StandardError => e
    log("Error checking #{node_config['name']}: #{e}", 'ERROR')
  end
  
  metrics
end

def check_alerts(node_id, node_config, metrics)
  # Prüft Schwellwerte und generiert Alerts
  alerts = []
  
  # Verfügbarkeit
  if !metrics['available'] && !node_config.fetch('optional', false)
    alerts.push({
                  'level' => 'CRITICAL',
                  'message' => "Node #{node_config['name']} nicht erreichbar!"
                })
  elsif metrics['available']
    # CPU
    if metrics['cpu'] && metrics['cpu'] > 90
      alerts.push({
                    'level' => 'WARNING',
                    'message' => "Node #{node_config['name']}: CPU bei #{metrics['cpu'].round(1)}%"
                  })
    end
    
    # RAM
    if metrics['ram'] && metrics['ram'] > 90
      alerts.push({
                    'level' => 'WARNING',
                    'message' => "Node #{node_config['name']}: RAM bei #{metrics['ram'].round(1)}%"
                  })
    end
    
    # Disk
    disk_threshold = node_config.fetch('disk_warning', 85)
    if metrics['disk'] && metrics['disk'] > disk_threshold
      level = metrics['disk'] > 95 ? 'CRITICAL' : 'WARNING'
      alerts.push({
                    'level' => level,
                    'message' => "Node #{node_config['name']}: Disk bei #{metrics['disk']}%"
                  })
    end
    
    # Gateway
    if node_config['critical'] && metrics['gateway_status'] == 'inactive'
      alerts.push({
                    'level' => 'CRITICAL',
                    'message' => "Node #{node_config['name']}: OpenClaw Gateway nicht aktiv!"
                  })
    end
  end
  
  alerts
end

def send_alert(alert)
  # Sendet Alert via channel-status-agent
  begin
    cmd = [
      'python3',
      File.join(WORKSPACE, 'skills', 'channel-status-agent', 'scripts', 'channel_status.py'),
      '--type', 'alert',
      '--message', "#{alert['level']}: #{alert['message']}"
    ]
    
    system(*cmd, out: '/dev/null', err: '/dev/null')
    log("Alert sent: #{alert['message']}")
  rescue StandardError => e
    log("Failed to send alert: #{e}", 'ERROR')
  end
end

def main
  # Hauptfunktion
  require 'optparse'
  
  options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: node_health.rb [options]'
    opts.on('--node NODE', 'Node ID oder "all"') { |v| options[:node] = v }
    opts.on('--check CHECK', %w[ping ssh metrics all], 'Check type') { |v| options[:check] = v }
    opts.on('--alert', 'Sende Alerts') { options[:alert] = true }
  end.parse!
  
  options[:node] ||= 'all'
  options[:check] ||= 'all'
  
  # Nodes bestimmen
  if options[:node] == 'all'
    nodes_to_check = NODES
  elsif NODES.key?(options[:node])
    nodes_to_check = { options[:node] => NODES[options[:node]] }
  else
    log("Unknown node: #{options[:node]}", 'ERROR')
    exit(1)
  end
  
  # Health-Checks durchführen
  all_alerts = []
  
  nodes_to_check.each do |node_id, node_config|
    log("Checking #{node_config['name']} (#{node_id})")
    
    # Ping
    if %w[ping all].include?(options[:check])
      if node_config['host'] != 'localhost'
        ping_ok = check_ping(node_config['host'])
        log("  Ping: #{ping_ok ? 'OK' : 'FAILED'}")
      end
    end
    
    # SSH
    if %w[ssh all].include?(options[:check])
      ssh_ok = check_ssh(node_config)
      log("  SSH: #{ssh_ok ? 'OK' : 'FAILED'}")
    end
    
    # Metriken
    if %w[metrics all].include?(options[:check])
      metrics = get_node_metrics(node_config)
      
      if metrics['available']
        log("  CPU: #{metrics['cpu'] ? "#{metrics['cpu'].round(1)}%" : 'N/A'}")
        log("  RAM: #{metrics['ram'] ? "#{metrics['ram'].round(1)}%" : 'N/A'}")
        log("  Disk: #{metrics['disk'] ? "#{metrics['disk']}%" : 'N/A'}")
        log("  Load: #{metrics['load'] ? metrics['load'] : 'N/A'}")
      else
        log('  Metrics: UNAVAILABLE')
      end
      
      # Alerts prüfen
      alerts = check_alerts(node_id, node_config, metrics)
      all_alerts.concat(alerts)
    end
  end
  
  # Alerts senden
  if options[:alert] && !all_alerts.empty?
    log("\nSending #{all_alerts.length} alerts...")
    all_alerts.each { |alert| send_alert(alert) }
  elsif !all_alerts.empty?
    log("\n#{all_alerts.length} alerts found (use --alert to send)")
  else
    log("\nAll nodes healthy!")
  end
end

# Hilfsklasse für Open3
module Open3
  def self.capture3(*cmd, timeout: nil)
    stdin, stdout, stderr, wait_thr = Open3.popen3(*cmd)
    
    if timeout
      pid = wait_thr.pid
      Thread.new do
        sleep timeout
        begin
          Process.kill('TERM', pid)
          sleep 2
          Process.kill('KILL', pid) if Process.kill(0, pid) rescue nil
        rescue StandardError
        end
      end
    end
    
    stdin.close_write
    out = stdout.read
    err = stderr.read
    status = wait_thr.value
    
    [out, err, status]
  end
end

main if __FILE__ == $PROGRAM_NAME
