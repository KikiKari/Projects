#!/usr/bin/tclsh8.6
# abstraction-provenance: {"artifact_sha256": "2c53abf41d760b5b4f631e5aea5988f1bd472457f8b2253e343d540eb33176e3", "source_sha256": "dd115a5287b5db772bd4af098a6620a66b294c0e327633048101753a48a3976b", "target_language": "tcl"}
# openclaw-node-autostart-termux.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# OpenClaw Node Mode Autostart für Termux (Node 5 - Redmi Note 11)
# Installiert nach: ~/.termux/boot/openclaw-node.tcl
# Getestet mit: Termux + Android + OpenClaw

set SESSION "openclaw-node"
set LOGFILE "$env(HOME)/.openclaw/node.log"
set GATEWAY "10.10.0.1"
set PORT "18789"

# Log-Verzeichnis erstellen
file mkdir "$env(HOME)/.openclaw"

# Prüfen ob tmux Session bereits läuft
if {[catch {exec tmux has-session -t $SESSION} result]} {
    # Session läuft nicht, fortfahren
} else {
    set logfile [open $LOGFILE a]
    puts $logfile "\[[clock format [clock seconds]]\] OpenClaw Node läuft bereits in tmux Session '$SESSION'"
    close $logfile
    exit 0
}

# Neue tmux Session erstellen und OpenClaw starten
set cmd "while true; do \
    echo '\[[clock format [clock seconds]]\] Starting OpenClaw Node Mode...' | tee -a '$LOGFILE'; \
    \
    # Prüfe WireGuard Verbindung \
    if ! ping -c 1 -W 3 $GATEWAY >/dev/null 2>&1; then \
        echo '\[[clock format [clock seconds]]\] FEHLER: WireGuard Gateway $GATEWAY nicht erreichbar!' | tee -a '$LOGFILE'; \
        echo '\[[clock format [clock seconds]]\] Warte 10 Sekunden...' | tee -a '$LOGFILE'; \
        sleep 10; \
        continue; \
    fi; \
    \
    # OpenClaw Node Mode starten \
    openclaw node run --host $GATEWAY --port $PORT 2>&1 | tee -a '$LOGFILE'; \
    \
    # Wenn der Prozess endet, warte und neustarten \
    echo '\[[clock format [clock seconds]]\] OpenClaw beendet. Neustart in 5 Sekunden...' | tee -a '$LOGFILE'; \
    sleep 5; \
done"

# Shell-Kommando escapen
set escaped_cmd [string map {' "'\\''"} $cmd]
exec tmux new-session -d -s $SESSION -n "node" "/data/data/com.termux/files/usr/bin/bash -c '$escaped_cmd'"

set logfile [open $LOGFILE a]
puts $logfile "\[[clock format [clock seconds]]\] OpenClaw Node Autostart aktiviert (tmux Session: $SESSION)"
close $logfile

# Optional: tmux attach Hinweis falls interaktiv gestartet
if {[info exists env(TERM)] && $env(TERM) ne ""} {
    puts "OpenClaw Node Mode gestartet in tmux Session '$SESSION'"
    puts "Zum Anschauen: tmux attach -t $SESSION"
    puts "Log-Datei: $LOGFILE"
}
