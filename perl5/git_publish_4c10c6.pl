#!/usr/bin/env perl
# abstraction-provenance: {"artifact_sha256": "96985afa704208373a6ed4ff255447c488b4594addd96c2cbf7189c2b42b4e65", "source_sha256": "4c10c6b6fd911cb95da119f761f402073d1a836cab6b40a9f3b989536d5df5ec", "target_language": "perl5"}
# git_publish.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
# auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use File::Spec;
use Cwd qw(abs_path);
use POSIX qw(strftime);

# Git Publish Agent - Automatisierte Skill-Veröffentlichung

my $HOME = $ENV{HOME};
my $SKILLS_DIR = File::Spec->catdir($HOME, ".openclaw", "workspace", "skills");

sub git_commit {
    my ($skill_path, $message) = @_;
    
    # Default commit message
    if (!defined $message) {
        my $timestamp = strftime("%Y-%m-%dT%H:%M:%S", localtime);
        $message = "[skill] Auto-update " . basename($skill_path) . " - $timestamp";
    }
    
    # Add files
    system("cd " . dirname($SKILLS_DIR) . " && git add '$skill_path'");
    
    # Commit
    my $result = system("cd " . dirname($SKILLS_DIR) . " && git commit -m '$message'");
    return $result == 0;
}

sub clawhub_publish {
    my ($skill_name) = @_;
    my $skill_path = File::Spec->catdir($SKILLS_DIR, $skill_name);
    
    my $cmd = "clawhub publish '$skill_path' --slug '$skill_name' --version '1.0.0'";
    my $output = `$cmd`;
    my $exit_code = $? >> 8;  # Extract exit code from special variable
    
    return ($exit_code == 0, $output);
}

sub batch_publish {
    # Check git status
    my $status_cmd = "cd " . dirname($SKILLS_DIR) . " && git status --short '$SKILLS_DIR'";
    my $status_output = `$status_cmd`;
    
    my @changed = ();
    for my $line (split /\n/, $status_output) {
        chomp $line;
        if ($line =~ /\S/ && $line =~ /skills\//) {
            my ($skill) = ($line =~ m{skills/([^/]+)});
            push @changed, $skill unless grep { $_ eq $skill } @changed;
        }
    }
    
    print "Changed skills: [" . join(", ", @changed) . "]\n";
    
    # Publish with delay simulation
    my $count = 0;
    for my $skill (@changed[0..4]) {  # Max 5 per batch (simulate slice)
        last if $count >= 5;
        
        if ($count > 0) {
            print "Waiting 15min for rate limit...\n";
            # In real: sleep(900);
        }
        
        print "Publishing $skill...\n";
        my $commit_ok = git_commit(File::Spec->catdir($SKILLS_DIR, $skill));
        if ($commit_ok) {
            my ($pub_ok, $output) = clawhub_publish($skill);
            my $status = $pub_ok ? "✓" : "✗";
            print "  $status $output\n";
        }
        $count++;
    }
}

sub basename {
    my ($path) = @_;
    my @parts = split '/', $path;
    return pop @parts;
}

sub dirname {
    my ($path) = @_;
    my @parts = split '/', $path;
    pop @parts;
    return join('/', @parts);
}

sub main {
    my $skill;
    my $all = 0;
    my $no_publish = 0;
    my $message;
    
    GetOptions(
        "skill=s"     => \$skill,
        "all"         => \$all,
        "no-publish"  => \$no_publish,
        "message=s"   => \$message
    );
    
    if (defined $skill) {
        my $skill_path = File::Spec->catdir($SKILLS_DIR, $skill);
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

main();
