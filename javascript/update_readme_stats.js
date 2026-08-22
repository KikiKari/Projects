#!/usr/bin/env node
// update_readme_stats.py — portiert nach javascript
// Quelle: python, OpenClaw@main:scripts/update_readme_stats.py
// Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

/** Fetch ClawHub stats and update README.md download counts and security status. */

const fs = require('fs');
const https = require('https');

const API_BASE = "https://clawhub.ai/api/v1";
const TOKEN = process.env.CLAWHUB_TOKEN || "";

const SKILLS = [
    ["Cluster Gateway",           "cluster-gateway"],
    ["MCP Tool Utils",            "mcp-tool-utils"],
    ["Reports Creator",           "reports-creator"],
    ["Relay Node",                "relay-node"],
    ["JSON Utils",                "json-utils"],
    ["Log Collector",             "log-collector"],
    ["TikTok Live Monitor",       "tiktok-live-monitor"],
    ["Doc Scraper",               "doc-scraper"],
    ["Workspace Database Manager","workspace-database-manager"],
    ["Scripting Utils",           "scripting-utils"],
];

function fetchSkill(slug) {
    return new Promise((resolve, reject) => {
        const url = `${API_BASE}/skills/${slug}`;
        const options = {
            headers: {
                'Accept': 'application/json'
            }
        };
        if (TOKEN) {
            options.headers.Authorization = `Bearer ${TOKEN}`;
        }
        
        https.get(url, options, (res) => {
            let data = '';
            res.on('data', (chunk) => {
                data += chunk;
            });
            res.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (err) {
                    reject(err);
                }
            });
        }).on('error', (err) => {
            reject(err);
        }).setTimeout(10000, () => {
            reject(new Error('Request timeout'));
        });
    });
}

function parseSkill(data) {
    const skill = data.skill || {};
    const stats = skill.stats || {};
    const versionData = data.latestVersion || {};
    const version = versionData.version || "1.0.0";
    const mod = data.moderation;

    const downloads = stats.downloads || 0;

    let security = "✅ Pass";
    if (mod === null || mod === undefined) {
        security = "✅ Pass";
    } else if (mod.isMalwareBlocked) {
        security = "🚫 Blocked";
    } else {
        security = "🔍 Review";
    }

    return {
        downloads: downloads,
        version: version.startsWith("v") ? version : `v${version}`,
        security: security,
    };
}

async function main() {
    const stats = {};
    let errors = 0;
    
    for (const [name, slug] of SKILLS) {
        try {
            const data = await fetchSkill(slug);
            const s = parseSkill(data);
            stats[slug] = s;
            console.log(`  OK  ${slug}: ${s.downloads} downloads, ${s.version}, ${s.security}`);
        } catch (exc) {
            console.error(`  ERR ${slug}: ${exc}`);
            errors++;
        }
    }

    if (Object.keys(stats).length === 0) {
        console.error("No data fetched — aborting.");
        process.exit(1);
    }

    let content = fs.readFileSync("README.md", "utf-8");

    for (const [name, slug] of SKILLS) {
        if (!(slug in stats)) {
            continue;
        }
        const dl = stats[slug].downloads;
        const escapedName = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        const pattern = new RegExp(`(\\|\\s*\\[?${escapedName}\\]?[^|]*\\|[^|]*\\|)\\s*\\d+\\s*(\\|)`, 'i');
        const replacement = `$1 ${dl} $2`;
        const newContent = content.replace(pattern, replacement);
        if (newContent !== content) {
            content = newContent;
            console.log(`  Updated: ${name} -> ${dl}`);
        }
    }

    fs.writeFileSync("README.md", content, "utf-8");
    console.log(`Done: ${Object.keys(stats).length} skills, ${errors} errors.`);
}

main().catch(err => {
    console.error(err);
    process.exit(1);
});
