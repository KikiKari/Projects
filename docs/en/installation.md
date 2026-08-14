# Installation

## Requirements

- Microsoft Edge or Google Chrome 114 or newer
- a public TikTok LIVE tab
- the unpacked `tiktok-live-companion-extension-0.7.1.zip`

## Steps

1. Extract the ZIP file.
2. Open `edge://extensions` or `chrome://extensions`.
3. Enable **Developer mode**.
4. Select **Load unpacked**.
5. Choose the folder containing `manifest.json`.
6. Open a public TikTok LIVE tab and click the extension icon.

## Optional local speech and song service

1. Select **Sprachdienst starten**. If one-time setup is still required, the side panel shows only **Installation abschließen!**; it does not display commands or the extension ID.
2. **Installation abschließen!** opens PowerShell in the actual service directory, runs setup with the correct extension ID, and starts the service automatically.
3. The locally generated pairing code is inserted into the side panel automatically. The installation button disappears after a successful health check.
4. Later starts use `tiktok-live-companion://start`; a short-lived nonce protects pairing transfer.
5. The service listens only on `127.0.0.1:43117`.

If the side panel reports that the local service is outdated, stop the process from the older extracted package, load the current unpacked extension, and select **Installation abschließen!** again. No additional manual start is required; an already running service is detected instead of launching a second process.

The pairing code is stored in `%LOCALAPPDATA%\TikTokLiveCompanion\service.json` and normally stays unchanged. It changes only if that file is deleted or recreated.

The **AudD API-Token** field stores the AudD key persistently in the same local configuration. Sherpa-ONNX voices are installed automatically by the current 0.7.1 service or through **Sherpa installieren**.

## First run

1. **Inspect page** reads caption metadata, visible controls, and stream information.
2. **Enable captions** activates only a clearly identified TikTok menu item.
3. **Set hook** enables observation only for the current tab before player code and reloads that tab.
4. After reload, chat, caption, and LIVE events appear when TikTok supplies them.

**Refresh** creates a new tab-scoped browser-session ID, opens the current LIVE stream in a new tab/document context, enables the hook there, and then closes the previous tab. If the tab cannot be replaced, it still receives a new session ID and reloads without page cache. Cookies, login, and other TikTok tabs remain unchanged.

**Play/Pause** remains available when TikTok's video element is temporarily missing or disabled. The extension retries TikTok's own player control.

## iOS 15 or newer

1. Extract `tiktok-live-companion-ios-0.7.1-source.zip` on macOS and open `TikTokLiveCompanion.xcodeproj` in Xcode.
2. Select an Apple Developer team and an App ID with the ShazamKit capability enabled.
3. Build on a physical device and grant microphone access only when recognition starts.

Windows cannot produce or sign a verified iOS/IPA build.

## Android and HyperOS

1. Extract `tiktok-live-companion-android-0.7.1-source.zip`.
2. Build `mockDebug` for UI and bridge testing. It deliberately reports **ShazamKit not configured**.
3. For real recognition, provide Apple's AAR as `app/libs/shazamkit-android-release.aar` and set `TLC_SHAZAM_TOKEN_URL` to the configured HTTPS token endpoint.
4. Build `shazamDebug` and grant microphone permission only when manual recognition starts.
