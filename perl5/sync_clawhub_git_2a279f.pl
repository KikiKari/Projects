#!/usr/bin/env perl
# sync_clawhub_git.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:scripts/sync_clawhub_git.py
# auch in: Projects@clawhub:clawhub/Skills/sync_clawhub_git.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);
use File::Find;
use Digest::SHA qw(sha256_hex);
use Getopt::Long;
use JSON;
use Time::Piece;

# Konfiguration
# Resolve paths relative to this repository so the helper works both in the
# hosted workspace and in environments without a /workspace mount.
my $script_dir = $0;
$script_dir =~ s|/[^/]*$||;
my $WORKSPACE_ROOT = "$script_dir/../..";
my $CLAWHUB_DIR = "$WORKSPACE_ROOT/skills";
my $GIT_DIR = "$WORKSPACE_ROOT/git/skills";
my $BACKUP_DIR = "$WORKSPACE_ROOT/backups/sync";
my $LOG_FILE = "$WORKSPACE_ROOT/logs/sync-agent.log";
my %IGNORED_NAMES = map { $_ => 1 } qw(.git .clawhub node_modules __pycache__ .pytest_cache);
my %RESERVED_SKILL_NAMES = map { $_ => 1 } qw(github-clones skills backups .restore git Abstraktionen);
my %PRESERVED_TARGET_NAMES = %IGNORED_NAMES;

# Erstelle Verzeichnisse
make_path($GIT_DIR, { verbose => 0 });
make_path($BACKUP_DIR, { verbose => 0 });
make_path(dirname($LOG_FILE), { verbose => 0 });

sub dirname {
    my ($path) = @_;
    $path =~ s|/[^/]*$||;
    return $path;
}

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
    my $skill_name = basename($skill_dir);
    if (exists $RESERVED_SKILL_NAMES{$skill_name}) {
        log_message("Validation failed: $skill_name is reserved and must not be synced as a skill", "ERROR");
        return 0;
    }
    if (!-f "$skill_dir/SKILL.md") {
        log_message("Validation failed: $skill_name missing SKILL.md", "ERROR");
        return 0;
    }
    return 1;
}

sub basename {
    my ($path) = @_;
    $path =~ s|.*/||;
    return $path;
}

sub _is_ignored_path {
    my ($path) = @_;
    my @parts = split('/', $path);
    for my $part (@parts) {
        return 1 if exists $IGNORED_NAMES{$part};
    }
    return $path =~ /\.pyc$/;
}

sub _is_generated_duplicate_path {
    my ($root, $rel_path) = @_;
    my @parts = split('/', $rel_path);
    return 0 unless @parts;
    my $root_name = basename($root);
    return 1 if $parts[0] eq $root_name;
    for my $i (1 .. $#parts) {
        return 1 if $parts[$i] eq $parts[$i-1];
    }
    return 0;
}

sub iter_sync_files {
    my ($root) = @_;
    my @files;
    find(sub {
        return if (-d $_ && $_ eq '.git');
        my $full_path = $File::Find::name;
        my $rel_path = substr($full_path, length($root) + 1);
        return if _is_ignored_path($rel_path);
        return unless -f $_;
        push @files, [$full_path, $rel_path];
    }, $root);
    return @files;
}

sub reset_sync_target {
    my ($target) = @_;
    make_path($target, { verbose => 0 });
    opendir(my $dh, $target) or die "Could not open directory '$target': $!";
    while (readdir $dh) {
        next if $_ eq '.' or $_ eq '..';
        next if exists $PRESERVED_TARGET_NAMES{$_};
        my $child = "$target/$_";
        if (-d $child && !-l $child) {
            remove_tree($child);
        } else {
            unlink $child;
        }
    }
    closedir $dh;
}

sub copy_sync_files {
    my ($source, $target) = @_;
    reset_sync_target($target);
    my @files = iter_sync_files($source);
    for my $file_info (@files) {
        my ($src_file, $rel_path) = @$file_info;
        my $dest_file = "$target/$rel_path";
        my $dest_dir = dirname($dest_file);
        make_path($dest_dir, { verbose => 0 });
        copy($src_file, $dest_file) or die "Copy failed: $!";
    }
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
        make_path($backup_path, { verbose => 0 });
        my @files = iter_sync_files($source);
        for my $file_info (@files) {
            my ($src_file, $rel_path) = @$file_info;
            my $dest_file = "$backup_path/$rel_path";
            my $dest_dir = dirname($dest_file);
            make_path($dest_dir, { verbose => 0 });
            copy($src_file, $dest_file) or die "Copy failed: $!";
        }
        log_message("Backup created: $backup_path");
        return 1;
    };
    if ($@) {
        log_message("Backup failed: $@", "ERROR");
        return 0;
    }
}

# Hash-Vergleich
sub get_file_hash {
    my ($file_path) = @_;
    return "" unless -f $file_path;
    eval {
        open(my $fh, '<', $file_path) or die "Cannot open $file_path: $!";
        binmode($fh);
        my $hash = sha256_hex(do { local $/; <$fh> });
        close $fh;
        return $hash;
    };
    if ($@) {
        log_message("Failed to hash $file_path: $@", "ERROR");
        return "";
    }
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
        return 0 unless create_backup($target, $skill_name);
    }
    
    # Änderungen erkennen
    my @changes;
    my @files = iter_sync_files($source);
    for my $file_info (@files) {
        my ($src_file, $rel_path) = @$file_info;
        my $tgt_file = "$target/$rel_path";
        if (!-e $tgt_file) {
            push @changes, "ADD $rel_path";
        } elsif (get_file_hash($src_file) ne get_file_hash($tgt_file)) {
            push @changes, "UPDATE $rel_path";
        }
    }
    
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
    copy_sync_files($source, $target);
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
        return 0 unless create_backup($target, $skill_name);
    }

    # Änderungen erkennen (gleiche Logik wie oben)
    my @changes;
    my @files = iter_sync_files($source);
    for my $file_info (@files) {
        my ($src_file, $rel_path) = @$file_info;
        my $tgt_file = "$target/$rel_path";
        if (!-e $tgt_file) {
            push @changes, "ADD $rel_path";
        } elsif (get_file_hash($src_file) ne get_file_hash($tgt_file)) {
            push @changes, "UPDATE $rel_path";
        }
    }

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
    copy_sync_files($source, $target);
    log_message("SYNC: $skill_name - Complete");
    return 1;
}

# Hauptfunktion
sub main {
    my ($skill, $direction, $dry_run, $force);
    GetOptions(
        "skill=s" => \$skill,
        "direction=s" => \$direction,
        "dry-run" => \$dry_run,
        "force" => \$force,
    ) or die "Error in command line arguments\n";
    
    die "Missing --skill argument\n" unless defined $skill;
    die "Missing --direction argument\n" unless defined $direction;
    die "Invalid direction: $direction\n" unless $direction eq 'to-git' || $direction eq 'to-clawhub';
    
    log_message("Starting sync: $skill ($direction)");
    
    my $success;
    if ($direction eq 'to-git') {
        $success = sync_to_git($skill, $dry_run);
    } else {
        $success = sync_to_clawhub($skill, $dry_run);
    }
    
    if (!$success) {
        log_message("Sync failed", "ERROR");
        exit 1;
    }
    
    log_message("Sync completed");
}

main() if !caller;
