# Threat model delta — TikTok LIVE Companion 0.7.0

Date: 2026-07-18  
Scope: browser extension, loopback companion service, Vercel token endpoint, iOS WKWebView app, Android/HyperOS WebView app, audio recognition flows, and release artifacts.

## Assets and trust boundaries

- TikTok DOM, metadata, WebSocket frames, chat, captions and player state are untrusted inputs.
- The MAIN-world bridge crosses into native code only from the main frame at the exact `https://www.tiktok.com` origin. Every envelope is versioned, type-allowlisted and limited to 64 KiB.
- Native commands cross in the opposite direction through a fixed allowlist. The bridge exposes no cookie, storage, key or arbitrary native-method access.
- Microphone and experimental WebView PCM remain in memory and are bounded to an explicit twelve-second recognition action. Browser recognition separately sends a bounded sample to AudD only after a click.
- Android receives short-lived ShazamKit developer tokens from `/api/shazam-token`. The Media Services private key, Team ID and Key ID remain server-side environment variables.
- Persistent storage contains settings and durable author mutes only. Stream state, audio, chat, captions, signatures and tokens are not deliberately persisted.

## Primary attacker stories and controls

| Story | Control | Residual risk |
| --- | --- | --- |
| A TikTok page forges bridge events | Exact origin/main-frame checks, schema/type/size validation, text-only rendering | Same-origin page code can still forge observational values; events are not authenticated evidence. |
| A page invokes arbitrary native functionality | No generic JavaScript interface; fixed command and event allowlists | Platform WebView regressions remain upstream risk. |
| Oversized audio or messages exhaust memory | 64 KiB envelope cap, twelve-second PCM cap, bounded chat/state collections, cancellation | Codec conversion and device-specific WebView behavior require device testing. |
| External navigation reaches unsafe schemes | Only exact TikTok HTTPS stays in WebView; only validated HTTPS links open externally | The external destination itself remains outside app control. |
| A third party harvests developer tokens | POST-only endpoint, Android platform header, short five-minute expiry, per-IP rate bound, no-store response | The endpoint has no device attestation by design for HyperOS compatibility; distributed rate limiting depends on the hosting layer. |
| Logs or errors reveal Apple key material | Stable error codes; response and application logs never serialize configuration or exceptions | Vercel operator access and environment-variable governance remain deployment responsibilities. |
| A malicious archive adds an AAR or key | AAR, signing keys, build outputs and xcuserdata are excluded; SHA-256 manifest covers release artifacts | Users must obtain artifacts from the documented release location and verify hashes. |

## Security acceptance checks

- Automated bridge tests cover wrong origin, subframes, oversize input, unknown commands, storage access guards and audio duration.
- Token tests cover ES256 header/claims/signature, five-minute lifetime, cache reuse, missing configuration, signing failure, per-address throttling and secret-free error bodies.
- Extension and service regression tests cover bounded requests, paired loopback access, origin rejection, AudD opt-in behavior and security guards.
- Static review confirms no `addJavascriptInterface`, wildcard WebView origin, cleartext traffic, cookie API, `innerHTML`, `eval`, bundled ShazamKit AAR or Apple private key.

## Release limitations

- iOS build/signing and XCTest require macOS, Xcode, an Apple Developer team and the ShazamKit capability.
- Real Android Shazam matching requires Apple’s licensed AAR and token-service configuration. The distributable mock debug APK must display “ShazamKit nicht konfiguriert”.
- Physical HyperOS behavior is unverified until tested on a Xiaomi device; Android API compatibility alone is not a HyperOS device certification.
