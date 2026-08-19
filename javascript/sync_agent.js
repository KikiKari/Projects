#!/usr/bin/env node
// sync_agent.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/clawhub-git-sync-agent/scripts/sync_agent.py
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

/**
 * Permanenter ClawHub ↔ Git Sync Agent
 * Multi-Node fähig, stündliche Ausführung
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const crypto = require('crypto');

// Import sync functions
const {
  syncToGit,
  syncToClawhub,
  log,
  validateSkill,
  getFileHash
} = require('./sync_clawhub_git.js');

const CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills";
const GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills";
const STATE_FILE = "/home/openclaw/.openclaw/workspace/db/sync_state.json";

// Root directory for backups
const BACKUP_ROOT = "/home/openclaw/.openclaw/workspace/backups/sync_agent";

function loadState() {
  /**Lädt den Sync-State*/
  if (fs.existsSync(STATE_FILE)) {
    const data = fs.readFileSync(STATE_FILE, 'utf8');
    return JSON.parse(data);
  }
  return { sync_history: [], pending: [] };
}

function saveState(state) {
  /**Speichert den Sync-State*/
  const dir = path.dirname(STATE_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function getAllSkills() {
  /**Findet nur valide Skill-Verzeichnisse in beiden Verzeichnissen.*/
  const clawhubSkills = new Set();
  const gitSkills = new Set();

  if (fs.existsSync(CLAWHUB_DIR)) {
    const dirs = fs.readdirSync(CLAWHUB_DIR);
    for (const item of dirs) {
      const fullPath = path.join(CLAWHUB_DIR, item);
      const stat = fs.statSync(fullPath);
      if (stat.isDirectory() && !item.startsWith('.') && !item.startsWith('_')) {
        if (fs.existsSync(path.join(fullPath, "SKILL.md"))) {
          clawhubSkills.add(item);
        }
      }
    }
  }

  if (fs.existsSync(GIT_DIR)) {
    const dirs = fs.readdirSync(GIT_DIR);
    for (const item of dirs) {
      const fullPath = path.join(GIT_DIR, item);
      const stat = fs.statSync(fullPath);
      if (stat.isDirectory() && !item.startsWith('.') && !item.startsWith('_')) {
        if (fs.existsSync(path.join(fullPath, "SKILL.md"))) {
          gitSkills.add(item);
        }
      }
    }
  }

  const allSkills = new Set([...clawhubSkills, ...gitSkills]);
  return Array.from(allSkills);
}

function initGitRepo(skillPath, skillName) {
  /**Initialisiert Git-Repo wenn nötig*/
  const gitDir = path.join(skillPath, ".git");
  if (!fs.existsSync(gitDir)) {
    process.chdir(skillPath);
    execSync("git init", { stdio: 'ignore' });
    execSync("git add .", { stdio: 'ignore' });
    execSync(`git commit -m "Initial commit: ${skillName} skill"`, { stdio: 'ignore' });
    log(`Git initialized for ${skillName}`);
  }
}

function backupSkillDir(skillPath, skillName) {
  /**Creates a timestamped tar.gz backup of a skill directory.*/
  if (!fs.existsSync(skillPath)) {
    return;
  }
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').replace('T', '').slice(0, -1);
  const backupDir = path.join(BACKUP_ROOT, timestamp);
  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }
  const archiveName = `${skillName}_${timestamp}`;
  const archivePath = path.join(backupDir, archiveName);
  
  // Create tar.gz using system tar command
  execSync(`tar -czf "${archivePath}.tar.gz" -C "${skillPath}" .`, { stdio: 'ignore' });
  log(`Backup created for ${skillName} at ${archivePath}.tar.gz`);
}

async function syncSkillBidirectional(skillName, dryRun = false) {
  /**Bidirektionale Synchronisation eines Skills*/
  const clawhubPath = path.join(CLAWHUB_DIR, skillName);
  const gitPath = path.join(GIT_DIR, skillName);

  // Fall 1: Nur in ClawHub → zu Git
  if (fs.existsSync(clawhubPath) && !fs.existsSync(gitPath)) {
    log(`NEW in ClawHub: ${skillName} → syncing to Git`);
    if (!dryRun) {
      backupSkillDir(clawhubPath, `${skillName}_clawhub`);
    }
    if (await syncToGit(skillName, dryRun)) {
      if (!dryRun) {
        initGitRepo(gitPath, skillName);
      }
      return "synced_to_git";
    }

  // Fall 2: Nur in Git → zu ClawHub
  } else if (fs.existsSync(gitPath) && !fs.existsSync(clawhubPath)) {
    log(`NEW in Git: ${skillName} → syncing to ClawHub`);
    if (!dryRun) {
      backupSkillDir(gitPath, `${skillName}_git`);
    }
    if (await syncToClawhub(skillName, dryRun)) {
      return "synced_to_clawhub";
    }

  // Fall 3: In beiden vorhanden → Vergleiche Timestamps
  } else if (fs.existsSync(clawhubPath) && fs.existsSync(gitPath)) {
    // --- MODIFIZIERTE LOGIK: Robusterer Datei-Hash-Vergleich ---

    // Stelle sicher, dass beide als gültige Skills validiert werden
    if (!validateSkill(clawhubPath)) {
      log(`Validation failed for ClawHub skill: ${skillName}`, "ERROR");
      return "error";
    }
    if (!validateSkill(gitPath)) {
      log(`Validation failed for Git skill: ${skillName}`, "ERROR");
      return "error";
    }

    // Berechne Hashes für clawhub und git
    const clawhubHashes = getHashes(clawhubPath);
    const gitHashes = getHashes(gitPath);

    if (JSON.stringify(clawhubHashes) !== JSON.stringify(gitHashes)) {
      log(`Content difference detected for: ${skillName}`);

      // Einfache (aber oft ausreichende) Logik: Wenn clawhub neuer ist, lade hoch.
      // Eine detailliertere Strategie (z.B. welche Version von Git übernehmen)
      // könnte hier implementiert werden, falls nötig.
      // Für jetzt: Wenn sie sich unterscheiden, priorisieren wir ClawHub > Git
      // und aktualisieren Git.

      const clawhubStat = fs.statSync(clawhubPath);
      const gitStat = fs.statSync(gitPath);
      const direction = clawhubStat.mtimeMs >= gitStat.mtimeMs ? "to-git" : "to-clawhub";
      log(`UPDATE: ${skillName} → syncing ${direction}`);
      if (!dryRun) {
        backupSkillDir(clawhubPath, `${skillName}_clawhub`);
        backupSkillDir(gitPath, `${skillName}_git`);
      }
      const sync = direction === "to-git" ? syncToGit : syncToClawhub;
      if (await sync(skillName, dryRun)) {
        if (!dryRun && direction === "to-git") {
          process.chdir(gitPath);
          execSync("git add .", { stdio: 'ignore' });
          execSync(`git commit -m "Sync from ClawHub content diff: ${new Date().toISOString().slice(0, 16).replace('T', ' ')}"`, { stdio: 'ignore' });
        }
        return direction === "to-git" ? "updated_git" : "updated_clawhub";
      } else {
        log(`Failed to sync ${skillName} to Git after content diff`, "ERROR");
        return "error";
      }
    } else {
      log(`Content is identical for: ${skillName}`);
      return "no_change";
    }
  }

  return "no_change";
}

// --- Hinzufügen dieser Hilfsfunktion ---
function getHashes(skillDir) {
  /**Erzeugt ein Dictionary von Datei-Hashes für einen Skill-Ordner.*/
  const hashes = {};

  function walkDir(currentDir) {
    const items = fs.readdirSync(currentDir);
    for (const item of items) {
      const fullPath = path.join(currentDir, item);
      const relativePath = path.relative(skillDir, fullPath);
      
      // Ignoriere .git Verzeichnisse
      if (relativePath.includes('.git')) {
        continue;
      }
      
      const stat = fs.statSync(fullPath);
      if (stat.isDirectory()) {
        walkDir(fullPath);
      } else {
        hashes[relativePath] = getFileHash(fullPath);
      }
    }
  }

  walkDir(skillDir);
  return hashes;
}

async function main() {
  /**Hauptfunktion des Sync-Agents*/
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run') || args.includes('-d');
  
  log("=== ClawHub ↔ Git Sync Agent gestartet ===");

  const state = loadState();
  const allSkills = getAllSkills();
  log(`Gefundene Skills: ${allSkills.length}`);

  const results = {
    synced_to_git: [],
    synced_to_clawhub: [],
    updated_git: [],
    updated_clawhub: [],
    no_change: [],
    errors: []
  };

  for (const skill of allSkills.sort()) {
    try {
      const result = await syncSkillBidirectional(skill, dryRun);
      results[result].push(skill);
    } catch (e) {
      log(`ERROR syncing ${skill}: ${e.message}`, "ERROR");
      results.errors.push(skill);
    }
  }

  // Zusammenfassung
  log("\n=== SYNC ZUSAMMENFASSUNG ===");
  log(`Neu in Git: ${results.synced_to_git.length} - ${results.synced_to_git}`);
  log(`Neu in ClawHub: ${results.synced_to_clawhub.length} - ${results.synced_to_clawhub}`);
  log(`Git aktualisiert: ${results.updated_git.length} - ${results.updated_git}`);
  log(`ClawHub aktualisiert: ${results.updated_clawhub.length} - ${results.updated_clawhub}`);
  log(`Keine Änderung: ${results.no_change.length}`);
  log(`Fehler: ${results.errors.length} - ${results.errors}`);

  // Ein Dry-Run bleibt vollständig nicht-mutierend (abgesehen vom Audit-Log).
  if (!dryRun) {
    if (!state.sync_history) {
      state.sync_history = [];
    }
    state.sync_history.push({
      timestamp: new Date().toISOString(),
      results: results
    });
    // Nur letzte 100 Einträge behalten
    state.sync_history = state.sync_history.slice(-100);
    saveState(state);
  }

  log("=== Sync Agent beendet ===\n");
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { 
  loadState, 
  saveState, 
  getAllSkills, 
  initGitRepo, 
  backupSkillDir, 
  syncSkillBidirectional, 
  getHashes 
};
