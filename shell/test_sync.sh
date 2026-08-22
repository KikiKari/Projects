#!/bin/bash
# test_sync.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:scripts/test_sync.py
# auch in: OpenClaw@gateway2:scripts/test_sync.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Test für Sync-Script

# Füge das Verzeichnis zum PYTHONPATH hinzu
export PYTHONPATH="${PYTHONPATH:-}:/home/openclaw/.openclaw/workspace/scripts"

# Test: db-maintainer ClawHub → Git (DRY-RUN)
echo "=== TEST: db-maintainer sync (DRY-RUN) ==="
skill="db-maintainer"

# Führe den Python-Code aus und speichere das Ergebnis
if python3 -c "
import sys
from sync_clawhub_git import sync_to_git
result = sync_to_git('$skill', dry_run=True)
print(f'Result: {\"SUCCESS\" if result else \"FAILED\"}')
sys.exit(0 if result else 1)
"; then
    echo "Result: SUCCESS"
else
    echo "Result: FAILED"
fi

echo -e "\n=== LOG-Inhalt ==="
# Zeige den Log-Inhalt an
if [[ -f "/home/openclaw/.openclaw/workspace/logs/sync.log" ]]; then
    cat "/home/openclaw/.openclaw/workspace/logs/sync.log"
else
    echo "Log-Datei nicht gefunden"
fi
