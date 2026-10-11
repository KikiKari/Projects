#!/usr/bin/env tclsh8.6
# tree_indexer_v2.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:scripts/tree_indexer_v2.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

# Tree Indexer v2 - Erweitertes Tracking mit Metadaten

package require sqlite3
package require fileutil
package require md5

set WORKSPACE "/workspace"
set DB_DIR $WORKSPACE

# Klasse TreeIndexerV2
proc TreeIndexerV2 {} {
    variable db_path
    variable conn
    
    set db_path "$WORKSPACE/db/tree.db"
    set conn ""
}

# Methode zur Initialisierung der Datenbankverbindung
proc connect {} {
    variable db_path
    variable conn
    
    if {$conn eq ""} {
        sqlite3 db_conn $db_path
        set conn db_conn
        ${conn} eval {PRAGMA foreign_keys = ON}
    }
    return $conn
}

# Methode zur Initialisierung des Schemas
proc init_schema_v2 {} {
    set conn [connect]
    
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
    ${conn} eval {CREATE INDEX IF NOT EXISTS idx_file_id ON tree_entries_v2(file_id)}
    ${conn} eval {CREATE INDEX IF NOT EXISTS idx_path ON tree_entries_v2(relative_path)}
    ${conn} eval {CREATE INDEX IF NOT EXISTS idx_mtime ON tree_entries_v2(mtime_timestamp)}
    ${conn} eval {CREATE INDEX IF NOT EXISTS idx_change_type ON tree_entries_v2(change_type)}
    
    puts "✅ tree.db Schema v2 erstellt/aktualisiert"
    return
}

# Methode zum Extrahieren von Metadaten einer Datei
proc get_file_metadata {full_path} {
    array set metadata [list size 0 mtime 0 mtime_iso ""]

    if {[catch {file stat $full_path stat_info}]} {
        return [array get metadata]
    }

    set metadata(size) $stat_info(size)
    set metadata(mtime) $stat_info(mtime)
    
    # Konvertiere Unix-Timestamp zu ISO-Format
    set iso_time [clock format $stat_info(mtime) -format "%Y-%m-%dT%H:%M:%S"]
    set metadata(mtime_iso) $iso_time
    
    return [array get metadata]
}

# Methode zur Generierung einer eindeutigen ID aus dem Pfad
proc generate_file_id {relative_path} {
    set hash [md5::md5 -hex $relative_path]
    return [string range $hash 0 15]
}

# Methode zum detaillierten Scannen mit Metadaten
proc scan_directory_detailed {root_path max_depth} {
    set entries [list]
    set root_len [string length $root_path]
    if {[string index $root_path end] ne "/"} {
        incr root_len
    }
    
    # Durchsuche rekursiv das Verzeichnis
    foreach item [glob -nocomplain -types {d f l} -path $root_path **] {
        # Berechne Tiefe
        set rel_path [string range $item $root_len end]
        set parts [split $rel_path "/"]
        set depth [llength $parts]
        
        # Max depth prüfen
        if {$depth > $max_depth} {
            continue
        }
        
        set file_id [generate_file_id $rel_path]
        array set metadata [get_file_metadata $item]
        
        # Bestimme Typ
        set type "file"
        if {[file isdirectory $item]} {
            set type "directory"
        } elseif {[file islink $item]} {
            set type "symlink"
        }
        
        # Erstelle Eintrag
        set entry [dict create \
            file_id $file_id \
            root_path $root_path \
            relative_path $rel_path \
            name [file tail $item] \
            type $type \
            depth $depth \
            parent_path [file dirname $rel_path] \
            size_bytes $metadata(size) \
            mtime_timestamp $metadata(mtime) \
            mtime_iso $metadata(mtime_iso) \
        ]
        
        lappend entries $entry
    }
    
    return $entries
}

# Methode zur Aktualisierung der Datenbank mit Änderungserkennung
proc update_database {entries} {
    set conn [connect]
    array set stats [list new 0 modified 0 unchanged 0 moved 0 deleted 0]
    
    # Aktuelle Zeit
    set now [clock seconds]
    set now_timestamp [expr {double($now)}]
    
    # Alle bestehenden Einträge als "potentiell gelöscht" markieren
    ${conn} eval {UPDATE tree_entries_v2 SET change_type = NULL}
    
    foreach entry $entries {
        set file_id [dict get $entry file_id]
        
        # Prüfe ob Datei bereits bekannt
        set existing [${conn} eval {SELECT * FROM tree_entries_v2 WHERE file_id = $file_id}]
        
        if {[llength $existing] > 0} {
            # Konvertiere Ergebnis in Array
            array set row {}
            set colnames [${conn} columns]
            foreach col $colnames val $existing {
                set row($col) $val
            }
            
            # Vergleiche Metadaten
            set old_mtime [expr {$row(mtime_timestamp) ? $row(mtime_timestamp) : 0}]
            set old_size [expr {$row(size_bytes) ? $row(size_bytes) : 0}]
            set old_path $row(relative_path)
            
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
                    size_bytes = $size,
                    previous_size_bytes = $prev_size,
                    size_change_bytes = $size_change,
                    mtime_timestamp = $mtime,
                    mtime_iso = $mtime_iso,
                    last_seen_timestamp = $last_seen,
                    change_type = $change_type,
                    previous_path = $prev_path,
                    original_path = COALESCE(original_path, $orig_path),
                    updated_at = CURRENT_TIMESTAMP
                WHERE file_id = $file_id
            } [subst {
                size [dict get $entry size_bytes]
                prev_size $old_size
                size_change $size_change
                mtime [dict get $entry mtime_timestamp]
                mtime_iso [dict get $entry mtime_iso]
                last_seen $now_timestamp
                change_type $change_type
                prev_path [expr {$change_type eq "MOVED" ? $old_path : ""}]
                orig_path [expr {$change_type eq "MOVED" ? $old_path : $row(original_path)}]
                file_id $file_id
            }]
            
            # Änderung in Historie loggen
            if {$change_type in {"MODIFIED" "MOVED"}} {
                ${conn} eval {
                    INSERT INTO file_history
                    (file_id, timestamp, change_type, old_path, new_path, old_size, new_size)
                    VALUES ($file_id, $timestamp, $change_type, $old_path, $new_path, $old_size, $new_size)
                } [subst {
                    file_id $file_id
                    timestamp $now_timestamp
                    change_type $change_type
                    old_path $old_path
                    new_path [dict get $entry relative_path]
                    old_size $old_size
                    new_size [dict get $entry size_bytes]
                }]
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
                VALUES ($file_id, $root_path, $rel_path, $name, $type, $depth, $parent_path,
                        $size_bytes, $size_bytes, 0,
                        $mtime_timestamp, $mtime_iso, $first_seen, $last_seen,
                        'NEW', NULL)
            } [subst {
                file_id [dict get $entry file_id]
                root_path [dict get $entry root_path]
                rel_path [dict get $entry relative_path]
                name [dict get $entry name]
                type [dict get $entry type]
                depth [dict get $entry depth]
                parent_path [dict get $entry parent_path]
                size_bytes [dict get $entry size_bytes]
                mtime_timestamp [dict get $entry mtime_timestamp]
                mtime_iso [dict get $entry mtime_iso]
                first_seen $now_timestamp
                last_seen $now_timestamp
            }]
        }
    }
    
    # Markiere nicht aktualisierte Einträge als DELETED
    set deleted [${conn} eval {
        SELECT * FROM tree_entries_v2 
        WHERE change_type IS NULL OR last_seen_timestamp < $cutoff
    } [subst {cutoff [expr {$now_timestamp - 3600}]}]]
    
    foreach row $deleted {
        array set item {}
        set colnames [${conn} columns]
        foreach col $colnames val $row {
            set item($col) $val
        }
        ${conn} eval {
            UPDATE tree_entries_v2 
            SET change_type = 'DELETED', updated_at = CURRENT_TIMESTAMP
            WHERE file_id = $file_id
        } [subst {file_id $item(file_id)}]
    }
    
    set stats(deleted) [expr {[llength $deleted] / 20}] ;# Anzahl Spalten in tree_entries_v2
    
    ${conn} eval {COMMIT}
    return [array get stats]
}

# Methode zum Exportieren von Änderungen der letzten X Stunden
proc export_changes {{since_hours 24}} {
    set conn [connect]
    
    set since [expr {[clock seconds] - ($since_hours * 3600)}]
    
    set changes [${conn} eval {
        SELECT * FROM tree_entries_v2 
        WHERE change_type IN ('NEW', 'MODIFIED', 'MOVED', 'DELETED')
        AND last_seen_timestamp > $since
        ORDER BY last_seen_timestamp DESC
    } [subst {since $since}]]
    
    # Export als JSON
    set export_file "$WORKSPACE/tree_changes_last_${since_hours}h.json"
    
    set data [list]
    set colnames [${conn} columns]
    
    # Verarbeite jede Zeile
    set row_length [llength $colnames]
    for {set i 0} {$i < [llength $changes]} {incr i $row_length} {
        set row_dict [dict create]
        for {set j 0} {$j < $row_length} {incr j} {
            dict set row_dict [lindex $colnames $j] [lindex $changes $i+$j]
        }
        lappend data $row_dict
    }
    
    # Schreibe JSON-Datei
    set f [open $export_file w]
    puts $f "\[[join [lmap row $data {
        set json_row "{"
        foreach {key value} $row {
            append json_row "\"$key\": \"[string map {\" \\\"} $value]\", "
        }
        # Entferne letztes Komma und Leerzeichen
        set json_row [string trimright $json_row ", "]
        append json_row "}"
    }] ",\n"]]"
    close $f
    
    puts "✅ Änderungen exportiert: $export_file ([llength $data] Einträge)"
    return $export_file
}

# Hauptmethode
proc main {} {
    puts [string repeat "=" 60]
    puts "TREE INDEXER v2 - Erweitertes Tracking"
    puts [string repeat "=" 60]
    
    init_schema_v2
    
    puts "\n--- Scanning Workspace ---"
    set entries [scan_directory_detailed $WORKSPACE 8]
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

# Starte das Programm
main
