#!/usr/bin/env perl
# abstraction-provenance: {"artifact_sha256": "db8a9ca4d1af45f25ab90dd22e213dcd9701b8ac531aa79fe3e8a84e3944b9eb", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "perl5"}
# openclaw-maintenance.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# === 1. Service-/Config-Drift ===
system("openclaw", "doctor") == 0 or die "openclaw doctor failed: $?";

# === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
system("openclaw", "plugins", "registry", "--refresh") == 0 or die "openclaw plugins registry --refresh failed: $?";
system("openclaw", "plugins", "update", "--all") == 0 or die "openclaw plugins update --all failed: $?";

# === 3. Tasks ===
system("openclaw", "tasks", "maintenance", "--apply") == 0 or die "openclaw tasks maintenance --apply failed: $?";

# === 4. Sessions – alle Agents auf einmal ===
system("openclaw", "sessions", "cleanup", "--enforce", "--all-agents") == 0 or die "openclaw sessions cleanup --enforce --all-agents failed: $?";

# === 5. Memory – status/index decken alle Agents ab ===
system("openclaw", "memory", "status", "--deep", "--fix") == 0 or die "openclaw memory status --deep --fix failed: $?";
system("openclaw", "memory", "index", "--force") == 0 or die "openclaw memory index --force failed: $?";

# === 6. Memory promote – MUSS pro Agent ===
my @agents = qw(main knecht docs ops-hub cron);
for my $agent (@agents) {
    system("openclaw", "memory", "promote", "--apply", "--agent", $agent) == 0 or die "openclaw memory promote --apply --agent $agent failed: $?";
}

# === 7. Secrets ===
system("openclaw", "secrets", "reload") == 0 or die "openclaw secrets reload failed: $?";
