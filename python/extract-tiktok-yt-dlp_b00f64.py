#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "89d23bd16974f73f5273f1bd974e8760f26fe0781fc54ae31f984358e37e1318", "source_sha256": "b00f64d55d344bbcc351ae7ade12137f0d9293b556aa0881ede43bef5bcb778b", "target_language": "python"}
# extract-tiktok-yt-dlp.sh — portiert nach python
# Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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

def main():
    if len(sys.argv) < 2:
        print("Usage: {} <username> [format] [--json]".format(sys.argv[0]), file=sys.stderr)
        sys.exit(64)

    username = sys.argv[1].lstrip('@')
    format_opt = sys.argv[2] if len(sys.argv) > 2 else "best"
    json_flag = sys.argv[3] if len(sys.argv) > 3 else ""
    timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

    # Validate username
    if not re.match(r'^[A-Za-z0-9._]{1,24}$', username):
        print("Invalid TikTok username", file=sys.stderr)
        sys.exit(64)

    # Validate format
    valid_formats = [
        "hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld",
        "hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
        "hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
        "hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld",
        "hls-sd/hls-ld/flv-sd/flv-ld",
        "hls-ld/flv-ld",
        "hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld"
    ]
    if format_opt not in valid_formats:
        print("Invalid yt-dlp format", file=sys.stderr)
        sys.exit(64)

    # Check system load
    try:
        load_per_cpu = os.getloadavg()[0] / max(1, os.cpu_count() or 1)
        max_load = float(os.environ.get("TIKTOK_MAX_LOAD_PER_CPU", "1.5"))
        if load_per_cpu > max_load:
            emit_json("false", "yt-dlp", username, "", format_opt, "host overloaded", timestamp, "overloaded")
            sys.exit(75)
    except Exception:
        pass

    # Check if yt-dlp is installed
    if not subprocess.run(["which", "yt-dlp"], capture_output=True).returncode == 0:
        emit_json("false", "yt-dlp", username, "", format_opt, "yt-dlp not installed", timestamp, "dependency_missing")
        sys.exit(2)

    # Create temporary directory
    with tempfile.TemporaryDirectory(prefix="tiktok-yt-dlp.") as tmp_dir:
        stdout_file = os.path.join(tmp_dir, "stdout.json")
        stderr_file = os.path.join(tmp_dir, "stderr.log")

        live_url = f"https://www.tiktok.com/@{username}/live"

        try:
            result = subprocess.run([
                "yt-dlp",
                "--no-warnings",
                "--dump-single-json",
                "--skip-download",
                "--format", format_opt,
                live_url
            ], stdout=open(stdout_file, "w"), stderr=open(stderr_file, "w"))

            if result.returncode != 0:
                with open(stderr_file, "r") as f:
                    stderr_content = f.read()
                
                if any(keyword in stderr_content.lower() for keyword in ["not currently live", "no live cdn found", "not available", "private video"]):
                    status = "offline"
                    code = 1
                else:
                    status = "technical_error"
                    code = 2
                
                emit_json("false", "yt-dlp", username, "", format_opt, 
                         stderr_content[:1000], timestamp, status)
                sys.exit(code)

            # Extract URL from JSON
            with open(stdout_file, "r") as f:
                data = json.load(f)
            
            url = ""
            candidates = []
            
            if isinstance(data.get("url"), str):
                candidates.append(data["url"])
            
            for item in data.get("formats", []):
                if isinstance(item, dict) and isinstance(item.get("url"), str):
                    candidates.append(item["url"])
            
            for value in candidates:
                low = value.lower()
                if (value.startswith("https://") and 
                    (".m3u8" in low or ".flv" in low) and 
                    "only_audio=1" not in low):
                    url = value
                    break
            
            if not url:
                emit_json("false", "yt-dlp", username, "", format_opt,
                         "could not extract HTTPS video URL", timestamp, "offline")
                sys.exit(1)
            
            if json_flag == "--json":
                emit_json("true", "yt-dlp", username, url, format_opt, "", timestamp, "live")
            else:
                print(url)

        except Exception as e:
            emit_json("false", "yt-dlp", username, "", format_opt,
                     str(e)[:1000], timestamp, "technical_error")
            sys.exit(2)

if __name__ == "__main__":
    main()
