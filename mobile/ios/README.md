# TikTok LIVE Companion iOS 0.8.1

Native SwiftUI/WKWebView companion for iOS 15 and newer. Music recognition uses Apple's ShazamKit. The stable path records twelve seconds from the microphone after explicit user action; WebView PCM capture is marked experimental and falls back to the microphone when unavailable.

## Prerequisites

- macOS with Xcode and an Apple Developer team
- an App ID with the ShazamKit capability enabled
- `xcodegen` only when regenerating `TikTokLiveCompanion.xcodeproj` from `project.yml`

Open `TikTokLiveCompanion.xcodeproj`, select a development team, and build the `TikTokLiveCompanion` scheme. No credentials or private keys belong in this project.

The app loads only `https://www.tiktok.com` in its WebView, never reads cookies, and opens other hosts in the system browser.

## ARM64 source preparation

The iOS source work is maintained on `tlc-arm64` in an iOS-branch worktree. The standalone Foundation monitor-core checks can run on Linux ARM64 using a native Swift toolchain:

```sh
SWIFTC=/home/codex/tlc-integration/ios-swift-6.1.3-arm64/usr/bin/swiftc sh mobile/ios/monitor-core-tests/run-monitor-core.sh
```

These checks cover the platform-independent monitor model only. They do not compile SwiftUI, MobileVLCKit, background scheduling or the iOS application. Apple builds and simulator checks require macOS with Xcode. The monitor integration is prepared but has not been built or validated on Apple platforms; do not assign an iOS Build 22 on the basis of these checks.
