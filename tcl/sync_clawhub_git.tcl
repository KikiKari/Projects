#!/usr/bin/env tclsh8.6
# sync_clawhub_git.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:scripts/sync_clawhub_git.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

#
# Bidirektionale ClawHub ↔ Git Synchronisation
#

package require sha256
package require fileutil
package require cmdline

# Konfiguration
set CLAWHUB_DIR "/home/openclaw/.openclaw/workspace/skills"
set GIT_DIR "/home/openclaw/.openclaw/workspace/git/skills"
set BACKUP_DIR "/home/openclaw/.openclaw/workspace/backups/sync"
set LOG_FILE "/home/openclaw/.openclaw/workspace/logs/sync-agent.log"

# Erstelle Verzeichnisse
file mkdir $GIT_DIR
file mkdir $BACKUP_DIR
file mkdir [file dirname $LOG_FILE]

# Logging
proc log {message {level "INFO"}} {
    global LOG_FILE
    set timestamp [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]
    set entry "\[${timestamp}\] \[$level\] $message"
    puts $entry
    set f [open $LOG_FILE a]
    puts $f $entry
    close $f
}

# Validierung
proc validate_skill {skill_dir} {
    # Prüft Skill-Struktur - SKILL.md required, scripts/ optional
    if {![file exists [file join $skill_dir SKILL.md]]} {
        log "Validation failed: [file tail $skill_dir] missing SKILL.md" ERROR
        return 0
    }
    return 1
}

# Backup
proc create_backup {source skill_name} {
    global BACKUP_DIR
    # Erstellt Backup eines Skills
    set timestamp [clock format [clock seconds] -format {%Y%m%d_%H%M%S}]
    set backup_path [file join $BACKUP_DIR ${skill_name}_${timestamp}]
    
    # Backup verzeichnis löschen falls es existiert
    if {[file exists $backup_path]} {
        if {[catch {file delete -force $backup_path} error]} {
            log "Failed to remove existing backup $backup_path: $error" ERROR
            return 0
        } else {
            log "Removed existing backup: $backup_path"
        }
    }
    
    if {[catch {file copy $source $backup_path} error]} {
        log "Backup failed: $error" ERROR
        return 0
    } else {
        log "Backup created: $backup_path"
        return 1
    }
}

# Hash-Vergleich
proc get_file_hash {file_path} {
    # SHA256-Hash einer Datei
    set f [open $file_path rb]
    set data [read $f]
    close $f
    return [sha2::sha256 -hex $data]
}

# Sync Richtung ClawHub → Git
proc sync_to_git {skill_name dry_run} {
    global CLAWHUB_DIR GIT_DIR
    # Synchronisiert ClawHub Skill zu Git
    set source [file join $CLAWHUB_DIR $skill_name]
    set target [file join $GIT_DIR $skill_name]
    
    if {![validate_skill $source]} {
        return 0
    }
    
    # Backup vor Änderungen (nur wenn target existiert)
    if {!$dry_run && [file exists $target]} {
        create_backup $target $skill_name
    }
    
    # Änderungen erkennen
    set changes {}
    foreach item [glob -nocomplain -dir $source -types f *] {
        set rel_path [file tail $item]
        set src_file $item
        set tgt_file [file join $target $rel_path]
        
        # Vergleich
        if {![file exists $tgt_file]} {
            lappend changes "ADD $rel_path"
        } elseif {[get_file_hash $src_file] ne [get_file_hash $tgt_file]} {
            lappend changes "UPDATE $rel_path"
        }
    }
    
    # Rekursiv durch Unterverzeichnisse gehen
    foreach dir [glob -nocomplain -dir $source -types d *] {
        set subdir_name [file tail $dir]
        if {$subdir_name eq ".git"} continue
        set sub_changes [detect_changes_recursive $source $target $subdir_name]
        set changes [concat $changes $sub_changes]
    }
    
    # Dry-Run Report
    if {$dry_run} {
        log "DRY-RUN: $skill_name - [llength $changes] changes"
        foreach change $changes {
            log "  $change"
        }
        return 1
    }
    
    # Echte Synchronisation
    log "SYNC: $skill_name - Applying [llength $changes] changes"
    if {[file exists $target]} {
        if {[catch {copy_tree_with_ignore $source $target .git} error]} {
            log "Copy failed: $error" ERROR
            return 0
        }
    } else {
        if {[catch {copy_tree_with_ignore $source $target .git} error]} {
            log "Copy failed: $error" ERROR
            return 0
        }
    }
    log "SYNC: $skill_name - Complete"
    return 1
}

# Sync Richtung Git → ClawHub
proc sync_to_clawhub {skill_name dry_run} {
    global GIT_DIR CLAWHUB_DIR
    # Synchronisiert Git Skill zu ClawHub
    set source [file join $GIT_DIR $skill_name]
    set target [file join $CLAWHUB_DIR $skill_name]
    
    if {![validate_skill $source]} {
        return 0
    }
    
    # Backup vor Änderungen (nur wenn target existiert)
    if {!$dry_run && [file exists $target]} {
        create_backup $target $skill_name
    }

    # Änderungen erkennen (gleiche Logik wie oben)
    set changes {}
    foreach item [glob -nocomplain -dir $source -types f *] {
        set rel_path [file tail $item]
        set src_file $item
        set tgt_file [file join $target $rel_path]
        
        if {![file exists $tgt_file]} {
            lappend changes "ADD $rel_path"
        } elseif {[get_file_hash $src_file] ne [get_file_hash $tgt_file]} {
            lappend changes "UPDATE $rel_path"
        }
    }
    
    # Rekursiv durch Unterverzeichnisse gehen
    foreach dir [glob -nocomplain -dir $source -types d *] {
        set subdir_name [file tail $dir]
        if {$subdir_name eq ".git"} continue
        set sub_changes [detect_changes_recursive $source $target $subdir_name]
        set changes [concat $changes $sub_changes]
    }

    # Dry-Run Report
    if {$dry_run} {
        log "DRY-RUN: $skill_name - [llength $changes] changes"
        foreach change $changes {
            log "  $change"
        }
        return 1
    }

    # Echte Synchronisation
    log "SYNC: $skill_name - Applying [llength $changes] changes"
    if {[file exists $target]} {
        if {[catch {copy_tree_with_ignore $source $target .git} error]} {
            log "Copy failed: $error" ERROR
            return 0
        }
    } else {
        if {[catch {copy_tree_with_ignore $source $target .git} error]} {
            log "Copy failed: $error" ERROR
            return 0
        }
    }
    log "SYNC: $skill_name - Complete"
    return 1
}

# Hilfsfunktion für rekursive Änderungserkennung
proc detect_changes_recursive {source_base target_base relative_path} {
    set source_dir [file join $source_base $relative_path]
    set target_dir [file join $target_base $relative_path]
    
    set changes {}
    
    # Prüfe Dateien im aktuellen Verzeichnis
    foreach item [glob -nocomplain -dir $source_dir -types f *] {
        set filename [file tail $item]
        set src_file $item
        set tgt_file [file join $target_dir $filename]
        set rel_file_path [file join $relative_path $filename]
        
        if {![file exists $tgt_file]} {
            lappend changes "ADD $rel_file_path"
        } elseif {[get_file_hash $src_file] ne [get_file_hash $tgt_file]} {
            lappend changes "UPDATE $rel_file_path"
        }
    }
    
    # Rekursion in Unterverzeichnisse
    foreach dir [glob -nocomplain -dir $source_dir -types d *] {
        set subdir_name [file tail $dir]
        if {$subdir_name eq ".git"} continue
        set sub_changes [detect_changes_recursive $source_base $target_base [file join $relative_path $subdir_name]]
        set changes [concat $changes $sub_changes]
    }
    
    return $changes
}

# Hilfsfunktion zum Kopieren von Verzeichnissen mit Ignorieren von Mustern
proc copy_tree_with_ignore {source target ignore_pattern} {
    # Erstelle Zielverzeichnis falls nicht vorhanden
    if {![file exists $target]} {
        file mkdir $target
    }
    
    # Hole alle Elemente im Quellverzeichnis
    set items [glob -nocomplain -dir $source *]
    
    foreach item $items {
        set name [file tail $item]
        # Überspringe ignorierte Muster
        if {$name eq $ignore_pattern} continue
        
        set dest_item [file join $target $name]
        
        if {[file isdirectory $item]} {
            # Rekursiver Aufruf für Verzeichnisse
            copy_tree_with_ignore $item $dest_item $ignore_pattern
        } else {
            # Kopiere Datei
            file copy -force $item $dest_item
        }
    }
}

# Hauptfunktion
proc main {} {
    global argv
    # Kommandozeilenoptionen parsen
    set options {
        {skill.arg "" "Skill name"}
        {direction.arg "" "Direction: to-git or to-clawhub"}
        {dry-run "Nur Änderungen anzeigen"}
        {force "Ohne Backup"}
    }
    
    if {[catch {array set opts [cmdline::getoptions argv $options]} error]} {
        puts stderr "Error parsing options: $error"
        exit 1
    }
    
    # Validierung der erforderlichen Parameter
    if {$opts(skill) eq "" || $opts(direction) eq ""} {
        puts stderr "Error: --skill and --direction are required"
        exit 1
    }
    
    if {$opts(direction) ni {"to-git" "to-clawhub"}} {
        puts stderr "Error: direction must be either 'to-git' or 'to-clawhub'"
        exit 1
    }
    
    set dry_run [info exists opts(dry-run)]
    
    log "Starting sync: $opts(skill) ($opts(direction))"
    
    set success 0
    if {$opts(direction) eq "to-git"} {
        set success [sync_to_git $opts(skill) $dry_run]
    } else {
        set success [sync_to_clawhub $opts(skill) $dry_run]
    }
    
    if {!$success} {
        log "Sync failed" ERROR
        exit 1
    }
    
    log "Sync completed"
}

# Starte das Programm
if {[info script] eq $argv0} {
    main
}
