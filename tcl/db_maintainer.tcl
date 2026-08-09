#!/usr/bin/env tclsh8.6
# db_maintainer.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/db_maintainer.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

#
# Database Maintainer Sub-Agent
# Automated database maintenance with 30min checks, hourly backups (3 days retention),
# band tree command execution for important/openclaw-tree.txt
#

package require sqlite3
package require json
package require fileutil

# Konstanten
set WORKSPACE "/home/openclaw/.openclaw/workspace"
set DB_DIR "$WORKSPACE/db"
set BACKUP_DIR "$DB_DIR/backups"
set LOG_DIR "$WORKSPACE/logs/db-maintainer"
set IMPORTANT_DIR "$WORKSPACE/important"

# Verzeichnisse erstellen
file mkdir $BACKUP_DIR
file mkdir $LOG_DIR

# Logger Klasse
proc Logger_new {} {
    variable log_file
    set today [clock format [clock seconds] -format "%Y-%m-%d"]
    set log_file "$LOG_DIR/$today.log"
    
    return "Logger"
}

proc Logger_log {level message} {
    variable log_file
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set line "\[$timestamp\] \[$level\] $message"
    puts $line
    set f [open $log_file a]
    puts $f $line
    close $f
}

proc Logger_info {msg} { Logger_log "INFO" $msg }
proc Logger_warn {msg} { Logger_log "WARN" $msg }
proc Logger_error {msg} { Logger_log "ERROR" $msg }

# DatabaseMaintainer Klasse
proc DatabaseMaintainer_new {} {
    variable state_file
    variable retention_days
    set state_file "$DB_DIR/maintainer_state.json"
    set retention_days 3
    return "DatabaseMaintainer"
}

proc DatabaseMaintainer_load_state {} {
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

proc DatabaseMaintainer_save_state {state} {
    variable state_file
    set f [open $state_file w]
    puts $f [::json::dict2json $state]
    close $f
}

proc DatabaseMaintainer_get_file_hash {filepath} {
    if {![file exists $filepath]} {
        return ""
    }
    if {[catch {set f [open $filepath r]}]} {
        return ""
    }
    set content [read $f]
    close $f
    return [::md5::md5 -hex $content]
}

proc DatabaseMaintainer_run_tree_command {} {
    global WORKSPACE
    if {[catch {exec tree -a -L 8 $WORKSPACE} result]} {
        Logger_error "tree command fehlgeschlagen: $result"
        return ""
    }
    Logger_info "tree -a -L 8 erfolgreich ausgeführt"
    return $result
}

proc DatabaseMaintainer_update_tree_file {tree_output} {
    global IMPORTANT_DIR WORKSPACE
    if {$tree_output eq ""} {
        return 0
    }
    
    set tree_file "$IMPORTANT_DIR/openclaw-tree.txt"
    set timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
    
    set header "# OpenClaw Workspace Tree
# Generiert: $timestamp
# Befehl: tree -a -L 8 $WORKSPACE
# Diese Datei wird automatisch von db-maintainer aktualisiert

"
    
    if {[catch {set f [open $tree_file w]}]} {
        Logger_error "Fehler beim Öffnen von openclaw-tree.txt"
        return 0
    }
    puts -nonewline $f $header
    puts -nonewline $f $tree_output
    close $f
    Logger_info "openclaw-tree.txt aktualisiert: $tree_file"
    return 1
}

proc DatabaseMaintainer_scan_documentations {} {
    global WORKSPACE
    set docs [list]
    
    # Finde alle .md Dateien
    set md_files [glob -nocomplain -types f -path $WORKSPACE *.md]
    foreach file [glob -nocomplain -types f -path $WORKSPACE */*.md] {
        lappend md_files $file
    }
    foreach file [glob -nocomplain -types f -path $WORKSPACE */*/*.md] {
        lappend md_files $file
    }
    foreach file [glob -nocomplain -types f -path $WORKSPACE */*/*/*.md] {
        lappend md_files $file
    }
    
    foreach md_file $md_files {
        # Prüfe ob es ein Symlink ist
        if {[file type $md_file] eq "link"} {
            continue
        }
        
        # Prüfe ob es in db/backups oder node_modules liegt
        set rel_path [string range $md_file [string length $WORKSPACE]+1 end]
        if {[string first "db/backups" $rel_path] != -1 || [string first "node_modules" $rel_path] != -1} {
            continue
        }
        
        set hash [DatabaseMaintainer_get_file_hash $md_file]
        set mtime [file mtime $md_file]
        lappend docs [dict create path $rel_path hash $hash mtime $mtime]
    }
    
    return $docs
}

proc DatabaseMaintainer_check_for_changes {} {
    set state [DatabaseMaintainer_load_state]
    set current_docs [DatabaseMaintainer_scan_documentations]
    
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

proc DatabaseMaintainer_update_databases {} {
    global WORKSPACE
    set script "$WORKSPACE/scripts/update_docs_db.py"
    if {![file exists $script]} {
        Logger_error "Update script nicht gefunden: $script"
        return 0
    }
    
    if {[catch {exec python3 $script} result]} {
        Logger_error "DB-Update fehlgeschlagen: $result"
        return 0
    }
    
    Logger_info "docs.db aktualisiert"
    return 1
}

proc DatabaseMaintainer_update_tree_db_v2 {} {
    global WORKSPACE
    set script "$WORKSPACE/scripts/tree_indexer_v2.py"
    if {![file exists $script]} {
        Logger_error "Tree DB v2 script nicht gefunden: $script"
        return 0
    }
    
    if {[catch {exec python3 $script} result]} {
        Logger_error "Tree-DB v2 fehlgeschlagen: $result"
        return 0
    }
    
    Logger_info "tree.db v2 aktualisiert"
    return 1
}

proc DatabaseMaintainer_create_backup {} {
    global DB_DIR BACKUP_DIR
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d_%H-%M"]
    
    foreach db_name [list "docs.db" "tree.db"] {
        set source "$DB_DIR/$db_name"
        if {[file exists $source]} {
            set backup_name "${timestamp}_${db_name}.bak"
            set backup_path "$BACKUP_DIR/$backup_name"
            file copy -force $source $backup_path
            Logger_info "Backup erstellt: $backup_name"
        }
    }
    
    return $timestamp
}

proc DatabaseMaintainer_cleanup_old_backups {} {
    variable retention_days
    global BACKUP_DIR
    set cutoff [expr {[clock seconds] - ($retention_days * 24 * 60 * 60)}]
    set deleted 0
    
    foreach db_name [list "docs.db" "tree.db"] {
        set pattern "$BACKUP_DIR/*_${db_name}.bak"
        foreach backup [glob -nocomplain $pattern] {
            # Extrahiere Datum aus Filename
            set basename [file tail $backup]
            set date_part [lindex [split $basename _] 0]
            set time_part [lindex [split $basename _] 1]
            
            if {[catch {clock scan "$date_part $time_part" -format "%Y-%m-%d %H-%M"} backup_time]} {
                Logger_warn "Konnte Backup-Datum nicht parsen: $basename"
                continue
            }
            
            if {$backup_time < $cutoff} {
                file delete $backup
                incr deleted
                Logger_info "Altes Backup gelöscht: [file tail $backup]"
            }
        }
    }
    
    if {$deleted == 0} {
        Logger_info "Keine alten Backups zum Löschen"
    } else {
        Logger_info "$deleted alte Backups gelöscht (< 3 Tage)"
    }
}

proc DatabaseMaintainer_run_cycle {} {
    Logger_info "============================================================"
    Logger_info "DB MAINTAINER CYCLE START"
    Logger_info "============================================================"
    
    set state [DatabaseMaintainer_load_state]
    
    # 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
    Logger_info "Führe tree -a -L 8 aus..."
    set tree_output [DatabaseMaintainer_run_tree_command]
    if {$tree_output ne ""} {
        DatabaseMaintainer_update_tree_file $tree_output
        dict set state last_tree_update [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
    }
    
    # 2. tree.db aktualisieren (intern v2)
    Logger_info "Aktualisiere tree.db v2..."
    DatabaseMaintainer_update_tree_db_v2
    
    # 3. Änderungen prüfen
    Logger_info "Prüfe auf Dokumentations-Änderungen..."
    lassign [DatabaseMaintainer_check_for_changes] changes current_hashes
    
    if {[llength $changes] > 0} {
        Logger_info "[llength $changes] Änderungen gefunden:"
        set count 0
        foreach change [lrange $changes 0 9] {
            Logger_info "  - $change"
            incr count
        }
        if {[llength $changes] > 10} {
            set remaining [expr {[llength $changes] - 10}]
            Logger_info "  ... und $remaining weitere"
        }
        
        # 4. docs.db aktualisieren
        Logger_info "Aktualisiere docs.db..."
        if {[DatabaseMaintainer_update_databases]} {
            dict set state last_check [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
            dict set state file_hashes $current_hashes
        }
    } else {
        Logger_info "Keine Dokumentations-Änderungen gefunden"
    }
    
    # 5. Prüfe ob Backup fällig (stündlich)
    set last_backup [dict get $state last_backup]
    set do_backup 1
    
    if {$last_backup ne ""} {
        if {[catch {clock scan $last_backup -format "%Y-%m-%dT%H:%M:%S"} last_backup_time]} {
            set last_backup_time 0
        }
        set now [clock seconds]
        set diff [expr {$now - $last_backup_time}]
        if {$diff < 3600} {
            set do_backup 0
        }
    }
    
    if {$do_backup} {
        Logger_info "Erstelle stündliches Backup..."
        set timestamp [DatabaseMaintainer_create_backup]
        dict set state last_backup [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
        
        # 6. Alte Backups aufräumen (3 Tage Retention)
        Logger_info "Räume alte Backups auf (3 Tage Retention)..."
        DatabaseMaintainer_cleanup_old_backups
    } else {
        Logger_info "Backup nicht nötig (letztes < 1h)"
    }
    
    DatabaseMaintainer_save_state $state
    
    Logger_info "============================================================"
    Logger_info "DB MAINTAINER CYCLE END"
    Logger_info "============================================================"
}

# Hauptfunktion
proc main {} {
    DatabaseMaintainer_new
    Logger_new
    
    if {[catch {DatabaseMaintainer_run_cycle} error]} {
        Logger_error "CRITICAL ERROR: $error"
        exit 1
    }
}

# Programmstart
main
