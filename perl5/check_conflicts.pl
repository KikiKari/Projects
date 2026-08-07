#!/usr/bin/perl
# check_conflicts.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use File::Find;
use File::Spec;
use Time::Piece;

=head1 NAME

Check Conflicts - Erkennt Sync-Konflikte

=cut

# Konstanten
use constant CLAWHUB_DIR => '/home/openclaw/.openclaw/workspace/skills';
use constant GIT_DIR     => '/home/openclaw/.openclaw/workspace/git/skills';

# Hilfsfunktion zur Berechnung des SHA256-Hashes einer Datei
sub get_file_hash {
    my ($file_path) = @_;
    open my $fh, '<', $file_path or die "Kann Datei $file_path nicht öffnen: $!";
    binmode $fh;
    my $hash = sha256_hex(do { local $/; <$fh> });
    close $fh;
    return $hash;
}

# Rekursive Funktion zum Sammeln aller Dateien in einem Verzeichnis (ohne .git)
sub collect_files {
    my ($dir, $files_ref) = @_;
    find(
        sub {
            return if $_ eq '.git' && -d $_;
            return unless -f $_;
            my $full_path = $File::Find::name;
            my $rel_path = File::Spec->abs2rel($full_path, $dir);
            $files_ref->{$rel_path} = $full_path;
        },
        $dir
    );
}

sub check_conflicts {
    my @conflicts;

    # Alle Skills, die in beiden Orten existieren
    my @common_skills;
    if (-d CLAWHUB_DIR && -d GIT_DIR) {
        opendir(my $clawhub_dh, CLAWHUB_DIR) or die "Kann " . CLAWHUB_DIR . " nicht öffnen: $!";
        my @clawhub_skills = grep { -d File::Spec->catdir(CLAWHUB_DIR, $_) } readdir($clawhub_dh);
        closedir $clawhub_dh;

        opendir(my $git_dh, GIT_DIR) or die "Kann " . GIT_DIR . " nicht öffnen: $!";
        my @git_skills = grep { -d File::Spec->catdir(GIT_DIR, $_) } readdir($git_dh);
        closedir $git_dh;

        # Schnittmenge der Skills
        my %clawhub_skills_map = map { $_ => 1 } @clawhub_skills;
        @common_skills = grep { $clawhub_skills_map{$_} } @git_skills;
    }

    print "Prüfe " . scalar(@common_skills) . " Skills auf Konflikte...\n\n";

    for my $skill (sort @common_skills) {
        my $clawhub_path = File::Spec->catdir(CLAWHUB_DIR, $skill);
        my $git_path     = File::Spec->catdir(GIT_DIR, $skill);

        # Alle Dateien sammeln
        my (%clawhub_files, %git_files);
        collect_files($clawhub_path, \%clawhub_files);
        collect_files($git_path, \%git_files);

        # Gemeinsame Dateien vergleichen
        my @skill_conflicts;
        for my $rel_path (keys %clawhub_files) {
            next unless exists $git_files{$rel_path};

            my $clawhub_file = $clawhub_files{$rel_path};
            my $git_file     = $git_files{$rel_path};

            if (get_file_hash($clawhub_file) ne get_file_hash($git_file)) {
                my @clawhub_stat = stat($clawhub_file);
                my @git_stat     = stat($git_file);

                my $clawhub_mtime = localtime($clawhub_stat[9])->strftime('%Y-%m-%d %H:%M:%S');
                my $git_mtime     = localtime($git_stat[9])->strftime('%Y-%m-%d %H:%M:%S');

                push @skill_conflicts, {
                    file              => $rel_path,
                    clawhub_modified  => $clawhub_mtime,
                    git_modified      => $git_mtime,
                    newer             => $clawhub_stat[9] > $git_stat[9] ? 'clawhub' : 'git'
                };
            }
        }

        if (@skill_conflicts) {
            push @conflicts, {
                skill     => $skill,
                conflicts => \@skill_conflicts
            };
        }
    }

    # Ausgabe
    if (@conflicts) {
        print "⚠️  KONFLIKTE GEFUNDEN:\n";
        print "=" x 80 . "\n";

        for my $conflict (@conflicts) {
            print "\n📦 Skill: " . $conflict->{skill} . "\n";
            print "-" x 40 . "\n";

            for my $file_conflict (@{$conflict->{conflicts}}) {
                print "  📄 " . $file_conflict->{file} . "\n";
                print "     ClawHub: " . $file_conflict->{clawhub_modified} . "\n";
                print "     Git:     " . $file_conflict->{git_modified} . "\n";
                print "     Neuer:   " . uc($file_conflict->{newer}) . "\n";
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

main() if __FILE__ eq $0;
