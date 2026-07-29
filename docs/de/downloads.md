# Downloads und Release 0.7.1

## Artefakte

- `tiktok-live-companion-extension-0.7.1.zip` – entpackbare Edge-/Chrome-Erweiterung
- `tiktok-live-companion-plugin-0.7.1.zip` – Codex-Plugin einschließlich Skill, Referenzen und Tests
- `tiktok-live-companion-service-0.7.1.zip` – optionaler lokaler Windows-Dienst
- `tiktok-live-companion-ios-0.7.1-source.zip` – vollständiges SwiftUI-/Xcode-Quellprojekt
- `tiktok-live-companion-android-0.7.1-source.zip` – Kotlin-/Compose-Quellprojekt für Android und HyperOS
- `tiktok-live-companion-android-0.7.1.apk` – optionales Testpaket, wenn die Android-Toolchain verfügbar war
- `tiktok-live-companion-0.7.1-SHA256.txt` – Integritätswerte

## Änderungen

Die Browser-Erweiterung 0.7.1 startet den bereits eingerichteten Sprachdienst über den lokalen Starter erneut im Hintergrund, zeigt Sherpa nach erfolgreicher Einrichtung als aktiv, filtert exakt wiederholte technische TTS-Dubletten und dämpft den Pegelschutz bei hoher Schutzstärke früher und stärker. Die bestehende Browser-VLC-Link-Liste bleibt unverändert.

Die Mobile-Quellarchive 0.7.1 gleichen Chat/Game-Mode, TTS-Dedupe, Pegelschutz, Auto-Reconnect mit 400-ms-Mindestabstand, Refresh mit App-/WebView-Cache-Leerung ohne Cookie-Löschung und VLC-kompatiblere HLS-/FLV-/MP4-Kandidaten an den Browserstand an.
