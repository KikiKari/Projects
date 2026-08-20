#!/usr/bin/env tclsh8.6
# test_node3.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/test_node3.sh
# auch in: OpenClaw@gateway2:scripts/test_node3.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# Test Node 3 Connection
set env(OPENCLAW_ALLOW_INSECURE_PRIVATE_WS) 1
puts "Starting node connection test..."

# Execute the command with timeout
set cmd "/usr/local/bin/openclaw node run --host 152.53.145.65 --port 18789"
if {[catch {exec /usr/bin/timeout 15 {*}$cmd} result]} {
    # Command failed or timed out
    puts stderr $result
    set exit_code 1
} else {
    # Command succeeded
    puts $result
    set exit_code 0
}

# If timeout failed to capture exit code, we'll use our own
puts "Exit code: $exit_code"
