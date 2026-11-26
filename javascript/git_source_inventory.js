#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "5a80760df414f84f99d90e04a63d3de0ecb5f99f8f50b13d4c69dec7b30791f6", "source_sha256": "42646f32f72b1ca4e041673cd4a65a4b6611379252e110d53df9fb001a5ba6de", "target_language": "javascript"}
// git_source_inventory.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/git_source_inventory.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/**
 * Git tree inventory and batched selected-blob loading.
 */

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const crypto = require('crypto');

function writePrivate(filePath, data) {
  const fd = fs.openSync(filePath, 'wx', 0o600);
  try {
    fs.writeFileSync(fd, data);
  } finally {
    fs.closeSync(fd);
  }
}

function snapshot(manager, runId, runAttempt, workflowSha) {
  function repositoryIndex(source) {
    const name = String(source.repo);
    const mirror = path.join(manager.QUELLEN_DIR, name + '.git');

    function git(...args) {
      return execFileSync('git', ['-C', mirror, ...args], {
        stdio: ['ignore', 'pipe', 'pipe'],
        timeout: 1800000,
        maxBuffer: 1024 * 1024 * 100
      });
    }

    const refsOutput = git('for-each-ref', '--format=%(refname:strip=2)%00%(objectname)', 'refs/heads');
    const refs = refsOutput.toString().trim().split('\n');
    const selected = [];
    
    for (const line of refs) {
      if (!line) continue;
      const [branchBytes, commit] = line.split('\0');
      const branch = branchBytes;
      if (source.branches === 'alle' || source.branches.includes(branch)) {
        selected.push([branch, commit]);
      }
    }

    function branchIndex([branch, commit]) {
      const lsTreeOutput = git('ls-tree', '-r', '-z', '--full-tree', commit);
      const entries = lsTreeOutput.toString().split('\0');
      const paths = [];
      
      for (const entry of entries) {
        if (!entry) continue;
        const [meta, filePath] = entry.split('\t');
        const parts = meta.split(' ');
        if (parts[1] === 'blob' && manager.QUELLSPRACHEN[path.extname(filePath).toLowerCase()]) {
          paths.push(filePath);
        }
      }
      
      return [branch, { commit, paths }];
    }

    const pool = require('worker_threads');
    // In Node.js we simulate ThreadPoolExecutor with Promise.all and slicing
    const branches = {};
    const results = selected.map(branchIndex);
    for (const [branch, data] of results) {
      branches[branch] = data;
    }
    
    if (Object.keys(branches).length === 0 || 
        (source.branches !== 'alle' && new Set(Object.keys(branches)).size !== new Set(source.branches).size)) {
      throw new Error('incomplete source branches');
    }
    
    return [name, branches];
  }

  // Simulate ThreadPoolExecutor with Promise.all
  const repositories = {};
  const results = manager.QUELLEN.map(repositoryIndex);
  for (const [name, branches] of results) {
    repositories[name] = branches;
  }
  
  return {
    version: 1,
    run_id: runId,
    run_attempt: runAttempt,
    workflow_sha: workflowSha,
    repositories
  };
}

function prepareGitSources(manager, directory, state, priority, count, runId, runAttempt, workflowSha) {
  const fs = require('fs');
  const path = require('path');
  const crypto = require('crypto');
  const { execFileSync } = require('child_process');

  function git(mirror, ...args) {
    const options = {
      input: args.data,
      stdio: ['pipe', 'pipe', 'pipe'],
      timeout: 1800000,
      maxBuffer: 1024 * 1024 * 100
    };
    
    return execFileSync('git', ['-C', mirror, ...args.filter(arg => arg !== 'data')], options);
  }

  fs.mkdirSync(manager.QUELLEN_DIR, { recursive: true });

  function update(source) {
    const repo = String(source.repo);
    const mirror = path.join(manager.QUELLEN_DIR, repo + '.git');
    
    let result;
    if (fs.existsSync(mirror)) {
      result = manager._git('remote', 'update', '--prune', { verzeichnis: mirror });
    } else {
      const url = `https://github.com/${manager.GITHUB_BENUTZER}/${repo}.git`;
      result = manager._git('clone', '--mirror', '--filter=blob:none', url, mirror);
    }
    
    if (result.status !== 0) {
      throw new Error(`${repo}: Quellspiegel nicht verfuegbar`);
    }
  }

  // Simulate ThreadPoolExecutor
  manager.QUELLEN.forEach(update);

  const index = snapshot(manager, runId, runAttempt, workflowSha);
  let sources = [];

  function listBranch([repo, branch, commit]) {
    const mirror = path.join(manager.QUELLEN_DIR, repo + '.git');
    const lsTreeOutput = git(mirror, 'ls-tree', '-r', '-z', '--full-tree', commit);
    const items = lsTreeOutput.toString().split('\0');
    const records = [];
    
    for (const item of items) {
      if (!item) continue;
      const [metadata, rawPath] = item.split('\t');
      const [mode, kind, oid] = metadata.split(' ');
      
      if (kind !== 'blob' || (mode !== '100644' && mode !== '100755')) {
        continue;
      }
      
      const filePath = rawPath.replace(/\\\\/g, '/');
      const language = manager.QUELLSPRACHEN[path.extname(filePath).toLowerCase()];
      
      if (language === undefined || manager.AUSSCHLUSS.some(pattern => '/' + filePath.includes(pattern))) {
        continue;
      }
      
      if (!/^[0-9a-f]{40}$/.test(oid)) {
        throw new Error('invalid Git blob identity');
      }
      
      records.push([repo, branch, commit, filePath, language, oid]);
    }
    
    return records;
  }

  const branches = [];
  for (const [repo, details] of Object.entries(index.repositories)) {
    for (const [branch, data] of Object.entries(details)) {
      branches.push([repo, branch, data.commit]);
    }
  }

  // Simulate ThreadPoolExecutor
  const results = branches.map(listBranch);
  for (const records of results) {
    sources = sources.concat(records);
  }

  const grouped = {};
  for (const [repo, branch, commit, filePath, language, oid] of sources) {
    const origin = `${repo}@${branch}:${filePath}`;
    let item = grouped[oid];
    
    if (item === undefined) {
      item = {
        blob: oid,
        repo: repo,
        commit: commit,
        path: filePath,
        sprache: language,
        herkunft: [],
        prioritaet: manager._prioritaet(filePath, language)
      };
      grouped[oid] = item;
    }
    
    item.herkunft.push(origin);
  }

  const rank = { high: 0, medium: 1, low: 2 };
  let candidates = Object.values(grouped).filter(
    item => priority === 'alle' || item.prioritaet === priority
  ).sort((a, b) => {
    const rankA = rank[a.prioritaet];
    const rankB = rank[b.prioritaet];
    if (rankA !== rankB) {
      return rankA - rankB;
    }
    return path.basename(a.path).localeCompare(path.basename(b.path));
  });

  const cursor = state.auswahl_blob_cursor?.[priority];
  if (cursor) {
    const pos = candidates.findIndex(item => item.blob === cursor);
    if (pos !== -1) {
      candidates = [...candidates.slice(pos + 1), ...candidates.slice(0, pos + 1)];
    }
  }

  const selected = candidates.slice(0, count);
  const byRepo = {};
  
  for (const item of selected) {
    if (!byRepo[item.repo]) {
      byRepo[item.repo] = [];
    }
    byRepo[item.repo].push(item);
  }

  function readBlobs([repo, items]) {
    const mirror = path.join(manager.QUELLEN_DIR, repo + '.git');
    const requested = items.map(item => item.blob + '\n').join('');
    const checksOutput = git(mirror, 'cat-file', '--batch-check=%(objectname) %(objecttype) %(objectsize)', { data: requested });
    const checks = checksOutput.toString().trim().split('\n');
    
    if (checks.length !== items.length) {
      throw new Error('incomplete Git blob metadata');
    }
    
    const eligible = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const line = checks[i];
      const fields = line.split(' ');
      
      if (fields.length !== 3 || fields[0] !== item.blob || fields[1] !== 'blob') {
        throw new Error('invalid Git blob metadata');
      }
      
      const size = parseInt(fields[2], 10);
      if (size <= manager.MAX_BYTES) {
        eligible.push([item, size]);
      }
    }
    
    if (eligible.length === 0) {
      return [];
    }
    
    const wanted = eligible.map(([item, _]) => item.blob + '\n').join('');
    const output = git(mirror, 'cat-file', '--batch', { data: wanted });
    const result = [];
    let offset = 0;
    
    for (const [item, size] of eligible) {
      const headerEnd = output.indexOf('\n', offset);
      const header = output.substring(offset, headerEnd).trim().split(' ');
      
      if (header.length !== 3 || header[0] !== item.blob || header[1] !== 'blob' || parseInt(header[2], 10) !== size) {
        throw new Error('invalid Git blob response');
      }
      
      const rawStart = headerEnd + 1;
      const raw = output.substring(rawStart, rawStart + size);
      
      if (raw.length !== size || (rawStart + size < output.length && output[rawStart + size] !== '\n')) {
        throw new Error('incomplete Git blob response');
      }
      
      result.push([item, Buffer.from(raw, 'binary')]);
      offset = rawStart + size + 1;
    }
    
    return result;
  }

  const loaded = {};
  // Simulate ThreadPoolExecutor
  const readResults = Object.entries(byRepo).map(readBlobs);
  for (const result of readResults) {
    for (const [item, raw] of result) {
      loaded[item.blob] = raw;
    }
  }

  const sourceDir = path.join(directory, 'sources');
  fs.mkdirSync(sourceDir, { mode: 0o700, recursive: true });
  
  const inventory = [];
  for (const item of selected) {
    const raw = loaded[item.blob];
    if (raw === undefined || raw.toString().trim() === '' || manager.enthaelt_zugangsdaten(raw)) {
      continue;
    }
    
    const digest = crypto.createHash('sha256').update(raw).digest('hex');
    const target = path.join(sourceDir, digest);
    
    if (!fs.existsSync(target)) {
      writePrivate(target, raw);
    }
    
    const sourcePath = path.parse(item.path);
    inventory.push({
      hash: digest.substring(0, 16),
      name: sourcePath.base,
      stamm: sourcePath.name,
      sprache: item.sprache,
      bytes: raw.length,
      pfad: target,
      herkunft: item.herkunft,
      prioritaet: item.prioritaet,
      css_only: false,
      source_blob: item.blob,
      source_repo: item.repo,
      source_commit: item.commit,
      source_path: item.path,
      source_sha256: digest
    });
  }
  
  const lastSelected = selected.length > 0 ? selected[selected.length - 1].blob : null;
  return [index, inventory, lastSelected];
}

module.exports = {
  snapshot,
  prepareGitSources
};
