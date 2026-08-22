#!/usr/bin/env python3
# tiktok-get-stream.js — portiert nach python
# Quelle: javascript, OpenClaw@gateway1:skills/tiktok-live/scripts/tiktok-get-stream.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

"""
TikTok Stream URL Extractor
Führt zuerst den profilgebundenen Status-Checker aus.
Nur bei bestätigtem Live-Status werden FLV-Netzwerk-URLs erfasst.
Offline wird keine Stream-URL ausgegeben.
"""

import asyncio
import json
import os
import platform
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

try:
    from playwright.async_api import async_playwright
except ImportError:
    print("Playwright ist nicht installiert. Bitte führe 'pip install playwright' aus.", file=sys.stderr)
    sys.exit(1)

def reject_busy_node():
    limit = os.environ.get('TIKTOK_MAX_LOAD_PER_CPU')
    if not limit:
        return
    
    try:
        limit = float(limit)
        if limit <= 0:
            return
    except ValueError:
        return
    
    try:
        # Lade Durchschnitt für Unix-Systeme
        if hasattr(os, 'getloadavg'):
            load_avg = os.getloadavg()[0]
        else:
            # Windows Workaround
            load_avg = 0.0
        
        cpu_count = max(1, os.cpu_count() or 1)
        normalized_load = load_avg / cpu_count if load_avg > 0 else 0
        
        if normalized_load > limit:
            print(f"NODE_BUSY normalizedLoad={normalized_load:.2f} limit={limit}", file=sys.stderr)
            sys.exit(75)
    except Exception:
        pass

def parse_json_output(output):
    try:
        return json.loads(output)
    except json.JSONDecodeError:
        return None

async def verify_live_status(username):
    checker_path = Path(__file__).parent / 'tiktok-check-profile.js'
    if not checker_path.exists():
        return False
    
    try:
        proc = await asyncio.create_subprocess_exec(
            sys.executable, str(checker_path), username,
            env=os.environ,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        try:
            stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=60)
        except asyncio.TimeoutError:
            proc.kill()
            await proc.communicate()
            return False
        
        output = stdout.decode('utf-8', errors='ignore') if stdout else ''
        if not output and stderr:
            output = stderr.decode('utf-8', errors='ignore')
        
        result = parse_json_output(output)
        if result:
            return result.get('isLive') is True
        return False
        
    except Exception:
        return False

def get_quality_rank(url):
    """Bewerte die Qualität anhand der URL."""
    suffix_ranks = [
        ('_origin.', 600), ('_uhd_60.', 550), ('_uhd.', 540),
        ('_hd_60.', 500), ('_hd.', 450), ('_sd.', 350), ('_ld.', 250)
    ]
    
    for suffix, rank in suffix_ranks:
        if suffix in url:
            return rank
    
    # Versuche Auflösung aus URL zu extrahieren
    match = re.search(r'(\d+)p', url)
    if match:
        return int(match.group(1))
    
    return 0

async def get_stream_url(username):
    if not await verify_live_status(username):
        error_response = {
            "username": username,
            "isLive": False,
            "error": "User is not currently live.",
            "timestamp": datetime.utcnow().isoformat() + 'Z'
        }
        print(json.dumps(error_response, indent=2), file=sys.stderr)
        return False

    async with async_playwright() as p:
        try:
            browser = await p.chromium.launch(headless=True)
            context = await browser.new_context(
                user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            )
            
            page = await context.new_page()
            flv_urls = []
            
            async def handle_request(request):
                url = request.url
                if '.flv' in url or 'pull-flv' in url:
                    flv_urls.append({
                        "url": url,
                        "type": request.resource_type,
                        "timestamp": datetime.utcnow().isoformat() + 'Z'
                    })
            
            page.on("request", handle_request)
            
            # Navigiere zur Live-Seite
            await page.goto(f'https://www.tiktok.com/@{username}/live', wait_until='load', timeout=60000)
            
            # Warte auf mögliche Cookie-Banner
            await page.wait_for_timeout(3000)
            
            # Akzeptiere Cookies falls vorhanden
            accept_button = await page.query_selector('button[data-e2e="cookie-banner-accept"]')
            if accept_button:
                await accept_button.click()
                await page.wait_for_timeout(1000)
            
            # Warte auf Stream-Laden
            await page.wait_for_timeout(8000)
            # Zusätzliche Wartezeit für Netzwerkanfragen
            await page.wait_for_timeout(10000)
            
            # Versuche Video abzuspielen
            video = await page.query_selector('video')
            if video:
                try:
                    await video.evaluate('v => v.play()')
                    await page.wait_for_timeout(3000)
                except:
                    pass
            
            await browser.close()
            
            if flv_urls:
                # Entferne Duplikate
                seen_urls = set()
                unique_urls = []
                for item in flv_urls:
                    if item["url"] not in seen_urls:
                        seen_urls.add(item["url"])
                        unique_urls.append(item)
                
                # Sortiere nach Qualität
                unique_urls.sort(key=lambda x: get_quality_rank(x["url"]), reverse=True)
                
                response = {
                    "username": username,
                    "isLive": True,
                    "streamCount": len(unique_urls),
                    "streams": unique_urls,
                    "vlcCommand": f'vlc "{unique_urls[0]["url"]}"' if unique_urls else "",
                    "timestamp": datetime.utcnow().isoformat() + 'Z'
                }
                print(json.dumps(response, indent=2))
                return True
            else:
                error_response = {
                    "username": username,
                    "isLive": False,
                    "error": "No stream URLs found - user may not be live",
                    "timestamp": datetime.utcnow().isoformat() + 'Z'
                }
                print(json.dumps(error_response, indent=2), file=sys.stderr)
                return False
                
        except Exception as e:
            try:
                await browser.close()
            except:
                pass
            
            error_response = {
                "error": True,
                "message": str(e),
                "timestamp": datetime.utcnow().isoformat() + 'Z'
            }
            print(json.dumps(error_response, indent=2), file=sys.stderr)
            return False

async def main():
    if len(sys.argv) != 2:
        print('Usage: python tiktok-get-stream.py <username>', file=sys.stderr)
        sys.exit(1)
    
    raw_username = sys.argv[1]
    username = raw_username.lstrip('@')
    
    if not username:
        print('Username must not be empty', file=sys.stderr)
        sys.exit(1)
    
    reject_busy_node()
    
    try:
        success = await get_stream_url(username)
        sys.exit(0 if success else 1)
    except Exception as e:
        error_response = {
            "error": True,
            "message": str(e),
            "timestamp": datetime.utcnow().isoformat() + 'Z'
        }
        print(json.dumps(error_response, indent=2), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    asyncio.run(main())
