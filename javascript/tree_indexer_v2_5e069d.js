#!/usr/bin/env node
// tree_indexer_v2.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:scripts/tree_indexer_v2.py
// Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

/**
 * Tree Indexer v2 - Erweitertes Tracking mit Metadaten
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { spawnSync } = require('child_process');

const WORKSPACE = process.env.OPENCLAW_WORKSPACE || path.resolve(__dirname, '..');
const DB_DIR = WORKSPACE;

class TreeIndexerV2 {
    constructor() {
        this.dbPath = path.join(DB_DIR, 'tree.db');
        this.sqlite3 = null;
        this.db = null;
    }

    async loadSQLite() {
        if (!this.sqlite3) {
            this.sqlite3 = await import('sqlite3');
            this.sqlite3 = this.sqlite3.Database;
        }
        return this.sqlite3;
    }

    async connect() {
        const sqlite3 = await this.loadSQLite();
        return new Promise((resolve, reject) => {
            this.db = new sqlite3(this.dbPath, (err) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(this.db);
                }
            });
        });
    }

    async initSchemaV2() {
        await this.connect();
        return new Promise((resolve, reject) => {
            const schemaSQL = `
                CREATE TABLE IF NOT EXISTS tree_entries_v2 (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    file_id TEXT UNIQUE,
                    root_path TEXT NOT NULL,
                    relative_path TEXT NOT NULL,
                    name TEXT NOT NULL,
                    type TEXT CHECK(type IN ('file', 'directory', 'symlink')),
                    depth INTEGER,
                    parent_path TEXT,
                    
                    size_bytes INTEGER,
                    previous_size_bytes INTEGER,
                    size_change_bytes INTEGER,
                    
                    mtime_timestamp REAL,
                    mtime_iso TEXT,
                    first_seen_timestamp REAL,
                    last_seen_timestamp REAL,
                    
                    change_type TEXT CHECK(change_type IN ('NEW', 'MODIFIED', 'MOVED', 'RENAMED', 'UNCHANGED', 'DELETED')),
                    
                    original_name TEXT,
                    original_path TEXT,
                    previous_path TEXT,
                    
                    content_hash TEXT,
                    
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                
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
                );
                
                CREATE INDEX IF NOT EXISTS idx_file_id ON tree_entries_v2(file_id);
                CREATE INDEX IF NOT EXISTS idx_path ON tree_entries_v2(relative_path);
                CREATE INDEX IF NOT EXISTS idx_mtime ON tree_entries_v2(mtime_timestamp);
                CREATE INDEX IF NOT EXISTS idx_change_type ON tree_entries_v2(change_type);
            `;
            
            this.db.exec(schemaSQL, (err) => {
                if (err) {
                    reject(err);
                } else {
                    console.log("✅ tree.db Schema v2 erstellt/aktualisiert");
                    resolve(this);
                }
            });
        });
    }

    getFileMetadata(fullPath) {
        try {
            const stats = fs.statSync(fullPath);
            return {
                size: stats.size,
                mtime: stats.mtime.getTime() / 1000,
                mtime_iso: stats.mtime.toISOString()
            };
        } catch (error) {
            return { size: 0, mtime: 0, mtime_iso: null };
        }
    }

    generateFileId(relativePath) {
        return crypto.createHash('md5')
            .update(String(relativePath))
            .digest('hex')
            .substring(0, 16);
    }

    scanDirectoryDetailed(rootPath, maxDepth = 8) {
        const entries = [];
        const root = path.resolve(rootPath);
        
        function walkDir(currentPath) {
            const items = fs.readdirSync(currentPath, { withFileTypes: true });
            
            for (const item of items) {
                const fullPath = path.join(currentPath, item.name);
                const relativePath = path.relative(root, fullPath);
                const depth = relativePath.split(path.sep).length;
                
                if (depth > maxDepth) continue;
                
                const fileId = this.generateFileId(relativePath);
                const metadata = this.getFileMetadata(fullPath);
                
                let type;
                if (item.isDirectory()) {
                    type = 'directory';
                } else if (item.isSymbolicLink()) {
                    type = 'symlink';
                } else {
                    type = 'file';
                }
                
                const entry = {
                    file_id: fileId,
                    root_path: root,
                    relative_path: relativePath,
                    name: item.name,
                    type: type,
                    depth: depth,
                    parent_path: path.dirname(relativePath) === '.' ? '' : path.dirname(relativePath),
                    size_bytes: metadata.size,
                    mtime_timestamp: metadata.mtime,
                    mtime_iso: metadata.mtime_iso
                };
                
                entries.push(entry);
                
                if (item.isDirectory()) {
                    walkDir(fullPath);
                }
            }
        }
        
        walkDir.call(this, root);
        return entries;
    }

    async updateDatabase(entries) {
        await this.connect();
        return new Promise((resolve, reject) => {
            this.db.serialize(() => {
                this.db.run("BEGIN TRANSACTION");
                
                // Alle bestehenden Einträge als "potentiell gelöscht" markieren
                this.db.run("UPDATE tree_entries_v2 SET change_type = NULL");
                
                const stats = { new: 0, modified: 0, unchanged: 0, moved: 0 };
                
                let processed = 0;
                const total = entries.length;
                
                entries.forEach((entry) => {
                    this.db.get(
                        "SELECT * FROM tree_entries_v2 WHERE file_id = ?",
                        [entry.file_id],
                        (err, existing) => {
                            if (err) {
                                this.db.run("ROLLBACK");
                                reject(err);
                                return;
                            }
                            
                            const now = new Date();
                            const nowTimestamp = now.getTime() / 1000;
                            
                            if (existing) {
                                const oldMtime = existing.mtime_timestamp || 0;
                                const oldSize = existing.size_bytes || 0;
                                const oldPath = existing.relative_path;
                                
                                const sizeChange = entry.size_bytes - oldSize;
                                
                                let changeType;
                                if (oldPath !== entry.relative_path) {
                                    changeType = 'MOVED';
                                    stats.moved += 1;
                                } else if (oldMtime !== entry.mtime_timestamp || oldSize !== entry.size_bytes) {
                                    changeType = 'MODIFIED';
                                    stats.modified += 1;
                                } else {
                                    changeType = 'UNCHANGED';
                                    stats.unchanged += 1;
                                }
                                
                                this.db.run(`
                                    UPDATE tree_entries_v2 SET
                                        size_bytes = ?,
                                        previous_size_bytes = ?,
                                        size_change_bytes = ?,
                                        mtime_timestamp = ?,
                                        mtime_iso = ?,
                                        last_seen_timestamp = ?,
                                        change_type = ?,
                                        previous_path = ?,
                                        original_path = COALESCE(original_path, ?),
                                        updated_at = CURRENT_TIMESTAMP
                                    WHERE file_id = ?
                                `, [
                                    entry.size_bytes,
                                    oldSize,
                                    sizeChange,
                                    entry.mtime_timestamp,
                                    entry.mtime_iso,
                                    nowTimestamp,
                                    changeType,
                                    changeType === 'MOVED' ? oldPath : null,
                                    changeType === 'MOVED' ? oldPath : null,
                                    entry.file_id
                                ]);
                                
                                if (changeType === 'MODIFIED' || changeType === 'MOVED') {
                                    this.db.run(`
                                        INSERT INTO file_history
                                        (file_id, timestamp, change_type, old_path, new_path, old_size, new_size)
                                        VALUES (?, ?, ?, ?, ?, ?, ?)
                                    `, [
                                        entry.file_id,
                                        nowTimestamp,
                                        changeType,
                                        oldPath,
                                        entry.relative_path,
                                        oldSize,
                                        entry.size_bytes
                                    ]);
                                }
                            } else {
                                stats.new += 1;
                                this.db.run(`
                                    INSERT INTO tree_entries_v2
                                    (file_id, root_path, relative_path, name, type, depth, parent_path,
                                     size_bytes, previous_size_bytes, size_change_bytes,
                                     mtime_timestamp, mtime_iso, first_seen_timestamp, last_seen_timestamp,
                                     change_type, content_hash)
                                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                                `, [
                                    entry.file_id,
                                    entry.root_path,
                                    entry.relative_path,
                                    entry.name,
                                    entry.type,
                                    entry.depth,
                                    entry.parent_path,
                                    entry.size_bytes,
                                    entry.size_bytes,
                                    0,
                                    entry.mtime_timestamp,
                                    entry.mtime_iso,
                                    nowTimestamp,
                                    nowTimestamp,
                                    'NEW',
                                    null
                                ]);
                            }
                            
                            processed++;
                            if (processed === total) {
                                // Markiere nicht aktualisierte Einträge als DELETED
                                const oneHourAgo = nowTimestamp - 3600;
                                this.db.all(`
                                    SELECT * FROM tree_entries_v2 
                                    WHERE change_type IS NULL OR last_seen_timestamp < ?
                                `, [oneHourAgo], (err, deleted) => {
                                    if (err) {
                                        this.db.run("ROLLBACK");
                                        reject(err);
                                        return;
                                    }
                                    
                                    let deletedProcessed = 0;
                                    if (deleted.length === 0) {
                                        this.db.run("COMMIT");
                                        stats.deleted = 0;
                                        resolve(stats);
                                        return;
                                    }
                                    
                                    stats.deleted = deleted.length;
                                    
                                    deleted.forEach((item) => {
                                        this.db.run(`
                                            UPDATE tree_entries_v2 
                                            SET change_type = 'DELETED', updated_at = CURRENT_TIMESTAMP
                                            WHERE file_id = ?
                                        `, [item.file_id], () => {
                                            deletedProcessed++;
                                            if (deletedProcessed === deleted.length) {
                                                this.db.run("COMMIT");
                                                resolve(stats);
                                            }
                                        });
                                    });
                                });
                            }
                        }
                    );
                });
            });
        });
    }

    async exportChanges(sinceHours = 24) {
        await this.connect();
        return new Promise((resolve, reject) => {
            const since = (new Date().getTime() / 1000) - (sinceHours * 3600);
            
            this.db.all(`
                SELECT * FROM tree_entries_v2 
                WHERE change_type IN ('NEW', 'MODIFIED', 'MOVED', 'DELETED')
                AND last_seen_timestamp > ?
                ORDER BY last_seen_timestamp DESC
            `, [since], (err, changes) => {
                if (err) {
                    reject(err);
                    return;
                }
                
                const exportFile = path.join(WORKSPACE, `tree_changes_last_${sinceHours}h.json`);
                
                fs.writeFile(exportFile, JSON.stringify(changes, null, 2), (err) => {
                    if (err) {
                        reject(err);
                        return;
                    }
                    
                    console.log(`✅ Änderungen exportiert: ${exportFile} (${changes.length} Einträge)`);
                    resolve(exportFile);
                });
            });
        });
    }
}

async function main() {
    console.log("=" + "=".repeat(59));
    console.log("TREE INDEXER v2 - Erweitertes Tracking");
    console.log("=" + "=".repeat(59));
    
    const indexer = new TreeIndexerV2();
    await indexer.initSchemaV2();
    
    console.log("\n--- Scanning Workspace ---");
    const entries = indexer.scanDirectoryDetailed(WORKSPACE, 8);
    console.log(`Gefunden: ${entries.length} Einträge`);
    
    console.log("\n--- Aktualisiere Datenbank ---");
    const stats = await indexer.updateDatabase(entries);
    console.log("Statistiken:");
    console.log(`  NEU:        ${stats.new || 0}`);
    console.log(`  MODIFIED:   ${stats.modified || 0}`);
    console.log(`  MOVED:      ${stats.moved || 0}`);
    console.log(`  UNCHANGED:  ${stats.unchanged || 0}`);
    console.log(`  DELETED:    ${stats.deleted || 0}`);
    
    console.log("\n--- Exportiere Änderungen (24h) ---");
    await indexer.exportChanges(24);
    
    console.log("\n" + "=".repeat(60));
    console.log("TREE INDEXING ABGESCHLOSSEN");
    console.log("=".repeat(60));
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = TreeIndexerV2;
