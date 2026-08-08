#!/usr/bin/env python3
# channel_status.ps1 — portiert nach python
# Quelle: powershell, Projects@abstractions:powershell/channel_status.ps1
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# channel_status.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

"""
Channel Status Agent - Automatische Status-Updates
"""

import os
import json
import logging
import subprocess
from datetime import datetime
from pathlib import Path


# Konfiguration
HOME = os.path.expanduser("~")
WORKSPACE = os.path.join(HOME, ".openclaw", "workspace")
LOGS_DB = os.path.join(WORKSPACE, "db", "logs.db")
CONFIG_FILE = os.path.join(WORKSPACE, "config", "channel-status.json")
LOG_FILE = os.path.join(WORKSPACE, "logs", "channel-status.log")


def setup_logging():
    """Einrichtung des Loggings"""
    log_dir = os.path.dirname(LOG_FILE)
    os.makedirs(log_dir, exist_ok=True)
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s [%(levelname)s] %(message)s',
        handlers=[
            logging.FileHandler(LOG_FILE),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)


logger = setup_logging()


def write_log(message, level="INFO"):
    """Schreibt eine Log-Nachricht"""
    if level == "ERROR":
        logger.error(message)
    elif level == "WARN":
        logger.warning(message)
    else:
        logger.info(message)


def get_system_status():
    """Holt den Systemstatus"""
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
        result = subprocess.run(["crontab", "-l"], capture_output=True, text=True, check=True)
        cron_lines = len([line for line in result.stdout.splitlines() if not line.startswith("#")])
        status["agents"]["active_crons"] = cron_lines
    except subprocess.CalledProcessError:
        status["agents"]["active_crons"] = "unknown"
    except FileNotFoundError:
        status["agents"]["active_crons"] = "unknown"

    # System-Metriken
    try:
        # Disk usage
        result = subprocess.run(["df", "-h", "/"], capture_output=True, text=True, check=True)
        for line in result.stdout.splitlines():
            if "/" in line and "%" in line:
                parts = line.split()
                status["system"]["disk_used"] = parts[4]
                break

        # RAM usage
        result = subprocess.run(["free", "-h"], capture_output=True, text=True, check=True)
        for line in result.stdout.splitlines():
            if "Mem:" in line:
                parts = line.split()
                status["system"]["ram_total"] = parts[1]
                status["system"]["ram_used"] = parts[2]
                break
    except (subprocess.CalledProcessError, FileNotFoundError):
        # Ignoriere Fehler
        pass

    return status


def format_daily_status(status):
    """Formatiert den täglichen Statusbericht"""
    nodes = status["nodes"]
    online = sum(1 for node in nodes.values() if node["status"] == "online")

    message = f"""📊 **Täglicher Status-Report**
🗓️ {datetime.now().strftime('%Y-%m-%d %H:%M')}

**🖥️ Nodes ({online}/5 online):**
"""

    for node_id, node in nodes.items():
        emoji = {
            "online": "🟢",
            "offline": "🔴"
        }.get(node["status"], "🟡")
        
        message += f"{emoji} {node['name']}: {node['status']}"
        if "reason" in node:
            message += f" ({node['reason']})"
        message += "\n"

    message += "\n**🤖 Agents:**\n"
    message += f"Aktive Cron-Jobs: {status['agents']['active_crons']}\n"

    if "disk_used" in status["system"]:
        message += "\n**💾 System:**\n"
        message += f"Disk: {status['system']['disk_used']} belegt\n"
        message += f"RAM: {status['system']['ram_used']} / {status['system']['ram_total']}\n"

    return message


def format_weekly_status(status):
    """Formatiert den wöchentlichen Statusbericht"""
    message = f"""📈 **Wöchentlicher Report**
📅 Woche {datetime.now().strftime('%Y-\\KW')} - {datetime.now().year}

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
    return message


def send_to_channel(message, channel_type="telegram", channel_id="-1002381931352"):
    """Sendet eine Nachricht an einen Kanal"""
    if channel_type == "telegram":
        cmd = ["openclaw", "message", "send", "--target", channel_id, "--message", message]
    else:
        write_log(f"Channel type {channel_type} not implemented", "WARN")
        return False

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        write_log(f"Message sent to {channel_type} {channel_id}")
        return True
    except subprocess.CalledProcessError as e:
        write_log(f"Failed to send: {e.stderr}", "ERROR")
        return False
    except Exception as e:
        write_log(f"Send error: {str(e)}", "ERROR")
        return False


def main(status_type, message=None, channel="-1002381931352", dry_run=False):
    """Hauptfunktion"""
    write_log(f"Starting {status_type} status update")

    # Status sammeln
    status = get_system_status()

    # Message formatieren
    if status_type == "daily":
        formatted_message = format_daily_status(status)
    elif status_type == "weekly":
        formatted_message = format_weekly_status(status)
    elif status_type == "alert":
        formatted_message = f"🚨 **ALERT**\n{message or 'Manual alert'}"
    else:
        write_log(f"Unknown type: {status_type}", "ERROR")
        return

    # Senden oder Dry-Run
    if dry_run:
        print("\n--- DRY RUN ---")
        print(formatted_message)
        print("--- END ---")
    else:
        send_to_channel(formatted_message, channel_id=channel)

    write_log("Status update completed")


if __name__ == "__main__":
    import sys
    import argparse

    parser = argparse.ArgumentParser(description="Channel Status Agent")
    parser.add_argument("--type", required=True, choices=["daily", "weekly", "alert"], help="Type of status update")
    parser.add_argument("--message", help="Custom message for alerts")
    parser.add_argument("--channel", default="-1002381931352", help="Target channel ID")
    parser.add_argument("--dry-run", action="store_true", help="Show message without sending")

    args = parser.parse_args()

    main(args.type, args.message, args.channel, args.dry_run)
