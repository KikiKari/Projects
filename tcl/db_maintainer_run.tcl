#!/usr/bin/env tclsh8.6
# db_maintainer_run.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:scripts/db_maintainer_run.py
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

# Database Maintainer Sub-Agent
# Automated database maintenance with 30min checks, hourly backups (3 days retention),
# band tree command execution for important/openclaw-tree.txt

package require Tcl 8.6
package require sqlite3
package require sha256
package require fileutil

set WORKSPACE "/workspace"
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
    set log_file "$::LOG_DIR/$today.log"
    
    proc log {level message} {
        set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
        set line "\[$timestamp\] \[$level\] $message"
        puts $line
        set f [open $log_file a]
        puts $f $line
        close $f
    }
    
    proc info {msg} { log INFO $msg }
    proc warn {msg} { log WARN $msg }
    proc error {msg} { log ERROR $msg }
    
    return ""
}

# DatabaseMaintainer Klasse
namespace eval DatabaseMaintainer {
    variable logger
    variable state_file
    variable retention_days
    
    proc init {} {
        variable logger [Logger_new]
        variable state_file "$::DB_DIR/maintainer_state.json"
        variable retention_days 3
    }
    
    proc load_state {} {
        variable state_file
        if {[file exists $state_file]} {
            set f [open $state_file r]
            set content [read $f]
            close $f
            return [dict create {*}[json::json2dict $content]]
        }
        return [dict create last_check "" last_backup "" last_tree_update "" file_hashes [dict create]]
    }
    
    proc save_state {state} {
        variable state_file
        set f [open $state_file w]
        puts $f [json::dict2json $state]
        close $f
    }
    
    proc get_file_hash {filepath} {
        if {[catch {open $filepath r} f]} {
            return ""
        }
        set content [read $f]
        close $f
        return [sha2::sha256 -hex $content]
    }
    
    proc run_tree_command {} {
        variable logger
        if {[catch {exec tree -a -L 6 $::WORKSPACE} result]} {
            $logger error "tree command fehlgeschlagen: $result"
            return ""
        }
        $logger info "tree -a -L 6 erfolgreich ausgeführt"
        return $result
    }
    
    proc update_tree_file {tree_output} {
        variable logger
        if {$tree_output eq ""} {
            return 0
        }
        
        set tree_file "$::IMPORTANT_DIR/openclaw-tree.txt"
        set timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
        set header "# OpenClaw Workspace Tree\n# Generiert: $timestamp\n# Befehl: tree -a -L 6 $::WORKSPACE\n# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n"
        
        if {[catch {open $tree_file w} f]} {
            $logger error "Fehler beim Öffnen von openclaw-tree.txt: $f"
            return 0
        }
        puts -nonewline $f $header
        puts -nonewline $f $tree_output
        close $f
        $logger info "openclaw-tree.txt aktualisiert: $tree_file"
        return 1
    }
    
    proc scan_documentations {} {
        set docs [list]
        foreach pattern {"*.md" "*/*.md"} {
            foreach md_file [glob -nocomplain -directory $::WORKSPACE $pattern] {
                if {[file isfile $md_file] && ![file islink $md_file]} {
                    set rel_path [string range $md_file [string length $::WORKSPACE]+1 end]
                    if {![string match "*db/backups*" $rel_path] && ![string match "*node_modules*" $rel_path]} {
                        lappend docs [dict create \
                            path $rel_path \
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
    
    proc update_databases {} {
        variable logger
        if {[catch {exec python3 $::WORKSPACE/scripts/update_docs_db.py} result]} {
            $logger error "DB-Update fehlgeschlagen: $result"
            return 0
        }
        $logger info "docs.db aktualisiert"
        return 1
    }
    
    proc update_tree_db_v2 {} {
        variable logger
        if {[catch {exec python3 $::WORKSPACE/scripts/tree_indexer_v2.py} result]} {
            $logger error "Tree-DB v2 fehlgeschlagen: $result"
            return 0
        }
        $logger info "tree.db v2 aktualisiert"
        return 1
    }
    
    proc create_backup {} {
        variable logger
        set timestamp [clock format [clock seconds] -format "%Y-%m-%d_%H-%M"]
        
        foreach db_name {"docs.db" "tree.db"} {
            set source "$::DB_DIR/$db_name"
            if {[file exists $source]} {
                set backup_name "${timestamp}_${db_name}.bak"
                set backup_path "$::BACKUP_DIR/$backup_name"
                file copy -force $source $backup_path
                $logger info "Backup erstellt: $backup_name"
            }
        }
        return $timestamp
    }
    
    proc cleanup_old_backups {} {
        variable logger
        variable retention_days
        set cutoff [expr {[clock seconds] - ($retention_days * 86400)}]
        set deleted 0
        
        foreach db_name {"docs.db" "tree.db"} {
            set pattern "$::BACKUP_DIR/*_${db_name}.bak"
            foreach backup [glob -nocomplain $pattern] {
                # Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
                if {[regexp {([0-9]{4}-[0-9]{2}-[0-9]{2})_([0-9]{2}-[0-9]{2})} [file tail $backup] match date_str time_str]} {
                    if {[catch {clock scan "$date_str $time_str" -format "%Y-%m-%d %H-%M"} backup_time]} {
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
    
    proc run_cycle {} {
        variable logger
        variable retention_days
        $logger info "============================================================"
        $logger info "DB MAINTAINER CYCLE START"
        $logger info "============================================================"
        
        set state [load_state]
        
        # 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
        $logger info "Führe tree -a -L 8 aus..."
        set tree_output [run_tree_command]
        if {$tree_output ne ""} {
            update_tree_file $tree_output
            dict set state last_tree_update [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
        }
        
        # 2. tree.db aktualisieren (intern v2)
        $logger info "Aktualisiere tree.db v2..."
        update_tree_db_v2
        
        # 3. Änderungen prüfen
        $logger info "Prüfe auf Dokumentations-Änderungen..."
        lassign [check_for_changes] changes current_hashes
        
        if {[llength $changes] > 0} {
            $logger info "[llength $changes] Änderungen gefunden:"
            set count 0
            foreach change [lrange $changes 0 9] {
                $logger info "  - $change"
                incr count
            }
            if {[llength $changes] > 10} {
                set remaining [expr {[llength $changes] - 10}]
                $logger info "  ... und $remaining weitere"
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
            set last_backup_time [clock scan $last_backup -format "%Y-%m-%dT%H:%M:%S"]
            set do_backup [expr {[clock seconds] - $last_backup_time >= 3600}]
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
        
        $logger info "============================================================"
        $logger info "DB MAINTAINER CYCLE END"
        $logger info "============================================================"
    }
}

proc main {} {
    DatabaseMaintainer::init
    if {[catch {DatabaseMaintainer::run_cycle} error]} {
        DatabaseMaintainer::variable logger
        $logger error "CRITICAL ERROR: $error"
        exit 1
    }
}

# JSON Unterstützung laden
if {![info commands json::json2dict] || ![info commands json::dict2json]} {
    # Einfache JSON-Unterstützung für Tcl
    namespace eval json {
        proc json2dict {json} {
            # Vereinfachte Implementierung für das spezielle Format
            regsub -all {\"([^"]*)\":\s*\"([^\"]*)\"} $json {\1 \2} result
            regsub -all {\"([^"]*)\":\s*\{} $result {\1 \{} result
            regsub -all {\"([^"]*)\":\s*\}} $result {\1 \}} result
            return [subst $result]
        }
        
        proc dict2json {dict_data} {
            # Vereinfachte Implementierung für das spezielle Format
            set result "{"
            set first 1
            dict for {key value} $dict_data {
                if {!$first} { append result "," }
                if {[string is dict $value]} {
                    append result "\"$key\": [dict2json $value]"
                } else {
                    append result "\"$key\": \"$value\""
                }
                set first 0
            }
            append result "}"
            return $result
        }
    }
}

main
