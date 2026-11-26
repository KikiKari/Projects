#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "d1686b093c8bdfee86c818734436e9a8a5786b4e29eb7bef20b537a67fba6b0d", "source_sha256": "8d48f51942bb1c171bbd41e0696beb0722cb4b94d6596233f54b32928b645086", "target_language": "javascript"}
// db_maintainer.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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
        this.logFile = path.join(LOG_DIR, `${today}.log`);
    }
    
    log(level, message) {
        const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19);
        const line = `[${timestamp}] [${level}] ${message}`;
        console.log(line);
        fs.appendFileSync(this.logFile, line + '\n');
    }
    
    info(msg) { this.log('INFO', msg); }
    warn(msg) { this.log('WARN', msg); }
    error(msg) { this.log('ERROR', msg); }
}

class DatabaseMaintainer {
    constructor() {
        this.logger = new Logger();
        this.stateFile = path.join(DB_DIR, "maintainer_state.json");
        this.retentionDays = 3; // 3 Tage Backup-Aufbewahrung
    }
    
    loadState() {
        /** Lädt letzten Check-Zustand */
        if (fs.existsSync(this.stateFile)) {
            const data = fs.readFileSync(this.stateFile, 'utf8');
            return JSON.parse(data);
        }
        return {'last_check': null, 'last_backup': null, 'last_tree_update': null, 'file_hashes': {}};
    }
    
    saveState(state) {
        /** Speichert aktuellen Zustand */
        fs.writeFileSync(this.stateFile, JSON.stringify(state, null, 2));
    }
    
    getFileHash(filepath) {
        /** Berechnet MD5-Hash einer Datei */
        try {
            const fileBuffer = fs.readFileSync(filepath);
            return crypto.createHash('md5').update(fileBuffer).digest('hex');
        } catch {
            return null;
        }
    }
    
    _pythonTreeFallback(maxDepth = 8) {
        /** Reiner Python-Fallback, falls das 'tree'-Binary fehlt (z.B. Sandbox). */
        const root = WORKSPACE;
        const lines = [root];
        
        const walk = (dirpath, prefix, depth) => {
            if (depth > maxDepth) {
                return;
            }
            try {
                const entries = fs.readdirSync(dirpath, { withFileTypes: true })
                    .sort((a, b) => {
                        if (a.isDirectory() === b.isDirectory()) {
                            return a.name.localeCompare(b.name);
                        }
                        return a.isDirectory() ? -1 : 1;
                    });
            } catch (error) {
                return;
            }
            
            entries.forEach((entry, i) => {
                const fullPath = path.join(dirpath, entry.name);
                const isLast = i === entries.length - 1;
                const connector = isLast ? '└── ' : '├── ';
                lines.push(prefix + connector + entry.name);
                
                if (entry.isDirectory() && !fs.lstatSync(fullPath).isSymbolicLink()) {
                    const extension = isLast ? '    ' : '│   ';
                    walk(fullPath, prefix + extension, depth + 1);
                }
            });
        };
        
        walk(root, '', 1);
        return lines.join('\n') + '\n';
    }
    
    runTreeCommand() {
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
                return this._pythonTreeFallback();
            }
        } catch (error) {
            if (error.code === 'ENOENT') {
                this.logger.warn("tree-Binary nicht installiert – nutze Python-Fallback");
                return this._pythonTreeFallback();
            } else {
                this.logger.error(`tree command Exception: ${error.message}`);
                return null;
            }
        }
    }
    
    updateTreeFile(treeOutput) {
        /** Schreibt tree-output in important/openclaw-tree.txt */
        if (!treeOutput) {
            return false;
        }
        
        const treeFile = path.join(IMPORTANT_DIR, "openclaw-tree.txt");
        
        // Header mit Timestamp
        const header = `# OpenClaw Workspace Tree
# Generiert: ${new Date().toISOString()}
# Befehl: tree -a -L 8 ${WORKSPACE}
# Diese Datei wird automatisch von db-maintainer aktualisiert

`;
        
        try {
            fs.writeFileSync(treeFile, header + treeOutput);
            this.logger.info(`openclaw-tree.txt aktualisiert: ${treeFile}`);
            return true;
        } catch (error) {
            this.logger.error(`Fehler beim Schreiben von openclaw-tree.txt: ${error.message}`);
            return false;
        }
    }
    
    scanDocumentations() {
        /** Scannt alle .md Dateien auf Änderungen */
        const docs = [];
        const glob = require('glob');
        
        // Simple implementation of glob-like search
        const findMdFiles = (dir) => {
            const results = [];
            const list = fs.readdirSync(dir);
            
            list.forEach(file => {
                const filePath = path.join(dir, file);
                const stat = fs.statSync(filePath);
                
                if (stat && stat.isDirectory()) {
                    // Skip node_modules and backup directories
                    if (!filePath.includes('node_modules') && !filePath.includes('db/backups')) {
                        results.push(...findMdFiles(filePath));
                    }
                } else if (file.endsWith('.md')) {
                    results.push(filePath);
                }
            });
            
            return results;
        };
        
        const mdFiles = findMdFiles(WORKSPACE);
        
        mdFiles.forEach(mdFile => {
            if (!fs.lstatSync(mdFile).isSymbolicLink()) {
                if (!mdFile.includes('db/backups') && !mdFile.includes('node_modules')) {
                    const relativePath = path.relative(WORKSPACE, mdFile);
                    docs.push({
                        'path': relativePath,
                        'hash': this.getFileHash(mdFile),
                        'mtime': fs.statSync(mdFile).mtimeMs
                    });
                }
            }
        });
        
        return docs;
    }
    
    checkForChanges() {
        /** Prüft auf Änderungen seit letztem Lauf */
        const state = this.loadState();
        const currentDocs = this.scanDocumentations();
        
        const changes = [];
        const currentHashes = {};
        
        currentDocs.forEach(doc => {
            const docPath = doc.path;
            currentHashes[docPath] = doc.hash;
            
            if (!state.file_hashes[docPath]) {
                changes.push(`NEW: ${docPath}`);
            } else if (state.file_hashes[docPath] !== doc.hash) {
                changes.push(`CHANGED: ${docPath}`);
            }
        });
        
        // Prüfe auf gelöschte Dateien
        Object.keys(state.file_hashes).forEach(oldPath => {
            if (!currentHashes[oldPath]) {
                changes.push(`DELETED: ${oldPath}`);
            }
        });
        
        return [changes, currentHashes];
    }
    
    updateDatabases() {
        /** Führt DB-Update-Scripts aus */
        try {
            // Update docs.db
            const scriptPath = path.join(WORKSPACE, 'scripts', 'update_docs_db.py');
            const result = spawnSync('python3', [scriptPath], {
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
        } catch (error) {
            this.logger.error(`DB-Update Exception: ${error.message}`);
            return false;
        }
    }
    
    updateTreeDbV2() {
        /** Führt tree_indexer_v2.py aus */
        try {
            const scriptPath = path.join(WORKSPACE, 'scripts', 'tree_indexer_v2.py');
            const result = spawnSync('python3', [scriptPath], {
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
        } catch (error) {
            this.logger.error(`Tree-DB v2 Exception: ${error.message}`);
            return false;
        }
    }
    
    createBackup() {
        /** Erstellt Backup beider Datenbanken */
        const timestamp = new Date().toISOString().replace(/[:]/g, '-').slice(0, 16);
        
        ['docs.db', 'tree.db'].forEach(dbName => {
            const source = path.join(DB_DIR, dbName);
            if (fs.existsSync(source)) {
                const backupName = `${timestamp}_${dbName}.bak`;
                const backupPath = path.join(BACKUP_DIR, backupName);
                fs.copyFileSync(source, backupPath);
                this.logger.info(`Backup erstellt: ${backupName}`);
            }
        });
        
        return timestamp;
    }
    
    cleanupOldBackups() {
        /** Löscht Backups älter als 3 Tage */
        const cutoff = new Date(Date.now() - this.retentionDays * 24 * 60 * 60 * 1000);
        let deleted = 0;
        
        ['docs.db', 'tree.db'].forEach(dbName => {
            const backups = fs.readdirSync(BACKUP_DIR)
                .filter(file => file.endsWith(`_${dbName}.bak`))
                .map(file => path.join(BACKUP_DIR, file));
            
            backups.forEach(backup => {
                // Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
                try {
                    const fileName = path.basename(backup);
                    const dateStr = fileName.split('_')[0];
                    const timeStr = fileName.split('_')[1];
                    const backupTime = new Date(`${dateStr}T${timeStr.replace('-', ':')}`);
                    
                    if (backupTime < cutoff) {
                        fs.unlinkSync(backup);
                        deleted++;
                        this.logger.info(`Altes Backup gelöscht: ${fileName}`);
                    }
                } catch (error) {
                    this.logger.warn(`Konnte Backup-Datum nicht parsen: ${path.basename(backup)}`);
                }
            });
        });
        
        if (deleted === 0) {
            this.logger.info("Keine alten Backups zum Löschen");
        } else {
            this.logger.info(`${deleted} alte Backups gelöscht (< 3 Tage)`);
        }
    }
    
    runCycle() {
        /** Ein kompletter Wartungszyklus */
        this.logger.info("=".repeat(60));
        this.logger.info("DB MAINTAINER CYCLE START");
        this.logger.info("=".repeat(60));
        
        const state = this.loadState();
        
        // 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
        this.logger.info("Führe tree -a -L 8 aus...");
        const treeOutput = this.runTreeCommand();
        if (treeOutput) {
            this.updateTreeFile(treeOutput);
            state.last_tree_update = new Date().toISOString();
        }
        
        // 2. tree.db aktualisieren (intern v2)
        this.logger.info("Aktualisiere tree.db v2...");
        this.updateTreeDbV2();
        
        // 3. Änderungen prüfen
        this.logger.info("Prüfe auf Dokumentations-Änderungen...");
        const [changes, currentHashes] = this.checkForChanges();
        
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
            if (this.updateDatabases()) {
                state.last_check = new Date().toISOString();
                state.file_hashes = currentHashes;
            }
        } else {
            this.logger.info("Keine Dokumentations-Änderungen gefunden");
        }
        
        // 5. Prüfe ob Backup fällig (stündlich)
        const lastBackup = state.last_backup;
        let doBackup;
        
        if (lastBackup) {
            const lastBackupTime = new Date(lastBackup);
            doBackup = (Date.now() - lastBackupTime.getTime()) >= 60 * 60 * 1000;
        } else {
            doBackup = true;
        }
        
        if (doBackup) {
            this.logger.info("Erstelle stündliches Backup...");
            const timestamp = this.createBackup();
            state.last_backup = new Date().toISOString();
            
            // 6. Alte Backups aufräumen (3 Tage Retention)
            this.logger.info("Räume alte Backups auf (3 Tage Retention)...");
            this.cleanupOldBackups();
        } else {
            this.logger.info("Backup nicht nötig (letztes < 1h)");
        }
        
        this.saveState(state);
        
        this.logger.info("=".repeat(60));
        this.logger.info("DB MAINTAINER CYCLE END");
        this.logger.info("=".repeat(60));
    }
}

function main() {
    /** Hauptfunktion */
    const maintainer = new DatabaseMaintainer();
    
    try {
        maintainer.runCycle();
    } catch (error) {
        maintainer.logger.error(`CRITICAL ERROR: ${error.message}`);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}
