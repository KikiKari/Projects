#!/usr/bin/env perl
# abstractions-publish-gateway.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Workspace-visible wrapper for the gateway publish job.
exec '/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh', @ARGV;
