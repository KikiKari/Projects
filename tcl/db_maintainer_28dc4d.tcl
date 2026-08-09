#!/usr/bin/env tclsh8.6
# db_maintainer.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:skills/db-maintainer/scripts/db_maintainer.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Database Maintainer Sub-Agent
# Automated database maintenance with 30min checks, hourly backups (3 days retention),
# band tree command execution for important/openclaw-tree.txt

package require sqlite3
package require json
package require fileutil

set WORKSPACE "/home/openclaw/.openclaw/workspace"
set DB_DIR "$WORKSPACE/db"
set BACKUP_DIR "$DB_DIR/backups"
set LOG_DIR "$WORKSPACE/logs/db-maintainer"
set IMPORTANT_DIR "$WORKSPACE/important"

# Verzeichnisse erstellen
file mkdir $BACKUP_DIR
file mkdir $LOG_DIR


# Einfacher Logger mit Datei-Ausgabe
proc create_logger {} {
    variable logger
    set logger(log_file) [file join $::LOG_DIR [clock format [clock seconds] -format "%Y-%m-%d"].log]
}

proc logger_log {level message} {
    variable logger
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set line "\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] \[$level\] $message"
    puts $line
    set fh [open $logger(log_file) a]
    puts $fh $line
    close $fh
}

proc logger_info {msg} { logger_log "INFO" $msg }
proc logger_warn {msg} { logger_log "WARN" $msg }
proc logger_error {msg} { logger_log "ERROR" $msg }


# Database Maintainer Class
proc DatabaseMaintainer_new {} {
    variable maintainer
    set maintainer(logger) [create_logger]
    set maintainer(state_file) "$::DB_DIR/maintainer_state.json"
    set maintainer(retention_days) 3
}

proc load_state {} {
    variable maintainer
    if {[file exists $maintainer(state_file)]} {
        set fh [open $maintainer(state_file) r]
        set content [read $fh]
        close $fh
        return [json::json2dict $content]
    }
    return [dict create last_check {} last_backup {} last_tree_update {} file_hashes {}]
}

proc save_state {state} {
    variable maintainer
    set fh [open $maintainer(state_file) w]
    puts $fh [json::dict2json $state]
    close $fh
}

proc get_file_hash {filepath} {
    if {[catch {set fh [open $filepath r]}]} {
        return {}
    }
    fconfigure $fh -translation binary
    set content [read $fh]
    close $fh
    return [::md5::md5 -hex $content]
}

proc run_tree_command {} {
    if {[catch {exec tree -a -L 6 $::WORKSPACE} result]} {
        logger_error "tree command fehlgeschlagen: $result"
        return {}
    }
    logger_info "tree -a -L 6 erfolgreich ausgeführt"
    return $result
}

proc update_tree_file {tree_output} {
    if {$tree_output eq ""} {
        return 0
    }
    
    set tree_file "$::IMPORTANT_DIR/openclaw-tree.txt"
    set header "# OpenClaw Workspace Tree\n# Generiert: [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]\n# Befehl: tree -a -L 6 $::WORKSPACE\n# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n"
    
    if {[catch {
        set fh [open $tree_file w]
        puts -nonewline $fh $header
        puts -nonewline $fh $tree_output
        close $fh
        logger_info "openclaw-tree.txt aktualisiert: $tree_file"
        return 1
    } error]} {
        logger_error "Fehler beim Schreiben von openclaw-tree.txt: $error"
        return 0
    }
}

proc scan_documentations {} {
    set docs {}
    foreach pattern [list "*.md" "**/*.md"] {
        foreach md_file [glob -nocomplain -directory $::WORKSPACE $pattern] {
            if {[file isfile $md_file] && ![file islink $md_file]} {
                if {![string match "*db/backups*" $md_file] && ![string match "*node_modules*" $md_file]} {
                    lappend docs [dict create \
                        path [fileutil::stripPath $::WORKSPACE $md_file] \
                        hash [get_file_hash $md_file] \
                        mtime [file mtime $md_file]]
                }
            }
        }
    }
    return $docs
}

proc check_for_changes {} {
    set state [load_state]
    set current_docs [scan_documentations]
    
    set changes {}
    set current_hashes {}
    
    foreach doc $current_docs {
        set path [dict get $doc path]
        set hash [dict get $doc hash]
        dict set current_hashes $path $hash
        
        if {![dict exists $state file_hashes $path]} {
            lappend changes "NEW: $path"
        } elseif {[dict get $state file_hashes $path] ne $hash} {
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

proc update_databases {} {
    if {[catch {
        set result [exec python3 $::WORKSPACE/scripts/update_docs_db.py]
        logger_info "docs.db aktualisiert"
        return 1
    } error]} {
        logger_error "DB-Update fehlgeschlagen: $error"
        return 0
    }
}

proc update_tree_db_v2 {} {
    if {[catch {
        set result [exec python3 $::WORKSPACE/scripts/tree_indexer_v2.py]
        logger_info "tree.db v2 aktualisiert"
        return 1
    } error]} {
        logger_error "Tree-DB v2 fehlgeschlagen: $error"
        return 0
    }
}

proc create_backup {} {
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d_%H-%M"]
    
    foreach db_name [list "docs.db" "tree.db"] {
        set source "$::DB_DIR/$db_name"
        if {[file exists $source]} {
            set backup_name "${timestamp}_${db_name}.bak"
            set backup_path "$::BACKUP_DIR/$backup_name"
            file copy -force $source $backup_path
            logger_info "Backup erstellt: $backup_name"
        }
    }
    
    return $timestamp
}

proc cleanup_old_backups {} {
    variable maintainer
    set cutoff [expr {[clock seconds] - ($maintainer(retention_days) * 86400)}]
    set deleted 0
    
    foreach db_name [list "docs.db" "tree.db"] {
        foreach backup [glob -nocomplain "$::BACKUP_DIR/*_${db_name}.bak"] {
            # Extrahiere Datum aus filename (Format: YYYY-MM-DD_HH-MM)
            if {[regexp {^([^_]+)_([0-9-]+)_} [file tail $backup] match date_str time_str]} {
                if {[catch {
                    set backup_time [clock scan "${date_str}_${time_str}"]
                    if {$backup_time < $cutoff} {
                        file delete $backup
                        incr deleted
                        logger_info "Altes Backup gelöscht: [file tail $backup]"
                    }
                }]} {
                    logger_warn "Konnte Backup-Datum nicht parsen: [file tail $backup]"
                }
            } else {
                logger_warn "Konnte Backup-Datum nicht parsen: [file tail $backup]"
            }
        }
    }
    
    if {$deleted == 0} {
        logger_info "Keine alten Backups zum Löschen"
    } else {
        logger_info "$deleted alte Backups gelöscht (< 3 Tage)"
    }
}

proc run_cycle {} {
    logger_info [string repeat "=" 60]
    logger_info "DB MAINTAINER CYCLE START"
    logger_info [string repeat "=" 60]
    
    set state [load_state]
    
    # 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
    logger_info "Führe tree -a -L 8 aus..."
    set tree_output [run_tree_command]
    if {$tree_output ne ""} {
        update_tree_file $tree_output
        dict set state last_tree_update [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
    }
    
    # 2. tree.db aktualisieren (intern v2)
    logger_info "Aktualisiere tree.db v2..."
    update_tree_db_v2
    
    # 3. Änderungen prüfen
    logger_info "Prüfe auf Dokumentations-Änderungen..."
    lassign [check_for_changes] changes current_hashes
    
    if {[llength $changes] > 0} {
        logger_info "[llength $changes] Änderungen gefunden:"
        set count 0
        foreach change [lrange $changes 0 9] {
            logger_info "  - $change"
            incr count
        }
        if {[llength $changes] > 10} {
            logger_info "  ... und [expr {[llength $changes] - 10}] weitere"
        }
        
        # 4. docs.db aktualisieren
        logger_info "Aktualisiere docs.db..."
        if {[update_databases]} {
            dict set state last_check [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
            dict set state file_hashes $current_hashes
        }
    } else {
        logger_info "Keine Dokumentations-Änderungen gefunden"
    }
    
    # 5. Prüfe ob Backup fällig (stündlich)
    set last_backup [dict get $state last_backup]
    
    set do_backup 1
    if {$last_backup ne ""} {
        set last_backup_time [clock scan $last_backup]
        set do_backup [expr {[clock seconds] - $last_backup_time >= 3600}]
    }
    
    if {$do_backup} {
        logger_info "Erstelle stündliches Backup..."
        set timestamp [create_backup]
        dict set state last_backup [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
        
        # 6. Alte Backups aufräumen (3 Tage Retention)
        logger_info "Räume alte Backups auf (3 Tage Retention)..."
        cleanup_old_backups
    } else {
        logger_info "Backup nicht nötig (letztes < 1h)"
    }
    
    save_state $state
    
    logger_info [string repeat "=" 60]
    logger_info "DB MAINTAINER CYCLE END"
    logger_info [string repeat "=" 60]
}


proc main {} {
    DatabaseMaintainer_new
    
    if {[catch {
        run_cycle
    } error]} {
        logger_error "CRITICAL ERROR: $error"
        exit 1
    }
}

main
