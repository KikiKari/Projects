<?php
// abstraction-provenance: {"artifact_sha256": "3f5b9d42d79667405d5e12fdee21770f788243f448d7af10c3dd1f1d33b86ef4", "source_sha256": "77eca70a7a8f9c0ff8dc240b14d8c37999854c241e031b8167e1fcd650cbd334", "target_language": "php"}
// install_cron.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
// auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Installiert den DB-Maintainer als Cron-Job
 */

const CRON_JOB = "
# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1
";

function install() {
    $workspace = "/home/openclaw/.openclaw/workspace";
    $cron_file = $workspace . "/crons/db-maintainer.cron";
    
    // Erstelle das Verzeichnis falls es nicht existiert
    if (!is_dir(dirname($cron_file))) {
        mkdir(dirname($cron_file), 0777, true);
    }
    
    // Schreibe die Cron-Job Definition in die Datei
    file_put_contents($cron_file, trim(CRON_JOB));
    
    echo "✅ Cron-Job installiert: " . $cron_file . "\n";
    echo "   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron\n";
    
    // Auch in OpenClaw cron registrieren
    $jobs_json = $workspace . "/.openclaw/cron/jobs.json";
    if (file_exists($jobs_json)) {
        $jobs = json_decode(file_get_contents($jobs_json), true);
        
        $jobs['db-maintainer'] = [
            'schedule' => '*/30 * * * *',
            'command' => 'python3 skills/db-maintainer/scripts/db_maintainer.py',
            'enabled' => true
        ];
        
        file_put_contents($jobs_json, json_encode($jobs, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
        
        echo "✅ In OpenClaw cron registriert\n";
    }
}

install();
?>
