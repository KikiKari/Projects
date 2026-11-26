#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "b6feda46d20baca2d64621186d1924d64e329a8443634ade18243e9867735c94", "source_sha256": "da890cc26fb848b78b6a85373d6cfa4e08f6e7c2002921e1c0247960b8b361d7", "target_language": "ruby"}
# collect_ist_gateway_b.sh — portiert nach ruby
# Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'fileutils'
require 'socket'
require 'open3'
require 'net/http'
require 'uri'
require 'json'

BASE_DIR = "#{ENV['HOME']}/.openclaw"
OUT_DIR = "#{BASE_DIR}/workspace/vscode"
NOW_UTC = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
NOW_LOCAL = Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")
TS = Time.now.strftime("%Y%m%d-%H%M%S")

FileUtils.mkdir_p(OUT_DIR)

IST_FILE = "#{OUT_DIR}/IST-ZUSTAND_GATEWAY-B_NODE7.md"
INV_FILE = "#{OUT_DIR}/ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md"
CFG_FILE = "#{OUT_DIR}/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md"
ENV_FILE = "#{OUT_DIR}/ENV-STATUS_GATEWAY-B_NODE7.md"
RUN_FILE = "#{OUT_DIR}/RUN-#{TS}.md"

OPENCLAW_JSON = "#{BASE_DIR}/openclaw.json"
ENV_DOT = "#{BASE_DIR}/.env"
ENV_SYSTEMD = "#{BASE_DIR}/gateway.systemd.env"
VSCODE_DIR = "#{BASE_DIR}/.vscode"

def safe_execute(command)
  stdout, stderr, status = Open3.capture3(command)
  status.success? ? stdout.strip : ""
rescue
  ""
end

def get_os_pretty_name
  if File.exist?("/etc/os-release")
    File.readlines("/etc/os-release").each do |line|
      if line.start_with?("PRETTY_NAME=")
        return line.split("=", 2)[1].strip.gsub('"', '')
      end
    end
  end
  ""
rescue
  ""
end

HOSTNAME_FQDN = Socket.gethostbyname(Socket.gethostname).first rescue Socket.gethostname
HOSTNAME_SHORT = Socket.gethostname
ARCH = safe_execute("uname -m")
KERNEL = safe_execute("uname -r")
OS_PRETTY = get_os_pretty_name
IPV4_ALL = safe_execute("hostname -I").split.join(" ") rescue ""
PUBLIC_IP = ""
TAILSCALE_IP = ""

begin
  uri = URI("http://ifconfig.me")
  req = Net::HTTP.new(uri.host, uri.port)
  req.open_timeout = 4
  req.read_timeout = 4
  res = req.get(uri.path)
  PUBLIC_IP = res.body.strip if res.code == "200"
rescue
  PUBLIC_IP = "(nicht ermittelt)"
end

TAILSCALE_IP = safe_execute("tailscale ip -4").lines.first&.strip || "(nicht ermittelt)"

OPENCLAW_VER = safe_execute("openclaw --version")
NODE_VER = safe_execute("node -v")

PUBLIC_IP = "(nicht ermittelt)" if PUBLIC_IP.empty?
TAILSCALE_IP = "(nicht ermittelt)" if TAILSCALE_IP.empty?
OPENCLAW_VER = "(nicht ermittelt)" if OPENCLAW_VER.empty?
NODE_VER = "(nicht ermittelt)" if NODE_VER.empty?

ist_content = <<~EOF
  # IST-Zustand: Gateway B / Node 7

  Stand (lokal): #{NOW_LOCAL}  
  Stand (UTC): #{NOW_UTC}

  ## 1) Identität & System

  - Gateway: **B**
  - Node: **7**
  - Hostname (short): `#{HOSTNAME_SHORT}`
  - Hostname (FQDN): `#{HOSTNAME_FQDN}`
  - Architektur: `#{ARCH}`
  - Kernel: `#{KERNEL}`
  - OS: `#{OS_PRETTY}`
  - IPv4 (lokal): `#{IPV4_ALL}`
  - Public IPv4: `#{PUBLIC_IP}`
  - Tailscale IPv4: `#{TAILSCALE_IP}`
  - OpenClaw Version: `#{OPENCLAW_VER}`
  - Node.js Version: `#{NODE_VER}`

  ## 2) Arbeitsverzeichnisse

  - Basis: `#{BASE_DIR}`
  - Funktionell VSCode: `#{VSCODE_DIR}`
  - Workspace Doku: `#{OUT_DIR}`

  ## 3) Kernartefakte (Existenz)

  - `#{OPENCLAW_JSON}`: #{File.exist?(OPENCLAW_JSON) ? "vorhanden" : "fehlt"}
  - `#{ENV_DOT}`: #{File.exist?(ENV_DOT) ? "vorhanden" : "fehlt"}
  - `#{ENV_SYSTEMD}`: #{File.exist?(ENV_SYSTEMD) ? "vorhanden" : "fehlt"}
  - `#{BASE_DIR}/plugins/installs.json`: #{File.exist?("#{BASE_DIR}/plugins/installs.json") ? "vorhanden" : "fehlt"}
  - `#{BASE_DIR}/plugin-skills`: #{File.directory?("#{BASE_DIR}/plugin-skills") ? "vorhanden" : "fehlt"}

  ## 4) Hinweis

  Diese Datei wird bei jedem Lauf neu geschrieben.
  Zusätzlich wird ein Laufprotokoll als `RUN-*.md` erzeugt.
EOF

File.write(IST_FILE, ist_content)

inv_content = []
inv_content << "# Artefakt-Inventar: Gateway B / Node 7"
inv_content << ""
inv_content << "Stand: #{NOW_LOCAL}"
inv_content << ""
inv_content << "## Top-Level in ~/.openclaw"
inv_content << ""
inv_content << '```text'
begin
  Dir.entries(BASE_DIR).sort.each do |entry|
    next if entry.start_with?(".")
    inv_content << entry
  end
rescue
  inv_content << "Fehler beim Lesen des Verzeichnisses"
end
inv_content << '```'
inv_content << ""
inv_content << "## ~/.openclaw/.vscode"
inv_content << ""
inv_content << '```text'
if File.directory?(VSCODE_DIR)
  begin
    Dir.entries(VSCODE_DIR).sort.each do |entry|
      next if entry == "." || entry == ".."
      full_path = File.join(VSCODE_DIR, entry)
      stat = File.stat(full_path)
      permissions = "%o" % (stat.mode & 0777)
      inv_content << "#{stat.ftype == 'directory' ? 'd' : '-'}#{permissions.rjust(4, '0')} #{stat.size.to_s.rjust(10)} #{entry}"
    end
  rescue
    inv_content << "Fehler beim Lesen des .vscode Verzeichnisses"
  end
else
  inv_content << "(nicht vorhanden)"
end
inv_content << '```'
inv_content << ""
inv_content << "## plugin-skills/"
inv_content << ""
inv_content << '```text'
if File.directory?("#{BASE_DIR}/plugin-skills")
  begin
    Dir.entries("#{BASE_DIR}/plugin-skills").sort.each do |entry|
      next if entry == "." || entry == ".."
      inv_content << entry
    end
  rescue
    inv_content << "Fehler beim Lesen des plugin-skills Verzeichnisses"
  end
else
  inv_content << "(nicht vorhanden)"
end
inv_content << '```'
inv_content << ""
inv_content << "## openclaw.json Backups"
inv_content << ""
inv_content << '```text'
begin
  backups = Dir.glob("#{BASE_DIR}/openclaw.json.bak*").sort
  if backups.empty?
    inv_content << "(keine gefunden)"
  else
    backups.each { |backup| inv_content << File.basename(backup) }
  end
rescue
  inv_content << "Fehler beim Suchen von Backups"
end
inv_content << '```'

File.write(INV_FILE, inv_content.join("\n"))

cfg_content = []
cfg_content << "# OpenClaw Config Snapshot: Gateway B / Node 7"
cfg_content << ""
cfg_content << "Stand: #{NOW_LOCAL}"
cfg_content << ""
cfg_content << "## Schlüsselpositionen (grep)"
cfg_content << ""
cfg_content << '```text'
if File.exist?(OPENCLAW_JSON)
  begin
    lines = File.readlines(OPENCLAW_JSON)
    lines.each_with_index do |line, index|
      if line =~ /"gateway"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"/
        cfg_content << "#{index + 1}: #{line.rstrip}"
      end
    end
  rescue
    cfg_content << "Fehler beim Lesen von openclaw.json"
  end
else
  cfg_content << "openclaw.json fehlt"
end
cfg_content << '```'
cfg_content << ""
cfg_content << "## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)"
cfg_content << ""
cfg_content << '```json'
if File.exist?(OPENCLAW_JSON)
  begin
    lines = File.readlines(OPENCLAW_JSON)
    start_line = [579, 0].max
    end_line = [779, lines.length - 1].min
    (start_line..end_line).each do |i|
      cfg_content << lines[i].rstrip if i < lines.length
    end
  rescue
    cfg_content << "{ \"error\": \"Fehler beim Lesen von openclaw.json\" }"
  end
else
  cfg_content << "{ \"error\": \"openclaw.json fehlt\" }"
end
cfg_content << '```'

File.write(CFG_FILE, cfg_content.join("\n"))

env_content = []
env_content << "# ENV-Status: Gateway B / Node 7"
env_content << ""
env_content << "Stand: #{NOW_LOCAL}"
env_content << ""
env_content << "## Dateien"
env_content << ""
env_content << '```text'
begin
  [ENV_DOT, ENV_SYSTEMD].each do |file|
    if File.exist?(file)
      stat = File.stat(file)
      permissions = "%o" % (stat.mode & 0777)
      env_content << "#{stat.ftype == 'directory' ? 'd' : '-'}#{permissions.rjust(4, '0')} #{stat.size.to_s.rjust(10)} #{File.basename(file)}"
    end
  end
rescue
  # Ignoriere Fehler
end
env_content << '```'
env_content << ""
env_content << "## .env (vollständig, ungefiltert)"
env_content << ""
env_content << '```dotenv'
if File.exist?(ENV_DOT)
  begin
    File.readlines(ENV_DOT).each { |line| env_content << line.rstrip }
  rescue
    env_content << "# Fehler beim Lesen von .env"
  end
else
  env_content << "# .env fehlt"
end
env_content << '```'
env_content << ""
env_content << "## gateway.systemd.env (vollständig, ungefiltert)"
env_content << ""
env_content << '```dotenv'
if File.exist?(ENV_SYSTEMD)
  begin
    File.readlines(ENV_SYSTEMD).each { |line| env_content << line.rstrip }
  rescue
    env_content << "# Fehler beim Lesen von gateway.systemd.env"
  end
else
  env_content << "# gateway.systemd.env fehlt"
end
env_content << '```'

File.write(ENV_FILE, env_content.join("\n"))

run_content = <<~EOF
  # Laufprotokoll Gateway B / Node 7

  - Zeit (lokal): #{NOW_LOCAL}
  - Zeit (UTC): #{NOW_UTC}
  - Script: #{__FILE__}

  ## Erzeugte Dateien

  - #{File.basename(IST_FILE)}
  - #{File.basename(INV_FILE)}
  - #{File.basename(CFG_FILE)}
  - #{File.basename(ENV_FILE)}

EOF

File.write(RUN_FILE, run_content)

puts "OK: IST-Zustand erfasst."
puts "Ausgabeordner: #{OUT_DIR}"
puts "Dateien:"
Dir.entries(OUT_DIR).sort.each do |entry|
  puts "- #{entry}" unless entry.start_with?(".")
end
