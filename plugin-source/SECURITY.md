# Targeted security review

Targeted review on 2026-07-15; formal Codex Security release-gate scan completed on 2026-07-17.

The formal scan closed all nine review scopes and validated two Low/P3 resource-boundary findings. There were no critical, high, or medium findings. The supplied 0.5.0 artifacts were not modified. Recommended byte, concurrency, and storage budgets are tracked for a subsequent version.

## Permissions

- `activeTab`, `tabs`, and `scripting` are used only for the user-selected TikTok tab and hook reload workflow.
- `sidePanel` hosts the local interface.
- `storage.session` holds tab state, public profile cache and optional diagnostics. `storage.local` contains only Autostart, speech continuity and speech volume preferences; URLs, chat and captions are not persisted there.
- `webRequest` is passive. The extension does not request `webRequestBlocking` and cannot modify traffic.
- Host permissions are limited to `www.tiktok.com` and named TikTok CDN suffixes.

## Data flow

- No cookie API permission and no `document.cookie` access.
- No remote scripts, analytics, telemetry, fetch uploads, API keys, or third-party API calls. A credentials-free GET to the creator's public TikTok profile page is allowed to refresh public profile values.
- No `eval`, `new Function`, or assignment to `innerHTML`.
- UI output is created with DOM nodes and `textContent`.
- Public chat is sanitized and limited to 50 session-only records per tab. Optional speech remains local to the browser.
- Diagnostic exports redact signed URL query values and contain neither chat contents nor cookies or API keys.
- Audio analysis and compression use only the local Web Audio API. The reported value is dBFS and must not be represented as a calibrated hearing-safety measurement in dB SPL.
- The WebSocket wrapper adds only `open`, `close`, and `message` listeners. It does not wrap or replace `send()`.
- The report control only opens TikTok's own dialog; it never selects a category or submits a report.

## Residual risks

- A page script can forge the page-to-content `postMessage` bridge. Captions are therefore observational records, not cryptographically authenticated evidence.
- Signed media URLs can grant temporary access to a stream. They remain in session memory and should be handled as sensitive while valid.
- TikTok may change DOM labels, metadata layout, CDN domains, compression, or protobuf fields. Such changes can cause false negatives.
- Automatically clicking a localized caption control is best-effort and deliberately avoids clicking unidentified icon-only buttons.
- Fullscreen and picture-in-picture may be rejected when the browser requires transient user activation; the extension reports this without bypassing the browser policy.
- Web Audio routing may be unavailable for a particular player/media configuration. The extension reports the failure and must not claim that a physical sound-pressure limit is enforced.
