<?php
// abstraction-provenance: {"artifact_sha256": "02779a572aa00aa9c55f0a766fc5f2bed0a6dd6d1b96168dd5dd57e60c48dac9", "source_sha256": "dd115a5287b5db772bd4af098a6620a66b294c0e327633048101753a48a3976b", "target_language": "php"}
// openclaw-node-autostart-termux.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
// OpenClaw Node Mode Autostart für Termux (Node 5 - Redmi Note 11)
// Installiert nach: ~/.termux/boot/openclaw-node.php
// Getestet mit: Termux + Android + OpenClaw

$SESSION = "openclaw-node";
$LOGFILE = $_SERVER['HOME'] . "/.openclaw/node.log";
$GATEWAY = "10.10.0.1";
$PORT = "18789";

// Log-Verzeichnis erstellen
@mkdir($_SERVER['HOME'] . "/.openclaw", 0755, true);

// Prüfen ob tmux Session bereits läuft
exec("tmux has-session -t " . escapeshellarg($SESSION), $output, $return_var);
if ($return_var === 0) {
    file_put_contents($LOGFILE, "[" . date("Y-m-d H:i:s") . "] OpenClaw Node läuft bereits in tmux Session '$SESSION'\n", FILE_APPEND);
    exit(0);
}

// Neue tmux Session erstellen und OpenClaw starten
$cmd = "tmux new-session -d -s " . escapeshellarg($SESSION) . " -n \"node\" \"while true; do
    echo '[\$(date)] Starting OpenClaw Node Mode...' | tee -a '$LOGFILE';
    
    # Prüfe WireGuard Verbindung
    if ! ping -c 1 -W 3 $GATEWAY >/dev/null 2>&1; then
        echo '[\$(date)] FEHLER: WireGuard Gateway $GATEWAY nicht erreichbar!' | tee -a '$LOGFILE';
        echo '[\$(date)] Warte 10 Sekunden...' | tee -a '$LOGFILE';
        sleep 10;
        continue;
    fi;
    
    # OpenClaw Node Mode starten
    openclaw node run --host $GATEWAY --port $PORT 2>&1 | tee -a '$LOGFILE';
    
    # Wenn der Prozess endet, warte und neustarten
    echo '[\$(date)] OpenClaw beendet. Neustart in 5 Sekunden...' | tee -a '$LOGFILE';
    sleep 5;
done\"";

exec($cmd);

file_put_contents($LOGFILE, "[" . date("Y-m-d H:i:s") . "] OpenClaw Node Autostart aktiviert (tmux Session: $SESSION)\n", FILE_APPEND);

// Optional: tmux attach Hinweis falls interaktiv gestartet
if (function_exists('posix_isatty') && posix_isatty(STDOUT)) {
    echo "OpenClaw Node Mode gestartet in tmux Session '$SESSION'\n";
    echo "Zum Anschauen: tmux attach -t $SESSION\n";
    echo "Log-Datei: $LOGFILE\n";
}
?>
