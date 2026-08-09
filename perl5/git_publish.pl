#!/usr/bin/env perl
# git_publish.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
# auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use File::Spec;
use File::Basename;
use Cwd 'abs_path';
use POSIX qw(strftime);

# Git Publish Agent - Automatisierte Skill-Veröffentlichung

my $SKILLS_DIR = File::Spec->catfile($ENV{HOME}, ".openclaw", "workspace", "skills");

sub git_commit {
    my ($skill_path, $message) = @_;
    
    # Default message if none provided
    if (!defined $message) {
        my $timestamp = strftime "%Y-%m-%dT%H:%M:%S", localtime;
        $message = "[skill] Auto-update " . basename($skill_path) . " - $timestamp";
    }
    
    my $parent_dir = dirname($SKILLS_DIR);
    system("git", "add", $skill_path) == 0 or return 0;
    my $result = system("git", "commit", "-m", $message, "cwd", $parent_dir);
    return $result == 0;
}

sub clawhub_publish {
    my ($skill_name) = @_;
    my $skill_path = File::Spec->catfile($SKILLS_DIR, $skill_name);
    my @cmd = ("clawhub", "publish", $skill_path, "--slug", $skill_name, "--version", "1.0.0");
    
    open(my $fh, '-|', @cmd) or die "Could not execute clawhub: $!";
    my $output = do { local $/; <$fh> };
    close $fh;
    my $success = ($? >> 8) == 0;
    
    return ($success, $output);
}

sub batch_publish {
    # Check git status
    my $status_cmd = "git status --short " . $SKILLS_DIR;
    open(my $fh, '-|', $status_cmd) or die "Could not execute git status: $!";
    my @lines = <$fh>;
    close $fh;
    
    my @changed;
    my %seen;
    for my $line (@lines) {
        chomp $line;
        if ($line =~ /\S/ && $line =~ /skills\//) {
            my ($skill) = ($line =~ /skills\/([^\/]+)/);
            if (defined $skill && !$seen{$skill}) {
                push @changed, $skill;
                $seen{$skill} = 1;
            }
        }
    }
    
    print "Changed skills: [" . join(", ", @changed) . "]\n";
    
    # Publish with delay (max 5 per batch)
    my $count = 0;
    for my $skill (@changed) {
        last if $count >= 5;
        if ($count > 0) {
            print "Waiting 15min for rate limit...\n";
            # In real: sleep(900);
        }
        
        print "Publishing $skill...\n";
        my $commit_ok = git_commit(File::Spec->catfile($SKILLS_DIR, $skill));
        if ($commit_ok) {
            my ($pub_ok, $output) = clawhub_publish($skill);
            my $status = $pub_ok ? "✓" : "✗";
            print "  $status $output\n";
        }
        $count++;
    }
}

sub main {
    my ($skill, $all, $no_publish, $message);
    GetOptions(
        "skill=s"     => \$skill,
        "all"         => \$all,
        "no-publish"  => \$no_publish,
        "message=s"   => \$message
    ) or die "Error in command line arguments\n";

    if (defined $skill) {
        my $skill_path = File::Spec->catfile($SKILLS_DIR, $skill);
        if ($no_publish) {
            git_commit($skill_path, $message);
        } else {
            git_commit($skill_path, $message);
            clawhub_publish($skill);
        }
    } elsif ($all) {
        batch_publish();
    } else {
        print "Use --skill <name> or --all\n";
    }
}

main() unless caller;
