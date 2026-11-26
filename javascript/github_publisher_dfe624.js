#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "755d3afe033a6a0f0b3680db5197d700b8d1ee6628e1b88a78e0d493687971fd", "source_sha256": "dfe62418dcbef9ea8aa7f18ada4f57d0ef73593432b7c7cefd85ee87eee622b4", "target_language": "javascript"}
// github_publisher.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/** Publish queued, provenance-checked artifacts without staging unrelated files. */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { spawnSync, execFileSync } = require('child_process');
const https = require('https');
const http = require('http');

const LANGUAGES = new Set(["perl5", "powershell", "perl6", "tcl", "javascript", "ruby", "python", "lua", "shell", "go", "java", "c", "cpp", "php", "fsharp", "css"]);

function hashFile(filePath) {
    const fileBuffer = fs.readFileSync(filePath);
    const hashSum = crypto.createHash('sha256');
    hashSum.update(fileBuffer);
    return hashSum.digest('hex');
}

function synchronizeCheckout(root, { remote = "https://github.com/KikiKari/OpenClaw.git", branch = "gateway1-abstractions" } = {}) {
    /** Reconcile a remote snapshot into the checkout without changing its Git history. */
    root = path.resolve(root);
    
    // Create temporary directory
    const tmpDir = fs.mkdtempSync(path.join(require('os').tmpdir(), 'abstractions-snapshot-'));
    try {
        const snapshot = path.join(tmpDir, 'repo');
        
        // Clone repository
        const cloneResult = spawnSync('git', [
            'clone', '--quiet', '--depth=1', '--single-branch',
            '--branch', branch, '--', remote, snapshot
        ], {
            stdio: ['ignore', 'ignore', 'ignore'],
            timeout: 300000
        });
        
        if (cloneResult.error || cloneResult.status !== 0) {
            throw new Error('Failed to clone repository');
        }
        
        // Get revision
        const revParseResult = spawnSync('git', ['-C', snapshot, 'rev-parse', 'HEAD'], {
            encoding: 'utf-8',
            timeout: 30000
        });
        
        if (revParseResult.error || revParseResult.status !== 0) {
            throw new Error('Failed to get revision');
        }
        
        const revision = revParseResult.stdout.trim();
        const counts = {};
        
        for (const language of Array.from(LANGUAGES).sort()) {
            const source = path.join(snapshot, language);
            const target = path.join(root, language);
            
            // Check for symlinks
            if (fs.existsSync(source) && fs.lstatSync(source).isSymbolicLink()) {
                throw new Error("language directory is a symlink");
            }
            
            if (fs.existsSync(target) && fs.lstatSync(target).isSymbolicLink()) {
                throw new Error("language directory is a symlink");
            }
            
            // Create target directory
            fs.mkdirSync(target, { recursive: true });
            
            // Get known hashes
            const known = new Set();
            const targetFiles = fs.readdirSync(target)
                .map(f => path.join(target, f))
                .filter(f => fs.statSync(f).isFile() && !fs.lstatSync(f).isSymbolicLink())
                .map(f => {
                    const hash = hashFile(f);
                    known.add(hash);
                    return f;
                });
            
            let files = [];
            if (fs.existsSync(source)) {
                files = fs.readdirSync(source)
                    .map(f => path.join(source, f))
                    .filter(f => {
                        const stat = fs.statSync(f);
                        return stat.isFile() && !fs.lstatSync(f).isSymbolicLink();
                    });
                
                // Validate files
                for (const file of files) {
                    if (fs.lstatSync(file).isSymbolicLink() || !fs.statSync(file).isFile()) {
                        throw new Error("invalid remote abstraction");
                    }
                }
            }
            
            counts[language] = files.length;
            
            for (const item of files) {
                const data = fs.readFileSync(item);
                const digest = crypto.createHash('sha256').update(data).digest('hex');
                
                if (known.has(digest)) {
                    continue;
                }
                
                const itemName = path.basename(item);
                let destination = path.join(target, itemName);
                
                if (fs.existsSync(destination) || (fs.existsSync(destination) && fs.lstatSync(destination).isSymbolicLink())) {
                    const parsedPath = path.parse(item);
                    destination = path.join(target, `${parsedPath.name}__pool_${digest}${parsedPath.ext}`);
                }
                
                try {
                    fs.writeFileSync(destination, data, { flag: 'wx' });
                } catch (error) {
                    if (error.code === 'EEXIST') {
                        if ((fs.lstatSync(destination).isSymbolicLink() || 
                             !fs.statSync(destination).isFile() || 
                             !fs.readFileSync(destination).equals(data))) {
                            throw new Error("local abstraction conflict");
                        }
                    } else {
                        throw error;
                    }
                }
                known.add(digest);
            }
        }
        
        return [revision, counts];
    } finally {
        // Clean up temporary directory
        fs.rmSync(tmpDir, { recursive: true, force: true });
    }
}

function updateStatusCounts(filePath, revision, counts) {
    let text = fs.readFileSync(filePath, 'utf-8');
    
    const rows = [
        "## Bestand",
        "",
        `GitHub-Stand: \`${revision}\``,
        "",
        "| Zielsprache | Dateien |",
        "|---|---:|"
    ];
    
    for (const language of Array.from(LANGUAGES).sort()) {
        rows.push(`| ${language} | ${counts[language]} |`);
    }
    
    rows.push(`| **gesamt** | **${Object.values(counts).reduce((a, b) => a + b, 0)}** |`, "", "");
    
    const pattern = /## Bestand\n[\s\S]*?(?=## Quellen\n)/;
    const replacement = rows.join('\n');
    
    const count = (text.match(pattern) || []).length;
    if (count !== 1) {
        throw new Error("status inventory section missing");
    }
    
    text = text.replace(pattern, replacement);
    fs.writeFileSync(filePath, text, 'utf-8');
}

function queueArtifact(state, root, filePath) {
    root = path.resolve(root);
    const resolvedPath = path.resolve(filePath);
    
    if (fs.lstatSync(filePath).isSymbolicLink()) {
        throw new Error("artifact must not be a symlink");
    }
    
    const relative = path.relative(root, resolvedPath);
    
    if (relative !== 'STATUS.md' && (!relative.split(path.sep).length || !LANGUAGES.has(relative.split(path.sep)[0]))) {
        throw new Error("artifact is outside a language directory");
    }
    
    if (!state.ausstehende_veroeffentlichungen) {
        state.ausstehende_veroeffentlichungen = {};
    }
    
    state.ausstehende_veroeffentlichungen[relative] = hashFile(filePath);
}

function makeRequest(options, postData = null) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    resolve({
                        statusCode: res.statusCode,
                        headers: res.headers,
                        data: JSON.parse(data)
                    });
                } catch (e) {
                    resolve({
                        statusCode: res.statusCode,
                        headers: res.headers,
                        data: data
                    });
                }
            });
        });
        
        req.on('error', reject);
        
        if (postData) {
            req.write(postData);
        }
        
        req.end();
    });
}

async function publishPending(root, state, save, token, { opener = makeRequest, sync = null } = {}) {
    const pending = state.ausstehende_veroeffentlichungen || {};
    
    if (typeof pending !== 'object' || pending === null) {
        throw new Error("invalid publication queue");
    }
    
    if (Object.keys(pending).length === 0 && sync === null) {
        return true;
    }
    
    if (!token || !token.trim()) {
        return false;
    }
    
    root = path.resolve(root);
    const headers = {
        "Authorization": "Bearer " + token.trim(),
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "abstractions-manager"
    };
    
    let success = true;
    const entries = Object.entries(pending).sort((a, b) => {
        if (a[0] === 'STATUS.md') return -1;
        if (b[0] === 'STATUS.md') return 1;
        return 0;
    });
    
    let synced = false;
    
    for (const [name, expected] of entries) {
        try {
            const filePath = path.join(root, name);
            
            if (fs.lstatSync(filePath).isSymbolicLink() || path.relative(root, path.resolve(filePath)) !== name) {
                throw new Error("invalid queued path");
            }
            
            const data = fs.readFileSync(filePath);
            const hash = crypto.createHash('sha256').update(data).digest('hex');
            
            if (hash !== expected) {
                throw new Error("queued artifact changed");
            }
            
            if (name === 'STATUS.md' && sync !== null) {
                if (!success) {
                    throw new Error("artifact publication incomplete");
                }
                
                const [revision, counts] = sync(root);
                synced = true;
                updateStatusCounts(filePath, revision, counts);
                
                const newData = fs.readFileSync(filePath);
                const newExpected = crypto.createHash('sha256').update(newData).digest('hex');
                pending[name] = newExpected;
                save(state);
            }
            
            async function lookup(remoteName) {
                const endpoint = "https://api.github.com/repos/KikiKari/OpenClaw/contents/" + encodeURIComponent(remoteName);
                const options = {
                    hostname: 'api.github.com',
                    path: `/repos/KikiKari/OpenClaw/contents/${encodeURIComponent(remoteName)}?ref=gateway1-abstractions`,
                    method: 'GET',
                    headers: headers
                };
                
                try {
                    const response = await opener(options);
                    return [endpoint, response.data];
                } catch (error) {
                    if (error.statusCode !== 404) {
                        throw error;
                    }
                    return [endpoint, null];
                }
            }
            
            function same(existing) {
                return (existing && typeof existing === 'object' && existing.encoding === "base64" &&
                        Buffer.from(existing.content, 'base64').equals(data));
            }
            
            let [endpoint, existing] = await lookup(name);
            
            if (name === 'STATUS.md' && existing !== null && !same(existing)) {
                const sha = typeof existing === 'object' ? existing.sha : null;
                if (typeof sha !== 'string' || !sha) {
                    throw new Error('missing remote status version');
                }
                
                const body = JSON.stringify({
                    'message': 'Update abstraction status',
                    'branch': 'gateway1-abstractions',
                    'content': data.toString('base64'),
                    'sha': sha
                });
                
                const putOptions = {
                    hostname: 'api.github.com',
                    path: `/repos/KikiKari/OpenClaw/contents/${encodeURIComponent(name)}`,
                    method: 'PUT',
                    headers: {...headers, 'Content-Length': Buffer.byteLength(body)}
                };
                
                const response = await opener(putOptions, body);
            } else if (existing !== null && !same(existing)) {
                // Independent managers can derive different results for one
                // source. Preserve both without overwriting the remote file.
                const candidate = path.parse(name);
                const alternate = path.posix.join(candidate.dir, `${candidate.name}_${expected.substring(0, 12)}${candidate.ext}`);
                [endpoint, existing] = await lookup(alternate);
                if (existing !== null && !same(existing)) {
                    throw new Error("remote artifact conflict");
                }
            }
            
            if (existing === null) {
                const body = JSON.stringify({
                    "message": "Publish script abstraction",
                    "branch": "gateway1-abstractions",
                    "content": data.toString('base64')
                });
                
                const putOptions = {
                    hostname: 'api.github.com',
                    path: `/repos/KikiKari/OpenClaw/contents/${encodeURIComponent(name)}`,
                    method: 'PUT',
                    headers: {...headers, 'Content-Length': Buffer.byteLength(body)}
                };
                
                const response = await opener(putOptions, body);
            }
            
            delete pending[name];
            save(state);
        } catch (error) {
            success = false;
        }
    }
    
    if (sync !== null && !synced) {
        try {
            sync(root);
        } catch (error) {
            success = false;
        }
    }
    
    return success;
}

module.exports = {
    LANGUAGES,
    synchronizeCheckout,
    updateStatusCounts,
    queueArtifact,
    publishPending
};
