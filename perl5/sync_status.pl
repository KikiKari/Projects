#!/usr/bin/perl
# sync_status.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/sync_status.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/sync_status.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use File::Find;
use File::Spec;
use POSIX qw(strftime);

# Sync Status - Zeigt Status aller Skills

my $CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills";
my $GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills";
my $STATE_FILE = "/home/openclaw/.openclaw/workspace/db/sync_state.json";

sub get_max_mtime {
    my ($path) = @_;
    my $max_mtime = 0;
    
    find(sub {
        return if -d $_;
        return if $_ eq '.' || $_ eq '..';
        return if $File::Find::dir =~ /\.git/;
        my $full_path = $File::Find::name;
        my @stat = stat($full_path);
        if (@stat && $stat[9] > $max_mtime) {
            $max_mtime = $stat[9];
        }
    }, $path);
    
    return $max_mtime;
}

sub check_skill_status {
    my ($skill_name) = @_;
    
    my $clawhub_path = File::Spec->catdir($CLAWHUB_DIR, $skill_name);
    my $git_path = File::Spec->catdir($GIT_DIR, $skill_name);
    
    my %status = (
        name => $skill_name,
        in_clawhub => -d $clawhub_path,
        in_git => -d $git_path,
        has_git_repo => (-d $git_path && -d File::Spec->catdir($git_path, ".git")),
        status => "unknown",
        last_modified => {}
    );
    
    # Status bestimmen
    if ($status{in_clawhub} && !$status{in_git}) {
        $status{status} = "only_clawhub";
    } elsif ($status{in_git} && !$status{in_clawhub}) {
        $status{status} = "only_git";
    } elsif ($status{in_clawhub} && $status{in_git}) {
        # Timestamps vergleichen
        eval {
            my $clawhub_mtime = get_max_mtime($clawhub_path);
            my $git_mtime = get_max_mtime($git_path);
            
            $status{last_modified}->{clawhub} = strftime('%Y-%m-%d %H:%M:%S', localtime($clawhub_mtime));
            $status{last_modified}->{git} = strftime('%Y-%m-%d %H:%M:%S', localtime($git_mtime));
            
            if (abs($clawhub_mtime - $git_mtime) < 60) {
                $status{status} = "synced";
            } elsif ($clawhub_mtime > $git_mtime) {
                $status{status} = "clawhub_newer";
            } else {
                $status{status} = "git_newer";
            }
        };
        if ($@) {
            $status{status} = "error";
        }
    }
    
    return \%status;
}

sub main {
    print "=" x 80 . "\n";
    print "ClawHub ↔ Git Sync Status\n";
    print "=" x 80 . "\n";
    print "Zeitpunkt: " . strftime('%Y-%m-%d %H:%M:%S', localtime()) . "\n\n";
    
    # Alle Skills finden
    my %all_skills;
    
    if (-d $CLAWHUB_DIR) {
        opendir(my $dh, $CLAWHUB_DIR) or die "Cannot open directory $CLAWHUB_DIR: $!";
        while (readdir $dh) {
            next if /^\./;
            my $path = File::Spec->catdir($CLAWHUB_DIR, $_);
            $all_skills{$_} = 1 if -d $path;
        }
        closedir $dh;
    }
    
    if (-d $GIT_DIR) {
        opendir(my $dh, $GIT_DIR) or die "Cannot open directory $GIT_DIR: $!";
        while (readdir $dh) {
            next if /^\./;
            my $path = File::Spec->catdir($GIT_DIR, $_);
            $all_skills{$_} = 1 if -d $path;
        }
        closedir $dh;
    }
    
    # Status-Kategorien
    my %categories = (
        synced => [],
        clawhub_newer => [],
        git_newer => [],
        only_clawhub => [],
        only_git => [],
        error => []
    );
    
    # Status für jeden Skill prüfen
    for my $skill (sort keys %all_skills) {
        my $status = check_skill_status($skill);
        push @{$categories{$status->{status}}}, $status;
    }
    
    # Ausgabe
    my $total_skills = scalar(keys %all_skills);
    print "📊 Gesamt: $total_skills Skills\n\n";
    
    # Synchronisiert
    if (@{$categories{synced}}) {
        print "✅ Synchronisiert (" . scalar(@{$categories{synced}}) . ")\n";
        for my $s (@{$categories{synced}}) {
            print "   - " . $s->{name} . "\n";
        }
        print "\n";
    }
    
    # ClawHub neuer
    if (@{$categories{clawhub_newer}}) {
        print "🔄 ClawHub neuer (" . scalar(@{$categories{clawhub_newer}}) . ")\n";
        for my $s (@{$categories{clawhub_newer}}) {
            print "   - " . $s->{name} . " (ClawHub: " . $s->{last_modified}->{clawhub} . ")\n";
        }
        print "\n";
    }
    
    # Git neuer
    if (@{$categories{git_newer}}) {
        print "🔄 Git neuer (" . scalar(@{$categories{git_newer}}) . ")\n";
        for my $s (@{$categories{git_newer}}) {
            print "   - " . $s->{name} . " (Git: " . $s->{last_modified}->{git} . ")\n";
        }
        print "\n";
    }
    
    # Nur in ClawHub
    if (@{$categories{only_clawhub}}) {
        print "📦 Nur in ClawHub (" . scalar(@{$categories{only_clawhub}}) . ")\n";
        for my $s (@{$categories{only_clawhub}}) {
            print "   - " . $s->{name} . "\n";
        }
        print "\n";
    }
    
    # Nur in Git
    if (@{$categories{only_git}}) {
        print "📁 Nur in Git (" . scalar(@{$categories{only_git}}) . ")\n";
        for my $s (@{$categories{only_git}}) {
            print "   - " . $s->{name} . "\n";
        }
        print "\n";
    }
    
    # Fehler
    if (@{$categories{error}}) {
        print "❌ Fehler (" . scalar(@{$categories{error}}) . ")\n";
        for my $s (@{$categories{error}}) {
            print "   - " . $s->{name} . "\n";
        }
        print "\n";
    }
    
    # State-File Info
    if (-f $STATE_FILE) {
        open(my $fh, '<', $STATE_FILE) or die "Cannot open file $STATE_FILE: $!";
        my $json_text = do { local $/; <$fh> };
        close $fh;
        my $state = decode_json($json_text);
        my @last_runs = keys %{$state->{last_sync}//{}};
        if (@last_runs) {
            @last_runs = sort @last_runs;
            print "📅 Letzter automatischer Sync: $last_runs[-1]\n";
        }
    }
    
    print "=" x 80 . "\n";
}

main() if __FILE__ eq $0;
