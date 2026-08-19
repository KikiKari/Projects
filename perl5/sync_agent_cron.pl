#!/usr/bin/perl
# sync_agent_cron.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:scripts/sync_agent_cron.py
# auch in: OpenClaw@gateway2:scripts/sync_agent_cron.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Find;
use File::stat;
use Time::Piece;
use JSON;
use File::Path qw(make_path);
use Cwd;

# Füge das Verzeichnis zum Suchpfad hinzu
unshift @INC, '/home/openclaw/.openclaw/workspace/scripts';

# Lade Funktionen aus dem externen Modul (simuliert)
# In echtem Perl würde man hier ein richtiges Modul laden
# Für diesen Port simulieren wir die benötigten Funktionen

# Globale Variablen
my $CLAWHUB_DIR = '/home/openclaw/.openclaw/workspace/skills';
my $GIT_DIR = '/home/openclaw/.openclaw/workspace/git/skills';
my $LOG_FILE = '/home/openclaw/.openclaw/workspace/logs/sync-agent.log';

# Simulierte externe Funktionen
sub sync_to_git {
    my ($skill, $dry_run) = @_;
    # Dummy-Implementierung für den Port
    return 1 unless $dry_run;
    return int(rand(2)); # Zufälliger Erfolg für Tests
}

sub sync_to_clawhub {
    my ($skill, $dry_run) = @_;
    # Dummy-Implementierung für den Port
    return 1 unless $dry_run;
    return int(rand(2)); # Zufälliger Erfolg für Tests
}

sub validate_skill {
    my ($path) = @_;
    # Dummy-Validierung
    return -d $path;
}

# Log-Funktion
sub write_to_log {
    my ($message, $level) = @_;
    $level //= "INFO";
    my $timestamp = localtime->strftime('%Y-%m-%d %H:%M:%S');
    my $entry = "[$timestamp] [$level] $message\n";
    print $entry;
    open(my $fh, '>>', $LOG_FILE) or die "Kann Log-Datei nicht öffnen: $!";
    print $fh $entry;
    close($fh);
}

# Hilfsfunktion zur Bestimmung der neuesten Dateizeit
sub file_mtime {
    my ($path) = @_;
    my @files;
    
    find(sub {
        return if $_ eq '.git' && -d $File::Find::name;
        push @files, $File::Find::name if -f $_;
    }, $path);
    
    return 0 unless @files;
    
    my $max_time = 0;
    for my $file (@files) {
        my $st = stat($file);
        next unless $st;
        $max_time = $st->mtime if $st->mtime > $max_time;
    }
    
    return $max_time;
}

# Hauptprogramm
write_to_log("=" x 70);
write_to_log("CLAWHUB ↔ GIT SYNC AGENT - CRON LAUF");
write_to_log("Zeitstempel: " . localtime->datetime);

# Sammle Skill-Verzeichnisse
sub get_skills {
    my ($dir) = @_;
    opendir(my $dh, $dir) or die "Kann Verzeichnis nicht öffnen: $!";
    my @skills = grep { !/^\./ && -d "$dir/$_" } readdir($dh);
    closedir($dh);
    return \@skills;
}

my $clawhub_skills = get_skills($CLAWHUB_DIR);
my $git_skills = get_skills($GIT_DIR);

# Erstelle Sets für Vergleich
my %clawhub_set = map { $_ => 1 } @$clawhub_skills;
my %git_set = map { $_ => 1 } @$git_skills;

# DRY-RUN: Erkenne Änderungen
write_to_log("\n[DRY-RUN] Analysiere Änderungen...");

my %changes_detected = (
    "new_in_clawhub" => [],
    "new_in_git" => [],
    "clawhub_newer" => [],
    "git_newer" => [],
    "synced" => []
);

# 1. Neue Skills
my @new_in_clawhub = sort grep { !$git_set{$_} } @$clawhub_skills;
my @new_in_git = sort grep { !$clawhub_set{$_} } @$git_skills;

$changes_detected{"new_in_clawhub"} = \@new_in_clawhub;
$changes_detected{"new_in_git"} = \@new_in_git;

# 2. Existierende prüfen
my @in_both = sort grep { $clawhub_set{$_} && $git_set{$_} } @$clawhub_skills;
for my $skill (@in_both) {
    my $c_mtime = file_mtime("$CLAWHUB_DIR/$skill");
    my $g_mtime = file_mtime("$GIT_DIR/$skill");
    my $diff = $c_mtime - $g_mtime;
    
    if (abs($diff) > 60) {
        if ($diff > 0) {
            push @{$changes_detected{"clawhub_newer"}}, [$skill, $diff];
        } else {
            push @{$changes_detected{"git_newer"}}, [$skill, abs($diff)];
        }
    } else {
        push @{$changes_detected{"synced"}}, $skill;
    }
}

# Report
my $total_changes = 
    scalar(@new_in_clawhub) + 
    scalar(@new_in_git) + 
    scalar(@{$changes_detected{"clawhub_newer"}}) + 
    scalar(@{$changes_detected{"git_newer"}});

write_to_log("Neu in ClawHub: " . scalar(@new_in_clawhub));
write_to_log("Neu in Git: " . scalar(@new_in_git));
write_to_log("ClawHub neuer: " . scalar(@{$changes_detected{"clawhub_newer"}}));
write_to_log("Git neuer: " . scalar(@{$changes_detected{"git_newer"}}));
write_to_log("Synchron: " . scalar(@{$changes_detected{"synced"}}));

if ($total_changes == 0) {
    write_to_log("\n✅ Keine Änderungen erkannt. Sync nicht nötig.");
    write_to_log("=" x 70);
    exit(0);
}

write_to_log("\n🔄 $total_changes Änderungen erkannt - starte Synchronisation...");

# ECHTE SYNCHRONISATION
my %results = (
    "synced_to_git" => [],
    "synced_to_clawhub" => [],
    "up_to_date" => [],
    "errors" => []
);

# 1. NEU in ClawHub → zu Git
for my $skill (@new_in_clawhub) {
    eval {
        if (validate_skill("$CLAWHUB_DIR/$skill")) {
            write_to_log("→ Synchronisiere $skill zu Git...");
            if (sync_to_git($skill, 0)) { # dry_run=false
                my $git_path = "$GIT_DIR/$skill";
                chdir($git_path) or die "Kann nicht ins Verzeichnis wechseln: $!";
                system('git init -q 2>/dev/null');
                system('git add . -f 2>/dev/null');
                my $dt = localtime->strftime("%Y-%m-%d %H:%M");
                system("git commit -m \"Initial: $skill\" -q 2>/dev/null");
                push @{$results{"synced_to_git"}}, $skill;
                write_to_log("  ✓ $skill synchronisiert");
            }
        } else {
            push @{$results{"errors"}}, "$skill (invalid)";
        }
        1;
    } or do {
        my $error = $@ || 'Unknown error';
        write_to_log("  ✗ ERROR: $skill - $error", "ERROR");
        push @{$results{"errors"}}, "$skill";
    };
}

# 2. NEU in Git → zu ClawHub
for my $skill (@new_in_git) {
    eval {
        if (validate_skill("$GIT_DIR/$skill")) {
            write_to_log("→ Synchronisiere $skill zu ClawHub...");
            if (sync_to_clawhub($skill, 0)) { # dry_run=false
                push @{$results{"synced_to_clawhub"}}, $skill;
                write_to_log("  ✓ $skill synchronisiert");
            }
        } else {
            push @{$results{"errors"}}, "$skill (invalid)";
        }
        1;
    } or do {
        my $error = $@ || 'Unknown error';
        write_to_log("  ✗ ERROR: $skill - $error", "ERROR");
        push @{$results{"errors"}}, "$skill";
    };
}

# 3. Updates
for my $item (@{$changes_detected{"clawhub_newer"}}) {
    my ($skill, $diff) = @$item;
    eval {
        write_to_log("→ Update $skill (ClawHub +${diff}s neuer)...");
        if (sync_to_git($skill, 0)) { # dry_run=false
            my $git_path = "$GIT_DIR/$skill";
            chdir($git_path) or die "Kann nicht ins Verzeichnis wechseln: $!";
            system('git add . -f 2>/dev/null');
            my $dt = localtime->strftime("%Y-%m-%d %H:%M");
            system("git commit -m \"Sync from ClawHub: $dt\" -q 2>/dev/null");
            push @{$results{"synced_to_git"}}, $skill;
            write_to_log("  ✓ $skill aktualisiert");
        }
        1;
    } or do {
        my $error = $@ || 'Unknown error';
        write_to_log("  ✗ ERROR: $skill - $error", "ERROR");
        push @{$results{"errors"}}, "$skill";
    };
}

for my $item (@{$changes_detected{"git_newer"}}) {
    my ($skill, $diff) = @$item;
    eval {
        write_to_log("→ Update $skill (Git +${diff}s neuer)...");
        if (sync_to_clawhub($skill, 0)) { # dry_run=false
            push @{$results{"synced_to_clawhub"}}, $skill;
            write_to_log("  ✓ $skill aktualisiert");
        }
        1;
    } or do {
        my $error = $@ || 'Unknown error';
        write_to_log("  ✗ ERROR: $skill - $error", "ERROR");
        push @{$results{"errors"}}, "$skill";
    };
}

$results{"up_to_date"} = $changes_detected{"synced"};

# ZUSAMMENFASSUNG
write_to_log("\n" . "=" x 70);
write_to_log("SYNCHRONISATION ABGESCHLOSSEN");
write_to_log("=" x 70);
write_to_log("Zu Git synchronisiert:     " . scalar(@{$results{"synced_to_git"}}));
write_to_log("Zu ClawHub synchronisiert: " . scalar(@{$results{"synced_to_clawhub"}}));
write_to_log("Bereits aktuell:           " . scalar(@{$results{"up_to_date"}}));
write_to_log("Fehler:                    " . scalar(@{$results{"errors"}}));

if (@{$results{"errors"}}) {
    write_to_log("  Fehlerhafte: " . join(", ", @{$results{"errors"}}));
}
write_to_log("=" x 70);

# State speichern
my $STATE_FILE = "/home/openclaw/.openclaw/workspace/db/sync_state.json";
my $state_dir = "/home/openclaw/.openclaw/workspace/db";
make_path($state_dir) unless -d $state_dir;

my $state = {
    "last_run" => localtime->datetime,
    "results" => \%results,
    "changes_detected" => {
        map { $_ => ref($changes_detected{$_}) eq 'ARRAY' ? scalar(@{$changes_detected{$_}}) : $changes_detected{$_} } keys %changes_detected
    }
};

open(my $fh, '>', $STATE_FILE) or die "Kann State-Datei nicht öffnen: $!";
print $fh to_json($state, { pretty => 1 });
close($fh);
write_to_log("State gespeichert: $STATE_FILE");
