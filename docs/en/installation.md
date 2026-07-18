# Installation

## Requirements

- Microsoft Edge or Google Chrome 114 or newer
- a public TikTok LIVE tab
- the unpacked `tiktok-live-companion-extension-0.7.0.zip`

## Steps

1. Extract the ZIP file.
2. Open `edge://extensions` or `chrome://extensions`.
3. Enable **Developer mode**.
4. Select **Load unpacked**.
5. Choose the folder containing `manifest.json`.
6. Open a public TikTok LIVE tab and click the extension icon.

## Optional local speech and song service

1. Extract `tiktok-live-companion-service-0.7.0.zip` and open PowerShell in that folder.
2. Run `npm run setup`; an AudD token is required only for song recognition.
3. Start the service with `npm start`.
4. Enter the displayed pairing code in the side panel. The service listens only on `127.0.0.1:43117`.

## First run

1. **Inspect page** reads caption metadata, visible controls, and stream information.
2. **Enable captions** activates only a clearly identified TikTok menu item.
3. **Set hook** registers observation before player code and reloads the tab.
4. After reload, chat, caption, and LIVE events appear when TikTok supplies them.

**Refresh** clears only the extension's volatile state for the current tab, re-enables the hook, and reloads TikTok without page cache. Cookies and login remain intact.

## iOS 15 or newer

1. Extract `tiktok-live-companion-ios-0.7.0-source.zip` on macOS and open `TikTokLiveCompanion.xcodeproj` in Xcode.
2. Select an Apple Developer team and an App ID with the ShazamKit capability enabled.
3. Build on a physical device and grant microphone access only when recognition starts.

Windows cannot produce or sign a verified iOS/IPA build.

## Android and HyperOS

1. Extract `tiktok-live-companion-android-0.7.0-source.zip`.
2. Build `mockDebug` for UI and bridge testing. It deliberately reports **ShazamKit not configured**.
3. For real recognition, provide Apple's AAR as `app/libs/shazamkit-android-release.aar` and set `TLC_SHAZAM_TOKEN_URL` to the configured HTTPS token endpoint.
4. Build `shazamDebug` and grant microphone permission only when manual recognition starts.
