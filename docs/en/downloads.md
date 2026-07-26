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
6e034b02dcdae010a0aec6e0fc42116363ca0eb13ee5caa7791093494a8c7790  tiktok-live-companion-plugin-0.7.1.zip
78b23fd4808738daee6bddb2ea2015b5761530c1ebf7db3c1e85692ccc5d535c  tiktok-live-companion-service-0.7.1.zip
8739c76e681f900923b900c9df0ef75cf421d39cabb54650c4b9ad19b6a76d85  tiktok-live-companion-ios-0.7.1-source.zip
da52da289023ed08287f21845921f1416fcd5b062d98f431479023c77d2c42ce  tiktok-live-companion-android-0.7.1-source.zip
```

## What's new

Version 0.7.1 adds native iOS and Android/HyperOS apps, an origin-restricted WebView bridge, and a short-lived ShazamKit token endpoint. The browser extension retains manual AudD recognition; mobile apps use ShazamKit with the microphone as the stable path and WebView PCM as experimental.

AudD receives an approximately twelve-second audio clip in the browser only after an explicit click. Mobile recognition also never starts without a click. The proprietary ShazamKit AAR, Apple keys, and signing certificates are not included in the archives.
