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
6e034b02dcdae010a0aec6e0fc42116363ca0eb13ee5caa7791093494a8c7790  tiktok-live-companion-plugin-0.7.1.zip
78b23fd4808738daee6bddb2ea2015b5761530c1ebf7db3c1e85692ccc5d535c  tiktok-live-companion-service-0.7.1.zip
8739c76e681f900923b900c9df0ef75cf421d39cabb54650c4b9ad19b6a76d85  tiktok-live-companion-ios-0.7.1-source.zip
da52da289023ed08287f21845921f1416fcd5b062d98f431479023c77d2c42ce  tiktok-live-companion-android-0.7.1-source.zip
```

## Änderungen in 0.7.1

Version 0.7.1 ergänzt native Apps für iOS und Android/HyperOS, eine origin-beschränkte WebView-Bridge sowie einen kurzlebigen ShazamKit-Token-Endpunkt. Die Browser-Erweiterung behält die manuelle AudD-Songerkennung; mobile Apps verwenden ShazamKit mit Mikrofon als stabilem Weg und WebView-PCM als experimentellem Weg.

AudD erhält im Browser nur nach einem ausdrücklichen Klick einen ungefähr zwölfsekündigen Audioausschnitt. Mobil beginnt ebenfalls keine Erkennung ohne Klick. Das proprietäre ShazamKit-AAR, Apple-Schlüssel und Signierzertifikate sind nicht Bestandteil der Archive.
