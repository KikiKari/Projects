#!/usr/bin/env perl
# openclaw-maintenance.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# === 1. Service-/Config-Drift ===
system("openclaw doctor");

# === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
system("openclaw plugins registry --refresh");
system("openclaw plugins update --all");

# === 3. Tasks ===
system("openclaw tasks maintenance --apply");

# === 4. Sessions – alle Agents auf einmal ===
system("openclaw sessions cleanup --enforce --all-agents");

# === 5. Memory – status/index decken alle Agents ab ===
system("openclaw memory status --deep --fix");
system("openclaw memory index --force");

# === 6. Memory promote – MUSS pro Agent ===
my @agents = qw(main knecht docs ops-hub cron);
for my $agent (@agents) {
    system("openclaw memory promote --apply --agent \"$agent\"");
}

# === 7. Secrets ===
system("openclaw secrets reload");
