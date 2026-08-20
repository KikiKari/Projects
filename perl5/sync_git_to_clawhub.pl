#!/usr/bin/perl
# sync_git_to_clawhub.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:scripts/sync_git_to_clawhub.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use lib '/home/openclaw/.openclaw/workspace/scripts';
require 'sync_clawhub_git.pl';

# Nur aktive Skill-Repositories synchronisieren.
my @git_repos = (
    "sub-agents-utils",
    "multi-nodes-utils",
);

# Check if in git/
my $git_path = "/home/openclaw/.openclaw/workspace/git";
foreach my $repo (@git_repos) {
    if (-d "$git_path/$repo") {
        sync_clawhub_git::log("Syncing $repo from Git to ClawHub...");
        sync_clawhub_git::sync_to_clawhub($repo, 0);
        sync_clawhub_git::log("✅ $repo synced to ClawHub");
    }
}
