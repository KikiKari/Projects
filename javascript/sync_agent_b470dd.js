#!/usr/bin/env node
// sync_agent.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:skills/clawhub-git-sync-agent/scripts/sync_agent.py
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
  getFileHash,
  iterSyncFiles,
  RESERVED_SKILL_NAMES
} = require('./sync_clawhub_git');

const CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills";
const GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills";
const STATE_FILE = "/home/openclaw/.openclaw/workspace/db/sync_state.json";

function loadState() {
  /** Lädt den Sync-State */
  if (fs.existsSync(STATE_FILE)) {
    return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
  }
  return { sync_history: [], pending: [] };
}

function saveState(state) {
  /** Speichert den Sync-State */
  // Ensure the parent directory exists (handle symlink to existing directory)
  const dir = path.dirname(STATE_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function getAllSkills() {
  /** Findet alle Skills in beiden Verzeichnissen */
  const clawhubSkills = new Set();
  const gitSkills = new Set();

  if (fs.existsSync(CLAWHUB_DIR)) {
    for (const item of fs.readdirSync(CLAWHUB_DIR)) {
      const fullPath = path.join(CLAWHUB_DIR, item);
      if (
        fs.statSync(fullPath).isDirectory() &&
        !item.startsWith('.') &&
        !RESERVED_SKILL_NAMES.has(item) &&
        fs.existsSync(path.join(fullPath, "SKILL.md"))
      ) {
        clawhubSkills.add(item);
      }
    }
  }

  if (fs.existsSync(GIT_DIR)) {
    for (const item of fs.readdirSync(GIT_DIR)) {
      const fullPath = path.join(GIT_DIR, item);
      if (
        fs.statSync(fullPath).isDirectory() &&
        !item.startsWith('.') &&
        !RESERVED_SKILL_NAMES.has(item) &&
        fs.existsSync(path.join(fullPath, "SKILL.md"))
      ) {
        gitSkills.add(item);
      }
    }
  }

  return new Set([...clawhubSkills, ...gitSkills]);
}

function initGitRepo(skillPath, skillName) {
  /** Initialisiert Git-Repo wenn nötig */
  const gitDir = path.join(skillPath, ".git");
  if (!fs.existsSync(gitDir)) {
    process.chdir(skillPath);
    execSync("git init", { stdio: 'ignore' });
    execSync("git add .", { stdio: 'ignore' });
    execSync(`git commit -m "Initial commit: ${skillName} skill"`, { stdio: 'ignore' });
    log(`Git initialized for ${skillName}`);
  }
}

function syncSkillBidirectional(skillName) {
  /** Bidirektionale Synchronisation eines Skills */
  const clawhubPath = path.join(CLAWHUB_DIR, skillName);
  const gitPath = path.join(GIT_DIR, skillName);

  // Fall 1: Nur in ClawHub → zu Git
  if (fs.existsSync(clawhubPath) && !fs.existsSync(gitPath)) {
    log(`NEW in ClawHub: ${skillName} → syncing to Git`);
    if (syncToGit(skillName, false)) {
      initGitRepo(gitPath, skillName);
      return "synced_to_git";
    }
  }

  // Fall 2: Nur in Git → zu ClawHub
  else if (fs.existsSync(gitPath) && !fs.existsSync(clawhubPath)) {
    log(`NEW in Git: ${skillName} → syncing to ClawHub`);
    if (syncToClawhub(skillName, false)) {
      return "synced_to_clawhub";
    }
  }

  // Fall 3: In beiden vorhanden
  else if (fs.existsSync(clawhubPath) && fs.existsSync(gitPath)) {
    if (!validateSkill(clawhubPath)) {
      log(`Validation failed for ClawHub skill: ${skillName}`, "ERROR");
      return "error";
    }
    if (!validateSkill(gitPath)) {
      log(`Validation failed for Git skill: ${skillName}`, "ERROR");
      return "error";
    }

    const clawhubChanges = previewChanges(clawhubPath, gitPath);
    const gitChanges = previewChanges(gitPath, clawhubPath);

    if (clawhubChanges.length === 0 && gitChanges.length === 0) {
      log(`Content is identical for: ${skillName}`);
      return "no_change";
    }

    if (clawhubChanges.length > 0 && gitChanges.length === 0) {
      log(`Content difference detected for: ${skillName}`);
      log(`UPDATE: ${skillName} ClawHub content is newer or different → syncing to Git`);
      if (syncToGit(skillName, false)) {
        process.chdir(gitPath);
        execSync("git add .", { stdio: 'ignore' });
        const now = new Date().toISOString().slice(0, 16).replace('T', ' ');
        execSync(`git commit -m "Sync from ClawHub content diff: ${now}"`, { stdio: 'ignore' });
        return "updated_git";
      }
      log(`Failed to sync ${skillName} to Git after content diff`, "ERROR");
      return "error";
    }

    if (gitChanges.length > 0 && clawhubChanges.length === 0) {
      log(`Content difference detected for: ${skillName}`);
      log(`UPDATE: ${skillName} Git content is newer or different → syncing to ClawHub`);
      if (syncToClawhub(skillName, false)) {
        return "updated_clawhub";
      }
      log(`Failed to sync ${skillName} to ClawHub after content diff`, "ERROR");
      return "error";
    }

    log(`Content difference detected for: ${skillName}`);
    if (newestMtime(clawhubPath) >= newestMtime(gitPath)) {
      log(`UPDATE: ${skillName} ClawHub content is newer or different → syncing to Git`);
      if (syncToGit(skillName, false)) {
        process.chdir(gitPath);
        execSync("git add .", { stdio: 'ignore' });
        const now = new Date().toISOString().slice(0, 16).replace('T', ' ');
        execSync(`git commit -m "Sync from ClawHub content diff: ${now}"`, { stdio: 'ignore' });
        return "updated_git";
      }
    } else {
      log(`UPDATE: ${skillName} Git content is newer or different → syncing to ClawHub`);
      if (syncToClawhub(skillName, false)) {
        return "updated_clawhub";
      }
    }

    log(`Failed to resolve content diff for ${skillName}`, "ERROR");
    return "error";
  }

  return "no_change";
}

// --- Hinzufügen dieser Hilfsfunktion ---
function getHashes(skillDir) {
  /** Erzeugt ein Dictionary von Datei-Hashes für einen Skill-Ordner. */
  const hashes = {};
  for (const [filePath, relPath] of iterSyncFiles(skillDir)) {
    hashes[relPath] = getFileHash(filePath);
  }
  return hashes;
}

function previewChanges(sourceDir, targetDir) {
  /** Berechnet Sync-Änderungen in einer Richtung, ohne zu schreiben. */
  const changes = [];
  for (const [srcFile, relPath] of iterSyncFiles(sourceDir)) {
    const tgtFile = path.join(targetDir, relPath);
    if (!fs.existsSync(tgtFile)) {
      changes.push(`ADD ${relPath}`);
    } else if (getFileHash(srcFile) !== getFileHash(tgtFile)) {
      changes.push(`UPDATE ${relPath}`);
    }
  }
  return changes;
}

function newestMtime(skillDir) {
  /** Ermittelt die neueste mtime über alle relevanten Dateien. */
  const mtimes = [];
  for (const [filePath] of iterSyncFiles(skillDir)) {
    mtimes.push(fs.statSync(filePath).mtimeMs);
  }
  return mtimes.length > 0 ? Math.max(...mtimes) : 0;
}

function main() {
  /** Hauptfunktion des Sync-Agents mit Dry-Run Phase */
  log("=== ClawHub ↔ Git Sync Agent gestartet ===");

  // Load previous state
  const state = loadState();
  const allSkills = getAllSkills();
  log(`Gefundene Skills: ${allSkills.size}`);

  // Dry-Run Phase: only report changes, no actual modifications
  log("--- Dry-Run Phase Start ---");
  for (const skill of Array.from(allSkills).sort()) {
    // Perform dry-run sync in both directions to capture potential changes
    syncToGit(skill, true);
    syncToClawhub(skill, true);
  }
  log("--- Dry-Run Phase End ---");

  const results = {
    synced_to_git: [],
    synced_to_clawhub: [],
    updated_git: [],
    updated_clawhub: [],
    no_change: [],
    errors: []
  };

  // Actual Sync Phase
  for (const skill of Array.from(allSkills).sort()) {
    try {
      const result = syncSkillBidirectional(skill);
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

  // State speichern
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

  log("=== Sync Agent beendet ===\n");
}

main();
