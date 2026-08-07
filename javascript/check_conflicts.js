#!/usr/bin/env node
// check_conflicts.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
// auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
// Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

/**
 * Check Conflicts - Erkennt Sync-Konflikte
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Import sync functions
const SYNC_UTILS_DIR = '/home/openclaw/.openclaw/workspace/scripts';
const syncModulePath = path.join(SYNC_UTILS_DIR, 'sync_clawhub_git.js');

// Prüfe ob sync_clawhub_git.js existiert und lade die Funktion
let getFileHash;
try {
  const syncModule = require(syncModulePath);
  getFileHash = syncModule.getFileHash;
} catch (error) {
  console.error('Fehler beim Laden von sync_clawhub_git.js:', error.message);
  process.exit(1);
}

const CLAWHUB_DIR = '/home/openclaw/.openclaw/workspace/skills';
const GIT_DIR = '/home/openclaw/.openclaw/workspace/git/skills';

/**
 * Liest alle Dateien eines Verzeichnisses rekursiv ein
 * @param {string} dir - Das zu durchsuchende Verzeichnis
 * @param {string} baseDir - Das Basisverzeichnis für relative Pfade
 * @returns {Object} Ein Objekt mit relativen Pfaden als Schlüssel und Dateipfaden als Werte
 */
function readFilesRecursively(dir, baseDir) {
  const files = {};
  
  function walk(currentDir) {
    const items = fs.readdirSync(currentDir, { withFileTypes: true });
    
    for (const item of items) {
      const fullPath = path.join(currentDir, item.name);
      
      // Überspringe .git Verzeichnisse
      if (item.name === '.git') continue;
      
      if (item.isDirectory()) {
        walk(fullPath);
      } else {
        const relativePath = path.relative(baseDir, fullPath);
        files[relativePath] = fullPath;
      }
    }
  }
  
  if (fs.existsSync(dir)) {
    walk(dir);
  }
  
  return files;
}

/**
 * Prüft auf Konflikte zwischen ClawHub und Git
 */
function checkConflicts() {
  const conflicts = [];
  
  // Alle Skills die in beiden Orten existieren
  let commonSkills = [];
  
  if (fs.existsSync(CLAWHUB_DIR) && fs.existsSync(GIT_DIR)) {
    const clawhubSkills = fs.readdirSync(CLAWHUB_DIR, { withFileTypes: true })
      .filter(dirent => dirent.isDirectory())
      .map(dirent => dirent.name);
      
    const gitSkills = fs.readdirSync(GIT_DIR, { withFileTypes: true })
      .filter(dirent => dirent.isDirectory())
      .map(dirent => dirent.name);
    
    commonSkills = clawhubSkills.filter(skill => gitSkills.includes(skill));
  }
  
  console.log(`Prüfe ${commonSkills.length} Skills auf Konflikte...\n`);
  
  for (const skill of commonSkills.sort()) {
    const clawhubPath = path.join(CLAWHUB_DIR, skill);
    const gitPath = path.join(GIT_DIR, skill);
    
    // Alle Dateien vergleichen
    const skillConflicts = [];
    
    // ClawHub Dateien
    const clawhubFiles = readFilesRecursively(clawhubPath, clawhubPath);
    
    // Git Dateien
    const gitFiles = readFilesRecursively(gitPath, gitPath);
    
    // Gemeinsame Dateien finden
    const commonFiles = Object.keys(clawhubFiles).filter(file => 
      Object.keys(gitFiles).includes(file)
    );
    
    // Vergleiche gemeinsame Dateien
    for (const relPath of commonFiles) {
      const clawhubFile = clawhubFiles[relPath];
      const gitFile = gitFiles[relPath];
      
      if (getFileHash(clawhubFile) !== getFileHash(gitFile)) {
        const clawhubStats = fs.statSync(clawhubFile);
        const gitStats = fs.statSync(gitFile);
        
        const clawhubMtime = new Date(clawhubStats.mtime);
        const gitMtime = new Date(gitStats.mtime);
        
        skillConflicts.push({
          file: relPath,
          clawhubModified: clawhubMtime.toISOString().slice(0, 19).replace('T', ' '),
          gitModified: gitMtime.toISOString().slice(0, 19).replace('T', ' '),
          newer: clawhubMtime > gitMtime ? "clawhub" : "git"
        });
      }
    }
    
    if (skillConflicts.length > 0) {
      conflicts.push({
        skill: skill,
        conflicts: skillConflicts
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
        console.log(`     ClawHub: ${fileConflict.clawhubModified}`);
        console.log(`     Git:     ${fileConflict.gitModified}`);
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

/**
 * Hauptfunktion
 */
function main() {
  checkConflicts();
}

main();
