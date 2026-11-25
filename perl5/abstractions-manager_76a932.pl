#!/usr/bin/env perl
# abstraction-provenance: {"artifact_sha256": "a45d40ff3e6de4cdb28018fbae2ac96efac2d0161cf4283481277c23656d05c6", "source_sha256": "76a9327ec4d8b7b9abcabfcbbbf89350cb4a3a4fdc0c949a0b343fe059dc87a8", "target_language": "perl5"}
# abstractions-manager.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

exec('/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh', @ARGV);
