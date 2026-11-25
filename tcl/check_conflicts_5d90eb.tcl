#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "b7d3a13f6d1616e4b7ec3406c3068190fca6daf74bfa11027a3746117f3421eb", "source_sha256": "5d90ebcd250a3cb80a0de664d94397af7ec03343d9d9fa64a28a9a11ad880754", "target_language": "tcl"}
# check_conflicts.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

#
# Check Conflicts - Erkennt Sync-Konflikte
#

# Import sync functions
lappend auto_path /home/openclaw/.openclaw/workspace/scripts

# Globals
set CLAWHUB_DIR "/home/openclaw/.openclaw/workspace/skills"
set GIT_DIR "/home/openclaw/.openclaw/workspace/git/skills"

proc get_file_hash {filepath} {
    # Lade die Funktion aus dem Python-Modul
    if {[catch {exec python3 -c "
import sys
sys.path.append('/home/openclaw/.openclaw/workspace/scripts')
from sync_clawhub_git import get_file_hash
print(get_file_hash('$filepath'))
"} result]} {
        error "Fehler beim Hash-Berechnen von $filepath: $result"
    }
    return $result
}

proc check_conflicts {} {
    global CLAWHUB_DIR GIT_DIR
    
    set conflicts [list]
    
    # Alle Skills die in beiden Orten existieren
    set common_skills [list]
    
    if {[file exists $CLAWHUB_DIR] && [file exists $GIT_DIR]} {
        set clawhub_skills [dict create]
        foreach d [glob -directory $CLAWHUB_DIR -types d *] {
            dict set clawhub_skills [file tail $d] 1
        }
        
        set git_skills [dict create]
        foreach d [glob -directory $GIT_DIR -types d *] {
            dict set git_skills [file tail $d] 1
        }
        
        # Finde gemeinsame Skills
        foreach skill [dict keys $clawhub_skills] {
            if {[dict exists $git_skills $skill]} {
                lappend common_skills $skill
            }
        }
    }
    
    puts "Prüfe [llength $common_skills] Skills auf Konflikte...\n"
    
    foreach skill [lsort $common_skills] {
        set clawhub_path [file join $CLAWHUB_DIR $skill]
        set git_path [file join $GIT_DIR $skill]
        
        # Alle Dateien vergleichen
        set skill_conflicts [list]
        
        # ClawHub Dateien
        set clawhub_files [dict create]
        foreach f [find_files_recursive $clawhub_path] {
            if {![string match "*.git*" $f]} {
                set rel_path [file relative $f $clawhub_path]
                dict set clawhub_files $rel_path $f
            }
        }
        
        # Git Dateien
        set git_files [dict create]
        foreach f [find_files_recursive $git_path] {
            if {![string match "*.git*" $f]} {
                set rel_path [file relative $f $git_path]
                dict set git_files $rel_path $f
            }
        }
        
        # Vergleiche gemeinsame Dateien
        set common_files [list]
        foreach rel_path [dict keys $clawhub_files] {
            if {[dict exists $git_files $rel_path]} {
                lappend common_files $rel_path
            }
        }
        
        foreach rel_path $common_files {
            set clawhub_file [dict get $clawhub_files $rel_path]
            set git_file [dict get $git_files $rel_path]
            
            if {[get_file_hash $clawhub_file] ne [get_file_hash $git_file]} {
                set clawhub_mtime [file mtime $clawhub_file]
                set git_mtime [file mtime $git_file]
                
                set clawhub_time_str [clock format $clawhub_mtime -format {%Y-%m-%d %H:%M:%S}]
                set git_time_str [clock format $git_mtime -format {%Y-%m-%d %H:%M:%S}]
                
                set newer ""
                if {$clawhub_mtime > $git_mtime} {
                    set newer "clawhub"
                } else {
                    set newer "git"
                }
                
                lappend skill_conflicts [dict create \
                    file $rel_path \
                    clawhub_modified $clawhub_time_str \
                    git_modified $git_time_str \
                    newer $newer]
            }
        }
        
        if {[llength $skill_conflicts] > 0} {
            lappend conflicts [dict create \
                skill $skill \
                conflicts $skill_conflicts]
        }
    }
    
    # Ausgabe
    if {[llength $conflicts] > 0} {
        puts "⚠️  KONFLIKTE GEFUNDEN:"
        puts [string repeat "=" 80]
        
        foreach conflict $conflicts {
            set skill_name [dict get $conflict skill]
            puts "\n📦 Skill: $skill_name"
            puts [string repeat "-" 40]
            
            foreach file_conflict [dict get $conflict conflicts] {
                set filename [dict get $file_conflict file]
                set clawhub_mod [dict get $file_conflict clawhub_modified]
                set git_mod [dict get $file_conflict git_modified]
                set newer [dict get $file_conflict newer]
                
                puts "  📄 $filename"
                puts "     ClawHub: $clawhub_mod"
                puts "     Git:     $git_mod"
                puts "     Neuer:   [string toupper $newer]"
                puts ""
            }
        }
        
        puts [string repeat "=" 80]
        puts "Gesamt: [llength $conflicts] Skills mit Konflikten"
        puts "\nNutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen."
    } else {
        puts "✅ Keine Konflikte gefunden!"
        puts "Alle gemeinsamen Skills sind synchron."
    }
}

proc find_files_recursive {path} {
    set files [list]
    if {[file isdirectory $path]} {
        foreach item [glob -nocomplain -directory $path *] {
            if {[file isfile $item]} {
                lappend files $item
            } elseif {[file isdirectory $item]} {
                set subfiles [find_files_recursive $item]
                foreach f $subfiles {
                    lappend files $f
                }
            }
        }
    }
    return $files
}

proc main {} {
    check_conflicts
}

if {[info script] eq $argv0} {
    main
}
