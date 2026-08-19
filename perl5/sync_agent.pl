#!/usr/bin/perl
# sync_agent.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/clawhub-git-sync-agent/scripts/sync_agent.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON qw(decode_json encode_json);
use File::Path qw(make_path);
use File::Spec;
use File::Copy qw(copy);
use File::Find;
use Digest::MD5 qw(md5_hex);
use POSIX qw(strftime);

# Füge das Skriptverzeichnis zum Suchpfad hinzu
use lib '/home/openclaw/.openclaw/workspace/scripts';
require 'sync_clawhub_git.pl';

my $CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills";
my $GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills";
my $STATE_FILE = "/home/openclaw/.openclaw/workspace/db/sync_state.json";

# Root directory for backups
my $BACKUP_ROOT = "/home/openclaw/.openclaw/workspace/backups/sync_agent";

sub load_state {
    # Lädt den Sync-State
    if (-f $STATE_FILE) {
        open my $fh, '<', $STATE_FILE or die "Cannot read $STATE_FILE: $!";
        my $json_text = do { local $/; <$fh> };
        close $fh;
        return decode_json($json_text);
    }
    return { sync_history => [], pending => [] };
}

sub save_state {
    # Speichert den Sync-State
    my ($state) = @_;
    my $state_dir = dirname($STATE_FILE);
    make_path($state_dir) unless -d $state_dir;
    open my $fh, '>', $STATE_FILE or die "Cannot write $STATE_FILE: $!";
    print $fh encode_json($state);
    close $fh;
}

sub dirname {
    my ($path) = @_;
    my @parts = split '/', $path;
    pop @parts;
    return join '/', @parts;
}

sub get_all_skills {
    # Findet nur valide Skill-Verzeichnisse in beiden Verzeichnissen.
    my (%clawhub_skills, %git_skills);
    
    opendir(my $dh, $CLAWHUB_DIR) or die "Cannot opendir $CLAWHUB_DIR: $!";
    while (readdir $dh) {
        next if /^\.\.?$/;
        my $dir = "$CLAWHUB_DIR/$_";
        if (-d $dir && !/^[._]/ && -f "$dir/SKILL.md") {
            $clawhub_skills{$_} = 1;
        }
    }
    closedir $dh;
    
    opendir($dh, $GIT_DIR) or die "Cannot opendir $GIT_DIR: $!";
    while (readdir $dh) {
        next if /^\.\.?$/;
        my $dir = "$GIT_DIR/$_";
        if (-d $dir && !/^[._]/ && -f "$dir/SKILL.md") {
            $git_skills{$_} = 1;
        }
    }
    closedir $dh;
    
    my %union = (%clawhub_skills, %git_skills);
    return keys %union;
}

sub init_git_repo {
    # Initialisiert Git-Repo wenn nötig
    my ($skill_path, $skill_name) = @_;
    my $git_dir = "$skill_path/.git";
    if (!-d $git_dir) {
        chdir $skill_path or die "Cannot chdir to $skill_path: $!";
        system("git", "init");
        system("git", "add", ".");
        system("git", "commit", "-m", "Initial commit: $skill_name skill");
        log_msg("Git initialized for $skill_name");
    }
}

sub backup_skill_dir {
    # Creates a timestamped tar.gz backup of a skill directory.
    my ($skill_path, $skill_name) = @_;
    return unless -d $skill_path;
    my $timestamp = strftime "%Y%m%d%H%M%S", localtime;
    my $backup_dir = "$BACKUP_ROOT/$timestamp";
    make_path($backup_dir) unless -d $backup_dir;
    my $archive_name = "${skill_name}_${timestamp}.tar.gz";
    my $archive_path = "$backup_dir/$archive_name";
    system("tar", "-czf", $archive_path, "-C", $skill_path, ".");
    log_msg("Backup created for $skill_name at $archive_path");
}

sub sync_skill_bidirectional {
    # Bidirektionale Synchronisation eines Skills
    my ($skill_name, $dry_run) = @_;
    my $clawhub_path = "$CLAWHUB_DIR/$skill_name";
    my $git_path = "$GIT_DIR/$skill_name";

    # Fall 1: Nur in ClawHub → zu Git
    if (-d $clawhub_path && !-d $git_path) {
        log_msg("NEW in ClawHub: $skill_name → syncing to Git");
        backup_skill_dir($clawhub_path, "${skill_name}_clawhub") unless $dry_run;
        if (sync_to_git($skill_name, $dry_run)) {
            init_git_repo($git_path, $skill_name) unless $dry_run;
            return "synced_to_git";
        }
    }

    # Fall 2: Nur in Git → zu ClawHub
    elsif (-d $git_path && !-d $clawhub_path) {
        log_msg("NEW in Git: $skill_name → syncing to ClawHub");
        backup_skill_dir($git_path, "${skill_name}_git") unless $dry_run;
        if (sync_to_clawhub($skill_name, $dry_run)) {
            return "synced_to_clawhub";
        }
    }

    # Fall 3: In beiden vorhanden → Vergleiche Timestamps
    elsif (-d $clawhub_path && -d $git_path) {
        # --- MODIFIZIERTE LOGIK: Robusterer Datei-Hash-Vergleich ---

        # Stelle sicher, dass beide als gültige Skills validiert werden
        if (!validate_skill($clawhub_path)) {
            log_msg("Validation failed for ClawHub skill: $skill_name", "ERROR");
            return "error";
        }
        if (!validate_skill($git_path)) {
            log_msg("Validation failed for Git skill: $skill_name", "ERROR");
            return "error";
        }

        # Berechne Hashes für clawhub und git
        my $clawhub_hashes = get_hashes($clawhub_path);
        my $git_hashes = get_hashes($git_path);

        if (!hashes_equal($clawhub_hashes, $git_hashes)) {
            log_msg("Content difference detected for: $skill_name");

            # Einfache (aber oft ausreichende) Logik: Wenn clawhub neuer ist, lade hoch.
            # Eine detailliertere Strategie (z.B. welche Version von Git übernehmen)
            # könnte hier implementiert werden, falls nötig.
            # Für jetzt: Wenn sie sich unterscheiden, priorisieren wir ClawHub > Git
            # und aktualisieren Git.

            my $direction = (-M $clawhub_path <= -M $git_path) ? "to-git" : "to-clawhub";
            log_msg("UPDATE: $skill_name → syncing $direction");
            unless ($dry_run) {
                backup_skill_dir($clawhub_path, "${skill_name}_clawhub");
                backup_skill_dir($git_path, "${skill_name}_git");
            }
            my $sync_func = ($direction eq "to-git") ? \&sync_to_git : \&sync_to_clawhub;
            if ($sync_func->($skill_name, $dry_run)) {
                if (!$dry_run && $direction eq "to-git") {
                    chdir $git_path or die "Cannot chdir to $git_path: $!";
                    system("git", "add", ".");
                    my $date_str = strftime "%Y-%m-%d %H:%M", localtime;
                    system("git", "commit", "-m", "Sync from ClawHub content diff: $date_str");
                }
                return ($direction eq "to-git") ? "updated_git" : "updated_clawhub";
            } else {
                log_msg("Failed to sync $skill_name to Git after content diff", "ERROR");
                return "error";
            }
        } else {
            log_msg("Content is identical for: $skill_name");
            return "no_change";
        }
    }

    return "no_change";
}

# --- Hinzufügen dieser Hilfsfunktion ---
sub get_hashes {
    # Erzeugt ein Dictionary von Datei-Hashes für einen Skill-Ordner.
    my ($skill_dir) = @_;
    my %hashes;
    
    find(sub {
        return if -d $_ || /\.git/;
        my $file_path = $File::Find::name;
        open my $fh, '<', $_ or die "Cannot open $_: $!";
        my $content;
        { local $/; $content = <$fh>; }
        close $fh;
        my $relative_path = substr($file_path, length($skill_dir) + 1);
        $hashes{$relative_path} = md5_hex($content);
    }, $skill_dir);
    
    return \%hashes;
}

sub hashes_equal {
    my ($hash1, $hash2) = @_;
    return 0 if keys %$hash1 != keys %$hash2;
    for my $key (keys %$hash1) {
        return 0 if !exists $hash2->{$key} || $hash1->{$key} ne $hash2->{$key};
    }
    return 1;
}

sub main {
    # Hauptfunktion des Sync-Agents
    my $dry_run = grep { $_ eq '--dry-run' } @ARGV;
    log_msg("=== ClawHub ↔ Git Sync Agent gestartet ===");

    my $state = load_state();
    my @all_skills = get_all_skills();
    log_msg("Gefundene Skills: " . scalar(@all_skills));

    my %results = (
        synced_to_git => [],
        synced_to_clawhub => [],
        updated_git => [],
        updated_clawhub => [],
        no_change => [],
        errors => []
    );

    for my $skill (sort @all_skills) {
        eval {
            my $result = sync_skill_bidirectional($skill, $dry_run);
            push @{$results{$result}}, $skill;
        };
        if ($@) {
            log_msg("ERROR syncing $skill: $@", "ERROR");
            push @{$results{errors}}, $skill;
        }
    }

    # Zusammenfassung
    log_msg("\n=== SYNC ZUSAMMENFASSUNG ===");
    log_msg("Neu in Git: " . scalar(@{$results{synced_to_git}}) . " - [" . join(", ", @{$results{synced_to_git}}) . "]");
    log_msg("Neu in ClawHub: " . scalar(@{$results{synced_to_clawhub}}) . " - [" . join(", ", @{$results{synced_to_clawhub}}) . "]");
    log_msg("Git aktualisiert: " . scalar(@{$results{updated_git}}) . " - [" . join(", ", @{$results{updated_git}}) . "]");
    log_msg("ClawHub aktualisiert: " . scalar(@{$results{updated_clawhub}}) . " - [" . join(", ", @{$results{updated_clawhub}}) . "]");
    log_msg("Keine Änderung: " . scalar(@{$results{no_change}}));
    log_msg("Fehler: " . scalar(@{$results{errors}}) . " - [" . join(", ", @{$results{errors}}) . "]");

    # Ein Dry-Run bleibt vollständig nicht-mutierend (abgesehen vom Audit-Log).
    unless ($dry_run) {
        $state->{sync_history} = [] unless exists $state->{sync_history};
        push @{$state->{sync_history}}, {
            timestamp => strftime("%Y-%m-%dT%H:%M:%S", localtime),
            results => \%results
        };
        # Nur letzte 100 Einträge behalten
        splice(@{$state->{sync_history}}, 0, scalar(@{$state->{sync_history}}) - 100) 
            if scalar(@{$state->{sync_history}}) > 100;
        save_state($state);
    }

    log_msg("=== Sync Agent beendet ===\n");
}

main() if !caller;

1;
