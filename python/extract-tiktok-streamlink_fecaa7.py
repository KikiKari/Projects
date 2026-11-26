#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "38b70c5201f3fbcdfec4c9de11ef7e6ac90c9d8f7a59c2e8e9d5850b7aab1f7a", "source_sha256": "fecaa7522aec9008996f5664c745893f7fb7a2a4a3134a9f2855acde7f79596c", "target_language": "python"}
# extract-tiktok-streamlink.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import json
import subprocess
import sys
import re
from datetime import datetime
import os

def emit_json(success, method, username, url, quality, author, title, error, timestamp, status):
    payload = {
        "success": success,
        "method": method,
        "username": username,
        "url": url,
        "quality": quality,
        "author": author,
        "title": title,
        "error": error,
        "timestamp": timestamp,
        "status": status
    }
    # Remove empty values
    payload = {k: v for k, v in payload.items() if v}
    if "success" in payload:
        payload["success"] = payload["success"]
    print(json.dumps(payload, ensure_ascii=False))

def main():
    if len(sys.argv) < 2:
        print("Invalid TikTok username", file=sys.stderr)
        sys.exit(64)
    
    USERNAME = sys.argv[1].lstrip('@')
    QUALITY = sys.argv[2] if len(sys.argv) > 2 else "best"
    JSON_FLAG = sys.argv[3] if len(sys.argv) > 3 else ""
    TIMESTAMP = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    
    # Validate username
    if not re.match(r'^[A-Za-z0-9._]{1,24}$', USERNAME):
        print("Invalid TikTok username", file=sys.stderr)
        sys.exit(64)
    
    # Validate quality
    valid_qualities = ["best", "worst", "original", "1080p60", "720p60", "720p", "540p", "360p", "auto"]
    if QUALITY not in valid_qualities:
        print("Invalid stream quality", file=sys.stderr)
        sys.exit(64)
    
    # Check system load
    try:
        load_per_cpu = os.getloadavg()[0] / max(1, os.cpu_count() or 1)
        max_load = float(os.environ.get("TIKTOK_MAX_LOAD_PER_CPU", "1.5"))
        if load_per_cpu > max_load:
            emit_json(False, "streamlink", USERNAME, "", QUALITY, "", "", 
                     "host overloaded", TIMESTAMP, "overloaded")
            sys.exit(75)
    except Exception:
        pass  # Continue if load check fails
    
    # Check if streamlink is installed
    try:
        subprocess.run(["streamlink", "--version"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        emit_json(False, "streamlink", USERNAME, "", QUALITY, "", "", 
                 "streamlink not installed", TIMESTAMP, "dependency_missing")
        sys.exit(2)
    
    LIVE_URL = f"https://www.tiktok.com/@{USERNAME}/live"
    
    # Quality selector mapping
    selectors = {
        "original": "origin,uhd_60,hd_60,hd,sd,ld,best,worst",
        "auto": "best,origin,uhd_60,hd_60,hd,sd,ld,worst",
        "1080p60": "uhd_60,hd_60,hd,sd,ld,worst",
        "720p60": "hd_60,hd,sd,ld,worst",
        "720p": "hd,sd,ld,worst",
        "540p": "sd,ld,worst",
        "360p": "ld,worst"
    }
    SELECTOR = selectors.get(QUALITY, QUALITY)
    
    # Try to get JSON output first
    try:
        result = subprocess.run(
            ["streamlink", "--json", LIVE_URL, SELECTOR],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0 or not result.stdout.strip():
            # Fallback to stream-url
            result = subprocess.run(
                ["streamlink", "--stream-url", LIVE_URL, SELECTOR],
                capture_output=True,
                text=True
            )
            
            if result.returncode != 0 or not result.stdout.strip():
                emit_json(False, "streamlink", USERNAME, "", QUALITY, "", "", 
                         "streamlink failed or no stream found", TIMESTAMP, "offline")
                sys.exit(1)
            
            URL = result.stdout.strip()
            if JSON_FLAG == "--json":
                emit_json(True, "streamlink", USERNAME, URL, QUALITY, "", "", "", TIMESTAMP, "live")
            else:
                print(URL)
            sys.exit(0)
        
        # Parse JSON output
        try:
            data = json.loads(result.stdout)
            url = data.get("url", "")
            streams = data.get("streams", {})
            
            if not url and isinstance(streams, dict):
                for key in ["best", "worst"] + list(streams.keys()):
                    value = streams.get(key)
                    if isinstance(value, dict) and value.get("url"):
                        url = value["url"]
                        break
            
            metadata = data.get("metadata", {})
            AUTHOR = metadata.get("author", "")
            TITLE = metadata.get("title", "")
            
            if not url:
                emit_json(False, "streamlink", USERNAME, "", QUALITY, AUTHOR, TITLE, 
                         "could not extract stream URL", TIMESTAMP, "offline")
                sys.exit(1)
            
            if JSON_FLAG == "--json":
                emit_json(True, "streamlink", USERNAME, url, QUALITY, AUTHOR, TITLE, "", TIMESTAMP, "live")
            else:
                print(url)
            sys.exit(0)
                
        except json.JSONDecodeError:
            emit_json(False, "streamlink", USERNAME, "", QUALITY, "", "", 
                     "invalid streamlink JSON", TIMESTAMP, "technical_error")
            sys.exit(2)
            
    except Exception as e:
        emit_json(False, "streamlink", USERNAME, "", QUALITY, "", "", 
                 "streamlink failed or no stream found", TIMESTAMP, "offline")
        sys.exit(1)

if __name__ == "__main__":
    main()
