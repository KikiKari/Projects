#!/usr/bin/env node
// sync_agent_cron.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:scripts/sync_agent_cron.py
// auch in: OpenClaw@gateway2:scripts/sync_agent_cron.py
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

/*
ClawHub ↔ Git Sync Agent - Cron Version mit Dry-Run + Auto-Sync
*/
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const CLAWHUB_DIR = '/home/openclaw/.openclaw/workspace/skills';
const GIT_DIR = '/home/openclaw/.openclaw/workspace/git/skills';
const LOG_FILE = '/home/openclaw/.openclaw/workspace/logs/sync-agent.log';

// Import sync functions (assuming they are in a separate module)
const { syncToGit, syncToClawhub, validateSkill } = require('./sync_clawhub_git');

function fileMtime(dirPath) {
    try {
        const files = getAllFiles(dirPath).filter(file => !file.includes('.git'));
        if (files.length === 0) return 0;
        return Math.max(...files.map(file => fs.statSync(file).mtime.getTime()));
    } catch {
        return 0;
    }
}

function getAllFiles(dirPath, arrayOfFiles = []) {
    const files = fs.readdirSync(dirPath);
    files.forEach(file => {
        const filePath = path.join(dirPath, file);
        if (fs.statSync(filePath).isDirectory()) {
            arrayOfFiles = getAllFiles(filePath, arrayOfFiles);
        } else {
            arrayOfFiles.push(filePath);
        }
    });
    return arrayOfFiles;
}

function writeToLog(message, level = "INFO") {
    const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
    const entry = `[${timestamp}] [${level}] ${message}`;
    console.log(entry);
    fs.appendFileSync(LOG_FILE, entry + '\n');
}

// Überschreibe die Log-Funktion
global.log = writeToLog;

writeToLog("=".repeat(70));
writeToLog("CLAWHUB ↔ GIT SYNC AGENT - CRON LAUF");
writeToLog(`Zeitstempel: ${new Date().toISOString()}`);
writeToLog("=".repeat(70));

const clawhubSkills = fs.readdirSync(CLAWHUB_DIR)
    .filter(d => fs.statSync(path.join(CLAWHUB_DIR, d)).isDirectory() && !d.startsWith('.'));

const gitSkills = fs.readdirSync(GIT_DIR)
    .filter(d => fs.statSync(path.join(GIT_DIR, d)).isDirectory() && !d.startsWith('.'));

// DRY-RUN: Erkenne Änderungen
writeToLog("\n[DRY-RUN] Analysiere Änderungen...");

let changesDetected = {
    new_in_clawhub: [],
    new_in_git: [],
    clawhub_newer: [],
    git_newer: [],
    synced: []
};

// 1. Neue Skills
const newInClawhub = clawhubSkills.filter(skill => !gitSkills.includes(skill)).sort();
const newInGit = gitSkills.filter(skill => !clawhubSkills.includes(skill)).sort();
changesDetected.new_in_clawhub = newInClawhub;
changesDetected.new_in_git = newInGit;

// 2. Existierende prüfen
const inBoth = clawhubSkills.filter(skill => gitSkills.includes(skill)).sort();
for (const skill of inBoth) {
    const cMtime = fileMtime(path.join(CLAWHUB_DIR, skill));
    const gMtime = fileMtime(path.join(GIT_DIR, skill));
    const diff = cMtime - gMtime;
    
    if (Math.abs(diff) > 60000) { // 60 seconds in milliseconds
        if (diff > 0) {
            changesDetected.clawhub_newer.push([skill, diff]);
        } else {
            changesDetected.git_newer.push([skill, Math.abs(diff)]);
        }
    } else {
        changesDetected.synced.push(skill);
    }
}

// Report
const totalChanges = newInClawhub.length + newInGit.length + changesDetected.clawhub_newer.length + changesDetected.git_newer.length;
writeToLog(`Neu in ClawHub: ${newInClawhub.length}`);
writeToLog(`Neu in Git: ${newInGit.length}`);
writeToLog(`ClawHub neuer: ${changesDetected.clawhub_newer.length}`);
writeToLog(`Git neuer: ${changesDetected.git_newer.length}`);
writeToLog(`Synchron: ${changesDetected.synced.length}`);

if (totalChanges === 0) {
    writeToLog("\n✅ Keine Änderungen erkannt. Sync nicht nötig.");
    writeToLog("=".repeat(70));
    process.exit(0);
}

writeToLog(`\n🔄 ${totalChanges} Änderungen erkannt - starte Synchronisation...`);

// ECHTE SYNCHRONISATION
let results = {
    synced_to_git: [],
    synced_to_clawhub: [],
    up_to_date: [],
    errors: []
};

// 1. NEU in ClawHub → zu Git
for (const skill of newInClawhub) {
    try {
        if (validateSkill(path.join(CLAWHUB_DIR, skill))) {
            writeToLog(`→ Synchronisiere ${skill} zu Git...`);
            if (syncToGit(skill, false)) {
                const gitPath = path.join(GIT_DIR, skill);
                process.chdir(gitPath);
                try {
                    execSync('git init -q', { stdio: 'ignore' });
                } catch {}
                try {
                    execSync('git add . -f', { stdio: 'ignore' });
                } catch {}
                try {
                    execSync(`git commit -m "Initial: ${skill}" -q`, { stdio: 'ignore' });
                } catch {}
                results.synced_to_git.push(skill);
                writeToLog(`  ✓ ${skill} synchronisiert`);
            }
        } else {
            results.errors.push(`${skill} (invalid)`);
        }
    } catch (e) {
        writeToLog(`  ✗ ERROR: ${skill} - ${e.message}`, "ERROR");
        results.errors.push(`${skill}`);
    }
}

// 2. NEU in Git → zu ClawHub
for (const skill of newInGit) {
    try {
        if (validateSkill(path.join(GIT_DIR, skill))) {
            writeToLog(`→ Synchronisiere ${skill} zu ClawHub...`);
            if (syncToClawhub(skill, false)) {
                results.synced_to_clawhub.push(skill);
                writeToLog(`  ✓ ${skill} synchronisiert`);
            }
        } else {
            results.errors.push(`${skill} (invalid)`);
        }
    } catch (e) {
        writeToLog(`  ✗ ERROR: ${skill} - ${e.message}`, "ERROR");
        results.errors.push(`${skill}`);
    }
}

// 3. Updates
for (const [skill, diff] of changesDetected.clawhub_newer) {
    try {
        writeToLog(`→ Update ${skill} (ClawHub +${Math.round(diff/1000)}s neuer)...`);
        if (syncToGit(skill, false)) {
            const gitPath = path.join(GIT_DIR, skill);
            process.chdir(gitPath);
            try {
                execSync('git add . -f', { stdio: 'ignore' });
            } catch {}
            const dt = new Date().toISOString().replace('T', ' ').substring(0, 16);
            try {
                execSync(`git commit -m "Sync from ClawHub: ${dt}" -q`, { stdio: 'ignore' });
            } catch {}
            results.synced_to_git.push(skill);
            writeToLog(`  ✓ ${skill} aktualisiert`);
        }
    } catch (e) {
        writeToLog(`  ✗ ERROR: ${skill} - ${e.message}`, "ERROR");
        results.errors.push(`${skill}`);
    }
}

for (const [skill, diff] of changesDetected.git_newer) {
    try {
        writeToLog(`→ Update ${skill} (Git +${Math.round(diff/1000)}s neuer)...`);
        if (syncToClawhub(skill, false)) {
            results.synced_to_clawhub.push(skill);
            writeToLog(`  ✓ ${skill} aktualisiert`);
        }
    } catch (e) {
        writeToLog(`  ✗ ERROR: ${skill} - ${e.message}`, "ERROR");
        results.errors.push(`${skill}`);
    }
}

results.up_to_date = changesDetected.synced;

// ZUSAMMENFASSUNG
writeToLog("\n" + "=".repeat(70));
writeToLog("SYNCHRONISATION ABGESCHLOSSEN");
writeToLog("=".repeat(70));
writeToLog(`Zu Git synchronisiert:     ${results.synced_to_git.length}`);
writeToLog(`Zu ClawHub synchronisiert: ${results.synced_to_clawhub.length}`);
writeToLog(`Bereits aktuell:           ${results.up_to_date.length}`);
writeToLog(`Fehler:                    ${results.errors.length}`);
if (results.errors.length > 0) {
    writeToLog(`  Fehlerhafte: ${results.errors.join(', ')}`);
}
writeToLog("=".repeat(70));

// State speichern
const STATE_FILE = "/home/openclaw/.openclaw/workspace/db/sync_state.json";
const stateDir = path.dirname(STATE_FILE);
if (!fs.existsSync(stateDir)) {
    fs.mkdirSync(stateDir, { recursive: true });
}
const state = {
    last_run: new Date().toISOString(),
    results: results,
    changes_detected: Object.fromEntries(
        Object.entries(changesDetected).map(([k, v]) => [
            k,
            Array.isArray(v) ? v.length : v
        ])
    )
};
fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
writeToLog(`State gespeichert: ${STATE_FILE}`);
