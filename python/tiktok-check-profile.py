#!/usr/bin/env python3
# tiktok-check-profile.js — portiert nach python
# Quelle: javascript, OpenClaw@gateway1:skills/tiktok-live/scripts/tiktok-check-profile.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

"""
TikTok Live Status Checker
Prüft ausschließlich profilgebundene Live-Indikatoren.
Der allgemeine TikTok-Navigationspunkt "LIVE" ist kein Statussignal.
Unterstützt @handle-Normalisierung und optionalen Node-Lastschutz
via TIKTOK_MAX_LOAD_PER_CPU (Exit-Code 75 bei NODE_BUSY).
"""

import sys
import os
import json
import asyncio
import psutil
from playwright.async_api import async_playwright
from datetime import datetime


def reject_busy_node():
    limit = os.environ.get('TIKTOK_MAX_LOAD_PER_CPU')
    try:
        limit = float(limit)
    except (TypeError, ValueError):
        return

    if limit <= 0:
        return

    cpu_count = max(1, psutil.cpu_count())
    normalized_load = psutil.getloadavg()[0] / cpu_count
    if normalized_load > limit:
        print(f'NODE_BUSY normalizedLoad={normalized_load:.2f} limit={limit}', file=sys.stderr)
        sys.exit(75)


async def check_live_status(username):
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            viewport={'width': 1920, 'height': 1080}
        )
        page = await context.new_page()

        try:
            # Navigate to profile
            await page.goto(f'https://www.tiktok.com/@{username}', wait_until='domcontentloaded', timeout=30000)

            # Warte auf initialen Seitenaufbau
            await page.wait_for_timeout(2000)

            # DSGVO-Banner schließen - mehrere Varianten probieren
            # Variante 1: "Verstanden" Button (deutsch)
            verstanden_button = await page.query_selector('button:has-text("Verstanden"), [data-e2e="cookie-banner-accept"], button:has-text("Accept")')
            if verstanden_button:
                try:
                    await verstanden_button.click()
                except:
                    pass
                await page.wait_for_timeout(1000)

            # Variante 2: Andere Cookie-Buttons
            cookie_selectors = [
                'button:has-text("Akzeptieren")',
                'button:has-text("Alle akzeptieren")',
                'button:has-text("Allow all")',
                'button:has-text("Accept all")',
                'button.TUXButton:has-text("Accept")',
                '[data-testid="cookie-policy-banner-accept"]'
            ]

            for selector in cookie_selectors:
                btn = await page.query_selector(selector)
                if btn:
                    try:
                        await btn.click()
                    except:
                        pass
                    await page.wait_for_timeout(500)
                    break

            # Warte auf vollständiges Laden ("Erneute Veröffentlichungen" Reiter)
            # Dieser Reiter erscheint erst, wenn die Seite komplett geladen ist
            await page.wait_for_timeout(3000)

            # Zusätzlich warte auf network idle für API-Calls
            try:
                await page.wait_for_load_state('networkidle', timeout=5000)
            except:
                # Ignorieren - Seite sollte trotzdem genug geladen sein
                pass

            # Nochmal warten für Live-Status-Prüfung durch TikTok
            await page.wait_for_timeout(2000)

            # Screenshot für Debugging (optional, nur wenn DEBUG=1)
            if os.environ.get('DEBUG') == '1':
                await page.screenshot(path=f'/tmp/tiktok-{username}.png')

            # Check for LIVE indicators
            # Method 1: data-e2e="live-icon"
            profile_scope = page.locator('[data-e2e="creator-page-header"], [data-e2e="profile-avatar"]')
            live_icon = profile_scope.locator('[data-e2e="live-icon"]').first
            try:
                live_icon_visible = await live_icon.is_visible()
            except:
                live_icon_visible = False

            # Method 2: LIVE text/badge (scoped to profile header/avatar)
            profile_badge = profile_scope.get_by_text(r'^LIVE$', exact=True).first
            try:
                live_badge_visible = await profile_badge.is_visible()
            except:
                live_badge_visible = False

            # Method 3: Roter Rahmen um Profilbild - mehrere Selektoren
            profile_selectors = [
                'img[data-e2e="avatar"]',
                'div[data-e2e="profile-avatar"] img',
                '[data-e2e="creator-page-header"] img[alt*="profile"]'
            ]

            has_live_border = False
            for selector in profile_selectors:
                profile_img = await page.query_selector(selector)
                if profile_img:
                    styles = await profile_img.evaluate('''el => {
                        const computed = window.getComputedStyle(el);
                        const parent = el.parentElement;
                        const parentComputed = parent ? window.getComputedStyle(parent) : null;
                        return {
                            borderColor: computed.borderColor,
                            borderStyle: computed.borderStyle,
                            borderWidth: computed.borderWidth,
                            outlineColor: computed.outlineColor,
                            boxShadow: computed.boxShadow,
                            parentBorderColor: parentComputed ? parentComputed.borderColor : null,
                            parentBorderStyle: parentComputed ? parentComputed.borderStyle : null,
                            parentBorderWidth: parentComputed ? parentComputed.borderWidth : null
                        };
                    }''')

                    # Prüfe auf rote/live-farbige Rahmen
                    red_indicators = [
                        styles['borderColor'],
                        styles['outlineColor'],
                        styles['parentBorderColor']
                    ]

                    for color in red_indicators:
                        if color and ('255' in color or 'red' in color or 'rgb(254' in color or 'fe2c55' in color or '#fe2c' in color):
                            has_live_border = True
                            break

                    # Box-Shadow für Live-Indikator (TikTok nutzt oft Glow-Effekte)
                    if styles['boxShadow'] and ('255' in styles['boxShadow'] or '254' in styles['boxShadow']):
                        has_live_border = True

                    if has_live_border:
                        break

            # Method 4: Check für Live-Link oder Live-Button
            live_link = await page.query_selector(f'a[href*="/@{username}/live"]')
            has_live_link = live_link is not None

            # Method 5: Check für pulsierenden roten Punkt (Live-Indikator)
            live_indicator = profile_scope.locator('[class*="live-indicator"], div[class*="LiveBadge"]').first
            try:
                live_indicator_visible = await live_indicator.is_visible()
            except:
                live_indicator_visible = False

            is_live = live_icon_visible or live_badge_visible or has_live_border or has_live_link or live_indicator_visible

            result = {
                'username': username,
                'isLive': is_live,
                'timestamp': datetime.utcnow().isoformat() + 'Z',
                'indicators': {
                    'liveIcon': live_icon_visible,
                    'liveBadge': live_badge_visible,
                    'liveBorder': has_live_border,
                    'liveLink': has_live_link,
                    'liveIndicator': live_indicator_visible
                }
            }

            print(json.dumps(result, indent=2))
            await browser.close()
            return is_live

        except Exception as error:
            await browser.close()
            error_result = {
                'error': True,
                'message': str(error),
                'stack': getattr(error, '__traceback__', None),
                'timestamp': datetime.utcnow().isoformat() + 'Z'
            }
            print(json.dumps(error_result), file=sys.stderr)
            sys.exit(1)


async def main():
    if len(sys.argv) < 2:
        print('Usage: python3 tiktok-check-profile.py <username>', file=sys.stderr)
        sys.exit(1)

    raw_username = sys.argv[1]
    if not raw_username:
        print('Username must not be empty', file=sys.stderr)
        sys.exit(1)

    username = raw_username.lstrip('@')
    if not username:
        print('Username must not be empty', file=sys.stderr)
        sys.exit(1)

    reject_busy_node()

    try:
        is_live = await check_live_status(username)
        sys.exit(0 if is_live else 1)
    except Exception as error:
        error_result = {
            'error': True,
            'message': str(error),
            'timestamp': datetime.utcnow().isoformat() + 'Z'
        }
        print(json.dumps(error_result), file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    asyncio.run(main())
