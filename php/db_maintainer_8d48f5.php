<?php
// abstraction-provenance: {"artifact_sha256": "30c6bb52d59f8161b7682b7f3e69a8a6339a0c5a97a5cc0cf40738990494f132", "source_sha256": "8d48f51942bb1c171bbd41e0696beb0722cb4b94d6596233f54b32928b645086", "target_language": "php"}
// db_maintainer.py — portiert nach php
// Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Database Maintainer Sub-Agent
 * Automated database maintenance with 30min checks, hourly backups (3 days retention),
 * band tree command execution for important/openclaw-tree.txt
 */

class Path {
    private $path;
    
    public function __construct($path) {
        $this->path = $path;
    }
    
    public static function resolve($path) {
        return new Path(realpath($path));
    }
    
    public function parents($levels = 1) {
        $parts = explode(DIRECTORY_SEPARATOR, $this->path);
        $newParts = array_slice($parts, 0, -$levels);
        return new Path(implode(DIRECTORY_SEPARATOR, $newParts));
    }
    
    public function __toString() {
        return $this->path;
    }
    
    public function exists() {
        return file_exists($this->path);
    }
    
    public function mkdir($parents = true, $exist_ok = true) {
        if (!file_exists($this->path)) {
            mkdir($this->path, 0755, $parents);
        }
    }
    
    public function glob($pattern) {
        $results = [];
        $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($this->path));
        foreach ($iterator as $file) {
            if ($file->isFile() && fnmatch($pattern, $file->getFilename())) {
                $results[] = $file->getPathname();
            }
        }
        return $results;
    }
}

$WORKSPACE = getenv('OPENCLAW_WORKSPACE') ? new Path(getenv('OPENCLAW_WORKSPACE')) : Path::resolve(__DIR__)->parents(1);
$DB_DIR = $WORKSPACE;
$BACKUP_DIR = new Path($WORKSPACE . DIRECTORY_SEPARATOR . 'db' . DIRECTORY_SEPARATOR . 'backups');
$LOG_DIR = new Path($WORKSPACE . DIRECTORY_SEPARATOR . 'logs' . DIRECTORY_SEPARATOR . 'db-maintainer');
$IMPORTANT_DIR = new Path($WORKSPACE . DIRECTORY_SEPARATOR . 'important');

// Verzeichnisse erstellen
$BACKUP_DIR->mkdir(true, true);
$LOG_DIR->mkdir(true, true);
$IMPORTANT_DIR->mkdir(true, true);

class Logger {
    private $log_file;
    
    public function __construct() {
        $today = date('Y-m-d');
        global $LOG_DIR;
        $this->log_file = $LOG_DIR . DIRECTORY_SEPARATOR . $today . '.log';
    }
    
    public function log($level, $message) {
        $timestamp = date('Y-m-d H:i:s');
        $line = "[{$timestamp}] [{$level}] {$message}" . PHP_EOL;
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
        $this->logger = new Logger();
        global $DB_DIR;
        $this->state_file = $DB_DIR . DIRECTORY_SEPARATOR . 'maintainer_state.json';
        $this->retention_days = 3;
    }
    
    public function load_state() {
        if (file_exists($this->state_file)) {
            return json_decode(file_get_contents($this->state_file), true);
        }
        return [
            'last_check' => null,
            'last_backup' => null,
            'last_tree_update' => null,
            'file_hashes' => []
        ];
    }
    
    public function save_state($state) {
        file_put_contents($this->state_file, json_encode($state, JSON_PRETTY_PRINT));
    }
    
    public function get_file_hash($filepath) {
        try {
            return md5_file($filepath);
        } catch (Exception $e) {
            return null;
        }
    }
    
    private function _python_tree_fallback($max_depth = 8) {
        global $WORKSPACE;
        $lines = [(string)$WORKSPACE];
        
        $walk = function($dirpath, $prefix, $depth) use (&$lines, &$walk, $max_depth) {
            if ($depth > $max_depth) return;
            try {
                $entries = scandir($dirpath);
                sort($entries);
                $filtered_entries = [];
                foreach ($entries as $entry) {
                    if ($entry !== '.' && $entry !== '..') {
                        $filtered_entries[] = $entry;
                    }
                }
                $entries = $filtered_entries;
            } catch (Exception $e) {
                return;
            }
            
            foreach ($entries as $i => $entry) {
                $fullPath = $dirpath . DIRECTORY_SEPARATOR . $entry;
                $isLast = ($i === count($entries) - 1);
                $connector = $isLast ? '└── ' : '├── ';
                $lines[] = $prefix . $connector . $entry;
                
                if (is_dir($fullPath) && !is_link($fullPath)) {
                    $extension = $isLast ? '    ' : '│   ';
                    $walk($fullPath, $prefix . $extension, $depth + 1);
                }
            }
        };
        
        $walk((string)$WORKSPACE, '', 1);
        return implode("\n", $lines) . "\n";
    }
    
    public function run_tree_command() {
        global $WORKSPACE;
        try {
            $command = 'tree -a -L 8 ' . escapeshellarg((string)$WORKSPACE);
            $descriptorspec = [
                0 => ["pipe", "r"],
                1 => ["pipe", "w"],
                2 => ["pipe", "w"]
            ];
            
            $process = proc_open($command, $descriptorspec, $pipes);
            
            if (is_resource($process)) {
                fclose($pipes[0]);
                $stdout = stream_get_contents($pipes[1]);
                fclose($pipes[1]);
                $stderr = stream_get_contents($pipes[2]);
                fclose($pipes[2]);
                
                $return_value = proc_close($process);
                
                if ($return_value === 0) {
                    $this->logger->info("tree -a -L 8 erfolgreich ausgeführt");
                    return $stdout;
                } else {
                    $this->logger->warn("tree command fehlgeschlagen: " . trim($stderr) . " – nutze PHP-Fallback");
                    return $this->_python_tree_fallback();
                }
            }
        } catch (Exception $e) {
            $this->logger->warn("tree-Binary nicht installiert – nutze PHP-Fallback");
            return $this->_python_tree_fallback();
        } catch (Exception $e) {
            $this->logger->error("tree command Exception: " . $e->getMessage());
            return null;
        }
    }
    
    public function update_tree_file($tree_output) {
        if (!$tree_output) {
            return false;
        }
        
        global $IMPORTANT_DIR;
        $tree_file = $IMPORTANT_DIR . DIRECTORY_SEPARATOR . "openclaw-tree.txt";
        
        // Header mit Timestamp
        $header = "# OpenClaw Workspace Tree\n" .
                  "# Generiert: " . date('c') . "\n" .
                  "# Befehl: tree -a -L 8 " . (string)$GLOBALS['WORKSPACE'] . "\n" .
                  "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";
        
        try {
            file_put_contents($tree_file, $header . $tree_output);
            $this->logger->info("openclaw-tree.txt aktualisiert: " . $tree_file);
            return true;
        } catch (Exception $e) {
            $this->logger->error("Fehler beim Schreiben von openclaw-tree.txt: " . $e->getMessage());
            return false;
        }
    }
    
    public function scan_documentations() {
        global $WORKSPACE;
        $docs = [];
        
        $patterns = ['*.md'];
        foreach ($patterns as $pattern) {
            $files = $WORKSPACE->glob($pattern);
            foreach ($files as $file) {
                if (is_file($file) && !is_link($file)) {
                    $relativePath = str_replace((string)$WORKSPACE . DIRECTORY_SEPARATOR, '', $file);
                    if (strpos($relativePath, 'db' . DIRECTORY_SEPARATOR . 'backups') === false &&
                        strpos($relativePath, 'node_modules') === false) {
                        $docs[] = [
                            'path' => $relativePath,
                            'hash' => $this->get_file_hash($file),
                            'mtime' => filemtime($file)
                        ];
                    }
                }
            }
        }
        
        return $docs;
    }
    
    public function check_for_changes() {
        $state = $this->load_state();
        $current_docs = $this->scan_documentations();
        
        $changes = [];
        $current_hashes = [];
        
        foreach ($current_docs as $doc) {
            $path = $doc['path'];
            $current_hashes[$path] = $doc['hash'];
            
            if (!isset($state['file_hashes'][$path])) {
                $changes[] = "NEW: " . $path;
            } elseif ($state['file_hashes'][$path] !== $doc['hash']) {
                $changes[] = "CHANGED: " . $path;
            }
        }
        
        // Prüfe auf gelöschte Dateien
        foreach ($state['file_hashes'] as $old_path => $hash) {
            if (!isset($current_hashes[$old_path])) {
                $changes[] = "DELETED: " . $old_path;
            }
        }
        
        return [$changes, $current_hashes];
    }
    
    public function update_databases() {
        global $WORKSPACE;
        try {
            // Update docs.db
            $script = (string)$WORKSPACE . DIRECTORY_SEPARATOR . 'scripts' . DIRECTORY_SEPARATOR . 'update_docs_db.py';
            $command = 'python3 ' . escapeshellarg($script);
            $output = shell_exec($command . ' 2>&1');
            
            if ($output === null || strpos($output, 'Error') !== false) {
                $this->logger->error("DB-Update fehlgeschlagen: " . $output);
                return false;
            } else {
                $this->logger->info("docs.db aktualisiert");
                return true;
            }
        } catch (Exception $e) {
            $this->logger->error("DB-Update Exception: " . $e->getMessage());
            return false;
        }
    }
    
    public function update_tree_db_v2() {
        global $WORKSPACE;
        try {
            $script = (string)$WORKSPACE . DIRECTORY_SEPARATOR . 'scripts' . DIRECTORY_SEPARATOR . 'tree_indexer_v2.py';
            $command = 'python3 ' . escapeshellarg($script);
            $output = shell_exec($command . ' 2>&1');
            
            if ($output === null || strpos($output, 'Error') !== false) {
                $this->logger->error("Tree-DB v2 fehlgeschlagen: " . $output);
                return false;
            } else {
                $this->logger->info("tree.db v2 aktualisiert");
                return true;
            }
        } catch (Exception $e) {
            $this->logger->error("Tree-DB v2 Exception: " . $e->getMessage());
            return false;
        }
    }
    
    public function create_backup() {
        $timestamp = date('Y-m-d_H-i');
        global $DB_DIR, $BACKUP_DIR;
        
        foreach (['docs.db', 'tree.db'] as $db_name) {
            $source = $DB_DIR . DIRECTORY_SEPARATOR . $db_name;
            if (file_exists($source)) {
                $backup_name = "{$timestamp}_{$db_name}.bak";
                $backup_path = $BACKUP_DIR . DIRECTORY_SEPARATOR . $backup_name;
                copy($source, $backup_path);
                $this->logger->info("Backup erstellt: " . $backup_name);
            }
        }
        
        return $timestamp;
    }
    
    public function cleanup_old_backups() {
        global $BACKUP_DIR;
        $cutoff = new DateTime("-{$this->retention_days} days");
        $deleted = 0;
        
        foreach (['docs.db', 'tree.db'] as $db_name) {
            $pattern = $BACKUP_DIR . DIRECTORY_SEPARATOR . "*_{$db_name}.bak";
            $backups = glob($pattern);
            
            foreach ($backups as $backup) {
                // Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
                try {
                    $filename = basename($backup);
                    $parts = explode('_', $filename);
                    $date_str = $parts[0];
                    $time_str = $parts[1];
                    $backup_time = DateTime::createFromFormat('Y-m-d_H-i', $date_str . '_' . $time_str);
                    
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
    
    public function run_cycle() {
        $this->logger->info(str_repeat("=", 60));
        $this->logger->info("DB MAINTAINER CYCLE START");
        $this->logger->info(str_repeat("=", 60));
        
        $state = $this->load_state();
        
        // 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
        $this->logger->info("Führe tree -a -L 8 aus...");
        $tree_output = $this->run_tree_command();
        if ($tree_output) {
            $this->update_tree_file($tree_output);
            $state['last_tree_update'] = date('c');
        }
        
        // 2. tree.db aktualisieren (intern v2)
        $this->logger->info("Aktualisiere tree.db v2...");
        $this->update_tree_db_v2();
        
        // 3. Änderungen prüfen
        $this->logger->info("Prüfe auf Dokumentations-Änderungen...");
        list($changes, $current_hashes) = $this->check_for_changes();
        
        if (!empty($changes)) {
            $this->logger->info(count($changes) . " Änderungen gefunden:");
            $display_count = min(10, count($changes));
            for ($i = 0; $i < $display_count; $i++) {
                $this->logger->info("  - " . $changes[$i]);
            }
            if (count($changes) > 10) {
                $this->logger->info("  ... und " . (count($changes) - 10) . " weitere");
            }
            
            // 4. docs.db aktualisieren
            $this->logger->info("Aktualisiere docs.db...");
            if ($this->update_databases()) {
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
            $timestamp = $this->create_backup();
            $state['last_backup'] = date('c');
            
            // 6. Alte Backups aufräumen (3 Tage Retention)
            $this->logger->info("Räume alte Backups auf (3 Tage Retention)...");
            $this->cleanup_old_backups();
        } else {
            $this->logger->info("Backup nicht nötig (letztes < 1h)");
        }
        
        $this->save_state($state);
        
        $this->logger->info(str_repeat("=", 60));
        $this->logger->info("DB MAINTAINER CYCLE END");
        $this->logger->info(str_repeat("=", 60));
    }
}

function main() {
    $maintainer = new DatabaseMaintainer();
    
    try {
        $maintainer->run_cycle();
    } catch (Exception $e) {
        $maintainer->logger->error("CRITICAL ERROR: " . $e->getMessage());
        exit(1);
    }
}

main();
?>
