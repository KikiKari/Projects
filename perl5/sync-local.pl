#!/usr/bin/perl
# sync-local.ps1 — portiert nach perl5
# Quelle: powershell, Onboarding@main:scripts/sync-local.ps1
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Basename;
use Cwd qw(abs_path);
use Time::Piece;

# SYNOPSIS
#   Hält den lokalen Dev-Stack (docker-compose.dev.yml) inkrementell mit GitHub synchron.
#
# DESCRIPTION
#   Pollt origin/<Branch> und zieht neue Commits per Fast-Forward. Danach entscheidet
#   der Diff, was nötig ist:
#     - nur Quellcode geändert            -> nichts tun, Hot-Reload übernimmt
#     - package.json / package-lock.json  -> Frontend-Container neu starten
#                                            (Entrypoint installiert Dependencies nur
#                                            bei geändertem Lockfile-Hash nach)
#     - backend/Dockerfile, requirements* -> Backend-Image gezielt neu bauen
#     - docker-compose.dev.yml            -> Dev-Stack neu erzeugen
#   Es wird nie „blind" der ganze Branch neu gebaut.
#
# EXAMPLE
#   perl scripts/sync-local.pl                # Dauerbetrieb, 20-s-Intervall
#   perl scripts/sync-local.pl --once         # genau ein Sync-Durchlauf
#   perl scripts/sync-local.pl --branch main  # anderen Branch verfolgen

my $branch = "claude/onboarding-persistent-sandbox-vjfmcx";
my $interval_seconds = 20;
my $compose_file = "docker-compose.dev.yml";
my $once = 0;

# Parameterverarbeitung
for (my $i = 0; $i < @ARGV; $i++) {
    my $arg = $ARGV[$i];
    if ($arg eq '--branch') {
        $branch = $ARGV[++$i];
    } elsif ($arg eq '--interval') {
        $interval_seconds = int($ARGV[++$i]);
    } elsif ($arg eq '--compose-file') {
        $compose_file = $ARGV[++$i];
    } elsif ($arg eq '--once') {
        $once = 1;
    }
}

my $repo_root = dirname(dirname(abs_path(__FILE__)));
chdir $repo_root or die "Konnte nicht in das Repo-Verzeichnis wechseln: $!";

sub log_msg {
    my ($msg) = @_;
    my $timestamp = localtime->strftime('%H:%M:%S');
    print "[$timestamp] $msg\n";
}

sub invoke_compose {
    my (@compose_args) = @_;
    system("docker", "compose", "-f", $compose_file, @compose_args);
    if ($? != 0) {
        log_msg("WARNUNG: docker compose " . join(' ', @compose_args) . " fehlgeschlagen (Exit " . ($?>>8) . ")");
    }
}

# Sicherstellen, dass der Ziel-Branch ausgecheckt ist.
my $current = `git rev-parse --abbrev-ref HEAD`;
chomp $current;
if ($current ne $branch) {
    log_msg("Wechsle von '$current' auf '$branch' …");
    system("git fetch origin $branch");
    system("git switch $branch 2>/dev/null");
    if ($? != 0) {
        system("git switch -c $branch --track origin/$branch");
    }
    if ($? != 0) {
        die "Branch '$branch' konnte nicht ausgecheckt werden.";
    }
}

log_msg("Sync aktiv: origin/$branch -> $repo_root (Intervall ${interval_seconds}s, Compose: $compose_file)");

while (1) {
    system("git fetch origin $branch --quiet");
    if ($? != 0) {
        log_msg("Fetch fehlgeschlagen (Netzwerk?) — nächster Versuch in ${interval_seconds}s");
    } else {
        my $local = `git rev-parse HEAD`;
        chomp $local;
        my $remote = `git rev-parse origin/$branch`;
        chomp $remote;

        if ($local ne $remote) {
            system("git merge-base --is-ancestor $local $remote");
            if ($? != 0) {
                log_msg("ACHTUNG: Lokaler Stand ist von origin/$branch abgewichen (lokale Commits?). Kein automatischer Merge — bitte manuell auflösen.");
            } else {
                my @changed = split /\n/, `git diff --name-only "$local..$remote"`;
                system("git merge --ff-only $remote --quiet");
                my $count = scalar(@changed);
                log_msg(sprintf("Aktualisiert %s -> %s (%d Datei(en))", substr($local, 0, 7), substr($remote, 0, 7), $count));

                my @frontend_deps = grep { $_ eq "package.json" || $_ eq "package-lock.json" } @changed;
                my @backend_image = grep { /^backend\/(Dockerfile|requirements.*\.txt)$/ } @changed;
                my @compose_changed = grep { $_ eq $compose_file } @changed;

                if (@compose_changed) {
                    log_msg("Compose-Datei geändert — erzeuge Dev-Stack neu …");
                    invoke_compose("up", "-d");
                }
                if (@backend_image) {
                    log_msg("Backend-Dependencies/Dockerfile geändert — baue nur das Backend neu …");
                    invoke_compose("up", "-d", "--build", "backend");
                }
                if (@frontend_deps) {
                    log_msg("Frontend-Dependencies geändert — starte Frontend neu (npm install läuft im Container) …");
                    invoke_compose("restart", "frontend");
                }
                if (!@compose_changed && !@backend_image && !@frontend_deps) {
                    log_msg("Nur Quellcode/Assets — Hot-Reload übernimmt, kein Build nötig.");
                }
            }
        }
    }

    last if $once;
    sleep $interval_seconds;
}
