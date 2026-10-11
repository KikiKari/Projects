#!/usr/bin/env node
// update_docs_db.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:scripts/update_docs_db.py
// Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

/** Scan documentation files and refresh docs.db for the mounted workspace. */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sqlite3 = require('sqlite3').verbose();

const WORKSPACE = '/workspace';
const DB_PATH = path.join(WORKSPACE, 'db', 'docs.db');

function* iterDocs() {
  const walk = function* (dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isSymbolicLink()) {
        continue;
      }
      if (entry.isDirectory()) {
        const rel = path.relative(WORKSPACE, fullPath);
        const parts = rel.split(path.sep);
        if (parts.some(part => ['node_modules', '.git', 'backups'].includes(part))) {
          continue;
        }
        yield* walk(fullPath);
      } else if (entry.isFile() && entry.name.endsWith('.md')) {
        yield fullPath;
      }
    }
  };
  yield* walk(WORKSPACE);
}

function fileHash(filePath) {
  return new Promise((resolve, reject) => {
    const hash = crypto.createHash('md5');
    const stream = fs.createReadStream(filePath, { highWaterMark: 8192 });
    
    stream.on('data', chunk => hash.update(chunk));
    stream.on('end', () => resolve(hash.digest('hex')));
    stream.on('error', reject);
  });
}

function wordCount(filePath) {
  try {
    const text = fs.readFileSync(filePath, { encoding: 'utf-8', flag: 'r' });
    return text.split(/\s+/).filter(word => word.length > 0).length;
  } catch (err) {
    return 0;
  }
}

async function buildRows() {
  const indexed = Date.now() / 1000;
  const rows = [];
  
  for (const mdFile of iterDocs()) {
    const relativePath = path.relative(WORKSPACE, mdFile);
    rows.push({
      path: relativePath,
      content_hash: await fileHash(mdFile),
      last_indexed: indexed,
      word_count: wordCount(mdFile)
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

function updateDatabase(rows) {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(DB_PATH);
    
    db.serialize(() => {
      ensureSchema(db)
        .then(() => {
          return new Promise((res, rej) => {
            db.run('DELETE FROM documents', err => {
              if (err) return rej(err);
              
              const stmt = db.prepare('INSERT INTO documents (path, content_hash, last_indexed, word_count) VALUES (?, ?, ?, ?)');
              rows.forEach(row => {
                stmt.run(row.path, row.content_hash, row.last_indexed, row.word_count);
              });
              stmt.finalize();
              
              db.run('COMMIT', err => {
                if (err) return rej(err);
                res();
              });
            });
          });
        })
        .then(() => {
          db.close();
          resolve();
        })
        .catch(err => {
          db.close();
          reject(err);
        });
    });
  });
}

function exportTable(table) {
  return new Promise((resolve, reject) => {
    const db = new sqlite3.Database(DB_PATH);
    
    db.all(`SELECT * FROM ${table}`, (err, rows) => {
      if (err) {
        db.close();
        return reject(err);
      }
      
      const jsonData = JSON.stringify(rows, null, 2);
      const jsonPath = path.join(WORKSPACE, `db_${table}.json`);
      fs.writeFileSync(jsonPath, jsonData);
      
      const csvPath = path.join(WORKSPACE, `db_${table}.csv`);
      const csvStream = fs.createWriteStream(csvPath);
      
      if (rows.length === 0) {
        csvStream.write('\n');
        csvStream.end();
        db.close();
        return resolve();
      }
      
      const headers = Object.keys(rows[0]);
      csvStream.write(headers.join(',') + '\n');
      
      rows.forEach(row => {
        const values = headers.map(header => `"${String(row[header]).replace(/"/g, '""')}"`);
        csvStream.write(values.join(',') + '\n');
      });
      
      csvStream.end();
      csvStream.on('finish', () => {
        db.close();
        resolve();
      });
    });
  });
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

if (require.main === module) {
  main().catch(console.error);
}
