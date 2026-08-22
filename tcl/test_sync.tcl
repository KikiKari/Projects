#!/usr/bin/env tclsh
# test_sync.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:scripts/test_sync.py
# auch in: OpenClaw@gateway2:scripts/test_sync.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# Test für Sync-Script

# Füge das Verzeichnis zum Pfad hinzu
lappend auto_path /home/openclaw/.openclaw/workspace/scripts

# Lade das sync_clawhub_git Modul
source /home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.tcl

# Test: db-maintainer ClawHub → Git (DRY-RUN)
puts "=== TEST: db-maintainer sync (DRY-RUN) ==="
set skill "db-maintainer"
set result [sync_to_git $skill -dry_run true]

if {$result} {
    puts "Result: SUCCESS"
} else {
    puts "Result: FAILED"
}

puts "\n=== LOG-Inhalt ==="
set logfile "/home/openclaw/.openclaw/workspace/logs/sync.log"
if {[file exists $logfile]} {
    set fh [open $logfile r]
    set content [read $fh]
    close $fh
    puts $content
} else {
    puts "Logfile nicht gefunden: $logfile"
}
