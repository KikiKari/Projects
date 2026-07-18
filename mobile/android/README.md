# TikTok LIVE Companion Android/HyperOS 0.7.0

Native Kotlin/Compose companion with an origin-restricted AndroidX WebKit bridge. It uses no Google Play Services and targets standard Android APIs, so the same APK is suitable for Android and HyperOS.

## Build variants

- `mockDebug`: reproducible UI/bridge test build that reports **ShazamKit nicht konfiguriert** and requires no proprietary SDK.
- `shazamDebug`: real ShazamKit build. Download Apple's Android 2.1.1 AAR and place it at `app/libs/shazamkit-android-release.aar` before building.

Set `TLC_SHAZAM_TOKEN_URL` as a Gradle property or environment variable to the deployed HTTPS `/api/shazam-token` endpoint. No Apple private key belongs in the app.

```powershell
.\gradlew.bat testMockDebugUnitTest assembleMockDebug
```

The packaging script renames the verified mock debug output to `tiktok-live-companion-android-0.7.0-debug.apk`. A real catalog build additionally requires the official AAR and configured token service.
