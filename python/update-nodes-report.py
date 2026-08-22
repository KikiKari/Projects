#!/usr/bin/env python3
# update-nodes-report.js — portiert nach python
# Quelle: javascript, OpenClaw@gateway1:scripts/update-nodes-report.js
# auch in: OpenClaw@gateway2:scripts/update-nodes-report.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

import subprocess
import json
import os
from datetime import datetime
import pytz

# Pfade
DASHBOARD_PATH = os.path.join(os.path.dirname(__file__), '../dashboards/nodes-overview.md')

# Farbcodes für Konsole
C = {
    'green': '\033[32m',
    'yellow': '\033[33m',
    'red': '\033[31m',
    'blue': '\033[34m',
    'reset': '\033[0m'
}

def get_node_status():
    try:
        result = subprocess.run(['openclaw', 'nodes', 'status', '--json'], capture_output=True, text=True, check=True)
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"{C['red']}❌ Fehler beim Abrufen des Node-Status:{C['reset']}", e.stderr)
        return []
    except json.JSONDecodeError as e:
        print(f"{C['red']}❌ Fehler beim Parsen des JSON:{C['reset']}", str(e))
        return []

def update_dashboard(nodes):
    tz = pytz.timezone('Europe/Berlin')
    now = datetime.now(tz).strftime('%d.%m.%Y, %H:%M:%S')

    # Manuelle Ergänzung statischer Konfigurationen (da nicht alle Infos über CLI)
    node_config = {
        '1': {'name': 'Gateway',       'os': 'Ubuntu 22.04', 'ip': '152.53.145.65',   'wg': '10.10.0.1', 'tunnel': '–', 'mode': 'Gateway'},
        '2': {'name': 'Netcup Server', 'os': 'Ubuntu 22.04', 'ip': '78.46.123.10',  'wg': '10.10.0.2', 'tunnel': '–', 'mode': 'Node'},
        '3': {'name': 'xNetX VPS',     'os': 'Debian 11',    'ip': '5.45.105.20',   'wg': '–',        'tunnel': 'Port 18794', 'mode': 'Node'},
        '4': {'name': 'Webhosting',    'os': 'Shared Linux', 'ip': '–',              'wg': '–',        'tunnel': '–', 'mode': '–'},
        '5': {'name': 'Redmi Note 11', 'os': 'Android',      'ip': '–',              'wg': '10.10.0.5', 'tunnel': '–', 'mode': 'Node'},
        '6': {'name': 'Lenovo (Win)',  'os': 'Windows 11',   'ip': '–',              'wg': '–',        'tunnel': '–', 'mode': 'Node'}
    }

    rows = []
    for node_id, cfg in node_config.items():
        # Finde den entsprechenden Node in der Liste
        node = None
        for n in nodes:
            if n.get('nodeId') == node_id or (n.get('name') and cfg['name'].split(' ')[0] in n.get('name', '')):
                node = n
                break

        status_vpn = '✅' if node and node.get('status') == 'paired' else ('🔴' if node else '⚠️')
        status_ssh = '✅' if cfg['tunnel'] != '–' else '❌'
        
        if node_id in ['2', '3']:
            ssh_key = '❌ (Pending)'
        elif node_id == '1':
            ssh_key = 'Local (id_ed25519)'
        else:
            ssh_key = '❌'

        if node and 'lastSeen' in node:
            last_check = datetime.fromtimestamp(node['lastSeen']).strftime('%d.%m.%Y, %H:%M:%S')
        else:
            last_check = '–'

        row = f"| {node_id}    | {cfg['name']} | {cfg['os']} | {cfg['ip']} | {cfg['mode']}       | {cfg['wg']}             | {cfg['tunnel']} | {status_vpn} | {status_ssh} | {ssh_key} | {last_check} |"
        rows.append(row)

    content = f"""# Nodes Overview (Network Status)

| Node | Name          | OS           | IP             | Mode       | Primär WG IP       | Sekundär/SSH Tunnel | StatusVPN | StatusSSH | SSH Key (Deployed) | Letzter Check       |
|------|---------------|--------------|----------------|------------|--------------------|---------------------|-----------|-----------|---------------------|---------------------|
{'\n'.join(rows)}

> 💡 **Legende:** 
> - **Primär WG IP**: Die WireGuard-VPN-IP des Nodes
> - **Sekundär/SSH Tunnel**: Fallback-Mechanismus (z. B. Reverse-Tunnel)
> - **StatusVPN**: Verbunden über OpenClaw/WireGuard
> - **StatusSSH**: SSH-Zugriff via Reverse-Tunnel aktiv
> - **SSH Key (Deployed)**: Zeigt an, ob der Gateway-Schlüssel (`id_ed25519`) auf dem Ziel bereitgestellt ist
> - Letzter Stand: **{now} CET**

*Größe: ~1.8 KB | Automatisch aktualisiert via `update-nodes-report.js`*
"""

    try:
        with open(DASHBOARD_PATH, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"{C['green']}✅ Dashboard aktualisiert:{C['reset']} {DASHBOARD_PATH}")
    except Exception as e:
        print(f"{C['red']}❌ Fehler beim Schreiben der Datei:{C['reset']}", str(e))

# Hauptausführung
print(f"{C['blue']}🔄 Aktualisiere Nodes-Übersicht...{C['reset']}")
nodes = get_node_status()
update_dashboard(nodes)
