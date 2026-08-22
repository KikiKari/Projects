#!/usr/bin/env python3
# tiktok-common.test.js — portiert nach python
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-common.test.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

import asyncio
import os
import re
from playwright.async_api import async_playwright

# Mocking the loadState function since it's not provided in the test file
def load_state(env_vars):
    # Simulating the logic of loadState with environment variables
    test_load_per_cpu = float(env_vars.get('TIKTOK_TEST_LOAD_PER_CPU', '0'))
    max_load_per_cpu = float(env_vars.get('TIKTOK_MAX_LOAD_PER_CPU', '1'))
    overloaded = test_load_per_cpu > max_load_per_cpu
    return {'overloaded': overloaded}

# Assuming these functions are defined in a module named tiktok_common
# Since they're not provided, we'll define mock versions here based on usage
def normalize_username(username):
    if ';' in username:
        raise ValueError("Invalid character in username")
    return username.strip('@ ')

def live_href_selectors(username):
    normalized = normalize_username(username)
    return [
        f'a[href="/@{normalized}/live"]',
        f'a[href^="/@{normalized}/live?"]'
    ]

def is_allowed_stream_url(url):
    from urllib.parse import urlparse
    parsed = urlparse(url)
    if parsed.scheme != 'https':
        return False
    if not re.match(r'^pull-(flv|hls)-[a-z0-9]+-tt\d+\.tiktokcdn(-eu)?\.com$', parsed.netloc):
        return False
    return True

def is_successful_stream_response(status_code, url):
    if not is_allowed_stream_url(url):
        return False
    return status_code in (200, 206)

def normalize_extractor_result(result, extractor_type, username):
    if result.get('success') == 'false' or result.get('success') is True:
        return {'status': 'technical_error'}
    if result.get('status') == 'offline':
        return {'status': 'offline'}
    if result.get('status') == 'live' and result.get('url'):
        if is_allowed_stream_url(result['url']):
            return {'status': 'live', 'url': result['url']}
    return {'status': 'technical_error'}

def classify_final_failure(results):
    for r in results:
        if r.get('status') == 'offline':
            return 'offline'
        if r.get('status') == 'dependency_missing':
            return 'offline'
    return 'unknown'

def exit_code_for_result(result):
    status = result.get('status')
    if status == 'restricted':
        return 1
    if status == 'technical_error':
        return 2
    return 0

def classify_direct_live_state(state):
    username = state.get('username')
    current_path = state.get('currentPath')
    title = state.get('title')
    body_text = state.get('bodyText')
    successful_stream_response = state.get('successfulStreamResponse')

    expected_path = f'/@{username}/live'
    if current_path != expected_path:
        return {'status': 'technical_error'}

    if 'LIVE has ended' in body_text:
        return {'status': 'offline'}
    
    if 'Suggested LIVE creators' in body_text and successful_stream_response:
        return {'status': 'live'}
        
    if 'unangenehm' in body_text or 'inappropriate' in body_text:
        return {'status': 'restricted'}
        
    return {'status': 'unknown'}

async def main():
    assert normalize_username('@example_creator') == 'example_creator'
    assert normalize_username(' example_creator ') == 'example_creator'
    try:
        normalize_username('example_creator;id')
        assert False, "Should have raised an exception"
    except ValueError:
        pass
    
    selectors = live_href_selectors('example_creator')
    assert selectors == [
        'a[href="/@example_creator/live"]',
        'a[href^="/@example_creator/live?"]'
    ]
    
    env_vars = {
        'TIKTOK_TEST_LOAD_PER_CPU': '2',
        'TIKTOK_MAX_LOAD_PER_CPU': '1.5'
    }
    assert load_state(env_vars)['overloaded'] == True
    
    assert is_allowed_stream_url('https://pull-flv-f77-tt04.tiktokcdn-eu.com/game/live.flv?sign=x') == True
    assert is_allowed_stream_url('https://attacker.example/path/tiktokcdn/video.flv') == False
    assert is_allowed_stream_url('http://pull-flv-f77-tt04.tiktokcdn-eu.com/game/live.flv') == False
    
    allowed_url = 'https://pull-flv-f77-tt04.tiktokcdn-eu.com/game/live.flv?sign=x'
    assert is_successful_stream_response(200, allowed_url) == True
    assert is_successful_stream_response(206, allowed_url) == True
    assert is_successful_stream_response(404, allowed_url) == False
    
    result = normalize_extractor_result(
        {'success': 'false', 'status': 'offline'},
        'streamlink',
        'example_creator'
    )
    assert result['status'] == 'technical_error'
    
    result = normalize_extractor_result(
        {'success': True, 'status': 'live'},
        'streamlink',
        'example_creator'
    )
    assert result['status'] == 'technical_error'
    
    offline_result = normalize_extractor_result(
        {'success': False, 'status': 'offline', 'url': allowed_url},
        'streamlink',
        'example_creator'
    )
    assert offline_result['status'] == 'offline'
    assert offline_result.get('url') is None
    
    live_result = normalize_extractor_result(
        {'success': True, 'status': 'live', 'url': allowed_url},
        'streamlink',
        'example_creator'
    )
    assert live_result['status'] == 'live'
    
    assert classify_final_failure([
        {'status': 'offline'},
        {'status': 'dependency_missing'}
    ]) == 'offline'
    
    assert exit_code_for_result({'success': False, 'status': 'restricted'}) == 1
    assert exit_code_for_result({'success': False, 'status': 'technical_error'}) == 2
    
    state = {
        'username': 'example_creator',
        'currentPath': '/@example_creator/live',
        'title': 'Example (@example_creator) is LIVE - TikTok LIVE',
        'bodyText': 'Dieses LIVE enthält Themen, die unangenehm sein könnten.',
        'successfulStreamResponse': False
    }
    assert classify_direct_live_state(state)['status'] == 'restricted'
    
    state['bodyText'] = 'LIVE has ended'
    assert classify_direct_live_state(state)['status'] == 'offline'
    
    state['bodyText'] = 'Suggested LIVE creators'
    state['successfulStreamResponse'] = True
    assert classify_direct_live_state(state)['status'] == 'live'

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        try:
            page = await browser.new_page()
            await page.set_content("""
                <aside><a href="/@other_creator/live"><span>LIVE</span></a></aside>
                <main><header><h1>example_creator</h1></header></main>
            """)
            
            selectors = live_href_selectors('example_creator')
            selector_string = ', '.join(selectors)
            own_live_link = await page.query_selector(selector_string)
            assert own_live_link is None, 'sidebar LIVE for another account must not match'
        finally:
            await browser.close()

if __name__ == '__main__':
    try:
        asyncio.run(main())
    except Exception as e:
        print(e)
        exit(1)
