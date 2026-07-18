# Features

## Chat and speech

Public chat messages are sanitized and rendered as accessible text. Emoji sequences and confidently detected per-stream team tags are removed from speech. `@` recipients and questions receive natural phrasing. Spoken nicknames omit punctuation and digits; technical `user…` names are limited to `user` plus at most three digits. Optional suitable-name shortening also detects clear main parts such as `Traumtänzer`, `Vanny`, `Löwin`, or `Maskenaufsicht`, and the same rules apply to `@` recipients. Excessive laughter runs are spoken as a short `haha`. Language, author names, and suitable nickname shortening are configurable. The optional local Windows service enables gain above the browser ceiling; browser speech remains the fallback.

## Top chatters and observed people

Per stream, the extension counts messages, words, and gift events for up to 5,000 people observed in chat. Stream mutes reset with the stream; permanent mutes remain local. This is not a complete TikTok viewer list.

## Song recognition

After explicit activation and a click, the extension records about twelve seconds of tab audio. The local service sends only that sample to AudD; no recording or transfer occurs without the click.

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

## Profile Force

Normal refresh remains non-disruptive. `Force` deliberately opens the profile page briefly, imports its public values, and then restores the LIVE URL.
