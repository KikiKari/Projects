#!/usr/bin/env node
// update_docs_db.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:scripts/update_docs_db.py
// Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

/**
 * Scannt alle vorhandenen Dokumentationen und aktualisiert docs.db
 */

const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

const WORKSPACE = '/home/openclaw/.openclaw/workspace';
const DB_PATH = path.join(WORKSPACE, 'db', 'docs.db');

function scanDocumentations() {
    /**Scannt alle .md Dateien im Workspace*/
    const docs = [];
    
    // Hauptverzeichnis
    const mainFiles = fs.readdirSync(WORKSPACE)
        .filter(file => file.endsWith('.md'))
        .map(file => path.join(WORKSPACE, file))
        .filter(filePath => fs.statSync(filePath).isFile() && !fs.lstatSync(filePath).isSymbolicLink());
    
    for (const filePath of mainFiles) {
        const fileName = path.basename(filePath);
        docs.push({
            name: fileName,
            path: '/',
            category: 'main',
            description: getDescription(filePath),
            type: 'doc',
            has_symlink: false,
            symlink_path: null,
            last_update: getMtime(filePath)
        });
    }
    
    // WebSearch Verzeichnis
    const websearchDir = path.join(WORKSPACE, 'websearch');
    if (fs.existsSync(websearchDir)) {
        const websearchFiles = fs.readdirSync(websearchDir)
            .filter(file => file.endsWith('.md'))
            .map(file => path.join(websearchDir, file));
        
        for (const filePath of websearchFiles) {
            const fileName = path.basename(filePath);
            docs.push({
                name: fileName,
                path: 'websearch/',
                category: 'websearch',
                description: getDescription(filePath),
                type: fileName.includes('GUIDE') ? 'guide' : 'config',
                has_symlink: true,
                symlink_path: `websearch/${fileName}`,
                last_update: getMtime(filePath)
            });
        }
    }
    
    // MCP Verzeichnis
    const mcpDir = path.join(WORKSPACE, 'mcp');
    if (fs.existsSync(mcpDir)) {
        const mcpFiles = fs.readdirSync(mcpDir)
            .filter(file => file.endsWith('.md'))
            .map(file => path.join(mcpDir, file));
        
        for (const filePath of mcpFiles) {
            const fileName = path.basename(filePath);
            const isSymlink = fs.lstatSync(filePath).isSymbolicLink();
            docs.push({
                name: fileName,
                path: 'mcp/',
                category: 'mcp',
                description: getDescription(filePath),
                type: isSymlink ? 'symlink' : 'guide',
                has_symlink: isSymlink,
                symlink_path: isSymlink ? fs.readlinkSync(filePath) : null,
                last_update: getMtime(filePath)
            });
        }
    }
    
    // Docs-Unterverzeichnisse
    const docsDir = path.join(WORKSPACE, 'docs');
    if (fs.existsSync(docsDir)) {
        const subdirs = fs.readdirSync(docsDir)
            .filter(item => fs.statSync(path.join(docsDir, item)).isDirectory());
        
        for (const subdir of subdirs) {
            const subdirPath = path.join(docsDir, subdir);
            const subdirFiles = fs.readdirSync(subdirPath)
                .filter(file => file.endsWith('.md'))
                .map(file => path.join(subdirPath, file));
            
            for (const filePath of subdirFiles) {
                const fileName = path.basename(filePath);
                docs.push({
                    name: fileName,
                    path: `docs/${subdir}/`,
                    category: subdir,
                    description: getDescription(filePath),
                    type: 'doc',
                    has_symlink: false,
                    symlink_path: null,
                    last_update: getMtime(filePath)
                });
            }
        }
    }
    
    // Cluster, Memory, Reports, Skills
    const categories = ['cluster', 'memory', 'reports', 'skills'];
    for (const category of categories) {
        const catDir = path.join(WORKSPACE, category);
        if (fs.existsSync(catDir)) {
            const catFiles = fs.readdirSync(catDir)
                .filter(file => file.endsWith('.md'))
                .map(file => path.join(catDir, file));
            
            for (const filePath of catFiles) {
                const fileName = path.basename(filePath);
                docs.push({
                    name: fileName,
                    path: `${category}/`,
                    category: category,
                    description: getDescription(filePath),
                    type: 'doc',
                    has_symlink: false,
                    symlink_path: null,
                    last_update: getMtime(filePath)
                });
            }
        }
    }
    
    return docs;
}

function getDescription(filePath) {
    /**Extrahiert erste Zeile als Beschreibung*/
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        const firstLine = content.split('\n')[0].trim();
        if (firstLine.startsWith('#')) {
            return firstLine.replace(/^#+\s*/, '');
        }
        return firstLine.length > 50 ? firstLine.substring(0, 50) + '...' : firstLine;
    } catch (error) {
        return 'Dokumentation';
    }
}

function getMtime(filePath) {
    /**Gibt letzte Änderung zurück*/
    try {
        const stats = fs.statSync(filePath);
        const date = new Date(stats.mtime);
        return date.toISOString().split('T')[0];
    } catch (error) {
        return '2026-04-18';
    }
}

function updateDatabase(docs) {
    /**Aktualisiert docs.db mit allen gefundenen Dokumenten*/
    const db = new sqlite3.Database(DB_PATH);
    
    return new Promise((resolve, reject) => {
        db.serialize(() => {
            // Lösche alte Einträge (außer config)
            db.run("DELETE FROM documents WHERE category != 'config'", (err) => {
                if (err) {
                    db.close();
                    return reject(err);
                }
                
                let inserted = 0;
                const stmt = db.prepare(`
                    INSERT INTO documents 
                    (name, path, category, description, type, has_symlink, symlink_path, last_update)
                    VALUES (?,?,?,?,?,?,?,?)
                `);
                
                docs.forEach(doc => {
                    stmt.run(
                        doc.name, doc.path, doc.category,
                        doc.description, doc.type, doc.has_symlink ? 1 : 0,
                        doc.symlink_path, doc.last_update
                    );
                    inserted++;
                });
                
                stmt.finalize();
                db.close();
                resolve(inserted);
            });
        });
    });
}

async function exportAll() {
    /**Erstellt alle Exporte*/
    const db = new sqlite3.Database(DB_PATH);
    
    return new Promise((resolve, reject) => {
        db.serialize(() => {
            const tables = ['documents', 'skills', 'symlinks'];
            
            let completed = 0;
            tables.forEach(table => {
                db.all(`SELECT * FROM ${table}`, (err, rows) => {
                    if (err) {
                        db.close();
                        return reject(err);
                    }
                    
                    // JSON Export
                    const jsonPath = path.join(WORKSPACE, `db_${table}.json`);
                    fs.writeFileSync(jsonPath, JSON.stringify(rows, null, 2));
                    console.log(`✅ ${jsonPath}`);
                    
                    // CSV Export
                    if (rows.length > 0) {
                        const headers = Object.keys(rows[0]);
                        const csvContent = [
                            headers.join(','),
                            ...rows.map(row => 
                                headers.map(header => `"${String(row[header]).replace(/"/g, '""')}"`).join(',')
                            )
                        ].join('\n');
                        
                        const csvPath = path.join(WORKSPACE, `db_${table}.csv`);
                        fs.writeFileSync(csvPath, csvContent);
                        console.log(`✅ ${csvPath}`);
                    }
                    
                    completed++;
                    if (completed === tables.length) {
                        db.close();
                        resolve();
                    }
                });
            });
        });
    });
}

async function main() {
    console.log("=" .repeat(60));
    console.log("DOCS.DB UPDATER");
    console.log("=" .repeat(60));
    
    console.log("\n--- Scanne Dokumentationen ---");
    const docs = scanDocumentations();
    console.log(`Gefunden: ${docs.length} Dokumente`);
    
    console.log("\n--- Aktualisiere docs.db ---");
    try {
        const inserted = await updateDatabase(docs);
        console.log(`✅ ${inserted} Dokumente in docs.db aktualisiert`);
        
        console.log("\n--- Erstelle Exporte ---");
        await exportAll();
        
        console.log("\n" + "=" .repeat(60));
        console.log("DOCS.DB AKTUALISIERT");
        console.log("=" .repeat(60));
    } catch (error) {
        console.error("Fehler beim Aktualisieren der Datenbank:", error);
    }
}

main();
