#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "8fe4093a137faea1c8ca54118564f25833415306208b1a284b9176203f70ed07", "source_sha256": "dd115a5287b5db772bd4af098a6620a66b294c0e327633048101753a48a3976b", "target_language": "perl6"}
# openclaw-node-autostart-termux.sh — portiert nach perl6
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# OpenClaw Node Mode Autostart für Termux (Node 5 - Redmi Note 11)
# Installiert nach: ~/.termux/boot/openclaw-node.sh
# Getestet mit: Termux + Android + OpenClaw

use v6;

my $SESSION = "openclaw-node";
my $LOGFILE = "$*HOME/.openclaw/node.log";
my $GATEWAY = "10.10.0.1";
my $PORT = "18789";

# Log-Verzeichnis erstellen
run 'mkdir', '-p', "$*HOME/.openclaw";

# Prüfen ob tmux Session bereits läuft
if run('tmux', 'has-session', '-t', $SESSION, :out, :err).exitcode == 0 {
    log-message("OpenClaw Node läuft bereits in tmux Session '$SESSION'");
    exit 0;
}

# Neue tmux Session erstellen und OpenClaw starten
my $cmd = qq:to/END/;
    while true; do
        echo '[\$(date)] Starting OpenClaw Node Mode...' | tee -a '$LOGFILE'
        
        # Prüfe WireGuard Verbindung
        if ! ping -c 1 -W 3 $GATEWAY >/dev/null 2>&1; then
            echo '[\$(date)] FEHLER: WireGuard Gateway $GATEWAY nicht erreichbar!' | tee -a '$LOGFILE'
            echo '[\$(date)] Warte 10 Sekunden...' | tee -a '$LOGFILE'
            sleep 10
            continue
        fi
        
        # OpenClaw Node Mode starten
        openclaw node run --host $GATEWAY --port $PORT 2>&1 | tee -a '$LOGFILE'
        
        # Wenn der Prozess endet, warte und neustarten
        echo '[\$(date)] OpenClaw beendet. Neustart in 5 Sekunden...' | tee -a '$LOGFILE'
        sleep 5
    done
    END

run 'tmux', 'new-session', '-d', '-s', $SESSION, '-n', 'node', $cmd.chomp;

log-message("OpenClaw Node Autostart aktiviert (tmux Session: $SESSION)");

# Optional: tmux attach Hinweis falls interaktiv gestartet
if $*IN.t && $*OUT.t {
    say "OpenClaw Node Mode gestartet in tmux Session '$SESSION'";
    say "Zum Anschauen: tmux attach -t $SESSION";
    say "Log-Datei: $LOGFILE";
}

sub log-message($message) {
    my $timestamp = DateTime.now.Str;
    my $log-entry = "[$timestamp] $message\n";
    spurt $LOGFILE, $log-entry, :append;
}
