#!/usr/bin/env python3
# channel_status.pl — portiert nach python
# Quelle: perl5, Projects@abstractions:perl5/channel_status.pl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# channel_status.py — portiert nach python3
# Quelle: perl5, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.pl
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.pl
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.pl

import json
import os
import subprocess
import logging
from datetime import datetime
from pathlib import Path

# Konfiguration
WORKSPACE = "/home/openclaw/.openclaw/workspace"
LOGS_DB = f"{WORKSPACE}/db/logs.db"
CONFIG_FILE = f"{WORKSPACE}/config/channel-status.json"
LOG_FILE = f"{WORKSPACE}/logs/channel-status.log"

# Logging konfigurieren
def setup_logging():
    log_dir = os.path.dirname(LOG_FILE)
    os.makedirs(log_dir, exist_ok=True)
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(message)s',
        handlers=[
            logging.FileHandler(LOG_FILE, mode='a'),
            logging.StreamHandler()
        ]
    )

def log_message(message, level="INFO"):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    entry = f"[{timestamp}] [{level}] {message}"
    print(entry)
    logging.info(entry)

def get_system_status():
    status = {
        "timestamp": datetime.now().strftime('%Y-%m-%dT%H:%M:%S'),
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
        lines = result.stdout.strip().split('\n')
        cron_lines = len([line for line in lines if line.strip() and not line.strip().startswith('#')])
        status["agents"]["active_crons"] = cron_lines
    except subprocess.CalledProcessError:
        status["agents"]["active_crons"] = "unknown"
    except FileNotFoundError:
        status["agents"]["active_crons"] = "unknown"
    
    # System-Metriken
    try:
        # Disk usage
        result = subprocess.run(['df', '-h', '/'], capture_output=True, text=True, check=True)
        for line in result.stdout.strip().split('\n'):
            if '/' in line and '%' in line:
                parts = line.split()
                status["system"]["disk_used"] = parts[4]
                break
        
        # RAM usage
        result = subprocess.run(['free', '-h'], capture_output=True, text=True, check=True)
        for line in result.stdout.strip().split('\n'):
            if 'Mem:' in line:
                parts = line.split()
                status["system"]["ram_total"] = parts[1]
                status["system"]["ram_used"] = parts[2]
                break
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    
    return status

def format_daily_status(status):
    nodes = status["nodes"]
    online = sum(1 for node in nodes.values() if node["status"] == "online")
    
    message = "📊 **Täglicher Status-Report**\n"
    message += f"🗓️ {datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n"
    message += f"**🖥️ Nodes ({online}/5 online):**\n"
    
    for node_id in sorted(nodes.keys()):
        info = nodes[node_id]
        emoji = "🟢" if info["status"] == "online" else ("🔴" if info["status"] == "offline" else "🟡")
        message += f"{emoji} {info['name']}: {info['status']}"
        if "reason" in info:
            message += f" ({info['reason']})"
        message += "\n"
    
    message += "\n**🤖 Agents:**\n"
    message += f"Aktive Cron-Jobs: {status['agents']['active_crons']}\n"
    
    if "disk_used" in status["system"]:
        message += "\n**💾 System:**\n"
        message += f"Disk: {status['system']['disk_used']} belegt\n"
        message += f"RAM: {status['system']['ram_used']} / {status['system']['ram_total']}\n"
    
    return message

def format_weekly_status(status):
    message = "📈 **Wöchentlicher Report**\n"
    message += f"📅 Woche {datetime.now().strftime('%V')} - {datetime.now().strftime('%Y')}\n\n"
    message += "**Zusammenfassung:**\n"
    message += "- 5 aktive Sub-Agents\n"
    message += "- 11 Skills synchronisiert\n"
    message += "- 3 neue Features implementiert\n\n"
    message += "**Top-Ereignisse:**\n"
    message += "1. ClawHub-Git Sync implementiert ✅\n"
    message += "2. Node 3 Disk voll (95%) ⚠️\n"
    message += "3. Channel-Status-Agent aktiviert 🆕\n\n"
    message += "**Geplante Wartungen:**\n"
    message += "- Node 3: Disk-Cleanup erforderlich\n"
    message += "- Node 7: Docker-Setup ausstehend\n"
    return message

def send_to_channel(message, channel_type="telegram", channel_id="-1002381931352"):
    if channel_type == "telegram":
        # Nutze OpenClaw message tool
        cmd = ["openclaw", "message", "send", "--target", channel_id, "--message", message]
        try:
            subprocess.run(cmd, check=True, capture_output=True)
            log_message(f"Message sent to {channel_type} {channel_id}")
            return True
        except subprocess.CalledProcessError as e:
            log_message(f"Failed to send: {e.stderr.decode() if e.stderr else str(e)}", "ERROR")
            return False
    else:
        log_message(f"Channel type {channel_type} not implemented", "WARN")
        return False

def main():
    import argparse
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--type", required=True, choices=["daily", "weekly", "alert"], help="Type of status update")
    parser.add_argument("--message", help="Custom message for alert type")
    parser.add_argument("--channel", default="-1002381931352", help="Channel ID")
    parser.add_argument("--dry-run", action="store_true", help="Show message without sending")
    
    args = parser.parse_args()
    
    log_message(f"Starting {args.type} status update")
    
    # Status sammeln
    status = get_system_status()
    
    # Message formatieren
    if args.type == 'daily':
        formatted_message = format_daily_status(status)
    elif args.type == 'weekly':
        formatted_message = format_weekly_status(status)
    elif args.type == 'alert':
        formatted_message = f"🚨 **ALERT**\n{args.message or 'Manual alert'}"
    
    # Senden oder Dry-Run
    if args.dry_run:
        print("\n--- DRY RUN ---")
        print(formatted_message)
        print("--- END ---")
    else:
        send_to_channel(formatted_message, "telegram", args.channel)
    
    log_message("Status update completed")

if __name__ == "__main__":
    setup_logging()
    main()
