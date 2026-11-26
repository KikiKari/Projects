// abstraction-provenance: {"artifact_sha256": "d182a2fd6fc221772532d18d0126b586ed3874d67a0d626a63601478d3974a98", "source_sha256": "3ee904e4ee842489bd9bef8522f5a93fc06583e6cb1c3c5243afae19a4e2ed5f", "target_language": "go"}
// db_maintainer.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/db_maintainer.py
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
	"strings"
	"time"
)

var (
	WORKSPACE   = "/home/openclaw/.openclaw/workspace"
	DB_DIR      = WORKSPACE + "/db"
	BACKUP_DIR  = DB_DIR + "/backups"
	LOG_DIR     = WORKSPACE + "/logs/db-maintainer"
	IMPORTANT_DIR = WORKSPACE + "/important"
)

func initDirs() {
	os.MkdirAll(BACKUP_DIR, 0755)
	os.MkdirAll(LOG_DIR, 0755)
}

type Logger struct {
	logFile *os.File
}

func NewLogger() *Logger {
	today := time.Now().Format("2006-01-02")
	logPath := filepath.Join(LOG_DIR, today+".log")
	
	// Öffne oder erstelle Log-Datei im Anhang-Modus
	file, err := os.OpenFile(logPath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		panic(fmt.Sprintf("Kann Log-Datei nicht öffnen: %v", err))
	}
	
	return &Logger{logFile: file}
}

func (l *Logger) log(level string, message string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	line := fmt.Sprintf("[%s] [%s] %s\n", timestamp, level, message)
	fmt.Print(line)
	l.logFile.WriteString(line)
}

func (l *Logger) Info(msg string)  { l.log("INFO", msg) }
func (l *Logger) Warn(msg string)  { l.log("WARN", msg) }
func (l *Logger) Error(msg string) { l.log("ERROR", msg) }

func (l *Logger) Close() {
	if l.logFile != nil {
		l.logFile.Close()
	}
}

type State struct {
	LastCheck       *time.Time            `json:"last_check"`
	LastBackup      *time.Time            `json:"last_backup"`
	LastTreeUpdate  *time.Time            `json:"last_tree_update"`
	FileHashes      map[string]string     `json:"file_hashes"`
}

type DocumentInfo struct {
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
	
	if _, err := os.Stat(dm.stateFile); err == nil {
		data, err := os.ReadFile(dm.stateFile)
		if err == nil {
			json.Unmarshal(data, state)
		}
	}
	
	return state
}

func (dm *DatabaseMaintainer) SaveState(state *State) {
	data, _ := json.MarshalIndent(state, "", "  ")
	os.WriteFile(dm.stateFile, data, 0644)
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

func (dm *DatabaseMaintainer) RunTreeCommand() *string {
	cmd := exec.Command("tree", "-a", "-L", "8", WORKSPACE)
	output, err := cmd.Output()
	
	if err != nil {
		dm.logger.Error(fmt.Sprintf("tree command fehlgeschlagen: %v", err))
		return nil
	}
	
	dm.logger.Info("tree -a -L 8 erfolgreich ausgeführt")
	result := string(output)
	return &result
}

func (dm *DatabaseMaintainer) UpdateTreeFile(treeOutput *string) bool {
	if treeOutput == nil {
		return false
	}
	
	treeFilePath := filepath.Join(IMPORTANT_DIR, "openclaw-tree.txt")
	
	header := fmt.Sprintf(`# OpenClaw Workspace Tree
# Generiert: %s
# Befehl: tree -a -L 8 %s
# Diese Datei wird automatisch von db-maintainer aktualisiert

`, time.Now().Format(time.RFC3339), WORKSPACE)
	
	content := header + *treeOutput
	
	err := os.WriteFile(treeFilePath, []byte(content), 0644)
	if err != nil {
		dm.logger.Error(fmt.Sprintf("Fehler beim Schreiben von openclaw-tree.txt: %v", err))
		return false
	}
	
	dm.logger.Info(fmt.Sprintf("openclaw-tree.txt aktualisiert: %s", treeFilePath))
	return true
}

func (dm *DatabaseMaintainer) ScanDocumentations() []DocumentInfo {
	var docs []DocumentInfo
	
	err := filepath.Walk(WORKSPACE, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return nil
		}
		
		relPath, _ := filepath.Rel(WORKSPACE, path)
		
		// Überspringe Backups und node_modules
		if strings.Contains(relPath, "db/backups") || strings.Contains(relPath, "node_modules") {
			return nil
		}
		
		// Nur .md Dateien
		if strings.HasSuffix(info.Name(), ".md") {
			doc := DocumentInfo{
				Path:  relPath,
				Hash:  dm.GetFileHash(path),
				MTime: info.ModTime().Unix(),
			}
			docs = append(docs, doc)
		}
		
		return nil
	})
	
	if err != nil {
		dm.logger.Error(fmt.Sprintf("Fehler beim Scannen der Dokumentation: %v", err))
	}
	
	return docs
}

func (dm *DatabaseMaintainer) CheckForChanges(state *State) ([]string, map[string]string) {
	currentDocs := dm.ScanDocumentations()
	var changes []string
	currentHashes := make(map[string]string)
	
	// Prüfe auf neue/geänderte Dateien
	for _, doc := range currentDocs {
		path := doc.Path
		currentHashes[path] = doc.Hash
		
		if oldHash, exists := state.FileHashes[path]; !exists {
			changes = append(changes, fmt.Sprintf("NEW: %s", path))
		} else if oldHash != doc.Hash {
			changes = append(changes, fmt.Sprintf("CHANGED: %s", path))
		}
	}
	
	// Prüfe auf gelöschte Dateien
	for oldPath := range state.FileHashes {
		if _, exists := currentHashes[oldPath]; !exists {
			changes = append(changes, fmt.Sprintf("DELETED: %s", oldPath))
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
				dm.logger.Error(fmt.Sprintf("Fehler beim Lesen der Quelldatei %s: %v", source, err))
				continue
			}
			
			err = os.WriteFile(backupPath, input, 0644)
			if err != nil {
				dm.logger.Error(fmt.Sprintf("Fehler beim Erstellen des Backups %s: %v", backupPath, err))
				continue
			}
			
			dm.logger.Info(fmt.Sprintf("Backup erstellt: %s", backupName))
		}
	}
	
	return timestamp
}

func (dm *DatabaseMaintainer) CleanupOldBackups() {
	cutoff := time.Now().AddDate(0, 0, -dm.retentionDays)
	deleted := 0
	
	for _, dbName := range []string{"docs.db", "tree.db"} {
		pattern := filepath.Join(BACKUP_DIR, fmt.Sprintf("*_%s.bak", dbName))
		matches, _ := filepath.Glob(pattern)
		
		for _, backup := range matches {
			// Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
			filename := filepath.Base(backup)
			parts := strings.Split(filename, "_")
			if len(parts) < 2 {
				dm.logger.Warn(fmt.Sprintf("Konnte Backup-Datum nicht parsen: %s", filename))
				continue
			}
			
			dateStr := parts[0]
			timeStr := strings.Split(parts[1], ".")[0]
			
			backupTime, err := time.Parse("2006-01-02_15-04", fmt.Sprintf("%s_%s", dateStr, timeStr))
			if err != nil {
				dm.logger.Warn(fmt.Sprintf("Konnte Backup-Datum nicht parsen: %s", filename))
				continue
			}
			
			if backupTime.Before(cutoff) {
				os.Remove(backup)
				deleted++
				dm.logger.Info(fmt.Sprintf("Altes Backup gelöscht: %s", filepath.Base(backup)))
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
	if treeOutput != nil {
		dm.UpdateTreeFile(treeOutput)
		now := time.Now()
		state.LastTreeUpdate = &now
	}
	
	// 2. tree.db aktualisieren (intern v2)
	dm.logger.Info("Aktualisiere tree.db v2...")
	dm.UpdateTreeDbV2()
	
	// 3. Änderungen prüfen
	dm.logger.Info("Prüfe auf Dokumentations-Änderungen...")
	changes, currentHashes := dm.CheckForChanges(state)
	
	if len(changes) > 0 {
		dm.logger.Info(fmt.Sprintf("%d Änderungen gefunden:", len(changes)))
		for i, change := range changes {
			if i >= 10 {
				dm.logger.Info(fmt.Sprintf("  ... und %d weitere", len(changes)-10))
				break
			}
			dm.logger.Info(fmt.Sprintf("  - %s", change))
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
	doBackup := true
	if state.LastBackup != nil {
		doBackup = time.Since(*state.LastBackup) >= time.Hour
	}
	
	if doBackup {
		dm.logger.Info("Erstelle stündliches Backup...")
		dm.CreateBackup()
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
	initDirs()
	maintainer := NewDatabaseMaintainer()
	defer maintainer.logger.Close()
	
	defer func() {
		if r := recover(); r != nil {
			maintainer.logger.Error(fmt.Sprintf("CRITICAL ERROR: %v", r))
			os.Exit(1)
		}
	}()
	
	maintainer.RunCycle()
}
