#!/data/data/com.termux/files/usr/bin/tclsh
# openclaw-node-autostart-termux.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

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
if {[catch {exec tmux has-session -t $SESSION}]} {
    # tmux Session läuft nicht, fortfahren
} else {
    set fh [open $LOGFILE a]
    puts $fh "\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] OpenClaw Node läuft bereits in tmux Session '$SESSION'"
    close $fh
    exit 0
}

# Neue tmux Session erstellen und OpenClaw starten
set script "
    while true; do
        echo '\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] Starting OpenClaw Node Mode...' | tee -a '$LOGFILE'
        
        # Prüfe WireGuard Verbindung
        if ! ping -c 1 -W 3 $GATEWAY >/dev/null 2>&1; then
            echo '\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] FEHLER: WireGuard Gateway $GATEWAY nicht erreichbar!' | tee -a '$LOGFILE'
            echo '\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] Warte 10 Sekunden...' | tee -a '$LOGFILE'
            sleep 10
            continue
        fi
        
        # OpenClaw Node Mode starten
        openclaw node run --host $GATEWAY --port $PORT 2>&1 | tee -a '$LOGFILE'
        
        # Wenn der Prozess endet, warte und neustarten
        echo '\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] OpenClaw beendet. Neustart in 5 Sekunden...' | tee -a '$LOGFILE'
        sleep 5
    done
"

exec tmux new-session -d -s $SESSION -n "node" "/data/data/com.termux/files/usr/bin/bash" "-c" $script

set fh [open $LOGFILE a]
puts $fh "\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] OpenClaw Node Autostart aktiviert (tmux Session: $SESSION)"
close $fh

# Optional: tmux attach Hinweis falls interaktiv gestartet
if {[info exists env(TERM)] && $env(TERM) != ""} {
    puts "OpenClaw Node Mode gestartet in tmux Session '$SESSION'"
    puts "Zum Anschauen: tmux attach -t $SESSION"
    puts "Log-Datei: $LOGFILE"
}
