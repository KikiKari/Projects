#!/usr/bin/env python3
# channel_status.js — portiert nach python
# Quelle: javascript, Projects@abstractions:javascript/channel_status.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# channel_status.py — portiert nach javascript
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

"""
Channel Status Agent - Automatische Status-Updates
"""

import os
import subprocess
import json
import argparse
from datetime import datetime
from pathlib import Path

# Konfiguration
WORKSPACE = Path('/home/openclaw/.openclaw/workspace')
LOGS_DB = WORKSPACE / 'db/logs.db'
CONFIG_FILE = WORKSPACE / 'config/channel-status.json'
LOG_FILE = WORKSPACE / 'logs/channel-status.log'

def log(message, level="INFO"):
    """Logging"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{timestamp}] [{level}] {message}"
    print(entry)
    with open(LOG_FILE, 'a') as f:
        f.write(entry + '\n')

def get_system_status():
    """Sammelt System-Status"""
    status = {
        "timestamp": datetime.now().isoformat(),
        "nodes": {},
        "agents": {},
        "system": {}
    }
    
    # Node-Status (vereinfacht)
    nodes = {
        "node1": {"name": "Gateway", "status": "online"},
        "node2": {"name": "Worker", "status": "online"},
        "node3": {"name": "Relay", "status": "offline", "reason": "disk full"},
        "node5": {"name": "Redmi", "status": "intermittent"},
        "node7": {"name": "Docker", "status": "planned"}
    }
    status["nodes"] = nodes
    
    # Agent-Status aus Cron
    try:
        result = subprocess.run(['crontab', '-l'], capture_output=True, text=True, check=True)
        cron_lines = [line for line in result.stdout.split('\n') if line and not line.startswith('#')]
        status["agents"]["active_crons"] = len(cron_lines)
    except subprocess.CalledProcessError:
        status["agents"]["active_crons"] = "unknown"
    
    # System-Metriken
    try:
        # Disk usage
        df_result = subprocess.run(['df', '-h', '/'], capture_output=True, text=True, check=True)
        for line in df_result.stdout.split('\n'):
            if '/' in line and '%' in line:
                parts = line.strip().split()
                status["system"]["disk_used"] = parts[4]
                break
        
        # RAM usage
        free_result = subprocess.run(['free', '-h'], capture_output=True, text=True, check=True)
        for line in free_result.stdout.split('\n'):
            if 'Mem:' in line:
                parts = line.strip().split()
                status["system"]["ram_total"] = parts[1]
                status["system"]["ram_used"] = parts[2]
                break
    except subprocess.CalledProcessError:
        # Ignore errors
        pass
    
    return status

def format_daily_status(status):
    """Formatiert täglichen Status"""
    nodes = status["nodes"]
    online = len([n for n in nodes.values() if n["status"] == "online"])
    
    message = f"""📊 **Täglicher Status-Report**
🗓️ {datetime.now().strftime('%d.%m.%Y %H:%M')}

**🖥️ Nodes ({online}/5 online):**
"""
    
    for node_id, info in nodes.items():
        emoji = "🟢" if info["status"] == "online" else "🔴" if info["status"] == "offline" else "🟡"
        message += f"{emoji} {info['name']}: {info['status']}"
        if "reason" in info:
            message += f" ({info['reason']})"
        message += "\n"
    
    message += f"\n**🤖 Agents:**\n"
    message += f"Aktive Cron-Jobs: {status['agents']['active_crons']}\n"
    
    if "disk_used" in status["system"]:
        message += f"\n**💾 System:**\n"
        message += f"Disk: {status['system']['disk_used']} belegt\n"
        message += f"RAM: {status['system']['ram_used']} / {status['system']['ram_total']}\n"
    
    return message

def format_weekly_status(status):
    """Formatiert wöchentlichen Status"""
    now = datetime.now()
    week_number = now.isocalendar()[1]
    
    return f"""📈 **Wöchentlicher Report**
📅 Woche {week_number:02d} - {now.year}

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
"""

def send_to_channel(message, channel_type="telegram", channel_id="-1002381931352"):
    """Sendet Nachricht an Channel"""
    if channel_type == "telegram":
        # Nutze OpenClaw message tool
        cmd = ['openclaw', 'message', 'send', '--target', channel_id, '--message', message]
    else:
        log(f"Channel type {channel_type} not implemented", "WARN")
        return False
    
    try:
        subprocess.run(cmd, check=True, capture_output=True)
        log(f"Message sent to {channel_type} {channel_id}")
        return True
    except subprocess.CalledProcessError as e:
        log(f"Failed to send: {e}", "ERROR")
        return False

def main():
    """Hauptfunktion"""
    parser = argparse.ArgumentParser(description='Channel Status Agent')
    parser.add_argument('--type', choices=['daily', 'weekly', 'alert'], required=True,
                        help='Type of status update')
    parser.add_argument('--message', type=str, help='Alert message')
    parser.add_argument('--channel', type=str, default='-1002381931352',
                        help='Channel ID')
    parser.add_argument('--dry-run', action='store_true',
                        help='Show message without sending')
    
    args = parser.parse_args()
    
    log(f"Starting {args.type} status update")
    
    # Status sammeln
    status = get_system_status()
    
    # Message formatieren
    if args.type == 'daily':
        message = format_daily_status(status)
    elif args.type == 'weekly':
        message = format_weekly_status(status)
    elif args.type == 'alert':
        message = f"🚨 **ALERT**\n{args.message or 'Manual alert'}"
    
    # Senden oder Dry-Run
    if args.dry_run:
        print("\n--- DRY RUN ---")
        print(message)
        print("--- END ---")
    else:
        send_to_channel(message, "telegram", args.channel)
    
    log("Status update completed")

# Ensure log directory exists
LOG_FILE.parent.mkdir(parents=True, exist_ok=True)

if __name__ == "__main__":
    main()
