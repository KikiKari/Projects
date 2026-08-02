# Downloads and release 0.7.1

## Artifacts

- `tiktok-live-companion-extension-0.7.1.zip` – unpacked Edge/Chrome extension package
- `tiktok-live-companion-plugin-0.7.1.zip` – Codex plugin with skill, references, and tests
- `tiktok-live-companion-service-0.7.1.zip` – optional local Windows service
- `tiktok-live-companion-ios-0.7.1-source.zip` – complete SwiftUI/Xcode source project
- `tiktok-live-companion-android-0.7.1-source.zip` – Kotlin/Compose source project for Android and HyperOS
- `tiktok-live-companion-android-0.7.1.apk` – optional test package when the Android toolchain was available
- `tiktok-live-companion-0.7.1-SHA256.txt` – integrity values

## What's new

Browser extension 0.7.1 starts an already configured speech service through the local starter, marks Sherpa as active after setup, filters exact technical TTS repeats, and makes peak protection react earlier and dampen more at high strength. The existing browser VLC link list remains unchanged.

The 2 August 2026 alpha places **VLC Ersatz** below **WebSocket-Hook**, **LIVE-Informationen** directly below **Seiteninformationen**, and expands **Top-Chatter** in steps up to 50 with **Reset** and the existing mute control. After explicit user action, the local service installs only VideoLAN's stable Windows build.

Mobile source archives 0.7.1 align Chat/Game Mode, TTS dedupe, peak protection, Auto-Reconnect with a 400 ms minimum interval, Refresh with app/WebView cache clearing without cookie deletion, and more VLC-compatible HLS/FLV/MP4 candidates with the browser baseline. **VLC Ersatz** uses embedded LibVLC/MobileVLCKit, while **VLC Player** hands the same media URL to the external VLC app or its official store listing.
