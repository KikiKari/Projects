# Security and privacy

## Formal release gate

The complete Codex Security scan on 17 July 2026 closed all nine review scopes. Result: no critical, high, or medium findings and two validated low residual risks (Low/P3). They concern missing byte budgets at the local page bridge and during decompression of observed WebSocket messages. Both paths already require code execution in the page tab or control of the WebSocket message and provide no account takeover, cookie, secret, or cross-origin access.

The supplied 0.5.0 artifacts were not modified for the review. Recommended size, concurrency, and storage budgets are tracked for a subsequent version.

## Controls

- no cookie permission and no `document.cookie` access;
- no telemetry, remote scripts, or uploads;
- no `eval`, `new Function`, or `innerHTML` assignment;
- `webRequest` without `webRequestBlocking`;
- at most 50 sanitized chat messages per tab;
- local-only speech and audio processing;
- the report control opens TikTok's dialog but never completes or submits it.

## Retention

Stream URLs, chat, captions, profiles, and diagnostics remain in `chrome.storage.session`. Only auto-hook, speech-continuity, and speech-volume preferences persist.

## Additional residual risks

A page script can imitate the `postMessage` bridge. Signed media URLs can provide access while valid. TikTok can change its DOM, CDN domains, compression, or protobuf fields and cause false negatives. Browsers may reject picture-in-picture, fullscreen, or Web Audio routing.

The public security section contains no PoCs or valid signed URLs.
