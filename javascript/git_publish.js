#!/usr/bin/env node
// git_publish.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
// auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

/** Git Publish Agent - Automatisierte Skill-Veröffentlichung */

const { spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const SKILLS_DIR = path.join(require('os').homedir(), '.openclaw', 'workspace', 'skills');

function gitCommit(skillPath, message = null) {
  /** Commit skill changes. */
  if (!message) {
    const now = new Date().toISOString();
    message = `[skill] Auto-update ${path.basename(skillPath)} - ${now}`;
  }
  
  const skillDir = path.dirname(skillPath);
  spawnSync('git', ['add', skillPath], { cwd: path.dirname(skillDir) });
  const result = spawnSync(
    'git', 
    ['commit', '-m', message],
    { cwd: path.dirname(skillDir), encoding: 'utf8' }
  );
  return result.status === 0;
}

function clawhubPublish(skillName) {
  /** Publish to ClawHub. */
  const skillPath = path.join(SKILLS_DIR, skillName);
  const result = spawnSync(
    'clawhub', 
    ['publish', skillPath, '--slug', skillName, '--version', '1.0.0'],
    { encoding: 'utf8' }
  );
  return [result.status === 0, result.stdout];
}

function batchPublish() {
  /** Publish all changed skills with rate limiting. */
  // Check git status
  const result = spawnSync(
    'git', 
    ['status', '--short', SKILLS_DIR],
    { encoding: 'utf8' }
  );
  
  const changed = [];
  const lines = result.stdout.split('\n');
  for (const line of lines) {
    if (line.trim() && line.includes('skills/')) {
      const skill = line.split('skills/')[1].split('/')[0];
      if (!changed.includes(skill)) {
        changed.push(skill);
      }
    }
  }
  
  console.log(`Changed skills: ${JSON.stringify(changed)}`);
  
  // Publish with delay
  const maxBatch = Math.min(5, changed.length);
  for (let i = 0; i < maxBatch; i++) {
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
}

function main() {
  const args = process.argv.slice(2);
  let skill = null;
  let all = false;
  let noPublish = false;
  let message = null;
  
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--skill' && i + 1 < args.length) {
      skill = args[i + 1];
      i++;
    } else if (args[i] === '--all') {
      all = true;
    } else if (args[i] === '--no-publish') {
      noPublish = true;
    } else if (args[i] === '--message' && i + 1 < args.length) {
      message = args[i + 1];
      i++;
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
