#!/usr/bin/env node
// dispatch_job.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
// Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

/**
 * Job Dispatcher - Verteilt Jobs auf passende Nodes
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const crypto = require('crypto');

function _job_weight_bytes(script_path, target_langs_count) {
    /** Arbeitsvolumen: Dateigröße × Anzahl der Zielsprachen. */
    const stats = fs.statSync(script_path);
    return stats.size * target_langs_count;
}

// Node-Konfiguration
const NODES = {
    "node1": {"always_available": true, "capacity": "medium", "priority": 3, "description": "Gateway"},
    "node2": {"always_available": false, "capacity": "high", "priority": 1, "description": "ARM Server"},
    "node3": {"always_available": false, "capacity": "medium", "priority": 4, "description": "AMD Server"},
    "node4": {"always_available": false, "capacity": "low", "priority": 5, "device": "Redmi Note 11S"},
    "node5": {"always_available": false, "capacity": "high", "priority": 2, "device": "Lenovo"},
    "node6": {"always_available": false, "device": "Lenovo (Docker)"},
};

const NODE_NAMES = {
    "node2": new Set(["openclaw-node2", "arm64-node", "v2202604104722449961", "v2202604104722449961.taild25fea.ts.net", "100.82.198.122"]),
    "node3": new Set(["openclaw-node3", "openclaw-node3.taild25fea.ts.net", "100.73.154.125"]),
    "node4": new Set(["openclaw-node4", "redmi-note-11s", "redmi-note-11s.taild25fea.ts.net", "100.94.134.39"]),
    "node5": new Set(["openclaw-node5", "windows node (lenovo-7)"]),
    "node6": new Set(["openclaw-node6"]),
};

function fetch_node_status() {
    /** Return mapped OpenClaw connection states; None indicates lookup failure. */
    try {
        const result = spawnSync("openclaw", ["nodes", "status", "--json"], {
            encoding: 'utf-8',
            timeout: 10000
        });
        
        if (result.error || result.status !== 0) {
            return null;
        }
        
        const payload = JSON.parse(result.stdout);
        if (typeof payload !== 'object' || !Array.isArray(payload.nodes)) {
            return null;
        }
        
        const states = {};
        for (const node of Object.keys(NODE_NAMES)) {
            states[node] = false;
        }
        
        for (const item of payload.nodes) {
            if (typeof item !== 'object') {
                continue;
            }
            
            const names = new Set([
                String(item.displayName || "").toLowerCase(),
                String(item.nodeId || "").toLowerCase(),
                String(item.remoteIp || "").toLowerCase()
            ]);
            
            for (const [node, aliases] of Object.entries(NODE_NAMES)) {
                for (const alias of aliases) {
                    if (names.has(alias.toLowerCase()) && item.connected === true) {
                        states[node] = true;
                        break;
                    }
                }
            }
        }
        
        states.node1 = true; // successful Gateway status request
        return states;
    } catch (error) {
        return null;
    }
}

class JobDispatcher {
    /** Dispatches jobs to appropriate nodes based on weight */
    
    get_job_weight(script_path, target_langs_count = 1) {
        /** Bewertet Job-Gewicht */
        if (!fs.existsSync(script_path)) {
            return "medium";
        }
        
        const total_work = _job_weight_bytes(script_path, target_langs_count);
        
        if (total_work > 50000) {  // > 50KB
            return "heavy";
        } else if (total_work > 10000) {  // > 10KB
            return "medium";
        } else {
            return "light";
        }
    }
    
    select_node(job_weight) {
        /** Wählt besten Node basierend auf Job-Gewicht */
        
        let preferred;
        if (job_weight === "heavy") {
            preferred = ["node1", "node2", "node5", "node6"];
        } else if (job_weight === "medium") {
            preferred = ["node1", "node2", "node3", "node6"];
        } else if (job_weight === "light") {
            preferred = ["node2", "node1", "node3", "node4"];
        } else {
            throw new Error(`Unknown job weight: ${job_weight}`);
        }

        const states = fetch_node_status();
        for (const node_id of preferred) {
            if (states && states[node_id] === true) {
                return node_id;
            }
        }
        return null; // no verified reachable node
    }

    check_node_available(node_id) {
        /** Use the live connection state rather than static availability. */
        const states = fetch_node_status();
        return Boolean(states && states[node_id] === true);
    }

    execute_translation(job, transport) {
        return execute_translation(job, transport);
    }

    _check_mobile_online() {
        /** Check Node4 (Redmi). */
        return this.check_node_available("node4");
    }

    dispatch(job_script, target_langs = null, source_text = null, source_language = null) {
        /** Dispatched Job und gibt Info zurück */
        if (target_langs === null) {
            target_langs = ["perl5"];
        }
        
        const weight = this.get_job_weight(job_script, target_langs.length);
        const selected_node = this.select_node(weight);
        const translation_jobs = [];
        
        for (const language of target_langs) {
            const job = {
                "job_id": crypto.randomUUID(),
                "source": job_script,
                "target_language": language,
                "selected_node": selected_node,
            };
            
            if (source_text !== null) {
                job.source_text = source_text;
            }
            if (source_language !== null) {
                job.source_language = source_language;
            }
            translation_jobs.push(job);
        }
        
        return {
            "job": job_script,
            "weight": weight,
            "selected_node": selected_node,
            "target_langs": target_langs,
            "translation_jobs": translation_jobs,
            "status": selected_node ? "selected" : "unavailable"
        };
    }
}

function execute_translation(job, transport) {
    /** Execute via a supplied transport and verify its result belongs to the job. */
    if (!job.selected_node || transport === null) {
        throw new Error("no verified node or authorized translation transport");
    }
    const response = transport(job);
    if (typeof response !== 'object') {
        throw new Error("invalid transport response");
    }
    for (const key of ["job_id", "selected_node", "target_language"]) {
        if (response[key] !== job[key]) {
            throw new Error("transport response does not match job");
        }
    }
    const code = response.code;
    if (response.status !== "ok" || typeof code !== 'string' || !code.trim()) {
        throw new Error("translation did not complete with code");
    }
    return code;
}

function dispatch_abstraction_job(job_script, target_langs) {
    /** Erstellt eine Node-Auswahl und je (Skript, Sprache) einen Auftrag. */
    const dispatcher = new JobDispatcher();
    return dispatcher.dispatch(job_script, target_langs);
}

function main() {
    const args = process.argv.slice(2);
    let jobPath = null;
    let langs = "perl5";
    let weight = null;
    let execute = false;
    
    // Simple argument parsing
    for (let i = 0; i < args.length; i++) {
        if (args[i] === "--job" || args[i] === "-j") {
            jobPath = args[++i];
        } else if (args[i] === "--langs" || args[i] === "-l") {
            langs = args[++i];
        } else if (args[i] === "--weight" || args[i] === "-w") {
            weight = args[++i];
        } else if (args[i] === "--execute" || args[i] === "-x") {
            execute = true;
        }
    }
    
    if (!jobPath) {
        console.error("Usage: node dispatch_job.js --job <job-script> [--langs <languages>] [--weight <weight>] [--execute]");
        process.exit(1);
    }
    
    if (!fs.existsSync(jobPath)) {
        console.error(`❌ Job not found: ${jobPath}`);
        process.exit(1);
    }
    
    const dispatcher = new JobDispatcher();
    const target_langs = langs.split(",");
    
    // Determine weight
    if (weight) {
        weight = weight;
    } else {
        weight = dispatcher.get_job_weight(jobPath, target_langs.length);
    }
    
    // Select node
    const selected_node = dispatcher.select_node(weight);
    
    // Output
    console.log("📦 Job Dispatch Information");
    console.log("=".repeat(50));
    const stats = fs.statSync(jobPath);
    console.log(`Job: ${jobPath}`);
    console.log(`Size: ${stats.size} bytes`);
    console.log(`Target langs: ${target_langs.join(", ")}`);
    console.log(`Job weight: ${weight}`);
    console.log(`Selected node: ${selected_node}`);
    console.log("=".repeat(50));
    
    if (execute) {
        console.error(`\nTranslation dispatch on ${selected_node} is not implemented.`);
        return 1;
    } else {
        console.log(`\n💡 To execute: node ${process.argv[1]} --job ${jobPath} --execute`);
    }
    return 0;
}

if (require.main === module) {
    process.exit(main());
}

module.exports = { JobDispatcher, dispatch_abstraction_job, execute_translation };
