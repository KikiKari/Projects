#!/usr/bin/env python3
# tiktok-check-profile.js — portiert nach python
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-check-profile.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

"""
Basic TikTok LIVE profile checker.

Scopes every signal to the requested account and ignores unrelated sidebar
LIVE labels. This profile-only checker does not classify restricted LIVE;
use the enhanced checker or dispatcher for that distinction.

Exit 0 = account-specific LIVE, 1 = offline, 2 = dependency/technical
failure, 75 = overloaded before Playwright startup.
"""

import sys
import json
import os
import asyncio
from datetime import datetime
from playwright.async_api import async_playwright
import stat

def normalize_username(username):
    """Normalize TikTok username by removing @ symbol if present"""
    if not username:
        raise ValueError("Username cannot be empty")
    if username.startswith('@'):
        return username[1:]
    return username

def enforce_load_limit(method):
    """Stub function to match JS interface - could implement load limiting logic"""
    pass

# LIVE href selectors pattern
def live_href_selectors(username):
    """Generate CSS selectors for live links specific to a username"""
    return [
        f'a[href="/@{username}/live"]',
        f'a[href="/@{username}/live/"]',
        f'[href="/@{username}/live"]',
        f'[href="/@{username}/live/"]'
    ]

async def check_live_status(username):
    """Check if a TikTok user is currently live streaming"""
    try:
        # Test if Playwright Chromium is available
        async with async_playwright() as p:
            try:
                executable_path = p.chromium.executable_path
                # Check if executable exists and is executable
                if not os.path.exists(executable_path) or not os.access(executable_path, os.X_OK):
                    raise FileNotFoundError(f"Playwright Chromium not found at {executable_path}")
            except Exception as e:
                print(json.dumps({
                    "error": True,
                    "status": "dependency_missing",
                    "method": "playwright_basic",
                    "message": f"Playwright Chromium unavailable: {str(e)}",
                    "timestamp": datetime.now().isoformat()
                }), file=sys.stderr)
                sys.exit(2)
            
            browser = await p.chromium.launch(headless=True)
            context = await browser.new_context(
                user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                viewport={"width": 1920, "height": 1080}
            )
            page = await context.new_page()
            
            try:
                # Navigate to profile
                await page.goto(f'https://www.tiktok.com/@{username}', 
                              wait_until='domcontentloaded', timeout=30000)
                
                # Wait for initial page build
                await page.wait_for_timeout(2000)
                
                # Close GDPR banner - try multiple variants
                # Variant 1: "Verstanden" button (German)
                verstanden_button = await page.query_selector('button:has-text("Verstanden"), [data-e2e="cookie-banner-accept"], button:has-text("Accept")')
                if verstanden_button:
                    try:
                        await verstanden_button.click()
                        await page.wait_for_timeout(1000)
                    except:
                        pass
                
                # Variant 2: Other cookie buttons
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
                            await page.wait_for_timeout(500)
                            break
                        except:
                            pass
                
                # Wait for complete loading ("Erneute Veröffentlichungen" tab)
                await page.wait_for_timeout(3000)
                
                # Additionally wait for network idle for API calls
                try:
                    await page.wait_for_load_state('networkidle', timeout=5000)
                except:
                    # Ignore - page should be loaded enough anyway
                    pass
                
                # Wait again for Live status check by TikTok
                await page.wait_for_timeout(2000)
                
                # Screenshot for debugging (optional, only if DEBUG=1)
                if os.environ.get('DEBUG') == '1':
                    await page.screenshot(path=f'/tmp/tiktok-{username}.png')
                
                # Account-scoped LIVE indicators only. Sidebar/recommendation labels
                # are outside the exact /@username/live link and never count.
                # Method 1: live icon inside the exact account link
                live_link_selectors = ', '.join(live_href_selectors(username))
                live_link_element = await page.query_selector(live_link_selectors)
                has_live_link = live_link_element is not None if live_link_element else False
                
                live_icon_visible = False
                if has_live_link:
                    try:
                        live_icon = await live_link_element.query_selector('[data-e2e="live-icon"], [class*="LiveBadge"], [class*="live-indicator"]')
                        if live_icon:
                            live_icon_visible = await live_icon.is_visible()
                    except:
                        live_icon_visible = False
                
                # Method 2: exact LIVE text/badge inside the account link
                live_badge_visible = False
                if has_live_link:
                    try:
                        # This is a simplified approach since Playwright doesn't have direct text matching like this
                        live_badge = await live_link_element.query_selector('text=/^LIVE$/i')
                        if live_badge:
                            live_badge_visible = await live_badge.is_visible()
                    except:
                        live_badge_visible = False
                else:
                    live_badge_visible = False
                
                # Method 3: Live frame at profile header/avatar
                profile_selectors = [
                    '[data-e2e="user-page"] img[data-e2e="avatar"]',
                    '[data-e2e="user-page"] div[data-e2e="profile-avatar"] img',
                    'main header img[data-e2e="avatar"]',
                    'main header [class*="avatar"] img'
                ]
                
                has_live_border = False
                for selector in profile_selectors:
                    profile_img = await page.query_selector(selector)
                    if profile_img:
                        try:
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
                            
                            # Check for red/live-colored borders
                            red_indicators = [
                                styles.get('borderColor', ''),
                                styles.get('outlineColor', ''),
                                styles.get('parentBorderColor', '')
                            ]
                            
                            for color in red_indicators:
                                if color and ('255' in color or 'red' in color.lower() or 
                                            'rgb(254' in color or 'fe2c55' in color or '#fe2c' in color):
                                    has_live_border = True
                                    break
                            
                            # Box-shadow for live indicator (TikTok often uses glow effects)
                            box_shadow = styles.get('boxShadow', '')
                            if box_shadow and ('255' in box_shadow or '254' in box_shadow):
                                has_live_border = True
                            
                            if has_live_border:
                                break
                        except:
                            continue
                
                # Method 4 & 5: exact account LIVE link and live indicator inside that account link
                live_indicator_visible = False
                if has_live_link:
                    try:
                        live_indicator = await live_link_element.query_selector('[class*="live-indicator"], div[class*="LiveBadge"]')
                        if live_indicator:
                            live_indicator_visible = await live_indicator.is_visible()
                    except:
                        live_indicator_visible = False
                
                is_live = (
                    has_live_link or
                    has_live_border or
                    live_icon_visible or
                    live_indicator_visible or
                    live_badge_visible
                )
                
                result = {
                    "username": username,
                    "isLive": is_live,
                    "timestamp": datetime.now().isoformat(),
                    "indicators": {
                        "liveIcon": live_icon_visible,
                        "liveBadge": live_badge_visible,
                        "liveBorder": has_live_border,
                        "liveLink": has_live_link,
                        "liveIndicator": live_indicator_visible
                    }
                }
                
                print(json.dumps(result, indent=2))
                return is_live
                
            except Exception as error:
                print(json.dumps({
                    "error": True,
                    "status": "technical_error",
                    "message": str(error),
                    "stack": str(error.__traceback__),
                    "timestamp": datetime.now().isoformat()
                }), file=sys.stderr)
                return None
            finally:
                await browser.close()
                
    except Exception as e:
        print(json.dumps({
            "error": True,
            "status": "technical_error",
            "message": str(e),
            "timestamp": datetime.now().isoformat()
        }), file=sys.stderr)
        return None

async def main():
    if len(sys.argv) != 2:
        print('Usage: python3 tiktok-check-profile.py <username>', file=sys.stderr)
        sys.exit(64)
    
    try:
        username = normalize_username(sys.argv[1])
    except ValueError as error:
        print('Usage: python3 tiktok-check-profile.py <username>', file=sys.stderr)
        print(str(error), file=sys.stderr)
        sys.exit(64)
    
    enforce_load_limit('playwright_basic')
    
    is_live = await check_live_status(username)
    if is_live is None:
        sys.exit(2)
    elif is_live:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
