#!/usr/bin/env node
// tree_indexer.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:scripts/tree_indexer.py
// auch in: OpenClaw@gateway2:scripts/tree_indexer.py
// Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

/**
 * Tree Indexer - Scannt Verzeichnisbäume und speichert in tree.db
 */

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const sqlite3 = require('sqlite3').verbose();

const WORKSPACE = path.join("/home/openclaw/.openclaw/workspace");
const DB_DIR = path.join(WORKSPACE, "db");

class TreeIndexer {
    constructor() {
        this.dbPath = path.join(DB_DIR, "tree.db");
        this.db = null;
    }

    connect() {
        if (!this.db) {
            this.db = new sqlite3.Database(this.dbPath);
        }
        return this.db;
    }

    async runTree(rootPath, maxDepth) {
        /** Führt tree -a -L {depth} aus und parst Ausgabe */
        return new Promise((resolve, reject) => {
            const child = spawn('tree', ['-a', '-L', String(maxDepth), rootPath], { timeout: 30000 });
            let stdout = '';
            let stderr = '';

            child.stdout.on('data', data => stdout += data.toString());
            child.stderr.on('data', data => stderr += data.toString());

            child.on('close', code => {
                if (code === 0) {
                    resolve(stdout);
                } else {
                    console.error(`❌ Fehler bei tree ${rootPath}: ${stderr}`);
                    resolve(null);
                }
            });

            child.on('error', err => {
                console.error(`❌ Fehler beim Starten von tree für ${rootPath}: ${err.message}`);
                resolve(null);
            });
        });
    }

    parseTreeOutput(treeOutput, rootPath) {
        /** Parst tree-Ausgabe und extrahiert Einträge */
        const entries = [];
        const lines = treeOutput.trim().split('\n');

        // Regex für tree-Zeilen
        // Beispiel: "├── .bash_history" oder "│   ├── bin"
        const pattern = /^[│ ]*[├└]── (.+)$/;

        for (const line of lines) {
            const match = line.match(pattern);
            if (match) {
                let name = match[1].trim();
                // Tiefe bestimmen durch Anzahl der │ und Leerzeichen
                const depth = (line.match(/│/g) || []).length + Math.floor((line.match(/ {4}/g) || []).length);

                // Typ bestimmen
                let entryType;
                if (name.endsWith('/')) {
                    entryType = 'directory';
                    name = name.slice(0, -1);
                } else if (name.includes(' -> ')) {
                    entryType = 'symlink';
                    name = name.split(' -> ')[0];
                } else {
                    entryType = 'file';
                }

                entries.push({
                    name: name,
                    type: entryType,
                    depth: depth,
                    line: line
                });
            }
        }

        return entries;
    }

    saveToDb(rootPath, maxDepth, entries) {
        /** Speichert Einträge in tree.db */
        const db = this.connect();
        return new Promise((resolve, reject) => {
            db.serialize(() => {
                // Scan-Metadaten
                const totalFiles = entries.filter(e => e.type === 'file').length;
                const totalDirs = entries.filter(e => e.type === 'directory').length;
                const totalSymlinks = entries.filter(e => e.type === 'symlink').length;

                const stmt = db.prepare(`
                    INSERT INTO tree_scans 
                    (root_path, max_depth, total_files, total_dirs, total_symlinks)
                    VALUES (?,?,?,?,?)
                `);

                stmt.run(String(rootPath), maxDepth, totalFiles, totalDirs, totalSymlinks, function(err) {
                    if (err) {
                        reject(err);
                        return;
                    }

                    const scanId = this.lastID;
                    stmt.finalize();

                    // Einträge speichern
                    const insertStmt = db.prepare(`
                        INSERT INTO tree_entries 
                        (root_path, relative_path, name, type, depth, parent_path, size)
                        VALUES (?,?,?,?,?,?,0)
                    `);

                    entries.forEach(entry => {
                        insertStmt.run(
                            String(rootPath),
                            entry.name,
                            entry.name,
                            entry.type,
                            entry.depth,
                            String(rootPath)
                        );
                    });

                    insertStmt.finalize();
                    db.run('COMMIT', () => {
                        console.log(`✅ ${entries.length} Einträge gespeichert für ${rootPath}`);
                        resolve(scanId);
                    });
                });
            });
        });
    }

    async indexDirectory(rootPath, maxDepth) {
        /** Komplette Indexierung eines Verzeichnisses */
        console.log(`\n--- Indexiere: ${rootPath} (Depth: ${maxDepth}) ---`);
        const treeOutput = await this.runTree(rootPath, maxDepth);

        if (treeOutput) {
            const entries = this.parseTreeOutput(treeOutput, rootPath);
            if (entries.length > 0) {
                return await this.saveToDb(rootPath, maxDepth, entries);
            }
        }
        return null;
    }

    exportCsv() {
        /** Exportiert alle Tree-Einträge als CSV */
        const db = this.connect();
        return new Promise((resolve, reject) => {
            db.all('SELECT * FROM tree_entries ORDER BY root_path, depth, name', (err, rows) => {
                if (err) {
                    reject(err);
                    return;
                }

                if (!rows || rows.length === 0) {
                    console.log("⚠️ Keine Tree-Daten vorhanden");
                    resolve(null);
                    return;
                }

                const csvPath = path.join(WORKSPACE, "export_tree_all.csv");
                const headers = Object.keys(rows[0]).join(',');
                const content = rows.map(row => Object.values(row).join(',')).join('\n');
                const csvContent = `${headers}\n${content}`;

                fs.writeFile(csvPath, csvContent, err => {
                    if (err) {
                        reject(err);
                        return;
                    }

                    console.log(`✅ Tree CSV exportiert: ${csvPath} (${rows.length} Einträge)`);
                    resolve(csvPath);
                });
            });
        });
    }

    exportByRoot() {
        /** Exportiert getrennt nach root_path */
        const db = this.connect();
        return new Promise((resolve, reject) => {
            db.all('SELECT DISTINCT root_path FROM tree_entries', (err, roots) => {
                if (err) {
                    reject(err);
                    return;
                }

                const exports = [];
                let completed = 0;

                if (!roots || roots.length === 0) {
                    console.log("⚠️ Keine Root-Pfade gefunden");
                    resolve(exports);
                    return;
                }

                roots.forEach(({ root_path }) => {
                    const safeName = root_path.replace(/\//g, '_').replace(/\./g, '');
                    const csvPath = path.join(WORKSPACE, `export_tree${safeName}.csv`);

                    db.all(
                        'SELECT * FROM tree_entries WHERE root_path = ? ORDER BY depth, name',
                        root_path,
                        (err, rows) => {
                            if (err) {
                                console.error(`Fehler beim Abfragen von ${root_path}:`, err);
                                return;
                            }

                            const headers = Object.keys(rows[0] || {}).join(',');
                            const content = rows.map(row => Object.values(row).join(',')).join('\n');
                            const csvContent = `${headers}\n${content}`;

                            fs.writeFile(csvPath, csvContent, err => {
                                if (err) {
                                    console.error(`Fehler beim Schreiben von ${csvPath}:`, err);
                                    return;
                                }

                                exports.push([root_path, csvPath, rows.length]);
                                console.log(`✅ Export ${root_path}: ${csvPath} (${rows.length} Einträge)`);

                                completed++;
                                if (completed === roots.length) {
                                    resolve(exports);
                                }
                            });
                        }
                    );
                });
            });
        });
    }
}

async function main() {
    console.log("=".repeat(60));
    console.log("TREE INDEXER");
    console.log("=".repeat(60));

    const indexer = new TreeIndexer();

    // 1. /home/openclaw/ mit depth 3
    await indexer.indexDirectory('/home/openclaw/', 3);

    // 2. Workspace mit depth 6
    await indexer.indexDirectory('/home/openclaw/.openclaw/workspace/', 6);

    // Exporte erstellen
    console.log("\n--- Exporte ---");
    try {
        await indexer.exportCsv();
        await indexer.exportByRoot();
    } catch (error) {
        console.error("Fehler beim Export:", error);
    }

    console.log("\n" + "=".repeat(60));
    console.log("TREE INDEXIERUNG ABGESCHLOSSEN");
    console.log("=".repeat(60));
}

main().catch(console.error);
