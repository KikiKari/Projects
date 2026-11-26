#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "2fcf46b1120ba19b183c4775b601614a90990fa3856a88c31bd300d42e71ad83", "source_sha256": "47064dbc7b32c01d57d42222f8cc3ac7caf9c8d82b98029dc5fc6ecb0d32f2c9", "target_language": "ruby"}
# collect_ist_gateway_a.sh — portiert nach ruby
# Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'fileutils'
require 'json'
require 'open3'

# Konfiguration
BASE_DIR = "#{Dir.home}/.openclaw"
OUT_DIR = "#{BASE_DIR}/workspace/vscode"
NOW_UTC = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
NOW_LOCAL = Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")
TS = Time.now.strftime("%Y%m%d-%H%M%S")

# Ausgabeverzeichnis erstellen
FileUtils.mkdir_p(OUT_DIR)

# Dateipfade
IST_FILE = "#{OUT_DIR}/IST-ZUSTAND_GATEWAY-A_NODE1.md"
INV_FILE = "#{OUT_DIR}/ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md"
CFG_FILE = "#{OUT_DIR}/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md"
ENV_FILE = "#{OUT_DIR}/ENV-STATUS_GATEWAY-A_NODE1.md"
RUN_FILE = "#{OUT_DIR}/RUN-#{TS}.md"

OPENCLAW_JSON = "#{BASE_DIR}/openclaw.json"
ENV_DOT = "#{BASE_DIR}/.env"
ENV_SYSTEMD = "#{BASE_DIR}/gateway.systemd.env"
VSCODE_DIR = "#{BASE_DIR}/.vscode"

# Systeminformationen sammeln
def get_hostname_fqdn
  stdout, stderr, status = Open3.capture3("hostname -f")
  if status.success?
    stdout.strip
  else
    `hostname`.strip
  end
end

HOSTNAME_FQDN = get_hostname_fqdn
HOSTNAME_SHORT = `hostname`.strip
ARCH = `uname -m`.strip
KERNEL = `uname -r`.strip

OS_PRETTY = begin
  if File.exist?("/etc/os-release")
    content = File.read("/etc/os-release")
    match = content.match(/^PRETTY_NAME=(.*)$/)
    match ? match[1].gsub('"', '') : ""
  else
    ""
  end
rescue
  ""
end

IPV4_ALL = begin
  stdout, stderr, status = Open3.capture3("hostname -I")
  if status.success?
    stdout.strip.split(" ").join(" ")
  else
    ""
  end
rescue
  ""
end

PUBLIC_IP = begin
  stdout, stderr, status = Open3.capture3("curl -4 -s --max-time 4 ifconfig.me")
  if status.success?
    stdout.strip
  else
    ""
  end
rescue
  ""
end

TAILSCALE_IP = begin
  stdout, stderr, status = Open3.capture3("tailscale ip -4")
  if status.success?
    stdout.strip.split("\n").first || ""
  else
    ""
  end
rescue
  ""
end

OPENCLAW_VER = begin
  stdout, stderr, status = Open3.capture3("openclaw --version")
  if status.success?
    stdout.strip
  else
    ""
  end
rescue
  ""
end

NODE_VER = begin
  stdout, stderr, status = Open3.capture3("node -v")
  if status.success?
    stdout.strip
  else
    ""
  end
rescue
  ""
end

# Leere Werte durch Standardtext ersetzen
PUBLIC_IP = "(nicht ermittelt)" if PUBLIC_IP.empty?
TAILSCALE_IP = "(nicht ermittelt)" if TAILSCALE_IP.empty?
OPENCLAW_VER = "(nicht ermittelt)" if OPENCLAW_VER.empty?
NODE_VER = "(nicht ermittelt)" if NODE_VER.empty?

# IST-Zustand Datei erstellen
File.open(IST_FILE, 'w') do |file|
  file.puts "# IST-Zustand: Gateway A / Node 1"
  file.puts
  file.puts "Stand (lokal): #{NOW_LOCAL}  "
  file.puts "Stand (UTC): #{NOW_UTC}"
  file.puts
  file.puts "## 1) Identitaet & System"
  file.puts
  file.puts "- Gateway: **A**"
  file.puts "- Node: **1**"
  file.puts "- Hostname (short): `#{HOSTNAME_SHORT}`"
  file.puts "- Hostname (FQDN): `#{HOSTNAME_FQDN}`"
  file.puts "- Architektur: `#{ARCH}`"
  file.puts "- Kernel: `#{KERNEL}`"
  file.puts "- OS: `#{OS_PRETTY}`"
  file.puts "- IPv4 (lokal): `#{IPV4_ALL}`"
  file.puts "- Public IPv4: `#{PUBLIC_IP}`"
  file.puts "- Tailscale IPv4: `#{TAILSCALE_IP}`"
  file.puts "- OpenClaw Version: `#{OPENCLAW_VER}`"
  file.puts "- Node.js Version: `#{NODE_VER}`"
  file.puts
  file.puts "## 2) Arbeitsverzeichnisse"
  file.puts
  file.puts "- Basis: `#{BASE_DIR}`"
  file.puts "- Funktionell VSCode: `#{VSCODE_DIR}`"
  file.puts "- Workspace Doku: `#{OUT_DIR}`"
  file.puts
  file.puts "## 3) Kernartefakte (Existenz)"
  file.puts
  
  # Existenzprüfung der Dateien
  file.puts "- `#{OPENCLAW_JSON}`: #{File.exist?(OPENCLAW_JSON) ? 'vorhanden' : 'fehlt'}"
  file.puts "- `#{ENV_DOT}`: #{File.exist?(ENV_DOT) ? 'vorhanden' : 'fehlt'}"
  file.puts "- `#{ENV_SYSTEMD}`: #{File.exist?(ENV_SYSTEMD) ? 'vorhanden' : 'fehlt'}"
  
  plugins_installs = "#{BASE_DIR}/plugins/installs.json"
  file.puts "- `#{plugins_installs}`: #{File.exist?(plugins_installs) ? 'vorhanden' : 'fehlt'}"
  
  plugin_skills_dir = "#{BASE_DIR}/plugin-skills"
  file.puts "- `#{plugin_skills_dir}`: #{File.directory?(plugin_skills_dir) ? 'vorhanden' : 'fehlt'}"
end

# Artefakt-Inventar Datei erstellen
File.open(INV_FILE, 'w') do |file|
  file.puts "# Artefakt-Inventar: Gateway A / Node 1"
  file.puts
  file.puts "Stand: #{NOW_LOCAL}"
  file.puts
  file.puts "## Top-Level in ~/.openclaw"
  file.puts
  file.puts '```text'
  
  if Dir.exist?(BASE_DIR)
    Dir.entries(BASE_DIR).sort.each do |entry|
      next if entry.start_with?('.')
      file.puts entry
    end
  end
  
  file.puts '```'
  file.puts
  file.puts "## ~/.openclaw/.vscode"
  file.puts
  file.puts '```text'
  
  if Dir.exist?(VSCODE_DIR)
    Dir.entries(VSCODE_DIR).each do |entry|
      next if entry == '.' || entry == '..'
      stat = File.stat("#{VSCODE_DIR}/#{entry}")
      permissions = "%o" % (stat.mode & 0777)
      file.puts "#{permissions} #{stat.mtime.strftime('%Y-%m-%d %H:%M')} #{entry}"
    end
  else
    file.puts "(nicht vorhanden)"
  end
  
  file.puts '```'
  file.puts
  file.puts "## plugin-skills/"
  file.puts
  file.puts '```text'
  
  plugin_skills_path = "#{BASE_DIR}/plugin-skills"
  if Dir.exist?(plugin_skills_path)
    Dir.entries(plugin_skills_path).sort.each do |entry|
      next if entry == '.' || entry == '..'
      file.puts entry
    end
  else
    file.puts "(nicht vorhanden)"
  end
  
  file.puts '```'
  file.puts
  file.puts "## openclaw.json Backups"
  file.puts
  file.puts '```text'
  
  backup_files = Dir.glob("#{BASE_DIR}/openclaw.json.bak*").sort
  if backup_files.any?
    backup_files.each { |f| file.puts File.basename(f) }
  else
    file.puts "(keine gefunden)"
  end
  
  file.puts '```'
end

# OpenClaw Config Snapshot Datei erstellen
File.open(CFG_FILE, 'w') do |file|
  file.puts "# OpenClaw Config Snapshot: Gateway A / Node 1"
  file.puts
  file.puts "Stand: #{NOW_LOCAL}"
  file.puts
  file.puts "## Schluesselpositionen (grep)"
  file.puts
  file.puts '```text'
  
  if File.exist?(OPENCLAW_JSON)
    begin
      content = File.read(OPENCLAW_JSON)
      keywords = ['"gateway"', '\"session\"', '\"dmScope\"', '\"auth\"', '\"secrets\"', '\"tools\"', '\"plugins\"', '\"profile\"', '\"alsoAllow\"', '\"denyCommands\"']
      lines = content.lines.each_with_index.map { |line, index| [line, index + 1] }
      
      lines.each do |line, line_number|
        keywords.each do |keyword|
          if line.include?(keyword)
            file.puts "#{line_number}: #{line.strip}"
            break
          end
        end
      end
    rescue => e
      file.puts "Fehler beim Lesen der Datei: #{e.message}"
    end
  else
    file.puts "openclaw.json fehlt"
  end
  
  file.puts '```'
  file.puts
  file.puts "## Ausschnitt gateway/session/auth"
  file.puts
  file.puts '```json'
  
  if File.exist?(OPENCLAW_JSON)
    begin
      lines = File.readlines(OPENCLAW_JSON)
      start_line = 579 # 580 - 1 for zero-based indexing
      end_line = 779  # 780 - 1 for zero-based indexing
      
      if lines.length > start_line
        actual_end = [end_line, lines.length - 1].min
        (start_line..actual_end).each do |i|
          file.puts lines[i]
        end
      end
    rescue => e
      file.puts "{ \"error\": \"Fehler beim Lesen der Datei: #{e.message}\" }"
    end
  else
    file.puts '{ "error": "openclaw.json fehlt" }'
  end
  
  file.puts '```'
end

# ENV-Status Datei erstellen
File.open(ENV_FILE, 'w') do |file|
  file.puts "# ENV-Status: Gateway A / Node 1"
  file.puts
  file.puts "Stand: #{NOW_LOCAL}"
  file.puts
  file.puts "## Dateien"
  file.puts
  file.puts '```text'
  
  env_files = [ENV_DOT, ENV_SYSTEMD]
  env_files.each do |env_file|
    if File.exist?(env_file)
      stat = File.stat(env_file)
      permissions = "%o" % (stat.mode & 0777)
      file.puts "-#{permissions} #{stat.mtime.strftime('%Y-%m-%d %H:%M')} #{env_file}"
    end
  end
  
  file.puts '```'
  file.puts
  file.puts "## .env (vollstaendig)"
  file.puts
  file.puts '```dotenv'
  
  if File.exist?(ENV_DOT)
    File.open(ENV_DOT, 'r') do |env_file|
      env_file.each_line { |line| file.puts line.chomp }
    end
  else
    file.puts "# .env fehlt"
  end
  
  file.puts '```'
  file.puts
  file.puts "## gateway.systemd.env (vollstaendig)"
  file.puts
  file.puts '```dotenv'
  
  if File.exist?(ENV_SYSTEMD)
    File.open(ENV_SYSTEMD, 'r') do |env_file|
      env_file.each_line { |line| file.puts line.chomp }
    end
  else
    file.puts "# gateway.systemd.env fehlt"
  end
  
  file.puts '```'
end

# Laufprotokoll Datei erstellen
File.open(RUN_FILE, 'w') do |file|
  script_name = File.basename(__FILE__)
  file.puts "# Laufprotokoll Gateway A / Node 1"
  file.puts
  file.puts "- Zeit (lokal): #{NOW_LOCAL}"
  file.puts "- Zeit (UTC): #{NOW_UTC}"
  file.puts "- Script: #{script_name}"
  file.puts
  file.puts "## Erzeugte Dateien"
  file.puts
  file.puts "- #{File.basename(IST_FILE)}"
  file.puts "- #{File.basename(INV_FILE)}"
  file.puts "- #{File.basename(CFG_FILE)}"
  file.puts "- #{File.basename(ENV_FILE)}"
end

# Erfolgsmeldung ausgeben
puts "OK: IST-Zustand erfasst."

Dir.entries(OUT_DIR).sort.each do |entry|
  next if entry.start_with?('.')
  puts "- #{entry}"
end
