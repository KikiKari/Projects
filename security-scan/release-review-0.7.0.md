# Security release review — 0.7.0

Date: 2026-07-18  
Result: **PASS for source and mock artifacts; device-dependent gates remain explicit.**

## Reviewed delta

- Exact-origin, main-frame-only WKWebView and AndroidX WebKit bridges
- Versioned 64 KiB message envelopes and fixed native command allowlists
- Explicit, cancellable twelve-second microphone/WebView PCM flows
- Android ShazamKit developer-token provider and Vercel ES256 token endpoint
- UserDefaults/DataStore persistence boundaries
- Android mock APK, iOS/Android source archives and package exclusions

## Automated evidence

- Browser extension regression/security script: pass
- Shared mobile bridge origin, frame, size, command, duration and storage guards: pass
- Native project static contract/secret scan: pass
- Companion service tests: 7 pass
- Token endpoint and documentation site tests: 27 pass
- Android JUnit/Robolectric tests: 5 pass
- Android `mockDebug` compilation and APK assembly: pass
- Six release SHA-256 values recomputed: pass
- ZIP inventory excludes `.aar`, `.p8`, `.gradle`, `.kotlin`, build output and `xcuserdata`: pass

## Findings

No new source-level High, Medium or Low finding was confirmed in the 0.7.0 delta. The unauthenticated Android token endpoint intentionally trades device attestation for compatibility with Android distributions such as HyperOS; short expiry, no-store responses and rate limiting reduce but do not eliminate token harvesting. Hosting-layer distributed rate enforcement remains a deployment responsibility.

## Gates not executable on this Windows host

- iOS compile/XCTest, ShazamKit capability validation and Apple signing require macOS/Xcode and the user’s Apple Developer configuration.
- Real Android ShazamKit matching requires Apple’s separately licensed AAR and configured token service.
- TikTok LIVE, microphone, PiP and WebView player behavior require physical-device/manual acceptance.
- HyperOS has not been tested on a physical Xiaomi device; only Android API compatibility and the Google-services-free dependency graph were checked.

See `threat_model_0.7.0.md` for trust boundaries, attacker stories and residual risks.
