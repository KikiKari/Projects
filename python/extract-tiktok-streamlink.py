#!/usr/bin/env python3
# extract-tiktok-streamlink.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import json
import os
import subprocess
import sys
from datetime import datetime

def emit_json(*args):
    keys = ("success", "method", "username", "url", "quality", "author", "title", "error", "timestamp", "status")
    values = args
    payload = {key: value for key, value in zip(keys, values) if value != ""}
    if "success" in payload:
        payload["success"] = payload["success"].lower() == "true"
    print(json.dumps(payload, ensure_ascii=False))

def validate_username(username):
    import re
    if not re.match(r'^[A-Za-z0-9._]{1,24}$', username):
        print("Invalid TikTok username", file=sys.stderr)
        sys.exit(64)

def validate_quality(quality):
    valid_qualities = ("best", "worst", "original", "1080p60", "720p60", "720p", "540p", "360p", "auto")
    if quality not in valid_qualities:
        print("Invalid stream quality", file=sys.stderr)
        sys.exit(64)

def get_load_per_cpu():
    load_avg = os.getloadavg()[0]
    cpu_count = max(1, os.cpu_count() or 1)
    return load_avg / cpu_count

def check_overload(max_load_per_cpu):
    load_per_cpu = get_load_per_cpu()
    if load_per_cpu > max_load_per_cpu:
        return True
    return False

def is_streamlink_installed():
    return subprocess.run(["which", "streamlink"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0

def get_selector(quality):
    selector_map = {
        "original": "origin,uhd_60,hd_60,hd,sd,ld,best,worst",
        "auto": "best,origin,uhd_60,hd_60,hd,sd,ld,worst",
        "1080p60": "uhd_60,hd_60,hd,sd,ld,worst",
        "720p60": "hd_60,hd,sd,ld,worst",
        "720p": "hd,sd,ld,worst",
        "540p": "sd,ld,worst",
        "360p": "ld,worst"
    }
    return selector_map.get(quality, quality)

def run_streamlink_json(live_url, selector):
    try:
        result = subprocess.run(
            ["streamlink", "--json", live_url, selector],
            capture_output=True,
            text=True
        )
        if result.returncode == 0 and result.stdout:
            return json.loads(result.stdout)
        else:
            return None
    except Exception:
        return None

def run_streamlink_url(live_url, selector):
    try:
        result = subprocess.run(
            ["streamlink", "--stream-url", live_url, selector],
            capture_output=True,
            text=True
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
        else:
            return None
    except Exception:
        return None

def parse_streamlink_json(data):
    url = data.get("url", "")
    streams = data.get("streams", {})
    if not url and isinstance(streams, dict):
        for key in ["best", "worst"] + list(streams.keys()):
            value = streams.get(key)
            if isinstance(value, dict) and value.get("url"):
                url = value["url"]
                break
    metadata = data.get("metadata", {})
    return {
        "url": url,
        "author": metadata.get("author", ""),
        "title": metadata.get("title", "")
    }

def main():
    if len(sys.argv) < 2:
        print("Usage: script.py <username> [quality] [--json]", file=sys.stderr)
        sys.exit(64)
    
    username = sys.argv[1].lstrip('@')
    quality = sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith('--') else 'best'
    json_flag = '--json' if '--json' in sys.argv else ''
    timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    
    validate_username(username)
    validate_quality(quality)
    
    max_load_per_cpu = float(os.environ.get('TIKTOK_MAX_LOAD_PER_CPU', '1.5'))
    if check_overload(max_load_per_cpu):
        emit_json("false", "streamlink", username, "", quality, "", "", "host overloaded", timestamp, "overloaded")
        sys.exit(75)
    
    if not is_streamlink_installed():
        emit_json("false", "streamlink", username, "", quality, "", "", "streamlink not installed", timestamp, "dependency_missing")
        sys.exit(2)
    
    live_url = f"https://www.tiktok.com/@{username}/live"
    selector = get_selector(quality)
    
    output_data = run_streamlink_json(live_url, selector)
    if output_data is None:
        url = run_streamlink_url(live_url, selector)
        if not url:
            emit_json("false", "streamlink", username, "", quality, "", "", "streamlink failed or no stream found", timestamp, "offline")
            sys.exit(1)
        if json_flag:
            emit_json("true", "streamlink", username, url, quality, "", "", "", timestamp, "live")
        else:
            print(url)
        sys.exit(0)
    
    try:
        parsed = parse_streamlink_json(output_data)
    except Exception:
        emit_json("false", "streamlink", username, "", quality, "", "", "invalid streamlink JSON", timestamp, "technical_error")
        sys.exit(2)
    
    url = parsed.get("url", "")
    author = parsed.get("author", "")
    title = parsed.get("title", "")
    
    if not url:
        emit_json("false", "streamlink", username, "", quality, author, title, "could not extract stream URL", timestamp, "offline")
        sys.exit(1)
    
    if json_flag:
        emit_json("true", "streamlink", username, url, quality, author, title, "", timestamp, "live")
    else:
        print(url)

if __name__ == "__main__":
    main()
