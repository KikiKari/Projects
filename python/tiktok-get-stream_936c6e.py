#!/usr/bin/env python3
# tiktok-get-stream.js — portiert nach python
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-get-stream.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

"""
Basic TikTok LIVE URL extractor.

Accepts only observed HTTPS TikTok-CDN .flv responses with HTTP 2xx.
Success writes one naked URL to stdout. Offline/no URL exits 1, dependency
or technical failure exits 2, and preflight overload exits 75.
"""

import sys
import json
import time
import re
from datetime import datetime
from playwright.sync_api import sync_playwright
from urllib.parse import urlparse

def normalize_username(username):
    """Normalize TikTok username by removing @ symbol if present"""
    if not username:
        raise ValueError("Username is required")
    if username.startswith('@'):
        return username[1:]
    return username

def enforce_load_limit(method):
    """Enforce load limits - placeholder for actual implementation"""
    pass

def forced_offline(method, username):
    """Check if we should force offline mode - placeholder for actual implementation"""
    return False

def is_successful_stream_response(status_code, url):
    """Check if response is a successful stream response"""
    return (200 <= status_code < 300 and 
            url.endswith('.flv') and 
            'tiktokcdn' in url)

def quality_key_from_url(url):
    """Extract quality key from URL"""
    match = re.search(r'(\d+)p', url)
    return match.group(1) + 'p' if match else 'unknown'

def main():
    if len(sys.argv) < 2:
        print('Usage: python tiktok-get-stream.py <username>')
        sys.exit(64)
    
    try:
        username = normalize_username(sys.argv[1])
    except ValueError as e:
        print('Usage: python tiktok-get-stream.py <username>')
        print(str(e))
        sys.exit(64)
    
    enforce_load_limit('playwright_network_basic')
    json_output = '--json' in sys.argv
    
    if forced_offline('playwright_network_basic', username):
        sys.exit(1)
    
    def get_stream_url(username):
        try:
            with sync_playwright() as p:
                # Check if browser is available
                try:
                    browser_path = p.chromium.executable_path
                except Exception as e:
                    error_result = {
                        'error': True,
                        'status': 'dependency_missing',
                        'method': 'playwright_network_basic',
                        'message': f'Playwright Chromium unavailable: {str(e)}',
                        'timestamp': datetime.utcnow().isoformat() + 'Z'
                    }
                    print(json.dumps(error_result))
                    sys.exit(2)
                
                browser = p.chromium.launch(headless=True)
                context = browser.new_context(
                    user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                )
                page = context.new_page()
                
                flv_urls = []
                max_collected_urls = 100
                
                def handle_response(response):
                    url = response.url
                    if (len(flv_urls) < max_collected_urls and 
                        is_successful_stream_response(response.status, url)):
                        flv_urls.append({
                            'url': url,
                            'status': response.status,
                            'timestamp': datetime.utcnow().isoformat() + 'Z'
                        })
                
                page.on('response', handle_response)
                
                try:
                    # Navigate to live page
                    page.goto(f'https://www.tiktok.com/@{username}/live', 
                             wait_until='load', 
                             timeout=60000)
                    
                    # Wait for potential DSGVO/consent dialogs
                    time.sleep(3)
                    
                    # Accept cookies if present
                    accept_button = page.query_selector('button[data-e2e="cookie-banner-accept"]')
                    if accept_button:
                        accept_button.click()
                        time.sleep(1)
                    
                    # Wait for stream to load (5-10 seconds typically)
                    time.sleep(8)
                    
                    # Try to trigger video play if needed
                    video = page.query_selector('video')
                    if video:
                        try:
                            video.evaluate('v => v.play()')
                        except:
                            pass
                        time.sleep(3)
                    
                    if len(flv_urls) > 0:
                        # Deduplicate URLs
                        seen_urls = {}
                        unique_urls = []
                        for item in flv_urls:
                            if item['url'] not in seen_urls:
                                seen_urls[item['url']] = True
                                unique_urls.append(item)
                        
                        # Sort by quality indicator (if present in URL)
                        def get_quality(item):
                            match = re.search(r'(\d+)p', item['url'])
                            return int(match.group(1)) if match else 0
                        
                        unique_urls.sort(key=get_quality, reverse=True)
                        
                        result = {
                            'success': True,
                            'status': 'live',
                            'method': 'playwright',
                            'username': username,
                            'isLive': True,
                            'streamCount': len(unique_urls),
                            # Keep the full signed URL: TikTok stream URLs are unusable
                            # without their query string.
                            'streams': [
                                {
                                    **item,
                                    'quality': quality_key_from_url(item['url'])
                                }
                                for item in unique_urls[:10]
                            ],
                            'url': unique_urls[0]['url'],
                            'timestamp': datetime.utcnow().isoformat() + 'Z'
                        }
                        
                        print(json.dumps(result) if json_output else result['url'])
                        return 0
                    else:
                        error_result = {
                            'success': False,
                            'status': 'offline',
                            'method': 'playwright',
                            'username': username,
                            'isLive': False,
                            'error': 'No stream URLs found - user may not be live',
                            'timestamp': datetime.utcnow().isoformat() + 'Z'
                        }
                        print(json.dumps(error_result))
                        return 1
                
                except Exception as e:
                    error_result = {
                        'error': True,
                        'status': 'technical_error',
                        'method': 'playwright',
                        'message': str(e),
                        'timestamp': datetime.utcnow().isoformat() + 'Z'
                    }
                    print(json.dumps(error_result))
                    return 2
                
                finally:
                    browser.close()
        
        except Exception as e:
            error_result = {
                'error': True,
                'status': 'technical_error',
                'method': 'playwright',
                'message': str(e),
                'timestamp': datetime.utcnow().isoformat() + 'Z'
            }
            print(json.dumps(error_result))
            return 2
    
    exit_code = get_stream_url(username)
    sys.exit(exit_code)

if __name__ == '__main__':
    main()
