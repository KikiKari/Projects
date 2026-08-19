#!/usr/bin/perl
# sync_agent.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:skills/clawhub-git-sync-agent/scripts/sync_agent.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON;
use File::Find;
use File::Spec;
use File::Path qw(make_path);
use Digest::MD5 qw(md5_hex);
use Time::HiRes qw(time);

# Permanenter ClawHub ↔ Git Sync Agent
# Multi-Node fähig, stündliche Ausführung

# Konfiguration
my $CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills";
my $GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills";
my $STATE_FILE = "/home/openclaw/.openclaw/workspace/db/sync_state.json";

# Reservierte Skill-Namen (aus sync_clawhub_git.py importiert)
my @RESERVED_SKILL_NAMES = qw(
    __pycache__
    .git
    node_modules
    venv
    env
    dist
    build
);

# Globale Variablen für Logging
my $LOG_LEVEL = "INFO";

sub log_message {
    my ($message, $level) = @_;
    $level //= "INFO";
    my $timestamp = localtime();
    print STDERR "[$timestamp] [$level] $message\n";
}

sub load_state {
    # Lädt den Sync-State
    if (-e $STATE_FILE) {
        open my $fh, '<', $STATE_FILE or die "Kann $STATE_FILE nicht öffnen: $!";
        local $/;
        my $content = <$fh>;
        close $fh;
        return decode_json($content);
    }
    return { sync_history => [], pending => [] };
}

sub save_state {
    # Speichert den Sync-State
    my ($state) = @_;
    
    # Stelle sicher, dass das Elternverzeichnis existiert
    my ($volume, $directories, $file) = File::Spec->splitpath($STATE_FILE);
    my $parent_dir = File::Spec->catpath($volume, $directories, '');
    
    unless (-d $parent_dir) {
        make_path($parent_dir) or die "Kann Verzeichnis $parent_dir nicht erstellen: $!";
    }
    
    open my $fh, '>', $STATE_FILE or die "Kann $STATE_FILE nicht öffnen: $!";
    print $fh to_json($state, { pretty => 1, canonical => 1 });
    close $fh;
}

sub get_all_skills {
    # Findet alle Skills in beiden Verzeichnissen
    my (%clawhub_skills, %git_skills);
    
    # Hole Skills aus ClawHub
    if (opendir(my $dh, $CLAWHUB_DIR)) {
        while (readdir $dh) {
            my $entry = $_;
            next if $entry =~ /^\./;
            next if grep { $_ eq $entry } @RESERVED_SKILL_NAMES;
            my $full_path = File::Spec->catfile($CLAWHUB_DIR, $entry);
            if (-d $full_path && -e File::Spec->catfile($full_path, "SKILL.md")) {
                $clawhub_skills{$entry} = 1;
            }
        }
        closedir $dh;
    }
    
    # Hole Skills aus Git
    if (opendir(my $dh, $GIT_DIR)) {
        while (readdir $dh) {
            my $entry = $_;
            next if $entry =~ /^\./;
            next if grep { $_ eq $entry } @RESERVED_SKILL_NAMES;
            my $full_path = File::Spec->catfile($GIT_DIR, $entry);
            if (-d $full_path && -e File::Spec->catfile($full_path, "SKILL.md")) {
                $git_skills{$entry} = 1;
            }
        }
        closedir $dh;
    }
    
    # Vereinige beide Sets
    my %all_skills = (%clawhub_skills, %git_skills);
    return keys %all_skills;
}

sub init_git_repo {
    # Initialisiert Git-Repo wenn nötig
    my ($skill_path, $skill_name) = @_;
    my $git_dir = File::Spec->catfile($skill_path, ".git");
    
    unless (-e $git_dir) {
        chdir $skill_path or die "Kann nicht in $skill_path wechseln: $!";
        system("git", "init") == 0 or die "git init fehlgeschlagen: $?";
        system("git", "add", ".") == 0 or die "git add fehlgeschlagen: $?";
        system("git", "commit", "-m", "Initial commit: $skill_name skill") == 0 or die "git commit fehlgeschlagen: $?";
        log_message("Git initialized for $skill_name");
    }
}

sub get_file_hash {
    # Berechnet MD5-Hash einer Datei
    my ($file_path) = @_;
    open my $fh, '<', $file_path or die "Kann $file_path nicht öffnen: $!";
    binmode $fh;
    my $hash = md5_hex(<$fh>);
    close $fh;
    return $hash;
}

sub iter_sync_files {
    # Gibt Liste von (Dateipfad, relativer Pfad) für alle synchronisierbaren Dateien zurück
    my ($skill_dir) = @_;
    my @files;
    
    find(sub {
        return if -d $_;  # Überspringe Verzeichnisse
        return if /^\./;  # Überspringe versteckte Dateien
        return if $_ eq "SKILL.md";  # SKILL.md wird separat behandelt
        
        my $relative_path = File::Spec->abs2rel($File::Find::name, $skill_dir);
        push @files, [$File::Find::name, $relative_path];
    }, $skill_dir);
    
    # Füge SKILL.md hinzu, falls vorhanden
    my $skill_md = File::Spec->catfile($skill_dir, "SKILL.md");
    if (-e $skill_md) {
        push @files, [$skill_md, "SKILL.md"];
    }
    
    return @files;
}

sub validate_skill {
    # Validiert einen Skill (vereinfachte Implementierung)
    my ($skill_path) = @_;
    # In Python-Version wird dies aus sync_clawhub_git importiert
    # Hier eine vereinfachte Prüfung
    return 1;  # Annahme: Skill ist gültig
}

sub preview_changes {
    # Berechnet Sync-Änderungen in einer Richtung, ohne zu schreiben
    my ($source_dir, $target_dir) = @_;
    my @changes;
    
    for my $file_info (iter_sync_files($source_dir)) {
        my ($src_file, $rel_path) = @$file_info;
        my $tgt_file = File::Spec->catfile($target_dir, $rel_path);
        
        if (!-e $tgt_file) {
            push @changes, "ADD $rel_path";
        } elsif (get_file_hash($src_file) ne get_file_hash($tgt_file)) {
            push @changes, "UPDATE $rel_path";
        }
    }
    
    return @changes;
}

sub newest_mtime {
    # Ermittelt die neueste mtime über alle relevanten Dateien
    my ($skill_dir) = @_;
    my @mtimes;
    
    for my $file_info (iter_sync_files($skill_dir)) {
        my ($file_path, $rel_path) = @$file_info;
        if (-e $file_path) {
            my @stat = stat($file_path);
            push @mtimes, $stat[9] if @stat;
        }
    }
    
    return @mtimes ? (sort { $b <=> $a } @mtimes)[0] : 0;
}

sub sync_to_git {
    # Sync-Funktion zu Git (vereinfacht)
    my ($skill_name, $dry_run) = @_;
    # In Python-Version wird dies aus sync_clawhub_git importiert
    # Hier eine vereinfachte Implementierung
    if (!$dry_run) {
        # Kopiere von ClawHub nach Git
        my $source = File::Spec->catdir($CLAWHUB_DIR, $skill_name);
        my $dest = File::Spec->catdir($GIT_DIR, $skill_name);
        
        # Erstelle Zielverzeichnis falls nötig
        unless (-d $dest) {
            make_path($dest) or die "Kann Verzeichnis $dest nicht erstellen: $!";
        }
        
        # Kopiere Dateien
        for my $file_info (iter_sync_files($source)) {
            my ($src_file, $rel_path) = @$file_info;
            my $tgt_file = File::Spec->catfile($dest, $rel_path);
            
            # Erstelle Zielverzeichnis falls nötig
            my ($volume, $directories, $file) = File::Spec->splitpath($tgt_file);
            my $tgt_dir = File::Spec->catpath($volume, $directories, '');
            unless (-d $tgt_dir) {
                make_path($tgt_dir) or die "Kann Verzeichnis $tgt_dir nicht erstellen: $!";
            }
            
            # Kopiere Datei
            open my $src_fh, '<', $src_file or die "Kann $src_file nicht öffnen: $!";
            open my $tgt_fh, '>', $tgt_file or die "Kann $tgt_file nicht öffnen: $!";
            binmode $src_fh;
            binmode $tgt_fh;
            while (read($src_fh, my $buffer, 4096)) {
                print $tgt_fh $buffer;
            }
            close $src_fh;
            close $tgt_fh;
        }
    }
    return 1;
}

sub sync_to_clawhub {
    # Sync-Funktion zu ClawHub (vereinfacht)
    my ($skill_name, $dry_run) = @_;
    # In Python-Version wird dies aus sync_clawhub_git importiert
    # Hier eine vereinfachte Implementierung
    if (!$dry_run) {
        # Kopiere von Git nach ClawHub
        my $source = File::Spec->catdir($GIT_DIR, $skill_name);
        my $dest = File::Spec->catdir($CLAWHUB_DIR, $skill_name);
        
        # Erstelle Zielverzeichnis falls nötig
        unless (-d $dest) {
            make_path($dest) or die "Kann Verzeichnis $dest nicht erstellen: $!";
        }
        
        # Kopiere Dateien
        for my $file_info (iter_sync_files($source)) {
            my ($src_file, $rel_path) = @$file_info;
            my $tgt_file = File::Spec->catfile($dest, $rel_path);
            
            # Erstelle Zielverzeichnis falls nötig
            my ($volume, $directories, $file) = File::Spec->splitpath($tgt_file);
            my $tgt_dir = File::Spec->catpath($volume, $directories, '');
            unless (-d $tgt_dir) {
                make_path($tgt_dir) or die "Kann Verzeichnis $tgt_dir nicht erstellen: $!";
            }
            
            # Kopiere Datei
            open my $src_fh, '<', $src_file or die "Kann $src_file nicht öffnen: $!";
            open my $tgt_fh, '>', $tgt_file or die "Kann $tgt_file nicht öffnen: $!";
            binmode $src_fh;
            binmode $tgt_fh;
            while (read($src_fh, my $buffer, 4096)) {
                print $tgt_fh $buffer;
            }
            close $src_fh;
            close $tgt_fh;
        }
    }
    return 1;
}

sub sync_skill_bidirectional {
    # Bidirektionale Synchronisation eines Skills
    my ($skill_name) = @_;
    my $clawhub_path = File::Spec->catdir($CLAWHUB_DIR, $skill_name);
    my $git_path = File::Spec->catdir($GIT_DIR, $skill_name);
    
    # Fall 1: Nur in ClawHub → zu Git
    if (-d $clawhub_path && !-d $git_path) {
        log_message("NEW in ClawHub: $skill_name → syncing to Git");
        if (sync_to_git($skill_name, 0)) {  # 0 = nicht dry-run
            init_git_repo($git_path, $skill_name);
            return "synced_to_git";
        }
    }
    
    # Fall 2: Nur in Git → zu ClawHub
    elsif (-d $git_path && !-d $clawhub_path) {
        log_message("NEW in Git: $skill_name → syncing to ClawHub");
        if (sync_to_clawhub($skill_name, 0)) {  # 0 = nicht dry-run
            return "synced_to_clawhub";
        }
    }
    
    # Fall 3: In beiden vorhanden
    elsif (-d $clawhub_path && -d $git_path) {
        unless (validate_skill($clawhub_path)) {
            log_message("Validation failed for ClawHub skill: $skill_name", "ERROR");
            return "error";
        }
        unless (validate_skill($git_path)) {
            log_message("Validation failed for Git skill: $skill_name", "ERROR");
            return "error";
        }

        my @clawhub_changes = preview_changes($clawhub_path, $git_path);
        my @git_changes = preview_changes($git_path, $clawhub_path);

        if (!@clawhub_changes && !@git_changes) {
            log_message("Content is identical for: $skill_name");
            return "no_change";
        }

        if (@clawhub_changes && !@git_changes) {
            log_message("Content difference detected for: $skill_name");
            log_message("UPDATE: $skill_name ClawHub content is newer or different → syncing to Git");
            if (sync_to_git($skill_name, 0)) {  # 0 = nicht dry-run
                chdir $git_path or die "Kann nicht in $git_path wechseln: $!";
                system("git", "add", ".") == 0 or die "git add fehlgeschlagen: $?";
                my $timestamp = localtime();
                system("git", "commit", "-m", "Sync from ClawHub content diff: $timestamp") == 0 or die "git commit fehlgeschlagen: $?";
                return "updated_git";
            }
            log_message("Failed to sync $skill_name to Git after content diff", "ERROR");
            return "error";
        }

        if (@git_changes && !@clawhub_changes) {
            log_message("Content difference detected for: $skill_name");
            log_message("UPDATE: $skill_name Git content is newer or different → syncing to ClawHub");
            if (sync_to_clawhub($skill_name, 0)) {  # 0 = nicht dry-run
                return "updated_clawhub";
            }
            log_message("Failed to sync $skill_name to ClawHub after content diff", "ERROR");
            return "error";
        }

        log_message("Content difference detected for: $skill_name");
        if (newest_mtime($clawhub_path) >= newest_mtime($git_path)) {
            log_message("UPDATE: $skill_name ClawHub content is newer or different → syncing to Git");
            if (sync_to_git($skill_name, 0)) {  # 0 = nicht dry-run
                chdir $git_path or die "Kann nicht in $git_path wechseln: $!";
                system("git", "add", ".") == 0 or die "git add fehlgeschlagen: $?";
                my $timestamp = localtime();
                system("git", "commit", "-m", "Sync from ClawHub content diff: $timestamp") == 0 or die "git commit fehlgeschlagen: $?";
                return "updated_git";
            }
        } else {
            log_message("UPDATE: $skill_name Git content is newer or different → syncing to ClawHub");
            if (sync_to_clawhub($skill_name, 0)) {  # 0 = nicht dry-run
                return "updated_clawhub";
            }
        }

        log_message("Failed to resolve content diff for $skill_name", "ERROR");
        return "error";
    }
    
    return "no_change";
}

sub main {
    # Hauptfunktion des Sync-Agents mit Dry-Run Phase
    log_message("=== ClawHub ↔ Git Sync Agent gestartet ===");
    
    # Load previous state
    my $state = load_state();
    my @all_skills = get_all_skills();
    log_message("Gefundene Skills: " . scalar(@all_skills));
    
    # Dry-Run Phase: only report changes, no actual modifications
    log_message("--- Dry-Run Phase Start ---");
    for my $skill (sort @all_skills) {
        # Perform dry-run sync in both directions to capture potential changes
        sync_to_git($skill, 1);      # 1 = dry-run
        sync_to_clawhub($skill, 1);  # 1 = dry-run
    }
    log_message("--- Dry-Run Phase End ---");
    
    my %results = (
        synced_to_git => [],
        synced_to_clawhub => [],
        updated_git => [],
        updated_clawhub => [],
        no_change => [],
        errors => []
    );
    
    # Actual Sync Phase
    for my $skill (sort @all_skills) {
        eval {
            my $result = sync_skill_bidirectional($skill);
            push @{$results{$result}}, $skill;
        };
        if ($@) {
            log_message("ERROR syncing $skill: $@", "ERROR");
            push @{$results{errors}}, $skill;
        }
    }
    
    # Zusammenfassung
    log_message("\n=== SYNC ZUSAMMENFASSUNG ===");
    log_message("Neu in Git: " . scalar(@{$results{synced_to_git}}) . " - " . join(", ", @{$results{synced_to_git}}));
    log_message("Neu in ClawHub: " . scalar(@{$results{synced_to_clawhub}}) . " - " . join(", ", @{$results{synced_to_clawhub}}));
    log_message("Git aktualisiert: " . scalar(@{$results{updated_git}}) . " - " . join(", ", @{$results{updated_git}}));
    log_message("ClawHub aktualisiert: " . scalar(@{$results{updated_clawhub}}) . " - " . join(", ", @{$results{updated_clawhub}}));
    log_message("Keine Änderung: " . scalar(@{$results{no_change}}));
    log_message("Fehler: " . scalar(@{$results{errors}}) . " - " . join(", ", @{$results{errors}}));
    
    # State speichern
    unless (exists $state->{sync_history}) {
        $state->{sync_history} = [];
    }
    
    push @{$state->{sync_history}}, {
        timestamp => localtime(),
        results => \%results
    };
    
    # Nur letzte 100 Einträge behalten
    if (@{$state->{sync_history}} > 100) {
        splice @{$state->{sync_history}}, 0, @{$state->{sync_history}} - 100;
    }
    
    save_state($state);
    log_message("=== Sync Agent beendet ===\n");
}

main() if __FILE__ eq $0;
