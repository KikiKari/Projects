// abstraction-provenance: {"artifact_sha256": "858b4259109f0dd059ac370b3957c1cefe72b3934a60167a99d674ad375b1d04", "source_sha256": "62685d1bad45f2dffb79d4424a8a668a222d4008e157a9d6b51a3e2a1d1d204d", "target_language": "go"}
// db_manager.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:scripts/db_manager.py
// auch in: OpenClaw@gateway2:scripts/db_manager.py
// auch in: Projects@abstractions:abstractions/db_manager.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/*
Workspace Documentation Database Manager

Erstellt und verwaltet docs.db und tree.db im Workspace-Datenbankverzeichnis.
Beide Datenbanken liegen unter $OPENCLAW_WORKSPACE/db/.

Verwendung:
    go run db_manager.go

Konfiguration:
    OPENCLAW_WORKSPACE (Umgebungsvariable) — Standard: /home/openclaw/.openclaw/workspace
*/

package main

import (
	"context"
	"database/sql"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

// ---------------------------------------------------------------------------
// Konfiguration
// ---------------------------------------------------------------------------

var (
	WORKSPACE string
	DB_DIR    string
)

func init() {
	WORKSPACE = getEnvOrDefault("OPENCLAW_WORKSPACE", "/home/openclaw/.openclaw/workspace")
	DB_DIR = filepath.Join(WORKSPACE, "db")
}

// Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
var DOCS_EXPORT_TABLES = map[string]bool{
	"documents": true,
	"categories": true,
	"symlinks":  true,
	"skills":    true,
}

var TREE_EXPORT_TABLES = map[string]bool{
	"tree_entries": true,
	"tree_scans":   true,
}

// ---------------------------------------------------------------------------
// Hilfsfunktionen
// ---------------------------------------------------------------------------

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return !os.IsNotExist(err)
}

// ---------------------------------------------------------------------------
// DocsDatabase
// ---------------------------------------------------------------------------

type DocsDatabase struct {
	dbPath string
}

func NewDocsDatabase() *DocsDatabase {
	return &DocsDatabase{
		dbPath: filepath.Join(DB_DIR, "docs.db"),
	}
}

func (db *DocsDatabase) getConnection() (*sql.DB, error) {
	conn, err := sql.Open("sqlite3", db.dbPath)
	if err != nil {
		return nil, fmt.Errorf("Fehler beim Öffnen der Datenbank: %v", err)
	}
	return conn, nil
}

func (db *DocsDatabase) initSchema() error {
	conn, err := db.getConnection()
	if err != nil {
		return err
	}
	defer conn.Close()

	queries := []string{
		`CREATE TABLE IF NOT EXISTS documents (
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
		)`,

		`CREATE TABLE IF NOT EXISTS categories (
			id          INTEGER PRIMARY KEY AUTOINCREMENT,
			name        TEXT    UNIQUE NOT NULL,
			description TEXT,
			priority    INTEGER DEFAULT 0
		)`,

		`CREATE TABLE IF NOT EXISTS symlinks (
			id          INTEGER PRIMARY KEY AUTOINCREMENT,
			name        TEXT    NOT NULL,
			target      TEXT    NOT NULL,
			source_path TEXT    NOT NULL,
			description TEXT,
			created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)`,

		`CREATE TABLE IF NOT EXISTS skills (
			id          INTEGER PRIMARY KEY AUTOINCREMENT,
			name        TEXT    NOT NULL,
			version     TEXT,
			status      TEXT    CHECK(status IN ('installed', 'local', 'published')),
			description TEXT,
			path        TEXT
		)`,
	}

	for _, query := range queries {
		_, err = conn.Exec(query)
		if err != nil {
			return fmt.Errorf("Fehler bei der Schema-Erstellung: %v", err)
		}
	}

	log.Printf("docs.db Schema initialisiert: %s", db.dbPath)
	return nil
}

func (db *DocsDatabase) populateFromWorkspace() error {
	categories := [][]interface{}{
		{"main", "Hauptverzeichnis Dateien", 1},
		{"memory", "Memory und Protokolle", 2},
		{"reports", "Berichte und Analysen", 3},
		{"cluster", "Cluster und Infrastruktur", 4},
		{"skills", "Installierte Skills", 5},
		{"websearch", "WebSearch Dokumentationen", 6},
		{"mcp", "MCP Integration", 7},
		{"links", "Symbolische Links", 8},
	}

	docs := [][]interface{}{
		{"AGENTS.md", "/", "main", "Agent-Konfiguration, Memory-Regeln", "config", false, nil, "2026-04-11"},
		{"SOUL.md", "/", "main", "Agent-Persönlichkeit und Kernwahrheiten", "config", false, nil, "2026-04-11"},
		{"IDENTITY.md", "/", "main", "Agent-Name und Eigenschaften", "config", false, nil, "2026-04-11"},
		{"USER.md", "/", "main", "Benutzerinformationen", "config", false, nil, "2026-04-11"},
		{"TOOLS.md", "/", "main", "Tool-spezifische Konfigurationen", "config", false, nil, "2026-04-18"},
		{"MEMORY.md", "/", "main", "Langzeitspeicher, System-Konfiguration", "config", false, nil, "2026-04-11"},
		{"DOCUMENTATION-INDEX.md", "/", "main", "Übersicht aller Dokumentationen", "doc", false, nil, "2026-04-18"},
		{"WORKSPACE-INDEX.md", "/", "main", "Symlink zu DOCUMENTATION-INDEX.md", "symlink", true, "DOCUMENTATION-INDEX.md", "2026-04-18"},
		{"WEBSEARCH_README.md", "websearch/", "websearch", "Schnellstart Guide", "guide", true, "websearch/WEBSEARCH_README.md", "2026-04-18"},
		{"WEBSEARCH_MCP_GUIDE.md", "websearch/", "websearch", "Vollständige technische Dokumentation", "guide", true, "websearch/WEBSEARCH_MCP_GUIDE.md", "2026-04-18"},
		{"WEBSEARCH_CONFIG.md", "websearch/", "websearch", "Konfigurations-Referenz", "config", true, "websearch/WEBSEARCH_CONFIG.md", "2026-04-18"},
		{"WEBSEARCH_PRIORITY_CONFIG.md", "websearch/", "websearch", "Provider-Priorität", "config", true, "websearch/WEBSEARCH_PRIORITY_CONFIG.md", "2026-04-18"},
		{"WEBSEARCH_SCRIPTS.md", "websearch/", "websearch", "Automation & Scripting", "script", true, "websearch/WEBSEARCH_SCRIPTS.md", "2026-04-18"},
		{"WEBSEARCH_OPS.md", "websearch/", "websearch", "IT-Operations", "guide", true, "websearch/WEBSEARCH_OPS.md", "2026-04-18"},
		{"MCP_GUIDE.md", "mcp/", "mcp", "Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md", "symlink", false, "websearch/WEBSEARCH_MCP_GUIDE.md", "2026-04-18"},
	}

	skills := [][]interface{}{
		{"json-utils", "1.0.0", "installed", "JSON parsing and validation", "skills/json-utils/"},
		{"scripting-utils", "1.0.0", "installed", "Multi-language scripting support", "skills/scripting-utils/"},
		{"tiktok-live-mon", "1.0.0", "installed", "TikTok stream monitoring", "skills/tiktok-live-mon/"},
		{"cluster-management", "1.0.0", "installed", "Cluster topology management", "skills/cluster-management/"},
		{"worker-node", "-", "local", "Worker node configuration", "skills/worker-node/"},
		{"resource-manager", "-", "local", "Resource management", "skills/resource-manager/"},
		{"git-publish-agent", "1.0.0", "local", "Git publishing automation", "skills/git-publish-agent/"},
	}

	symlinks := [][]interface{}{
		{"openclaw.env", "/home/openclaw/.config/openclaw/env", "/", "API-Keys Shortcut"},
		{"openclaw.json", "/home/openclaw/.openclaw/openclaw.json", "/", "Konfig Shortcut"},
		{"links/config/openclaw-env", "/home/openclaw/.config/openclaw/env", "links/config/", "API-Keys"},
		{"links/dotfiles/.tavily", "/home/openclaw/.tavily/", "links/dotfiles/", "Tavily Config"},
		{"links/dotfiles/.claude", "/home/openclaw/.claude/", "links/dotfiles/", "Claude Config"},
		{"links/dotfiles/.mcporter", "/home/openclaw/.mcporter/", "links/dotfiles/", "MCPorter Config"},
		{"links/dotfiles/.ssh", "/home/openclaw/.ssh/", "links/dotfiles/", "SSH Keys"},
	}

	conn, err := db.getConnection()
	if err != nil {
		return err
	}
	defer conn.Close()

	tx, err := conn.Begin()
	if err != nil {
		return fmt.Errorf("Fehler beim Starten der Transaktion: %v", err)
	}
	defer tx.Rollback()

	// Insert categories
	stmt, err := tx.Prepare("INSERT OR IGNORE INTO categories (name, description, priority) VALUES (?, ?, ?)")
	if err != nil {
		return fmt.Errorf("Fehler beim Vorbereiten der Categories-Query: %v", err)
	}
	defer stmt.Close()

	for _, category := range categories {
		_, err = stmt.Exec(category...)
		if err != nil {
			return fmt.Errorf("Fehler beim Einfügen der Category: %v", err)
		}
	}

	// Insert documents
	stmt, err = tx.Prepare(`INSERT OR REPLACE INTO documents 
		(name, path, category, description, type, has_symlink, symlink_path, last_update) 
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)`)
	if err != nil {
		return fmt.Errorf("Fehler beim Vorbereiten der Documents-Query: %v", err)
	}
	defer stmt.Close()

	for _, doc := range docs {
		_, err = stmt.Exec(doc...)
		if err != nil {
			return fmt.Errorf("Fehler beim Einfügen des Documents: %v", err)
		}
	}

	// Insert skills
	stmt, err = tx.Prepare("INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES (?, ?, ?, ?, ?)")
	if err != nil {
		return fmt.Errorf("Fehler beim Vorbereiten der Skills-Query: %v", err)
	}
	defer stmt.Close()

	for _, skill := range skills {
		_, err = stmt.Exec(skill...)
		if err != nil {
			return fmt.Errorf("Fehler beim Einfügen des Skills: %v", err)
		}
	}

	// Insert symlinks
	stmt, err = tx.Prepare("INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES (?, ?, ?, ?)")
	if err != nil {
		return fmt.Errorf("Fehler beim Vorbereiten der Symlinks-Query: %v", err)
	}
	defer stmt.Close()

	for _, symlink := range symlinks {
		_, err = stmt.Exec(symlink...)
		if err != nil {
			return fmt.Errorf("Fehler beim Einfügen des Symlinks: %v", err)
		}
	}

	err = tx.Commit()
	if err != nil {
		return fmt.Errorf("Fehler beim Commit der Transaktion: %v", err)
	}

	log.Printf("docs.db befüllt: %d Dokumente, %d Skills, %d Symlinks", len(docs), len(skills), len(symlinks))
	return nil
}

func (db *DocsDatabase) validateTableName(table string, allowed map[string]bool) error {
	if !allowed[table] {
		var allowedTables []string
		for t := range allowed {
			allowedTables = append(allowedTables, t)
		}
		return fmt.Errorf("Ungültiger Tabellenname: '%s'. Erlaubt: %v", table, allowedTables)
	}
	return nil
}

func (db *DocsDatabase) exportCSV(table string) (string, error) {
	err := db.validateTableName(table, DOCS_EXPORT_TABLES)
	if err != nil {
		return "", err
	}

	conn, err := db.getConnection()
	if err != nil {
		return "", err
	}
	defer conn.Close()

	query := fmt.Sprintf("SELECT * FROM %s", table)
	rows, err := conn.Query(query)
	if err != nil {
		return "", fmt.Errorf("Fehler beim Abfragen der Tabelle: %v", err)
	}
	defer rows.Close()

	columns, err := rows.Columns()
	if err != nil {
		return "", fmt.Errorf("Fehler beim Abrufen der Spaltennamen: %v", err)
	}

	var result [][]string
	for rows.Next() {
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))
		for i := range values {
			valuePtrs[i] = &values[i]
		}

		err = rows.Scan(valuePtrs...)
		if err != nil {
			return "", fmt.Errorf("Fehler beim Scannen der Zeile: %v", err)
		}

		row := make([]string, len(columns))
		for i, val := range values {
			if val == nil {
				row[i] = ""
			} else {
				row[i] = fmt.Sprintf("%v", val)
			}
		}
		result = append(result, row)
	}

	if len(result) == 0 {
		log.Printf("Tabelle '%s' ist leer — kein CSV erzeugt", table)
		return "", nil
	}

	csvPath := filepath.Join(WORKSPACE, fmt.Sprintf("export_%s.csv", table))
	file, err := os.Create(csvPath)
	if err != nil {
		return "", fmt.Errorf("Fehler beim Erstellen der CSV-Datei: %v", err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	err = writer.Write(columns)
	if err != nil {
		return "", fmt.Errorf("Fehler beim Schreiben der Header: %v", err)
	}

	for _, row := range result {
		err = writer.Write(row)
		if err != nil {
			return "", fmt.Errorf("Fehler beim Schreiben der Zeile: %v", err)
		}
	}

	log.Printf("CSV exportiert: %s (%d Zeilen)", csvPath, len(result))
	return csvPath, nil
}

func (db *DocsDatabase) exportJSON(table string) (string, error) {
	err := db.validateTableName(table, DOCS_EXPORT_TABLES)
	if err != nil {
		return "", err
	}

	conn, err := db.getConnection()
	if err != nil {
		return "", err
	}
	defer conn.Close()

	query := fmt.Sprintf("SELECT * FROM %s", table)
	rows, err := conn.Query(query)
	if err != nil {
		return "", fmt.Errorf("Fehler beim Abfragen der Tabelle: %v", err)
	}
	defer rows.Close()

	columns, err := rows.Columns()
	if err != nil {
		return "", fmt.Errorf("Fehler beim Abrufen der Spaltennamen: %v", err)
	}

	var result []map[string]interface{}
	for rows.Next() {
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))
		for i := range values {
			valuePtrs[i] = &values[i]
		}

		err = rows.Scan(valuePtrs...)
		if err != nil {
			return "", fmt.Errorf("Fehler beim Scannen der Zeile: %v", err)
		}

		row := make(map[string]interface{})
		for i, col := range columns {
			val := values[i]
			if val == nil {
				row[col] = nil
			} else {
				row[col] = val
			}
		}
		result = append(result, row)
	}

	if len(result) == 0 {
		log.Printf("Tabelle '%s' ist leer — kein JSON erzeugt", table)
		return "", nil
	}

	jsonPath := filepath.Join(WORKSPACE, fmt.Sprintf("export_%s.json", table))
	file, err := os.Create(jsonPath)
	if err != nil {
		return "", fmt.Errorf("Fehler beim Erstellen der JSON-Datei: %v", err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	err = encoder.Encode(result)
	if err != nil {
		return "", fmt.Errorf("Fehler beim Schreiben der JSON-Daten: %v", err)
	}

	log.Printf("JSON exportiert: %s (%d Einträge)", jsonPath, len(result))
	return jsonPath, nil
}

// ---------------------------------------------------------------------------
// TreeDatabase
// ---------------------------------------------------------------------------

type TreeDatabase struct {
	dbPath string
}

func NewTreeDatabase() *TreeDatabase {
	return &TreeDatabase{
		dbPath: filepath.Join(DB_DIR, "tree.db"),
	}
}

func (db *TreeDatabase) getConnection() (*sql.DB, error) {
	conn, err := sql.Open("sqlite3", db.dbPath)
	if err != nil {
		return nil, fmt.Errorf("Fehler beim Öffnen der Datenbank: %v", err)
	}
	return conn, nil
}

func (db *TreeDatabase) initSchema() error {
	conn, err := db.getConnection()
	if err != nil {
		return err
	}
	defer conn.Close()

	queries := []string{
		`CREATE TABLE IF NOT EXISTS tree_entries (
			id            INTEGER PRIMARY KEY AUTOINCREMENT,
			root_path     TEXT    NOT NULL,
			relative_path TEXT    NOT NULL,
			name          TEXT    NOT NULL,
			type          TEXT    CHECK(type IN ('file', 'directory', 'symlink')),
			depth         INTEGER,
			parent_path   TEXT,
			size          INTEGER,
			created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)`,

		`CREATE TABLE IF NOT EXISTS tree_scans (
			id             INTEGER PRIMARY KEY AUTOINCREMENT,
			root_path      TEXT    NOT NULL,
			max_depth      INTEGER,
			total_files    INTEGER,
			total_dirs     INTEGER,
			total_symlinks INTEGER,
			scanned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)`,
	}

	for _, query := range queries {
		_, err = conn.Exec(query)
		if err != nil {
			return fmt.Errorf("Fehler bei der Schema-Erstellung: %v", err)
		}
	}

	log.Printf("tree.db Schema initialisiert: %s", db.dbPath)
	return nil
}

func (db *TreeDatabase) addEntry(rootPath, relativePath, name, entryType string, depth int, parentPath string, size int) error {
	conn, err := db.getConnection()
	if err != nil {
		return err
	}
	defer conn.Close()

	stmt, err := conn.Prepare(`INSERT INTO tree_entries 
		(root_path, relative_path, name, type, depth, parent_path, size) 
		VALUES (?, ?, ?, ?, ?, ?, ?)`)
	if err != nil {
		return fmt.Errorf("Fehler beim Vorbereiten der Query: %v", err)
	}
	defer stmt.Close()

	_, err = stmt.Exec(rootPath, relativePath, name, entryType, depth, parentPath, size)
	if err != nil {
		return fmt.Errorf("Fehler beim Einfügen des Eintrags: %v", err)
	}

	return nil
}

func (db *TreeDatabase) exportCSV(rootPathFilter string) (string, error) {
	conn, err := db.getConnection()
	if err != nil {
		return "", err
	}
	defer conn.Close()

	var rows *sql.Rows
	if rootPathFilter != "" {
		rows, err = conn.Query("SELECT * FROM tree_entries WHERE root_path = ?", rootPathFilter)
	} else {
		rows, err = conn.Query("SELECT * FROM tree_entries")
	}
	if err != nil {
		return "", fmt.Errorf("Fehler beim Abfragen der Tabelle: %v", err)
	}
	defer rows.Close()

	columns, err := rows.Columns()
	if err != nil {
		return "", fmt.Errorf("Fehler beim Abrufen der Spaltennamen: %v", err)
	}

	var result [][]string
	for rows.Next() {
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))
		for i := range values {
			valuePtrs[i] = &values[i]
		}

		err = rows.Scan(valuePtrs...)
		if err != nil {
			return "", fmt.Errorf("Fehler beim Scannen der Zeile: %v", err)
		}

		row := make([]string, len(columns))
		for i, val := range values {
			if val == nil {
				row[i] = ""
			} else {
				row[i] = fmt.Sprintf("%v", val)
			}
		}
		result = append(result, row)
	}

	if len(result) == 0 {
		log.Println("Keine Tree-Einträge vorhanden — kein CSV erzeugt")
		return "", nil
	}

	suffix := "_all"
	if rootPathFilter != "" {
		suffix = "_" + strings.ReplaceAll(rootPathFilter, "/", "_")
	}
	csvPath := filepath.Join(WORKSPACE, fmt.Sprintf("export_tree%s.csv", suffix))

	file, err := os.Create(csvPath)
	if err != nil {
		return "", fmt.Errorf("Fehler beim Erstellen der CSV-Datei: %v", err)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	err = writer.Write(columns)
	if err != nil {
		return "", fmt.Errorf("Fehler beim Schreiben der Header: %v", err)
	}

	for _, row := range result {
		err = writer.Write(row)
		if err != nil {
			return "", fmt.Errorf("Fehler beim Schreiben der Zeile: %v", err)
		}
	}

	log.Printf("Tree-CSV exportiert: %s (%d Einträge)", csvPath, len(result))
	return csvPath, nil
}

// ---------------------------------------------------------------------------
// Einstiegspunkt
// ---------------------------------------------------------------------------

func main() {
	fmt.Println("=" + strings.Repeat("-", 59))
	fmt.Println("WORKSPACE DATABASE MANAGER")
	fmt.Println("=" + strings.Repeat("-", 59))

	// DB-Verzeichnis hier (nicht auf Modulebene) anlegen
	err := os.MkdirAll(DB_DIR, 0755)
	if err != nil {
		log.Fatalf("DB-Verzeichnis konnte nicht erstellt werden: %v", err)
	}
	log.Printf("DB-Verzeichnis: %s", DB_DIR)

	// docs.db aufbauen
	docsDB := NewDocsDatabase()
	err = docsDB.initSchema()
	if err != nil {
		log.Fatalf("Fehler bei der Initialisierung des docs.db-Schemas: %v", err)
	}

	err = docsDB.populateFromWorkspace()
	if err != nil {
		log.Fatalf("Fehler beim Befüllen der docs.db: %v", err)
	}

	// Exporte
	fmt.Println("\n--- Exporte docs.db ---")
	for _, table := range []string{"documents", "skills", "symlinks"} {
		_, err = docsDB.exportCSV(table)
		if err != nil {
			log.Printf("Fehler beim Exportieren der Tabelle %s: %v", table, err)
		}
	}

	_, err = docsDB.exportJSON("documents")
	if err != nil {
		log.Printf("Fehler beim Exportieren der documents-Tabelle als JSON: %v", err)
	}

	// tree.db aufbauen (Daten kommen via tree.py)
	fmt.Println("\n--- tree.db Initialisierung ---")
	treeDB := NewTreeDatabase()
	err = treeDB.initSchema()
	if err != nil {
		log.Fatalf("Fehler bei der Initialisierung des tree.db-Schemas: %v", err)
	}
	log.Println("Tree-Daten werden via tree.py Script befüllt")

	fmt.Println("\n" + "=" + strings.Repeat("-", 59))
	fmt.Println("DATENBANKEN BEREIT")
	fmt.Println("=" + strings.Repeat("-", 59))
	fmt.Printf("\nDatenbanken: %s/\n", DB_DIR)
	fmt.Printf("Exporte:     %s/\n", WORKSPACE)
}
