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

1. Select **Sprachdienst installieren** in the side panel and copy its generated one-time setup command. It has the form `npm run setup -- -ExtensionId <extension-id>`; the root script delegates to `companion-service`.
2. Setup binds the local configuration to that extension ID, registers the local start action, installs the German and English default voices, and finally runs `npm start` in the background.
3. Later button presses start the configured service through `tiktok-live-companion://start`; a short-lived local nonce transfers the existing pairing code automatically.
4. No separate installer or Native Messaging host is used.
5. The service listens only on `127.0.0.1:43117`.

If the side panel reports that the local service is outdated, an older extracted package is still running on `127.0.0.1:43117`. Press `Ctrl+C` in the old PowerShell window, then start the current service:

```powershell
cd "C:\Users\silve\Downloads\tiktok-live-companion-extension-0.7.1\companion-service"
npm run setup -- -ExtensionId <extension-id-from-side-panel>
npm start
```

Alternatively, run the same commands from the extracted package root:

```powershell
cd "C:\Users\silve\Downloads\tiktok-live-companion-extension-0.7.1"
npm run setup -- -ExtensionId <extension-id-from-side-panel>
npm start
```

The pairing code is stored in `%LOCALAPPDATA%\TikTokLiveCompanion\service.json` and normally stays unchanged. It changes only if that file is deleted or recreated. The PowerShell running `npm start` must remain active unless the registered protocol starter has launched the service in the background.

The **AudD API-Token** field stores the AudD key persistently in the same local configuration. Sherpa-ONNX voices are installed automatically by the current 0.7.1 service or through **Sherpa installieren**. If automatic installation is blocked:

```powershell
cd "C:\Users\silve\Downloads\tiktok-live-companion-extension-0.7.1\companion-service"
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-sherpa.ps1
npm run setup -- -ExtensionId <extension-id-from-side-panel>
npm start
```

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
