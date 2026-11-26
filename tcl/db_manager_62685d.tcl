#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "bdd45b7732423b6fefb2736eba64e5639b24fb7ad7fe45ab8444ca270bdda73a", "source_sha256": "62685d1bad45f2dffb79d4424a8a668a222d4008e157a9d6b51a3e2a1d1d204d", "target_language": "tcl"}
# db_manager.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:scripts/db_manager.py
# auch in: OpenClaw@gateway2:scripts/db_manager.py
# auch in: Projects@abstractions:abstractions/db_manager.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Workspace Documentation Database Manager
#
# Erstellt und verwaltet docs.db und tree.db im Workspace-Datenbankverzeichnis.
# Beide Datenbanken liegen unter $OPENCLAW_WORKSPACE/db/.
#
# Verwendung:
#     tclsh8.6 db_manager.tcl
#
# Konfiguration:
#     OPENCLAW_WORKSPACE (Umgebungsvariable) — Standard: /home/openclaw/.openclaw/workspace

package require sqlite3
package require csv
package require json

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

set WORKSPACE [expr {[info exists ::env(OPENCLAW_WORKSPACE)] ? $::env(OPENCLAW_WORKSPACE) : "/home/openclaw/.openclaw/workspace"}]
set DB_DIR [file join $WORKSPACE "db"]

# Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
array set DOCS_EXPORT_TABLES {
    documents 1
    categories 1
    symlinks 1
    skills 1
}

array set TREE_EXPORT_TABLES {
    tree_entries 1
    tree_scans 1
}

# ---------------------------------------------------------------------------
# Logger
# ---------------------------------------------------------------------------

proc log_info {msg} {
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    puts "$timestamp | INFO     | db_manager | $msg"
}

proc log_error {msg} {
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    puts "$timestamp | ERROR    | db_manager | $msg"
}

# ---------------------------------------------------------------------------
# DocsDatabase
# ---------------------------------------------------------------------------

namespace eval DocsDatabase {
    variable db_path
    
    proc new {} {
        variable db_path
        set db_path [file join $::DB_DIR "docs.db"]
        return [namespace current]
    }
    
    proc get_connection {} {
        variable db_path
        sqlite3 db $db_path
        db eval {PRAGMA foreign_keys = ON}
        return db
    }
    
    proc close_connection {conn} {
        $conn close
    }
    
    proc init_schema {} {
        variable db_path
        set conn [get_connection]
        
        $conn eval {
            CREATE TABLE IF NOT EXISTS documents (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    NOT NULL,
                path        TEXT    NOT NULL,
                category    TEXT,
                description TEXT,
                type        TEXT    CHECK(type IN ('config', 'doc', 'guide', 'script', 'symlink')),
                has_symlink BOOLEAN DEFAULT FALSE,
                symlink_path TEXT,
                last_update TEXT,
                created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE TABLE IF NOT EXISTS categories (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    UNIQUE NOT NULL,
                description TEXT,
                priority    INTEGER DEFAULT 0
            );
            
            CREATE TABLE IF NOT EXISTS symlinks (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    NOT NULL,
                target      TEXT    NOT NULL,
                source_path TEXT    NOT NULL,
                description TEXT,
                created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE TABLE IF NOT EXISTS skills (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    NOT NULL,
                version     TEXT,
                status      TEXT    CHECK(status IN ('installed', 'local', 'published')),
                description TEXT,
                path        TEXT
            );
        }
        
        close_connection $conn
        log_info "docs.db Schema initialisiert: $db_path"
        return [namespace current]
    }
    
    proc populate_from_workspace {} {
        variable db_path
        set conn [get_connection]
        
        set categories {
            {main "Hauptverzeichnis Dateien" 1}
            {memory "Memory und Protokolle" 2}
            {reports "Berichte und Analysen" 3}
            {cluster "Cluster und Infrastruktur" 4}
            {skills "Installierte Skills" 5}
            {websearch "WebSearch Dokumentationen" 6}
            {mcp "MCP Integration" 7}
            {links "Symbolische Links" 8}
        }
        
        set docs {
            {"AGENTS.md" "/" "main" "Agent-Konfiguration, Memory-Regeln" "config" 0 "" "2026-04-11"}
            {"SOUL.md" "/" "main" "Agent-Persönlichkeit und Kernwahrheiten" "config" 0 "" "2026-04-11"}
            {"IDENTITY.md" "/" "main" "Agent-Name und Eigenschaften" "config" 0 "" "2026-04-11"}
            {"USER.md" "/" "main" "Benutzerinformationen" "config" 0 "" "2026-04-11"}
            {"TOOLS.md" "/" "main" "Tool-spezifische Konfigurationen" "config" 0 "" "2026-04-18"}
            {"MEMORY.md" "/" "main" "Langzeitspeicher, System-Konfiguration" "config" 0 "" "2026-04-11"}
            {"DOCUMENTATION-INDEX.md" "/" "main" "Übersicht aller Dokumentationen" "doc" 0 "" "2026-04-18"}
            {"WORKSPACE-INDEX.md" "/" "main" "Symlink zu DOCUMENTATION-INDEX.md" "symlink" 1 "DOCUMENTATION-INDEX.md" "2026-04-18"}
            {"WEBSEARCH_README.md" "websearch/" "websearch" "Schnellstart Guide" "guide" 1 "websearch/WEBSEARCH_README.md" "2026-04-18"}
            {"WEBSEARCH_MCP_GUIDE.md" "websearch/" "websearch" "Vollständige technische Dokumentation" "guide" 1 "websearch/WEBSEARCH_MCP_GUIDE.md" "2026-04-18"}
            {"WEBSEARCH_CONFIG.md" "websearch/" "websearch" "Konfigurations-Referenz" "config" 1 "websearch/WEBSEARCH_CONFIG.md" "2026-04-18"}
            {"WEBSEARCH_PRIORITY_CONFIG.md" "websearch/" "websearch" "Provider-Priorität" "config" 1 "websearch/WEBSEARCH_PRIORITY_CONFIG.md" "2026-04-18"}
            {"WEBSEARCH_SCRIPTS.md" "websearch/" "websearch" "Automation & Scripting" "script" 1 "websearch/WEBSEARCH_SCRIPTS.md" "2026-04-18"}
            {"WEBSEARCH_OPS.md" "websearch/" "websearch" "IT-Operations" "guide" 1 "websearch/WEBSEARCH_OPS.md" "2026-04-18"}
            {"MCP_GUIDE.md" "mcp/" "mcp" "Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md" "symlink" 0 "websearch/WEBSEARCH_MCP_GUIDE.md" "2026-04-18"}
        }
        
        set skills {
            {"json-utils" "1.0.0" "installed" "JSON parsing and validation" "skills/json-utils/"}
            {"scripting-utils" "1.0.0" "installed" "Multi-language scripting support" "skills/scripting-utils/"}
            {"tiktok-live-mon" "1.0.0" "installed" "TikTok stream monitoring" "skills/tiktok-live-mon/"}
            {"cluster-management" "1.0.0" "installed" "Cluster topology management" "skills/cluster-management/"}
            {"worker-node" "-" "local" "Worker node configuration" "skills/worker-node/"}
            {"resource-manager" "-" "local" "Resource management" "skills/resource-manager/"}
            {"git-publish-agent" "1.0.0" "local" "Git publishing automation" "skills/git-publish-agent/"}
        }
        
        set symlinks {
            {"openclaw.env" "/home/openclaw/.config/openclaw/env" "/" "API-Keys Shortcut"}
            {"openclaw.json" "/home/openclaw/.openclaw/openclaw.json" "/" "Konfig Shortcut"}
            {"links/config/openclaw-env" "/home/openclaw/.config/openclaw/env" "links/config/" "API-Keys"}
            {"links/dotfiles/.tavily" "/home/openclaw/.tavily/" "links/dotfiles/" "Tavily Config"}
            {"links/dotfiles/.claude" "/home/openclaw/.claude/" "links/dotfiles/" "Claude Config"}
            {"links/dotfiles/.mcporter" "/home/openclaw/.mcporter/" "links/dotfiles/" "MCPorter Config"}
            {"links/dotfiles/.ssh" "/home/openclaw/.ssh/" "links/dotfiles/" "SSH Keys"}
        }
        
        foreach cat $categories {
            lassign $cat name description priority
            $conn eval {
                INSERT OR IGNORE INTO categories (name, description, priority) VALUES ($name, $description, $priority)
            }
        }
        
        foreach doc $docs {
            lassign $doc name path category description type has_symlink symlink_path last_update
            $conn eval {
                INSERT OR REPLACE INTO documents 
                (name, path, category, description, type, has_symlink, symlink_path, last_update)
                VALUES ($name, $path, $category, $description, $type, $has_symlink, $symlink_path, $last_update)
            }
        }
        
        foreach skill $skills {
            lassign $skill name version status description path
            $conn eval {
                INSERT OR REPLACE INTO skills (name, version, status, description, path) 
                VALUES ($name, $version, $status, $description, $path)
            }
        }
        
        foreach link $symlinks {
            lassign $link name target source_path description
            $conn eval {
                INSERT OR REPLACE INTO symlinks (name, target, source_path, description) 
                VALUES ($name, $target, $source_path, $description)
            }
        }
        
        $conn close
        
        log_info "docs.db befüllt: [llength $docs] Dokumente, [llength $skills] Skills, [llength $symlinks] Symlinks"
        return [namespace current]
    }
    
    proc validate_table_name {table allowed} {
        if {![info exists allowed($table)]} {
            error "Ungültiger Tabellenname: '$table'. Erlaubt: [lsort [array names allowed]]"
        }
    }
    
    proc export_csv {table} {
        validate_table_name $table ::DOCS_EXPORT_TABLES
        
        set conn [get_connection]
        set rows [$conn eval "SELECT * FROM $table"]
        set column_names {}
        if {[llength $rows] > 0} {
            set stmt [$conn prepare "SELECT * FROM $table LIMIT 1"]
            set column_names [$stmt columns]
            $stmt finalize
        }
        close_connection $conn
        
        if {[llength $rows] == 0} {
            log_info "Tabelle '$table' ist leer — kein CSV erzeugt"
            return
        }
        
        set csv_path [file join $::WORKSPACE "export_${table}.csv"]
        set fh [open $csv_path w]
        csv::write $fh $column_names
        foreach row $rows {
            csv::write $fh $row
        }
        close $fh
        
        log_info "CSV exportiert: $csv_path ([expr {[llength $rows] / [llength $column_names]}] Zeilen)"
        return $csv_path
    }
    
    proc export_json {table} {
        validate_table_name $table ::DOCS_EXPORT_TABLES
        
        set conn [get_connection]
        set rows [$conn eval "SELECT * FROM $table"]
        set column_names {}
        if {[llength $rows] > 0} {
            set stmt [$conn prepare "SELECT * FROM $table LIMIT 1"]
            set column_names [$stmt columns]
            $stmt finalize
        }
        close_connection $conn
        
        if {[llength $rows] == 0} {
            log_info "Tabelle '$table' ist leer — kein JSON erzeugt"
            return
        }
        
        set data {}
        set num_columns [llength $column_names]
        for {set i 0} {$i < [llength $rows]} {incr i $num_columns} {
            set row_dict {}
            for {set j 0} {$j < $num_columns} {incr j} {
                dict set row_dict [lindex $column_names $j] [lindex $rows [expr {$i + $j}]]
            }
            lappend data $row_dict
        }
        
        set json_path [file join $::WORKSPACE "export_${table}.json"]
        set fh [open $json_path w]
        puts $fh [json::encode $data]
        close $fh
        
        log_info "JSON exportiert: $json_path ([llength $data] Einträge)"
        return $json_path
    }
}

# ---------------------------------------------------------------------------
# TreeDatabase
# ---------------------------------------------------------------------------

namespace eval TreeDatabase {
    variable db_path
    
    proc new {} {
        variable db_path
        set db_path [file join $::DB_DIR "tree.db"]
        return [namespace current]
    }
    
    proc get_connection {} {
        variable db_path
        sqlite3 db $db_path
        db eval {PRAGMA foreign_keys = ON}
        return db
    }
    
    proc close_connection {conn} {
        $conn close
    }
    
    proc init_schema {} {
        variable db_path
        set conn [get_connection]
        
        $conn eval {
            CREATE TABLE IF NOT EXISTS tree_entries (
                id            INTEGER PRIMARY KEY AUTOINCREMENT,
                root_path     TEXT    NOT NULL,
                relative_path TEXT    NOT NULL,
                name          TEXT    NOT NULL,
                type          TEXT    CHECK(type IN ('file', 'directory', 'symlink')),
                depth         INTEGER,
                parent_path   TEXT,
                size          INTEGER,
                created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE TABLE IF NOT EXISTS tree_scans (
                id             INTEGER PRIMARY KEY AUTOINCREMENT,
                root_path      TEXT    NOT NULL,
                max_depth      INTEGER,
                total_files    INTEGER,
                total_dirs     INTEGER,
                total_symlinks INTEGER,
                scanned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        }
        
        close_connection $conn
        log_info "tree.db Schema initialisiert: $db_path"
        return [namespace current]
    }
    
    proc add_entry {root_path relative_path name entry_type depth parent_path {size 0}} {
        set conn [get_connection]
        $conn eval {
            INSERT INTO tree_entries
            (root_path, relative_path, name, type, depth, parent_path, size)
            VALUES ($root_path, $relative_path, $name, $entry_type, $depth, $parent_path, $size)
        }
        close_connection $conn
    }
    
    proc export_csv {{root_path_filter ""}} {
        set conn [get_connection]
        
        if {$root_path_filter ne ""} {
            set rows [$conn eval {
                SELECT * FROM tree_entries WHERE root_path = $root_path_filter
            }]
        } else {
            set rows [$conn eval {SELECT * FROM tree_entries}]
        }
        
        set column_names {}
        if {[llength $rows] > 0} {
            set stmt [$conn prepare "SELECT * FROM tree_entries LIMIT 1"]
            set column_names [$stmt columns]
            $stmt finalize
        }
        close_connection $conn
        
        if {[llength $rows] == 0} {
            log_info "Keine Tree-Einträge vorhanden — kein CSV erzeugt"
            return
        }
        
        set suffix [expr {$root_path_filter eq "" ? "_all" : "_[string map {"/" "_"} $root_path_filter]"}]
        set csv_path [file join $::WORKSPACE "export_tree${suffix}.csv"]
        
        set fh [open $csv_path w]
        csv::write $fh $column_names
        foreach row $rows {
            csv::write $fh $row
        }
        close $fh
        
        log_info "Tree-CSV exportiert: $csv_path ([expr {[llength $rows] / [llength $column_names]}] Einträge)"
        return $csv_path
    }
}

# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

proc main {} {
    puts [string repeat "=" 60]
    puts "WORKSPACE DATABASE MANAGER"
    puts [string repeat "=" 60]
    
    # DB-Verzeichnis hier (nicht auf Modulebene) anlegen
    if {![file exists $::DB_DIR]} {
        if {[catch {file mkdir $::DB_DIR} err]} {
            log_error "DB-Verzeichnis konnte nicht erstellt werden: $err"
            exit 1
        }
    }
    log_info "DB-Verzeichnis: $::DB_DIR"
    
    # docs.db aufbauen
    set docs_db [DocsDatabase::new]
    DocsDatabase::init_schema
    DocsDatabase::populate_from_workspace
    
    # Exporte
    puts "\n--- Exporte docs.db ---"
    foreach table {documents skills symlinks} {
        DocsDatabase::export_csv $table
    }
    DocsDatabase::export_json documents
    
    # tree.db aufbauen (Daten kommen via tree.py)
    puts "\n--- tree.db Initialisierung ---"
    set tree_db [TreeDatabase::new]
    TreeDatabase::init_schema
    log_info "Tree-Daten werden via tree.py Script befüllt"
    
    puts "\n[string repeat "=" 60]"
    puts "DATENBANKEN BEREIT"
    puts [string repeat "=" 60]
    puts "\nDatenbanken: $::DB_DIR/"
    puts "Exporte:     $::WORKSPACE/"
}

if {[info script] eq $argv0} {
    main
}
