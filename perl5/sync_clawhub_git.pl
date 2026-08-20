#!/usr/bin/perl
# sync_clawhub_git.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:scripts/sync_clawhub_git.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);
use File::Find;
use Digest::SHA qw(sha256_hex);
use Getopt::Long;
use Time::Piece;

# Konfiguration
my $CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills";
my $GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills";
my $BACKUP_DIR = "/home/openclaw/.openclaw/workspace/backups/sync";
my $LOG_FILE = "/home/openclaw/.openclaw/workspace/logs/sync-agent.log";

# Erstelle Verzeichnisse
make_path($GIT_DIR, { verbose => 0 });
make_path($BACKUP_DIR, { verbose => 0 });
make_path((split '/', $LOG_FILE)[0..$#_-1], { verbose => 0 });

# Logging
sub log_message {
    my ($message, $level) = @_;
    $level //= "INFO";
    my $timestamp = localtime->strftime('%Y-%m-%d %H:%M:%S');
    my $entry = "[$timestamp] [$level] $message\n";
    print $entry;
    open(my $fh, '>>', $LOG_FILE) or die "Could not open file '$LOG_FILE' $!";
    print $fh $entry;
    close $fh;
}

# Validierung
sub validate_skill {
    my ($skill_dir) = @_;
    my $skill_md = "$skill_dir/SKILL.md";
    unless (-e $skill_md) {
        log_message("Validation failed: " . (split '/', $skill_dir)[-1] . " missing SKILL.md", "ERROR");
        return 0;
    }
    return 1;
}

# Backup
sub create_backup {
    my ($source, $skill_name) = @_;
    my $timestamp = localtime->strftime('%Y%m%d_%H%M%S');
    my $backup_path = "$BACKUP_DIR/${skill_name}_${timestamp}";

    # Backup verzeichnis löschen falls es existiert
    if (-e $backup_path) {
        eval {
            remove_tree($backup_path);
            log_message("Removed existing backup: $backup_path");
        };
        if ($@) {
            log_message("Failed to remove existing backup $backup_path: $@", "ERROR");
            return 0;
        }
    }

    eval {
        copy_recursive($source, $backup_path);
        log_message("Backup created: $backup_path");
        return 1;
    };
    if ($@) {
        log_message("Backup failed: $@", "ERROR");
        return 0;
    }
}

# Rekursives Kopieren
sub copy_recursive {
    my ($src, $dst) = @_;
    opendir(my $dh, $src) or die "Cannot open directory '$src': $!";
    mkdir $dst or die "Cannot create directory '$dst': $!" unless -e $dst;
    while (readdir $dh) {
        next if ($_ eq '.' || $_ eq '..');
        next if ($_ eq '.git'); # Ignoriere .git Verzeichnis
        my $src_path = "$src/$_";
        my $dst_path = "$dst/$_";
        if (-d $src_path) {
            copy_recursive($src_path, $dst_path);
        } else {
            copy($src_path, $dst_path) or die "Copy failed: $!";
        }
    }
    closedir $dh;
}

# Hash-Vergleich
sub get_file_hash {
    my ($file_path) = @_;
    open(my $fh, '<', $file_path) or die "Cannot open file '$file_path': $!";
    binmode($fh);
    my $hash = sha256_hex(do { local $/; <$fh> });
    close $fh;
    return $hash;
}

# Sync Richtung ClawHub → Git
sub sync_to_git {
    my ($skill_name, $dry_run) = @_;
    $dry_run //= 1;
    my $source = "$CLAWHUB_DIR/$skill_name";
    my $target = "$GIT_DIR/$skill_name";

    return 0 unless validate_skill($source);

    # Backup vor Änderungen (nur wenn target existiert)
    if (!$dry_run && -e $target) {
        create_backup($target, $skill_name) or return 0;
    }

    # Änderungen erkennen
    my @changes;
    find(sub {
        return if $_ eq '.git';
        my $rel_path = $File::Find::name;
        $rel_path =~ s/^$source//;
        $rel_path =~ s/^\///;
        return unless -f $_;
        my $tgt_file = "$target/$rel_path";
        if (!-e $tgt_file) {
            push @changes, "ADD $rel_path";
        } elsif (get_file_hash($_) ne get_file_hash($tgt_file)) {
            push @changes, "UPDATE $rel_path";
        }
    }, $source);

    # Dry-Run Report
    if ($dry_run) {
        log_message("DRY-RUN: $skill_name - " . scalar(@changes) . " changes");
        for my $change (@changes) {
            log_message("  $change");
        }
        return 1;
    }

    # Echte Synchronisation
    log_message("SYNC: $skill_name - Applying " . scalar(@changes) . " changes");
    if (-e $target) {
        remove_tree($target);
    }
    copy_recursive($source, $target);
    log_message("SYNC: $skill_name - Complete");
    return 1;
}

# Sync Richtung Git → ClawHub
sub sync_to_clawhub {
    my ($skill_name, $dry_run) = @_;
    $dry_run //= 1;
    my $source = "$GIT_DIR/$skill_name";
    my $target = "$CLAWHUB_DIR/$skill_name";

    return 0 unless validate_skill($source);

    # Backup vor Änderungen (nur wenn target existiert)
    if (!$dry_run && -e $target) {
        create_backup($target, $skill_name) or return 0;
    }

    # Änderungen erkennen (gleiche Logik wie oben)
    my @changes;
    find(sub {
        return if $_ eq '.git';
        my $rel_path = $File::Find::name;
        $rel_path =~ s/^$source//;
        $rel_path =~ s/^\///;
        return unless -f $_;
        my $tgt_file = "$target/$rel_path";
        if (!-e $tgt_file) {
            push @changes, "ADD $rel_path";
        } elsif (get_file_hash($_) ne get_file_hash($tgt_file)) {
            push @changes, "UPDATE $rel_path";
        }
    }, $source);

    # Dry-Run Report
    if ($dry_run) {
        log_message("DRY-RUN: $skill_name - " . scalar(@changes) . " changes");
        for my $change (@changes) {
            log_message("  $change");
        }
        return 1;
    }

    # Echte Synchronisation
    log_message("SYNC: $skill_name - Applying " . scalar(@changes) . " changes");
    if (-e $target) {
        remove_tree($target);
    }
    copy_recursive($source, $target);
    log_message("SYNC: $skill_name - Complete");
    return 1;
}

# Hauptfunktion
sub main {
    my ($skill, $direction, $dry_run, $force);
    GetOptions(
        "skill=s"     => \$skill,
        "direction=s" => \$direction,
        "dry-run"     => \$dry_run,
        "force"       => \$force,
    ) or die "Error in command line arguments\n";

    die "Missing --skill argument\n" unless defined $skill;
    die "Missing --direction argument\n" unless defined $direction;
    die "Invalid direction. Use 'to-git' or 'to-clawhub'\n"
        unless $direction eq 'to-git' || $direction eq 'to-clawhub';

    log_message("Starting sync: $skill ($direction)");

    my $success;
    if ($direction eq 'to-git') {
        $success = sync_to_git($skill, $dry_run);
    } else {
        $success = sync_to_clawhub($skill, $dry_run);
    }

    unless ($success) {
        log_message("Sync failed", "ERROR");
        exit 1;
    }

    log_message("Sync completed");
}

main() if !caller;
