#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "cd2124c5dc1eeb0b48f107f14d101048385f273feee3ce963664855d23ab82a8", "source_sha256": "dd115a5287b5db772bd4af098a6620a66b294c0e327633048101753a48a3976b", "target_language": "javascript"}
// openclaw-node-autostart-termux.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const { spawn, execSync } = require('child_process');
const path = require('path');

const SESSION = "openclaw-node";
const LOGFILE = path.join(process.env.HOME, ".openclaw", "node.log");
const GATEWAY = "10.10.0.1";
const PORT = "18789";

// Log-Verzeichnis erstellen
const logDir = path.dirname(LOGFILE);
if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
}

function logMessage(message) {
    const timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
    const logEntry = `[${timestamp}] ${message}\n`;
    fs.appendFileSync(LOGFILE, logEntry);
    return logEntry.trim();
}

// Prüfen ob tmux Session bereits läuft
try {
    execSync(`tmux has-session -t "${SESSION}"`, { stdio: 'ignore' });
    console.log(logMessage(`OpenClaw Node läuft bereits in tmux Session '${SESSION}'`));
    process.exit(0);
} catch (error) {
    // Session existiert nicht, fortfahren
}

// Neue tmux Session erstellen und OpenClaw starten
const sessionCommand = `
    while true; do
        echo '[${new Date().toISOString()}] Starting OpenClaw Node Mode...' | tee -a '${LOGFILE}'
        
        # Prüfe WireGuard Verbindung
        if ! ping -c 1 -W 3 ${GATEWAY} >/dev/null 2>&1; then
            echo '[${new Date().toISOString()}] FEHLER: WireGuard Gateway ${GATEWAY} nicht erreichbar!' | tee -a '${LOGFILE}'
            echo '[${new Date().toISOString()}] Warte 10 Sekunden...' | tee -a '${LOGFILE}'
            sleep 10
            continue
        fi
        
        # OpenClaw Node Mode starten
        openclaw node run --host ${GATEWAY} --port ${PORT} 2>&1 | tee -a '${LOGFILE}'
        
        # Wenn der Prozess endet, warte und neustarten
        echo '[${new Date().toISOString()}] OpenClaw beendet. Neustart in 5 Sekunden...' | tee -a '${LOGFILE}'
        sleep 5
    done
`;

const tmuxProcess = spawn('tmux', [
    'new-session', '-d', '-s', SESSION, '-n', 'node', sessionCommand
]);

tmuxProcess.on('close', (code) => {
    logMessage(`OpenClaw Node Autostart aktiviert (tmux Session: ${SESSION})`);
    
    // Optional: tmux attach Hinweis falls interaktiv gestartet
    if (process.stdin.isTTY) {
        console.log(`OpenClaw Node Mode gestartet in tmux Session '${SESSION}'`);
        console.log(`Zum Anschauen: tmux attach -t ${SESSION}`);
        console.log(`Log-Datei: ${LOGFILE}`);
    }
});
