<?php
// abstraction-provenance: {"artifact_sha256": "6e6293df4fe06e17bddb59cbdace62e991002000e5693701bf995198ee3c8959", "source_sha256": "3ee904e4ee842489bd9bef8522f5a93fc06583e6cb1c3c5243afae19a4e2ed5f", "target_language": "php"}
// db_maintainer.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/db_maintainer.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Database Maintainer Sub-Agent
 * Automated database maintenance with 30min checks, hourly backups (3 days retention),
 * band tree command execution for important/openclaw-tree.txt
 */

$WORKSPACE = "/home/openclaw/.openclaw/workspace";
$DB_DIR = $WORKSPACE . "/db";
$BACKUP_DIR = $DB_DIR . "/backups";
$LOG_DIR = $WORKSPACE . "/logs/db-maintainer";
$IMPORTANT_DIR = $WORKSPACE . "/important";

// Verzeichnisse erstellen
@mkdir($BACKUP_DIR, 0755, true);
@mkdir($LOG_DIR, 0755, true);

class Logger {
    private $log_file;
    
    public function __construct() {
        $today = date('Y-m-d');
        $this->log_file = dirname(__FILE__) . "/logs/db-maintainer/{$today}.log";
        @mkdir(dirname($this->log_file), 0755, true);
    }
    
    public function log($level, $message) {
        $timestamp = date('Y-m-d H:i:s');
        $line = "[{$timestamp}] [{$level}] {$message}\n";
        echo $line;
        file_put_contents($this->log_file, $line, FILE_APPEND | LOCK_EX);
    }
    
    public function info($msg) { $this->log('INFO', $msg); }
    public function warn($msg) { $this->log('WARN', $msg); }
    public function error($msg) { $this->log('ERROR', $msg); }
}

class DatabaseMaintainer {
    private $logger;
    private $state_file;
    private $retention_days;
    
    public function __construct() {
        global $DB_DIR;
        $this->logger = new Logger();
        $this->state_file = $DB_DIR . "/maintainer_state.json";
        $this->retention_days = 3; // 3 Tage Backup-Aufbewahrung
    }
    
    public function loadState() {
        if (file_exists($this->state_file)) {
            $content = file_get_contents($this->state_file);
            return json_decode($content, true);
        }
        return [
            'last_check' => null,
            'last_backup' => null,
            'last_tree_update' => null,
            'file_hashes' => []
        ];
    }
    
    public function saveState($state) {
        file_put_contents($this->state_file, json_encode($state, JSON_PRETTY_PRINT));
    }
    
    public function getFileHash($filepath) {
        if (!file_exists($filepath)) {
            return null;
        }
        return md5_file($filepath);
    }
    
    public function runTreeCommand() {
        global $WORKSPACE;
        try {
            $command = "tree -a -L 8 " . escapeshellarg($WORKSPACE);
            $output = shell_exec("timeout 60 {$command} 2>&1");
            $return_code = 0; // In PHP we can't easily get the return code from shell_exec
            
            if ($output !== null) {
                $this->logger->info("tree -a -L 8 erfolgreich ausgeführt");
                return $output;
            } else {
                $this->logger->error("tree command fehlgeschlagen");
                return null;
            }
        } catch (Exception $e) {
            $this->logger->error("tree command Exception: " . $e->getMessage());
            return null;
        }
    }
    
    public function updateTreeFile($tree_output) {
        global $IMPORTANT_DIR;
        if (!$tree_output) {
            return false;
        }
        
        $tree_file = $IMPORTANT_DIR . "/openclaw-tree.txt";
        
        // Header mit Timestamp
        $header = "# OpenClaw Workspace Tree\n";
        $header .= "# Generiert: " . date('c') . "\n";
        $header .= "# Befehl: tree -a -L 8 " . $GLOBALS['WORKSPACE'] . "\n";
        $header .= "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";
        
        try {
            file_put_contents($tree_file, $header . $tree_output);
            $this->logger->info("openclaw-tree.txt aktualisiert: {$tree_file}");
            return true;
        } catch (Exception $e) {
            $this->logger->error("Fehler beim Schreiben von openclaw-tree.txt: " . $e->getMessage());
            return false;
        }
    }
    
    public function scanDocumentations() {
        global $WORKSPACE;
        $docs = [];
        
        $patterns = ['*.md'];
        foreach ($patterns as $pattern) {
            $files = glob("{$WORKSPACE}/{$pattern}");
            foreach ($files as $md_file) {
                if (is_file($md_file) && !is_link($md_file)) {
                    $relative_path = str_replace($WORKSPACE . '/', '', $md_file);
                    if (strpos($relative_path, 'db/backups') === false && 
                        strpos($relative_path, 'node_modules') === false) {
                        $docs[] = [
                            'path' => $relative_path,
                            'hash' => $this->getFileHash($md_file),
                            'mtime' => filemtime($md_file)
                        ];
                    }
                }
            }
            
            // Rekursive Suche
            $files = glob("{$WORKSPACE}/**/{$pattern}", GLOB_BRACE);
            foreach ($files as $md_file) {
                if (is_file($md_file) && !is_link($md_file)) {
                    $relative_path = str_replace($WORKSPACE . '/', '', $md_file);
                    if (strpos($relative_path, 'db/backups') === false && 
                        strpos($relative_path, 'node_modules') === false) {
                        $docs[] = [
                            'path' => $relative_path,
                            'hash' => $this->getFileHash($md_file),
                            'mtime' => filemtime($md_file)
                        ];
                    }
                }
            }
        }
        
        return $docs;
    }
    
    public function checkForChanges() {
        $state = $this->loadState();
        $current_docs = $this->scanDocumentations();
        
        $changes = [];
        $current_hashes = [];
        
        foreach ($current_docs as $doc) {
            $path = $doc['path'];
            $current_hashes[$path] = $doc['hash'];
            
            if (!isset($state['file_hashes'][$path])) {
                $changes[] = "NEW: {$path}";
            } elseif ($state['file_hashes'][$path] !== $doc['hash']) {
                $changes[] = "CHANGED: {$path}";
            }
        }
        
        // Prüfe auf gelöschte Dateien
        foreach ($state['file_hashes'] as $old_path => $hash) {
            if (!isset($current_hashes[$old_path])) {
                $changes[] = "DELETED: {$old_path}";
            }
        }
        
        return [$changes, $current_hashes];
    }
    
    public function updateDatabases() {
        global $WORKSPACE;
        try {
            $script = $WORKSPACE . '/scripts/update_docs_db.py';
            $command = "timeout 60 python3 " . escapeshellarg($script);
            $output = shell_exec("{$command} 2>&1");
            
            if ($output !== null) {
                $this->logger->info("docs.db aktualisiert");
                return true;
            } else {
                $this->logger->error("DB-Update fehlgeschlagen");
                return false;
            }
        } catch (Exception $e) {
            $this->logger->error("DB-Update Exception: " . $e->getMessage());
            return false;
        }
    }
    
    public function updateTreeDbV2() {
        global $WORKSPACE;
        try {
            $script = $WORKSPACE . '/scripts/tree_indexer_v2.py';
            $command = "timeout 120 python3 " . escapeshellarg($script);
            $output = shell_exec("{$command} 2>&1");
            
            if ($output !== null) {
                $this->logger->info("tree.db v2 aktualisiert");
                return true;
            } else {
                $this->logger->error("Tree-DB v2 fehlgeschlagen");
                return false;
            }
        } catch (Exception $e) {
            $this->logger->error("Tree-DB v2 Exception: " . $e->getMessage());
            return false;
        }
    }
    
    public function createBackup() {
        global $DB_DIR, $BACKUP_DIR;
        $timestamp = date('Y-m-d_H-i');
        
        foreach (['docs.db', 'tree.db'] as $db_name) {
            $source = $DB_DIR . "/{$db_name}";
            if (file_exists($source)) {
                $backup_name = "{$timestamp}_{$db_name}.bak";
                $backup_path = $BACKUP_DIR . "/{$backup_name}";
                if (copy($source, $backup_path)) {
                    $this->logger->info("Backup erstellt: {$backup_name}");
                }
            }
        }
        
        return $timestamp;
    }
    
    public function cleanupOldBackups() {
        global $BACKUP_DIR;
        $cutoff = new DateTime("-{$this->retention_days} days");
        $deleted = 0;
        
        foreach (['docs.db', 'tree.db'] as $db_name) {
            $pattern = $BACKUP_DIR . "/*_{$db_name}.bak";
            $backups = glob($pattern);
            
            foreach ($backups as $backup) {
                // Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
                try {
                    $filename = basename($backup);
                    $parts = explode('_', $filename);
                    $date_str = $parts[0];
                    $time_str = $parts[1];
                    $backup_time = DateTime::createFromFormat('Y-m-d_H-i', "{$date_str}_{$time_str}");
                    
                    if ($backup_time < $cutoff) {
                        unlink($backup);
                        $deleted++;
                        $this->logger->info("Altes Backup gelöscht: " . basename($backup));
                    }
                } catch (Exception $e) {
                    $this->logger->warn("Konnte Backup-Datum nicht parsen: " . basename($backup));
                }
            }
        }
        
        if ($deleted == 0) {
            $this->logger->info("Keine alten Backups zum Löschen");
        } else {
            $this->logger->info("{$deleted} alte Backups gelöscht (< 3 Tage)");
        }
    }
    
    public function runCycle() {
        $this->logger->info(str_repeat("=", 60));
        $this->logger->info("DB MAINTAINER CYCLE START");
        $this->logger->info(str_repeat("=", 60));
        
        $state = $this->loadState();
        
        // 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
        $this->logger->info("Führe tree -a -L 8 aus...");
        $tree_output = $this->runTreeCommand();
        if ($tree_output) {
            $this->updateTreeFile($tree_output);
            $state['last_tree_update'] = date('c');
        }
        
        // 2. tree.db aktualisieren (intern v2)
        $this->logger->info("Aktualisiere tree.db v2...");
        $this->updateTreeDbV2();
        
        // 3. Änderungen prüfen
        $this->logger->info("Prüfe auf Dokumentations-Änderungen...");
        list($changes, $current_hashes) = $this->checkForChanges();
        
        if (!empty($changes)) {
            $this->logger->info(count($changes) . " Änderungen gefunden:");
            $display_count = min(10, count($changes));
            for ($i = 0; $i < $display_count; $i++) {
                $this->logger->info("  - {$changes[$i]}");
            }
            if (count($changes) > 10) {
                $this->logger->info("  ... und " . (count($changes) - 10) . " weitere");
            }
            
            // 4. docs.db aktualisieren
            $this->logger->info("Aktualisiere docs.db...");
            if ($this->updateDatabases()) {
                $state['last_check'] = date('c');
                $state['file_hashes'] = $current_hashes;
            }
        } else {
            $this->logger->info("Keine Dokumentations-Änderungen gefunden");
        }
        
        // 5. Prüfe ob Backup fällig (stündlich)
        $last_backup = isset($state['last_backup']) ? $state['last_backup'] : null;
        
        if ($last_backup) {
            $last_backup_time = new DateTime($last_backup);
            $now = new DateTime();
            $interval = $now->diff($last_backup_time);
            $do_backup = ($interval->h >= 1 || $interval->days > 0);
        } else {
            $do_backup = true;
        }
        
        if ($do_backup) {
            $this->logger->info("Erstelle stündliches Backup...");
            $timestamp = $this->createBackup();
            $state['last_backup'] = date('c');
            
            // 6. Alte Backups aufräumen (3 Tage Retention)
            $this->logger->info("Räume alte Backups auf (3 Tage Retention)...");
            $this->cleanupOldBackups();
        } else {
            $this->logger->info("Backup nicht nötig (letztes < 1h)");
        }
        
        $this->saveState($state);
        
        $this->logger->info(str_repeat("=", 60));
        $this->logger->info("DB MAINTAINER CYCLE END");
        $this->logger->info(str_repeat("=", 60));
    }
}

function main() {
    $maintainer = new DatabaseMaintainer();
    
    try {
        $maintainer->runCycle();
    } catch (Exception $e) {
        $maintainer->logger->error("CRITICAL ERROR: " . $e->getMessage());
        exit(1);
    }
}

main();
