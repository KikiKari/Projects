#!/usr/bin/env node
// github_publisher.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
// Erzeugt: 2026-11-20 durch ABSTRACTIONS_MANAGER.py

/** Publish queued, provenance-checked artifacts without staging unrelated files. */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const child_process = require('child_process');
const https = require('https');
const http = require('http');

const LANGUAGES = new Set(["perl5", "powershell", "perl6", "tcl", "javascript", "ruby", "python", "lua", "shell", "go"]);

function synchronizeCheckout(root, options = {}) {
    const { remote = "https://github.com/KikiKari/OpenClaw.git", branch = "gateway1-abstractions" } = options;
    
    root = path.resolve(root);
    if (!fs.existsSync(root)) {
        throw new Error("Root directory does not exist");
    }
    
    const tmpDir = fs.mkdtempSync("abstractions-snapshot-");
    try {
        const snapshot = path.join(tmpDir, "repo");
        
        // Clone repository
        child_process.execFileSync("git", [
            "clone", "--quiet", "--depth=1", "--single-branch",
            "--branch", branch, "--", remote, snapshot
        ], { stdio: 'ignore', timeout: 300000 });
        
        // Get revision
        const revision = child_process.execFileSync("git", [
            "-C", snapshot, "rev-parse", "HEAD"
        ], { encoding: 'utf8', timeout: 30000 }).trim();
        
        const counts = {};
        
        for (const language of Array.from(LANGUAGES).sort()) {
            const source = path.join(snapshot, language);
            const target = path.join(root, language);
            
            if (fs.existsSync(source) && fs.lstatSync(source).isSymbolicLink()) {
                throw new Error("language directory is a symlink");
            }
            if (fs.existsSync(target) && fs.lstatSync(target).isSymbolicLink()) {
                throw new Error("language directory is a symlink");
            }
            
            if (fs.existsSync(source) && !fs.statSync(source).isDirectory()) {
                throw new Error("invalid remote language directory");
            }
            
            if (!fs.existsSync(target)) {
                fs.mkdirSync(target, { recursive: true });
            }
            
            const known = new Set();
            if (fs.existsSync(target)) {
                for (const file of fs.readdirSync(target)) {
                    const filePath = path.join(target, file);
                    if (fs.statSync(filePath).isFile() && !fs.lstatSync(filePath).isSymbolicLink()) {
                        const data = fs.readFileSync(filePath);
                        known.add(crypto.createHash('sha256').update(data).digest('hex'));
                    }
                }
            }
            
            let files = [];
            if (fs.existsSync(source)) {
                files = fs.readdirSync(source)
                    .map(file => path.join(source, file))
                    .filter(filePath => fs.statSync(filePath).isFile() && !fs.lstatSync(filePath).isSymbolicLink());
                
                if (files.some(filePath => fs.lstatSync(filePath).isSymbolicLink() || !fs.statSync(filePath).isFile())) {
                    throw new Error("invalid remote abstraction");
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
                
                if (fs.existsSync(destination) || fs.lstatSync(destination).isSymbolicLink()) {
                    const parsedPath = path.parse(item);
                    destination = path.join(target, `${parsedPath.name}__pool_${digest}${parsedPath.ext}`);
                }
                
                try {
                    fs.writeFileSync(destination, data, { flag: 'wx' });
                } catch (error) {
                    if (error.code === 'EEXIST') {
                        if (fs.lstatSync(destination).isSymbolicLink() || 
                            !fs.statSync(destination).isFile() || 
                            !fs.readFileSync(destination).equals(data)) {
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
        if (fs.existsSync(tmpDir)) {
            fs.rmSync(tmpDir, { recursive: true, force: true });
        }
    }
}

function updateStatusCounts(filePath, revision, counts) {
    let text = fs.readFileSync(filePath, 'utf8');
    
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
    
    const pattern = /^## Bestand\n.*?(?=^## Quellen\n)/ms;
    const countResult = text.match(pattern);
    
    if (!countResult) {
        throw new Error("status inventory section missing");
    }
    
    const updated = text.replace(pattern, rows.join('\n'));
    fs.writeFileSync(filePath, updated, 'utf8');
}

function queueArtifact(state, root, filePath) {
    root = path.resolve(root);
    filePath = path.resolve(filePath);
    
    if (fs.lstatSync(filePath).isSymbolicLink()) {
        throw new Error("artifact must not be a symlink");
    }
    
    const relative = path.relative(root, filePath);
    
    if (relative !== 'STATUS.md' && (!relative.split(path.sep)[0] || !LANGUAGES.has(relative.split(path.sep)[0]))) {
        throw new Error("artifact is outside a language directory");
    }
    
    const data = fs.readFileSync(filePath);
    const hash = crypto.createHash('sha256').update(data).digest('hex');
    
    if (!state.ausstehende_veroeffentlichungen) {
        state.ausstehende_veroeffentlichungen = {};
    }
    state.ausstehende_veroeffentlichungen[relative] = hash;
}

function publishPending(root, state, save, token, options = {}) {
    const { opener = null, sync = null } = options;
    
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
        return (a[0] === 'STATUS.md' ? 0 : 1) - (b[0] === 'STATUS.md' ? 0 : 1);
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
            
            function lookup(remoteName) {
                const endpoint = "https://api.github.com/repos/KikiKari/OpenClaw/contents/" + encodeURIComponent(remoteName);
                
                return new Promise((resolve, reject) => {
                    const url = new URL(endpoint + "?ref=gateway1-abstractions");
                    const req = (url.protocol === 'https:' ? https : http).request({
                        hostname: url.hostname,
                        port: url.port,
                        path: url.pathname + url.search,
                        method: 'GET',
                        headers: headers
                    }, (response) => {
                        let data = '';
                        response.on('data', chunk => data += chunk);
                        response.on('end', () => {
                            if (response.statusCode === 404) {
                                resolve([endpoint, null]);
                            } else if (response.statusCode >= 200 && response.statusCode < 300) {
                                try {
                                    const jsonData = JSON.parse(data);
                                    resolve([endpoint, jsonData]);
                                } catch (err) {
                                    reject(err);
                                }
                            } else {
                                reject(new Error(`HTTP ${response.statusCode}: ${data}`));
                            }
                        });
                    });
                    
                    req.on('error', reject);
                    req.setTimeout(60000, () => {
                        req.destroy();
                        reject(new Error('Request timeout'));
                    });
                    req.end();
                });
            }
            
            function same(existing) {
                return (existing && typeof existing === 'object' && existing.encoding === "base64" &&
                       Buffer.from(existing.content || "", 'base64').equals(data));
            }
            
            lookup(name).then(([endpoint, existing]) => {
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
                    
                    return new Promise((resolve, reject) => {
                        const url = new URL(endpoint);
                        const req = (url.protocol === 'https:' ? https : http).request({
                            hostname: url.hostname,
                            port: url.port,
                            path: url.pathname,
                            method: 'PUT',
                            headers: {
                                ...headers,
                                'Content-Length': Buffer.byteLength(body),
                                'Content-Type': 'application/json'
                            }
                        }, (response) => {
                            let responseData = '';
                            response.on('data', chunk => responseData += chunk);
                            response.on('end', () => {
                                if (response.statusCode >= 200 && response.statusCode < 300) {
                                    try {
                                        JSON.parse(responseData);
                                        resolve();
                                    } catch (err) {
                                        reject(err);
                                    }
                                } else {
                                    reject(new Error(`HTTP ${response.statusCode}: ${responseData}`));
                                }
                            });
                        });
                        
                        req.on('error', reject);
                        req.setTimeout(60000, () => {
                            req.destroy();
                            reject(new Error('Request timeout'));
                        });
                        req.write(body);
                        req.end();
                    });
                } else if (existing !== null && !same(existing)) {
                    const candidate = path.parse(name);
                    const alternate = path.posix.join(
                        candidate.dir, 
                        `${candidate.name}_${expected.substring(0, 12)}${candidate.ext}`
                    );
                    
                    return lookup(alternate).then(([altEndpoint, altExisting]) => {
                        if (altExisting !== null && !same(altExisting)) {
                            throw new Error("remote artifact conflict");
                        }
                        return [altEndpoint, altExisting];
                    });
                }
                
                if (existing === null) {
                    const body = JSON.stringify({
                        "message": "Publish script abstraction",
                        "branch": "gateway1-abstractions",
                        "content": data.toString('base64')
                    });
                    
                    return new Promise((resolve, reject) => {
                        const url = new URL(endpoint);
                        const req = (url.protocol === 'https:' ? https : http).request({
                            hostname: url.hostname,
                            port: url.port,
                            path: url.pathname,
                            method: 'PUT',
                            headers: {
                                ...headers,
                                'Content-Length': Buffer.byteLength(body),
                                'Content-Type': 'application/json'
                            }
                        }, (response) => {
                            let responseData = '';
                            response.on('data', chunk => responseData += chunk);
                            response.on('end', () => {
                                if (response.statusCode >= 200 && response.statusCode < 300) {
                                    try {
                                        JSON.parse(responseData);
                                        resolve();
                                    } catch (err) {
                                        reject(err);
                                    }
                                } else {
                                    reject(new Error(`HTTP ${response.statusCode}: ${responseData}`));
                                }
                            });
                        });
                        
                        req.on('error', reject);
                        req.setTimeout(60000, () => {
                            req.destroy();
                            reject(new Error('Request timeout'));
                        });
                        req.write(body);
                        req.end();
                    });
                }
                
                return Promise.resolve();
            }).then(() => {
                delete pending[name];
                save(state);
            }).catch(error => {
                success = false;
                console.error(error);
            });
            
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
    synchronizeCheckout,
    updateStatusCounts,
    queueArtifact,
    publishPending,
    LANGUAGES
};
