#!/usr/bin/env tclsh8.6
# tree_indexer.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:scripts/tree_indexer.py
# auch in: OpenClaw@gateway2:scripts/tree_indexer.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# Tree Indexer - Scannt Verzeichnisbäume und speichert in tree.db

package require sqlite3

set WORKSPACE "/home/openclaw/.openclaw/workspace"
set DB_DIR [file join $WORKSPACE "db"]

proc connect_db {} {
    global DB_DIR
    set db_path [file join $DB_DIR "tree.db"]
    sqlite3 db $db_path
    db eval {PRAGMA foreign_keys = ON}
    return db
}

proc run_tree {root_path max_depth} {
    # Führt tree -a -L {depth} aus und parst Ausgabe
    if {[catch {
        set cmd [list exec tree -a -L $max_depth $root_path]
        set result [eval $cmd]
        return $result
    } error]} {
        puts "❌ Fehler bei tree $root_path: $error"
        return ""
    }
}

proc parse_tree_output {tree_output root_path} {
    # Parst tree-Ausgabe und extrahiert Einträge
    set entries {}
    set lines [split [string trim $tree_output] "\n"]
    
    # Regex für tree-Zeilen
    # Beispiel: "├── .bash_history" oder "│   ├── bin"
    set pattern {^[│ ]*[├└]── (.+)$}
    
    foreach line $lines {
        if {[regexp $pattern $line match name_part]} {
            set name [string trim $name_part]
            # Tiefe bestimmen durch Anzahl der │ und Leerzeichen
            set depth 0
            set chars [split $line ""]
            foreach char $chars {
                if {$char eq "│"} {
                    incr depth
                }
            }
            # Zähle auch die Leerzeichenblöcke
            set space_blocks [regexp -all {(?: {4})} $line]
            incr depth $space_blocks
            
            # Typ bestimmen
            set entry_type "file"
            if {[string index $name end] eq "/"} {
                set entry_type "directory"
                set name [string range $name 0 end-1]
            } elseif {[string first " -> " $name] != -1} {
                set entry_type "symlink"
                set parts [split $name " -> "]
                set name [lindex $parts 0]
            }
            
            lappend entries [dict create \
                name $name \
                type $entry_type \
                depth $depth \
                line $line]
        }
    }
    
    return $entries
}

proc save_to_db {root_path max_depth entries} {
    # Speichert Einträge in tree.db
    connect_db
    set total_files 0
    set total_dirs 0
    set total_symlinks 0
    
    foreach entry $entries {
        set entry_type [dict get $entry type]
        if {$entry_type eq "file"} {
            incr total_files
        } elseif {$entry_type eq "directory"} {
            incr total_dirs
        } elseif {$entry_type eq "symlink"} {
            incr total_symlinks
        }
    }
    
    db eval {
        INSERT INTO tree_scans 
        (root_path, max_depth, total_files, total_dirs, total_symlinks)
        VALUES ($root_path, $max_depth, $total_files, $total_dirs, $total_symlinks)
    }
    
    set scan_id [db last_insert_rowid]
    
    # Einträge speichern
    foreach entry $entries {
        set name [dict get $entry name]
        set entry_type [dict get $entry type]
        set depth [dict get $entry depth]
        
        db eval {
            INSERT INTO tree_entries 
            (root_path, relative_path, name, type, depth, parent_path, size)
            VALUES ($root_path, $name, $name, $entry_type, $depth, $root_path, 0)
        }
    }
    
    db close
    puts "✅ [llength $entries] Einträge gespeichert für $root_path"
    return $scan_id
}

proc index_directory {root_path max_depth} {
    # Komplette Indexierung eines Verzeichnisses
    puts "\n--- Indexiere: $root_path (Depth: $max_depth) ---"
    set tree_output [run_tree $root_path $max_depth]
    
    if {$tree_output ne ""} {
        set entries [parse_tree_output $tree_output $root_path]
        if {[llength $entries] > 0} {
            return [save_to_db $root_path $max_depth $entries]
        }
    }
    return ""
}

proc export_csv {} {
    # Exportiert alle Tree-Einträge als CSV
    connect_db
    
    set rows [db eval {
        SELECT * FROM tree_entries ORDER BY root_path, depth, name
    }]
    
    if {[llength $rows] == 0} {
        puts "⚠️ Keine Tree-Daten vorhanden"
        db close
        return ""
    }
    
    set columns [db eval {
        PRAGMA table_info(tree_entries)
    }]
    set header {}
    foreach {cid name type notnull dflt_value pk} $columns {
        lappend header $name
    }
    
    global WORKSPACE
    set csv_path [file join $WORKSPACE "export_tree_all.csv"]
    
    set f [open $csv_path w]
    puts $f [join $header ","]
    
    db eval {
        SELECT * FROM tree_entries ORDER BY root_path, depth, name
    } row {
        set values {}
        foreach col $header {
            lappend values [set row($col)]
        }
        puts $f [join $values ","]
    }
    
    close $f
    db close
    puts "✅ Tree CSV exportiert: $csv_path ([expr {[llength $rows] / [llength $header]}] Einträge)"
    return $csv_path
}

proc export_by_root {} {
    # Exportiert getrennt nach root_path
    connect_db
    
    set roots [db eval {
        SELECT DISTINCT root_path FROM tree_entries
    }]
    
    set exports {}
    foreach root_path $roots {
        set safe_name [regsub -all {/} $root_path "_"]
        set safe_name [regsub -all {\.{1,}} $safe_name ""]
        global WORKSPACE
        set csv_path [file join $WORKSPACE "export_tree${safe_name}.csv"]
        
        set columns [db eval {
            PRAGMA table_info(tree_entries)
        }]
        set header {}
        foreach {cid name type notnull dflt_value pk} $columns {
            lappend header $name
        }
        
        set f [open $csv_path w]
        puts $f [join $header ","]
        
        set count 0
        db eval {
            SELECT * FROM tree_entries WHERE root_path = $root_path ORDER BY depth, name
        } row {
            set values {}
            foreach col $header {
                lappend values [set row($col)]
            }
            puts $f [join $values ","]
            incr count
        }
        
        close $f
        lappend exports [list $root_path $csv_path $count]
        puts "✅ Export $root_path: $csv_path ($count Einträge)"
    }
    
    db close
    return $exports
}

proc main {} {
    puts [string repeat "=" 60]
    puts "TREE INDEXER"
    puts [string repeat "=" 60]
    
    # 1. /home/openclaw/ mit depth 3
    index_directory "/home/openclaw/" 3
    
    # 2. Workspace mit depth 6
    index_directory "/home/openclaw/.openclaw/workspace/" 6
    
    # Exporte erstellen
    puts "\n--- Exporte ---"
    export_csv
    export_by_root
    
    puts "\n[string repeat "=" 60]"
    puts "TREE INDEXIERUNG ABGESCHLOSSEN"
    puts [string repeat "=" 60]
}

main
