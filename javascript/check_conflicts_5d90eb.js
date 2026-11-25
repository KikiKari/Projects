#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "7629ff2298f724b826ffd362f7e96685470269f274e1ecbeaf862aa019ee6cba", "source_sha256": "5d90ebcd250a3cb80a0de664d94397af7ec03343d9d9fa64a28a9a11ad880754", "target_language": "javascript"}
// check_conflicts.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
// auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

/**
 * Check Conflicts - Erkennt Sync-Konflikte
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Import sync functions
const SYNC_UTILS_PATH = '/home/openclaw/.openclaw/workspace/scripts';
const SYNC_MODULE_PATH = path.join(SYNC_UTILS_PATH, 'sync_clawhub_git.js');

// Dynamically import the module
let getFileHash;
try {
  const syncModule = require(SYNC_MODULE_PATH);
  getFileHash = syncModule.getFileHash;
} catch (error) {
  console.error(`Fehler beim Laden des Sync-Moduls: ${error.message}`);
  process.exit(1);
}

const CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills";
const GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills";

function getDirectories(source) {
  try {
    return fs.readdirSync(source, { withFileTypes: true })
      .filter(dirent => dirent.isDirectory())
      .map(dirent => dirent.name);
  } catch (error) {
    return [];
  }
}

function getAllFiles(dirPath, relativeTo) {
  let files = {};
  
  function walk(currentPath) {
    try {
      const items = fs.readdirSync(currentPath);
      for (const item of items) {
        const fullPath = path.join(currentPath, item);
        const stat = fs.statSync(fullPath);
        
        // Skip .git directories
        if (item === '.git') continue;
        
        if (stat.isDirectory()) {
          walk(fullPath);
        } else {
          const relPath = path.relative(relativeTo, fullPath);
          files[relPath] = fullPath;
        }
      }
    } catch (error) {
      // Ignore errors
    }
  }
  
  walk(dirPath);
  return files;
}

function formatDateTime(timestamp) {
  const date = new Date(timestamp);
  return date.getFullYear() + '-' + 
         String(date.getMonth() + 1).padStart(2, '0') + '-' + 
         String(date.getDate()).padStart(2, '0') + ' ' +
         String(date.getHours()).padStart(2, '0') + ':' + 
         String(date.getMinutes()).padStart(2, '0') + ':' + 
         String(date.getSeconds()).padStart(2, '0');
}

function checkConflicts() {
  /** Prüft auf Konflikte zwischen ClawHub und Git */
  let conflicts = [];
  
  // Alle Skills die in beiden Orten existieren
  let commonSkills = [];
  
  if (fs.existsSync(CLAWHUB_DIR) && fs.existsSync(GIT_DIR)) {
    const clawhubSkills = new Set(getDirectories(CLAWHUB_DIR));
    const gitSkills = new Set(getDirectories(GIT_DIR));
    
    // Find intersection
    commonSkills = [...clawhubSkills].filter(skill => gitSkills.has(skill));
  }
  
  console.log(`Prüfe ${commonSkills.length} Skills auf Konflikte...\n`);
  
  for (const skill of commonSkills.sort()) {
    const clawhubPath = path.join(CLAWHUB_DIR, skill);
    const gitPath = path.join(GIT_DIR, skill);
    
    // Alle Dateien vergleichen
    let skillConflicts = [];
    
    // ClawHub Dateien
    const clawhubFiles = getAllFiles(clawhubPath, clawhubPath);
    
    // Git Dateien
    const gitFiles = getAllFiles(gitPath, gitPath);
    
    // Vergleiche gemeinsame Dateien
    const clawhubFilePaths = Object.keys(clawhubFiles);
    const gitFilePaths = Object.keys(gitFiles);
    const commonFilePaths = clawhubFilePaths.filter(filePath => gitFilePaths.includes(filePath));
    
    for (const relPath of commonFilePaths) {
      const clawhubFile = clawhubFiles[relPath];
      const gitFile = gitFiles[relPath];
      
      if (getFileHash(clawhubFile) !== getFileHash(gitFile)) {
        const clawhubStat = fs.statSync(clawhubFile);
        const gitStat = fs.statSync(gitFile);
        const clawhubMtime = clawhubStat.mtime.getTime();
        const gitMtime = gitStat.mtime.getTime();
        
        skillConflicts.push({
          "file": relPath,
          "clawhub_modified": formatDateTime(clawhubMtime),
          "git_modified": formatDateTime(gitMtime),
          "newer": clawhubMtime > gitMtime ? "clawhub" : "git"
        });
      }
    }
    
    if (skillConflicts.length > 0) {
      conflicts.push({
        "skill": skill,
        "conflicts": skillConflicts
      });
    }
  }
  
  // Ausgabe
  if (conflicts.length > 0) {
    console.log("⚠️  KONFLIKTE GEFUNDEN:");
    console.log("=".repeat(80));
    
    for (const conflict of conflicts) {
      console.log(`\n📦 Skill: ${conflict.skill}`);
      console.log("-".repeat(40));
      
      for (const fileConflict of conflict.conflicts) {
        console.log(`  📄 ${fileConflict.file}`);
        console.log(`     ClawHub: ${fileConflict.clawhub_modified}`);
        console.log(`     Git:     ${fileConflict.git_modified}`);
        console.log(`     Neuer:   ${fileConflict.newer.toUpperCase()}`);
        console.log();
      }
    }
    
    console.log("=".repeat(80));
    console.log(`Gesamt: ${conflicts.length} Skills mit Konflikten`);
    console.log("\nNutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen.");
  } else {
    console.log("✅ Keine Konflikte gefunden!");
    console.log("Alle gemeinsamen Skills sind synchron.");
  }
}

function main() {
  /** Hauptfunktion */
  checkConflicts();
}

main();
