#!/usr/bin/env tclsh8.6
# sync_bulk.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/sync_bulk.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/sync_bulk.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

#
# Bulk Sync - Synchronisiert alle Skills
#

package require cmdline

# Globale Variablen
set CLAWHUB_DIR "/home/openclaw/.openclaw/workspace/skills"
set GIT_DIR "/home/openclaw/.openclaw/workspace/git/skills"

# Lade externe Funktionen
lappend auto_path "/home/openclaw/.openclaw/workspace/scripts"
package require sync_clawhub_git

proc sync_all_skills {dry_run} {
    global CLAWHUB_DIR GIT_DIR
    
    # Alle Skills finden
    set all_skills [dict create]
    
    # Skills aus ClawHub Verzeichnis
    if {[file exists $CLAWHUB_DIR] && [file isdirectory $CLAWHUB_DIR]} {
        foreach dir [glob -nocomplain -directory $CLAWHUB_DIR -type d *] {
            set skill_name [file tail $dir]
            if {![string match .* $skill_name]} {
                dict set all_skills $skill_name 1
            }
        }
    }
    
    # Skills aus Git Verzeichnis
    if {[file exists $GIT_DIR] && [file isdirectory $GIT_DIR]} {
        foreach dir [glob -nocomplain -directory $GIT_DIR -type d *] {
            set skill_name [file tail $dir]
            if {![string match .* $skill_name]} {
                dict set all_skills $skill_name 1
            }
        }
    }
    
    set skill_list [lsort [dict keys $all_skills]]
    sync_clawhub_git::log "Bulk Sync: [llength $skill_list] Skills gefunden"
    
    set results [dict create synced {} skipped {} failed {}]
    
    foreach skill $skill_list {
        set clawhub_path [file join $CLAWHUB_DIR $skill]
        set git_path [file join $GIT_DIR $skill]
        
        if {[catch {
            # Nur in ClawHub → zu Git
            if {[file exists $clawhub_path] && ![file exists $git_path]} {
                if {[sync_clawhub_git::validate_skill $clawhub_path]} {
                    sync_clawhub_git::log "Syncing $skill to Git..."
                    if {[sync_clawhub_git::sync_to_git $skill $dry_run]} {
                        dict lappend results synced "$skill → Git"
                    } else {
                        dict lappend results failed $skill
                    }
                } else {
                    dict lappend results skipped "$skill (validation failed)"
                }
            }
            
            # Nur in Git → zu ClawHub
            elseif {[file exists $git_path] && ![file exists $clawhub_path]} {
                if {[sync_clawhub_git::validate_skill $git_path]} {
                    sync_clawhub_git::log "Syncing $skill to ClawHub..."
                    if {[sync_clawhub_git::sync_to_clawhub $skill $dry_run]} {
                        dict lappend results synced "$skill → ClawHub"
                    } else {
                        dict lappend results failed $skill
                    }
                } else {
                    dict lappend results skipped "$skill (validation failed)"
                }
            }
            
            # In beiden - prüfe ob Update nötig
            elseif {[file exists $clawhub_path] && [file exists $git_path]} {
                # Vereinfachte Prüfung
                set clawhub_mtime 0
                foreach file [glob -nocomplain -directory $clawhub_path -recurse *] {
                    if {[file isfile $file]} {
                        set mtime [file mtime $file]
                        if {$mtime > $clawhub_mtime} {
                            set clawhub_mtime $mtime
                        }
                    }
                }
                
                set git_mtime 0
                foreach file [glob -nocomplain -directory $git_path -recurse *] {
                    if {[file isfile $file] && [string first ".git" $file] == -1} {
                        set mtime [file mtime $file]
                        if {$mtime > $git_mtime} {
                            set git_mtime $mtime
                        }
                    }
                }
                
                if {abs($clawhub_mtime - $git_mtime) > 60} {
                    if {$clawhub_mtime > $git_mtime} {
                        sync_clawhub_git::log "Updating $skill in Git..."
                        if {[sync_clawhub_git::sync_to_git $skill $dry_run]} {
                            dict lappend results synced "$skill → Git (update)"
                        } else {
                            dict lappend results failed $skill
                        }
                    } else {
                        sync_clawhub_git::log "Updating $skill in ClawHub..."
                        if {[sync_clawhub_git::sync_to_clawhub $skill $dry_run]} {
                            dict lappend results synced "$skill → ClawHub (update)"
                        } else {
                            dict lappend results failed $skill
                        }
                    }
                } else {
                    dict lappend results skipped "$skill (already synced)"
                }
            }
        } errmsg]} {
            sync_clawhub_git::log "Error processing $skill: $errmsg" "ERROR"
            dict lappend results failed $skill
        }
    }
    
    # Zusammenfassung
    puts "\n[string repeat = 60]"
    set mode "DRY-RUN"
    if {!$dry_run} {
        set mode "EXECUTED"
    }
    puts "Bulk Sync $mode - Zusammenfassung"
    puts [string repeat = 60]
    set synced_list [dict get $results synced]
    puts "✅ Synchronisiert: [llength $synced_list]"
    foreach item $synced_list {
        puts "   - $item"
    }
    set skipped_list [dict get $results skipped]
    puts "\n⏭️  Übersprungen: [llength $skipped_list]"
    if {[llength $skipped_list] <= 10} {
        foreach item $skipped_list {
            puts "   - $item"
        }
    } else {
        puts "   - [llength $skipped_list] Skills (bereits synchron oder Validierung fehlgeschlagen)"
    }
    set failed_list [dict get $results failed]
    puts "\n❌ Fehlgeschlagen: [llength $failed_list]"
    foreach item $failed_list {
        puts "   - $item"
    }
    puts [string repeat = 60]
}

proc main {} {
    # Kommandozeilenargumente parsen
    set options {
        {dry-run "Nur Änderungen anzeigen"}
        {execute "Sync ausführen"}
    }
    
    array set opts [cmdline::getoptions argv $options]
    
    set dry_run 1
    set execute 0
    
    if {[info exists opts(dry-run)]} {
        set dry_run 1
    }
    if {[info exists opts(execute)]} {
        set dry_run 0
        set execute 1
    }
    
    if {!$dry_run && !$execute} {
        puts "Bitte --dry-run oder --execute angeben"
        exit 1
    }
    
    sync_all_skills $dry_run
}

# Hauptprogramm ausführen
main
