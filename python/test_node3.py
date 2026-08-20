#!/usr/bin/env python3
# test_node3.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:scripts/test_node3.sh
# auch in: OpenClaw@gateway2:scripts/test_node3.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

import os
import subprocess
import sys

# Test Node 3 Connection
os.environ['OPENCLAW_ALLOW_INSECURE_PRIVATE_WS'] = '1'
print("Starting node connection test...")

try:
    result = subprocess.run([
        '/usr/local/bin/openclaw', 'node', 'run',
        '--host', '152.53.145.65',
        '--port', '18789'
    ], timeout=15, capture_output=True, text=True)
    
    print(result.stdout, end='')
    if result.stderr:
        print(result.stderr, end='', file=sys.stderr)
    
    print(f"Exit code: {result.returncode}")
    sys.exit(result.returncode)
    
except subprocess.TimeoutExpired as e:
    if e.stdout:
        print(e.stdout.decode(), end='')
    if e.stderr:
        print(e.stderr.decode(), end='', file=sys.stderr)
    print("Exit code: 124")
    sys.exit(124)
    
except FileNotFoundError:
    print("Error: openclaw command not found")
    print("Exit code: 127")
    sys.exit(127)
