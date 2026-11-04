#!/usr/bin/perl
# run_sync_agent.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:scripts/run_sync_agent.py
# Erzeugt: 2026-11-04 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use lib '/workspace/scripts';
use lib '/workspace/skills/clawhub-git-sync-agent/scripts';

# Sandbox-Wrapper fuer sync_agent.py: mappt hartcodierte Host-Pfade auf /workspace.

require sync_agent;

my $WS = '/workspace';
$sync_agent::CLAWHUB_DIR = "$WS/skills";
$sync_agent::GIT_DIR = "$WS/git/skills";
$sync_agent::STATE_FILE = "$WS/db/sync_state.json";

sync_agent::main() if __FILE__ eq $0;
