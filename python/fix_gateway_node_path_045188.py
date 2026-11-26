#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "0e61a41b8c609ceed618991cd23163219f1e59a36dfd1b94909fdd9e990bdf11", "source_sha256": "04518825207cd6ef771c2d840daf0a025f3144f4e384f1d13b46e016570f59df", "target_language": "python"}
# fix_gateway_node_path.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
# auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import shutil
import subprocess
import datetime
import os

# Backup der originalen Service-Datei
service_file = "/etc/systemd/system/openclaw-gateway.service"
timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
backup_file = f"/etc/systemd/system/openclaw-gateway.service.backup-{timestamp}"
shutil.copy2(service_file, backup_file)

# Korrektur des Node.js Pfads in der Service-Datei
# Annahme: Node.js ist unter /usr/bin/node verfügbar (wie von 'which node' gezeigt)
with open(service_file, 'r') as file:
    content = file.read()

content = content.replace('/home/openclaw/.nvm/versions/node/v22.22.2/bin/node', '/usr/bin/node')

with open(service_file, 'w') as file:
    file.write(content)

# Service neu laden und neu starten
subprocess.run(['systemctl', 'daemon-reload'])
subprocess.run(['systemctl', 'restart', 'openclaw-gateway'])

# Status prüfen
subprocess.run(['systemctl', 'status', 'openclaw-gateway', '--no-pager'])
