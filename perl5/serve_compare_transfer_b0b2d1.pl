#!/usr/bin/perl
# serve_compare_transfer.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway2:scripts/serve_compare_transfer.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Find;
use File::Basename;
use Cwd 'abs_path';

my $COMPARE_DIR = "/home/openclaw/.openclaw/workspace/vscode/compare";
my $TRANSFER_DIR = "/home/openclaw/.openclaw/workspace/vscode/compare/transfer";
my $HOST_IP = "89.58.15.220";
my $PORT = "80";
my $SELF_PATH = abs_path($0);

# Sammle alle Dateien im Compare-Verzeichnis (ohne Unterverzeichnisse)
my @files;
opendir(my $dir, $COMPARE_DIR) or die "Kann Verzeichnis $COMPARE_DIR nicht öffnen: $!";
while (my $file = readdir($dir)) {
    my $full_path = "$COMPARE_DIR/$file";
    # Überspringe das Skript selbst und versteckte Dateien (beginnend mit .)
    next if $file =~ /^\./ || $full_path eq $SELF_PATH;
    # Nur reguläre Dateien
    push @files, $full_path if -f $full_path;
}
closedir($dir);

# Sortiere die Dateien alphabetisch
@files = sort @files;

if (@files == 0) {
    print "Keine Dateien in ${COMPARE_DIR} gefunden.\n";
    exit 1;
}

print "\n";
print "Bereitgestellte Dateien aus ${COMPARE_DIR}:\n";
for my $src (@files) {
    print "- " . basename($src) . "\n";
}

print "\n";
print "Copy/Paste auf anderem Gateway (Download nach ${TRANSFER_DIR}):\n";
for my $src (@files) {
    my $file = basename($src);
    print "curl -fL --retry 3 --connect-timeout 10 -o ${TRANSFER_DIR}/${file} http://${HOST_IP}:${PORT}/${file}\n";
}

print "\n";
print "Server auf Port ${PORT} aktiv. Beenden mit STRG+C.\n";
print "\n";

# Wechsle ins Compare-Verzeichnis und starte den HTTP-Server
chdir($COMPARE_DIR) or die "Kann nicht in Verzeichnis $COMPARE_DIR wechseln: $!";

# Starte den Python HTTP-Server
exec("python3", "-m", "http.server", $PORT, "--bind", "0.0.0.0");
