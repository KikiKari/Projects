#!/usr/bin/env tclsh
# tree_indexer_v2.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:scripts/tree_indexer_v2.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

# Tree Indexer v2 - Erweitertes Tracking mit Metadaten

package require sqlite3
package require md5

# Konfiguration
set WORKSPACE [file normalize [expr {[info exists ::env(OPENCLAW_WORKSPACE)] ? $::env(OPENCLAW_WORKSPACE) : [file dirname [file dirname [info script]]]}]]
set DB_DIR $WORKSPACE
set DB_PATH [file join $DB_DIR "tree.db"]

# Globale Variablen fuer die Datenbankverbindung
variable conn

proc connect_db {} {
    global conn DB_PATH
    if {![info exists conn]} {
        sqlite3 conn $DB_PATH
        conn eval {PRAGMA foreign_keys = ON}
    }
    return $conn
}

proc init_schema_v2 {} {
    # Erstellt erweiterte Tabellenstruktur
    set db [connect_db]
    
    # Haupttabelle mit erweiterten Metadaten
    $db eval {
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
    $db eval {
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
    $db eval {CREATE INDEX IF NOT EXISTS idx_file_id ON tree_entries_v2(file_id)}
    $db eval {CREATE INDEX IF NOT EXISTS idx_path ON tree_entries_v2(relative_path)}
    $db eval {CREATE INDEX IF NOT EXISTS idx_mtime ON tree_entries_v2(mtime_timestamp)}
    $db eval {CREATE INDEX IF NOT EXISTS idx_change_type ON tree_entries_v2(change_type)}
    
    puts "✅ tree.db Schema v2 erstellt/aktualisiert"
    return
}

proc get_file_metadata {full_path} {
    # Extrahiert Metadaten einer Datei
    if {[catch {file stat $full_path stat_info}]} {
        return [dict create size 0 mtime 0 mtime_iso ""]
    } else {
        set mtime [clock format $stat_info(mtime) -format "%Y-%m-%dT%H:%M:%S"]
        return [dict create size $stat_info(size) mtime $stat_info(mtime) mtime_iso $mtime]
    }
}

proc generate_file_id {relative_path} {
    # Generiert eindeutige ID aus Pfad
    set hash [md5::md5 -hex $relative_path]
    return [string range $hash 0 15]
}

proc scan_directory_detailed {root_path max_depth} {
    # Detailliertes Scanning mit Metadaten
    set entries {}
    
    # Rekursives Durchsuchen des Verzeichnisses
    proc scan_recursive {current_path root_path depth max_depth entries_ref} {
        upvar $entries_ref entries
        
        if {$depth > $max_depth} {
            return
        }
        
        if {![file isdirectory $current_path]} {
            return
        }
        
        set dirlist {}
        if {[catch {glob -nocomplain -dir $current_path *} files]} {
            set files {}
        }
        
        foreach item $files {
            # Versteckte Dateien ignorieren
            if {[string match ".*" [file tail $item]] && ![string equal [file tail $item] "."] && ![string equal [file tail $item] ".."]} {
                continue
            }
            
            set relative_path [file relativa $root_path $item]
            set file_id [generate_file_id $relative_path]
            set metadata [get_file_metadata $item]
            
            # Bestimme den Typ
            set type "file"
            if {[file isdirectory $item]} {
                set type "directory"
            } elseif {[file islink $item]} {
                set type "symlink"
            }
            
            # Parent-Pfad bestimmen
            set parent_path ""
            if {$relative_path ne "."} {
                set parent_path [file dirname $relative_path]
                if {$parent_path eq "." || $parent_path eq "/"} {
                    set parent_path ""
                }
            }
            
            lappend entries [dict create \
                file_id $file_id \
                root_path $root_path \
                relative_path $relative_path \
                name [file tail $item] \
                type $type \
                depth $depth \
                parent_path $parent_path \
                size_bytes [dict get $metadata size] \
                mtime_timestamp [dict get $metadata mtime] \
                mtime_iso [dict get $metadata mtime_iso] \
            ]
            
            # Rekursion fuer Unterverzeichnisse
            if {[file isdirectory $item] && ![file islink $item]} {
                scan_recursive $item $root_path [expr {$depth + 1}] $max_depth entries_ref
            }
        }
    }
    
    scan_recursive $root_path $root_path 0 $max_depth entries
    return $entries
}

proc update_database {entries} {
    # Aktualisiert DB mit Änderungs-Erkennung
    set db [connect_db]
    
    # Aktuelle Zeit
    set now [clock seconds]
    set now_timestamp [expr {double($now)}]
    
    # Alle bestehenden Einträge als "potentiell gelöscht" markieren
    $db eval {UPDATE tree_entries_v2 SET change_type = NULL}
    
    array set stats [list new 0 modified 0 unchanged 0 moved 0]
    
    foreach entry $entries {
        # Prüfe ob Datei bereits bekannt
        set rows [$db eval {SELECT * FROM tree_entries_v2 WHERE file_id = $file_id} [dict get $entry file_id]]
        
        if {[llength $rows] > 0} {
            # Vergleiche Metadaten
            set existing [lindex $rows 0]
            set old_mtime [expr {[dict exists $existing mtime_timestamp] ? [dict get $existing mtime_timestamp] : 0}]
            set old_size [expr {[dict exists $existing size_bytes] ? [dict get $existing size_bytes] : 0}]
            set old_path [dict get $existing relative_path]
            
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
            $db eval {
                UPDATE tree_entries_v2 SET
                    size_bytes = $new_size,
                    previous_size_bytes = $old_size_val,
                    size_change_bytes = $size_change_val,
                    mtime_timestamp = $mtime_timestamp_val,
                    mtime_iso = $mtime_iso_val,
                    last_seen_timestamp = $last_seen_timestamp_val,
                    change_type = $change_type_val,
                    previous_path = $previous_path_val,
                    original_path = COALESCE(original_path, $original_path_val),
                    updated_at = CURRENT_TIMESTAMP
                WHERE file_id = $file_id_val
            } {
                set new_size [dict get $entry size_bytes]
                set old_size_val $old_size
                set size_change_val $size_change
                set mtime_timestamp_val [dict get $entry mtime_timestamp]
                set mtime_iso_val [dict get $entry mtime_iso]
                set last_seen_timestamp_val $now_timestamp
                set change_type_val $change_type
                set previous_path_val [expr {$change_type eq "MOVED" ? $old_path : ""}]
                set original_path_val [expr {$change_type eq "MOVED" ? $old_path : ""}]
                set file_id_val [dict get $entry file_id]
            }
            
            # Änderung in Historie loggen
            if {$change_type in {"MODIFIED" "MOVED"}} {
                $db eval {
                    INSERT INTO file_history
                    (file_id, timestamp, change_type, old_path, new_path, old_size, new_size)
                    VALUES ($file_id_hist, $timestamp_hist, $change_type_hist, $old_path_hist, $new_path_hist, $old_size_hist, $new_size_hist)
                } {
                    set file_id_hist [dict get $entry file_id]
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
            $db eval {
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
    set deleted_rows [$db eval {SELECT * FROM tree_entries_v2 WHERE change_type IS NULL OR last_seen_timestamp < $cutoff_time} [expr {$now_timestamp - 3600}]]
    set stats(deleted) [llength $deleted_rows]
    
    foreach item $deleted_rows {
        $db eval {UPDATE tree_entries_v2 SET change_type = 'DELETED', updated_at = CURRENT_TIMESTAMP WHERE file_id = $file_id_del} [dict get $item file_id]
    }
    
    $db eval {COMMIT}
    return [array get stats]
}

proc export_changes {since_hours} {
    # Exportiert Änderungen der letzten X Stunden
    set db [connect_db]
    
    set since [expr {[clock seconds] - ($since_hours * 3600)}]
    
    set changes [$db eval {
        SELECT * FROM tree_entries_v2 
        WHERE change_type IN ('NEW', 'MODIFIED', 'MOVED', 'DELETED')
        AND last_seen_timestamp > $since_val
        ORDER BY last_seen_timestamp DESC
    }]
    
    # Export als JSON
    set export_file [file join $::WORKSPACE "tree_changes_last_${since_hours}h.json"]
    
    set data {}
    foreach row $changes {
        lappend data $row
    }
    
    set f [open $export_file w]
    puts $f [json_export $data]
    close $f
    
    puts "✅ Änderungen exportiert: $export_file ([llength $changes] Einträge)"
    return $export_file
}

proc json_export {data} {
    # Einfacher JSON-Export (da Tcl kein natives JSON hat)
    set json "\[\n"
    set first_item 1
    foreach item $data {
        if {!$first_item} {
            append json ",\n"
        }
        append json "  \{"
        set first_key 1
        foreach {key value} $item {
            if {!$first_key} {
                append json ","
            }
            append json "\n    \"$key\": \"[string map {\" \\\"} $value]\""
            set first_key 0
        }
        append json "\n  \}"
        set first_item 0
    }
    append json "\n\]\n"
    return $json
}

proc main {} {
    puts [string repeat "=" 60]
    puts "TREE INDEXER v2 - Erweitertes Tracking"
    puts [string repeat "=" 60]
    
    init_schema_v2
    
    puts "\n--- Scanning Workspace ---"
    set entries [scan_directory_detailed $::WORKSPACE 8]
    puts "Gefunden: [llength $entries] Einträge"
    
    puts "\n--- Aktualisiere Datenbank ---"
    array set stats [update_database $entries]
    puts "Statistiken:"
    puts "  NEU:        $stats(new)"
    puts "  MODIFIED:   $stats(modified)"
    puts "  MOVED:      $stats(moved)"
    puts "  UNCHANGED:  $stats(unchanged)"
    puts "  DELETED:    $stats(deleted)"
    
    puts "\n--- Exportiere Änderungen (24h) ---"
    export_changes 24
    
    puts "\n[string repeat "=" 60]"
    puts "TREE INDEXING ABGESCHLOSSEN"
    puts [string repeat "=" 60]
}

# Hilfsprozedur fuer file relativer Pfad
proc file_relative {base_path target_path} {
    set base_parts [file split $base_path]
    set target_parts [file split $target_path]
    
    # Entferne gemeinsamen Anfang
    set i 0
    while {$i < [llength $base_parts] && $i < [llength $target_parts] && [lindex $base_parts $i] eq [lindex $target_parts $i]} {
        incr i
    }
    
    # Erstelle relativen Pfad
    set result_parts {}
    for {set j $i} {$j < [llength $base_parts]} {incr j} {
        lappend result_parts ".."
    }
    for {set j $i} {$j < [llength $target_parts]} {incr j} {
        lappend result_parts [lindex $target_parts $j]
    }
    
    if {[llength $result_parts] == 0} {
        return "."
    } else {
        return [eval file join $result_parts]
    }
}

# Alias fuer file relativ
interp alias {} file_relata {} file_relative

main
