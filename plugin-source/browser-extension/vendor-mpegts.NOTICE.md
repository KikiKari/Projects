# mpegts.js vendor notice

- Upstream: https://github.com/xqq/mpegts.js
- Version: 1.8.1
- License: Apache-2.0 (see `vendor-mpegts.LICENSE.txt`)
- Purpose: HTTP-FLV live-stream transmuxing into Media Source Extensions for the in-page media fallback.
- Worker mode: disabled by the extension integration.
- MV3 compatibility adjustment: the two UMD global-object fallbacks based on `Function(...)` were replaced with `globalThis`; no decoding or transmuxing logic was changed.
- Bundled file SHA-256: `0786F9AF6780822FF29240259A73B07ED7BC479BC44966E49418DD38213B8064`
