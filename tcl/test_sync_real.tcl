#!/usr/bin/env tclsh8.6
# test_sync_real.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:scripts/test_sync_real.py
# auch in: OpenClaw@gateway2:scripts/test_sync_real.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# Test echte Synchronisation

lappend auto_path /home/openclaw/.openclaw/workspace/scripts
source /home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.tcl

# Test: db-maintainer ClawHub → Git (ECHT)
puts "=== TEST: db-maintainer sync (REAL) ==="
set skill "db-maintainer"
set result [sync_to_git $skill 0]

if {$result} {
    puts "Result: SUCCESS"
} else {
    puts "Result: FAILED"
}

# Prüfe Ergebnis
set target "/home/openclaw/.openclaw/workspace/git/skills/db-maintainer"
if {[file exists $target]} {
    puts "\n✅ Git-Repo erstellt: $target"
    
    # Rekursives Verzeichnislisting
    proc list_dir {path {level 0}} {
        set indent [string repeat " " [expr {$level * 2}]]
        puts "${indent}[file tail $path]/"
        
        set subindent [string repeat " " [expr {($level + 1) * 2}]]
        
        # Sortierte Liste der Dateien und Verzeichnisse
        set entries [lsort [glob -nocomplain -dir $path *]]
        foreach entry $entries {
            if {[file isdirectory $entry]} {
                list_dir $entry [expr {$level + 1}]
            } else {
                puts "${subindent}[file tail $entry]"
            }
        }
    }
    
    list_dir $target
}
