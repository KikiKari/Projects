#!/usr/bin/env python3
# tiktok-get-stream.js — portiert nach python
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/tiktok-get-stream.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

"""
Enhanced TikTok LIVE URL extractor.

Order: Playwright response interception, streamlink, then yt-dlp. Every
result is schema-normalized and must be an allowed HTTPS TikTok-CDN FLV
URL. Fallbacks use fixed argument arrays, bounded output, timeouts, and
process-group cleanup.

Exit 0 = URL, 1 = offline/restricted/no URL, 2 = dependency/technical
failure, 75 = overloaded before Playwright startup.
"""

import asyncio
import json
import os
import random
import re
import subprocess
import sys
import time
from pathlib import Path

# Import from tiktok-common.py
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from tiktok_common import (
    classify_final_failure,
    enforce_load_limit,
    exit_code_for_result,
    forced_offline,
    is_successful_stream_response,
    normalize_extractor_result,
    normalize_username,
    quality_key_from_url
)

FALLBACK_TIMEOUT_MS = 45000
FALLBACK_MAX_OUTPUT = 1024 * 1024


def log(message):
    print(message, file=sys.stderr)


def run_fallback(script_path, args):
    async def _run():
        try:
            proc = await asyncio.create_subprocess_exec(
                'bash', script_path, *args,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout_data, stderr_data = await asyncio.wait_for(
                proc.communicate(),
                timeout=FALLBACK_TIMEOUT_MS / 1000
            )
            
            stdout_str = stdout_data.decode('utf-8', errors='ignore')
            stderr_str = stderr_data.decode('utf-8', errors='ignore')
            
            if len(stdout_str.encode('utf-8')) > FALLBACK_MAX_OUTPUT:
                return {'code': 2, 'stdout': '', 'stderr': 'fallback output exceeded limit'}
                
            if len(stderr_str.encode('utf-8')) > FALLBACK_MAX_OUTPUT:
                return {'code': 2, 'stdout': '', 'stderr': 'fallback output exceeded limit'}
                
            return {
                'code': proc.returncode if proc.returncode is not None else 2,
                'stdout': stdout_str.strip(),
                'stderr': stderr_str.strip()
            }
            
        except asyncio.TimeoutError:
            try:
                proc.terminate()
                await asyncio.sleep(3)
                proc.kill()
            except ProcessLookupError:
                pass
            return {'code': 2, 'stdout': '', 'stderr': 'fallback timeout'}
        except Exception as e:
            return {'code': 2, 'stdout': '', 'stderr': str(e)}

    return asyncio.run(_run())


def parse_fallback_result(method, username, execution):
    for text in [execution.get('stdout', ''), execution.get('stderr', '')]:
        if not text:
            continue
        try:
            value = json.loads(text)
            if isinstance(value, dict):
                return normalize_extractor_result(value, method, username)
        except (json.JSONDecodeError, TypeError):
            continue
    
    return normalize_extractor_result({
        'success': False,
        'status': 'overloaded' if execution.get('code') == 75 else 'technical_error',
        'method': method,
        'username': username,
        'message': execution.get('stderr', f'fallback exited {execution.get("code", "unknown")}')
    }, method, username)


def playwright_preflight():
    try:
        from playwright.sync_api import sync_playwright
        
        with sync_playwright() as p:
            executable = p.chromium.executable_path
            if not os.access(executable, os.X_OK):
                raise PermissionError(f"Chromium not executable: {executable}")
            return {'ok': True, 'executable': executable}
    except Exception as e:
        return {
            'ok': False,
            'status': 'dependency_missing',
            'error': f'Playwright Chromium unavailable: {str(e)}'
        }


def human_delay(min_ms=2000, max_ms=4000):
    return random.randint(min_ms, max_ms) / 1000.0


def handle_popups(page):
    closed = False
    
    # DSGVO selectors
    dsgvo_selectors = [
        'button:has-text("Verstanden")', '[data-e2e="cookie-banner-accept"]',
        'button:has-text("Accept")', 'button:has-text("Akzeptieren")',
        'button:has-text("Alle akzeptieren")', 'button:has-text("Allow all")',
        'button:has-text("Accept all")', '[data-testid="cookie-policy-banner-accept"]'
    ]
    
    for selector in dsgvo_selectors:
        try:
            btn = page.wait_for_selector(selector, state='visible', timeout=3000)
            if btn:
                btn.click()
                time.sleep(human_delay(1000, 2000))
                closed = True
                break
        except Exception:
            continue
    
    # Login popup 1
    try:
        login_text = page.query_selector('text="Bei TikTok anmelden"')
        if login_text:
            close_btn = page.query_selector('div[role="dialog"] [aria-label="Close"], div[role="dialog"] button[aria-label="Schließen"], div[role="dialog"] svg')
            if close_btn:
                close_btn.click()
                time.sleep(human_delay(1000, 2000))
                closed = True
    except Exception:
        pass
    
    # Login popup 2
    try:
        skip_btn = page.query_selector('button:has-text("Jetzt nicht"), button:has-text("Not now")')
        if skip_btn:
            skip_btn.click()
            time.sleep(human_delay(1000, 2000))
            closed = True
    except Exception:
        pass
    
    return closed


def check_restrictions(page):
    restriction_texts = [
        'text="Bei TikTok anmelden"',
        'text=/Dieses LIVE enthält Themen/',
        'text="Melde dich an für das vollständige Erlebnis"',
        'text=/Melde dich an für das volle/',
        'text="Log in to TikTok"',
        'text=/mature content/',
        'text=/age-restricted/'
    ]
    
    for selector in restriction_texts:
        try:
            el = page.query_selector(selector)
            if el and el.is_visible():
                reason = re.sub(r'[/""]', '', selector.replace('text=', ''))
                return {'restricted': True, 'reason': reason}
        except Exception:
            continue
    
    return {'restricted': False, 'reason': None}


def extract_with_playwright(username, quality_preference):
    preflight = playwright_preflight()
    if not preflight['ok']:
        return {
            'success': False,
            'method': 'playwright',
            'status': preflight['status'],
            'error': preflight['error']
        }
    
    try:
        from playwright.sync_api import sync_playwright
        
        with sync_playwright() as p:
            browser = p.chromium.launch(
                headless=True,
                args=['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu', '--disable-dev-shm-usage']
            )
            
            context = browser.new_context(
                user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                viewport={'width': 1920, 'height': 1080}
            )
            
            page = context.new_page()
            collected_urls = []
            
            def on_response(response):
                url = response.url
                if len(collected_urls) < 100 and is_successful_stream_response(response.status, url):
                    collected_urls.append({
                        'url': url,
                        'status': response.status,
                        'timestamp': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
                    })
            
            page.on('response', on_response)
            
            # Navigate to live page
            page.goto(f'https://www.tiktok.com/@{username}/live', 
                     wait_until='domcontentloaded', timeout=30000)
            
            # Handle popups
            handle_popups(page)
            
            # Wait for page load
            time.sleep(human_delay(3000, 5000))
            try:
                page.wait_for_load_state('networkidle', timeout=10000)
            except Exception:
                pass
            
            # Check restrictions
            restrictions = check_restrictions(page)
            if restrictions['restricted']:
                log(f'Playwright: Stream restricted - {restrictions["reason"]}')
                return {
                    'success': False,
                    'method': 'playwright',
                    'status': 'restricted',
                    'restricted': True,
                    'reason': restrictions['reason']
                }
            
            # Try to play video
            try:
                video = page.query_selector('video')
                if video:
                    video.evaluate('v => v.play()')
            except Exception:
                pass
            
            # Wait for FLV URLs
            time.sleep(human_delay(8000, 12000))
            
            # Second attempt at handling popups
            handle_popups(page)
            time.sleep(human_delay(3000, 5000))
            
            # Check restrictions again
            restrictions2 = check_restrictions(page)
            if restrictions2['restricted']:
                log(f'Playwright: Stream became restricted after wait - {restrictions2["reason"]}')
                return {
                    'success': False,
                    'method': 'playwright',
                    'status': 'restricted',
                    'restricted': True,
                    'reason': restrictions2['reason']
                }
            
            # Evaluate URLs
            if len(collected_urls) == 0:
                log('Playwright: No FLV URLs captured via network monitoring.')
                return {
                    'success': False,
                    'method': 'playwright',
                    'status': 'offline',
                    'restricted': False,
                    'reason': 'No FLV URLs found'
                }
            
            # Deduplicate and sort by quality
            unique_urls_dict = {}
            for item in collected_urls:
                base_url = item['url'].split('?')[0]
                if base_url not in unique_urls_dict:
                    unique_urls_dict[base_url] = item
            
            unique_urls = list(unique_urls_dict.values())
            
            quality_order = {
                'original': ['_origin.flv', '_uhd_60.flv', '_hd_60.flv', '_hd.flv', '_sd.flv', '_ld.flv'],
                '1080p60': ['_uhd_60.flv', '_hd_60.flv', '_hd.flv', '_sd.flv', '_ld.flv'],
                '720p60': ['_hd_60.flv', '_hd.flv', '_sd.flv', '_ld.flv'],
                '720p': ['_hd.flv', '_sd.flv', '_ld.flv'],
                '540p': ['_sd.flv', '_ld.flv'],
                '360p': ['_ld.flv'],
                'auto': ['_origin.flv', '_uhd_60.flv', '_hd_60.flv', '_hd.flv', '_sd.flv', '_ld.flv'],
            }.get(quality_preference, [])
            
            best_url = None
            for suffix in quality_order:
                for url_item in unique_urls:
                    if suffix in url_item['url']:
                        best_url = url_item
                        break
                if best_url:
                    break
            
            if not best_url and quality_preference in ('auto', 'original'):
                best_url = unique_urls[0]
            
            if not best_url:
                return {
                    'success': False,
                    'method': 'playwright',
                    'status': 'quality_unavailable',
                    'reason': f'Requested quality {quality_preference} was not captured in this fresh browser session'
                }
            
            return {
                'success': True,
                'status': 'live',
                'method': 'playwright',
                'username': username,
                'url': best_url['url'],
                'quality': quality_preference,
                'allUrls': [{'url': item['url'], 'quality': quality_key_from_url(item['url'])} for item in unique_urls],
                'allUrlsCount': len(unique_urls),
                'timestamp': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
            }
    
    except Exception as e:
        log(f'Playwright error: {str(e)}')
        return {
            'success': False,
            'method': 'playwright',
            'status': 'technical_error',
            'error': str(e)
        }
    finally:
        try:
            browser.close()
        except Exception:
            pass


def try_streamlink(username, quality):
    script_path = os.path.join(os.path.dirname(__file__), 'extraction-methods', 'extract-tiktok-streamlink.sh')
    execution = run_fallback(script_path, [username, quality, '--json'])
    return parse_fallback_result('streamlink', username, execution)


def try_yt_dlp(username, quality):
    script_path = os.path.join(os.path.dirname(__file__), 'extraction-methods', 'extract-tiktok-yt-dlp.sh')
    
    yt_format_map = {
        'original': 'hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld',
        '1080p60': 'hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
        '720p60': 'hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
        '720p': 'hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld',
        '540p': 'hls-sd/hls-ld/flv-sd/flv-ld',
        '360p': 'hls-ld/flv-ld',
        'auto': 'hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld',
    }
    
    yt_format = yt_format_map.get(quality, yt_format_map['auto'])
    execution = run_fallback(script_path, [username, yt_format, '--json'])
    return parse_fallback_result('yt-dlp', username, execution)


async def get_stream_url(username, quality_preference='auto'):
    timestamp = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
    
    # 1. Playwright
    log(f'[1/3] Trying Playwright for @{username}...')
    pw_result = extract_with_playwright(username, quality_preference)
    if pw_result.get('success'):
        pw_result['timestamp'] = timestamp
        return pw_result
    if pw_result.get('status') in ('restricted', 'overloaded'):
        return pw_result
    log(f'Playwright result: {pw_result.get("reason", pw_result.get("error", "failed"))}')
    
    # 2. Streamlink
    log(f'[2/3] Trying streamlink for @{username} (quality: {quality_preference})...')
    sl_result = try_streamlink(username, quality_preference)
    if sl_result.get('success'):
        return sl_result
    if sl_result.get('status') in ('restricted', 'overloaded'):
        return sl_result
    log(f'Streamlink result: {sl_result.get("message", sl_result.get("error", "failed"))}')
    
    # 3. yt-dlp
    log(f'[3/3] Trying yt-dlp for @{username}...')
    yt_result = try_yt_dlp(username, quality_preference)
    if yt_result.get('success'):
        return yt_result
    if yt_result.get('status') in ('restricted', 'overloaded'):
        return yt_result
    log(f'yt-dlp result: {yt_result.get("message", yt_result.get("error", "failed"))}')
    
    # All failed
    status = classify_final_failure([pw_result, sl_result, yt_result])
    return {
        'success': False,
        'status': status,
        'username': username,
        'message': 'All extraction methods failed (Playwright, streamlink, yt-dlp).',
        'playwrightReason': pw_result.get('reason', pw_result.get('error')),
        'streamlinkReason': sl_result.get('message', sl_result.get('error')),
        'ytdlpReason': yt_result.get('message', yt_result.get('error')),
        'timestamp': timestamp
    }


def main():
    if len(sys.argv) < 2:
        print('Usage: python3 tiktok-get-stream.py <username> [quality: original|1080p60|720p60|720p|540p|360p|auto] [--json]', file=sys.stderr)
        sys.exit(1)
    
    try:
        cli_username = normalize_username(sys.argv[1])
    except ValueError as e:
        print(str(e), file=sys.stderr)
        sys.exit(64)
    
    enforce_load_limit('playwright_streamlink_ytdlp')
    if forced_offline('playwright_streamlink_ytdlp', cli_username):
        sys.exit(1)
    
    cli_quality = 'auto'
    for arg in sys.argv[2:]:
        if not arg.startswith('--'):
            cli_quality = arg
            break
    
    cli_json = '--json' in sys.argv
    
    valid_qualities = ['original', '1080p60', '720p60', '720p', '540p', '360p', 'auto']
    if cli_quality not in valid_qualities:
        print('Invalid quality; expected original, 1080p60, 720p60, 720p, 540p, 360p, or auto', file=sys.stderr)
        sys.exit(64)
    
    try:
        result = asyncio.run(get_stream_url(cli_username, cli_quality))
        if cli_json:
            print(json.dumps(result, indent=2))
        else:
            if result.get('success'):
                print(result['url'])
            else:
                print(result.get('message', ''), file=sys.stderr)
        
        sys.exit(exit_code_for_result(result))
    except Exception as e:
        print(f'Unhandled error: {str(e)}', file=sys.stderr)
        sys.exit(2)


if __name__ == '__main__':
    main()
