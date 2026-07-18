# Downloads und Release 0.7.0

## Artefakte

- `tiktok-live-companion-extension-0.7.0.zip` – entpackbare Edge-/Chrome-Erweiterung
- `tiktok-live-companion-plugin-0.7.0.zip` – Codex-Plugin einschließlich Skill, Referenzen und Tests
- `tiktok-live-companion-service-0.7.0.zip` – optionaler lokaler Windows-Dienst
- `tiktok-live-companion-ios-0.7.0-source.zip` – vollständiges SwiftUI-/Xcode-Quellprojekt
- `tiktok-live-companion-android-0.7.0-source.zip` – Kotlin-/Compose-Quellprojekt für Android und HyperOS
- `tiktok-live-companion-android-0.7.0-debug.apk` – optionales Testpaket, wenn die Android-Toolchain verfügbar war
- `tiktok-live-companion-0.7.0-SHA256.txt` – Integritätswerte

## SHA-256

```text
40721b800a0f1aa4580ebabaa13ad82d10426ce0287eb1559749385f5850dfce  tiktok-live-companion-extension-0.7.0.zip
c8696754cc06453ad26237cb0d1d641ddeb19b7c21df7df3b06c7ac0b55f457c  tiktok-live-companion-plugin-0.7.0.zip
617c63288976c8507d2e5cd6cfaf9eb5767f43b4c901e703f29d3aff58aa6c56  tiktok-live-companion-service-0.7.0.zip
```

## Änderungen in 0.7.0

Version 0.7.0 ergänzt native Apps für iOS und Android/HyperOS, eine origin-beschränkte WebView-Bridge sowie einen kurzlebigen ShazamKit-Token-Endpunkt. Die Browser-Erweiterung behält die manuelle AudD-Songerkennung; mobile Apps verwenden ShazamKit mit Mikrofon als stabilem Weg und WebView-PCM als experimentellem Weg.

AudD erhält im Browser nur nach einem ausdrücklichen Klick einen ungefähr zwölfsekündigen Audioausschnitt. Mobil beginnt ebenfalls keine Erkennung ohne Klick. Das proprietäre ShazamKit-AAR, Apple-Schlüssel und Signierzertifikate sind nicht Bestandteil der Archive.
