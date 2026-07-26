# Downloads und Release 0.7.1

## Artefakte

- `tiktok-live-companion-extension-0.7.1.zip` – entpackbare Edge-/Chrome-Erweiterung
- `tiktok-live-companion-plugin-0.7.1.zip` – Codex-Plugin einschließlich Skill, Referenzen und Tests
- `tiktok-live-companion-service-0.7.1.zip` – optionaler lokaler Windows-Dienst
- `tiktok-live-companion-ios-0.7.1-source.zip` – vollständiges SwiftUI-/Xcode-Quellprojekt
- `tiktok-live-companion-android-0.7.1-source.zip` – Kotlin-/Compose-Quellprojekt für Android und HyperOS
- `tiktok-live-companion-0.7.1-SHA256.txt` – Integritätswerte

## SHA-256

```text
db0d00b390af95a1829adb1904e3ea371a68905513822478e733cf42c376b58b  tiktok-live-companion-extension-0.7.1.zip
3b7d4265405a66efc333ecda3911f59f889faf7135557b3bf0094d9804c5360b  tiktok-live-companion-plugin-0.7.1.zip
78b23fd4808738daee6bddb2ea2015b5761530c1ebf7db3c1e85692ccc5d535c  tiktok-live-companion-service-0.7.1.zip
2d9b6b1b189bc9680c2538d48274867ba6d487557b23979724640961f9406ede  tiktok-live-companion-ios-0.7.1-source.zip
8739c76e681f900923b900c9df0ef75cf421d39cabb54650c4b9ad19b6a76d85  tiktok-live-companion-android-0.7.1-source.zip
```

## Änderungen in 0.7.1

Version 0.7.1 ergänzt native Apps für iOS und Android/HyperOS, eine origin-beschränkte WebView-Bridge sowie einen kurzlebigen ShazamKit-Token-Endpunkt. Die Browser-Erweiterung behält die manuelle AudD-Songerkennung; mobile Apps verwenden ShazamKit mit Mikrofon als stabilem Weg und WebView-PCM als experimentellem Weg.

AudD erhält im Browser nur nach einem ausdrücklichen Klick einen ungefähr zwölfsekündigen Audioausschnitt. Mobil beginnt ebenfalls keine Erkennung ohne Klick. Das proprietäre ShazamKit-AAR, Apple-Schlüssel und Signierzertifikate sind nicht Bestandteil der Archive.
