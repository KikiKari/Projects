#!/usr/bin/env node
// sync_bulk.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/sync_bulk.py
// auch in: OpenClaw@gateway2:skills/sync-utils/scripts/sync_bulk.py
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

/**
 * Bulk Sync - Synchronisiert alle Skills
 */

const fs = require('fs');
const path = require('path');

// Import sync functions
const {
  syncToGit,
  syncToClawhub,
  log,
  validateSkill
} = require('/home/openclaw/.openclaw/workspace/scripts/sync_clawhub_git.js');

const CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills";
const GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills";

function getMaxMtime(dirPath, excludePattern = null) {
  let maxMtime = 0;
  
  function walkDir(currentPath) {
    const entries = fs.readdirSync(currentPath, { withFileTypes: true });
    
    for (const entry of entries) {
      const fullPath = path.join(currentPath, entry.name);
      
      if (excludePattern && excludePattern.test(fullPath)) {
        continue;
      }
      
      if (entry.isDirectory()) {
        walkDir(fullPath);
      } else if (entry.isFile()) {
        const stat = fs.statSync(fullPath);
        if (stat.mtimeMs > maxMtime) {
          maxMtime = stat.mtimeMs;
        }
      }
    }
  }
  
  walkDir(dirPath);
  return maxMtime;
}

function syncAllSkills(dryRun = true) {
  // Alle Skills finden
  const allSkills = new Set();
  
  if (fs.existsSync(CLAWHUB_DIR)) {
    const clawhubDirs = fs.readdirSync(CLAWHUB_DIR, { withFileTypes: true })
      .filter(d => d.isDirectory() && !d.name.startsWith('.'))
      .map(d => d.name);
    clawhubDirs.forEach(d => allSkills.add(d));
  }
  
  if (fs.existsSync(GIT_DIR)) {
    const gitDirs = fs.readdirSync(GIT_DIR, { withFileTypes: true })
      .filter(d => d.isDirectory() && !d.name.startsWith('.'))
      .map(d => d.name);
    gitDirs.forEach(d => allSkills.add(d));
  }
  
  log(`Bulk Sync: ${allSkills.size} Skills gefunden`);
  
  const results = {
    "synced": [],
    "skipped": [],
    "failed": []
  };
  
  [...allSkills].sort().forEach(skill => {
    const clawhubPath = path.join(CLAWHUB_DIR, skill);
    const gitPath = path.join(GIT_DIR, skill);
    
    try {
      // Nur in ClawHub → zu Git
      if (fs.existsSync(clawhubPath) && !fs.existsSync(gitPath)) {
        if (validateSkill(clawhubPath)) {
          log(`Syncing ${skill} to Git...`);
          if (syncToGit(skill, dryRun)) {
            results.synced.push(`${skill} → Git`);
          } else {
            results.failed.push(skill);
          }
        } else {
          results.skipped.push(`${skill} (validation failed)`);
        }
      }
      
      // Nur in Git → zu ClawHub
      else if (fs.existsSync(gitPath) && !fs.existsSync(clawhubPath)) {
        if (validateSkill(gitPath)) {
          log(`Syncing ${skill} to ClawHub...`);
          if (syncToClawhub(skill, dryRun)) {
            results.synced.push(`${skill} → ClawHub`);
          } else {
            results.failed.push(skill);
          }
        } else {
          results.skipped.push(`${skill} (validation failed)`);
        }
      }
      
      // In beiden - prüfe ob Update nötig
      else if (fs.existsSync(clawhubPath) && fs.existsSync(gitPath)) {
        // Vereinfachte Prüfung
        const clawhubMtime = getMaxMtime(clawhubPath);
        const gitMtime = getMaxMtime(gitPath, /\.git/);
        
        if (Math.abs(clawhubMtime - gitMtime) > 60000) {
          if (clawhubMtime > gitMtime) {
            log(`Updating ${skill} in Git...`);
            if (syncToGit(skill, dryRun)) {
              results.synced.push(`${skill} → Git (update)`);
            } else {
              results.failed.push(skill);
            }
          } else {
            log(`Updating ${skill} in ClawHub...`);
            if (syncToClawhub(skill, dryRun)) {
              results.synced.push(`${skill} → ClawHub (update)`);
            } else {
              results.failed.push(skill);
            }
          }
        } else {
          results.skipped.push(`${skill} (already synced)`);
        }
      }
    } catch (e) {
      log(`Error processing ${skill}: ${e}`, "ERROR");
      results.failed.push(skill);
    }
  });
  
  // Zusammenfassung
  console.log("\n" + "=".repeat(60));
  console.log(`Bulk Sync ${dryRun ? 'DRY-RUN' : 'EXECUTED'} - Zusammenfassung`);
  console.log("=".repeat(60));
  console.log(`✅ Synchronisiert: ${results.synced.length}`);
  results.synced.forEach(item => console.log(`   - ${item}`));
  console.log(`\n⏭️  Übersprungen: ${results.skipped.length}`);
  if (results.skipped.length <= 10) {
    results.skipped.forEach(item => console.log(`   - ${item}`));
  } else {
    console.log(`   - ${results.skipped.length} Skills (bereits synchron oder Validierung fehlgeschlagen)`);
  }
  console.log(`\n❌ Fehlgeschlagen: ${results.failed.length}`);
  results.failed.forEach(item => console.log(`   - ${item}`));
  console.log("=".repeat(60));
}

function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const execute = args.includes('--execute');
  
  if (!dryRun && !execute) {
    console.log("Bitte --dry-run oder --execute angeben");
    process.exit(1);
  }
  
  syncAllSkills(dryRun);
}

main();
