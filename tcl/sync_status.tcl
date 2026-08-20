#!/usr/bin/env tclsh8.6
# sync_status.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/sync_status.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/sync_status.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

#
# Sync Status - Zeigt Status aller Skills
#

package require json

# Globale Variablen
set CLAWHUB_DIR "/home/openclaw/.openclaw/workspace/skills"
set GIT_DIR "/home/openclaw/.openclaw/workspace/git/skills"
set STATE_FILE "/home/openclaw/.openclaw/workspace/db/sync_state.json"

# Hilfsfunktion zur Rekursion durch Verzeichnisse
proc get_max_mtime {path exclude} {
    set max_time 0
    foreach file [glob -nocomplain -directory $path *] {
        if {[file isdirectory $file]} {
            if {$exclude eq "" || [string first $exclude $file] == -1} {
                set dir_time [get_max_mtime $file $exclude]
                if {$dir_time > $max_time} {
                    set max_time $dir_time
                }
            }
        } elseif {[file isfile $file]} {
            set mtime [file mtime $file]
            if {$mtime > $max_time} {
                set max_time $mtime
            }
        }
    }
    return $max_time
}

# Prüft Status eines Skills
proc check_skill_status {skill_name} {
    global CLAWHUB_DIR GIT_DIR
    
    set clawhub_path [file join $CLAWHUB_DIR $skill_name]
    set git_path [file join $GIT_DIR $skill_name]
    
    set status [dict create \
        name $skill_name \
        in_clawhub [expr {[file isdirectory $clawhub_path]}] \
        in_git [expr {[file isdirectory $git_path]}] \
        has_git_repo [expr {[file isdirectory $git_path] && [file isdirectory [file join $git_path .git]]}] \
        status "unknown" \
        last_modified [dict create]
    ]
    
    # Status bestimmen
    set in_clawhub [dict get $status in_clawhub]
    set in_git [dict get $status in_git]
    
    if {$in_clawhub && !$in_git} {
        dict set status status "only_clawhub"
    } elseif {$in_git && !$in_clawhub} {
        dict set status status "only_git"
    } elseif {$in_clawhub && $in_git} {
        # Timestamps vergleichen
        if {[catch {
            set clawhub_mtime [get_max_mtime $clawhub_path ""]
            set git_mtime [get_max_mtime $git_path ".git"]
            
            dict set status last_modified clawhub [clock format $clawhub_mtime -format "%Y-%m-%d %H:%M:%S"]
            dict set status last_modified git [clock format $git_mtime -format "%Y-%m-%d %H:%M:%S"]
            
            set diff [expr {abs($clawhub_mtime - $git_mtime)}]
            if {$diff < 60} {
                dict set status status "synced"
            } elseif {$clawhub_mtime > $git_mtime} {
                dict set status status "clawhub_newer"
            } else {
                dict set status status "git_newer"
            }
        } err]} {
            dict set status status "error"
        }
    }
    
    return $status
}

# Hauptfunktion
proc main {} {
    global CLAWHUB_DIR GIT_DIR STATE_FILE
    
    puts [string repeat "=" 80]
    puts "ClawHub ↔ Git Sync Status"
    puts [string repeat "=" 80]
    puts "Zeitpunkt: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
    puts ""
    
    # Alle Skills finden
    set all_skills [dict create]
    
    if {[file isdirectory $CLAWHUB_DIR]} {
        foreach d [glob -nocomplain -directory $CLAWHUB_DIR *] {
            if {[file isdirectory $d] && ![string match .* [file tail $d]]} {
                dict set all_skills [file tail $d] 1
            }
        }
    }
    
    if {[file isdirectory $GIT_DIR]} {
        foreach d [glob -nocomplain -directory $GIT_DIR *] {
            if {[file isdirectory $d] && ![string match .* [file tail $d]]} {
                dict set all_skills [file tail $d] 1
            }
        }
    }
    
    # Status-Kategorien
    set categories [dict create \
        synced [list] \
        clawhub_newer [list] \
        git_newer [list] \
        only_clawhub [list] \
        only_git [list] \
        error [list]
    ]
    
    # Status für jeden Skill prüfen
    set skill_names [lsort [dict keys $all_skills]]
    foreach skill $skill_names {
        set status [check_skill_status $skill]
        set cat [dict get $status status]
        dict lappend categories $cat $status
    }
    
    # Ausgabe
    set total_count [llength $skill_names]
    puts "📊 Gesamt: $total_count Skills\n"
    
    # Synchronisiert
    set synced_list [dict get $categories synced]
    if {[llength $synced_list] > 0} {
        puts "✅ Synchronisiert ([llength $synced_list])"
        foreach s $synced_list {
            puts "   - [dict get $s name]"
        }
        puts ""
    }
    
    # ClawHub neuer
    set clawhub_newer_list [dict get $categories clawhub_newer]
    if {[llength $clawhub_newer_list] > 0} {
        puts "🔄 ClawHub neuer ([llength $clawhub_newer_list])"
        foreach s $clawhub_newer_list {
            set lm [dict get $s last_modified]
            puts "   - [dict get $s name] (ClawHub: [dict get $lm clawhub])"
        }
        puts ""
    }
    
    # Git neuer
    set git_newer_list [dict get $categories git_newer]
    if {[llength $git_newer_list] > 0} {
        puts "🔄 Git neuer ([llength $git_newer_list])"
        foreach s $git_newer_list {
            set lm [dict get $s last_modified]
            puts "   - [dict get $s name] (Git: [dict get $lm git])"
        }
        puts ""
    }
    
    # Nur in ClawHub
    set only_clawhub_list [dict get $categories only_clawhub]
    if {[llength $only_clawhub_list] > 0} {
        puts "📦 Nur in ClawHub ([llength $only_clawhub_list])"
        foreach s $only_clawhub_list {
            puts "   - [dict get $s name]"
        }
        puts ""
    }
    
    # Nur in Git
    set only_git_list [dict get $categories only_git]
    if {[llength $only_git_list] > 0} {
        puts "📁 Nur in Git ([llength $only_git_list])"
        foreach s $only_git_list {
            puts "   - [dict get $s name]"
        }
        puts ""
    }
    
    # Fehler
    set error_list [dict get $categories error]
    if {[llength $error_list] > 0} {
        puts "❌ Fehler ([llength $error_list])"
        foreach s $error_list {
            puts "   - [dict get $s name]"
        }
        puts ""
    }
    
    # State-File Info
    if {[file exists $STATE_FILE]} {
        if {[catch {
            set fp [open $STATE_FILE r]
            set json_data [read $fp]
            close $fp
            set state [::json::json2dict $json_data]
            if {[dict exists $state last_sync]} {
                set last_sync_dict [dict get $state last_sync]
                set last_runs [lsort [dict keys $last_sync_dict]]
                if {[llength $last_runs] > 0} {
                    set last_run [lindex $last_runs end]
                    puts "📅 Letzter automatischer Sync: $last_run"
                }
            }
        } err]} {
            # Ignoriere Fehler beim Lesen der State-Datei
        }
    }
    
    puts [string repeat "=" 80]
}

# Programmstart
if {$::argv0 eq [info script]} {
    main
}
