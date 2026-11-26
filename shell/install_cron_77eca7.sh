#!/usr/bin/env bash
# abstraction-provenance: {"artifact_sha256": "1b3fc28ea328e2e9f57a815d989536e5665e204a91963a3b667e147a9ca4e64a", "source_sha256": "77eca70a7a8f9c0ff8dc240b14d8c37999854c241e031b8167e1fcd650cbd334", "target_language": "shell"}
# install_cron.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
# auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Installiert den DB-Maintainer als Cron-Job

readonly CRON_JOB='# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1'

readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly CRON_FILE="${WORKSPACE}/crons/db-maintainer.cron"
readonly JOBS_JSON="${WORKSPACE}/.openclaw/cron/jobs.json"

install() {
    # Erstelle das Cron-Verzeichnis falls es nicht existiert
    mkdir -p "$(dirname "$CRON_FILE")"
    
    # Schreibe den Cron-Job in die Datei
    echo "$CRON_JOB" > "$CRON_FILE"
    
    echo "✅ Cron-Job installiert: $CRON_FILE"
    echo "   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron"
    
    # Auch in OpenClaw cron registrieren
    if [[ -f "$JOBS_JSON" ]]; then
        # Lese die vorhandenen Jobs und füge den neuen hinzu
        local temp_jobs
        temp_jobs=$(jq '.["db-maintainer"] = {
            "schedule": "*/30 * * * *",
            "command": "python3 skills/db-maintainer/scripts/db_maintainer.py",
            "enabled": true
        }' "$JOBS_JSON")
        
        # Schreibe die aktualisierten Jobs zurück
        echo "$temp_jobs" | jq '.' > "$JOBS_JSON"
        
        echo "✅ In OpenClaw cron registriert"
    fi
}

# Hauptausführung
install
