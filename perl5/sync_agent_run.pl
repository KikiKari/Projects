#!/usr/bin/perl
# sync_agent_run.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:scripts/sync_agent_run.py
# auch in: OpenClaw@gateway2:scripts/sync_agent_run.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use lib '/home/openclaw/.openclaw/workspace/scripts';
use File::Find;
use File::stat;
use JSON;
use Time::Piece;

# Lade Funktionen aus externem Modul
require "sync_clawhub_git.pl";

my $CLAWHUB_DIR = '/home/openclaw/.openclaw/workspace/skills';
my $GIT_DIR = '/home/openclaw/.openclaw/workspace/git/skills';

sub file_mtime {
    my ($path) = @_;
    my @files;
    find(sub {
        return if -d $_ || $_ eq '.git';
        push @files, $File::Find::name;
    }, $path);
    
    return 0 unless @files;
    
    my $max_time = 0;
    for my $file (@files) {
        my $mtime = (stat($file))[9];
        $max_time = $mtime if $mtime > $max_time;
    }
    return $max_time;
}

sub log_message {
    my ($message, $level) = @_;
    $level //= "INFO";
    print "$message\n";
}

log_message("=" x 70);
log_message("CLAWHUB ↔ GIT SYNC AGENT - PRODUKTIONS-LAUF");
log_message("Zeitstempel: " . localtime->datetime);
log_message("=" x 70);

sub get_directories {
    my ($base_dir) = @_;
    opendir(my $dh, $base_dir) or return ();
    my @dirs = grep { !/^\./ && -d "$base_dir/$_" } readdir($dh);
    closedir $dh;
    return @dirs;
}

my @clawhub_skills = get_directories($CLAWHUB_DIR);
my @git_skills = get_directories($GIT_DIR);

my %clawhub_hash = map { $_ => 1 } @clawhub_skills;
my %git_hash = map { $_ => 1 } @git_skills;

my %results = (
    synced_to_git => [],
    synced_to_clawhub => [],
    up_to_date => [],
    errors => []
);

# Phase 1: Neu in ClawHub -> zu Git syncen
log_message("\n[PHASE 1] ClawHub → Git Synchronisation");
log_message("-" x 40);

my @new_in_clawhub = sort grep { !$git_hash{$_} } @clawhub_skills;
for my $skill (@new_in_clawhub) {
    eval {
        my $skill_path = "$CLAWHUB_DIR/$skill";
        if (validate_skill($skill_path)) {
            log_message("→ Synchronisiere $skill zu Git...");
            if (sync_to_git($skill, 0)) {  # 0 = nicht dry-run
                my $git_path = "$GIT_DIR/$skill";
                chdir($git_path);
                system('git init -q 2>/dev/null');
                system('git add . -f 2>/dev/null');
                my $dt = localtime->strftime("%Y-%m-%d %H:%M");
                system("git commit -m \"Initial: $skill\" -q 2>/dev/null");
                push @{$results{synced_to_git}}, $skill;
                log_message("  ✓ $skill synchronisiert & Git initialisiert");
            } else {
                push @{$results{errors}}, "$skill (sync failed)";
            }
        } else {
            push @{$results{errors}}, "$skill (invalid)";
        }
        1;
    } or do {
        my $error = $@ || 'Unknown error';
        log_message("  ✗ ERROR: $skill - $error", "ERROR");
        push @{$results{errors}}, "$skill (exception)";
    };
}

# Phase 2: Prüfe existierende Skills auf Änderungen
log_message("\n[PHASE 2] Prüfe existierende Skills auf Änderungen");
log_message("-" x 40);

my @in_both = sort grep { $git_hash{$_} } @clawhub_skills;
for my $skill (@in_both) {
    eval {
        my $c_mtime = file_mtime("$CLAWHUB_DIR/$skill");
        my $g_mtime = file_mtime("$GIT_DIR/$skill");
        my $diff = $c_mtime - $g_mtime;

        if (abs($diff) > 60) {
            if ($diff > 0) {
                log_message("→ $skill: ClawHub neuer (+${diff}s) → sync zu Git");
                if (sync_to_git($skill, 0)) {
                    my $git_path = "$GIT_DIR/$skill";
                    chdir($git_path);
                    system('git add . -f 2>/dev/null');
                    my $dt = localtime->strftime("%Y-%m-%d %H:%M");
                    system("git commit -m \"Sync from ClawHub: $dt\" -q 2>/dev/null");
                    push @{$results{synced_to_git}}, $skill;
                } else {
                    push @{$results{errors}}, "$skill (update failed)";
                }
            } else {
                log_message("→ $skill: Git neuer (+".abs($diff)."s) → sync zu ClawHub");
                if (sync_to_clawhub($skill, 0)) {
                    push @{$results{synced_to_clawhub}}, $skill;
                } else {
                    push @{$results{errors}}, "$skill (update failed)";
                }
            }
        } else {
            push @{$results{up_to_date}}, $skill;
        }
        1;
    } or do {
        my $error = $@ || 'Unknown error';
        log_message("  ✗ ERROR: $skill - $error", "ERROR");
        push @{$results{errors}}, "$skill (exception)";
    };
}

# Zusammenfassung
log_message("\n" . "=" x 70);
log_message("SYNCHRONISATION ABGESCHLOSSEN");
log_message("=" x 70);
log_message(sprintf("Zu Git synchronisiert:     %d", scalar @{$results{synced_to_git}}));
if (@{$results{synced_to_git}}) {
    log_message("  " . join(", ", @{$results{synced_to_git}}));
}
log_message(sprintf("Zu ClawHub synchronisiert: %d", scalar @{$results{synced_to_clawhub}}));
if (@{$results{synced_to_clawhub}}) {
    log_message("  " . join(", ", @{$results{synced_to_clawhub}}));
}
log_message(sprintf("Bereits aktuell:           %d", scalar @{$results{up_to_date}}));
log_message(sprintf("Fehler:                    %d", scalar @{$results{errors}}));
if (@{$results{errors}}) {
    log_message("  " . join(", ", @{$results{errors}}));
}
log_message("=" x 70);

# Speichere State
my $STATE_FILE = "/home/openclaw/.openclaw/workspace/db/sync_state.json";
my $state_dir = "/home/openclaw/.openclaw/workspace/db";
mkdir $state_dir unless -d $state_dir;

my $state = {
    last_run => localtime->datetime,
    results => \%results
};

open(my $fh, '>', $STATE_FILE) or die "Kann $STATE_FILE nicht öffnen: $!";
print $fh to_json($state, {pretty => 1});
close($fh);
log_message("State gespeichert: $STATE_FILE");
