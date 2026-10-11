#!/usr/bin/env tclsh8.6
# update_docs_db.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:scripts/update_docs_db.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

# Scan documentation files and refresh docs.db for the mounted workspace.

package require sqlite3
package require json

set WORKSPACE "/workspace"
set DB_PATH "$WORKSPACE/db/docs.db"

proc iter_docs {} {
    global WORKSPACE
    set docs {}
    
    # Find all .md files recursively
    set cmd [list glob -nocomplain -dir $WORKSPACE -types {f r} "**/*.md"]
    if {[catch $cmd files]} {
        set files {}
    }
    
    foreach md_file $files {
        # Skip symlinks and non-files
        if {![file isfile $md_file] || [file type $md_file] eq "link"} {
            continue
        }
        
        # Get relative path
        set rel_path [string range $md_file [string length $WORKSPACE]/ end]
        
        # Check if path contains excluded directories
        set skip 0
        foreach part [split $rel_path /] {
            if {$part in {"node_modules" ".git" "backups"}} {
                set skip 1
                break
            }
        }
        
        if {!$skip} {
            lappend docs $md_file
        }
    }
    
    return $docs
}

proc file_hash {path} {
    if {[catch {open $path rb} fh]} {
        return ""
    }
    
    set digest [::md5::MD5Init]
    while {![eof $fh]} {
        set chunk [read $fh 8192]
        if {$chunk ne ""} {
            ::md5::MD5Update $digest $chunk
        }
    }
    close $fh
    
    set result [::md5::MD5Final $digest]
    return [string tolower [binary encode hex $result]]
}

proc word_count {path} {
    if {[catch {open $path r} fh]} {
        return 0
    }
    
    set content [read $fh]
    close $fh
    
    # Split by whitespace and count words
    set words [regexp -all -inline {\S+} $content]
    return [llength $words]
}

proc build_rows {} {
    set indexed [clock seconds]
    set rows {}
    
    foreach md_file [iter_docs] {
        global WORKSPACE
        set rel_path [string range $md_file [string length $WORKSPACE]/ end]
        lappend rows [dict create \
            path $rel_path \
            content_hash [file_hash $md_file] \
            last_indexed $indexed \
            word_count [word_count $md_file]]
    }
    
    return $rows
}

proc ensure_schema {conn} {
    ${conn} eval {
        CREATE TABLE IF NOT EXISTS documents (
            path TEXT PRIMARY KEY,
            content_hash TEXT,
            last_indexed REAL,
            word_count INTEGER
        )
    }
    
    ${conn} eval {
        CREATE TABLE IF NOT EXISTS tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT,
            tag TEXT
        )
    }
}

proc update_database {rows} {
    global DB_PATH
    sqlite3 db $DB_PATH
    
    ensure_schema db
    db eval {DELETE FROM documents}
    
    set stmt [db prepare {INSERT INTO documents (path, content_hash, last_indexed, word_count) VALUES (?, ?, ?, ?)}]
    
    foreach row $rows {
        $stmt execute [dict get $row path] [dict get $row content_hash] [dict get $row last_indexed] [dict get $row word_count]
    }
    
    $stmt finalize
    db close
}

proc export_table {table} {
    global WORKSPACE DB_PATH
    sqlite3 db $DB_PATH
    db eval "SELECT * FROM $table" rows {
        # Collect all rows
    }
    
    set data {}
    set headers {}
    
    # Get column names from first row
    if {[info exists rows(*)]} {
        set headers [array names rows(*)]
    }
    
    # Convert to list of dicts
    db eval "SELECT * FROM $table" row {
        set dict_row {}
        foreach col $headers {
            dict set dict_row $col $row($col)
        }
        lappend data $dict_row
    }
    
    # Write JSON
    set json_path "$WORKSPACE/db_${table}.json"
    set json_fh [open $json_path w]
    puts $json_fh [::json::json-encode $data]
    close $json_fh
    
    # Write CSV
    set csv_path "$WORKSPACE/db_${table}.csv"
    set csv_fh [open $csv_path w]
    
    if {[llength $data] > 0} {
        # Write header
        set header_keys [dict keys [lindex $data 0]]
        puts $csv_fh [join $header_keys ","]
        
        # Write data rows
        foreach row $data {
            set values {}
            foreach key $header_keys {
                lappend values [dict get $row $key]
            }
            puts $csv_fh [join $values ","]
        }
    } else {
        puts $csv_fh ""
    }
    
    close $csv_fh
    db close
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
    
    puts ""
    puts [string repeat "=" 60]
    puts "DOCS.DB AKTUALISIERT"
    puts [string repeat "=" 60]
}

if {$::argv0 eq [info script]} {
    main
}
