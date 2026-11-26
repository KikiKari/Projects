#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "06dfddeef59bf5e2dc96ba00bc35e1f2f96c251653a4e076fb41d3d6aeefc7e3", "source_sha256": "128b137e5c7d86f81ea7fdb61718540c70e4ed38de4430ae6a23a5739962c024", "target_language": "javascript"}
// dispatch_job.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/**
 * Job Dispatcher - Verteilt Jobs auf passende Nodes
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

// Node-Konfiguration
const NODES = {
    "node1": { "always_available": true, "capacity": "medium", "priority": 2 },
    "node2": { "always_available": true, "capacity": "medium", "priority": 3 },
    "node3": { "always_available": false, "capacity": "medium", "priority": 4 },
    "node5": { "always_available": false, "capacity": "low", "priority": 5, "device": "Redmi Note 11S" },
    "node7": { "always_available": true, "capacity": "high", "priority": 1 }
};

class JobDispatcher {
    /** Bewertet Job-Gewicht */
    getJobWeight(scriptPath, targetLangsCount = 1) {
        if (!fs.existsSync(scriptPath)) {
            return "medium";
        }
        
        const stats = fs.statSync(scriptPath);
        const scriptSize = stats.size;
        const totalWork = scriptSize * targetLangsCount;
        
        if (totalWork > 50000) {  // > 50KB
            return "heavy";
        } else if (totalWork > 10000) {  // > 10KB
            return "medium";
        } else {
            return "light";
        }
    }
    
    /** Wählt besten Node basierend auf Job-Gewicht */
    selectNode(jobWeight) {
        let preferred = [];
        
        if (jobWeight === "heavy") {
            // Schwere Jobs → Node 7 (Docker), dann Node 2, dann Node 1
            preferred = ["node7", "node2", "node1"];
        } else if (jobWeight === "medium") {
            // Mittlere Jobs → Stable Nodes
            preferred = ["node2", "node1", "node7"];
        } else {  // light
            // Leichte Jobs → Mobile/verfügbare Nodes
            preferred = ["node5", "node1", "node2"];
        }
        
        // Prüfe Verfügbarkeit
        for (const nodeId of preferred) {
            if (this.checkNodeAvailable(nodeId)) {
                return nodeId;
            }
        }
        
        // Fallback
        return "node1";
    }
    
    /** Prüft ob Node erreichbar ist */
    checkNodeAvailable(nodeId) {
        if (!NODES[nodeId]) {
            return false;
        }
        
        const node = NODES[nodeId];
        
        // Nicht immer-verfügbare Nodes nur wenn explizit requested
        if (!node.always_available) {
            // Für light-jobs prüfen wir ob online
            if (nodeId === "node5") {  // Redmi
                return this._checkMobileOnline();
            }
            return false;
        }
        
        // Für immer-verfügbare Nodes: prüfe ob wirklich online
        try {
            const result = spawnSync("openclaw", ["nodes", "status", nodeId], {
                timeout: 3000
            });
            return result.status === 0;
        } catch (error) {
            return !!node.always_available;
        }
    }
    
    /** Prüft ob Redmi (Node 5) Internet hat */
    _checkMobileOnline() {
        try {
            const result = spawnSync("openclaw", ["nodes", "status", "node5"], {
                timeout: 5000
            });
            return result.status === 0 && result.stdout.toString().toLowerCase().includes("online");
        } catch (error) {
            return false;
        }
    }
    
    /** Dispatched Job und gibt Info zurück */
    dispatch(jobScript, targetLangs = null) {
        if (targetLangs === null) {
            targetLangs = ["perl5"];
        }
        
        const weight = this.getJobWeight(jobScript, targetLangs.length);
        const selectedNode = this.selectNode(weight);
        
        return {
            "job": jobScript,
            "weight": weight,
            "selected_node": selectedNode,
            "target_langs": targetLangs,
            "status": "dispatched"
        };
    }
}

function main() {
    const args = process.argv.slice(2);
    let jobPath = "";
    let langs = "perl5";
    let weight = "";
    let execute = false;
    
    // Simple argument parsing
    for (let i = 0; i < args.length; i++) {
        if ((args[i] === "--job" || args[i] === "-j") && i + 1 < args.length) {
            jobPath = args[++i];
        } else if ((args[i] === "--langs" || args[i] === "-l") && i + 1 < args.length) {
            langs = args[++i];
        } else if ((args[i] === "--weight" || args[i] === "-w") && i + 1 < args.length) {
            weight = args[++i];
        } else if (args[i] === "--execute" || args[i] === "-x") {
            execute = true;
        }
    }
    
    if (!jobPath) {
        console.error("❌ Job path is required");
        process.exit(1);
    }
    
    if (!fs.existsSync(jobPath)) {
        console.error(`❌ Job not found: ${jobPath}`);
        process.exit(1);
    }
    
    const dispatcher = new JobDispatcher();
    const targetLangs = langs.split(",");
    
    // Determine weight
    if (!weight) {
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
    
    if (execute) {
        console.log(`\n🚀 Executing on ${selectedNode}...`);
        // TODO: Implement remote execution
        console.log("(Remote execution not yet implemented)");
    } else {
        console.log(`\n💡 To execute: node ${process.argv[1]} --job ${jobPath} --execute`);
    }
}

if (require.main === module) {
    main();
}

module.exports = { JobDispatcher };
