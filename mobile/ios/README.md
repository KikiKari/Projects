# TikTok LIVE Companion iOS 0.7.0

Native SwiftUI/WKWebView companion for iOS 15 and newer. Music recognition uses Apple's ShazamKit. The stable path records twelve seconds from the microphone after explicit user action; WebView PCM capture is marked experimental and falls back to the microphone when unavailable.

## Prerequisites

- macOS with Xcode and an Apple Developer team
- an App ID with the ShazamKit capability enabled
- `xcodegen` only when regenerating `TikTokLiveCompanion.xcodeproj` from `project.yml`

Open `TikTokLiveCompanion.xcodeproj`, select a development team, and build the `TikTokLiveCompanion` scheme. No credentials or private keys belong in this project.

The app loads only `https://www.tiktok.com` in its WebView, never reads cookies, and opens other hosts in the system browser.
