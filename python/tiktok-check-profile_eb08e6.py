#!/usr/bin/env python3
# tiktok-check-profile.js — portiert nach python
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/tiktok-check-profile.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

"""
Enhanced TikTok LIVE status checker.

Uses exact account selectors and the direct /@username/live page to return
live, restricted, offline, dependency_missing, technical_error, or
overloaded. An accessible LIVE requires a successful allowed TikTok-CDN
FLV response; unrelated sidebar LIVE labels never count.

Browser resources are closed on every completion path.
"""

import sys
import json
import random
import time
import os
from datetime import datetime
from urllib.parse import urlparse
import asyncio
from playwright.async_api import async_playwright
import tiktok_common

def human_delay(min_ms=2000, max_ms=4000):
    """Realistische Verzögerung (2-4s zufällig)"""
    delay = random.randint(min_ms, max_ms)
    time.sleep(delay / 1000)

async def close_dsgvo_banner(page):
    """Alle bekannten Cookie/DSGVO-Button-Varianten"""
    selectors = [
        'button:has-text("Verstanden")',
        '[data-e2e="cookie-banner-accept"]',
        'button:has-text("Accept")',
        'button:has-text("Akzeptieren")',
        'button:has-text("Alle akzeptieren")',
        'button:has-text("Allow all")',
        'button:has-text("Accept all")',
        'button.TUXButton:has-text("Accept")',
        '[data-testid="cookie-policy-banner-accept"]'
    ]

    for selector in selectors:
        try:
            btn = await page.query_selector(selector)
            if btn:
                await btn.click()
                await page.wait_for_timeout(random.randint(1000, 2000))
                return True
        except Exception:
            pass
    return False

async def wait_for_page_ready(page):
    """
    KRITISCH: TikTok lädt die Seite in Phasen.
    Der LIVE-Badge und der rote Rahmen erscheinen ERST wenn die Seite
    vollständig geladen ist. Erkennbar am Menüband:
    "Videos" + "Erneute Veröffentlichungen" + "Gelikt"
    "Erneute Veröffentlichungen" erscheint als LETZTES.
    """

    # Phase 1: Initiales Laden abwarten
    await page.wait_for_timeout(random.randint(2000, 3000))

    # Phase 2: Warte explizit auf "Erneute Veröffentlichungen" Tab
    # Das ist der zuverlässigste Indikator für vollständigen Seitenaufbau
    page_ready = False
    try:
        await page.wait_for_selector(
            'text="Erneute Veröffentlichungen"',
            state='visible',
            timeout=25000
        )
        page_ready = True
    except Exception:
        # Fallback: englische Version probieren
        try:
            await page.wait_for_selector(
                'text="Reposts"',
                state='visible',
                timeout=5000
            )
            page_ready = True
        except Exception:
            # Letzter Fallback: einfach auf networkidle warten
            try:
                await page.wait_for_load_state('networkidle', timeout=10000)
            except Exception:
                pass

    # Phase 3: Nach dem Erscheinen des Menübands noch kurz warten,
    # damit der LIVE-Badge/roter Rahmen gerendert wird
    await page.wait_for_timeout(random.randint(2000, 3000))

    return page_ready

async def detect_live_status(page, username):
    indicators = {
        'liveIcon': False,
        'liveBadge': False,
        'liveBorder': False,
        'liveLink': False,
        'liveIndicator': False
    }
    detection_method = 'none'

    # --- Priorität 1: LIVE-Icon innerhalb des exakten Account-LIVE-Links ---
    try:
        live_href_selectors = tiktok_common.live_href_selectors(username)
        live_link = page.locator(','.join(live_href_selectors)).first
        live_icon_visible = await live_link.locator(
            '[data-e2e="live-icon"], [class*="LiveBadge"], [class*="live-indicator"]'
        ).first.is_visible()
        if live_icon_visible:
            indicators['liveIcon'] = True
            detection_method = 'live-icon'
            return {'isLive': True, 'detectionMethod': detection_method, 'indicators': indicators}
    except Exception:
        pass

    # --- Priorität 2: exaktes LIVE-Badge innerhalb desselben Account-Links ---
    try:
        live_href_selectors = tiktok_common.live_href_selectors(username)
        live_link = page.locator(','.join(live_href_selectors)).first
        live_badge = live_link.locator('text=/^LIVE$/i').first
        live_badge_visible = await live_badge.is_visible()
        if live_badge_visible:
            indicators['liveBadge'] = True
            detection_method = 'live-badge'
            return {'isLive': True, 'detectionMethod': detection_method, 'indicators': indicators}
    except Exception:
        pass

    # --- Priorität 3: Live-Rahmen am Profilkopf/Avatar des Accounts ---
    try:
        profile_selectors = [
            '[data-e2e="user-page"] img[data-e2e="avatar"]',
            '[data-e2e="user-page"] div[data-e2e="profile-avatar"] img',
            'main header img[data-e2e="avatar"]',
            'main header [class*="avatar"] img'
        ]

        for selector in profile_selectors:
            profile_img = await page.query_selector(selector)
            if not profile_img:
                continue

            styles = await profile_img.evaluate("""el => {
                const computed = window.getComputedStyle(el);
                const parent = el.parentElement;
                const parentComputed = parent ? window.getComputedStyle(parent) : null;
                const grandParent = parent ? parent.parentElement : null;
                const grandParentComputed = grandParent ? window.getComputedStyle(grandParent) : null;
                return {
                    borderColor: computed.borderColor,
                    outlineColor: computed.outlineColor,
                    boxShadow: computed.boxShadow,
                    parentBorderColor: parentComputed ? parentComputed.borderColor : null,
                    parentBoxShadow: parentComputed ? parentComputed.boxShadow : null,
                    grandParentBorderColor: grandParentComputed ? grandParentComputed.borderColor : null,
                    grandParentBoxShadow: grandParentComputed ? grandParentComputed.boxShadow : null
                };
            }""")

            all_colors = [
                styles.get('borderColor'),
                styles.get('outlineColor'),
                styles.get('parentBorderColor'),
                styles.get('grandParentBorderColor')
            ]
            all_shadows = [
                styles.get('boxShadow'),
                styles.get('parentBoxShadow'),
                styles.get('grandParentBoxShadow')
            ]

            def is_red(color):
                if not color or color == 'none':
                    return False
                return ('255' in color or 'red' in color or
                        'rgb(254' in color or 'fe2c55' in color or
                        '#fe2c' in color or 'rgb(255, 0' in color or
                        'rgb(255, 44' in color)

            if any(is_red(color) for color in all_colors if color) or any(is_red(shadow) for shadow in all_shadows if shadow):
                indicators['liveBorder'] = True
                detection_method = 'live-border'
                return {'isLive': True, 'detectionMethod': detection_method, 'indicators': indicators}
    except Exception:
        pass

    # --- Priorität 4: Live-Indikator innerhalb des exakten Account-Links ---
    try:
        live_href_selectors = tiktok_common.live_href_selectors(username)
        live_link = page.locator(','.join(live_href_selectors)).first
        live_indicator_visible = await live_link.locator(
            '[class*="live-indicator"], div[class*="LiveBadge"]'
        ).first.is_visible()
        if live_indicator_visible:
            indicators['liveIndicator'] = True
            detection_method = 'live-indicator'
            return {'isLive': True, 'detectionMethod': detection_method, 'indicators': indicators}
    except Exception:
        pass

    # --- Priorität 5: sichtbarer exakter /@username/live-Link ---
    try:
        live_href_selectors = tiktok_common.live_href_selectors(username)
        live_link = page.locator(','.join(live_href_selectors)).first
        if await live_link.is_visible():
            indicators['liveLink'] = True
            detection_method = 'live-link'
            return {'isLive': True, 'detectionMethod': detection_method, 'indicators': indicators}
    except Exception:
        pass

    return {'isLive': False, 'detectionMethod': detection_method, 'indicators': indicators}

async def inspect_direct_live_state(page, username):
    successful_stream_response = False
    
    def response_handler(response):
        nonlocal successful_stream_response
        if tiktok_common.is_successful_stream_response(response.status, response.url):
            successful_stream_response = True

    page.on('response', response_handler)
    try:
        await page.goto(f'https://www.tiktok.com/@{username}/live', {
            'wait_until': 'domcontentloaded',
            'timeout': 30000
        })
        await page.wait_for_timeout(random.randint(8000, 10000))
        current_url = urlparse(page.url)
        try:
            body_text = await page.locator('body').inner_text()
        except Exception:
            body_text = ''
        
        return tiktok_common.classify_direct_live_state({
            'username': username,
            'currentPath': current_url.path,
            'title': await page.title(),
            'bodyText': body_text,
            'successfulStreamResponse': successful_stream_response
        })
    except Exception as error:
        return {'status': 'technical_error', 'reason': str(error)}
    finally:
        page.remove_listener('response', response_handler)

async def check_live_status(username):
    try:
        async with async_playwright() as p:
            # Check if chromium is available
            try:
                executable_path = p.chromium.executable_path
                if not os.access(executable_path, os.X_OK):
                    raise Exception("Chromium not executable")
            except Exception as error:
                print(json.dumps({
                    'error': True,
                    'status': 'dependency_missing',
                    'method': 'playwright_enhanced',
                    'message': f'Playwright Chromium unavailable: {str(error)}',
                    'timestamp': datetime.now().isoformat()
                }), file=sys.stderr)
                sys.exit(2)

            browser = await p.chromium.launch(headless=True)
            context = await browser.new_context(
                user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                viewport={'width': 1920, 'height': 1080}
            )
            page = await context.new_page()

            # Navigiere zum Profil
            await page.goto(f'https://www.tiktok.com/@{username}', {
                'wait_until': 'domcontentloaded',
                'timeout': 30000
            })

            # Step 1: DSGVO Banner schließen
            banner_closed = await close_dsgvo_banner(page)

            # Step 2: Warte auf vollständigen Seitenaufbau
            # KRITISCH: LIVE-Badge erscheint erst nach "Erneute Veröffentlichungen"
            page_ready = await wait_for_page_ready(page)

            # Debug-Screenshot
            if os.environ.get('DEBUG') == '1':
                await page.screenshot(path=f'/tmp/tiktok-{username}-v2.png', full_page=True)

            # Step 3: Live-Status prüfen (priorisiert)
            live_result = await detect_live_status(page, username)

            # Step 4: Accountgenaue /live-Seite prüfen. Das trennt zugängliche
            # Streams, Login-/Content-Sperren und tatsächlich beendete Streams.
            direct_result = await inspect_direct_live_state(page, username)
            
            if direct_result['status'] == 'restricted':
                final_status = 'restricted'
            elif live_result['isLive'] or direct_result['status'] == 'live':
                final_status = 'live'
            else:
                final_status = direct_result['status']

            # Ergebnis ausgeben
            result = {
                'username': username,
                'status': final_status,
                'isLive': final_status == 'live' or final_status == 'restricted',
                'detectionMethod': 'account-live-restricted' if direct_result['status'] == 'restricted' else live_result['detectionMethod'],
                'isAgeRestricted': final_status == 'restricted',
                'ageRestrictionReason': direct_result.get('reason') if final_status == 'restricted' else None,
                'indicators': live_result['indicators'],
                'bannerClosed': banner_closed,
                'pageFullyLoaded': page_ready,
                'timestamp': datetime.now().isoformat(),
                'version': '2.1'
            }

            print(json.dumps(result, indent=2))
            return final_status

    except Exception as error:
        result = {
            'username': username,
            'isLive': False,
            'status': 'technical_error',
            'detectionMethod': 'error',
            'isAgeRestricted': False,
            'ageRestrictionReason': None,
            'indicators': {},
            'error': str(error),
            'timestamp': datetime.now().isoformat(),
            'version': 2
        }
        print(json.dumps(result, indent=2), file=sys.stderr)
        return 'technical_error'
    finally:
        if 'browser' in locals():
            await browser.close()

async def main():
    if len(sys.argv) != 2:
        print('Usage: python tiktok-check-profile.py <username>', file=sys.stderr)
        sys.exit(64)
    
    try:
        username = tiktok_common.normalize_username(sys.argv[1])
    except Exception as error:
        print('Usage: python tiktok-check-profile.py <username>', file=sys.stderr)
        print(str(error), file=sys.stderr)
        sys.exit(64)
    
    tiktok_common.enforce_load_limit('playwright_enhanced')
    
    status = await check_live_status(username)
    if status == 'live':
        sys.exit(0)
    elif status == 'offline' or status == 'restricted':
        sys.exit(1)
    else:
        sys.exit(2)

if __name__ == '__main__':
    asyncio.run(main())
