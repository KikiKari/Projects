#!/usr/bin/env bash
# backup_dbs.py — portiert nach shell
# Quelle: python, OpenClaw@gateway2:tmp/backup_dbs.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Backup docs.db and tree.db with timestamp into /workspace/db/backups

workspace="${OPENCLAW_WORKSPACE:-/workspace}"
backup_dir="$workspace/db/backups"

# Ensure backup_dir exists
mkdir -p "$backup_dir"

timestamp=$(date '+%Y-%m-%d_%H-%M')

for db_name in docs.db tree.db; do
    src="$workspace/$db_name"
    if [[ -f "$src" ]]; then
        dest="$backup_dir/${timestamp}_${db_name}.bak"
        cp -p "$src" "$dest"
        echo "Backup created: $dest"
    else
        echo "Source db not found: $src"
    fi
done
