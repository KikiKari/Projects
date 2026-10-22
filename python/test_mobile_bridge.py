#!/usr/bin/env python3
# test_mobile_bridge.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_mobile_bridge.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import pathlib

def read_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        return f.read()

def main():
    root = pathlib.Path(__file__).parent.parent.absolute()
    bridge_path = root / "mobile-shared" / "webview-bridge.js"
    
    try:
        source = read_file(bridge_path)
    except Exception as e:
        print(f"Failed to read bridge file: {e}")
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
            print(f"Assertion failed at index {i}")
            sys.exit(1)

    # Check copies
    copies = [
        root.parent / "mobile" / "ios" / "Resources" / "webview-bridge.js",
        root.parent / "mobile" / "android" / "app" / "src" / "main" / "res" / "raw" / "webview_bridge.js"
    ]
    
    for copy in copies:
        try:
            copy_content = read_file(copy)
            if copy_content != source:
                print(f"Bridge copy drifted: {copy}")
                sys.exit(1)
        except Exception as e:
            print(f"Failed to read copy file {copy}: {e}")
            sys.exit(1)

    print("PASS: mobile bridge origin, main-frame, size, command, audio-duration and storage guards")

if __name__ == "__main__":
    main()
