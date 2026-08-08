#!/usr/bin/perl
# abgleich.sh — portiert nach perl5
# Quelle: shell, Projects@abstractions:abstractions/abgleich.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Path qw(make_path);
use File::Find;
use IPC::Run qw(run);

# Haelt den Abstraktions-Bestand im Container aktuell.
#
# Alle zwoelf Stunden wird der oeffentliche Branch Projects@abstractions nach
# /home/openclaw/.openclaw/workspace/git/Abstraktionen geholt. Das Repository
# ist oeffentlich, es wird kein Token gebraucht — der Container liest nur.
#
# Erzeugt wird hier nichts: das Portieren laeuft in GitHub Actions, weil dort
# der Schluessel liegt und der Lauf auch dann stattfindet, wenn dieser Rechner
# aus ist. Ein Lauf von Hand ist trotzdem moeglich:
#
#   docker exec -e OPENROUTER_API_KEY=... abstractions-manager \
#       python abstractions/ABSTRACTIONS_MANAGER.py --anzahl 5

$ENV{ABSTRACTIONS_WORKSPACE} //= '/home/openclaw/.openclaw/workspace';
my $WURZEL = $ENV{ABSTRACTIONS_WORKSPACE};
my $ZIEL = "$WURZEL/git/Abstraktionen";
my $HERKUNFT = 'https://github.com/KikiKari/Projects.git';
my $BRANCH = 'abstractions';
$ENV{ABGLEICH_TAKT} //= '43200';   # zwoelf Stunden
my $TAKT = $ENV{ABGLEICH_TAKT};

sub melde {
    my (@args) = @_;
    my $timestamp = gmtime() . ' UTC';
    print "$timestamp | abgleich | " . join(' ', @args) . "\n";
}

sub abgleichen {
    if (! -d "$ZIEL/.git") {
        melde("Erstabgleich nach $ZIEL");
        make_path($ZIEL);
        system("git", "init", "-q", $ZIEL) == 0 or die "git init failed: $?";
        system("git", "-C", $ZIEL, "remote", "add", "herkunft", $HERKUNFT) == 0 or die "git remote add failed: $?";
    }
    my @fetch_cmd = ("git", "-C", $ZIEL, "fetch", "-q", "--depth", "1", "herkunft", $BRANCH);
    if (run(\@fetch_cmd, \undef, \undef, \undef)) {
        system("git", "-C", $ZIEL, "checkout", "-q", "-f", "-B", $BRANCH, "FETCH_HEAD") == 0 or die "git checkout failed: $?";
        my $stand = qx(git -C "$ZIEL" rev-parse --short HEAD);
        chomp $stand;
        my $anzahl = 0;
        find(sub {
            return unless -f $_;
            return if $File::Find::dir =~ m|/.git/|;
            $anzahl++ if /\.(js|pl|ps1|py|sh|tcl)$/;
        }, $ZIEL);
        melde("Stand $stand, $anzahl Erzeugnisse");
    } else {
        melde("Abgleich fehlgeschlagen — vorheriger Stand bleibt bestehen");
    }
}

melde("Start, Takt ${TAKT}s");
while (1) {
    abgleichen();
    sleep($TAKT);
}
