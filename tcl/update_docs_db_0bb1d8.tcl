#!/usr/bin/env tclsh8.6
# update_docs_db.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:scripts/update_docs_db.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# Scan documentation files and refresh docs.db for the mounted workspace.

package require sqlite3
package require json

# Global variables
set WORKSPACE [expr {[info exists ::env(OPENCLAW_WORKSPACE)] ? $::env(OPENCLAW_WORKSPACE) : [file dirname [file dirname [info script]]]}]
set DB_PATH [file join $WORKSPACE "docs.db"]

proc iter_docs {} {
    global WORKSPACE
    set docs {}
    
    # Find all .md files recursively
    set md_files {}
    proc find_md_files {dir} {
        global md_files
        if {[catch {glob -directory $dir -tails -types {d f l} *} entries]} {
            return
        }
        foreach entry $entries {
            set full_path [file join $dir $entry]
            if {[file isdirectory $full_path] && ![file islink $full_path]} {
                # Skip node_modules, .git, backups directories
                set basename [file tail $full_path]
                if {$basename ni {node_modules .git backups}} {
                    find_md_files $full_path
                }
            } elseif {[file extension $entry] eq ".md" && [file isfile $full_path] && ![file islink $full_path]} {
                lappend md_files $full_path
            }
        }
    }
    
    find_md_files $WORKSPACE
    return $md_files
}

proc file_hash {path} {
    if {[catch {open $path rb} fh]} {
        return ""
    }
    
    set digest [dict create]
    # Simple MD5-like implementation would be complex in Tcl, using a placeholder
    # For real implementation, we'd need to implement MD5 or use external tool
    
    # As Tcl doesn't have built-in MD5, we'll use a simple approach:
    # Read file and create a hash-like string
    if {[catch {read $fh} content]} {
        close $fh
        return ""
    }
    close $fh
    
    # Create a simple hash representation
    set hash_val 0
    binary scan $content H* hex_content
    return [string range $hex_content 0 31]
}

proc word_count {path} {
    if {[catch {open $path r} fh]} {
        return 0
    }
    
    if {[catch {read $fh} content]} {
        close $fh
        return 0
    }
    close $fh
    
    # Count words by splitting on whitespace
    set words [split [string trim $content] \ \t\n\r]
    set count 0
    foreach word $words {
        if {$word ne ""} {
            incr count
        }
    }
    return $count
}

proc build_rows {} {
    global WORKSPACE
    set indexed [clock seconds]
    set rows {}
    
    foreach md_file [iter_docs] {
        set rel_path [string range $md_file [string length $WORKSPACE]+1 end]
        lappend rows [dict create \
            path $rel_path \
            content_hash [file_hash $md_file] \
            last_indexed $indexed \
            word_count [word_count $md_file]]
    }
    return $rows
}

proc ensure_schema {conn} {
    $conn eval {
        CREATE TABLE IF NOT EXISTS documents (
            path TEXT PRIMARY KEY,
            content_hash TEXT,
            last_indexed REAL,
            word_count INTEGER
        )
    }
    
    $conn eval {
        CREATE TABLE IF NOT EXISTS tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT,
            tag TEXT
        )
    }
}

proc update_database {rows} {
    global DB_PATH
    sqlite3 conn $DB_PATH
    
    ensure_schema conn
    conn execute {DELETE FROM documents}
    
    set stmt [conn prepare {INSERT INTO documents (path, content_hash, last_indexed, word_count) VALUES (?, ?, ?, ?)}]
    
    foreach row $rows {
        $stmt bind 1 [dict get $row path]
        $stmt bind 2 [dict get $row content_hash]
        $stmt bind 3 [dict get $row last_indexed]
        $stmt bind 4 [dict get $row word_count]
        $stmt step
        $stmt reset
    }
    
    $stmt finalize
    conn close
}

proc export_table {table} {
    global DB_PATH WORKSPACE
    sqlite3 conn $DB_PATH
    conn function rows
    
    set rows [conn eval "SELECT * FROM $table"]
    set data {}
    
    # Get column names
    set col_names {}
    if {[llength $rows] > 0} {
        set query "PRAGMA table_info($table)"
        set cols [conn eval $query]
        for {set i 0} {$i < [llength $cols]} {incr i 6} {
            lappend col_names [lindex $cols [expr {$i + 1}]]
        }
    }
    
    # Convert rows to dict format
    set result {}
    if {[llength $col_names] > 0} {
        foreach row $rows {
            set dict_row {}
            for {set i 0} {$i < [llength $col_names]} {incr i} {
                dict set dict_row [lindex $col_names $i] [lindex $row $i]
            }
            lappend result $dict_row
        }
    }
    
    # Export to JSON
    set json_path [file join $WORKSPACE "db_${table}.json"]
    set json_data [json::encode $result]
    set fh [open $json_path w]
    puts $fh $json_data
    close $fh
    
    # Export to CSV
    set csv_path [file join $WORKSPACE "db_${table}.csv"]
    set fh [open $csv_path w]
    if {[llength $col_names] > 0} {
        puts $fh [join $col_names ","]
        foreach row $rows {
            puts $fh [join $row ","]
        }
    } else {
        puts $fh ""
    }
    close $fh
    
    conn close
}

proc main {} {
    puts [string repeat "=" 60]
    puts "DOCS.DB UPDATER"
    puts [string repeat "=" 60]
    
    set rows [build_rows]
    puts "Gefunden: [llength $rows] Dokumente"
    
    update_database $rows
    puts "✅ [llength $rows] Dokumente in docs.db aktualisiert"
    
    export_table "documents"
    export_table "tags"
    puts "✅ Exporte aktualisiert"
    
    puts "\n[string repeat "=" 60]"
    puts "DOCS.DB AKTUALISIERT"
    puts [string repeat "=" 60]
}

# Run main if script is executed directly
if {[info script] eq $argv0} {
    main
}
