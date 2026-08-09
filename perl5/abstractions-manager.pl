#!/usr/bin/env perl
# abstractions-manager.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

exec('/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh', @ARGV);
