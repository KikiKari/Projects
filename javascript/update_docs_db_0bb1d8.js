#!/usr/bin/env node
// update_docs_db.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:scripts/update_docs_db.py
// Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

import { createHash } from 'crypto';
import { readFile, writeFile, stat, readdir } from 'fs/promises';
import { join, relative, dirname } from 'path';
import { fileURLToPath } from 'url';
import { Database } from 'sqlite3';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const WORKSPACE = process.env.OPENCLAW_WORKSPACE || join(__dirname, '..');
const DB_PATH = join(WORKSPACE, 'docs.db');

async function isFile(path) {
  try {
    const stats = await stat(path);
    return stats.isFile();
  } catch {
    return false;
  }
}

async function isSymlink(path) {
  try {
    const stats = await stat(path);
    return stats.isSymbolicLink();
  } catch {
    return false;
  }
}

async function* iterDocs() {
  async function* walk(dir) {
    let entries;
    try {
      entries = await readdir(dir, { withFileTypes: true });
    } catch {
      return;
    }
    
    for (const entry of entries) {
      const fullPath = join(dir, entry.name);
      const relPath = relative(WORKSPACE, fullPath);
      const parts = relPath.split(/[/\\]/);
      
      if (parts.some(part => ['node_modules', '.git', 'backups'].includes(part))) {
        continue;
      }
      
      if (entry.isDirectory()) {
        yield* walk(fullPath);
      } else if (entry.name.endsWith('.md')) {
        if (await isFile(fullPath) && !(await isSymlink(fullPath))) {
          yield fullPath;
        }
      }
    }
  }
  
  yield* walk(WORKSPACE);
}

async function fileHash(path) {
  const hash = createHash('md5');
  const buffer = await readFile(path);
  hash.update(buffer);
  return hash.digest('hex');
}

async function wordCount(path) {
  try {
    const text = await readFile(path, 'utf8');
    return text.split(/\s+/).filter(word => word.length > 0).length;
  } catch {
    return 0;
  }
}

async function buildRows() {
  const indexed = Date.now() / 1000;
  const rows = [];
  
  for await (const mdFile of iterDocs()) {
    rows.push({
      path: relative(WORKSPACE, mdFile).replace(/\\/g, '/'),
      content_hash: await fileHash(mdFile),
      last_indexed: indexed,
      word_count: await wordCount(mdFile),
    });
  }
  
  return rows;
}

function ensureSchema(db) {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      db.run(`
        CREATE TABLE IF NOT EXISTS documents (
          path TEXT PRIMARY KEY,
          content_hash TEXT,
          last_indexed REAL,
          word_count INTEGER
        )
      `, err => {
        if (err) return reject(err);
        
        db.run(`
          CREATE TABLE IF NOT EXISTS tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT,
            tag TEXT
          )
        `, err => {
          if (err) return reject(err);
          resolve();
        });
      });
    });
  });
}

async function updateDatabase(rows) {
  const db = new Database(DB_PATH);
  
  try {
    await ensureSchema(db);
    
    return new Promise((resolve, reject) => {
      db.serialize(() => {
        db.run('DELETE FROM documents', err => {
          if (err) return reject(err);
          
          const stmt = db.prepare('INSERT INTO documents (path, content_hash, last_indexed, word_count) VALUES (?, ?, ?, ?)');
          
          rows.forEach(row => {
            stmt.run(row.path, row.content_hash, row.last_indexed, row.word_count, err => {
              if (err) reject(err);
            });
          });
          
          stmt.finalize(err => {
            if (err) return reject(err);
            
            db.run('COMMIT', err => {
              if (err) return reject(err);
              resolve();
            });
          });
        });
      });
    });
  } finally {
    db.close();
  }
}

async function exportTable(table) {
  const db = new Database(DB_PATH);
  
  try {
    const rows = await new Promise((resolve, reject) => {
      db.all(`SELECT * FROM ${table}`, (err, rows) => {
        if (err) return reject(err);
        resolve(rows);
      });
    });
    
    const data = rows.map(row => ({...row}));
    const jsonPath = join(WORKSPACE, `db_${table}.json`);
    const csvPath = join(WORKSPACE, `db_${table}.csv`);
    
    await writeFile(jsonPath, JSON.stringify(data, null, 2));
    
    let csvContent = '';
    if (rows.length > 0) {
      const headers = Object.keys(rows[0]);
      csvContent += headers.join(',') + '\n';
      for (const row of rows) {
        csvContent += headers.map(header => 
          `"${String(row[header]).replace(/"/g, '""')}"`
        ).join(',') + '\n';
      }
    }
    
    await writeFile(csvPath, csvContent);
  } finally {
    db.close();
  }
}

async function main() {
  console.log('=' .repeat(60));
  console.log('DOCS.DB UPDATER');
  console.log('=' .repeat(60));
  
  const rows = await buildRows();
  console.log(`Gefunden: ${rows.length} Dokumente`);
  
  await updateDatabase(rows);
  console.log(`✅ ${rows.length} Dokumente in docs.db aktualisiert`);
  
  await exportTable('documents');
  await exportTable('tags');
  console.log('✅ Exporte aktualisiert');
  
  console.log('\n' + '=' .repeat(60));
  console.log('DOCS.DB AKTUALISIERT');
  console.log('=' .repeat(60));
}

main().catch(console.error);
