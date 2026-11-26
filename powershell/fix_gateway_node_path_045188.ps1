#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "1d5866bb9e55518b255af9d8212db43373bbf630055481b989bdcb35467abf4a", "source_sha256": "04518825207cd6ef771c2d840daf0a025f3144f4e384f1d13b46e016570f59df", "target_language": "powershell"}
# fix_gateway_node_path.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
# auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Backup der originalen Service-Datei
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item -Path "/etc/systemd/system/openclaw-gateway.service" -Destination "/etc/systemd/system/openclaw-gateway.service.backup-$timestamp"

# Korrektur des Node.js Pfads in der Service-Datei
# Annahme: Node.js ist unter /usr/bin/node verfügbar (wie von 'which node' gezeigt)
$content = Get-Content -Path "/etc/systemd/system/openclaw-gateway.service" -Raw
$newContent = $content -replace '/home/openclaw/.nvm/versions/node/v22.22.2/bin/node', '/usr/bin/node'
Set-Content -Path "/etc/systemd/system/openclaw-gateway.service" -Value $newContent

# Service neu laden und neu starten
systemctl daemon-reload
systemctl restart openclaw-gateway

# Status prüfen
systemctl status openclaw-gateway --no-pager
