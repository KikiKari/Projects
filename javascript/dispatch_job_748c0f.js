#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "2caa3ee592cbfe64c02a4cf84b27410a584076ff32771bfff9dac200a7850a26", "source_sha256": "748c0fc07a58caf07d4983d358cf0e1ce57c4e180b87ae617d598f53c61efcec", "target_language": "javascript"}
// dispatch_job.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/**
 * Job Dispatcher - Verteilt Jobs auf passende Nodes
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const crypto = require('crypto');

function _jobWeightBytes(scriptPath, targetLangsCount) {
    /** Arbeitsvolumen: Dateigröße × Anzahl der Zielsprachen. */
    const stats = fs.statSync(scriptPath);
    return stats.size * targetLangsCount;
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

function fetchNodeStatus() {
    /** Return mapped OpenClaw connection states; None indicates lookup failure. */
    try {
        const result = spawnSync("openclaw", ["nodes", "status", "--json"], {
            timeout: 10000,
            encoding: 'utf8'
        });
        
        if (result.error || result.status !== 0) {
            return null;
        }
        
        const payload = JSON.parse(result.stdout);
        if (!payload || !Array.isArray(payload.nodes)) {
            return null;
        }
        
        const states = {};
        Object.keys(NODE_NAMES).forEach(node => {
            states[node] = false;
        });
        
        for (const item of payload.nodes) {
            if (typeof item !== 'object' || item === null) {
                continue;
            }
            
            const names = new Set([
                String(item.displayName || "").toLowerCase(),
                String(item.nodeId || "").toLowerCase(),
                String(item.remoteIp || "").toLowerCase()
            ]);
            
            for (const [node, aliases] of Object.entries(NODE_NAMES)) {
                for (const alias of aliases) {
                    if (names.has(alias.toLowerCase())) {
                        if (item.connected === true) {
                            states[node] = true;
                        }
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
    
    getJobWeight(scriptPath, targetLangsCount = 1) {
        /** Bewertet Job-Gewicht */
        if (!fs.existsSync(scriptPath)) {
            return "medium";
        }
        
        const totalWork = _jobWeightBytes(scriptPath, targetLangsCount);
        
        if (totalWork > 50000) {  // > 50KB
            return "heavy";
        } else if (totalWork > 10000) {  // > 10KB
            return "medium";
        } else {
            return "light";
        }
    }
    
    selectNode(jobWeight) {
        /** Wählt besten Node basierend auf Job-Gewicht */
        
        let preferred;
        if (jobWeight === "heavy") {
            preferred = ["node1", "node2", "node5", "node6"];
        } else if (jobWeight === "medium") {
            preferred = ["node1", "node2", "node3", "node6"];
        } else if (jobWeight === "light") {
            preferred = ["node2", "node1", "node3", "node4"];
        } else {
            throw new Error(`Unknown job weight: ${jobWeight}`);
        }

        const states = fetchNodeStatus();
        for (const nodeId of preferred) {
            if (states && states[nodeId] === true) {
                return nodeId;
            }
        }
        return null; // no verified reachable node
    }

    checkNodeAvailable(nodeId) {
        /** Use the live connection state rather than static availability. */
        const states = fetchNodeStatus();
        return Boolean(states && states[nodeId] === true);
    }

    executeTranslation(job, transport) {
        return executeTranslation(job, transport);
    }

    _checkMobileOnline() {
        /** Check Node4 (Redmi). */
        return this.checkNodeAvailable("node4");
    }

    dispatch(jobScript, targetLangs = null, sourceText = null, sourceLanguage = null) {
        /** Dispatched Job und gibt Info zurück */
        if (targetLangs === null) {
            targetLangs = ["perl5"];
        }
        
        const weight = this.getJobWeight(jobScript, targetLangs.length);
        const selectedNode = this.selectNode(weight);
        const translationJobs = [];
        
        for (const language of targetLangs) {
            const job = {
                "job_id": crypto.randomUUID(),
                "source": jobScript,
                "target_language": language,
                "selected_node": selectedNode,
            };
            
            if (sourceText !== null) {
                job.source_text = sourceText;
            }
            if (sourceLanguage !== null) {
                job.source_language = sourceLanguage;
            }
            translationJobs.push(job);
        }
        
        return {
            "job": jobScript,
            "weight": weight,
            "selected_node": selectedNode,
            "target_langs": targetLangs,
            "translation_jobs": translationJobs,
            "status": selectedNode ? "selected" : "unavailable"
        };
    }
}

function executeTranslation(job, transport) {
    /** Execute via a supplied transport and verify its result belongs to the job. */
    if (!job.selected_node || transport === null) {
        throw new Error("no verified node or authorized translation transport");
    }
    const response = transport(job);
    if (typeof response !== 'object' || response === null) {
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

function dispatchAbstractionJob(jobScript, targetLangs) {
    /** Erstellt eine Node-Auswahl und je (Skript, Sprache) einen Auftrag. */
    const dispatcher = new JobDispatcher();
    return dispatcher.dispatch(jobScript, targetLangs);
}

function main() {
    const { program } = require('commander');
    
    program
        .description("Dispatch job to optimal node")
        .option("--job <path>", "Path to job script")
        .option("--langs <languages>", "Comma-separated target languages", "perl5")
        .option("--weight <weight>", "Force job weight", /^(light|medium|heavy)$/i)
        .option("--execute", "Actually execute on selected node")
        .parse();
    
    const options = program.opts();
    
    if (!options.job) {
        console.error("❌ Job path is required");
        process.exit(1);
    }
    
    const jobPath = options.job;
    if (!fs.existsSync(jobPath)) {
        console.error(`❌ Job not found: ${jobPath}`);
        process.exit(1);
    }
    
    const dispatcher = new JobDispatcher();
    const targetLangs = options.langs.split(",");
    
    // Determine weight
    let weight;
    if (options.weight) {
        weight = options.weight;
    } else {
        weight = dispatcher.getJobWeight(jobPath, targetLangs.length);
    }
    
    // Select node
    const selectedNode = dispatcher.selectNode(weight);
    
    // Output
    console.log("📦 Job Dispatch Information");
    console.log("=".repeat(50));
    console.log(`Job: ${jobPath}`);
    console.log(`Size: ${fs.statSync(jobPath).size} bytes`);
    console.log(`Target langs: ${targetLangs.join(", ")}`);
    console.log(`Job weight: ${weight}`);
    console.log(`Selected node: ${selectedNode}`);
    console.log("=".repeat(50));
    
    if (options.execute) {
        console.error(`\nTranslation dispatch on ${selectedNode} is not implemented.`);
        process.exit(1);
    } else {
        console.log(`\n💡 To execute: node ${process.argv[1]} --job ${options.job} --execute`);
    }
    process.exit(0);
}

if (require.main === module) {
    main();
}

module.exports = {
    JobDispatcher,
    dispatchAbstractionJob,
    executeTranslation
};
