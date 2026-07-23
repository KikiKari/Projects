# Downloads and release 0.7.2

## Browser core package

- `tiktok-live-companion-extension-0.7.2.zip` – unpacked Edge/Chrome extension
- `tiktok-live-companion-plugin-0.7.2.zip` – Codex plugin with browser, service, and installer sources
- `tiktok-live-companion-service-0.7.2.zip` – manual local Windows service
- `tiktok-live-companion-setup-0.7.2-unsigned-dev.exe` – per-user Windows installer with a pinned Node runtime and Chrome/Edge Native Messaging; not code-signed
- `tiktok-live-companion-0.7.2-SHA256.txt` – integrity values

Android and iOS remain unchanged at 0.7.0 and are not part of this browser core package.

## SHA-256

```text
6c35fc60ff8842479a8fe5e2eb165f69cb97ae6e54753816f89b78abc64f66ea  tiktok-live-companion-extension-0.7.2.zip
398dfd9b03962171f31409c611eff5d7cd2a9d99f49cb0255fc05aa0fbfe906e  tiktok-live-companion-plugin-0.7.2.zip
c474066ec55cf539df1d8457c45118d1841a2b5f5fbc886cccb74dc339155aaf  tiktok-live-companion-service-0.7.2.zip
3d1f96d856c65e8bf3dd5cce4224a54e7c5fbfcf3468826766d5321c78ab6c0c  tiktok-live-companion-setup-0.7.2-unsigned-dev.exe
```

## What's new

0.7.2 removes the quality box and six explanatory texts, stabilizes native captions through DOM coalescing and WebSocket precedence, displays volume and peak protection as 0–100, and replaces side-panel capture with a background broker. Native Messaging automates internal service authentication and keeps the AudD token out of extension storage, logs, and debug exports.
