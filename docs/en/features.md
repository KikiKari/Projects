# Features

## Chat and speech

Public chat messages are sanitized and rendered as accessible text. Emoji sequences are removed from the compact view. Optional speech remains local to the browser and is off by default.

## Captions

The UI separates three signals: a caption feature announced by `caption_info`, a detected menu item, and actual `WebcastCaptionMessage` events. No events does not prove nobody spoke.

## LIVE information

The hook observes `WebcastRoomUserSeqMessage`, `WebcastLikeMessage`, and `WebcastSocialMessage`. Follows since hook is a local event counter; host follower count is a separate total.

## Player and peak protection

Play/pause, reload, volume, mute, picture-in-picture, and fullscreen operate TikTok's existing player. The optional compressor limits digital peaks locally. dBFS is not a calibrated dB SPL value.

## Quality and VLC

Quality variants come from TikTok stream metadata. **Automatic** is a player mode and has no VLC link. Signed FLV/HLS links can expire and remain sensitive until then.

## Diagnostics

The optional debug mode exports sanitized events. Signed URL parameter values, chat contents, cookies, and API keys are excluded.
