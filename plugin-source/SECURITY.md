# Targeted security review

Targeted review on 2026-07-15; formal Codex Security release-gate scan completed on 2026-07-17. The 0.7.0 mobile, WebView, token and audio-flow delta was threat-modeled and statically reviewed on 2026-07-18; see `../security-scan/threat_model_0.7.0.md`.

The earlier formal scan closed all nine review scopes and validated two Low/P3 resource-boundary findings. Version 0.7.0 adds bounded participant storage, request-body limits, a loopback-only paired service, origin-restricted native WebViews and a short-lived token endpoint. Automated delta checks and the documented static review are required before publication; native device testing remains a separate release gate.

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
- Audio analysis, TTS gain and compression use local APIs. A song sample is transferred to AudD only after an explicit recognition click; the AudD token remains in the local service configuration.
- The companion service binds to `127.0.0.1`, requires a high-entropy pairing code, rejects non-extension browser origins, caps TTS bodies at 64 KiB and recognition bodies at 10 MiB, and deletes temporary speech files in `finally` cleanup.
- The WebSocket wrapper adds only `open`, `close`, and `message` listeners. It does not wrap or replace `send()`.
- The report control only opens TikTok's own dialog; it never selects a category or submits a report.
- Native WebViews accept bridge messages only from the HTTPS TikTok main frame, enforce a 64 KiB envelope limit and expose only fixed commands. Audio capture is explicit and capped at twelve seconds.
- The token endpoint returns only a short-lived developer token and expiry. It never returns or logs the Apple private key, Team ID, Key ID or Media ID.

## Residual risks

- A page script can forge the page-to-content `postMessage` bridge. Captions are therefore observational records, not cryptographically authenticated evidence.
- Signed media URLs can grant temporary access to a stream. They remain in session memory and should be handled as sensitive while valid.
- TikTok may change DOM labels, metadata layout, CDN domains, compression, or protobuf fields. Such changes can cause false negatives.
- Automatically clicking a localized caption control is best-effort and deliberately avoids clicking unidentified icon-only buttons.
- Fullscreen and picture-in-picture may be rejected when the browser requires transient user activation; the extension reports this without bypassing the browser policy.
- Web Audio routing may be unavailable for a particular player/media configuration. The extension reports the failure and must not claim that a physical sound-pressure limit is enforced.
