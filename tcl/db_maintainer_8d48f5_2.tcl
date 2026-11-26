#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "777bffc2d82ad7350647bc5afed31cbebf39a19f3253a73661ff448f71a6f6a9", "source_sha256": "8d48f51942bb1c171bbd41e0696beb0722cb4b94d6596233f54b32928b645086", "target_language": "tcl"}
# db_maintainer.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Database Maintainer Sub-Agent
# Automated database maintenance with 30min checks, hourly backups (3 days retention),
# band tree command execution for important/openclaw-tree.txt

package require Tcl 8.6
package require sqlite3
package require sha256

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
    variable logger_obj
    set logger_obj [dict create]
    dict set logger_obj log_file [file join $::LOG_DIR "[clock format [clock seconds] -format {%Y-%m-%d}].log"]
    return $logger_obj
}

proc Logger_log {logger level message} {
    set timestamp [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]
    set line "\[$timestamp\] \[$level\] $message"
    puts $line
    set fh [open [dict get $logger log_file] a]
    puts $fh $line
    close $fh
}

proc Logger_info {logger msg} { Logger_log $logger INFO $msg }
proc Logger_warn {logger msg} { Logger_log $logger WARN $msg }
proc Logger_error {logger msg} { Logger_log $logger ERROR $msg }

# DatabaseMaintainer class
proc DatabaseMaintainer_new {} {
    set obj [dict create]
    dict set obj logger [Logger_new]
    dict set obj state_file [file join $::DB_DIR "maintainer_state.json"]
    dict set obj retention_days 3
    return $obj
}

proc DatabaseMaintainer_load_state {self} {
    set state_file [dict get $self state_file]
    if {[file exists $state_file]} {
        set fh [open $state_file r]
        set content [read $fh]
        close $fh
        if {[catch {::json::json2dict $content} data]} {
            return [dict create last_check {} last_backup {} last_tree_update {} file_hashes [dict create]]
        }
        return $data
    }
    return [dict create last_check {} last_backup {} last_tree_update {} file_hashes [dict create]]
}

proc DatabaseMaintainer_save_state {self state} {
    set state_file [dict get $self state_file]
    set fh [open $state_file w]
    puts $fh [::json::dict2json $state]
    close $fh
}

proc DatabaseMaintainer_get_file_hash {self filepath} {
    if {![file exists $filepath] || [file size $filepath] == 0} {
        return ""
    }
    if {[catch {set fh [open $filepath rb]} err]} {
        return ""
    }
    set content [read $fh]
    close $fh
    return [sha256::sha256 -hex $content]
}

proc DatabaseMaintainer_python_tree_fallback {self {max_depth 8}} {
    set root $::WORKSPACE
    set lines [list $root]
    
    proc walk {dirpath prefix depth max_depth lines_var} {
        upvar $lines_var lines
        if {$depth > $max_depth} {
            return
        }
        if {[catch {set entries [lsort -dictionary [glob -nocomplain -directory $dirpath *]]}]} {
            return
        }
        set count [llength $entries]
        for {set i 0} {$i < $count} {incr i} {
            set entry [lindex $entries $i]
            set name [file tail $entry]
            set connector [expr {$i == $count - 1 ? "└── " : "├── "}]
            lappend lines "$prefix$connector$name"
            if {[file isdirectory $entry] && ![file type $entry] eq "link"} {
                set extension [expr {$i == $count - 1 ? "    " : "│   "}]
                walk $entry "$prefix$extension" [expr {$depth + 1}] $max_depth lines
            }
        }
    }
    
    walk $root "" 1 $max_depth lines
    return [join $lines "\n"]\n
}

proc DatabaseMaintainer_run_tree_command {self} {
    set logger [dict get $self logger]
    if {[catch {exec tree -a -L 8 $::WORKSPACE} result]} {
        Logger_warn $logger "tree-Binary nicht installiert – nutze Python-Fallback"
        return [DatabaseMaintainer_python_tree_fallback $self]
    } else {
        Logger_info $logger "tree -a -L 8 erfolgreich ausgeführt"
        return $result
    }
}

proc DatabaseMaintainer_update_tree_file {self tree_output} {
    if {![string length $tree_output]} {
        return 0
    }
    
    set logger [dict get $self logger]
    set tree_file [file join $::IMPORTANT_DIR "openclaw-tree.txt"]
    set timestamp [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S}]
    
    set header "# OpenClaw Workspace Tree
# Generiert: $timestamp
# Befehl: tree -a -L 8 $::WORKSPACE
# Diese Datei wird automatisch von db-maintainer aktualisiert

"
    
    if {[catch {set fh [open $tree_file w]} err]} {
        Logger_error $logger "Fehler beim Schreiben von openclaw-tree.txt: $err"
        return 0
    }
    puts -nonewline $fh $header
    puts -nonewline $fh $tree_output
    close $fh
    Logger_info $logger "openclaw-tree.txt aktualisiert: $tree_file"
    return 1
}

proc DatabaseMaintainer_scan_documentations {self} {
    set docs [list]
    foreach pattern {"*.md" "**/*.md"} {
        if {[catch {glob -nocomplain -directory $::WORKSPACE $pattern} files]} {
            continue
        }
        foreach md_file $files {
            if {[file isfile $md_file] && ![file type $md_file] eq "link"} {
                set rel_path [file join [lrange [file split [file normalize $md_file]] [llength [file split [file normalize $::WORKSPACE]]] end]]
                if {![string match "*db/backups*" $rel_path] && ![string match "*node_modules*" $rel_path]} {
                    lappend docs [dict create \
                        path $rel_path \
                        hash [DatabaseMaintainer_get_file_hash $self $md_file] \
                        mtime [file mtime $md_file]]
                }
            }
        }
    }
    return $docs
}

proc DatabaseMaintainer_check_for_changes {self} {
    set state [DatabaseMaintainer_load_state $self]
    set current_docs [DatabaseMaintainer_scan_documentations $self]
    
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
    
    # Check for deleted files
    dict for {old_path old_hash} [dict get $state file_hashes] {
        if {![dict exists $current_hashes $old_path]} {
            lappend changes "DELETED: $old_path"
        }
    }
    
    return [list $changes $current_hashes]
}

proc DatabaseMaintainer_update_databases {self} {
    set logger [dict get $self logger]
    if {[catch {exec python3 [file join $::WORKSPACE scripts update_docs_db.py]} result]} {
        Logger_error $logger "DB-Update Exception: $result"
        return 0
    } else {
        Logger_info $logger "docs.db aktualisiert"
        return 1
    }
}

proc DatabaseMaintainer_update_tree_db_v2 {self} {
    set logger [dict get $self logger]
    if {[catch {exec python3 [file join $::WORKSPACE scripts tree_indexer_v2.py]} result]} {
        Logger_error $logger "Tree-DB v2 Exception: $result"
        return 0
    } else {
        Logger_info $logger "tree.db v2 aktualisiert"
        return 1
    }
}

proc DatabaseMaintainer_create_backup {self} {
    set logger [dict get $self logger]
    set timestamp [clock format [clock seconds] -format {%Y-%m-%d_%H-%M}]
    
    foreach db_name {"docs.db" "tree.db"} {
        set source [file join $::DB_DIR $db_name]
        if {[file exists $source]} {
            set backup_name "${timestamp}_${db_name}.bak"
            set backup_path [file join $::BACKUP_DIR $backup_name]
            file copy -force $source $backup_path
            Logger_info $logger "Backup erstellt: $backup_name"
        }
    }
    
    return $timestamp
}

proc DatabaseMaintainer_cleanup_old_backups {self} {
    set logger [dict get $self logger]
    set retention_days [dict get $self retention_days]
    set cutoff [expr {[clock seconds] - ($retention_days * 24 * 60 * 60)}]
    set deleted 0
    
    foreach db_name {"docs.db" "tree.db"} {
        if {[catch {glob -nocomplain -directory $::BACKUP_DIR "*_${db_name}.bak"} backups]} {
            continue
        }
        foreach backup $backups {
            if {[regexp {^([0-9]{4}-[0-9]{2}-[0-9]{2})_([0-9]{2}-[0-9]{2})_} [file tail $backup] -> date_str time_str]} {
                if {[catch {clock scan "$date_str $time_str" -format "%Y-%m-%d %H-%M"} backup_time]} {
                    Logger_warn $logger "Konnte Backup-Datum nicht parsen: [file tail $backup]"
                    continue
                }
                if {$backup_time < $cutoff} {
                    file delete $backup
                    incr deleted
                    Logger_info $logger "Altes Backup gelöscht: [file tail $backup]"
                }
            } else {
                Logger_warn $logger "Konnte Backup-Datum nicht parsen: [file tail $backup]"
            }
        }
    }
    
    if {$deleted == 0} {
        Logger_info $logger "Keine alten Backups zum Löschen"
    } else {
        Logger_info $logger "$deleted alte Backups gelöscht (< 3 Tage)"
    }
}

proc DatabaseMaintainer_run_cycle {self} {
    set logger [dict get $self logger]
    Logger_info $logger [string repeat "=" 60]
    Logger_info $logger "DB MAINTAINER CYCLE START"
    Logger_info $logger [string repeat "=" 60]
    
    set state [DatabaseMaintainer_load_state $self]
    
    # 1. Run tree command and write to openclaw-tree.txt
    Logger_info $logger "Führe tree -a -L 8 aus..."
    set tree_output [DatabaseMaintainer_run_tree_command $self]
    if {[string length $tree_output]} {
        DatabaseMaintainer_update_tree_file $self $tree_output
        dict set state last_tree_update [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S}]
    }
    
    # 2. Update tree.db (internal v2)
    Logger_info $logger "Aktualisiere tree.db v2..."
    DatabaseMaintainer_update_tree_db_v2 $self
    
    # 3. Check for changes
    Logger_info $logger "Prüfe auf Dokumentations-Änderungen..."
    lassign [DatabaseMaintainer_check_for_changes $self] changes current_hashes
    
    if {[llength $changes]} {
        Logger_info $logger "[llength $changes] Änderungen gefunden:"
        set count 0
        foreach change [lrange $changes 0 9] {
            Logger_info $logger "  - $change"
            incr count
        }
        if {[llength $changes] > 10} {
            Logger_info $logger "  ... und [expr {[llength $changes] - 10}] weitere"
        }
        
        # 4. Update docs.db
        Logger_info $logger "Aktualisiere docs.db..."
        if {[DatabaseMaintainer_update_databases $self]} {
            dict set state last_check [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S}]
            dict set state file_hashes $current_hashes
        }
    } else {
        Logger_info $logger "Keine Dokumentations-Änderungen gefunden"
    }
    
    # 5. Check if backup is due (hourly)
    set last_backup [dict get $state last_backup]
    set do_backup 0
    
    if {[string length $last_backup]} {
        if {[catch {clock scan $last_backup -format "%Y-%m-%dT%H:%M:%S"} last_backup_time]} {
            set do_backup 1
        } else {
            set do_backup [expr {[clock seconds] - $last_backup_time >= 3600}]
        }
    } else {
        set do_backup 1
    }
    
    if {$do_backup} {
        Logger_info $logger "Erstelle stündliches Backup..."
        set timestamp [DatabaseMaintainer_create_backup $self]
        dict set state last_backup [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S}]
        
        # 6. Clean up old backups (3 days retention)
        Logger_info $logger "Räume alte Backups auf (3 Tage Retention)..."
        DatabaseMaintainer_cleanup_old_backups $self
    } else {
        Logger_info $logger "Backup nicht nötig (letztes < 1h)"
    }
    
    DatabaseMaintainer_save_state $self $state
    
    Logger_info $logger [string repeat "=" 60]
    Logger_info $logger "DB MAINTAINER CYCLE END"
    Logger_info $logger [string repeat "=" 60]
}

proc main {} {
    set maintainer [DatabaseMaintainer_new]
    
    if {[catch {DatabaseMaintainer_run_cycle $maintainer} error]} {
        set logger [dict get $maintainer logger]
        Logger_error $logger "CRITICAL ERROR: $error"
        exit 1
    }
}

# Load required packages
if {[catch {package require json}]} {
    # Fallback JSON implementation for basic dict<->JSON conversion
    namespace eval json {
        proc json2dict {json} {
            # Very basic JSON parser for this specific use case
            regsub -all {,\s*} $json { } json
            regsub -all {\{} $json {\[} json
            regsub -all {\}} $json {\]} json
            regsub -all {\"([^"]*)\":} $json {\"\1\" } json
            return [uplevel #0 [list subst $json]]
        }
        
        proc dict2json {dict_val} {
            # Very basic dict to JSON converter
            set result "{"
            set first 1
            dict for {key value} $dict_val {
                if {!$first} {
                    append result ","
                }
                if {[dict size $value] > 0} {
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

if {[info script] eq $argv0} {
    main
}
