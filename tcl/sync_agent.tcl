#!/usr/bin/env tclsh8.6
# sync_agent.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/clawhub-git-sync-agent/scripts/sync_agent.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

#
# Permanenter ClawHub ↔ Git Sync Agent
# Multi-Node fähig, stündliche Ausführung
#

package require Tcl 8.6
package require json
package require fileutil

# Globale Konfiguration
set CLAWHUB_DIR "/home/openclaw/.openclaw/workspace/skills"
set GIT_DIR "/home/openclaw/.openclaw/workspace/git/skills"
set STATE_FILE "/home/openclaw/.openclaw/workspace/db/sync_state.json"
set BACKUP_ROOT "/home/openclaw/.openclaw/workspace/backups/sync_agent"
set SCRIPTS_DIR "/home/openclaw/.openclaw/workspace/scripts"

# Lade externe Funktionen
source [file join $SCRIPTS_DIR sync_clawhub_git.tcl]

proc load_state {} {
    # Lädt den Sync-State
    global STATE_FILE
    if {[file exists $STATE_FILE]} {
        set fd [open $STATE_FILE r]
        set data [read $fd]
        close $fd
        return [::json::json2dict $data]
    }
    return [dict create sync_history {} pending {}]
}

proc save_state {state} {
    # Speichert den Sync-State
    global STATE_FILE
    file mkdir [file dirname $STATE_FILE]
    set fd [open $STATE_FILE w]
    puts $fd [::json::dict2json $state]
    close $fd
}

proc get_all_skills {} {
    # Findet nur valide Skill-Verzeichnisse in beiden Verzeichnissen.
    global CLAWHUB_DIR GIT_DIR
    
    set clawhub_skills [list]
    if {[file exists $CLAWHUB_DIR] && [file isdirectory $CLAWHUB_DIR]} {
        foreach d [glob -nocomplain -directory $CLAWHUB_DIR *] {
            if {[file isdirectory $d] && 
                ![string match {.*) [file tail $d]] && 
                [file exists [file join $d SKILL.md]]} {
                lappend clawhub_skills [file tail $d]
            }
        }
    }
    
    set git_skills [list]
    if {[file exists $GIT_DIR] && [file isdirectory $GIT_DIR]} {
        foreach d [glob -nocomplain -directory $GIT_DIR *] {
            if {[file isdirectory $d] && 
                ![string match {.*) [file tail $d]] && 
                [file exists [file join $d SKILL.md]]} {
                lappend git_skills [file tail $d]
            }
        }
    }
    
    # Vereinigung beider Listen
    set all_skills {}
    foreach skill $clawhub_skills {
        if {$skill ni $all_skills} {
            lappend all_skills $skill
        }
    }
    foreach skill $git_skills {
        if {$skill ni $all_skills} {
            lappend all_skills $skill
        }
    }
    return $all_skills
}

proc init_git_repo {skill_path skill_name} {
    # Initialisiert Git-Repo wenn nötig
    set git_dir [file join $skill_path .git]
    if {![file exists $git_dir]} {
        set oldpwd [pwd]
        cd $skill_path
        if {[catch {exec git init} result]} {
            log "Fehler bei git init für $skill_name: $result" ERROR
        }
        if {[catch {exec git add .} result]} {
            log "Fehler bei git add für $skill_name: $result" ERROR
        }
        if {[catch {exec git commit -m "Initial commit: $skill_name skill"} result]} {
            log "Fehler bei git commit für $skill_name: $result" ERROR
        }
        log "Git initialized for $skill_name"
        cd $oldpwd
    }
}

proc backup_skill_dir {skill_path skill_name} {
    # Creates a timestamped tar.gz backup of a skill directory.
    if {![file exists $skill_path]} {
        return
    }
    global BACKUP_ROOT
    set timestamp [clock format [clock seconds] -format "%Y%m%d%H%M%S"]
    set backup_dir [file join $BACKUP_ROOT $timestamp]
    file mkdir $backup_dir
    set archive_name "${skill_name}_${timestamp}.tar.gz"
    set archive_path [file join $backup_dir $archive_name]
    
    if {[catch {exec tar -czf $archive_path -C $skill_path .} result]} {
        log "Fehler beim Backup von $skill_name: $result" ERROR
    } else {
        log "Backup created for $skill_name at $archive_path"
    }
}

proc get_hashes {skill_dir} {
    # Erzeugt ein Dictionary von Datei-Hashes für einen Skill-Ordner.
    set hashes [dict create]
    foreach file [glob -nocomplain -directory $skill_dir -types f **] {
        # Ignoriere .git Verzeichnisse
        if {[string first ".git" $file] == -1} {
            set rel_path [fileutil::stripPath $skill_dir $file]
            dict set hashes $rel_path [get_file_hash $file]
        }
    }
    return $hashes
}

proc sync_skill_bidirectional {skill_name {dry_run false}} {
    # Bidirektionale Synchronisation eines Skills
    global CLAWHUB_DIR GIT_DIR
    
    set clawhub_path [file join $CLAWHUB_DIR $skill_name]
    set git_path [file join $GIT_DIR $skill_name]
    
    # Fall 1: Nur in ClawHub → zu Git
    if {[file exists $clawhub_path] && ![file exists $git_path]} {
        log "NEW in ClawHub: $skill_name → syncing to Git"
        if {!$dry_run} {
            backup_skill_dir $clawhub_path "${skill_name}_clawhub"
        }
        if {[sync_to_git $skill_name $dry_run]} {
            if {!$dry_run} {
                init_git_repo $git_path $skill_name
            }
            return "synced_to_git"
        }
    }
    
    # Fall 2: Nur in Git → zu ClawHub
    if {[file exists $git_path] && ![file exists $clawhub_path]} {
        log "NEW in Git: $skill_name → syncing to ClawHub"
        if {!$dry_run} {
            backup_skill_dir $git_path "${skill_name}_git"
        }
        if {[sync_to_clawhub $skill_name $dry_run]} {
            return "synced_to_clawhub"
        }
    }
    
    # Fall 3: In beiden vorhanden → Vergleiche Timestamps
    if {[file exists $clawhub_path] && [file exists $git_path]} {
        # --- MODIFIZIERTE LOGIK: Robusterer Datei-Hash-Vergleich ---
        
        # Stelle sicher, dass beide als gültige Skills validiert werden
        if {![validate_skill $clawhub_path]} {
            log "Validation failed for ClawHub skill: $skill_name" ERROR
            return "error"
        }
        if {![validate_skill $git_path]} {
            log "Validation failed for Git skill: $skill_name" ERROR
            return "error"
        }
        
        # Berechne Hashes für clawhub und git
        set clawhub_hashes [get_hashes $clawhub_path]
        set git_hashes [get_hashes $git_path]
        
        if {$clawhub_hashes != $git_hashes} {
            log "Content difference detected for: $skill_name"
            
            # Einfache (aber oft ausreichende) Logik: Wenn clawhub neuer ist, lade hoch.
            # Eine detailliertere Strategie (z.B. welche Version von Git übernehmen)
            # könnte hier implementiert werden, falls nötig.
            # Für jetzt: Wenn sie sich unterscheiden, priorisieren wir ClawHub > Git
            # und aktualisieren Git.
            
            set clawhub_mtime [file mtime $clawhub_path]
            set git_mtime [file mtime $git_path]
            set direction [expr {$clawhub_mtime >= $git_mtime ? "to-git" : "to-clawhub"}]
            log "UPDATE: $skill_name → syncing $direction"
            
            if {!$dry_run} {
                backup_skill_dir $clawhub_path "${skill_name}_clawhub"
                backup_skill_dir $git_path "${skill_name}_git"
            }
            
            set success 0
            if {$direction eq "to-git"} {
                set success [sync_to_git $skill_name $dry_run]
                if {$success && !$dry_run} {
                    set oldpwd [pwd]
                    cd $git_path
                    if {[catch {exec git add .} result]} {
                        log "Fehler bei git add: $result" ERROR
                    }
                    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M"]
                    if {[catch {exec git commit -m "Sync from ClawHub content diff: $timestamp"} result]} {
                        log "Fehler bei git commit: $result" ERROR
                    }
                    cd $oldpwd
                }
            } else {
                set success [sync_to_clawhub $skill_name $dry_run]
            }
            
            if {$success} {
                return [expr {$direction eq "to-git" ? "updated_git" : "updated_clawhub"}]
            } else {
                log "Failed to sync $skill_name to Git after content diff" ERROR
                return "error"
            }
        } else {
            log "Content is identical for: $skill_name"
            return "no_change"
        }
    }
    
    return "no_change"
}

proc main {argv} {
    # Hauptfunktion des Sync-Agents
    set dry_run false
    
    # Parse command line arguments
    foreach arg $argv {
        if {$arg eq "--dry-run"} {
            set dry_run true
        }
    }
    
    log "=== ClawHub ↔ Git Sync Agent gestartet ==="
    
    set state [load_state]
    set all_skills [get_all_skills]
    log "Gefundene Skills: [llength $all_skills]"
    
    set results [dict create \
        synced_to_git {} \
        synced_to_clawhub {} \
        updated_git {} \
        updated_clawhub {} \
        no_change {} \
        errors {}]
    
    foreach skill [lsort $all_skills] {
        if {[catch {
            set result [sync_skill_bidirectional $skill $dry_run]
            dict lappend results $result $skill
        } error]} {
            log "ERROR syncing $skill: $error" ERROR
            dict lappend results errors $skill
        }
    }
    
    # Zusammenfassung
    log "\n=== SYNC ZUSAMMENFASSUNG ==="
    set synced_to_git [dict get $results synced_to_git]
    log "Neu in Git: [llength $synced_to_git] - $synced_to_git"
    
    set synced_to_clawhub [dict get $results synced_to_clawhub]
    log "Neu in ClawHub: [llength $synced_to_clawhub] - $synced_to_clawhub"
    
    set updated_git [dict get $results updated_git]
    log "Git aktualisiert: [llength $updated_git] - $updated_git"
    
    set updated_clawhub [dict get $results updated_clawhub]
    log "ClawHub aktualisiert: [llength $updated_clawhub] - $updated_clawhub"
    
    set no_change [dict get $results no_change]
    log "Keine Änderung: [llength $no_change]"
    
    set errors [dict get $results errors]
    log "Fehler: [llength $errors] - $errors"
    
    # Ein Dry-Run bleibt vollständig nicht-mutierend (abgesehen vom Audit-Log).
    if {!$dry_run} {
        if {![dict exists $state sync_history]} {
            dict set state sync_history {}
        }
        set history [dict get $state sync_history]
        lappend history [dict create \
            timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"] \
            results $results]
        
        # Nur letzte 100 Einträge behalten
        set len [llength $history]
        if {$len > 100} {
            set start [expr {$len - 100}]
            set history [lrange $history $start end]
        }
        dict set state sync_history $history
        save_state $state
    }
    
    log "=== Sync Agent beendet ===\n"
}

# Starte das Programm
main $argv
