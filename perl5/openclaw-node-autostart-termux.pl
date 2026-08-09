#!/data/data/com.termux/files/usr/bin/perl
# openclaw-node-autostart-termux.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use POSIX qw(strftime);

# OpenClaw Node Mode Autostart für Termux (Node 5 - Redmi Note 11)
# Installiert nach: ~/.termux/boot/openclaw-node.sh
# Getestet mit: Termux + Android + OpenClaw

my $SESSION = "openclaw-node";
my $LOGFILE = "$ENV{HOME}/.openclaw/node.log";
my $GATEWAY = "10.10.0.1";
my $PORT = "18789";

# Log-Verzeichnis erstellen
system("mkdir -p '$ENV{HOME}/.openclaw'");

# Prüfen ob tmux Session bereits läuft
if (system("tmux has-session -t '$SESSION' >/dev/null 2>&1") == 0) {
    log_message("OpenClaw Node läuft bereits in tmux Session '$SESSION'");
    exit 0;
}

# Neue tmux Session erstellen und OpenClaw starten
my $cmd = <<'END_TMUX';
while true; do
    echo '[$(date)] Starting OpenClaw Node Mode...' | tee -a '$LOGFILE'
    
    # Prüfe WireGuard Verbindung
    if ! ping -c 1 -W 3 $GATEWAY >/dev/null 2>&1; then
        echo '[$(date)] FEHLER: WireGuard Gateway $GATEWAY nicht erreichbar!' | tee -a '$LOGFILE'
        echo '[$(date)] Warte 10 Sekunden...' | tee -a '$LOGFILE'
        sleep 10
        continue
    fi
    
    # OpenClaw Node Mode starten
    openclaw node run --host $GATEWAY --port $PORT 2>&1 | tee -a '$LOGFILE'
    
    # Wenn der Prozess endet, warte und neustarten
    echo '[$(date)] OpenClaw beendet. Neustart in 5 Sekunden...' | tee -a '$LOGFILE'
    sleep 5
done
END_TMUX

chomp $cmd;
$cmd =~ s/\$GATEWAY/$GATEWAY/g;
$cmd =~ s/\$PORT/$PORT/g;
$cmd =~ s/\$LOGFILE/$LOGFILE/g;

system("tmux new-session -d -s '$SESSION' -n 'node' '$cmd'");

log_message("OpenClaw Node Autostart aktiviert (tmux Session: $SESSION)");

# Optional: tmux attach Hinweis falls interaktiv gestartet
if (-t STDOUT) {
    print "OpenClaw Node Mode gestartet in tmux Session '$SESSION'\n";
    print "Zum Anschauen: tmux attach -t $SESSION\n";
    print "Log-Datei: $LOGFILE\n";
}

sub log_message {
    my ($message) = @_;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
    open(my $fh, '>>', $LOGFILE) or die "Could not open file '$LOGFILE': $!";
    print $fh "[$timestamp] $message\n";
    close $fh;
}
