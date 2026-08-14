# Architecture

## Components

- `content-core.js`: pure URL/chat normalization, profile and summary detection, media classification, quality metadata extraction, and metadata traversal
- `content.js`: isolated-world DOM inspection plus TikTok caption, chat fallback, public-profile refresh, local Web Audio controls, report-dialog, and quality-control automation
- `background.js`: passive CDN request observation, per-tab session state, non-sensitive preferences, and hook registration
- `proto-main.js`: minimal protobuf reader for TikTok push frames, captions, public chat, viewer statistics, likes, and social events
- `hook.js`: optional MAIN-world WebSocket observer installed before page scripts after reload
- `sidepanel.*`: local presentation and user-triggered export/copy actions
- `companion-service/`: loopback-only Node.js service for Windows speech WAV output and explicitly initiated AudD recognition

## Hook lifecycle

1. The user clicks the hook button in the side panel.
2. The service worker registers `proto-main.js` and `hook.js` at `document_start` in the MAIN world.
3. For a manual hook the registration lasts for the browser session; with Autostart it persists across browser restarts. The active TikTok tab is reloaded.
4. On the next document start, `hook.js` wraps the constructor with a transparent `Proxy` and only adds a `message` listener.
5. Caption, public-chat, and LIVE-statistics records are decoded in the page world and forwarded to the isolated content script.

When the active tab is switched to TikTok's `/embed/live/@handle` route, the service worker can open a normal `/@handle/live` tab in the same window with `active: false`. That source tab is marked chat-only, muted in the content script, and relays public chat, gifts and LIVE statistics into the active embed tab state. It is a normal browser tab because Manifest V3 content scripts cannot read TikTok chat from a fully hidden page.

## Full tab reset

The reset action clears only the extension's `chrome.storage.session` state for the active tab, registers the hook again and calls `chrome.tabs.reload({ bypassCache: true })`. It does not clear cookies, login state, TikTok storage, or browser-wide caches.

The page-to-content bridge is not cryptographically authenticated. Its output is useful for collection and troubleshooting but should not be treated as an independently authenticated transcript.

## Data retention

Stream state uses `chrome.storage.session`, including at most 50 sanitized chat messages and 5,000 observed participant aggregates. Preferences and permanent mute identities use `chrome.storage.local`. The AudD token is never stored by the extension; it remains in the loopback service configuration. Signed stream URLs may contain bearer-like query tokens and should not be published while still valid.

## Accessibility and player actions

The side panel renders only text nodes with `textContent`. Emoji sequences and confidently detected per-stream team tags are removed from speech. Optional speech first tries the paired local Windows service and falls back to Web Speech. A manually initiated song-recognition action captures about twelve seconds of tab audio and sends it through the local service to AudD. Player and report buttons only operate TikTok's existing page controls; the report action stops after opening TikTok's dialog.

The speech enabled flag is persisted separately from the volume and language settings. If TikTok fullscreen teardown causes the browser to rebuild the side panel, the content script reports the fullscreen exit and the service worker re-enables the side panel for the tab; the side panel then restores the active speech state for new chat lines.

The audio meter reports dBFS, not calibrated dB SPL. After explicit activation, `content.js` connects the primary video to a local `DynamicsCompressorNode` and analyser. The configurable threshold controls digital compression only; operating-system volume, amplifier gain and headphone sensitivity remain outside the extension's visibility.
