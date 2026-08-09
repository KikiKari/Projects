#!/usr/bin/env python3
# extract-tiktok-yt-dlp.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime

def emit_json(*args):
    keys = ("success", "method", "username", "url", "format", "error", "timestamp", "status")
    payload = {k: v for k, v in zip(keys, args) if v != ""}
    if "success" in payload:
        payload["success"] = payload["success"].lower() == "true"
    print(json.dumps(payload, ensure_ascii=False))

def get_load_per_cpu():
    try:
        with open("/proc/loadavg", "r") as f:
            load_avg = f.readline().split()[0]
        load = float(load_avg)
        cpu_count = os.cpu_count() or 1
        return load / max(1, cpu_count)
    except:
        return 0.0

def main():
    if len(sys.argv) < 2:
        print("Invalid TikTok username", file=sys.stderr)
        sys.exit(64)
    
    username = sys.argv[1].lstrip('@')
    format_choice = sys.argv[2] if len(sys.argv) > 2 else "best"
    json_flag = sys.argv[3] if len(sys.argv) > 3 else ""
    
    timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    
    valid_username_pattern = r'^[A-Za-z0-9._]{1,24}$'
    if not re.match(valid_username_pattern, username):
        print("Invalid TikTok username", file=sys.stderr)
        sys.exit(64)
    
    valid_formats = [
        "hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld",
        "hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
        "hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
        "hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld",
        "hls-sd/hls-ld/flv-sd/flv-ld",
        "hls-ld/flv-ld",
        "hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld"
    ]
    
    if format_choice not in valid_formats:
        print("Invalid yt-dlp format", file=sys.stderr)
        sys.exit(64)
    
    load_per_cpu = get_load_per_cpu()
    max_load = float(os.environ.get("TIKTOK_MAX_LOAD_PER_CPU", "1.5"))
    
    if load_per_cpu > max_load:
        emit_json("false", "yt-dlp", username, "", format_choice, "host overloaded", timestamp, "overloaded")
        sys.exit(75)
    
    try:
        subprocess.run(["yt-dlp", "--version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        emit_json("false", "yt-dlp", username, "", format_choice, "yt-dlp not installed", timestamp, "dependency_missing")
        sys.exit(2)
    
    with tempfile.TemporaryDirectory() as tmp_dir:
        stdout_file = os.path.join(tmp_dir, "stdout.json")
        stderr_file = os.path.join(tmp_dir, "stderr.log")
        
        live_url = f"https://www.tiktok.com/@{username}/live"
        
        try:
            result = subprocess.run([
                "yt-dlp",
                "--no-warnings",
                "--dump-single-json",
                "--skip-download",
                "--format", format_choice,
                live_url
            ], stdout=open(stdout_file, "w"), stderr=open(stderr_file, "w"))
        except Exception as e:
            emit_json("false", "yt-dlp", username, "", format_choice, str(e), timestamp, "technical_error")
            sys.exit(2)
        
        exit_code = result.returncode
        if exit_code != 0:
            try:
                with open(stderr_file, "r") as f:
                    stderr_content = f.read()[:1000]
            except:
                stderr_content = ""
            
            if any(keyword in stderr_content.lower() for keyword in ["not currently live", "no live cdn found", "not available", "private video"]):
                status = "offline"
                code = 1
            else:
                status = "technical_error"
                code = 2
            
            emit_json("false", "yt-dlp", username, "", format_choice, stderr_content, timestamp, status)
            sys.exit(code)
        
        try:
            with open(stdout_file, "r") as f:
                data = json.load(f)
        except Exception as e:
            emit_json("false", "yt-dlp", username, "", format_choice, "could not parse JSON output", timestamp, "technical_error")
            sys.exit(2)
        
        candidates = []
        if isinstance(data.get("url"), str):
            candidates.append(data["url"])
        
        for item in data.get("formats", []) or []:
            if isinstance(item, dict) and isinstance(item.get("url"), str):
                candidates.append(item["url"])
        
        url = ""
        for value in candidates:
            low = value.lower()
            if value.startswith("https://") and (".m3u8" in low or ".flv" in low) and "only_audio=1" not in low:
                url = value
                break
        
        if not url:
            emit_json("false", "yt-dlp", username, "", format_choice, "could not extract HTTPS video URL", timestamp, "offline")
            sys.exit(1)
        
        if json_flag == "--json":
            emit_json("true", "yt-dlp", username, url, format_choice, "", timestamp, "live")
        else:
            print(url)

if __name__ == "__main__":
    main()
