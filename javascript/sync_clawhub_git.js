#!/usr/bin/env node
// sync_clawhub_git.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:scripts/sync_clawhub_git.py
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

/**
 * Bidirektionale ClawHub ↔ Git Synchronisation
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { program } = require('commander');

// Konfiguration
const CLAWHUB_DIR = path.join('/home/openclaw/.openclaw/workspace/skills');
const GIT_DIR = path.join('/home/openclaw/.openclaw/workspace/git/skills');
const BACKUP_DIR = path.join('/home/openclaw/.openclaw/workspace/backups/sync');
const LOG_FILE = path.join('/home/openclaw/.openclaw/workspace/logs/sync-agent.log');

// Erstelle Verzeichnisse
[CLAWHUB_DIR, GIT_DIR, BACKUP_DIR, path.dirname(LOG_FILE)].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// Logging
function log(message, level = "INFO") {
  const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19);
  const entry = `[${timestamp}] [${level}] ${message}`;
  console.log(entry);
  fs.appendFileSync(LOG_FILE, entry + '\n');
}

// Validierung
function validateSkill(skillDir) {
  /** Prüft Skill-Struktur - SKILL.md required, scripts/ optional */
  const skillMdPath = path.join(skillDir, "SKILL.md");
  if (!fs.existsSync(skillMdPath)) {
    log(`Validation failed: ${path.basename(skillDir)} missing SKILL.md`, "ERROR");
    return false;
  }
  return true;
}

// Backup
function createBackup(source, skillName) {
  /** Erstellt Backup eines Skills */
  const timestamp = new Date().toISOString().replace(/[-:]/g, '').replace('T', '_').slice(0, 15);
  const backupPath = path.join(BACKUP_DIR, `${skillName}_${timestamp}`);
  
  // Backup verzeichnis löschen falls es existiert
  if (fs.existsSync(backupPath)) {
    try {
      fs.rmSync(backupPath, { recursive: true, force: true });
      log(`Removed existing backup: ${backupPath}`);
    } catch (e) {
      log(`Failed to remove existing backup ${backupPath}: ${e.message}`, "ERROR");
      return false;
    }
  }
  
  try {
    copyRecursiveSync(source, backupPath);
    log(`Backup created: ${backupPath}`);
    return true;
  } catch (e) {
    log(`Backup failed: ${e.message}`, "ERROR");
    return false;
  }
}

// Hilfsfunktion für rekursives Kopieren
function copyRecursiveSync(src, dest) {
  const stats = fs.statSync(src);
  if (stats.isDirectory()) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    fs.readdirSync(src).forEach(child => {
      if (child !== '.git') {
        copyRecursiveSync(path.join(src, child), path.join(dest, child));
      }
    });
  } else {
    fs.copyFileSync(src, dest);
  }
}

// Hash-Vergleich
function getFileHash(filePath) {
  /** SHA256-Hash einer Datei */
  const hash = crypto.createHash('sha256');
  const stream = fs.createReadStream(filePath);
  
  return new Promise((resolve, reject) => {
    stream.on('data', chunk => hash.update(chunk));
    stream.on('end', () => resolve(hash.digest('hex')));
    stream.on('error', reject);
  });
}

// Sync Richtung ClawHub → Git
async function syncToGit(skillName, dryRun = true) {
  /** Synchronisiert ClawHub Skill zu Git */
  const source = path.join(CLAWHUB_DIR, skillName);
  const target = path.join(GIT_DIR, skillName);
  
  if (!validateSkill(source)) {
    return false;
  }
  
  // Backup vor Änderungen (nur wenn target existiert)
  if (!dryRun && fs.existsSync(target)) {
    createBackup(target, skillName);
  }
  
  // Änderungen erkennen
  const changes = [];
  
  function walkDir(currentPath, relativeBase) {
    const items = fs.readdirSync(currentPath);
    items.forEach(item => {
      if (item === '.git') return;
      
      const fullPath = path.join(currentPath, item);
      const stat = fs.statSync(fullPath);
      const relPath = path.relative(relativeBase, currentPath);
      const targetItemPath = path.join(target, relPath, item);
      
      if (stat.isDirectory()) {
        walkDir(fullPath, relativeBase);
      } else {
        if (!fs.existsSync(targetItemPath)) {
          changes.push(`ADD ${path.join(relPath, item)}`);
        } else {
          // Für DRY-RUN können wir hier vereinfacht vergleichen
          // In Produktion sollte getFileHash verwendet werden
        }
      }
    });
  }
  
  if (fs.existsSync(source)) {
    walkDir(source, source);
  }
  
  // Für echte Implementierung mit Hash-Vergleich:
  async function collectChangesWithHash(srcBase, tgtBase) {
    const changesList = [];
    
    async function walkWithHash(currentSrc, relBase) {
      const items = fs.readdirSync(currentSrc);
      for (const item of items) {
        if (item === '.git') continue;
        
        const srcPath = path.join(currentSrc, item);
        const stat = fs.statSync(srcPath);
        const relPath = path.relative(relBase, currentSrc);
        const tgtPath = path.join(tgtBase, relPath, item);
        
        if (stat.isDirectory()) {
          await walkWithHash(srcPath, relBase);
        } else {
          if (!fs.existsSync(tgtPath)) {
            changesList.push(`ADD ${path.join(relPath, item)}`);
          } else {
            const srcHash = await getFileHash(srcPath);
            const tgtHash = await getFileHash(tgtPath);
            if (srcHash !== tgtHash) {
              changesList.push(`UPDATE ${path.join(relPath, item)}`);
            }
          }
        }
      }
    }
    
    if (fs.existsSync(srcBase)) {
      await walkWithHash(srcBase, srcBase);
    }
    return changesList;
  }
  
  const actualChanges = await collectChangesWithHash(source, target);
  
  // Dry-Run Report
  if (dryRun) {
    log(`DRY-RUN: ${skillName} - ${actualChanges.length} changes`);
    actualChanges.forEach(change => log(`  ${change}`));
    return true;
  }
  
  // Echte Synchronisation
  log(`SYNC: ${skillName} - Applying ${actualChanges.length} changes`);
  if (fs.existsSync(target)) {
    // Entferne Zielverzeichnis-Inhalt außer .git
    const targetItems = fs.readdirSync(target);
    targetItems.forEach(item => {
      if (item !== '.git') {
        fs.rmSync(path.join(target, item), { recursive: true, force: true });
      }
    });
    copyRecursiveSync(source, target);
  } else {
    copyRecursiveSync(source, target);
  }
  log(`SYNC: ${skillName} - Complete`);
  return true;
}

// Sync Richtung Git → ClawHub
async function syncToClawhub(skillName, dryRun = true) {
  /** Synchronisiert Git Skill zu ClawHub */
  const source = path.join(GIT_DIR, skillName);
  const target = path.join(CLAWHUB_DIR, skillName);
  
  if (!validateSkill(source)) {
    return false;
  }
  
  // Backup vor Änderungen (nur wenn target existiert)
  if (!dryRun && fs.existsSync(target)) {
    createBackup(target, skillName);
  }

  // Änderungen erkennen (gleiche Logik wie oben)
  async function collectChangesWithHash(srcBase, tgtBase) {
    const changesList = [];
    
    async function walkWithHash(currentSrc, relBase) {
      const items = fs.readdirSync(currentSrc);
      for (const item of items) {
        if (item === '.git') continue;
        
        const srcPath = path.join(currentSrc, item);
        const stat = fs.statSync(srcPath);
        const relPath = path.relative(relBase, currentSrc);
        const tgtPath = path.join(tgtBase, relPath, item);
        
        if (stat.isDirectory()) {
          await walkWithHash(srcPath, relBase);
        } else {
          if (!fs.existsSync(tgtPath)) {
            changesList.push(`ADD ${path.join(relPath, item)}`);
          } else {
            const srcHash = await getFileHash(srcPath);
            const tgtHash = await getFileHash(tgtPath);
            if (srcHash !== tgtHash) {
              changesList.push(`UPDATE ${path.join(relPath, item)}`);
            }
          }
        }
      }
    }
    
    if (fs.existsSync(srcBase)) {
      await walkWithHash(srcBase, srcBase);
    }
    return changesList;
  }
  
  const actualChanges = await collectChangesWithHash(source, target);
  
  // Dry-Run Report
  if (dryRun) {
    log(`DRY-RUN: ${skillName} - ${actualChanges.length} changes`);
    actualChanges.forEach(change => log(`  ${change}`));
    return true;
  }

  // Echte Synchronisation
  log(`SYNC: ${skillName} - Applying ${actualChanges.length} changes`);
  if (fs.existsSync(target)) {
    // Entferne Zielverzeichnis-Inhalt
    const targetItems = fs.readdirSync(target);
    targetItems.forEach(item => {
      fs.rmSync(path.join(target, item), { recursive: true, force: true });
    });
    copyRecursiveSync(source, target);
  } else {
    copyRecursiveSync(source, target);
  }
  log(`SYNC: ${skillName} - Complete`);
  return true;
}

// Hauptfunktion
async function main() {
  program
    .description('Bidirektionaler Sync ClawHub ↔ Git')
    .requiredOption('--skill <name>', 'Skill name')
    .option('--direction <dir>', 'Sync direction', 'to-git') // Standardwert hinzugefügt
    .option('--dry-run', 'Nur Änderungen anzeigen')
    .option('--force', 'Ohne Backup')
    .action(async (options) => {
      const { skill, direction, dryRun, force } = options;
      
      if (!['to-git', 'to-clawhub'].includes(direction)) {
        console.error('Error: --direction must be either "to-git" or "to-clawhub"');
        process.exit(1);
      }
      
      log(`Starting sync: ${skill} (${direction})`);
      
      let success;
      if (direction === 'to-git') {
        success = await syncToGit(skill, dryRun);
      } else {
        success = await syncToClawhub(skill, dryRun);
      }
      
      if (!success) {
        log("Sync failed", "ERROR");
        process.exit(1);
      }
      
      log("Sync completed");
    });
    
  program.parse();
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
