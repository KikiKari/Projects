# Overview

TikTok LIVE Companion 0.5.0 is a local browser extension for public TikTok LIVE streams. Its side panel combines accessible chat text, local speech, native-caption checks, LIVE information, player controls, digital peak protection, quality variants, and FLV/HLS links.

## What it does

- displays the five latest sanitized public chat lines and keeps at most 50 session records per tab;
- speaks only new chat lines locally through the Web Speech API;
- distinguishes `caption_info`, a visible caption control, and received CaptionMessages;
- reads viewers, total views, likes, follows, and shares from observed LIVE events;
- operates TikTok's existing player without ever submitting a report;
- detects stream variants, codecs, resolution, bitrate, and temporary FLV/HLS URLs;
- exports captions as JSONL and sanitized diagnostics as JSON.

## Limits

The extension does not generate captions. If TikTok emits no native caption events, it cannot force them. WebSocket bridge data is an observational record, not cryptographically authenticated evidence. The meter reports dBFS; it cannot guarantee a physical dB SPL value at the ear without calibrated output hardware.

The extension reads no cookies, requires no account, and uses no API key.
