#!/usr/bin/env tclsh8.6
# db_manager.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:scripts/db_manager.py
# auch in: OpenClaw@gateway1:abstraction-manager/db_manager.py
# auch in: OpenClaw@gateway2:scripts/db_manager.py
# auch in: OpenClaw@gateway2:abstraction-manager/db_manager.py
# auch in: 1 weiteren Fundstellen
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

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
package require json

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

set WORKSPACE [expr {[info exists ::env(OPENCLAW_WORKSPACE)] ? $::env(OPENCLAW_WORKSPACE) : "/home/openclaw/.openclaw/workspace"}]
set DB_DIR [file join $WORKSPACE "db"]

# Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
array set _DOCS_EXPORT_TABLES {documents 1 categories 1 symlinks 1 skills 1}
array set _TREE_EXPORT_TABLES {tree_entries 1 tree_scans 1}

# ---------------------------------------------------------------------------
# Logger
# ---------------------------------------------------------------------------

proc log_message {level name message} {
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    puts "$timestamp | [format "%-8s" [string toupper $level]] | $name | $message"
}

proc log_info {name message} {
    log_message "info" $name $message
}

proc log_error {name message} {
    log_message "error" $name $message
}

# ---------------------------------------------------------------------------
# DocsDatabase
# ---------------------------------------------------------------------------

proc DocsDatabase_new {} {
    set self [dict create]
    dict set self db_path [file join $::DB_DIR "docs.db"]
    return $self
}

proc DocsDatabase_get_connection {self} {
    set db_name [dict get $self db_path]
    sqlite3 db_$db_name $db_name
    db_$db_name timeout 5000
    return db_$db_name
}

proc DocsDatabase_close_connection {db_handle} {
    $db_handle close
}

proc DocsDatabase_init_schema {self} {
    set db [DocsDatabase_get_connection $self]
    
    $db eval {
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
        )
    }
    
    $db eval {
        CREATE TABLE IF NOT EXISTS categories (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    UNIQUE NOT NULL,
            description TEXT,
            priority    INTEGER DEFAULT 0
        )
    }
    
    $db eval {
        CREATE TABLE IF NOT EXISTS symlinks (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL,
            target      TEXT    NOT NULL,
            source_path TEXT    NOT NULL,
            description TEXT,
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    }
    
    $db eval {
        CREATE TABLE IF NOT EXISTS skills (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL,
            version     TEXT,
            status      TEXT    CHECK(status IN ('installed', 'local', 'published')),
            description TEXT,
            path        TEXT
        )
    }
    
    $db close
    log_info "db_manager" "docs.db Schema initialisiert: [dict get $self db_path]"
    return $self
}

proc DocsDatabase_populate_from_workspace {self} {
    set db [DocsDatabase_get_connection $self]
    
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
        {AGENTS.md / main "Agent-Konfiguration, Memory-Regeln" config 0 {} 2026-04-11}
        {SOUL.md / main "Agent-Persönlichkeit und Kernwahrheiten" config 0 {} 2026-04-11}
        {IDENTITY.md / main "Agent-Name und Eigenschaften" config 0 {} 2026-04-11}
        {USER.md / main "Benutzerinformationen" config 0 {} 2026-04-11}
        {TOOLS.md / main "Tool-spezifische Konfigurationen" config 0 {} 2026-04-18}
        {MEMORY.md / main "Langzeitspeicher, System-Konfiguration" config 0 {} 2026-04-11}
        {DOCUMENTATION-INDEX.md / main "Übersicht aller Dokumentationen" doc 0 {} 2026-04-18}
        {WORKSPACE-INDEX.md / main "Symlink zu DOCUMENTATION-INDEX.md" symlink 1 DOCUMENTATION-INDEX.md 2026-04-18}
        {WEBSEARCH_README.md websearch/ websearch "Schnellstart Guide" guide 1 websearch/WEBSEARCH_README.md 2026-04-18}
        {WEBSEARCH_MCP_GUIDE.md websearch/ websearch "Vollständige technische Dokumentation" guide 1 websearch/WEBSEARCH_MCP_GUIDE.md 2026-04-18}
        {WEBSEARCH_CONFIG.md websearch/ websearch "Konfigurations-Referenz" config 1 websearch/WEBSEARCH_CONFIG.md 2026-04-18}
        {WEBSEARCH_PRIORITY_CONFIG.md websearch/ websearch "Provider-Priorität" config 1 websearch/WEBSEARCH_PRIORITY_CONFIG.md 2026-04-18}
        {WEBSEARCH_SCRIPTS.md websearch/ websearch "Automation & Scripting" script 1 websearch/WEBSEARCH_SCRIPTS.md 2026-04-18}
        {WEBSEARCH_OPS.md websearch/ websearch "IT-Operations" guide 1 websearch/WEBSEARCH_OPS.md 2026-04-18}
        {MCP_GUIDE.md mcp/ mcp "Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md" symlink 0 websearch/WEBSEARCH_MCP_GUIDE.md 2026-04-18}
    }
    
    set skills {
        {json-utils 1.0.0 installed "JSON parsing and validation" skills/json-utils/}
        {scripting-utils 1.0.0 installed "Multi-language scripting support" skills/scripting-utils/}
        {tiktok-live-mon 1.0.0 installed "TikTok stream monitoring" skills/tiktok-live-mon/}
        {cluster-management 1.0.0 installed "Cluster topology management" skills/cluster-management/}
        {worker-node - local "Worker node configuration" skills/worker-node/}
        {resource-manager - local "Resource management" skills/resource-manager/}
        {git-publish-agent 1.0.0 local "Git publishing automation" skills/git-publish-agent/}
    }
    
    set symlinks {
        {openclaw.env /home/openclaw/.config/openclaw/env / "API-Keys Shortcut"}
        {openclaw.json /home/openclaw/.openclaw/openclaw.json / "Konfig Shortcut"}
        {links/config/openclaw-env /home/openclaw/.config/openclaw/env links/config/ "API-Keys"}
        {links/dotfiles/.tavily /home/openclaw/.tavily/ links/dotfiles/ "Tavily Config"}
        {links/dotfiles/.claude /home/openclaw/.claude/ links/dotfiles/ "Claude Config"}
        {links/dotfiles/.mcporter /home/openclaw/.mcporter/ links/dotfiles/ "MCPorter Config"}
        {links/dotfiles/.ssh /home/openclaw/.ssh/ links/dotfiles/ "SSH Keys"}
    }
    
    foreach category $categories {
        $db eval {
            INSERT OR IGNORE INTO categories (name, description, priority) VALUES ($category)
        }
    }
    
    foreach doc $docs {
        $db eval {
            INSERT OR REPLACE INTO documents
            (name, path, category, description, type, has_symlink, symlink_path, last_update)
            VALUES ($doc)
        }
    }
    
    foreach skill $skills {
        $db eval {
            INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES ($skill)
        }
    }
    
    foreach symlink $symlinks {
        $db eval {
            INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES ($symlink)
        }
    }
    
    $db close
    
    log_info "db_manager" "docs.db befüllt: [llength $docs] Dokumente, [llength $skills] Skills, [llength $symlinks] Symlinks"
    return $self
}

proc DocsDatabase_validate_table_name {table allowed} {
    if {![info exists allowed($table)]} {
        error "Ungültiger Tabellenname: '$table'. Erlaubt: [lsort [array names allowed]]"
    }
}

proc DocsDatabase_export_csv {self table} {
    DocsDatabase_validate_table_name $table ::_DOCS_EXPORT_TABLES
    
    set db [DocsDatabase_get_connection $self]
    
    set rows [list]
    set column_names [list]
    
    $db eval "SELECT * FROM $table" row {
        if {[llength $column_names] == 0} {
            set column_names [dict keys $row]
        }
        lappend rows [dict values $row]
    }
    
    $db close
    
    if {[llength $rows] == 0} {
        log_info "db_manager" "Tabelle '$table' ist leer — kein CSV erzeugt"
        return
    }
    
    set csv_path [file join $::WORKSPACE "export_${table}.csv"]
    set fh [open $csv_path w]
    
    puts $fh [join $column_names ","]
    foreach row $rows {
        set escaped_row [list]
        foreach cell $row {
            if {[string match "*\[,\]*" $cell] || [string match "*\"*" $cell]} {
                set cell "\"[string map {\" \"\"} $cell]\""
            }
            lappend escaped_row $cell
        }
        puts $fh [join $escaped_row ","]
    }
    
    close $fh
    
    log_info "db_manager" "CSV exportiert: $csv_path ([llength $rows] Zeilen)"
    return $csv_path
}

proc DocsDatabase_export_json {self table} {
    DocsDatabase_validate_table_name $table ::_DOCS_EXPORT_TABLES
    
    set db [DocsDatabase_get_connection $self]
    
    set rows [list]
    $db eval "SELECT * FROM $table" row {
        lappend rows [dict get $row *]
    }
    
    $db close
    
    if {[llength $rows] == 0} {
        log_info "db_manager" "Tabelle '$table' ist leer — kein JSON erzeugt"
        return
    }
    
    set data [list]
    foreach row $rows {
        lappend data [dict create {*}$row]
    }
    
    set json_path [file join $::WORKSPACE "export_${table}.json"]
    set fh [open $json_path w]
    puts $fh [::json::write object {*}[dict get $data *]]
    close $fh
    
    log_info "db_manager" "JSON exportiert: $json_path ([llength $data] Einträge)"
    return $json_path
}

# ---------------------------------------------------------------------------
# TreeDatabase
# ---------------------------------------------------------------------------

proc TreeDatabase_new {} {
    set self [dict create]
    dict set self db_path [file join $::DB_DIR "tree.db"]
    return $self
}

proc TreeDatabase_get_connection {self} {
    set db_name [dict get $self db_path]
    sqlite3 db_$db_name $db_name
    db_$db_name timeout 5000
    return db_$db_name
}

proc TreeDatabase_close_connection {db_handle} {
    $db_handle close
}

proc TreeDatabase_init_schema {self} {
    set db [TreeDatabase_get_connection $self]
    
    $db eval {
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
        )
    }
    
    $db eval {
        CREATE TABLE IF NOT EXISTS tree_scans (
            id             INTEGER PRIMARY KEY AUTOINCREMENT,
            root_path      TEXT    NOT NULL,
            max_depth      INTEGER,
            total_files    INTEGER,
            total_dirs     INTEGER,
            total_symlinks INTEGER,
            scanned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    }
    
    $db close
    
    log_info "db_manager" "tree.db Schema initialisiert: [dict get $self db_path]"
    return $self
}

proc TreeDatabase_add_entry {self root_path relative_path name entry_type depth parent_path {size 0}} {
    set db [TreeDatabase_get_connection $self]
    
    $db eval {
        INSERT INTO tree_entries
        (root_path, relative_path, name, type, depth, parent_path, size)
        VALUES ($root_path, $relative_path, $name, $entry_type, $depth, $parent_path, $size)
    }
    
    $db close
}

proc TreeDatabase_export_csv {self {root_path_filter ""}} {
    set db [TreeDatabase_get_connection $self]
    
    set rows [list]
    set column_names [list]
    
    if {$root_path_filter ne ""} {
        $db eval {SELECT * FROM tree_entries WHERE root_path = $root_path_filter} row {
            if {[llength $column_names] == 0} {
                set column_names [dict keys $row]
            }
            lappend rows [dict values $row]
        }
    } else {
        $db eval {SELECT * FROM tree_entries} row {
            if {[llength $column_names] == 0} {
                set column_names [dict keys $row]
            }
            lappend rows [dict values $row]
        }
    }
    
    $db close
    
    if {[llength $rows] == 0} {
        log_info "db_manager" "Keine Tree-Einträge vorhanden — kein CSV erzeugt"
        return
    }
    
    set suffix [expr {$root_path_filter ne "" ? "_[string map {/ _} $root_path_filter]" : "_all"}]
    set csv_path [file join $::WORKSPACE "export_tree${suffix}.csv"]
    
    set fh [open $csv_path w]
    
    puts $fh [join $column_names ","]
    foreach row $rows {
        set escaped_row [list]
        foreach cell $row {
            if {[string match "*\[,\]*" $cell] || [string match "*\"*" $cell]} {
                set cell "\"[string map {\" \"\"} $cell]\""
            }
            lappend escaped_row $cell
        }
        puts $fh [join $escaped_row ","]
    }
    
    close $fh
    
    log_info "db_manager" "Tree-CSV exportiert: $csv_path ([llength $rows] Einträge)"
    return $csv_path
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
        if {[catch {file mkdir $::DB_DIR} error]} {
            log_error "db_manager" "DB-Verzeichnis konnte nicht erstellt werden: $error"
            exit 1
        }
    }
    log_info "db_manager" "DB-Verzeichnis: $::DB_DIR"
    
    # docs.db aufbauen
    set docs_db [DocsDatabase_new]
    DocsDatabase_init_schema $docs_db
    DocsDatabase_populate_from_workspace $docs_db
    
    # Exporte
    puts "\n--- Exporte docs.db ---"
    foreach table {documents skills symlinks} {
        DocsDatabase_export_csv $docs_db $table
    }
    DocsDatabase_export_json $docs_db "documents"
    
    # tree.db aufbauen (Daten kommen via tree.py)
    puts "\n--- tree.db Initialisierung ---"
    set tree_db [TreeDatabase_new]
    TreeDatabase_init_schema $tree_db
    log_info "db_manager" "Tree-Daten werden via tree.py Script befüllt"
    
    puts "\n[string repeat "=" 60]"
    puts "DATENBANKEN BEREIT"
    puts [string repeat "=" 60]
    puts "\nDatenbanken: $::DB_DIR/"
    puts "Exporte:     $::WORKSPACE/"
}

if {[info script] eq $argv0} {
    main
}
