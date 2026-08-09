#!/usr/bin/env tclsh
# openclaw-maintenance.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6

# Determine the OpenClaw binary path
set OPENCLAW_BIN [expr {[info exists ::env(OPENCLAW_BIN)] ? $::env(OPENCLAW_BIN) : "$::env(HOME)/.local/bin/openclaw"}]

# Check if the OpenClaw binary exists and is executable
if {![file executable $OPENCLAW_BIN]} {
    puts stderr "ERROR: OpenClaw binary not found: $OPENCLAW_BIN"
    exit 1
}

# Print the version of OpenClaw
if {[catch {exec $OPENCLAW_BIN --version} version_output]} {
    puts stderr "ERROR: Failed to get OpenClaw version"
    exit 1
}
puts "Using OpenClaw: $version_output"

# === 1. Service-/Config-Drift ===
if {[catch {exec $OPENCLAW_BIN doctor} result]} {
    puts stderr "ERROR: doctor command failed: $result"
    exit 1
}

# === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
if {[catch {exec $OPENCLAW_BIN plugins registry --refresh} result]} {
    puts stderr "ERROR: plugin registry refresh failed: $result"
    exit 1
}

if {[info exists ::env(RUN_PLUGIN_UPDATE)] && $::env(RUN_PLUGIN_UPDATE) eq "1"} {
    if {[catch {exec $OPENCLAW_BIN plugins update --all} result]} {
        puts stderr "ERROR: plugin update failed: $result"
        exit 1
    }
} else {
    puts "Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable."
}

# === 3. Tasks ===
if {[catch {exec $OPENCLAW_BIN tasks maintenance --apply} result]} {
    puts stderr "ERROR: tasks maintenance failed: $result"
    exit 1
}

# === 4. Sessions – alle Agents auf einmal ===
if {[catch {exec $OPENCLAW_BIN sessions cleanup --enforce --all-agents} result]} {
    puts stderr "ERROR: sessions cleanup failed: $result"
    exit 1
}

# === 5. Memory – status/index decken alle Agents ab ===
if {[catch {exec $OPENCLAW_BIN memory status --deep --fix} result]} {
    puts stderr "ERROR: memory status failed: $result"
    exit 1
}

if {[catch {exec $OPENCLAW_BIN memory index --force} result]} {
    puts stderr "ERROR: memory index failed: $result"
    exit 1
}

# === 6. Memory promote – MUSS pro Agent ===
foreach AGENT {main knecht docs ops-hub cron} {
    if {[catch {exec $OPENCLAW_BIN memory promote --apply --agent $AGENT} result]} {
        puts stderr "ERROR: memory promote for agent $AGENT failed: $result"
        exit 1
    }
}

# === 7. Secrets ===
if {[catch {exec $OPENCLAW_BIN secrets reload} result]} {
    puts stderr "ERROR: secrets reload failed: $result"
    exit 1
}
