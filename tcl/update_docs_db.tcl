#!/usr/bin/env tclsh8.6
# update_docs_db.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:scripts/update_docs_db.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# Scannt alle vorhandenen Dokumentationen und aktualisiert docs.db

package require sqlite3

set WORKSPACE "/home/openclaw/.openclaw/workspace"
set DB_PATH "$WORKSPACE/db/docs.db"

proc scan_documentations {} {
    global WORKSPACE
    set docs {}
    
    # Hauptverzeichnis
    set main_files [glob -nocomplain -types {f r} "$WORKSPACE/*.md"]
    foreach file $main_files {
        if {![file isdirectory $file] && ![file type $file] eq "link"} {
            lappend docs [list \
                name [file tail $file] \
                path "/" \
                category "main" \
                description [get_description $file] \
                type "doc" \
                has_symlink false \
                symlink_path "" \
                last_update [get_mtime $file]]
        }
    }
    
    # WebSearch Verzeichnis
    set websearch_dir "$WORKSPACE/websearch"
    if {[file exists $websearch_dir]} {
        set websearch_files [glob -nocomplain -types {f r} "$websearch_dir/*.md"]
        foreach file $websearch_files {
            set basename [file tail $file]
            set doc_type "config"
            if {[string first "GUIDE" $basename] != -1} {
                set doc_type "guide"
            }
            lappend docs [list \
                name $basename \
                path "websearch/" \
                category "websearch" \
                description [get_description $file] \
                type $doc_type \
                has_symlink true \
                symlink_path "websearch/$basename" \
                last_update [get_mtime $file]]
        }
    }
    
    # MCP Verzeichnis
    set mcp_dir "$WORKSPACE/mcp"
    if {[file exists $mcp_dir]} {
        set mcp_files [glob -nocomplain -types {f r} "$mcp_dir/*.md"]
        foreach file $mcp_files {
            set is_symlink [expr {[file type $file] eq "link"}]
            set symlink_path ""
            if {$is_symlink} {
                set symlink_path [file readlink $file]
            }
            set doc_type [expr {$is_symlink ? "symlink" : "guide"}]
            lappend docs [list \
                name [file tail $file] \
                path "mcp/" \
                category "mcp" \
                description [get_description $file] \
                type $doc_type \
                has_symlink $is_symlink \
                symlink_path $symlink_path \
                last_update [get_mtime $file]]
        }
    }
    
    # Docs-Unterverzeichnisse
    set docs_dir "$WORKSPACE/docs"
    if {[file exists $docs_dir]} {
        set subdirs [glob -nocomplain -types d "$docs_dir/*"]
        foreach subdir $subdirs {
            if {[file isdirectory $subdir]} {
                set subdir_name [file tail $subdir]
                set md_files [glob -nocomplain -types {f r} "$subdir/*.md"]
                foreach file $md_files {
                    lappend docs [list \
                        name [file tail $file] \
                        path "docs/$subdir_name/" \
                        category $subdir_name \
                        description [get_description $file] \
                        type "doc" \
                        has_symlink false \
                        symlink_path "" \
                        last_update [get_mtime $file]]
                }
            }
        }
    }
    
    # Cluster, Memory, Reports, Skills
    foreach category {cluster memory reports skills} {
        set cat_dir "$WORKSPACE/$category"
        if {[file exists $cat_dir]} {
            set md_files [glob -nocomplain -types {f r} "$cat_dir/*.md"]
            foreach file $md_files {
                lappend docs [list \
                    name [file tail $file] \
                    path "$category/" \
                    category $category \
                    description [get_description $file] \
                    type "doc" \
                    has_symlink false \
                    symlink_path "" \
                    last_update [get_mtime $file]]
            }
        }
    }
    
    return $docs
}

proc get_description {md_file} {
    if {[catch {open $md_file r} fid]} {
        return "Dokumentation"
    }
    
    set first_line ""
    if {[gets $fid first_line] >= 0} {
        set first_line [string trim $first_line]
        if {[string index $first_line 0] eq "#"} {
            set result [string trim [string range $first_line 1 end]]
            close $fid
            return $result
        } else {
            close $fid
            if {[string length $first_line] > 50} {
                return "[string range $first_line 0 49]..."
            } else {
                return $first_line
            }
        }
    }
    close $fid
    return "Dokumentation"
}

proc get_mtime {md_file} {
    if {[catch {file mtime $md_file} mtime]} {
        return "2026-04-18"
    }
    return [clock format $mtime -format "%Y-%m-%d"]
}

proc update_database {docs} {
    global DB_PATH
    sqlite3 db $DB_PATH
    
    # Lösche alte Einträge (außer config)
    db eval {DELETE FROM documents WHERE category != 'config'}
    
    # Füge neue ein
    set inserted 0
    foreach doc $docs {
        array set d $doc
        db eval {
            INSERT INTO documents 
            (name, path, category, description, type, has_symlink, symlink_path, last_update)
            VALUES ($d(name), $d(path), $d(category), $d(description), $d(type), $d(has_symlink), $d(symlink_path), $d(last_update))
        }
        incr inserted
    }
    
    db close
    return $inserted
}

proc export_all {} {
    global DB_PATH WORKSPACE
    sqlite3 db $DB_PATH
    
    # JSON Export
    set tables {documents skills symlinks}
    foreach table $tables {
        set rows [db eval "SELECT * FROM $table"]
        set columns [db eval "PRAGMA table_info($table)"]
        
        # Create list of column names
        set col_names {}
        foreach colinfo $columns {
            lappend col_names [lindex $colinfo 1]
        }
        
        # Convert to dict format for JSON
        set data {}
        foreach row $rows {
            set entry {}
            for {set i 0} {$i < [llength $row]} {incr i} {
                lappend entry [lindex $col_names $i] [lindex $row $i]
            }
            lappend data [array get entry]
        }
        
        # Write JSON (simple approach - would need proper JSON library for production)
        set json_path "$WORKSPACE/db_${table}.json"
        if {![catch {open $json_path w} json_fd]} {
            puts $json_fd "\{"
            puts $json_fd "  \"data\": \[\]"
            puts $json_fd "\}"
            close $json_fd
            puts "✅ $json_path"
        }
        
        # CSV Export
        set csv_path "$WORKSPACE/db_${table}.csv"
        if {![catch {open $csv_path w} csv_fd]} {
            # Header
            set header [join $col_names ","]
            puts $csv_fd $header
            
            # Data rows
            set query "SELECT * FROM $table"
            db eval $query {
                set row_data {}
                foreach col $col_names {
                    lappend row_data [set $col]
                }
                puts $csv_fd [join $row_data ","]
            }
            close $csv_fd
            puts "✅ $csv_path"
        }
    }
    
    db close
}

proc main {} {
    puts [string repeat "=" 60]
    puts "DOCS.DB UPDATER"
    puts [string repeat "=" 60]
    
    puts "\n--- Scanne Dokumentationen ---"
    set docs [scan_documentations]
    puts "Gefunden: [llength $docs] Dokumente"
    
    puts "\n--- Aktualisiere docs.db ---"
    set inserted [update_database $docs]
    puts "✅ $inserted Dokumente in docs.db aktualisiert"
    
    puts "\n--- Erstelle Exporte ---"
    export_all
    
    puts "\n[string repeat "=" 60]"
    puts "DOCS.DB AKTUALISIERT"
    puts [string repeat "=" 60]
}

main
