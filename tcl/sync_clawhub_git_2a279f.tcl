#!/usr/bin/env tclsh
# sync_clawhub_git.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:scripts/sync_clawhub_git.py
# auch in: Projects@clawhub:clawhub/Skills/sync_clawhub_git.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# Bidirektionale ClawHub ↔ Git Synchronisation

package require fileutil
package require sha256

# Konfiguration
# Resolve paths relative to this repository so the helper works both in the
# hosted workspace and in environments without a /workspace mount.
set scriptDir [file normalize [file dirname $argv0]]
set WORKSPACE_ROOT [file normalize "$scriptDir/../.."]
set CLAWHUB_DIR [file join $WORKSPACE_ROOT skills]
set GIT_DIR [file join $WORKSPACE_ROOT git skills]
set BACKUP_DIR [file join $WORKSPACE_ROOT backups sync]
set LOG_FILE [file join $WORKSPACE_ROOT logs sync-agent.log]
array set IGNORED_NAMES {}
foreach name {.git .clawhub node_modules __pycache__ .pytest_cache} {
    set IGNORED_NAMES($name) 1
}
array set RESERVED_SKILL_NAMES {}
foreach name {github-clones skills backups .restore git Abstraktionen} {
    set RESERVED_SKILL_NAMES($name) 1
}
array set PRESERVED_TARGET_NAMES {}
foreach name {.git .clawhub node_modules __pycache__ .pytest_cache} {
    set PRESERVED_TARGET_NAMES($name) 1
}

# Erstelle Verzeichnisse
file mkdir $GIT_DIR
file mkdir $BACKUP_DIR
file mkdir [file dirname $LOG_FILE]

# Logging
proc log {message {level INFO}} {
    global LOG_FILE
    set timestamp [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]
    set entry "\[$timestamp\] \[$level\] $message"
    puts $entry
    if {[catch {open $LOG_FILE a} fid]} {
        puts "Fehler beim Öffnen der Logdatei: $fid"
        return
    }
    puts $fid $entry
    close $fid
}

# Validierung
proc validate_skill {skill_dir} {
    global RESERVED_SKILL_NAMES
    set skill_name [file tail $skill_dir]
    if {[info exists RESERVED_SKILL_NAMES($skill_name)]} {
        log "Validation failed: $skill_name is reserved and must not be synced as a skill" ERROR
        return 0
    }
    if {![file exists [file join $skill_dir SKILL.md]]} {
        log "Validation failed: $skill_name missing SKILL.md" ERROR
        return 0
    }
    return 1
}

proc _is_ignored_path {path} {
    global IGNORED_NAMES
    foreach part [split $path /] {
        if {$part eq ""} continue
        if {[info exists IGNORED_NAMES($part)] || [string match "*.pyc" $part]} {
            return 1
        }
    }
    return 0
}

proc _is_generated_duplicate_path {root rel_path} {
    set parts [split $rel_path /]
    if {[llength $parts] == 0} {
        return 0
    }
    set first_part [lindex $parts 0]
    if {$first_part eq [file tail $root]} {
        return 1
    }
    for {set i 1} {$i < [llength $parts]} {incr i} {
        if {[lindex $parts $i] eq [lindex $parts [expr {$i-1}]]} {
            return 1
        }
    }
    return 0
}

proc iter_sync_files {root} {
    global IGNORED_NAMES
    set result {}
    set dirs_to_walk [list $root]
    while {[llength $dirs_to_walk] > 0} {
        set current_root [lindex $dirs_to_walk 0]
        set dirs_to_walk [lrange $dirs_to_walk 1 end]
        
        set rel_root [string range $current_root [string length $root]+1 end]
        if {$rel_root eq ""} {
            set rel_root .
        } else {
            set rel_root [string trim $rel_root "/"]
        }
        
        if {[_is_ignored_path $rel_root]} {
            continue
        }
        
        set kept_dirs {}
        if {[catch {glob -nocomplain -directory $current_root *} entries]} {
            continue
        }
        foreach entry $entries {
            if {[file isdirectory $entry]} {
                set dir_name [file tail $entry]
                if {[info exists IGNORED_NAMES($dir_name)] || [string match "__pycache__*" $dir_name]} {
                    continue
                }
                set rel_dir [file join $rel_root $dir_name]
                if {[_is_generated_duplicate_path $root $rel_dir]} {
                    continue
                }
                lappend kept_dirs $entry
            }
        }
        
        foreach dir $kept_dirs {
            lappend dirs_to_walk $dir
        }
        
        if {[catch {glob -nocomplain -directory $current_root *} entries]} {
            continue
        }
        foreach entry $entries {
            if {[file isfile $entry]} {
                set file_name [file tail $entry]
                if {[info exists IGNORED_NAMES($file_name)] || [string match "*.pyc" $file_name]} {
                    continue
                }
                set rel_path [file join $rel_root $file_name]
                if {[_is_ignored_path $rel_path]} {
                    continue
                }
                if {[_is_generated_duplicate_path $root $rel_path]} {
                    continue
                }
                if {$file_name eq "SKILL.md" && $rel_path ne "SKILL.md"} {
                    continue
                }
                lappend result [list $entry $rel_path]
            }
        }
    }
    return $result
}

proc reset_sync_target {target} {
    global PRESERVED_TARGET_NAMES
    file mkdir $target
    if {![file isdirectory $target]} {
        return
    }
    if {[catch {glob -nocomplain -directory $target *} children]} {
        return
    }
    foreach child $children {
        set child_name [file tail $child]
        if {[info exists PRESERVED_TARGET_NAMES($child_name)]} {
            continue
        }
        if {[file isdirectory $child] && ![file islink $child]} {
            if {[catch {file delete -force $child} err]} {
                log "Failed to remove directory $child: $err" ERROR
            }
        } else {
            if {[catch {file delete $child} err]} {
                log "Failed to remove file $child: $err" ERROR
            }
        }
    }
}

proc copy_sync_files {source target} {
    reset_sync_target $target
    foreach item [iter_sync_files $source] {
        lassign $item src_file rel_path
        set dest_file [file join $target $rel_path]
        set dest_dir [file dirname $dest_file]
        file mkdir $dest_dir
        if {[catch {file copy -force -- $src_file $dest_file} err]} {
            log "Failed to copy $src_file to $dest_file: $err" ERROR
        }
    }
}

# Backup
proc create_backup {source skill_name} {
    global BACKUP_DIR
    set timestamp [clock format [clock seconds] -format {%Y%m%d_%H%M%S}]
    set backup_path [file join $BACKUP_DIR ${skill_name}_$timestamp]
    
    # Backup verzeichnis löschen falls es existiert
    if {[file exists $backup_path]} {
        if {[catch {file delete -force $backup_path} err]} {
            log "Failed to remove existing backup $backup_path: $err" ERROR
            return 0
        }
        log "Removed existing backup: $backup_path"
    }
    
    if {[catch {exec cp -r $source $backup_path} err]} {
        log "Backup failed: $err" ERROR
        return 0
    }
    log "Backup created: $backup_path"
    return 1
}

# Hash-Vergleich
proc get_file_hash {file_path} {
    # Ensure the path points to a regular file.
    if {![file isfile $file_path]} {
        return ""
    }
    if {[catch {open $file_path r} fd]} {
        log "Failed to open file $file_path: $fd" ERROR
        return ""
    }
    fconfigure $fd -translation binary
    set content [read $fd]
    close $fd
    return [sha2::sha256 $content]
}

# Sync Richtung ClawHub → Git
proc sync_to_git {skill_name dry_run} {
    global CLAWHUB_DIR GIT_DIR
    set source [file join $CLAWHUB_DIR $skill_name]
    set target [file join $GIT_DIR $skill_name]
    
    if {![validate_skill $source]} {
        return 0
    }
    
    # Backup vor Änderungen (nur wenn target existiert)
    if {!$dry_run && [file exists $target]} {
        if {![create_backup $target $skill_name]} {
            return 0
        }
    }
    
    # Änderungen erkennen
    set changes {}
    foreach item [iter_sync_files $source] {
        lassign $item src_file rel_path
        set tgt_file [file join $target $rel_path]
        if {![file exists $tgt_file]} {
            lappend changes "ADD $rel_path"
        } elseif {[get_file_hash $src_file] ne [get_file_hash $tgt_file]} {
            lappend changes "UPDATE $rel_path"
        }
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
    copy_sync_files $source $target
    log "SYNC: $skill_name - Complete"
    return 1
}

# Sync Richtung Git → ClawHub
proc sync_to_clawhub {skill_name dry_run} {
    global GIT_DIR CLAWHUB_DIR
    set source [file join $GIT_DIR $skill_name]
    set target [file join $CLAWHUB_DIR $skill_name]
    
    if {![validate_skill $source]} {
        return 0
    }
    
    # Backup vor Änderungen (nur wenn target existiert)
    if {!$dry_run && [file exists $target]} {
        if {![create_backup $target $skill_name]} {
            return 0
        }
    }

    # Änderungen erkennen (gleiche Logik wie oben)
    set changes {}
    foreach item [iter_sync_files $source] {
        lassign $item src_file rel_path
        set tgt_file [file join $target $rel_path]
        if {![file exists $tgt_file]} {
            lappend changes "ADD $rel_path"
        } elseif {[get_file_hash $src_file] ne [get_file_hash $tgt_file]} {
            lappend changes "UPDATE $rel_path"
        }
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
    copy_sync_files $source $target
    log "SYNC: $skill_name - Complete"
    return 1
}

# Hauptfunktion
proc main {} {
    global argv
    set skill ""
    set direction ""
    set dry_run 0
    set force 0
    
    # Simple argument parsing
    set i 0
    while {$i < [llength $argv]} {
        set arg [lindex $argv $i]
        incr i
        switch -- $arg {
            --skill {
                if {$i < [llength $argv]} {
                    set skill [lindex $argv $i]
                    incr i
                }
            }
            --direction {
                if {$i < [llength $argv]} {
                    set direction [lindex $argv $i]
                    incr i
                }
            }
            --dry-run {
                set dry_run 1
            }
            --force {
                set force 1
            }
        }
    }
    
    if {$skill eq "" || $direction eq ""} {
        puts "Usage: $argv0 --skill <skill> --direction <to-git|to-clawhub> \[--dry-run\] \[--force\]"
        exit 1
    }
    
    log "Starting sync: $skill ($direction)"
    
    set success 0
    if {$direction eq "to-git"} {
        set success [sync_to_git $skill $dry_run]
    } else {
        set success [sync_to_clawhub $skill $dry_run]
    }
    
    if {!$success} {
        log "Sync failed" ERROR
        exit 1
    }
    
    log "Sync completed"
}

if {!$tcl_interactive} {
    main
}
