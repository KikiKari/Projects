#!/usr/bin/env tclsh8.6
# check_conflicts.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

#
# Check Conflicts - Erkennt Sync-Konflikte
#

# Globale Variablen
set CLAWHUB_DIR "/home/openclaw/.openclaw/workspace/skills"
set GIT_DIR "/home/openclaw/.openclaw/workspace/git/skills"

# Hilfsfunktion zur Berechnung des Hashes einer Datei
proc get_file_hash {filepath} {
    if {[catch {open $filepath r} fd]} {
        return ""
    }
    fconfigure $fd -translation binary
    set content [read $fd]
    close $fd
    
    # Berechne MD5-Hash
    set hash [md5::md5 -hex $content]
    return $hash
}

# Lade das md5-Paket
package require md5

# Funktion zum Prüfen auf Konflikte
proc check_conflicts {} {
    global CLAWHUB_DIR GIT_DIR
    
    set conflicts {}
    
    # Alle Skills die in beiden Orten existieren
    set common_skills {}
    if {[file exists $CLAWHUB_DIR] && [file exists $GIT_DIR]} {
        set clawhub_skills {}
        if {[file exists $CLAWHUB_DIR]} {
            foreach d [glob -nocomplain -directory $CLAWHUB_DIR *] {
                if {[file isdirectory $d]} {
                    lappend clawhub_skills [file tail $d]
                }
            }
        }
        
        set git_skills {}
        if {[file exists $GIT_DIR]} {
            foreach d [glob -nocomplain -directory $GIT_DIR *] {
                if {[file isdirectory $d]} {
                    lappend git_skills [file tail $d]
                }
            }
        }
        
        # Finde gemeinsame Skills
        foreach skill $clawhub_skills {
            if {[lsearch -exact $git_skills $skill] != -1} {
                lappend common_skills $skill
            }
        }
    }
    
    puts "Prüfe [llength $common_skills] Skills auf Konflikte...\n"
    
    foreach skill [lsort $common_skills] {
        set clawhub_path [file join $CLAWHUB_DIR $skill]
        set git_path [file join $GIT_DIR $skill]
        
        # Alle Dateien vergleichen
        set skill_conflicts {}
        
        # ClawHub Dateien
        set clawhub_files {}
        foreach f [get_recursive_files $clawhub_path] {
            if {[file isfile $f] && [string first ".git" $f] == -1} {
                set rel_path [file relative $clawhub_path $f]
                dict set clawhub_files $rel_path $f
            }
        }
        
        # Git Dateien
        set git_files {}
        foreach f [get_recursive_files $git_path] {
            if {[file isfile $f] && [string first ".git" $f] == -1} {
                set rel_path [file relative $git_path $f]
                dict set git_files $rel_path $f
            }
        }
        
        # Vergleiche gemeinsame Dateien
        set common_files {}
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
                
                set newer "git"
                if {$clawhub_mtime > $git_mtime} {
                    set newer "clawhub"
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
            
            set file_conflicts [dict get $conflict conflicts]
            foreach file_conflict $file_conflicts {
                set file_name [dict get $file_conflict file]
                set clawhub_modified [dict get $file_conflict clawhub_modified]
                set git_modified [dict get $file_conflict git_modified]
                set newer [dict get $file_conflict newer]
                
                puts "  📄 $file_name"
                puts "     ClawHub: $clawhub_modified"
                puts "     Git:     $git_modified"
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

# Hilfsfunktion zum rekursiven Sammeln von Dateien
proc get_recursive_files {dir} {
    set files {}
    
    # Prüfe ob das Verzeichnis existiert
    if {![file exists $dir] || ![file isdirectory $dir]} {
        return $files
    }
    
    # Durchlaufe das Verzeichnis rekursiv
    foreach item [glob -nocomplain -directory $dir *] {
        if {[file isdirectory $item]} {
            # Rekursiver Aufruf für Unterverzeichnisse
            set subfiles [get_recursive_files $item]
            foreach f $subfiles {
                lappend files $f
            }
        } else {
            lappend files $item
        }
    }
    
    return $files
}

# Hauptfunktion
proc main {} {
    check_conflicts
}

# Starte das Programm
main
