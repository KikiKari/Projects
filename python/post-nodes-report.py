#!/usr/bin/env python3
# post-nodes-report.js — portiert nach python
# Quelle: javascript, OpenClaw@gateway1:scripts/post-nodes-report.js
# auch in: OpenClaw@gateway2:scripts/post-nodes-report.js
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import os
import json
import subprocess
from datetime import datetime

# Pfade
DASHBOARD_PATH = os.path.join(os.path.dirname(__file__), '../dashboards/nodes-overview.md')
REPORT_LOG = os.path.join(os.path.dirname(__file__), '../logs/nodes-report.log')

# Farbcodes
C = {
    'green': '\033[32m',
    'yellow': '\033[33m',
    'red': '\033[31m',
    'reset': '\033[0m'
}

def post_report():
    try:
        with open(DASHBOARD_PATH, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as err:
        print(f"{C['red']}❌ Fehler beim Lesen der Dashboard-Datei:{C['reset']}", str(err))
        return

    # Nachricht über OpenClaw message senden
    # JSON-kodieren und neue Zeilen escapen
    json_content = json.dumps(content)
    escaped_content = json_content.replace('\\n', '\\\\n').replace('"', '\\"')
    message_cmd = f'openclaw message send --target=main --message "{escaped_content}"'

    try:
        subprocess.run(message_cmd, shell=True, check=True, capture_output=True)
        print(f"{C['green']}✅ Report erfolgreich im 'main'-Channel gepostet.{C['reset']}")
        with open(REPORT_LOG, 'a', encoding='utf-8') as f:
            f.write(f"[{datetime.utcnow().isoformat()}] Report posted.\n")
    except subprocess.CalledProcessError as err:
        error_msg = err.stderr.decode('utf-8') if err.stderr else str(err)
        print(f"{C['red']}❌ Fehler beim Senden der Nachricht:{C['reset']}", error_msg)
        with open(REPORT_LOG, 'a', encoding='utf-8') as f:
            f.write(f"[{datetime.utcnow().isoformat()}] Failed to post: {error_msg}\n")
    except Exception as err:
        print(f"{C['red']}❌ Fehler beim Senden der Nachricht:{C['reset']}", str(err))
        with open(REPORT_LOG, 'a', encoding='utf-8') as f:
            f.write(f"[{datetime.utcnow().isoformat()}] Failed to post: {str(err)}\n")

# Hauptausführung
print(f"{C['yellow']}📤 Sende Nodes-Übersicht in 'main'...{C['reset']}")
post_report()
