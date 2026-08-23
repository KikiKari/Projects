#!/usr/bin/env bash
# tiktok-check-profile.js — portiert nach shell
# Quelle: javascript, OpenClaw@gateway2:skills/tiktok-live/scripts/tiktok-check-profile.js
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Basic TikTok LIVE profile checker.
#
# Scopes every signal to the requested account and ignores unrelated sidebar
# LIVE labels. This profile-only checker does not classify restricted LIVE;
# use the enhanced checker or dispatcher for that distinction.
#
# Exit 0 = account-specific LIVE, 1 = offline, 2 = dependency/technical
# failure, 75 = overloaded before Playwright startup.

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly COMMON_FILE="${SCRIPT_FILE%/*}/tiktok-common.sh"

if [[ ! -f "$COMMON_FILE" ]]; then
    echo "Error: Common functions file not found at $COMMON_FILE" >&2
    exit 2
fi

source "$COMMON_FILE"

# Check arguments
if [[ $# -ne 1 ]]; then
    echo 'Usage: tiktok-check-profile.sh <username>' >&2
    exit 64
fi

username="$1"
normalize_username "$username" || {
    echo "Invalid username format: $username" >&2
    exit 64
}

enforce_load_limit "playwright_basic"

# Check dependencies
if ! command -v chromium >/dev/null 2>&1; then
    jq -n --arg msg "Chromium not found in PATH" '{
        error: true,
        status: "dependency_missing",
        method: "playwright_basic",
        message: $msg,
        timestamp: (now | todateiso8601)
    }' >&2
    exit 2
fi

if ! command -v playwright >/dev/null 2>&1; then
    jq -n --arg msg "Playwright CLI not found in PATH" '{
        error: true,
        status: "dependency_missing",
        method: "playwright_basic",
        message: $msg,
        timestamp: (now | todateiso8601)
    }' >&2
    exit 2
fi

# Create temporary directory for session files
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Generate script content
cat >"$TMPDIR/script.js" <<'EOF'
const { chromium } = require('playwright');
const fs = require('fs');

async function checkLiveStatus(username) {
    try {
        fs.accessSync(chromium.executablePath(), fs.constants.X_OK);
    } catch (error) {
        console.error(JSON.stringify({
            error: true,
            status: 'dependency_missing',
            method: 'playwright_basic',
            message: `Playwright Chromium unavailable: ${error.message}`,
            timestamp: new Date().toISOString()
        }));
        process.exit(2);
    }
    
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        viewport: { width: 1920, height: 1080 }
    });
    const page = await context.newPage();
    
    try {
        // Navigate to profile
        await page.goto(`https://www.tiktok.com/@${username}`, { 
            waitUntil: 'domcontentloaded',
            timeout: 30000 
        });
        
        // Wait for initial page build
        await page.waitForTimeout(2000);
        
        // Close GDPR banner - try multiple variants
        // Variant 1: "Verstanden" button (German)
        const verstandenButton = await page.$('button:has-text("Verstanden"), [data-e2e="cookie-banner-accept"], button:has-text("Accept")');
        if (verstandenButton) {
            await verstandenButton.click().catch(() => {});
            await page.waitForTimeout(1000);
        }
        
        // Variant 2: Other cookie buttons
        const cookieSelectors = [
            'button:has-text("Akzeptieren")',
            'button:has-text("Alle akzeptieren")',
            'button:has-text("Allow all")',
            'button:has-text("Accept all")',
            'button.TUXButton:has-text("Accept")',
            '[data-testid="cookie-policy-banner-accept"]'
        ];
        
        for (const selector of cookieSelectors) {
            const btn = await page.$(selector);
            if (btn) {
                await btn.click().catch(() => {});
                await page.waitForTimeout(500);
                break;
            }
        }
        
        // Wait for complete loading ("Erneute Veröffentlichungen" tab)
        // This tab appears only when the page is fully loaded
        await page.waitForTimeout(3000);
        
        // Additionally wait for network idle for API calls
        try {
            await page.waitForLoadState('networkidle', { timeout: 5000 });
        } catch (e) {
            // Ignore - page should still be sufficiently loaded
        }
        
        // Wait again for TikTok's live status check
        await page.waitForTimeout(2000);
        
        // Screenshot for debugging (optional, only if DEBUG=1)
        if (process.env.DEBUG === '1') {
            await page.screenshot({ path: `/tmp/tiktok-${username}.png` });
        }
        
        // Account-scoped LIVE indicators only. Sidebar/recommendation labels
        // are outside the exact /@username/live link and never count.
        // Method 1: live icon inside the exact account link
        const liveLink = page.locator('[href="/@' + username + '/live"]').first();
        const hasLiveLink = await liveLink.isVisible().catch(() => false);
        const liveIconVisible = hasLiveLink &&
            await liveLink.locator(
                '[data-e2e="live-icon"], [class*="LiveBadge"], [class*="live-indicator"]'
            ).first().isVisible().catch(() => false);
        
        // Method 2: exact LIVE text/badge inside the account link
        const liveBadge = hasLiveLink
            ? liveLink.locator('text=/^LIVE$/i').first()
            : page.locator('body > __never_match__');
        const liveBadgeVisible = await liveBadge.isVisible().catch(() => false);
        
        // Method 3: Live frame on profile header/avatar
        const profileSelectors = [
            '[data-e2e="user-page"] img[data-e2e="avatar"]',
            '[data-e2e="user-page"] div[data-e2e="profile-avatar"] img',
            'main header img[data-e2e="avatar"]',
            'main header [class*="avatar"] img'
        ];
        
        let hasLiveBorder = false;
        for (const selector of profileSelectors) {
            const profileImg = await page.$(selector);
            if (profileImg) {
                const styles = await profileImg.evaluate(el => {
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
                });
                
                // Check for red/live-colored borders
                const redIndicators = [
                    styles.borderColor,
                    styles.outlineColor,
                    styles.parentBorderColor
                ];
                
                for (const color of redIndicators) {
                    if (color && (color.includes('255') || color.includes('red') || color.includes('rgb(254') || color.includes('fe2c55') || color.includes('#fe2c'))) {
                        hasLiveBorder = true;
                        break;
                    }
                }
                
                // Box-shadow for live indicator (TikTok often uses glow effects)
                if (styles.boxShadow && (styles.boxShadow.includes('255') || styles.boxShadow.includes('254'))) {
                    hasLiveBorder = true;
                }
                
                if (hasLiveBorder) break;
            }
        }
        
        // Method 4: exact account LIVE link
        // Method 5: live indicator inside that account link
        const liveIndicatorVisible = hasLiveLink &&
            await liveLink.locator(
                '[class*="live-indicator"], div[class*="LiveBadge"]'
            ).first().isVisible().catch(() => false);
        
        const isLive =
            hasLiveLink ||
            hasLiveBorder ||
            liveIconVisible ||
            liveIndicatorVisible ||
            liveBadgeVisible;
        
        console.log(JSON.stringify({
            username,
            isLive,
            timestamp: new Date().toISOString(),
            indicators: {
                liveIcon: liveIconVisible,
                liveBadge: liveBadgeVisible,
                liveBorder: hasLiveBorder,
                liveLink: hasLiveLink,
                liveIndicator: liveIndicatorVisible
            }
        }, null, 2));
        
        return isLive;
        
    } catch (error) {
        console.error(JSON.stringify({
            error: true,
            status: 'technical_error',
            message: error.message,
            stack: error.stack,
            timestamp: new Date().toISOString()
        }));
        return null;
    } finally {
        await browser.close();
    }
}

checkLiveStatus(process.argv[2]).then(isLive => process.exit(isLive === null ? 2 : (isLive ? 0 : 1)));
EOF

# Run the Node.js script with provided username
node "$TMPDIR/script.js" "$username"
exit_code=$?

# Map exit codes as per original specification
case $exit_code in
    0|1|2|75) exit $exit_code ;;
    *) exit 2 ;;  # Default to technical error for any other code
esac
