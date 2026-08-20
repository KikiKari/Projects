#!/usr/bin/env node
// sync_status.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/sync_status.py
// auch in: OpenClaw@gateway2:skills/sync-utils/scripts/sync_status.py
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

/**
 * Sync Status - Zeigt Status aller Skills
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Konstanten
const CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills";
const GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills";
const STATE_FILE = "/home/openclaw/.openclaw/workspace/db/sync_state.json";

/**
 * Prüft Status eines Skills
 */
function checkSkillStatus(skillName) {
    const clawhubPath = path.join(CLAWHUB_DIR, skillName);
    const gitPath = path.join(GIT_DIR, skillName);
    
    const status = {
        name: skillName,
        in_clawhub: fs.existsSync(clawhubPath),
        in_git: fs.existsSync(gitPath),
        has_git_repo: fs.existsSync(path.join(gitPath, ".git")),
        status: "unknown",
        last_modified: {}
    };
    
    // Status bestimmen
    if (status.in_clawhub && !status.in_git) {
        status.status = "only_clawhub";
    } else if (status.in_git && !status.in_clawhub) {
        status.status = "only_git";
    } else if (status.in_clawhub && status.in_git) {
        // Timestamps vergleichen
        try {
            let clawhubFiles = [];
            function walkDir(dir) {
                const files = fs.readdirSync(dir);
                for (const file of files) {
                    const filePath = path.join(dir, file);
                    const stat = fs.statSync(filePath);
                    if (stat.isDirectory()) {
                        walkDir(filePath);
                    } else {
                        clawhubFiles.push({ path: filePath, mtime: stat.mtime.getTime() });
                    }
                }
            }
            
            walkDir(clawhubPath);
            const clawhubMtimes = clawhubFiles.map(f => f.mtime);
            const clawhubMtime = Math.max(...clawhubMtimes);
            
            let gitFiles = [];
            function walkGitDir(dir) {
                const files = fs.readdirSync(dir);
                for (const file of files) {
                    if (file === '.git') continue;
                    const filePath = path.join(dir, file);
                    const stat = fs.statSync(filePath);
                    if (stat.isDirectory()) {
                        walkGitDir(filePath);
                    } else {
                        gitFiles.push({ path: filePath, mtime: stat.mtime.getTime() });
                    }
                }
            }
            
            walkGitDir(gitPath);
            const gitMtimes = gitFiles.map(f => f.mtime);
            const gitMtime = Math.max(...gitMtimes);
            
            const clawhubDate = new Date(clawhubMtime);
            const gitDate = new Date(gitMtime);
            
            status.last_modified.clawhub = clawhubDate.getFullYear() + '-' +
                String(clawhubDate.getMonth() + 1).padStart(2, '0') + '-' +
                String(clawhubDate.getDate()).padStart(2, '0') + ' ' +
                String(clawhubDate.getHours()).padStart(2, '0') + ':' +
                String(clawhubDate.getMinutes()).padStart(2, '0') + ':' +
                String(clawhubDate.getSeconds()).padStart(2, '0');
                
            status.last_modified.git = gitDate.getFullYear() + '-' +
                String(gitDate.getMonth() + 1).padStart(2, '0') + '-' +
                String(gitDate.getDate()).padStart(2, '0') + ' ' +
                String(gitDate.getHours()).padStart(2, '0') + ':' +
                String(gitDate.getMinutes()).padStart(2, '0') + ':' +
                String(gitDate.getSeconds()).padStart(2, '0');
            
            if (Math.abs(clawhubMtime - gitMtime) < 60000) {
                status.status = "synced";
            } else if (clawhubMtime > gitMtime) {
                status.status = "clawhub_newer";
            } else {
                status.status = "git_newer";
            }
        } catch (e) {
            status.status = "error";
        }
    }
    
    return status;
}

/**
 * Hauptfunktion
 */
function main() {
    console.log("=" .repeat(80));
    console.log("ClawHub ↔ Git Sync Status");
    console.log("=" .repeat(80));
    
    const now = new Date();
    console.log(`Zeitpunkt: ${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`);
    console.log();
    
    // Alle Skills finden
    let allSkills = new Set();
    
    if (fs.existsSync(CLAWHUB_DIR)) {
        const clawhubDirs = fs.readdirSync(CLAWHUB_DIR);
        for (const dir of clawhubDirs) {
            const fullPath = path.join(CLAWHUB_DIR, dir);
            const stat = fs.statSync(fullPath);
            if (stat.isDirectory() && !dir.startsWith('.')) {
                allSkills.add(dir);
            }
        }
    }
    
    if (fs.existsSync(GIT_DIR)) {
        const gitDirs = fs.readdirSync(GIT_DIR);
        for (const dir of gitDirs) {
            const fullPath = path.join(GIT_DIR, dir);
            const stat = fs.statSync(fullPath);
            if (stat.isDirectory() && !dir.startsWith('.')) {
                allSkills.add(dir);
            }
        }
    }
    
    // Status-Kategorien
    const categories = {
        "synced": [],
        "clawhub_newer": [],
        "git_newer": [],
        "only_clawhub": [],
        "only_git": [],
        "error": []
    };
    
    // Status für jeden Skill prüfen
    for (const skill of Array.from(allSkills).sort()) {
        const status = checkSkillStatus(skill);
        categories[status.status].push(status);
    }
    
    // Ausgabe
    console.log(`📊 Gesamt: ${allSkills.size} Skills\n`);
    
    // Synchronisiert
    if (categories.synced.length > 0) {
        console.log(`✅ Synchronisiert (${categories.synced.length})`);
        for (const s of categories.synced) {
            console.log(`   - ${s.name}`);
        }
        console.log();
    }
    
    // ClawHub neuer
    if (categories.clawhub_newer.length > 0) {
        console.log(`🔄 ClawHub neuer (${categories.clawhub_newer.length})`);
        for (const s of categories.clawhub_newer) {
            console.log(`   - ${s.name} (ClawHub: ${s.last_modified.clawhub})`);
        }
        console.log();
    }
    
    // Git neuer
    if (categories.git_newer.length > 0) {
        console.log(`🔄 Git neuer (${categories.git_newer.length})`);
        for (const s of categories.git_newer) {
            console.log(`   - ${s.name} (Git: ${s.last_modified.git})`);
        }
        console.log();
    }
    
    // Nur in ClawHub
    if (categories.only_clawhub.length > 0) {
        console.log(`📦 Nur in ClawHub (${categories.only_clawhub.length})`);
        for (const s of categories.only_clawhub) {
            console.log(`   - ${s.name}`);
        }
        console.log();
    }
    
    // Nur in Git
    if (categories.only_git.length > 0) {
        console.log(`📁 Nur in Git (${categories.only_git.length})`);
        for (const s of categories.only_git) {
            console.log(`   - ${s.name}`);
        }
        console.log();
    }
    
    // Fehler
    if (categories.error.length > 0) {
        console.log(`❌ Fehler (${categories.error.length})`);
        for (const s of categories.error) {
            console.log(`   - ${s.name}`);
        }
        console.log();
    }
    
    // State-File Info
    if (fs.existsSync(STATE_FILE)) {
        const stateContent = fs.readFileSync(STATE_FILE, 'utf8');
        const state = JSON.parse(stateContent);
        const lastRuns = Object.keys(state.last_sync || {});
        if (lastRuns.length > 0) {
            console.log(`📅 Letzter automatischer Sync: ${lastRuns[lastRuns.length - 1]}`);
        }
    }
    
    console.log("=" .repeat(80));
}

main();
