#!/usr/bin/env perl
# openclaw-maintenance.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use IPC::Run3;

my $OPENCLAW_BIN = $ENV{OPENCLAW_BIN} // "$ENV{HOME}/.local/bin/openclaw";

if (!-x $OPENCLAW_BIN) {
    print STDERR "ERROR: OpenClaw binary not found: $OPENCLAW_BIN\n";
    exit 1;
}

my @version_cmd = ($OPENCLAW_BIN, '--version');
my ($version_out, $version_err);
run3(\@version_cmd, \undef, \$version_out, \$version_err);
chomp $version_out if $version_out;
print "Using OpenClaw: $version_out\n";

# === 1. Service-/Config-Drift ===
my @doctor_cmd = ($OPENCLAW_BIN, 'doctor');
run3(\@doctor_cmd) or die "Doctor command failed: $?";

# === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
my @plugins_registry_cmd = ($OPENCLAW_BIN, 'plugins', 'registry', '--refresh');
run3(\@plugins_registry_cmd) or die "Plugins registry refresh failed: $?";

if ($ENV{RUN_PLUGIN_UPDATE} && $ENV{RUN_PLUGIN_UPDATE} eq "1") {
    my @plugins_update_cmd = ($OPENCLAW_BIN, 'plugins', 'update', '--all');
    run3(\@plugins_update_cmd) or die "Plugins update failed: $?";
} else {
    print "Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable.\n";
}

# === 3. Tasks ===
my @tasks_cmd = ($OPENCLAW_BIN, 'tasks', 'maintenance', '--apply');
run3(\@tasks_cmd) or die "Tasks maintenance failed: $?";

# === 4. Sessions – alle Agents auf einmal ===
my @sessions_cmd = ($OPENCLAW_BIN, 'sessions', 'cleanup', '--enforce', '--all-agents');
run3(\@sessions_cmd) or die "Sessions cleanup failed: $?";

# === 5. Memory – status/index decken alle Agents ab ===
my @memory_status_cmd = ($OPENCLAW_BIN, 'memory', 'status', '--deep', '--fix');
run3(\@memory_status_cmd) or die "Memory status failed: $?";

my @memory_index_cmd = ($OPENCLAW_BIN, 'memory', 'index', '--force');
run3(\@memory_index_cmd) or die "Memory index failed: $?";

# === 6. Memory promote – MUSS pro Agent ===
my @agents = qw(main knecht docs ops-hub cron);
for my $AGENT (@agents) {
    my @promote_cmd = ($OPENCLAW_BIN, 'memory', 'promote', '--apply', '--agent', $AGENT);
    run3(\@promote_cmd) or die "Memory promote for agent $AGENT failed: $?";
}

# === 7. Secrets ===
my @secrets_cmd = ($OPENCLAW_BIN, 'secrets', 'reload');
run3(\@secrets_cmd) or die "Secrets reload failed: $?";
