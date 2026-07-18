# Overview

TikTok LIVE Companion 0.7.0 is a local browser extension for public TikTok LIVE streams. Its side panel combines sanitized chat, natural speech, top chatters, observed participants, gift counts, native-caption checks, LIVE information, optional manual song recognition, player controls, digital peak protection, quality variants, and FLV/HLS links.

Version 0.7.0 also includes native source projects for iOS 15+ and Android/HyperOS API 21+. They reproduce companion functions in a restricted TikTok WebView and use ShazamKit only for explicitly initiated song recognition. The browser continues to use AudD.

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

The extension reads no cookies and requires no TikTok account. The optional AudD workflow needs a token stored only by the local service and transfers audio solely after a manual recognition click.

The mobile apps likewise never read cookies or Web Storage. Functions rejected by TikTok or the platform remain visible with an explicit availability state rather than a false success indication.
