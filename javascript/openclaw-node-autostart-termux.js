#!/data/data/com.termux/files/usr/bin/node
// openclaw-node-autostart-termux.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

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
    const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
    const logEntry = `[${timestamp}] ${message}`;
    fs.appendFileSync(LOGFILE, logEntry + '\n');
    return logEntry;
}

// Prüfen ob tmux Session bereits läuft
try {
    execSync(`tmux has-session -t ${SESSION}`, { stdio: 'ignore' });
    console.log(logMessage(`OpenClaw Node läuft bereits in tmux Session '${SESSION}'`));
    process.exit(0);
} catch (error) {
    // Session existiert nicht, fortfahren
}

// Neue tmux Session erstellen und OpenClaw starten
const sessionCommand = `
    while true; do
        echo '[${new Date().toISOString().replace('T', ' ').substring(0, 19)}] Starting OpenClaw Node Mode...' | tee -a '${LOGFILE}'
        
        # Prüfe WireGuard Verbindung
        if ! ping -c 1 -W 3 ${GATEWAY} >/dev/null 2>&1; then
            echo '[${new Date().toISOString().replace('T', ' ').substring(0, 19)}] FEHLER: WireGuard Gateway ${GATEWAY} nicht erreichbar!' | tee -a '${LOGFILE}'
            echo '[${new Date().toISOString().replace('T', ' ').substring(0, 19)}] Warte 10 Sekunden...' | tee -a '${LOGFILE}'
            sleep 10
            continue
        fi
        
        # OpenClaw Node Mode starten
        openclaw node run --host ${GATEWAY} --port ${PORT} 2>&1 | tee -a '${LOGFILE}'
        
        # Wenn der Prozess endet, warte und neustarten
        echo '[${new Date().toISOString().replace('T', ' ').substring(0, 19)}] OpenClaw beendet. Neustart in 5 Sekunden...' | tee -a '${LOGFILE}'
        sleep 5
    done
`;

const tmuxProcess = spawn('tmux', [
    'new-session', '-d', '-s', SESSION, '-n', 'node', sessionCommand
]);

tmuxProcess.on('close', (code) => {
    logMessage(`OpenClaw Node Autostart aktiviert (tmux Session: ${SESSION})`);
});

// Optional: tmux attach Hinweis falls interaktiv gestartet
if (process.stdout.isTTY) {
    console.log(`OpenClaw Node Mode gestartet in tmux Session '${SESSION}'`);
    console.log(`Zum Anschauen: tmux attach -t ${SESSION}`);
    console.log(`Log-Datei: ${LOGFILE}`);
}
