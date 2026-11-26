#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "214e79693c99db50c8a5c34ee3b73b2c2c09acbca5a3f7c1f1b08be78bd34229", "source_sha256": "5a841c728d9c1585b5c3191e88fdd38cf887a0d51560ce803b8c0172412bef3d", "target_language": "javascript"}
// check_nodes.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
// auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/**
 * Node-Status Checker - Prüft Verfügbarkeit aller Nodes
 */

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Node-Konfiguration (sollte aus config file geladen werden)
const NODES = {
    "node1": {
        "always_available": true,
        "capacity": "medium",
        "priority": 2,
        "description": "Gateway-Master"
    },
    "node2": {
        "always_available": true,
        "capacity": "medium",
        "priority": 3,
        "description": "Stable Worker"
    },
    "node3": {
        "always_available": false,
        "capacity": "medium",
        "priority": 4,
        "description": "Bald verfügbar (nach Reorganisation)"
    },
    "node5": {
        "always_available": false,
        "capacity": "low",
        "priority": 5,
        "device": "Redmi Note 11S",
        "description": "Mobile (bei Internet verfügbar)"
    },
    "node7": {
        "always_available": true,
        "capacity": "high",
        "priority": 1,
        "description": "Docker Hauptarbeitspferd (bald verfügbar)"
    },
};

/**
 * Prüft Status eines einzelnen Nodes
 */
function checkNodeStatus(nodeId) {
    try {
        const result = spawnSync("openclaw", ["nodes", "status", nodeId], {
            encoding: 'utf8',
            timeout: 5000
        });
        
        const isOnline = result.status === 0 && (
            result.stdout.toLowerCase().includes("online") || 
            result.stdout.toLowerCase().includes("active")
        );
        
        return {
            id: nodeId,
            online: isOnline,
            available: NODES[nodeId]?.always_available || false,
            response: result.stdout ? result.stdout.trim().substring(0, 100) : "No response"
        };
    } catch (error) {
        if (error.code === 'ETIMEDOUT') {
            return {
                id: nodeId,
                online: false,
                available: NODES[nodeId]?.always_available || false,
                response: "Timeout"
            };
        } else {
            return {
                id: nodeId,
                online: false,
                available: NODES[nodeId]?.always_available || false,
                response: `Error: ${error.message}`
            };
        }
    }
}

/**
 * Gibt Node-Status als Tabelle aus
 */
function printTable(nodesStatus) {
    console.log("\n" + "=".repeat(90));
    console.log(`${"Node".padEnd(8)} ${"Status".padEnd(12)} ${"Verfügbar".padEnd(12)} ${"Kapazität".padEnd(10)} ${"Priorität".padEnd(10)} Gerät/Beschreibung`);
    console.log("=".repeat(90));
    
    for (const status of nodesStatus) {
        const nodeId = status.id;
        const config = NODES[nodeId];
        
        const statusIcon = status.online ? "🟢 Online" : "🔴 Offline";
        const availIcon = status.available ? "✅ Immer" : "📱 Bedingt";
        const capacity = config.capacity || "unknown";
        const priority = config.priority || "-";
        const device = config.device || config.description || "";
        
        console.log(
            `${nodeId.padEnd(8)} ${statusIcon.padEnd(12)} ${availIcon.padEnd(12)} ${capacity.padEnd(10)} ${String(priority).padEnd(10)} ${device}`
        );
    }
    
    console.log("=".repeat(90));
    console.log(`\nGeprüft am: ${new Date().toLocaleString('de-DE')}`);
}

/**
 * Gibt Node-Status als JSON aus
 */
function printJson(nodesStatus) {
    const output = {
        timestamp: new Date().toISOString(),
        nodes: {}
    };
    
    for (const status of nodesStatus) {
        const nodeId = status.id;
        output.nodes[nodeId] = {
            status: status,
            config: NODES[nodeId]
        };
    }
    
    console.log(JSON.stringify(output, null, 2));
}

function main() {
    const args = process.argv.slice(2);
    let format = "table";
    let saveFile = null;
    
    // Parse arguments
    for (let i = 0; i < args.length; i++) {
        if (args[i] === "--format" || args[i] === "-f") {
            format = args[i + 1] || "table";
            i++;
        } else if (args[i] === "--save" || args[i] === "-s") {
            saveFile = args[i + 1];
            i++;
        }
    }
    
    console.log("🔍 Prüfe Node-Status...");
    
    // Prüfe alle Nodes
    const nodesStatus = [];
    const sortedNodeIds = Object.keys(NODES).sort();
    
    for (const nodeId of sortedNodeIds) {
        process.stdout.write(`  → ${nodeId}... `);
        const status = checkNodeStatus(nodeId);
        nodesStatus.push(status);
        console.log(status.online ? "✓" : "✗");
    }
    
    // Ausgabe
    if (format === "table") {
        printTable(nodesStatus);
    } else {
        printJson(nodesStatus);
    }
    
    // Speichern
    if (saveFile) {
        const output = {
            timestamp: new Date().toISOString(),
            nodes: {}
        };
        
        for (const status of nodesStatus) {
            output.nodes[status.id] = status;
        }
        
        fs.writeFileSync(saveFile, JSON.stringify(output, null, 2));
        console.log(`\n💾 Gespeichert: ${saveFile}`);
    }
    
    // Zusammenfassung
    const onlineCount = nodesStatus.filter(s => s.online).length;
    console.log(`\n📊 Zusammenfassung: ${onlineCount}/${nodesStatus.length} Nodes online`);
}

main();
