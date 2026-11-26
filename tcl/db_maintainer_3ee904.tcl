#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "f542330b16b7c3b09751557513697d0d773b0664cbd9232e960a69760f23bce8", "source_sha256": "3ee904e4ee842489bd9bef8522f5a93fc06583e6cb1c3c5243afae19a4e2ed5f", "target_language": "tcl"}
# db_maintainer.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/db_maintainer.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Database Maintainer Sub-Agent
# Automated database maintenance with 30min checks, hourly backups (3 days retention),
# band tree command execution for important/openclaw-tree.txt

package require sqlite3
package require fileutil
package require json

set WORKSPACE "/home/openclaw/.openclaw/workspace"
set DB_DIR "$WORKSPACE/db"
set BACKUP_DIR "$DB_DIR/backups"
set LOG_DIR "$WORKSPACE/logs/db-maintainer"
set IMPORTANT_DIR "$WORKSPACE/important"

# Create directories
file mkdir $BACKUP_DIR
file mkdir $LOG_DIR

# Logger Class
proc Logger_new {} {
    variable log_file
    set today [clock format [clock seconds] -format "%Y-%m-%d"]
    set log_file "$::LOG_DIR/$today.log"
    
    namespace eval Logger {}
    proc Logger::log {level message} {
        variable log_file
        set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
        set line "\[$timestamp\] \[$level\] $message"
        puts $line
        set f [open $log_file a]
        puts $f $line
        close $f
    }
    
    proc Logger::info {msg} {
        Logger::log INFO $msg
    }
    
    proc Logger::warn {msg} {
        Logger::log WARN $msg
    }
    
    proc Logger::error {msg} {
        Logger::log ERROR $msg
    }
    
    return Logger
}

# DatabaseMaintainer Class
proc DatabaseMaintainer_new {} {
    namespace eval DatabaseMaintainer {}
    
    variable logger [Logger_new]
    variable state_file "$::DB_DIR/maintainer_state.json"
    variable retention_days 3
    
    proc DatabaseMaintainer::load_state {} {
        variable state_file
        if {[file exists $state_file]} {
            set f [open $state_file r]
            set content [read $f]
            close $f
            if {$content eq ""} {
                return [dict create last_check {} last_backup {} last_tree_update {} file_hashes {}]
            }
            return [json::json2dict $content]
        }
        return [dict create last_check {} last_backup {} last_tree_update {} file_hashes {}]
    }
    
    proc DatabaseMaintainer::save_state {state} {
        variable state_file
        set f [open $state_file w]
        puts $f [json::dict2json $state]
        close $f
    }
    
    proc DatabaseMaintainer::get_file_hash {filepath} {
        if {![file exists $filepath]} {
            return ""
        }
        if {[catch {set f [open $filepath r]}]} {
            return ""
        }
        set data [read $f]
        close $f
        return [md5::md5 -hex $data]
    }
    
    proc DatabaseMaintainer::run_tree_command {} {
        variable logger
        if {[catch {exec tree -a -L 8 $::WORKSPACE} result]} {
            $logger error "tree command failed: $result"
            return ""
        }
        $logger info "tree -a -L 8 executed successfully"
        return $result
    }
    
    proc DatabaseMaintainer::update_tree_file {tree_output} {
        variable logger
        if {$tree_output eq ""} {
            return 0
        }
        
        set tree_file "$::IMPORTANT_DIR/openclaw-tree.txt"
        set timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
        set header "# OpenClaw Workspace Tree\n# Generated: $timestamp\n# Command: tree -a -L 8 $::WORKSPACE\n# This file is automatically updated by db-maintainer\n\n"
        
        if {[catch {set f [open $tree_file w]}]} {
            $logger error "Failed to open $tree_file for writing"
            return 0
        }
        puts -nonewline $f $header
        puts -nonewline $f $tree_output
        close $f
        $logger info "Updated openclaw-tree.txt: $tree_file"
        return 1
    }
    
    proc DatabaseMaintainer::scan_documentations {} {
        variable logger
        set docs {}
        set patterns [list "*.md" "*/*.md"]
        
        foreach pattern $patterns {
            set full_pattern "$::WORKSPACE/$pattern"
            if {[catch {glob -nocomplain $full_pattern} files]} {
                continue
            }
            foreach md_file $files {
                if {![file isfile $md_file] || [file type $md_file] eq "link"} {
                    continue
                }
                if {[string match "*db/backups*" $md_file] || [string match "*node_modules*" $md_file]} {
                    continue
                }
                set rel_path [string range $md_file [string length "$::WORKSPACE/"] end]
                lappend docs [dict create \
                    path $rel_path \
                    hash [DatabaseMaintainer::get_file_hash $md_file] \
                    mtime [file mtime $md_file]]
            }
        }
        return $docs
    }
    
    proc DatabaseMaintainer::check_for_changes {} {
        set state [DatabaseMaintainer::load_state]
        set current_docs [DatabaseMaintainer::scan_documentations]
        
        set changes {}
        set current_hashes {}
        
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
    
    proc DatabaseMaintainer::update_databases {} {
        variable logger
        if {[catch {exec python3 "$::WORKSPACE/scripts/update_docs_db.py"} result]} {
            $logger error "DB update failed: $result"
            return 0
        }
        $logger info "docs.db updated"
        return 1
    }
    
    proc DatabaseMaintainer::update_tree_db_v2 {} {
        variable logger
        if {[catch {exec python3 "$::WORKSPACE/scripts/tree_indexer_v2.py"} result]} {
            $logger error "Tree DB v2 failed: $result"
            return 0
        }
        $logger info "tree.db v2 updated"
        return 1
    }
    
    proc DatabaseMaintainer::create_backup {} {
        variable logger
        set timestamp [clock format [clock seconds] -format "%Y-%m-%d_%H-%M"]
        
        foreach db_name [list docs.db tree.db] {
            set source "$::DB_DIR/$db_name"
            if {[file exists $source]} {
                set backup_name "${timestamp}_${db_name}.bak"
                set backup_path "$::BACKUP_DIR/$backup_name"
                file copy -force $source $backup_path
                $logger info "Created backup: $backup_name"
            }
        }
        return $timestamp
    }
    
    proc DatabaseMaintainer::cleanup_old_backups {} {
        variable logger
        variable retention_days
        set cutoff [expr {[clock seconds] - ($retention_days * 86400)}]
        set deleted 0
        
        foreach db_name [list docs.db tree.db] {
            set pattern "$::BACKUP_DIR/*_${db_name}.bak"
            if {[catch {glob -nocomplain $pattern} backups]} {
                continue
            }
            foreach backup $backups {
                set filename [file tail $backup]
                set parts [split $filename _]
                if {[llength $parts] < 3} continue
                set date_part [lindex $parts 0]
                set time_part [lindex $parts 1]
                if {[catch {clock scan "$date_part $time_part" -format "%Y-%m-%d %H-%M"} backup_time]} {
                    $logger warn "Could not parse backup date: $filename"
                    continue
                }
                
                if {$backup_time < $cutoff} {
                    file delete $backup
                    incr deleted
                    $logger info "Deleted old backup: $filename"
                }
            }
        }
        
        if {$deleted == 0} {
            $logger info "No old backups to delete"
        } else {
            $logger info "$deleted old backups deleted (< 3 days)"
        }
    }
    
    proc DatabaseMaintainer::run_cycle {} {
        variable logger
        $logger info [string repeat "=" 60]
        $logger info "DB MAINTAINER CYCLE START"
        $logger info [string repeat "=" 60]
        
        set state [DatabaseMaintainer::load_state]
        
        # 1. Run tree command and write to openclaw-tree.txt
        $logger info "Running tree -a -L 8..."
        set tree_output [DatabaseMaintainer::run_tree_command]
        if {$tree_output ne ""} {
            DatabaseMaintainer::update_tree_file $tree_output
            dict set state last_tree_update [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
        }
        
        # 2. Update tree.db (internal v2)
        $logger info "Updating tree.db v2..."
        DatabaseMaintainer::update_tree_db_v2
        
        # 3. Check for changes
        $logger info "Checking for documentation changes..."
        lassign [DatabaseMaintainer::check_for_changes] changes current_hashes
        
        if {[llength $changes] > 0} {
            $logger info "[llength $changes] changes found:"
            set count 0
            foreach change [lrange $changes 0 9] {
                $logger info "  - $change"
                incr count
            }
            if {[llength $changes] > 10} {
                $logger info "  ... and [expr {[llength $changes] - 10}] more"
            }
            
            # 4. Update docs.db
            $logger info "Updating docs.db..."
            if {[DatabaseMaintainer::update_databases]} {
                dict set state last_check [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
                dict set state file_hashes $current_hashes
            }
        } else {
            $logger info "No documentation changes found"
        }
        
        # 5. Check if backup is due (hourly)
        set last_backup [dict get $state last_backup]
        set do_backup 0
        
        if {$last_backup ne ""} {
            if {[catch {clock scan $last_backup -format "%Y-%m-%dT%H:%M:%S"} last_backup_time]} {
                set do_backup 1
            } else {
                set now [clock seconds]
                if {($now - $last_backup_time) >= 3600} {
                    set do_backup 1
                }
            }
        } else {
            set do_backup 1
        }
        
        if {$do_backup} {
            $logger info "Creating hourly backup..."
            set timestamp [DatabaseMaintainer::create_backup]
            dict set state last_backup [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
            
            # 6. Clean up old backups (3 day retention)
            $logger info "Cleaning up old backups (3 day retention)..."
            DatabaseMaintainer::cleanup_old_backups
        } else {
            $logger info "Backup not needed (last < 1h)"
        }
        
        DatabaseMaintainer::save_state $state
        
        $logger info [string repeat "=" 60]
        $logger info "DB MAINTAINER CYCLE END"
        $logger info [string repeat "=" 60]
    }
    
    return DatabaseMaintainer
}

proc main {} {
    set maintainer [DatabaseMaintainer_new]
    if {[catch {$maintainer run_cycle} error]} {
        set logger [Logger_new]
        $logger error "CRITICAL ERROR: $error"
        exit 1
    }
}

if {[info script] eq $argv0} {
    main
}
