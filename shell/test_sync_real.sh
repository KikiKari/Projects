#!/usr/bin/env bash
# test_sync_real.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:scripts/test_sync_real.py
# auch in: OpenClaw@gateway2:scripts/test_sync_real.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Test echte Synchronisation

# Füge das Verzeichnis zum PYTHONPATH hinzu und führe das Python-Skript aus
export PYTHONPATH="/home/openclaw/.openclaw/workspace/scripts:$PYTHONPATH"

echo "=== TEST: db-maintainer sync (REAL) ==="

# Führe die Python-Funktion über ein Inline-Python-Skript aus
python3 -c "
import sys
sys.path.append('/home/openclaw/.openclaw/workspace/scripts')
from sync_clawhub_git import sync_to_git

# Test: db-maintainer ClawHub → Git (ECHT)
skill = 'db-maintainer'
result = sync_to_git(skill, dry_run=False)
print(f'Result: {\"SUCCESS\" if result else \"FAILED\"}')
" > /tmp/sync_result.txt

cat /tmp/sync_result.txt

# Prüfe Ergebnis
target="/home/openclaw/.openclaw/workspace/git/skills/db-maintainer"
if [ -d "$target" ]; then
    echo -e "\n✅ Git-Repo erstellt: $target"
    # Baumstruktur des Verzeichnisses anzeigen
    find "$target" -type d -print | sort | while read -r dir; do
        indent=$(echo "$dir" | sed "s|$target||g" | grep -o "/" | wc -l)
        spaces=$(printf ' %.0s' $(seq 1 $((indent * 2))))
        basename_dir=$(basename "$dir")
        if [ "$dir" != "$target" ]; then
            echo "${spaces}${basename_dir}/"
        else
            echo "${basename_dir}/"
        fi
    done
    
    find "$target" -type f -print | sort | while read -r file; do
        indent=$(echo "$file" | sed "s|$target||g" | grep -o "/" | wc -l)
        spaces=$(printf ' %.0s' $(seq 1 $((indent * 2))))
        basename_file=$(basename "$file")
        echo "${spaces}${basename_file}"
    done
fi

# Temporäre Datei aufräumen
rm -f /tmp/sync_result.txt
