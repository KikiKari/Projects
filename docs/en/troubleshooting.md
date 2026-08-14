# Troubleshooting

## No CaptionMessages

Run **Inspect page** first. `caption_info` and a visible menu item indicate availability only; received CaptionMessages confirm events during the observation window. Set the hook before player connection and reload the tab.

## Hook remains disconnected

Use **Refresh** in the hook area. The current LIVE stream receives a new tab-scoped browser-session ID and opens in a new tab/document context with the hook enabled; the previous tab is then closed. Only if replacement is unavailable does the same tab reload without cache with a new session ID. Cookies, login, and other TikTok tabs remain unchanged.

## Player action rejected

Picture-in-picture and fullscreen may require immediate user activation. Web Audio may be unavailable for a media configuration; the extension reports the failure and does not claim active peak protection.

## No VLC links

A stream may expose only HLS, only FLV, or no extractable URL. **Automatic** is not a concrete stream URL. Run **Inspect page** after the player loads.

## Diagnostic export

Enable debug mode only for troubleshooting. The export contains no chat text and removes signed URL parameter values.
