#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "4dc2108d711289706e259642791a029b02f04d469a312f8f42da4f5fed6c2e5c", "source_sha256": "5d90ebcd250a3cb80a0de664d94397af7ec03343d9d9fa64a28a9a11ad880754", "target_language": "perl5"}
# check_conflicts.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Find;
use Digest::MD5 qw(md5_hex);
use File::Spec;
use File::Basename;

binmode(STDOUT, ':encoding(UTF-8)');

# Konfiguration
my $CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills";
my $GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills";

# Hilfsfunktionen
sub get_file_hash {
    my ($file_path) = @_;
    open(my $fh, '<', $file_path) or die "Kann $file_path nicht öffnen: $!";
    binmode($fh);
    my $hash = md5_hex(<$fh>);
    close($fh);
    return $hash;
}

sub read_dir {
    my ($dir) = @_;
    opendir(my $dh, $dir) or die "Kann Verzeichnis $dir nicht öffnen: $!";
    my @files = grep { !/^\.{1,2}$/ } readdir($dh);
    closedir($dh);
    return @files;
}

sub find_files {
    my ($base_dir, $exclude_pattern) = @_;
    my %files;
    
    find(sub {
        return if -d $_;
        return if $File::Find::name =~ /$exclude_pattern/;
        my $rel_path = File::Spec->abs2rel($File::Find::name, $base_dir);
        $files{$rel_path} = $File::Find::name;
    }, $base_dir);
    
    return %files;
}

sub get_mtime {
    my ($file) = @_;
    my @stat = stat($file);
    return $stat[9];
}

sub format_time {
    my ($epoch) = @_;
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime($epoch);
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d", 
                   $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
}

sub check_conflicts {
    # Prüfe ob Verzeichnisse existieren
    unless (-d $CLAWHUB_DIR && -d $GIT_DIR) {
        print "Fehler: ClawHub oder Git Verzeichnis nicht gefunden\n";
        return;
    }
    
    # Lese Skills aus beiden Verzeichnissen
    my @clawhub_skills = read_dir($CLAWHUB_DIR);
    my @git_skills = read_dir($GIT_DIR);
    
    # Finde gemeinsame Skills
    my %clawhub_skills_map = map { $_ => 1 } @clawhub_skills;
    my @common_skills = grep { $clawhub_skills_map{$_} } @git_skills;
    
    print "Prüfe " . scalar(@common_skills) . " Skills auf Konflikte...\n\n";
    
    my @conflicts;
    
    for my $skill (sort @common_skills) {
        my $clawhub_path = File::Spec->catdir($CLAWHUB_DIR, $skill);
        my $git_path = File::Spec->catdir($GIT_DIR, $skill);
        
        # Überspringe wenn eines der Pfade kein Verzeichnis ist
        next unless -d $clawhub_path && -d $git_path;
        
        # Finde alle Dateien
        my %clawhub_files = find_files($clawhub_path, '\.git');
        my %git_files = find_files($git_path, '\.git');
        
        # Vergleiche gemeinsame Dateien
        my @clawhub_keys = keys %clawhub_files;
        my %clawhub_key_map = map { $_ => 1 } @clawhub_keys;
        my @common_files = grep { $clawhub_key_map{$_} } keys %git_files;
        
        my @skill_conflicts;
        
        for my $rel_path (@common_files) {
            my $clawhub_file = $clawhub_files{$rel_path};
            my $git_file = $git_files{$rel_path};
            
            if (get_file_hash($clawhub_file) ne get_file_hash($git_file)) {
                my $clawhub_mtime = get_mtime($clawhub_file);
                my $git_mtime = get_mtime($git_file);
                
                push @skill_conflicts, {
                    "file" => $rel_path,
                    "clawhub_modified" => format_time($clawhub_mtime),
                    "git_modified" => format_time($git_mtime),
                    "newer" => $clawhub_mtime > $git_mtime ? "clawhub" : "git"
                };
            }
        }
        
        if (@skill_conflicts) {
            push @conflicts, {
                "skill" => $skill,
                "conflicts" => \@skill_conflicts
            };
        }
    }
    
    # Ausgabe
    if (@conflicts) {
        print "⚠️  KONFLIKTE GEFUNDEN:\n";
        print "=" x 80 . "\n";
        
        for my $conflict (@conflicts) {
            print "\n📦 Skill: " . $conflict->{"skill"} . "\n";
            print "-" x 40 . "\n";
            
            for my $file_conflict (@{$conflict->{"conflicts"}}) {
                print "  📄 " . $file_conflict->{"file"} . "\n";
                print "     ClawHub: " . $file_conflict->{"clawhub_modified"} . "\n";
                print "     Git:     " . $file_conflict->{"git_modified"} . "\n";
                print "     Neuer:   " . uc($file_conflict->{"newer"}) . "\n";
                print "\n";
            }
        }
        
        print "=" x 80 . "\n";
        print "Gesamt: " . scalar(@conflicts) . " Skills mit Konflikten\n";
        print "\nNutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen.\n";
    } else {
        print "✅ Keine Konflikte gefunden!\n";
        print "Alle gemeinsamen Skills sind synchron.\n";
    }
}

sub main {
    check_conflicts();
}

main();
