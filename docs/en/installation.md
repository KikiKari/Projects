# Installation

## Requirements

- Microsoft Edge or Google Chrome 114 or newer
- a public TikTok LIVE tab
- the unpacked `tiktok-live-companion-extension-0.5.0.zip`

## Steps

1. Extract the ZIP file.
2. Open `edge://extensions` or `chrome://extensions`.
3. Enable **Developer mode**.
4. Select **Load unpacked**.
5. Choose the folder containing `manifest.json`.
6. Open a public TikTok LIVE tab and click the extension icon.

## First run

1. **Inspect page** reads caption metadata, visible controls, and stream information.
2. **Enable captions** activates only a clearly identified TikTok menu item.
3. **Set hook** registers observation before player code and reloads the tab.
4. After reload, chat, caption, and LIVE events appear when TikTok supplies them.

**Refresh** clears only the extension's volatile state for the current tab, re-enables the hook, and reloads TikTok without page cache. Cookies and login remain intact.
