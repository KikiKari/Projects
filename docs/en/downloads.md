# Downloads and release 0.7.1

## Artifacts

- `tiktok-live-companion-extension-0.7.1.zip` – unpacked Edge/Chrome extension package
- `tiktok-live-companion-plugin-0.7.1.zip` – Codex plugin with skill, references, and tests
- `tiktok-live-companion-service-0.7.1.zip` – optional local Windows service
- `tiktok-live-companion-ios-0.7.1-source.zip` – complete SwiftUI/Xcode source project
- `tiktok-live-companion-android-0.7.1-source.zip` – Kotlin/Compose source project for Android and HyperOS
- `tiktok-live-companion-0.7.1-SHA256.txt` – integrity values

## SHA-256

```text
db0d00b390af95a1829adb1904e3ea371a68905513822478e733cf42c376b58b  tiktok-live-companion-extension-0.7.1.zip
3b7d4265405a66efc333ecda3911f59f889faf7135557b3bf0094d9804c5360b  tiktok-live-companion-plugin-0.7.1.zip
78b23fd4808738daee6bddb2ea2015b5761530c1ebf7db3c1e85692ccc5d535c  tiktok-live-companion-service-0.7.1.zip
2d9b6b1b189bc9680c2538d48274867ba6d487557b23979724640961f9406ede  tiktok-live-companion-ios-0.7.1-source.zip
8739c76e681f900923b900c9df0ef75cf421d39cabb54650c4b9ad19b6a76d85  tiktok-live-companion-android-0.7.1-source.zip
```

## What's new

Version 0.7.1 adds native iOS and Android/HyperOS apps, an origin-restricted WebView bridge, and a short-lived ShazamKit token endpoint. The browser extension retains manual AudD recognition; mobile apps use ShazamKit with the microphone as the stable path and WebView PCM as experimental.

AudD receives an approximately twelve-second audio clip in the browser only after an explicit click. Mobile recognition also never starts without a click. The proprietary ShazamKit AAR, Apple keys, and signing certificates are not included in the archives.
