#!/usr/bin/env python3
# channel_status.sh — portiert nach python
# Quelle: shell, Projects@abstractions:shell/channel_status.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# channel_status.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import json
import subprocess
import argparse
from datetime import datetime
import shutil


# Channel Status Agent - Automatische Status-Updates

# Konfiguration
WORKSPACE = "/home/openclaw/.openclaw/workspace"
LOGS_DB = f"{WORKSPACE}/db/logs.db"
CONFIG_FILE = f"{WORKSPACE}/config/channel-status.json"
LOG_FILE = f"{WORKSPACE}/logs/channel-status.log"


# Logging
def log(message, level="INFO"):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    entry = f"[{timestamp}] [{level}] {message}"
    print(entry)
    with open(LOG_FILE, "a") as f:
        f.write(entry + "\n")


# Sammelt System-Status
def get_system_status():
    status_dict = {
        "timestamp": datetime.now().isoformat(),
        "nodes": {
            "node1": {"name": "Gateway", "status": "online"},
            "node2": {"name": "Worker", "status": "online"},
            "node3": {"name": "Relay", "status": "offline", "reason": "disk full"},
            "node5": {"name": "Redmi", "status": "intermittent"},
            "node7": {"name": "Docker", "status": "planned"}
        },
        "agents": {},
        "system": {}
    }

    # Agent-Status aus Cron
    try:
        cron_output = subprocess.run(["crontab", "-l"], capture_output=True, text=True)
        if cron_output.returncode == 0:
            cron_lines = len([line for line in cron_output.stdout.splitlines() if not line.startswith("#")])
        else:
            cron_lines = "unknown"
    except Exception:
        cron_lines = "unknown"
    status_dict["agents"]["active_crons"] = str(cron_lines)

    # System-Metriken
    try:
        df_output = subprocess.check_output(["df", "-h", "/"], text=True)
        disk_used = df_output.splitlines()[1].split()[4]
        status_dict["system"]["disk_used"] = disk_used
    except Exception as e:
        log(f"Fehler beim Abrufen der Disk-Nutzung: {e}", "WARN")

    try:
        free_output = subprocess.check_output(["free", "-h"], text=True)
        ram_line = free_output.splitlines()[1]
        ram_parts = ram_line.split()
        ram_total = ram_parts[1]
        ram_used = ram_parts[2]
        status_dict["system"]["ram_total"] = ram_total
        status_dict["system"]["ram_used"] = ram_used
    except Exception as e:
        log(f"Fehler beim Abrufen der RAM-Nutzung: {e}", "WARN")

    return json.dumps(status_dict)


# Formatiert täglichen Status
def format_daily_status(status_json_str):
    status_json = json.loads(status_json_str)
    message = "📊 **Täglicher Status-Report**\n"
    message += datetime.now().strftime('🗓️ %Y-%m-%d %H:%M') + "\n\n"

    message += "**🖥️ Nodes (**"
    online_nodes = sum(1 for node in status_json["nodes"].values() if node["status"] == "online")
    message += f"{online_nodes}/5 online):\n"

    for node_id, node_data in status_json["nodes"].items():
        name = node_data["name"]
        status = node_data["status"]
        reason = node_data.get("reason", "")

        if status == "online":
            emoji = "🟢"
        elif status == "offline":
            emoji = "🔴"
        else:
            emoji = "🟡"

        message += f"{emoji} {name}: {status}"
        if reason and reason != "null":
            message += f" ({reason})"
        message += "\n"

    message += "\n**🤖 Agents:**\n"
    active_crons = status_json["agents"].get("active_crons", "unknown")
    message += f"Aktive Cron-Jobs: {active_crons}\n"

    if "disk_used" in status_json["system"]:
        message += "\n**💾 System:**\n"
        disk_used = status_json["system"]["disk_used"]
        ram_used = status_json["system"]["ram_used"]
        ram_total = status_json["system"]["ram_total"]
        message += f"Disk: {disk_used} belegt\n"
        message += f"RAM: {ram_used} / {ram_total}\n"

    return message


# Formatiert wöchentlichen Status
def format_weekly_status():
    message = "📈 **Wöchentlicher Report**\n"
    message += datetime.now().strftime('📅 Woche %V - %Y') + "\n\n"

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


# Sendet Nachricht an Channel
def send_to_channel(message, channel_type="telegram", channel_id="-1002381931352"):
    if channel_type == "telegram":
        cmd = ["openclaw", "message", "send", "--target", channel_id, "--message", message]
    else:
        log(f"Channel type {channel_type} not implemented", "WARN")
        return False

    try:
        result = subprocess.run(cmd, check=True)
        log(f"Message sent to {channel_type} {channel_id}")
        return True
    except subprocess.CalledProcessError:
        log("Failed to send message", "ERROR")
        return False


# Hauptfunktion
def main():
    parser = argparse.ArgumentParser(description="Channel Status Agent")
    parser.add_argument("--type", required=True, help="Art des Status (daily, weekly, alert)")
    parser.add_argument("--message", help="Nachricht für Alerts")
    parser.add_argument("--channel", default="-1002381931352", help="Zielkanal-ID")
    parser.add_argument("--dry-run", action="store_true", help="Nur anzeigen, nicht senden")

    args = parser.parse_args()

    log(f"Starting {args.type} status update")

    # Status sammeln
    status = get_system_status()

    # Message formatieren
    if args.type == "daily":
        formatted_message = format_daily_status(status)
    elif args.type == "weekly":
        formatted_message = format_weekly_status()
    elif args.type == "alert":
        formatted_message = "🚨 **ALERT**\n" + (args.message or "Manual alert")
    else:
        print(f"Unbekannter Typ: {args.type}", file=sys.stderr)
        sys.exit(1)

    # Senden oder Dry-Run
    if args.dry_run:
        print("\n--- DRY RUN ---")
        print(formatted_message)
        print("--- END ---\n")
    else:
        send_to_channel(formatted_message, "telegram", args.channel)

    log("Status update completed")


# Sicherstellen, dass das Log-Verzeichnis existiert
os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

# Hauptfunktion aufrufen
if __name__ == "__main__":
    main()
