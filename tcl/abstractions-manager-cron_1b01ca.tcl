#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "f7c55fcfe819e9ebf57ed118a24e3082025ab1e0d52c2f9733a614e9000febc7", "source_sha256": "1b01ca0f5943b16d3905faf557953600ee54f15ecf1dc18c1461585eba94d376", "target_language": "tcl"}
# abstractions-manager-cron.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

# Set the PATH environment variable
set env(PATH) "/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin"

# Source the .env file and export its variables
source /home/openclaw/.openclaw/.env
array set env [array get env]

# Check if OPENROUTER_API_KEY is set
if {![info exists env(OPENROUTER_API_KEY)]} {
    puts stderr "OPENROUTER_API_KEY fehlt"
    exit 1
}

# Set GITHUB_TOKEN with fallbacks
if {[info exists env(GITHUB_TOKEN)]} {
    set env(GITHUB_TOKEN) $env(GITHUB_TOKEN)
} elseif {[info exists env(GH_TOKEN)]} {
    set env(GITHUB_TOKEN) $env(GH_TOKEN)
} elseif {[info exists env(GH_ACCESS_TOKEN)]} {
    set env(GITHUB_TOKEN) $env(GH_ACCESS_TOKEN)
} else {
    set env(GITHUB_TOKEN) ""
}

# Attempt to acquire a lock and execute the Python script
if {[catch {
    open "|/usr/bin/flock --nonblock /home/openclaw/.openclaw/locks/abstractions-manager.lock /usr/bin/python3/home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py [join $argv]" r
} fileId]} {
    # If flock fails, it means the lock is already held by another process
    puts stderr "Could not acquire lock, another instance might be running."
    exit 1
}

# Read the output of the Python script
while {[gets $fileId line] >= 0} {
    puts $line
}

# Close the file descriptor
close $fileId
