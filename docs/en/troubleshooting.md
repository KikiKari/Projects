# Troubleshooting

## No CaptionMessages

Run **Inspect page** first. `caption_info` and a visible menu item indicate availability only; received CaptionMessages confirm events during the observation window. Set the hook before player connection and reload the tab.

## Hook remains disconnected

Use **Refresh** in the hook area. This clears only volatile tab state, registers the hook again, and reloads without cache. Auto-hook can keep registration across browser restarts.

## Player action rejected

Picture-in-picture and fullscreen may require immediate user activation. Web Audio may be unavailable for a media configuration; the extension reports the failure and does not claim active peak protection.

## No VLC links

A stream may expose only HLS, only FLV, or no extractable URL. **Automatic** is not a concrete stream URL. Run **Inspect page** after the player loads.

## Diagnostic export

Enable debug mode only for troubleshooting. The export contains no chat text and removes signed URL parameter values.
