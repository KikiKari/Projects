#!/usr/bin/env node
// test_multinode_fallback.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:scripts/test_multinode_fallback.py
// auch in: OpenClaw@gateway2:scripts/test_multinode_fallback.py
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

/**
 * Testet Multi-Node Fallback-Logik des db-maintainer
 * Simuliert: Worker-Node nicht erreichbar → Fallback auf lokal
 */

const { execSync } = require('child_process');
const path = require('path');

const WORKSPACE = '/home/openclaw/.openclaw/workspace';

function checkNodeReachable(nodeId) {
    /** Prüft ob Node erreichbar ist */
    try {
        // Versuche Node-Status abzufragen
        const result = execSync('openclaw nodes status', {
            timeout: 10000,
            encoding: 'utf8'
        });
        return result.includes(nodeId) && result.includes('connected');
    } catch (error) {
        return false;
    }
}

function spawnOnNode(nodeId, task) {
    /** Versucht Task auf Node auszuführen */
    console.log(`Versuche Task auf Node ${nodeId} zu starten...`);
    try {
        // Simuliert: openclaw agent spawn --node {nodeId}
        const result = execSync(`echo 'Spawned on ${nodeId}: ${task}'`, {
            timeout: 5000,
            encoding: 'utf8'
        });
        console.log(`✅ Erfolgreich delegiert an ${nodeId}`);
        return true;
    } catch (error) {
        console.log(`❌ Node ${nodeId} nicht erreichbar: ${error.message}`);
        return false;
    }
}

function executeLocally(task) {
    /** Führt Task lokal aus (Fallback) */
    console.log('🔄 Fallback: Führe Task lokal aus...');
    try {
        if (task === 'db_maintainer') {
            const scriptPath = path.join(WORKSPACE, 'skills', 'db-maintainer', 'scripts', 'db_maintainer.py');
            const result = execSync(`python3 ${scriptPath}`, {
                timeout: 60000,
                encoding: 'utf8'
            });
            console.log('✅ Lokale Ausführung erfolgreich');
            return true;
        }
    } catch (error) {
        console.log(`❌ Fehler: ${error.message.substring(0, 200)}`);
        return false;
    }
}

function main() {
    console.log('='.repeat(60));
    console.log('MULTI-NODE FALLBACK TEST');
    console.log('='.repeat(60));
    console.log();
    
    // Konfiguration
    const primaryNode = 'v2202603104722445775';  // Node 2
    const task = 'db_maintainer';
    
    console.log(`Primärer Node: ${primaryNode}`);
    console.log(`Task: ${task}`);
    console.log();
    
    // 1. Prüfe Node-Erreichbarkeit
    console.log('--- 1. Prüfe Node-Erreichbarkeit ---');
    if (checkNodeReachable(primaryNode)) {
        console.log(`✅ Node ${primaryNode} ist erreichbar`);
        
        // 2. Versuche Delegation
        console.log('\n--- 2. Versuche Delegation ---');
        if (spawnOnNode(primaryNode, task)) {
            console.log('\n✅ MULTI-NODE: Task erfolgreich delegiert');
            return 0;
        } else {
            console.log('\n⚠️ Delegation fehlgeschlagen, aktiviere Fallback...');
        }
    } else {
        console.log(`❌ Node ${primaryNode} nicht erreichbar`);
        console.log('🔄 Fallback wird aktiviert...');
    }
    
    // 3. Lokale Ausführung (Fallback)
    console.log('\n--- 3. Lokale Ausführung (Fallback) ---');
    if (executeLocally(task)) {
        console.log('\n✅ FALLBACK: Task lokal erfolgreich ausgeführt');
        return 0;
    } else {
        console.log('\n❌ FEHLER: Weder Delegation noch Fallback erfolgreich');
        return 1;
    }
}

process.exit(main());
