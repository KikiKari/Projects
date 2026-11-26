#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "bbf8dfdd1ed52048dc48cf4c8c2f27ce09fb655fec1f09668718d9cc39e2efa3", "source_sha256": "04518825207cd6ef771c2d840daf0a025f3144f4e384f1d13b46e016570f59df", "target_language": "perl5"}
# fix_gateway_node_path.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
# auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use POSIX qw(strftime);

# Backup der originalen Service-Datei
my $service_file = "/etc/systemd/system/openclaw-gateway.service";
my $timestamp = strftime("%Y%m%d_%H%M%S", localtime);
my $backup_file = "${service_file}.backup-${timestamp}";

system("cp", $service_file, $backup_file) == 0
    or die "Backup fehlgeschlagen: $?";

# Korrektur des Node.js Pfads in der Service-Datei
# Annahme: Node.js ist unter /usr/bin/node verfügbar (wie von 'which node' gezeigt)
{
    open(my $fh, '<', $service_file)
        or die "Kann $service_file nicht lesen: $!";
    my @lines = <$fh>;
    close($fh);

    for (@lines) {
        s|/home/openclaw/.nvm/versions/node/v22.22.2/bin/node|/usr/bin/node|g;
    }

    open($fh, '>', $service_file)
        or die "Kann $service_file nicht schreiben: $!";
    print $fh @lines;
    close($fh);
}

# Service neu laden und neu starten
system("systemctl", "daemon-reload") == 0
    or die "systemctl daemon-reload fehlgeschlagen: $?";

system("systemctl", "restart", "openclaw-gateway") == 0
    or die "systemctl restart openclaw-gateway fehlgeschlagen: $?";

# Status prüfen
system("systemctl", "status", "openclaw-gateway", "--no-pager");
