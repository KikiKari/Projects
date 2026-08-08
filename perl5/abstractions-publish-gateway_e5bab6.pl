#!/usr/bin/env perl
# abstractions-publish-gateway.tcl — portiert nach perl5
# Quelle: tcl, Projects@abstractions:tcl/abstractions-publish-gateway.tcl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# abstractions-publish-gateway.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.
system('/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh', @ARGV) == 0
    or die "Command failed: $!";
