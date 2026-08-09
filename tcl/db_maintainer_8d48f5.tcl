#!/usr/bin/env tclsh8.6
# db_maintainer.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Database Maintainer Sub-Agent
# Automated database maintenance with 30min checks, hourly backups (3 days retention),
# band tree command execution for important/openclaw-tree.txt

package require Tcl 8.6
package require sqlite3
package require md5
package require json

# Global variables
set WORKSPACE [expr {[info exists ::env(OPENCLAW_WORKSPACE)] ? $::env(OPENCLAW_WORKSPACE) : [file dirname [file dirname [info script]]]}]
set DB_DIR $WORKSPACE
set BACKUP_DIR [file join $WORKSPACE "db" "backups"]
set LOG_DIR [file join $WORKSPACE "logs" "db-maintainer"]
set IMPORTANT_DIR [file join $WORKSPACE "important"]

# Create directories
file mkdir $BACKUP_DIR
file mkdir $LOG_DIR
file mkdir $IMPORTANT_DIR

# Logger class
proc Logger_new {} {
    variable log_file
    variable instance_counter
    if {![info exists instance_counter]} {
        set instance_counter 0
    }
    incr instance_counter
    set obj "Logger_$instance_counter"
    
    namespace eval $obj {
        variable log_file
        set today [clock format [clock seconds] -format "%Y-%m-%d"]
        set log_file [file join $::LOG_DIR "${today}.log"]
    }
    
    proc ${obj}::log {level message} {
        variable log_file
        set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
        set line "\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] \[$level\] $message"
        puts $line
        set f [open $log_file a]
        puts $f $line
        close $f
    }
    
    proc ${obj}::info {msg} {
        log "INFO" $msg
    }
    
    proc ${obj}::warn {msg} {
        log "WARN" $msg
    }
    
    proc ${obj}::error {msg} {
        log "ERROR" $msg
    }
    
    return $obj
}

# DatabaseMaintainer class
proc DatabaseMaintainer_new {} {
    variable logger
    variable state_file
    variable retention_days
    variable instance_counter
    if {![info exists instance_counter]} {
        set instance_counter 0
    }
    incr instance_counter
    set obj "DatabaseMaintainer_$instance_counter"
    
    namespace eval $obj {
        variable logger
        variable state_file
        variable retention_days
        set logger [Logger_new]
        set state_file [file join $::DB_DIR "maintainer_state.json"]
        set retention_days 3
    }
    
    proc ${obj}::load_state {} {
        variable state_file
        if {[file exists $state_file]} {
            set f [open $state_file r]
            set content [read $f]
            close $f
            if {[catch {::json::json2dict $content} state]} {
                return [dict create last_check {} last_backup {} last_tree_update {} file_hashes [dict create]]
            }
            return $state
        }
        return [dict create last_check {} last_backup {} last_tree_update {} file_hashes [dict create]]
    }
    
    proc ${obj}::save_state {state} {
        variable state_file
        set f [open $state_file w]
        puts $f [::json::dict2json $state]
        close $f
    }
    
    proc ${obj}::get_file_hash {filepath} {
        if {[catch {set f [open $filepath r]}]} {
            return {}
        }
        set content [read $f]
        close $f
        return [::md5::md5 -hex $content]
    }
    
    proc ${obj}::_python_tree_fallback {{max_depth 8}} {
        set root $::WORKSPACE
        set lines [list $root]
        
        proc walk {dirpath prefix depth max_depth lines_var} {
            upvar $lines_var lines
            if {$depth > $max_depth} {
                return
            }
            if {[catch {set entries [lsort -dictionary [glob -nocomplain -dir $dirpath *]]}]} {
                return
            }
            set i 0
            set len [llength $entries]
            foreach entry $entries {
                set connector [expr {$i == $len - 1 ? "└── " : "├── "}]
                lappend lines "$prefix$connector[file tail $entry]"
                if {[file isdirectory $entry] && ![file type $entry] eq "link"} {
                    set extension [expr {$i == $len - 1 ? "    " : "│   "}]
                    walk $entry "$prefix$extension" [expr {$depth + 1}] $max_depth lines
                }
                incr i
            }
        }
        
        walk $root "" 1 $max_depth lines
        return [join $lines "\n"]\n
    }
    
    proc ${obj}::run_tree_command {} {
        variable logger
        if {[catch {exec tree -a -L 8 $::WORKSPACE} result]} {
            $logger warn "tree-Binary nicht installiert – nutze Python-Fallback"
            return [_python_tree_fallback]
        } else {
            $logger info "tree -a -L 8 erfolgreich ausgeführt"
            return $result
        }
    }
    
    proc ${obj}::update_tree_file {tree_output} {
        variable logger
        if {![string length $tree_output]} {
            return 0
        }
        
        set tree_file [file join $::IMPORTANT_DIR "openclaw-tree.txt"]
        set header "# OpenClaw Workspace Tree\n# Generiert: [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]\n# Befehl: tree -a -L 8 $::WORKSPACE\n# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n"
        
        if {[catch {set f [open $tree_file w]}]} {
            $logger error "Fehler beim Öffnen von openclaw-tree.txt"
            return 0
        }
        puts -nonewline $f $header
        puts -nonewline $f $tree_output
        close $f
        $logger info "openclaw-tree.txt aktualisiert: $tree_file"
        return 1
    }
    
    proc ${obj}::scan_documentations {} {
        set docs [list]
        foreach pattern {"*.md" "*/*.md"} {
            foreach md_file [glob -nocomplain -dir $::WORKSPACE $pattern] {
                if {[file isfile $md_file] && [file type $md_file] ne "link"} {
                    if {![string match "*db/backups*" $md_file] && ![string match "*node_modules*" $md_file]} {
                        lappend docs [dict create \
                            path [string range $md_file [string length $::WORKSPACE]+1 end] \
                            hash [get_file_hash $md_file] \
                            mtime [file mtime $md_file]]
                    }
                }
            }
        }
        return $docs
    }
    
    proc ${obj}::check_for_changes {} {
        set state [load_state]
        set current_docs [scan_documentations]
        
        set changes [list]
        set current_hashes [dict create]
        
        foreach doc $current_docs {
            set path [dict get $doc path]
            set hash [dict get $doc hash]
            dict set current_hashes $path $hash
            
            if {![dict exists [dict get $state file_hashes] $path]} {
                lappend changes "NEW: $path"
            } elseif {[dict get [dict get $state file_hashes] $path] ne $hash} {
                lappend changes "CHANGED: $path"
            }
        }
        
        # Prüfe auf gelöschte Dateien
        dict for {old_path old_hash} [dict get $state file_hashes] {
            if {![dict exists $current_hashes $old_path]} {
                lappend changes "DELETED: $old_path"
            }
        }
        
        return [list $changes $current_hashes]
    }
    
    proc ${obj}::update_databases {} {
        variable logger
        if {[catch {exec python3 [file join $::WORKSPACE scripts update_docs_db.py]} result]} {
            $logger error "DB-Update Exception: $result"
            return 0
        }
        if {[lindex $result 0] eq "0"} {
            $logger info "docs.db aktualisiert"
            return 1
        } else {
            $logger error "DB-Update fehlgeschlagen: [lindex $result 1]"
            return 0
        }
    }
    
    proc ${obj}::update_tree_db_v2 {} {
        variable logger
        if {[catch {exec python3 [file join $::WORKSPACE scripts tree_indexer_v2.py]} result]} {
            $logger error "Tree-DB v2 Exception: $result"
            return 0
        }
        if {[lindex $result 0] eq "0"} {
            $logger info "tree.db v2 aktualisiert"
            return 1
        } else {
            $logger error "Tree-DB v2 fehlgeschlagen: [lindex $result 1]"
            return 0
        }
    }
    
    proc ${obj}::create_backup {} {
        variable logger
        set timestamp [clock format [clock seconds] -format "%Y-%m-%d_%H-%M"]
        
        foreach db_name {"docs.db" "tree.db"} {
            set source [file join $::DB_DIR $db_name]
            if {[file exists $source]} {
                set backup_name "${timestamp}_${db_name}.bak"
                set backup_path [file join $::BACKUP_DIR $backup_name]
                file copy -force $source $backup_path
                $logger info "Backup erstellt: $backup_name"
            }
        }
        
        return $timestamp
    }
    
    proc ${obj}::cleanup_old_backups {} {
        variable logger
        variable retention_days
        set cutoff [expr {[clock seconds] - ($retention_days * 24 * 60 * 60)}]
        set deleted 0
        
        foreach db_name {"docs.db" "tree.db"} {
            foreach backup [glob -nocomplain -dir $::BACKUP_DIR "*_${db_name}.bak"] {
                # Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
                if {[regexp {^([0-9]{4}-[0-9]{2}-[0-9]{2})_([0-9]{2}-[0-9]{2})_} [file tail $backup] match date_str time_str]} {
                    if {[catch {clock scan "${date_str}_${time_str}" -format "%Y-%m-%d_%H-%M"} backup_time]} {
                        $logger warn "Konnte Backup-Datum nicht parsen: [file tail $backup]"
                        continue
                    }
                    
                    if {$backup_time < $cutoff} {
                        file delete $backup
                        incr deleted
                        $logger info "Altes Backup gelöscht: [file tail $backup]"
                    }
                } else {
                    $logger warn "Konnte Backup-Datum nicht parsen: [file tail $backup]"
                }
            }
        }
        
        if {$deleted == 0} {
            $logger info "Keine alten Backups zum Löschen"
        } else {
            $logger info "$deleted alte Backups gelöscht (< 3 Tage)"
        }
    }
    
    proc ${obj}::run_cycle {} {
        variable logger
        $logger info [string repeat "=" 60]
        $logger info "DB MAINTAINER CYCLE START"
        $logger info [string repeat "=" 60]
        
        set state [load_state]
        
        # 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
        $logger info "Führe tree -a -L 8 aus..."
        set tree_output [run_tree_command]
        if {[string length $tree_output]} {
            update_tree_file $tree_output
            dict set state last_tree_update [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
        }
        
        # 2. tree.db aktualisieren (intern v2)
        $logger info "Aktualisiere tree.db v2..."
        update_tree_db_v2
        
        # 3. Änderungen prüfen
        $logger info "Prüfe auf Dokumentations-Änderungen..."
        lassign [check_for_changes] changes current_hashes
        
        if {[llength $changes]} {
            $logger info "[llength $changes] Änderungen gefunden:"
            set i 0
            foreach change [lrange $changes 0 9] {
                $logger info "  - $change"
                incr i
            }
            if {[llength $changes] > 10} {
                $logger info "  ... und [expr {[llength $changes] - 10}] weitere"
            }
            
            # 4. docs.db aktualisieren
            $logger info "Aktualisiere docs.db..."
            if {[update_databases]} {
                dict set state last_check [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
                dict set state file_hashes $current_hashes
            }
        } else {
            $logger info "Keine Dokumentations-Änderungen gefunden"
        }
        
        # 5. Prüfe ob Backup fällig (stündlich)
        set last_backup [dict get $state last_backup]
        
        if {$last_backup ne ""} {
            set last_backup_time [clock scan $last_backup]
            set do_backup [expr {[clock seconds] - $last_backup_time >= 60*60}]
        } else {
            set do_backup 1
        }
        
        if {$do_backup} {
            $logger info "Erstelle stündliches Backup..."
            set timestamp [create_backup]
            dict set state last_backup [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
            
            # 6. Alte Backups aufräumen (3 Tage Retention)
            $logger info "Räume alte Backups auf (3 Tage Retention)..."
            cleanup_old_backups
        } else {
            $logger info "Backup nicht nötig (letztes < 1h)"
        }
        
        save_state $state
        
        $logger info [string repeat "=" 60]
        $logger info "DB MAINTAINER CYCLE END"
        $logger info [string repeat "=" 60]
    }
    
    return $obj
}

proc main {} {
    set maintainer [DatabaseMaintainer_new]
    
    if {[catch {${maintainer}::run_cycle} error]} {
        ${maintainer}::logger error "CRITICAL ERROR: $error"
        exit 1
    }
}

if {[info script] eq $argv0} {
    main
}
