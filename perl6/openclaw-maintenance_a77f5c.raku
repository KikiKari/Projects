#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "7e61906e8b7772670dd80462373a47b682e2c86a4a01f61f56b8e37a18d7c710", "source_sha256": "a77f5c2629fe7fafac268cfbf2f0b3e77a194322aee8f9c06967eb6c33db043e", "target_language": "perl6"}
# openclaw-maintenance.sh — portiert nach perl6
# Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use v6;

my $OPENCLAW_BIN = %*ENV<OPENCLAW_BIN> // "$*HOME/.local/bin/openclaw";

if !("$OPENCLAW_BIN".IO ~~ :x) {
    note "ERROR: OpenClaw binary not found: $OPENCLAW_BIN";
    exit 1;
}

say "Using OpenClaw: " ~ qqx{"$OPENCLAW_BIN" --version}.chomp;

# === 1. Service-/Config-Drift ===
shell "$OPENCLAW_BIN doctor";

# === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
shell "$OPENCLAW_BIN plugins registry --refresh";
if (%*ENV<RUN_PLUGIN_UPDATE> // "0") eq "1" {
    shell "$OPENCLAW_BIN plugins update --all";
} else {
    say "Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable.";
}

# === 3. Tasks ===
shell "$OPENCLAW_BIN tasks maintenance --apply";

# === 4. Sessions – alle Agents auf einmal ===
shell "$OPENCLAW_BIN sessions cleanup --enforce --all-agents";

# === 5. Memory – status/index decken alle Agents ab ===
shell "$OPENCLAW_BIN memory status --deep --fix";
shell "$OPENCLAW_BIN memory index --force";

# === 6. Memory promote – MUSS pro Agent ===
for <main knecht docs ops-hub cron> -> $AGENT {
    shell "$OPENCLAW_BIN memory promote --apply --agent $AGENT";
}

# === 7. Secrets ===
shell "$OPENCLAW_BIN secrets reload";
