#!/usr/bin/env node
// db_maintainer.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

/**
 * Database Maintainer Sub-Agent
 * Automated database maintenance with 30min checks, hourly backups (3 days retention),
 * band tree command execution for important/openclaw-tree.txt
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { spawnSync } = require('child_process');

const WORKSPACE = process.env.OPENCLAW_WORKSPACE || path.resolve(__dirname, '..');
const DB_DIR = WORKSPACE;
const BACKUP_DIR = path.join(WORKSPACE, 'db', 'backups');
const LOG_DIR = path.join(WORKSPACE, 'logs', 'db-maintainer');
const IMPORTANT_DIR = path.join(WORKSPACE, 'important');

// Verzeichnisse erstellen
[BACKUP_DIR, LOG_DIR, IMPORTANT_DIR].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

class Logger {
  /** Einfacher Logger mit Datei-Ausgabe */
  
  constructor() {
    const today = new Date().toISOString().split('T')[0];
    this.log_file = path.join(LOG_DIR, `${today}.log`);
  }
  
  log(level, message) {
    const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19);
    const line = `[${timestamp}] [${level}] ${message}`;
    console.log(line);
    fs.appendFileSync(this.log_file, line + '\n');
  }
  
  info(msg) { this.log('INFO', msg); }
  warn(msg) { this.log('WARN', msg); }
  error(msg) { this.log('ERROR', msg); }
}

class DatabaseMaintainer {
  constructor() {
    this.logger = new Logger();
    this.state_file = path.join(DB_DIR, "maintainer_state.json");
    this.retention_days = 3; // 3 Tage Backup-Aufbewahrung
  }
  
  load_state() {
    /** Lädt letzten Check-Zustand */
    if (fs.existsSync(this.state_file)) {
      return JSON.parse(fs.readFileSync(this.state_file, 'utf8'));
    }
    return {'last_check': null, 'last_backup': null, 'last_tree_update': null, 'file_hashes': {}};
  }
  
  save_state(state) {
    /** Speichert aktuellen Zustand */
    fs.writeFileSync(this.state_file, JSON.stringify(state, null, 2));
  }
  
  get_file_hash(filepath) {
    /** Berechnet MD5-Hash einer Datei */
    try {
      const data = fs.readFileSync(filepath);
      return crypto.createHash('md5').update(data).digest('hex');
    } catch {
      return null;
    }
  }
  
  _python_tree_fallback(max_depth = 8) {
    /** Reiner Python-Fallback, falls das 'tree'-Binary fehlt (z.B. Sandbox). */
    const root = WORKSPACE;
    const lines = [root];
    
    const walk = (dirpath, prefix, depth) => {
      if (depth > max_depth) return;
      try {
        const entries = fs.readdirSync(dirpath, { withFileTypes: true })
          .sort((a, b) => {
            if (a.isDirectory() === b.isDirectory()) {
              return a.name.localeCompare(b.name);
            }
            return a.isDirectory() ? -1 : 1;
          });
        
        entries.forEach((entry, i) => {
          const connector = i === entries.length - 1 ? '└── ' : '├── ';
          lines.push(prefix + connector + entry.name);
          if (entry.isDirectory() && !entry.isSymbolicLink()) {
            const extension = i === entries.length - 1 ? '    ' : '│   ';
            walk(path.join(dirpath, entry.name), prefix + extension, depth + 1);
          }
        });
      } catch (err) {
        // Ignore permission errors
      }
    };
    
    walk(root, '', 1);
    return lines.join('\n') + '\n';
  }
  
  run_tree_command() {
    /** Führt tree -a -L 8 auf workspace aus und gibt Ergebnis zurück */
    try {
      const result = spawnSync('tree', ['-a', '-L', '8', WORKSPACE], {
        encoding: 'utf8',
        timeout: 60000
      });
      
      if (result.status === 0) {
        this.logger.info("tree -a -L 8 erfolgreich ausgeführt");
        return result.stdout;
      } else {
        this.logger.warn(`tree command fehlgeschlagen: ${result.stderr.trim()} – nutze Python-Fallback`);
        return this._python_tree_fallback();
      }
    } catch (e) {
      if (e.code === 'ENOENT') {
        this.logger.warn("tree-Binary nicht installiert – nutze Python-Fallback");
        return this._python_tree_fallback();
      } else {
        this.logger.error(`tree command Exception: ${e}`);
        return null;
      }
    }
  }
  
  update_tree_file(tree_output) {
    /** Schreibt tree-output in important/openclaw-tree.txt */
    if (!tree_output) return false;
    
    const tree_file = path.join(IMPORTANT_DIR, "openclaw-tree.txt");
    
    // Header mit Timestamp
    const header = `# OpenClaw Workspace Tree
# Generiert: ${new Date().toISOString()}
# Befehl: tree -a -L 8 ${WORKSPACE}
# Diese Datei wird automatisch von db-maintainer aktualisiert

`;
    
    try {
      fs.writeFileSync(tree_file, header + tree_output);
      this.logger.info(`openclaw-tree.txt aktualisiert: ${tree_file}`);
      return true;
    } catch (e) {
      this.logger.error(`Fehler beim Schreiben von openclaw-tree.txt: ${e}`);
      return false;
    }
  }
  
  scan_documentations() {
    /** Scannt alle .md Dateien auf Änderungen */
    const docs = [];
    
    const walk = (dir) => {
      const entries = fs.readdirSync(dir, { withFileTypes: true });
      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        const relativePath = path.relative(WORKSPACE, fullPath);
        
        // Skip backup and node_modules directories
        if (relativePath.includes('db/backups') || relativePath.includes('node_modules')) {
          continue;
        }
        
        if (entry.isFile() && entry.name.endsWith('.md')) {
          const stat = fs.statSync(fullPath);
          docs.push({
            'path': relativePath,
            'hash': this.get_file_hash(fullPath),
            'mtime': stat.mtimeMs
          });
        } else if (entry.isDirectory()) {
          walk(fullPath);
        }
      }
    };
    
    walk(WORKSPACE);
    return docs;
  }
  
  check_for_changes() {
    /** Prüft auf Änderungen seit letztem Lauf */
    const state = this.load_state();
    const current_docs = this.scan_documentations();
    
    const changes = [];
    const current_hashes = {};
    
    for (const doc of current_docs) {
      const doc_path = doc['path'];
      current_hashes[doc_path] = doc['hash'];
      
      if (!(doc_path in state['file_hashes'])) {
        changes.push(`NEW: ${doc_path}`);
      } else if (state['file_hashes'][doc_path] !== doc['hash']) {
        changes.push(`CHANGED: ${doc_path}`);
      }
    }
    
    // Prüfe auf gelöschte Dateien
    for (const old_path in state['file_hashes']) {
      if (!(old_path in current_hashes)) {
        changes.push(`DELETED: ${old_path}`);
      }
    }
    
    return [changes, current_hashes];
  }
  
  update_databases() {
    /** Führt DB-Update-Scripts aus */
    try {
      // Update docs.db
      const result = spawnSync('python3', [path.join(WORKSPACE, 'scripts', 'update_docs_db.py')], {
        encoding: 'utf8',
        timeout: 60000
      });
      
      if (result.status === 0) {
        this.logger.info("docs.db aktualisiert");
        return true;
      } else {
        this.logger.error(`DB-Update fehlgeschlagen: ${result.stderr}`);
        return false;
      }
    } catch (e) {
      this.logger.error(`DB-Update Exception: ${e}`);
      return false;
    }
  }
  
  update_tree_db_v2() {
    /** Führt tree_indexer_v2.py aus */
    try {
      const result = spawnSync('python3', [path.join(WORKSPACE, 'scripts', 'tree_indexer_v2.py')], {
        encoding: 'utf8',
        timeout: 120000
      });
      
      if (result.status === 0) {
        this.logger.info("tree.db v2 aktualisiert");
        return true;
      } else {
        this.logger.error(`Tree-DB v2 fehlgeschlagen: ${result.stderr}`);
        return false;
      }
    } catch (e) {
      this.logger.error(`Tree-DB v2 Exception: ${e}`);
      return false;
    }
  }
  
  create_backup() {
    /** Erstellt Backup beider Datenbanken */
    const timestamp = new Date().toISOString().replace(/[:]/g, '-').slice(0, 16);
    
    for (const db_name of ['docs.db', 'tree.db']) {
      const source = path.join(DB_DIR, db_name);
      if (fs.existsSync(source)) {
        const backup_name = `${timestamp}_${db_name}.bak`;
        const backup_path = path.join(BACKUP_DIR, backup_name);
        fs.copyFileSync(source, backup_path);
        this.logger.info(`Backup erstellt: ${backup_name}`);
      }
    }
    
    return timestamp;
  }
  
  cleanup_old_backups() {
    /** Löscht Backups älter als 3 Tage */
    const cutoff = new Date(Date.now() - this.retention_days * 24 * 60 * 60 * 1000);
    let deleted = 0;
    
    for (const db_name of ['docs.db', 'tree.db']) {
      const backups = fs.readdirSync(BACKUP_DIR)
        .filter(f => f.endsWith(`_${db_name}.bak`))
        .map(f => path.join(BACKUP_DIR, f));
      
      for (const backup of backups) {
        // Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
        try {
          const filename = path.basename(backup);
          const date_str = filename.split('_')[0];
          const time_str = filename.split('_')[1];
          const backup_time = new Date(`${date_str}T${time_str.replace('-', ':')}`);
          
          if (backup_time < cutoff) {
            fs.unlinkSync(backup);
            deleted++;
            this.logger.info(`Altes Backup gelöscht: ${path.basename(backup)}`);
          }
        } catch (e) {
          this.logger.warn(`Konnte Backup-Datum nicht parsen: ${path.basename(backup)}`);
        }
      }
    }
    
    if (deleted === 0) {
      this.logger.info("Keine alten Backups zum Löschen");
    } else {
      this.logger.info(`${deleted} alte Backups gelöscht (< 3 Tage)`);
    }
  }
  
  run_cycle() {
    /** Ein kompletter Wartungszyklus */
    this.logger.info("=".repeat(60));
    this.logger.info("DB MAINTAINER CYCLE START");
    this.logger.info("=".repeat(60));
    
    const state = this.load_state();
    
    // 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
    this.logger.info("Führe tree -a -L 8 aus...");
    const tree_output = this.run_tree_command();
    if (tree_output) {
      this.update_tree_file(tree_output);
      state['last_tree_update'] = new Date().toISOString();
    }
    
    // 2. tree.db aktualisieren (intern v2)
    this.logger.info("Aktualisiere tree.db v2...");
    this.update_tree_db_v2();
    
    // 3. Änderungen prüfen
    this.logger.info("Prüfe auf Dokumentations-Änderungen...");
    const [changes, current_hashes] = this.check_for_changes();
    
    if (changes.length > 0) {
      this.logger.info(`${changes.length} Änderungen gefunden:`);
      changes.slice(0, 10).forEach(change => {
        this.logger.info(`  - ${change}`);
      });
      if (changes.length > 10) {
        this.logger.info(`  ... und ${changes.length-10} weitere`);
      }
      
      // 4. docs.db aktualisieren
      this.logger.info("Aktualisiere docs.db...");
      if (this.update_databases()) {
        state['last_check'] = new Date().toISOString();
        state['file_hashes'] = current_hashes;
      }
    } else {
      this.logger.info("Keine Dokumentations-Änderungen gefunden");
    }
    
    // 5. Prüfe ob Backup fällig (stündlich)
    const last_backup = state.get('last_backup');
    
    let do_backup;
    if (last_backup) {
      const last_backup_time = new Date(last_backup);
      do_backup = Date.now() - last_backup_time >= 60 * 60 * 1000; // 1 hour
    } else {
      do_backup = true;
    }
    
    if (do_backup) {
      this.logger.info("Erstelle stündliches Backup...");
      const timestamp = this.create_backup();
      state['last_backup'] = new Date().toISOString();
      
      // 6. Alte Backups aufräumen (3 Tage Retention)
      this.logger.info("Räume alte Backups auf (3 Tage Retention)...");
      this.cleanup_old_backups();
    } else {
      this.logger.info("Backup nicht nötig (letztes < 1h)");
    }
    
    this.save_state(state);
    
    this.logger.info("=".repeat(60));
    this.logger.info("DB MAINTAINER CYCLE END");
    this.logger.info("=".repeat(60));
  }
}

function main() {
  /** Hauptfunktion */
  const maintainer = new DatabaseMaintainer();
  
  try {
    maintainer.run_cycle();
  } catch (e) {
    maintainer.logger.error(`CRITICAL ERROR: ${e}`);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}
