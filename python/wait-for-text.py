#!/usr/bin/env python3
# wait-for-text.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/wait-for-text.sh
# auch in: OpenClaw@gateway2:skills/tmux/scripts/wait-for-text.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

import argparse
import re
import subprocess
import sys
import time

def usage():
    print('''Usage: wait-for-text.py -t target -p pattern [options]

Poll a tmux pane for text and exit when found.

Options:
  -t, --target    tmux target (session:window.pane), required
  -p, --pattern   regex pattern to look for, required
  -F, --fixed     treat pattern as a fixed string (grep -F)
  -T, --timeout   seconds to wait (integer, default: 15)
  -i, --interval  poll interval in seconds (default: 0.5)
  -l, --lines     number of history lines to inspect (integer, default: 1000)
  -h, --help      show this help''')

def main():
    parser = argparse.ArgumentParser(
        description='Poll a tmux pane for text and exit when found.',
        add_help=False,
        usage=argparse.SUPPRESS
    )
    
    parser.add_argument('-t', '--target', required=True, help='tmux target (session:window.pane)')
    parser.add_argument('-p', '--pattern', required=True, help='regex pattern to look for')
    parser.add_argument('-F', '--fixed', action='store_true', help='treat pattern as a fixed string')
    parser.add_argument('-T', '--timeout', type=int, default=15, help='seconds to wait (integer, default: 15)')
    parser.add_argument('-i', '--interval', type=float, default=0.5, help='poll interval in seconds (default: 0.5)')
    parser.add_argument('-l', '--lines', type=int, default=1000, help='number of history lines to inspect (integer, default: 1000)')
    parser.add_argument('-h', '--help', action='store_true', help='show help')
    
    args = parser.parse_args()
    
    if args.help:
        usage()
        sys.exit(0)
        
    if not args.target or not args.pattern:
        print("target and pattern are required", file=sys.stderr)
        usage()
        sys.exit(1)
        
    if args.timeout <= 0:
        print("timeout must be a positive integer number of seconds", file=sys.stderr)
        sys.exit(1)
        
    if args.lines <= 0:
        print("lines must be a positive integer", file=sys.stderr)
        sys.exit(1)
        
    try:
        subprocess.run(['tmux', '-V'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("tmux not found in PATH", file=sys.stderr)
        sys.exit(1)
        
    start_time = time.time()
    deadline = start_time + args.timeout
    
    while True:
        try:
            result = subprocess.run(
                ['tmux', 'capture-pane', '-p', '-J', '-t', args.target, '-S', f'-{args.lines}'],
                capture_output=True,
                text=True,
                check=True
            )
            pane_text = result.stdout
        except subprocess.CalledProcessError:
            pane_text = ""
            
        if args.fixed:
            if args.pattern in pane_text:
                sys.exit(0)
        else:
            try:
                if re.search(args.pattern, pane_text):
                    sys.exit(0)
            except re.error:
                print(f"Invalid regex pattern: {args.pattern}", file=sys.stderr)
                sys.exit(1)
                
        if time.time() >= deadline:
            print(f"Timed out after {args.timeout}s waiting for pattern: {args.pattern}", file=sys.stderr)
            print(f"Last {args.lines} lines from {args.target}:", file=sys.stderr)
            print(pane_text, file=sys.stderr)
            sys.exit(1)
            
        time.sleep(args.interval)

if __name__ == '__main__':
    main()
