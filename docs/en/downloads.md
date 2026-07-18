# Downloads and release 0.7.0

## Artifacts

- `tiktok-live-companion-extension-0.7.0.zip` – unpacked Edge/Chrome extension package
- `tiktok-live-companion-plugin-0.7.0.zip` – Codex plugin with skill, references, and tests
- `tiktok-live-companion-service-0.7.0.zip` – optional local Windows service
- `tiktok-live-companion-ios-0.7.0-source.zip` – complete SwiftUI/Xcode source project
- `tiktok-live-companion-android-0.7.0-source.zip` – Kotlin/Compose source project for Android and HyperOS
- `tiktok-live-companion-android-0.7.0-debug.apk` – optional test package when the Android toolchain was available
- `tiktok-live-companion-0.7.0-SHA256.txt` – integrity values

## SHA-256

```text
40721b800a0f1aa4580ebabaa13ad82d10426ce0287eb1559749385f5850dfce  tiktok-live-companion-extension-0.7.0.zip
c8696754cc06453ad26237cb0d1d641ddeb19b7c21df7df3b06c7ac0b55f457c  tiktok-live-companion-plugin-0.7.0.zip
617c63288976c8507d2e5cd6cfaf9eb5767f43b4c901e703f29d3aff58aa6c56  tiktok-live-companion-service-0.7.0.zip
```

## What's new

Version 0.7.0 adds native iOS and Android/HyperOS apps, an origin-restricted WebView bridge, and a short-lived ShazamKit token endpoint. The browser extension retains manual AudD recognition; mobile apps use ShazamKit with the microphone as the stable path and WebView PCM as experimental.

AudD receives an approximately twelve-second audio clip in the browser only after an explicit click. Mobile recognition also never starts without a click. The proprietary ShazamKit AAR, Apple keys, and signing certificates are not included in the archives.
