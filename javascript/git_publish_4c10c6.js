#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "7810a132045bd443af7b3d9ef40e116429c9f94d2101dced07445745f44ef0d5", "source_sha256": "4c10c6b6fd911cb95da119f761f402073d1a836cab6b40a9f3b989536d5df5ec", "target_language": "javascript"}
// git_publish.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
// auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const SKILLS_DIR = path.join(require('os').homedir(), '.openclaw', 'workspace', 'skills');

function gitCommit(skillPath, message = null) {
    if (!message) {
        const now = new Date().toISOString();
        message = `[skill] Auto-update ${path.basename(skillPath)} - ${now}`;
    }
    
    try {
        execSync(`git add "${skillPath}"`, { cwd: path.dirname(SKILLS_DIR) });
        execSync(`git commit -m "${message}"`, { cwd: path.dirname(SKILLS_DIR) });
        return true;
    } catch (error) {
        return false;
    }
}

function clawhubPublish(skillName) {
    const skillPath = path.join(SKILLS_DIR, skillName);
    try {
        const result = execSync(
            `clawhub publish "${skillPath}" --slug ${skillName} --version 1.0.0`,
            { encoding: 'utf8' }
        );
        return [true, result];
    } catch (error) {
        return [false, error.message];
    }
}

function batchPublish() {
    try {
        const result = execSync(
            `git status --short "${SKILLS_DIR}"`,
            { encoding: 'utf8' }
        );
        
        const lines = result.split('\n');
        const changed = [];
        
        for (const line of lines) {
            if (line.trim() && line.includes('skills/')) {
                const skill = line.split('skills/')[1].split('/')[0];
                if (!changed.includes(skill)) {
                    changed.push(skill);
                }
            }
        }
        
        console.log(`Changed skills: ${JSON.stringify(changed)}`);
        
        const batchSize = Math.min(5, changed.length);
        for (let i = 0; i < batchSize; i++) {
            const skill = changed[i];
            if (i > 0) {
                console.log('Waiting 15min for rate limit...');
                // In real: await new Promise(resolve => setTimeout(resolve, 900000));
            }
            
            console.log(`Publishing ${skill}...`);
            const commitOk = gitCommit(path.join(SKILLS_DIR, skill));
            if (commitOk) {
                const [pubOk, output] = clawhubPublish(skill);
                console.log(`  ${pubOk ? '✓' : '✗'} ${output}`);
            }
        }
    } catch (error) {
        console.error('Batch publish failed:', error.message);
    }
}

function main() {
    const args = process.argv.slice(2);
    let skill = null;
    let all = false;
    let noPublish = false;
    let message = null;
    
    for (let i = 0; i < args.length; i++) {
        if (args[i] === '--skill' && i + 1 < args.length) {
            skill = args[++i];
        } else if (args[i] === '--all') {
            all = true;
        } else if (args[i] === '--no-publish') {
            noPublish = true;
        } else if (args[i] === '--message' && i + 1 < args.length) {
            message = args[++i];
        }
    }
    
    if (skill) {
        const skillPath = path.join(SKILLS_DIR, skill);
        if (noPublish) {
            gitCommit(skillPath, message);
        } else {
            gitCommit(skillPath, message);
            clawhubPublish(skill);
        }
    } else if (all) {
        batchPublish();
    } else {
        console.log('Use --skill <name> or --all');
    }
}

main();
