#!/usr/bin/env perl
# serve_compare_transfer.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/serve_compare_transfer.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Find;
use File::Spec;
use Cwd 'abs_path';
use File::Basename;

my $COMPARE_DIR = "/home/openclaw/.openclaw/workspace/vscode/compare";
my $TRANSFER_DIR = "/home/openclaw/.openclaw/workspace/vscode/compare/transfer";
my $HOST_IP = "152.53.145.65";
my $PORT = "80";
my $SELF_PATH = abs_path($0);

# Finde alle Dateien im Verzeichnis (ohne Unterverzeichnisse)
my @FILES;
opendir(my $dh, $COMPARE_DIR) or die "Kann Verzeichnis $COMPARE_DIR nicht öffnen: $!";
while (readdir $dh) {
    my $file = File::Spec->catfile($COMPARE_DIR, $_);
    # Überspringe das Skript selbst und nur reguläre Dateien
    if ($_ ne '.' && $_ ne '..' && $file ne $SELF_PATH && -f $file) {
        push @FILES, $file;
    }
}

closedir $dh;

# Sortiere die Dateien
@FILES = sort @FILES;

if (@FILES == 0) {
    print "Keine Dateien in ${COMPARE_DIR} gefunden.\n";
    exit 1;
}

print "\n";
print "Bereitgestellte Dateien aus ${COMPARE_DIR}:\n";
for my $src (@FILES) {
    my ($filename) = fileparse($src);
    print "- $filename\n";
}

print "\n";
print "Copy/Paste auf anderem Gateway (Download nach ${TRANSFER_DIR}):\n";
for my $src (@FILES) {
    my ($filename) = fileparse($src);
    print "curl -fL --retry 3 --connect-timeout 10 -o ${TRANSFER_DIR}/${filename} http://${HOST_IP}:${PORT}/${filename}\n";
}

print "\n";
print "Server auf Port ${PORT} aktiv. Beenden mit STRG+C.\n";
print "\n";

# Wechsle ins Compare-Verzeichnis und starte den HTTP-Server
chdir $COMPARE_DIR or die "Kann nicht in Verzeichnis $COMPARE_DIR wechseln: $!";

# Starte den Python HTTP-Server
exec("python3", "-m", "http.server", $PORT, "--bind", "0.0.0.0");
