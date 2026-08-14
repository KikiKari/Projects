# Mobile WebView bridge 0.7.0

`webview-bridge.js` is injected only into the main frame of `https://www.tiktok.com` after `content-core.js` and `proto-main.js`. It exposes a narrow event envelope and an allowlisted command function. It never reads cookies, credentials, local storage, or session storage.

## Event envelope

```json
{"version":1,"type":"bridge-ready","streamId":"","sequence":1,"timestamp":"2026-07-18T12:00:00.000Z","payload":{}}
```

Native clients reject messages above 64 KiB, unknown types, non-main-frame senders, and origins other than `https://www.tiktok.com`.

## Audio

`start-webview-audio` is experimental and can run only after a native user action. It emits bounded mono PCM16 chunks for at most twelve seconds. If Web Audio, cross-origin media, or the WebView blocks capture, the bridge emits `capability` with `available: false`; native clients offer microphone recognition instead.
