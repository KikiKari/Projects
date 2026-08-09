#!/usr/bin/env python3
# ops-hub-heartbeat.js — portiert nach python
# Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
# auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import os
import datetime
import sys

# Aktualisiere den Statusbericht mit aktueller Zeit
status_path = os.path.join(os.path.dirname(__file__), '../docs/ops-hub/status.md')

def update_heartbeat():
    try:
        with open(status_path, 'r', encoding='utf-8') as file:
            content = file.read()
    except Exception as err:
        print(f'❌ Konnte status.md nicht lesen: {err}', file=sys.stderr)
        return

    now = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=1))).strftime('%d.%m.%Y, %H:%M:%S')
    updated = content.replace('(Letzter Heartbeat:) [^\n]*', f'Letzter Heartbeat: {now}', 1)

    try:
        with open(status_path, 'w', encoding='utf-8') as file:
            file.write(updated)
        print(f'✅ Heartbeat aktualisiert: {now}')
    except Exception as err:
        print(f'❌ Konnte status.md nicht schreiben: {err}', file=sys.stderr)

update_heartbeat()
