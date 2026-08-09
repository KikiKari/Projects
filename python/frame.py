#!/usr/bin/env python3
# frame.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
# auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import sys
import os
import subprocess
import argparse
from pathlib import Path

def usage():
    """Print usage information and exit with code 2"""
    print("""Usage:
  frame.sh <video-file> [--time HH:MM:SS] [--index N] --out /path/to/frame.jpg

Examples:
  frame.sh video.mp4 --out /tmp/frame.jpg
  frame.sh video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg
  frame.sh video.mp4 --index 0 --out /tmp/frame0.png""", file=sys.stderr)
    sys.exit(2)

def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        usage()

    # Parse arguments manually to match shell script behavior
    args = sys.argv[1:]
    in_file = args[0] if args else ""
    
    if not in_file:
        usage()
    
    # Remove first argument (input file)
    remaining_args = args[1:]
    
    time_arg = ""
    index_arg = ""
    out_arg = ""
    
    i = 0
    while i < len(remaining_args):
        arg = remaining_args[i]
        if arg == "--time":
            if i + 1 < len(remaining_args):
                time_arg = remaining_args[i + 1]
                i += 2
            else:
                print("Unknown arg: --time", file=sys.stderr)
                usage()
        elif arg == "--index":
            if i + 1 < len(remaining_args):
                index_arg = remaining_args[i + 1]
                i += 2
            else:
                print("Unknown arg: --index", file=sys.stderr)
                usage()
        elif arg == "--out":
            if i + 1 < len(remaining_args):
                out_arg = remaining_args[i + 1]
                i += 2
            else:
                print("Unknown arg: --out", file=sys.stderr)
                usage()
        else:
            print(f"Unknown arg: {arg}", file=sys.stderr)
            usage()
    
    if not os.path.isfile(in_file):
        print(f"File not found: {in_file}", file=sys.stderr)
        sys.exit(1)
    
    if not out_arg:
        print("Missing --out", file=sys.stderr)
        usage()
    
    # Create output directory
    out_path = Path(out_arg)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Build ffmpeg command based on provided arguments
    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]
    
    if index_arg:
        cmd.extend(["-i", in_file, "-vf", f"select=eq(n\\,{index_arg})", "-vframes", "1", out_arg])
    elif time_arg:
        cmd.extend(["-ss", time_arg, "-i", in_file, "-frames:v", "1", out_arg])
    else:
        cmd.extend(["-i", in_file, "-vf", "select=eq(n\\,0)", "-vframes", "1", out_arg])
    
    # Execute ffmpeg
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)
    
    print(out_arg)

if __name__ == "__main__":
    main()
