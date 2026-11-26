#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "58c04110eb2834fbb80f6da241ce08e0837adabdf8812fdb6ff107a587390eb8", "source_sha256": "04518825207cd6ef771c2d840daf0a025f3144f4e384f1d13b46e016570f59df", "target_language": "ruby"}
# fix_gateway_node_path.sh — portiert nach ruby
# Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
# auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'fileutils'
require 'time'

# Backup der originalen Service-Datei
service_file = '/etc/systemd/system/openclaw-gateway.service'
timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
backup_file = "/etc/systemd/system/openclaw-gateway.service.backup-#{timestamp}"

FileUtils.cp(service_file, backup_file)

# Korrektur des Node.js Pfads in der Service-Datei
# Annahme: Node.js ist unter /usr/bin/node verfügbar (wie von 'which node' gezeigt)
content = File.read(service_file)
updated_content = content.gsub('/home/openclaw/.nvm/versions/node/v22.22.2/bin/node', '/usr/bin/node')
File.write(service_file, updated_content)

# Service neu laden und neu starten
system('systemctl daemon-reload')
system('systemctl restart openclaw-gateway')

# Status prüfen
system('systemctl status openclaw-gateway --no-pager')
