#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "ebac8c092a70e5ad263d628a3ea95e8665595447b416529469b3ca2796bbca0f", "source_sha256": "77eca70a7a8f9c0ff8dc240b14d8c37999854c241e031b8167e1fcd650cbd334", "target_language": "javascript"}
// install_cron.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
// auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/**
 * Installiert den DB-Maintainer als Cron-Job
 */

const fs = require('fs');
const path = require('path');

const CRON_JOB = `
# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1
`.trim();

function install() {
    const workspace = path.join('/home/openclaw/.openclaw/workspace');
    const cronFile = path.join(workspace, 'crons', 'db-maintainer.cron');
    
    // Stelle sicher, dass das Verzeichnis existiert
    fs.mkdirSync(path.dirname(cronFile), { recursive: true });
    
    // Schreibe die Cron-Datei
    fs.writeFileSync(cronFile, CRON_JOB);
    
    console.log(`✅ Cron-Job installiert: ${cronFile}`);
    console.log('   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron');
    
    // Auch in OpenClaw cron registrieren
    const jobsJson = path.join(workspace, '.openclaw', 'cron', 'jobs.json');
    if (fs.existsSync(jobsJson)) {
        const jobs = JSON.parse(fs.readFileSync(jobsJson, 'utf8'));
        
        jobs['db-maintainer'] = {
            schedule: '*/30 * * * *',
            command: 'python3 skills/db-maintainer/scripts/db_maintainer.py',
            enabled: true
        };
        
        fs.writeFileSync(jobsJson, JSON.stringify(jobs, null, 2));
        
        console.log('✅ In OpenClaw cron registriert');
    }
}

install();
