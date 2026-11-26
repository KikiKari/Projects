// abstraction-provenance: {"artifact_sha256": "eb7a795bbc40488cfd37325ed2e2b314572cd2a901e6c1ad4c6f286210da712e", "source_sha256": "8d48f51942bb1c171bbd41e0696beb0722cb4b94d6596233f54b32928b645086", "target_language": "go"}
// db_maintainer.py — portiert nach go
// Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/*
Database Maintainer Sub-Agent
Automated database maintenance with 30min checks, hourly backups (3 days retention),
band tree command execution for important/openclaw-tree.txt
*/

package main

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/spf13/afero"
)

var (
	fs           = afero.NewOsFs()
	WORKSPACE    string
	DB_DIR       string
	BACKUP_DIR   string
	LOG_DIR      string
	IMPORTANT_DIR string
)

func init() {
	if envWorkspace := os.Getenv("OPENCLAW_WORKSPACE"); envWorkspace != "" {
		WORKSPACE = envWorkspace
	} else {
		exePath, _ := os.Executable()
		WORKSPACE = filepath.Dir(filepath.Dir(exePath))
	}
	
	DB_DIR = WORKSPACE
	BACKUP_DIR = filepath.Join(WORKSPACE, "db", "backups")
	LOG_DIR = filepath.Join(WORKSPACE, "logs", "db-maintainer")
	IMPORTANT_DIR = filepath.Join(WORKSPACE, "important")
	
	os.MkdirAll(BACKUP_DIR, 0755)
	os.MkdirAll(LOG_DIR, 0755)
	os.MkdirAll(IMPORTANT_DIR, 0755)
}

type Logger struct {
	logFile *os.File
}

func NewLogger() *Logger {
	today := time.Now().Format("2006-01-02")
	logFilePath := filepath.Join(LOG_DIR, today+".log")
	
	file, err := os.OpenFile(logFilePath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		panic(fmt.Sprintf("Cannot create log file: %v", err))
	}
	
	return &Logger{logFile: file}
}

func (l *Logger) log(level, message string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	line := fmt.Sprintf("[%s] [%s] %s\n", timestamp, level, message)
	fmt.Print(line)
	l.logFile.WriteString(line)
}

func (l *Logger) Info(msg string)  { l.log("INFO", msg) }
func (l *Logger) Warn(msg string)  { l.log("WARN", msg) }
func (l *Logger) Error(msg string) { l.log("ERROR", msg) }

type State struct {
	LastCheck      *time.Time            `json:"last_check"`
	LastBackup     *time.Time            `json:"last_backup"`
	LastTreeUpdate *time.Time            `json:"last_tree_update"`
	FileHashes     map[string]string     `json:"file_hashes"`
}

type Document struct {
	Path  string `json:"path"`
	Hash  string `json:"hash"`
	MTime int64  `json:"mtime"`
}

type DatabaseMaintainer struct {
	logger     *Logger
	stateFile  string
	retentionDays int
}

func NewDatabaseMaintainer() *DatabaseMaintainer {
	return &DatabaseMaintainer{
		logger:        NewLogger(),
		stateFile:     filepath.Join(DB_DIR, "maintainer_state.json"),
		retentionDays: 3,
	}
}

func (dm *DatabaseMaintainer) LoadState() *State {
	state := &State{
		FileHashes: make(map[string]string),
	}
	
	if _, err := os.Stat(dm.stateFile); os.IsNotExist(err) {
		return state
	}
	
	data, err := os.ReadFile(dm.stateFile)
	if err != nil {
		dm.logger.Error(fmt.Sprintf("Failed to read state file: %v", err))
		return state
	}
	
	var raw map[string]interface{}
	if err := json.Unmarshal(data, &raw); err != nil {
		dm.logger.Error(fmt.Sprintf("Failed to parse state JSON: %v", err))
		return state
	}
	
	if lc, ok := raw["last_check"].(string); ok {
		if t, err := time.Parse(time.RFC3339, lc); err == nil {
			state.LastCheck = &t
		}
	}
	if lb, ok := raw["last_backup"].(string); ok {
		if t, err := time.Parse(time.RFC3339, lb); err == nil {
			state.LastBackup = &t
		}
	}
	if lt, ok := raw["last_tree_update"].(string); ok {
		if t, err := time.Parse(time.RFC3339, lt); err == nil {
			state.LastTreeUpdate = &t
		}
	}
	if fh, ok := raw["file_hashes"].(map[string]interface{}); ok {
		for k, v := range fh {
			if s, ok := v.(string); ok {
				state.FileHashes[k] = s
			}
		}
	}
	
	return state
}

func (dm *DatabaseMaintainer) SaveState(state *State) {
	data, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		dm.logger.Error(fmt.Sprintf("Failed to marshal state: %v", err))
		return
	}
	
	if err := os.WriteFile(dm.stateFile, data, 0644); err != nil {
		dm.logger.Error(fmt.Sprintf("Failed to write state file: %v", err))
	}
}

func (dm *DatabaseMaintainer) GetFileHash(filepath string) string {
	file, err := os.Open(filepath)
	if err != nil {
		return ""
	}
	defer file.Close()
	
	hash := md5.New()
	if _, err := io.Copy(hash, file); err != nil {
		return ""
	}
	
	return hex.EncodeToString(hash.Sum(nil))
}

func (dm *DatabaseMaintainer) pythonTreeFallback(maxDepth int) string {
	var lines []string
	lines = append(lines, WORKSPACE)
	
	walk := func(dirpath string, prefix string, depth int, visit func(string, string, int)) {
		if depth > maxDepth {
			return
		}
		
		entries, err := os.ReadDir(dirpath)
		if err != nil {
			return
		}
		
		// Sort entries: directories first, then alphabetically
		sort.Slice(entries, func(i, j int) bool {
			if entries[i].IsDir() == entries[j].IsDir() {
				return entries[i].Name() < entries[j].Name()
			}
			return entries[i].IsDir()
		})
		
		for i, entry := range entries {
			connector := "├── "
			if i == len(entries)-1 {
				connector = "└── "
			}
			
			lines = append(lines, prefix+connector+entry.Name())
			
			if entry.IsDir() && !entry.Type().Perm().IsSymlink() {
				extension := "│   "
				if i == len(entries)-1 {
					extension = "    "
				}
				visit(filepath.Join(dirpath, entry.Name()), prefix+extension, depth+1)
			}
		}
	}
	
	walk(WORKSPACE, "", 1, walk)
	return strings.Join(lines, "\n") + "\n"
}

func (dm *DatabaseMaintainer) RunTreeCommand() string {
	cmd := exec.Command("tree", "-a", "-L", "8", WORKSPACE)
	output, err := cmd.Output()
	
	if err == nil {
		dm.logger.Info("tree -a -L 8 erfolgreich ausgeführt")
		return string(output)
	}
	
	dm.logger.Warn(fmt.Sprintf("tree command fehlgeschlagen: %v – nutze Python-Fallback", err))
	return dm.pythonTreeFallback(8)
}

func (dm *DatabaseMaintainer) UpdateTreeFile(treeOutput string) bool {
	if treeOutput == "" {
		return false
	}
	
	treeFile := filepath.Join(IMPORTANT_DIR, "openclaw-tree.txt")
	
	header := fmt.Sprintf(`# OpenClaw Workspace Tree
# Generiert: %s
# Befehl: tree -a -L 8 %s
# Diese Datei wird automatisch von db-maintainer aktualisiert

`, time.Now().Format(time.RFC3339), WORKSPACE)
	
	content := header + treeOutput
	
	if err := os.WriteFile(treeFile, []byte(content), 0644); err != nil {
		dm.logger.Error(fmt.Sprintf("Fehler beim Schreiben von openclaw-tree.txt: %v", err))
		return false
	}
	
	dm.logger.Info(fmt.Sprintf("openclaw-tree.txt aktualisiert: %s", treeFile))
	return true
}

func (dm *DatabaseMaintainer) ScanDocumentations() []Document {
	var docs []Document
	
	err := filepath.Walk(WORKSPACE, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Continue walking despite errors
		}
		
		if !info.Mode().IsRegular() || !strings.HasSuffix(info.Name(), ".md") {
			return nil
		}
		
		relPath, _ := filepath.Rel(WORKSPACE, path)
		
		// Skip backups and node_modules
		if strings.Contains(relPath, "db/backups") || strings.Contains(relPath, "node_modules") {
			return nil
		}
		
		docs = append(docs, Document{
			Path:  relPath,
			Hash:  dm.GetFileHash(path),
			MTime: info.ModTime().Unix(),
		})
		
		return nil
	})
	
	if err != nil {
		dm.logger.Error(fmt.Sprintf("Error scanning documentation: %v", err))
	}
	
	return docs
}

func (dm *DatabaseMaintainer) CheckForChanges() ([]string, map[string]string) {
	state := dm.LoadState()
	currentDocs := dm.ScanDocumentations()
	
	var changes []string
	currentHashes := make(map[string]string)
	
	for _, doc := range currentDocs {
		path := doc.Path
		currentHashes[path] = doc.Hash
		
		if oldHash, exists := state.FileHashes[path]; !exists {
			changes = append(changes, "NEW: "+path)
		} else if oldHash != doc.Hash {
			changes = append(changes, "CHANGED: "+path)
		}
	}
	
	// Check for deleted files
	for oldPath := range state.FileHashes {
		if _, exists := currentHashes[oldPath]; !exists {
			changes = append(changes, "DELETED: "+oldPath)
		}
	}
	
	return changes, currentHashes
}

func (dm *DatabaseMaintainer) UpdateDatabases() bool {
	scriptPath := filepath.Join(WORKSPACE, "scripts", "update_docs_db.py")
	cmd := exec.Command("python3", scriptPath)
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		dm.logger.Error(fmt.Sprintf("DB-Update fehlgeschlagen: %s", string(output)))
		return false
	}
	
	dm.logger.Info("docs.db aktualisiert")
	return true
}

func (dm *DatabaseMaintainer) UpdateTreeDbV2() bool {
	scriptPath := filepath.Join(WORKSPACE, "scripts", "tree_indexer_v2.py")
	cmd := exec.Command("python3", scriptPath)
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		dm.logger.Error(fmt.Sprintf("Tree-DB v2 fehlgeschlagen: %s", string(output)))
		return false
	}
	
	dm.logger.Info("tree.db v2 aktualisiert")
	return true
}

func (dm *DatabaseMaintainer) CreateBackup() string {
	timestamp := time.Now().Format("2006-01-02_15-04")
	
	for _, dbName := range []string{"docs.db", "tree.db"} {
		source := filepath.Join(DB_DIR, dbName)
		if _, err := os.Stat(source); err == nil {
			backupName := fmt.Sprintf("%s_%s.bak", timestamp, dbName)
			backupPath := filepath.Join(BACKUP_DIR, backupName)
			
			input, err := os.ReadFile(source)
			if err != nil {
				dm.logger.Error(fmt.Sprintf("Failed to read source DB: %v", err))
				continue
			}
			
			if err := os.WriteFile(backupPath, input, 0644); err != nil {
				dm.logger.Error(fmt.Sprintf("Failed to write backup: %v", err))
				continue
			}
			
			dm.logger.Info(fmt.Sprintf("Backup erstellt: %s", backupName))
		}
	}
	
	return timestamp
}

func (dm *DatabaseMaintainer) CleanupOldBackups() {
	cutoff := time.Now().Add(-time.Duration(dm.retentionDays) * 24 * time.Hour)
	deleted := 0
	
	for _, dbName := range []string{"docs.db", "tree.db"} {
		pattern := filepath.Join(BACKUP_DIR, "*_"+dbName+".bak")
		matches, _ := filepath.Glob(pattern)
		
		for _, backup := range matches {
			filename := filepath.Base(backup)
			parts := strings.Split(filename, "_")
			if len(parts) < 2 {
				dm.logger.Warn(fmt.Sprintf("Konnte Backup-Datum nicht parsen: %s", filename))
				continue
			}
			
			dateStr := parts[0]
			timeStr := strings.TrimSuffix(parts[1], ".bak")
			
			backupTime, err := time.Parse("2006-01-02_15-04", dateStr+"_"+timeStr)
			if err != nil {
				dm.logger.Warn(fmt.Sprintf("Konnte Backup-Datum nicht parsen: %s", filename))
				continue
			}
			
			if backupTime.Before(cutoff) {
				if err := os.Remove(backup); err != nil {
					dm.logger.Error(fmt.Sprintf("Failed to delete backup: %v", err))
					continue
				}
				deleted++
				dm.logger.Info(fmt.Sprintf("Altes Backup gelöscht: %s", filename))
			}
		}
	}
	
	if deleted == 0 {
		dm.logger.Info("Keine alten Backups zum Löschen")
	} else {
		dm.logger.Info(fmt.Sprintf("%d alte Backups gelöscht (< 3 Tage)", deleted))
	}
}

func (dm *DatabaseMaintainer) RunCycle() {
	dm.logger.Info(strings.Repeat("=", 60))
	dm.logger.Info("DB MAINTAINER CYCLE START")
	dm.logger.Info(strings.Repeat("=", 60))
	
	state := dm.LoadState()
	
	// 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
	dm.logger.Info("Führe tree -a -L 8 aus...")
	treeOutput := dm.RunTreeCommand()
	if treeOutput != "" {
		dm.UpdateTreeFile(treeOutput)
		now := time.Now()
		state.LastTreeUpdate = &now
	}
	
	// 2. tree.db aktualisieren (intern v2)
	dm.logger.Info("Aktualisiere tree.db v2...")
	dm.UpdateTreeDbV2()
	
	// 3. Änderungen prüfen
	dm.logger.Info("Prüfe auf Dokumentations-Änderungen...")
	changes, currentHashes := dm.CheckForChanges()
	
	if len(changes) > 0 {
		dm.logger.Info(fmt.Sprintf("%d Änderungen gefunden:", len(changes)))
		displayCount := len(changes)
		if displayCount > 10 {
			displayCount = 10
		}
		
		for i := 0; i < displayCount; i++ {
			dm.logger.Info(fmt.Sprintf("  - %s", changes[i]))
		}
		
		if len(changes) > 10 {
			dm.logger.Info(fmt.Sprintf("  ... und %d weitere", len(changes)-10))
		}
		
		// 4. docs.db aktualisieren
		dm.logger.Info("Aktualisiere docs.db...")
		if dm.UpdateDatabases() {
			now := time.Now()
			state.LastCheck = &now
			state.FileHashes = currentHashes
		}
	} else {
		dm.logger.Info("Keine Dokumentations-Änderungen gefunden")
	}
	
	// 5. Prüfe ob Backup fällig (stündlich)
	doBackup := state.LastBackup == nil
	
	if state.LastBackup != nil {
		doBackup = time.Since(*state.LastBackup) >= time.Hour
	}
	
	if doBackup {
		dm.logger.Info("Erstelle stündliches Backup...")
		timestamp := dm.CreateBackup()
		now := time.Now()
		state.LastBackup = &now
		
		// 6. Alte Backups aufräumen (3 Tage Retention)
		dm.logger.Info("Räume alte Backups auf (3 Tage Retention)...")
		dm.CleanupOldBackups()
	} else {
		dm.logger.Info("Backup nicht nötig (letztes < 1h)")
	}
	
	dm.SaveState(state)
	
	dm.logger.Info(strings.Repeat("=", 60))
	dm.logger.Info("DB MAINTAINER CYCLE END")
	dm.logger.Info(strings.Repeat("=", 60))
}

func main() {
	maintainer := NewDatabaseMaintainer()
	
	defer func() {
		if r := recover(); r != nil {
			maintainer.logger.Error(fmt.Sprintf("CRITICAL ERROR: %v", r))
			os.Exit(1)
		}
	}()
	
	maintainer.RunCycle()
}
