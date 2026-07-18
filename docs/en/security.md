# Security and privacy

## Formal release gate

The complete Codex Security scan on 17 July 2026 closed all nine review scopes. Result: no critical, high, or medium findings and two validated low residual risks (Low/P3). They concern missing byte budgets at the local page bridge and during decompression of observed WebSocket messages. Both paths already require code execution in the page tab or control of the WebSocket message and provide no account takeover, cookie, secret, or cross-origin access.

Version 0.7.0 adds mobile WebView bridges, native microphone/PCM paths, and an Android token endpoint. These new boundaries are reviewed in addition to the browser extension; platform states not built or tested on real hardware are explicitly identified.

## Controls

- no cookie permission and no `document.cookie` access;
- no telemetry or remote scripts; only an explicit song-recognition click uploads a short audio sample to AudD;
- mobile WebView messages only from the `https://www.tiktok.com` main frame, at most 64 KiB, and only for known event and command types;
- the Media Services private key remains in a Vercel secret; Android receives only short-lived ES256 developer tokens;
- mobile audio recognition starts only after user action and ends after at most twelve seconds;
- no `eval`, `new Function`, or `innerHTML` assignment;
- `webRequest` without `webRequestBlocking`;
- at most 50 sanitized chat messages per tab;
- local speech and gain; the companion service binds only to `127.0.0.1` and enforces pairing, origin checks, and body-size limits;
- the report control opens TikTok's dialog but never completes or submits it.

## Retention

Stream URLs, chat, captions, profiles, participant aggregates, and diagnostics remain in browser `chrome.storage.session` and only in memory on mobile. Preferences and permanent mute identities persist in `chrome.storage.local`, UserDefaults, or DataStore; the AudD token remains only in the local service configuration.

## Additional residual risks

A page script can imitate the `postMessage` bridge. Signed media URLs can provide access while valid. TikTok can change its DOM, CDN domains, compression, or protobuf fields and cause false negatives. Browsers may reject picture-in-picture, fullscreen, or Web Audio routing.

The public security section contains no PoCs or valid signed URLs.
