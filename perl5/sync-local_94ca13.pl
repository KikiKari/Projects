#!/usr/bin/env perl
# sync-local.sh — portiert nach perl5
# Quelle: shell, Onboarding@main:scripts/sync-local.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use Cwd qw(abs_path);
use POSIX qw(strftime);

my $BRANCH = "claude/onboarding-persistent-sandbox-vjfmcx";
my $INTERVAL = 20;
my $COMPOSE_FILE = "docker-compose.dev.yml";
my $ONCE = 0;

GetOptions(
    "branch=s"   => \$BRANCH,
    "interval=i" => \$INTERVAL,
    "once"       => \$ONCE,
) or die "Fehler beim Parsen der Kommandozeilenargumente\n";

my $script_dir = dirname(abs_path($0));
chdir("$script_dir/..") or die "Konnte nicht ins Projektverzeichnis wechseln: $!";

sub log_message {
    my ($msg) = @_;
    my $time = strftime "%H:%M:%S", localtime;
    print "[$time] $msg\n";
}

sub compose {
    my (@args) = @_;
    system("docker", "compose", "-f", $COMPOSE_FILE, @args) == 0
        or log_message("WARNUNG: docker compose " . join(" ", @args) . " fehlgeschlagen");
}

my $current_branch = `git rev-parse --abbrev-ref HEAD`;
chomp $current_branch;

if ($current_branch ne $BRANCH) {
    log_message("Wechsle von '$current_branch' auf '$BRANCH' …");
    system("git", "fetch", "origin", $BRANCH) == 0
        or die "Git fetch fehlgeschlagen: $?";
    my $switch_result = system("git", "switch", $BRANCH, "2>/dev/null");
    if ($switch_result != 0) {
        system("git", "switch", "-c", $BRANCH, "--track", "origin/$BRANCH") == 0
            or die "Git switch fehlgeschlagen: $?";
    }
}

log_message("Sync aktiv: origin/$BRANCH -> " . abs_path(".") . " (Intervall ${INTERVAL}s, Compose: $COMPOSE_FILE)");

while (1) {
    my $fetch_result = system("git", "fetch", "origin", $BRANCH, "--quiet");
    if ($fetch_result != 0) {
        log_message("Fetch fehlgeschlagen (Netzwerk?) — nächster Versuch in ${INTERVAL}s");
    } else {
        my $local_rev = `git rev-parse HEAD`;
        chomp $local_rev;
        my $remote_rev = `git rev-parse "origin/$BRANCH"`;
        chomp $remote_rev;

        if ($local_rev ne $remote_rev) {
            my $ancestor_check = system("git", "merge-base", "--is-ancestor", $local_rev, $remote_rev);
            if ($ancestor_check != 0) {
                log_message("ACHTUNG: Lokaler Stand von origin/$BRANCH abgewichen — kein automatischer Merge, bitte manuell auflösen.");
            } else {
                my $changed_files = `git diff --name-only "$local_rev..$remote_rev"`;
                system("git", "merge", "--ff-only", $remote_rev, "--quiet") == 0
                    or die "Merge fehlgeschlagen: $?";

                my @changed_lines = split /\n/, $changed_files;
                log_message(sprintf(
                    "Aktualisiert %.7s -> %.7s (%d Datei(en))",
                    $local_rev,
                    $remote_rev,
                    scalar(@changed_lines)
                ));

                my $needs_none = 1;
                for my $file (@changed_lines) {
                    if ($file eq $COMPOSE_FILE) {
                        log_message("Compose-Datei geändert — erzeuge Dev-Stack neu …");
                        compose("up", "-d");
                        $needs_none = 0;
                    }
                    if ($file =~ m{^backend/(Dockerfile|requirements.*\.txt)$}) {
                        log_message("Backend-Dependencies/Dockerfile geändert — baue nur das Backend neu …");
                        compose("up", "-d", "--build", "backend");
                        $needs_none = 0;
                    }
                    if ($file =~ m{^(package\.json|package-lock\.json)$}) {
                        log_message("Frontend-Dependencies geändert — starte Frontend neu (npm install läuft im Container) …");
                        compose("restart", "frontend");
                        $needs_none = 0;
                    }
                }
                if ($needs_none) {
                    log_message("Nur Quellcode/Assets — Hot-Reload übernimmt, kein Build nötig.");
                }
            }
        }
    }
    last if $ONCE;
    sleep($INTERVAL);
}
