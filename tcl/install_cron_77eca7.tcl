#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "972efb8b81783a6448e5c04aa6e6a58d91413cb53085d804c1cf63fe34fc6b1c", "source_sha256": "77eca70a7a8f9c0ff8dc240b14d8c37999854c241e031b8167e1fcd650cbd334", "target_language": "tcl"}
# install_cron.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
# auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Installiert den DB-Maintainer als Cron-Job

package require json

set CRON_JOB {
# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1
}

proc file_exists {filename} {
    return [expr {[file exists $filename] && ![file isdirectory $filename]}]
}

proc install {} {
    set workspace "/home/openclaw/.openclaw/workspace"
    set cron_file "$workspace/crons/db-maintainer.cron"
    
    file mkdir [file dirname $cron_file]
    
    set f [open $cron_file w]
    puts $f [string trim $::CRON_JOB]
    close $f
    
    puts "✅ Cron-Job installiert: $cron_file"
    puts "   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron"
    
    # Auch in OpenClaw cron registrieren
    set jobs_json "$workspace/.openclaw/cron/jobs.json"
    if {[file exists $jobs_json]} {
        set f [open $jobs_json r]
        set json_data [read $f]
        close $f
        
        if {$json_data eq ""} {
            set jobs [dict create]
        } else {
            set jobs [::json::json2dict $json_data]
        }
        
        dict set jobs "db-maintainer" [dict create \
            schedule "*/30 * * * *" \
            command "python3 skills/db-maintainer/scripts/db_maintainer.py" \
            enabled true]
        
        set f [open $jobs_json w]
        puts $f [::json::dict2json $jobs]
        close $f
        
        puts "✅ In OpenClaw cron registriert"
    }
}

install
