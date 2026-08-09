#!/usr/bin/env perl
# fix_gateway_node_path.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
# auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use POSIX qw(strftime);

# Backup der originalen Service-Datei
my $service_file = "/etc/systemd/system/openclaw-gateway.service";
my $timestamp = strftime("%Y%m%d_%H%M%S", localtime);
my $backup_file = "${service_file}.backup-${timestamp}";

# Kopiere die Datei für das Backup
system("cp", $service_file, $backup_file) == 0
    or die "Fehler beim Erstellen des Backups: $!";

# Korrektur des Node.js Pfads in der Service-Datei
# Annahme: Node.js ist unter /usr/bin/node verfügbar (wie von 'which node' gezeigt)
{
    # Öffne die Datei zum Lesen
    open(my $fh_read, '<', $service_file)
        or die "Kann $service_file nicht zum Lesen öffnen: $!";
    
    # Lies den gesamten Inhalt
    my @lines = <$fh_read>;
    close($fh_read);
    
    # Ersetze den Pfad
    for my $line (@lines) {
        $line =~ s|/home/openclaw/.nvm/versions/node/v22.22.2/bin/node|/usr/bin/node|g;
    }
    
    # Öffne die Datei zum Schreiben
    open(my $fh_write, '>', $service_file)
        or die "Kann $service_file nicht zum Schreiben öffnen: $!";
    
    # Schreibe den geänderten Inhalt
    print $fh_write @lines;
    close($fh_write);
}

# Service neu laden und neu starten
system("systemctl", "daemon-reload") == 0
    or die "Fehler beim Neuladen der Systemd-Konfiguration: $!";

system("systemctl", "restart", "openclaw-gateway") == 0
    or die "Fehler beim Neustarten des Services: $!";

# Status prüfen
system("systemctl", "status", "openclaw-gateway", "--no-pager");
