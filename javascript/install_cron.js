#!/usr/bin/env node
// install_cron.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
// auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

/**
 * Installiert den DB-Maintainer als Cron-Job
 */

import { writeFileSync, existsSync, mkdirSync, readFileSync } from 'fs';
import { resolve } from 'path';

const CRON_JOB = `
# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1
`.trim();

function install() {
    const workspace = resolve('/home/openclaw/.openclaw/workspace');
    const cronFile = resolve(workspace, 'crons', 'db-maintainer.cron');
    
    mkdirSync(resolve(workspace, 'crons'), { recursive: true });
    
    writeFileSync(cronFile, CRON_JOB);
    
    console.log(`✅ Cron-Job installiert: ${cronFile}`);
    console.log('   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron');
    
    // Auch in OpenClaw cron registrieren
    const jobsJson = resolve(workspace, '.openclaw', 'cron', 'jobs.json');
    if (existsSync(jobsJson)) {
        const jobs = JSON.parse(readFileSync(jobsJson, 'utf8'));
        
        jobs['db-maintainer'] = {
            'schedule': '*/30 * * * *',
            'command': 'python3 skills/db-maintainer/scripts/db_maintainer.py',
            'enabled': true
        };
        
        writeFileSync(jobsJson, JSON.stringify(jobs, null, 2));
        
        console.log('✅ In OpenClaw cron registriert');
    }
}

install();
