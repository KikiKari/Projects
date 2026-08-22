#!/usr/bin/env tclsh8.6
# tree_indexer_v2.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:scripts/tree_indexer_v2.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# Tree Indexer v2 - Erweitertes Tracking mit Metadaten

package require sqlite3

set WORKSPACE "/home/openclaw/.openclaw/workspace"
set DB_DIR "$WORKSPACE/db"

# Hilfsfunktionen
proc file_normalize {path} {
    # Entferne abschließende Slashes
    set path [string trimright $path "/"]
    if {$path eq ""} {set path "/"}
    return $path
}

proc file_join {args} {
    set result ""
    foreach part $args {
        if {$part ne ""} {
            if {$result eq ""} {
                set result $part
            } else {
                set result [file join $result $part]
            }
        }
    }
    return $result
}

proc dict_get_default {dict key default} {
    if {[dict exists $dict $key]} {
        return [dict get $dict $key]
    } else {
        return $default
    }
}

proc timestamp_to_iso {timestamp} {
    if {$timestamp eq "" || $timestamp == 0} {
        return ""
    }
    return [clock format $timestamp -format "%Y-%m-%dT%H:%M:%S"]
}

proc iso_now {} {
    return [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
}

proc md5_short {text} {
    if {[catch {exec echo -n $text | md5sum} result]} {
        # Fallback ohne md5sum
        set hash ""
        binary scan $text H* hash
        return [string range $hash 0 15]
    } else {
        return [string range $result 0 15]
    }
}

proc glob_recursive {dir {max_depth 8}} {
    set entries {}
    set queue [list [list $dir 0]]
    
    while {[llength $queue] > 0} {
        set item [lindex $queue 0]
        set queue [lrange $queue 1 end]
        
        set current_dir [lindex $item 0]
        set depth [lindex $item 1]
        
        if {$depth > $max_depth} {
            continue
        }
        
        if {[catch {glob -nocomplain -dir $current_dir *} files]} {
            continue
        }
        
        foreach file $files {
            lappend entries [list $file $depth]
            if {[file isdirectory $file]} {
                lappend queue [list $file [expr {$depth + 1}]]
            }
        }
    }
    
    return $entries
}

proc TreeIndexerV2_new {} {
    set obj [dict create]
    dict set obj db_path "$DB_DIR/tree.db"
    dict set obj conn ""
    return $obj
}

proc TreeIndexerV2_connect {this} {
    set db_path [dict get $this db_path]
    set conn "db_conn"
    
    # Stelle sicher dass das DB-Verzeichnis existiert
    file mkdir [file dirname $db_path]
    
    sqlite3 $conn $db_path
    ${conn} eval {PRAGMA foreign_keys = ON}
    
    dict set this conn $conn
    return $this
}

proc TreeIndexerV2_init_schema_v2 {this} {
    set this [TreeIndexerV2_connect $this]
    set conn [dict get $this conn]
    
    # Haupttabelle mit erweiterten Metadaten
    ${conn} eval {
        CREATE TABLE IF NOT EXISTS tree_entries_v2 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_id TEXT UNIQUE,              -- Eindeutige Datei-ID (Hash von Pfad)
            root_path TEXT NOT NULL,
            relative_path TEXT NOT NULL,
            name TEXT NOT NULL,
            type TEXT CHECK(type IN ('file', 'directory', 'symlink')),
            depth INTEGER,
            parent_path TEXT,
            
            -- Größen-Tracking
            size_bytes INTEGER,               -- Aktuelle Größe
            previous_size_bytes INTEGER,      -- Vorherige Größe (für Delta)
            size_change_bytes INTEGER,        -- Änderung (positiv/negativ)
            
            -- Zeitstempel
            mtime_timestamp REAL,             -- Letzte Änderung (Unix timestamp)
            mtime_iso TEXT,                   -- ISO-Format für Lesbarkeit
            first_seen_timestamp REAL,        -- Wann wurde Datei erste Mal gesehen
            last_seen_timestamp REAL,         -- Wann wurde Datei zuletzt gesehen
            
            -- Änderungs-Tracking
            change_type TEXT CHECK(change_type IN ('NEW', 'MODIFIED', 'MOVED', 'RENAMED', 'UNCHANGED', 'DELETED')),
            
            -- Historie
            original_name TEXT,               -- Ursprünglicher Name wenn umbenannt
            original_path TEXT,               -- Ursprünglicher Pfad wenn verschoben
            previous_path TEXT,               -- Vorheriger Pfad
            
            -- Content-Hash (optionale Integritätsprüfung)
            content_hash TEXT,                -- MD5 der Datei (nur für kleine Dateien)
            
            -- Metadaten
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    }
    
    # Historie-Tabelle für alle Änderungen
    ${conn} eval {
        CREATE TABLE IF NOT EXISTS file_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_id TEXT NOT NULL,
            timestamp REAL NOT NULL,
            change_type TEXT NOT NULL,
            old_path TEXT,
            new_path TEXT,
            old_size INTEGER,
            new_size INTEGER,
            FOREIGN KEY (file_id) REFERENCES tree_entries_v2(file_id)
        )
    }
    
    # Index für schnelle Suchen
    ${conn} eval {
        CREATE INDEX IF NOT EXISTS idx_file_id ON tree_entries_v2(file_id);
        CREATE INDEX IF NOT EXISTS idx_path ON tree_entries_v2(relative_path);
        CREATE INDEX IF NOT EXISTS idx_mtime ON tree_entries_v2(mtime_timestamp);
        CREATE INDEX IF NOT EXISTS idx_change_type ON tree_entries_v2(change_type);
    }
    
    puts "✅ tree.db Schema v2 erstellt/aktualisiert"
    return $this
}

proc TreeIndexerV2_get_file_metadata {this full_path} {
    array set meta {}
    set meta(size) 0
    set meta(mtime) 0
    set meta(mtime_iso) ""
    
    if {[file exists $full_path]} {
        if {![catch {file mtime $full_path} mtime_val]} {
            set meta(size) [file size $full_path]
            set meta(mtime) $mtime_val
            set meta(mtime_iso) [timestamp_to_iso $mtime_val]
        }
    }
    
    return [array get meta]
}

proc TreeIndexerV2_generate_file_id {this relative_path} {
    return [md5_short $relative_path]
}

proc TreeIndexerV2_scan_directory_detailed {this root_path {max_depth 8}} {
    set entries {}
    set root_path [file_normalize $root_path]
    
    set items [glob_recursive $root_path $max_depth]
    
    foreach item_info $items {
        set item [lindex $item_info 0]
        set depth [lindex $item_info 1]
        
        # Berechne relativen Pfad
        set relative_path [string range $item [string length $root_path] end]
        set relative_path [string trimleft $relative_path "/"]
        
        if {$relative_path eq ""} continue
        
        set file_id [TreeIndexerV2_generate_file_id $this $relative_path]
        array set metadata [TreeIndexerV2_get_file_metadata $this $item]
        
        set entry [dict create \
            file_id $file_id \
            root_path $root_path \
            relative_path $relative_path \
            name [file tail $item] \
            type [expr {[file isdirectory $item] ? "directory" : ([file islink $item] ? "symlink" : "file")}] \
            depth $depth \
            parent_path [file dirname $relative_path] \
            size_bytes $metadata(size) \
            mtime_timestamp $metadata(mtime) \
            mtime_iso $metadata(mtime_iso) \
        ]
        
        lappend entries $entry
    }
    
    return $entries
}

proc TreeIndexerV2_update_database {this entries} {
    set this [TreeIndexerV2_connect $this]
    set conn [dict get $this conn]
    
    # Aktuelle Zeit
    set now [clock seconds]
    set now_timestamp [clock scan [clock format $now -format "%Y-%m-%d %H:%M:%S"]]
    
    # Alle bestehenden Einträge als "potentiell gelöscht" markieren
    ${conn} eval {UPDATE tree_entries_v2 SET change_type = NULL}
    
    array set stats [list new 0 modified 0 unchanged 0 moved 0 deleted 0]
    
    foreach entry $entries {
        set file_id [dict get $entry file_id]
        
        # Prüfe ob Datei bereits bekannt
        set existing_rows [${conn} eval {
            SELECT * FROM tree_entries_v2 WHERE file_id = $file_id
        }]
        
        if {[llength $existing_rows] > 0} {
            # Konvertiere Ergebnis zu Dict
            set colnames [${conn} eval {PRAGMA table_info(tree_entries_v2)}]
            set existing_dict [dict create]
            for {set i 0} {$i < [llength $colnames]} {incr i 2} {
                set colname [lindex $colnames $i 1]
                set value [lindex $existing_rows $i]
                dict set existing_dict $colname $value
            }
            
            # Vergleiche Metadaten
            set old_mtime [dict_get_default $existing_dict mtime_timestamp 0]
            set old_size [dict_get_default $existing_dict size_bytes 0]
            set old_path [dict_get_default $existing_dict relative_path ""]
            
            # Größenänderung berechnen
            set size_change [expr {[dict get $entry size_bytes] - $old_size}]
            
            # Änderungstyp bestimmen
            set change_type "UNCHANGED"
            if {$old_path ne [dict get $entry relative_path]} {
                set change_type "MOVED"
                incr stats(moved)
            } elseif {$old_mtime != [dict get $entry mtime_timestamp] || $old_size != [dict get $entry size_bytes]} {
                set change_type "MODIFIED"
                incr stats(modified)
            } else {
                incr stats(unchanged)
            }
            
            # Update
            ${conn} eval {
                UPDATE tree_entries_v2 SET
                    size_bytes = $size_bytes,
                    previous_size_bytes = $old_size,
                    size_change_bytes = $size_change,
                    mtime_timestamp = $mtime_timestamp,
                    mtime_iso = $mtime_iso,
                    last_seen_timestamp = $last_seen_timestamp,
                    change_type = $change_type,
                    previous_path = $previous_path,
                    original_path = COALESCE(original_path, $original_path_value),
                    updated_at = CURRENT_TIMESTAMP
                WHERE file_id = $file_id
            } {
                set size_bytes [dict get $entry size_bytes]
                set old_size $old_size
                set size_change $size_change
                set mtime_timestamp [dict get $entry mtime_timestamp]
                set mtime_iso [dict get $entry mtime_iso]
                set last_seen_timestamp $now_timestamp
                set change_type $change_type
                set previous_path [expr {$change_type eq "MOVED" ? $old_path : ""}]
                set original_path_value [expr {$change_type eq "MOVED" ? $old_path : $old_path}]
                set file_id $file_id
            }
            
            # Änderung in Historie loggen
            if {$change_type in {"MODIFIED" "MOVED"}} {
                ${conn} eval {
                    INSERT INTO file_history
                    (file_id, timestamp, change_type, old_path, new_path, old_size, new_size)
                    VALUES ($file_id_hist, $timestamp_hist, $change_type_hist, $old_path_hist, $new_path_hist, $old_size_hist, $new_size_hist)
                } {
                    set file_id_hist $file_id
                    set timestamp_hist $now_timestamp
                    set change_type_hist $change_type
                    set old_path_hist $old_path
                    set new_path_hist [dict get $entry relative_path]
                    set old_size_hist $old_size
                    set new_size_hist [dict get $entry size_bytes]
                }
            }
        } else {
            # Neue Datei
            incr stats(new)
            ${conn} eval {
                INSERT INTO tree_entries_v2
                (file_id, root_path, relative_path, name, type, depth, parent_path,
                 size_bytes, previous_size_bytes, size_change_bytes,
                 mtime_timestamp, mtime_iso, first_seen_timestamp, last_seen_timestamp,
                 change_type, content_hash)
                VALUES ($file_id_ins, $root_path_ins, $relative_path_ins, $name_ins, $type_ins, $depth_ins, $parent_path_ins,
                        $size_bytes_ins, $previous_size_bytes_ins, $size_change_bytes_ins,
                        $mtime_timestamp_ins, $mtime_iso_ins, $first_seen_timestamp_ins, $last_seen_timestamp_ins,
                        $change_type_ins, $content_hash_ins)
            } {
                set file_id_ins [dict get $entry file_id]
                set root_path_ins [dict get $entry root_path]
                set relative_path_ins [dict get $entry relative_path]
                set name_ins [dict get $entry name]
                set type_ins [dict get $entry type]
                set depth_ins [dict get $entry depth]
                set parent_path_ins [dict get $entry parent_path]
                set size_bytes_ins [dict get $entry size_bytes]
                set previous_size_bytes_ins [dict get $entry size_bytes]
                set size_change_bytes_ins 0
                set mtime_timestamp_ins [dict get $entry mtime_timestamp]
                set mtime_iso_ins [dict get $entry mtime_iso]
                set first_seen_timestamp_ins $now_timestamp
                set last_seen_timestamp_ins $now_timestamp
                set change_type_ins "NEW"
                set content_hash_ins ""
            }
        }
    }
    
    # Markiere nicht aktualisierte Einträge als DELETED
    set deleted_rows [${conn} eval {
        SELECT * FROM tree_entries_v2 
        WHERE change_type IS NULL OR last_seen_timestamp < $cutoff_time
    } {
        set cutoff_time [expr {$now_timestamp - 3600}]
    }]
    
    set deleted_count 0
    # Iteriere durch die gelöschten Zeilen (vereinfachte Version)
    set deleted_files [${conn} eval {
        SELECT file_id FROM tree_entries_v2 
        WHERE change_type IS NULL OR last_seen_timestamp < $cutoff_time
    } {
        set cutoff_time [expr {$now_timestamp - 3600}]
    }]
    
    foreach file_id_del $deleted_files {
        ${conn} eval {
            UPDATE tree_entries_v2 
            SET change_type = 'DELETED', updated_at = CURRENT_TIMESTAMP
            WHERE file_id = $file_id_del
        }
        incr deleted_count
    }
    
    set stats(deleted) $deleted_count
    
    ${conn} eval {COMMIT}
    return [array get stats]
}

proc TreeIndexerV2_export_changes {this {since_hours 24}} {
    set this [TreeIndexerV2_connect $this]
    set conn [dict get $this conn]
    
    set since [expr {[clock seconds] - ($since_hours * 3600)}]
    
    set changes [${conn} eval {
        SELECT * FROM tree_entries_v2 
        WHERE change_type IN ('NEW', 'MODIFIED', 'MOVED', 'DELETED')
        AND last_seen_timestamp > $since_timestamp
        ORDER BY last_seen_timestamp DESC
    } {
        set since_timestamp $since
    }]
    
    # Export als JSON-ähnliches Format
    set export_file "$WORKSPACE/tree_changes_last_${since_hours}h.json"
    set fp [open $export_file w]
    
    puts $fp "\["
    set first 1
    set count 0
    
    # Da direkte SQL-Abfrage komplex ist, simuliere einfachen Export
    set rows [${conn} eval {
        SELECT id, file_id, root_path, relative_path, name, type, depth, parent_path,
               size_bytes, previous_size_bytes, size_change_bytes,
               mtime_timestamp, mtime_iso, first_seen_timestamp, last_seen_timestamp,
               change_type, original_name, original_path, previous_path, content_hash,
               created_at, updated_at
        FROM tree_entries_v2 
        WHERE change_type IN ('NEW', 'MODIFIED', 'MOVED', 'DELETED')
        AND last_seen_timestamp > $since_timestamp
        ORDER BY last_seen_timestamp DESC
    } {
        set since_timestamp $since
    }]
    
    set row_count [expr {[llength $rows] / 22}] ;# 22 Spalten
    
    for {set i 0} {$i < [llength $rows]} {incr i 22} {
        if {!$first} {puts -nonewline $fp ","}
        puts $fp "  \{"
        
        set fields [list id file_id root_path relative_path name type depth parent_path \
                         size_bytes previous_size_bytes size_change_bytes \
                         mtime_timestamp mtime_iso first_seen_timestamp last_seen_timestamp \
                         change_type original_name original_path previous_path content_hash \
                         created_at updated_at]
                         
        for {set j 0} {$j < 22} {incr j} {
            set field [lindex $fields $j]
            set value [lindex $rows [expr {$i + $j}]]
            if {$value eq ""} {
                set json_value "null"
            } elseif {[string is double $value] || [string is integer $value]} {
                set json_value $value
            } else {
                set json_value "\"$value\""
            }
            puts $fp "    \"$field\": $json_value"
            if {$j < 21} {puts -nonewline $fp ","}
            puts $fp ""
        }
        
        puts -nonewline $fp "  \}"
        set first 0
        incr count
    }
    
    puts $fp "\n\]"
    close $fp
    
    puts "✅ Änderungen exportiert: $export_file ($count Einträge)"
    return $export_file
}

proc main {} {
    puts [string repeat "=" 60]
    puts "TREE INDEXER v2 - Erweitertes Tracking"
    puts [string repeat "=" 60]
    
    set indexer [TreeIndexerV2_new]
    set indexer [TreeIndexerV2_init_schema_v2 $indexer]
    
    puts "\n--- Scanning Workspace ---"
    set entries [TreeIndexerV2_scan_directory_detailed $indexer "/home/openclaw/.openclaw/workspace/" 8]
    puts "Gefunden: [llength $entries] Einträge"
    
    puts "\n--- Aktualisiere Datenbank ---"
    array set stats [TreeIndexerV2_update_database $indexer $entries]
    puts "Statistiken:"
    puts "  NEU:        $stats(new)"
    puts "  MODIFIED:   $stats(modified)"
    puts "  MOVED:      $stats(moved)"
    puts "  UNCHANGED:  $stats(unchanged)"
    puts "  DELETED:    $stats(deleted)"
    
    puts "\n--- Exportiere Änderungen (24h) ---"
    TreeIndexerV2_export_changes $indexer 24
    
    puts "\n[string repeat "=" 60]"
    puts "TREE INDEXING ABGESCHLOSSEN"
    puts [string repeat "=" 60]
}

# Starte das Programm
main
