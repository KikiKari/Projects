#!/usr/bin/env bash
# install_cron.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
# auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Installiert den DB-Maintainer als Cron-Job

readonly CRON_JOB='# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1'

readonly WORKSPACE="/home/openclaw/.openclaw/workspace"
readonly CRON_FILE="${WORKSPACE}/crons/db-maintainer.cron"
readonly JOBS_JSON="${WORKSPACE}/.openclaw/cron/jobs.json"

install() {
    # Erstelle das Verzeichnis falls es nicht existiert
    mkdir -p "$(dirname "${CRON_FILE}")"
    
    # Schreibe den Cron-Job in die Datei
    echo "${CRON_JOB}" > "${CRON_FILE}"
    
    echo "✅ Cron-Job installiert: ${CRON_FILE}"
    echo "   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron"
    
    # Auch in OpenClaw cron registrieren
    if [[ -f "${JOBS_JSON}" ]]; then
        # Lese die vorhandenen Jobs, füge den neuen hinzu und schreibe alles zurück
        local temp_jobs
        temp_jobs=$(mktemp)
        
        # Entferne den alten Eintrag falls vorhanden und füge den neuen hinzu
        if command -v jq >/dev/null 2>&1; then
            jq '.["db-maintainer"] = {
                "schedule": "*/30 * * * *",
                "command": "python3 skills/db-maintainer/scripts/db_maintainer.py",
                "enabled": true
            }' "${JOBS_JSON}" > "${temp_jobs}"
            mv "${temp_jobs}" "${JOBS_JSON}"
        else
            # Fallback ohne jq - überschreibe den gesamten Eintrag
            cat > "${JOBS_JSON}" <<EOF
{
  "db-maintainer": {
    "schedule": "*/30 * * * *",
    "command": "python3 skills/db-maintainer/scripts/db_maintainer.py",
    "enabled": true
  }
}
EOF
        fi
        
        echo "✅ In OpenClaw cron registriert"
    fi
}

# Hauptprogramm
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install
fi
