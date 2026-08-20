#!/usr/bin/env python3
# test_mobile_bridge.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_bridge.cjs
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import pathlib

def read_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        return f.read()

def main():
    root = pathlib.Path(__file__).parent.parent.absolute()
    bridge_path = root / "mobile-shared" / "webview-bridge.js"
    
    if not bridge_path.exists():
        print(f"Bridge file not found: {bridge_path}", file=sys.stderr)
        sys.exit(1)
        
    source = read_file(bridge_path)
    
    # Compile the JavaScript source to verify syntax (using eval as rough equivalent)
    try:
        compile(source, str(bridge_path), 'exec')
    except SyntaxError as e:
        print(f"Syntax error in bridge file: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Assertions to check content
    assertions = [
        'location.hostname !== "www.tiktok.com"' in source,
        "root.top === root" in source,
        "if (!isTop) return" in source,
        "MAX_MESSAGE_BYTES = 64 * 1024" in source,
        "MAX_AUDIO_SECONDS = 12" in source,
        "QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400" in source,
        "ALLOWED_COMMANDS" in source,
        '"set-auto-reconnect"' in source,
        '"set-limiter"' in source,
        '"scan-recommendations"' in source,
        '"cancel-recommendation-scan"' in source,
        "MAX_MEDIA_URLS = 12" in source,
        "const mediaUrls = new Map()" in source,
        'emit("media-url"' in source,
        'addEventListener("message"' in source,
        ".send =" not in source,
        "document.cookie" not in source,
        "localStorage" not in source,
        'FORCE_RETURN_KEY = "tlc-force-return"' in source,
        "sessionStorage.getItem(FORCE_RETURN_KEY)" in source,
        "sessionStorage.clear" not in source,
        "innerHTML" not in source
    ]
    
    for i, assertion in enumerate(assertions):
        if not assertion:
            print(f"Assertion {i+1} failed", file=sys.stderr)
            sys.exit(1)
            
    # Check copies
    copies = [
        root.parent / "mobile" / "ios" / "Resources" / "webview-bridge.js",
        root.parent / "mobile" / "android" / "app" / "src" / "main" / "res" / "raw" / "webview_bridge.js"
    ]
    
    for copy_path in copies:
        if not copy_path.exists():
            print(f"Bridge copy not found: {copy_path}", file=sys.stderr)
            sys.exit(1)
            
        copy_content = read_file(copy_path)
        if copy_content != source:
            print(f"Bridge copy drifted: {copy_path}", file=sys.stderr)
            sys.exit(1)
            
    print("PASS: mobile bridge origin, main-frame, size, command, audio-duration and storage guards")

if __name__ == "__main__":
    main()
