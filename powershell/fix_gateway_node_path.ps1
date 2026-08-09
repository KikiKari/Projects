#!/usr/bin/env pwsh
# fix_gateway_node_path.sh — portiert nach powershell
# Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
# auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Backup der originalen Service-Datei
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item -Path "/etc/systemd/system/openclaw-gateway.service" -Destination "/etc/systemd/system/openclaw-gateway.service.backup-$timestamp"

# Korrektur des Node.js Pfads in der Service-Datei
# Annahme: Node.js ist unter /usr/bin/node verfügbar (wie von 'which node' gezeigt)
$serviceFile = "/etc/systemd/system/openclaw-gateway.service"
$content = Get-Content -Path $serviceFile
$updatedContent = $content -replace '/home/openclaw/.nvm/versions/node/v22.22.2/bin/node', '/usr/bin/node'
Set-Content -Path $serviceFile -Value $updatedContent

# Service neu laden und neu starten
systemctl daemon-reload
systemctl restart openclaw-gateway

# Status prüfen
systemctl status openclaw-gateway --no-pager
