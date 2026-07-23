# Links und Erreichbarkeiten v0.7.0

**Version:** 0.7.0 · **Status:** veröffentlicht · **Stand:** 18. Juli 2026
**Projektwurzel:** `C:\Users\silve\Documents\Codex\TikTok-Live-Companion`
**Kanonische Quelle:** GitHub · alle anderen Systeme spiegeln den freigegebenen Stand.

### Status-Legende

| Symbol | Bedeutung |
|---|---|
| ✅ | verifiziert am 18.07.2026 |
| 🔗 | aus dem Sitzungsverlauf übernommen |
| ⚠️ | offen oder klärungsbedürftig |
| 🔒 | lokal, nicht öffentlich erreichbar |

---

## 1. Veröffentlichte Branches ✅

| Branch | Adresse | Visualisierungscommit |
|---|---|---|
| `TikTok-Live-Companion` | https://github.com/KikiKari/Projects/tree/TikTok-Live-Companion | `18ef6cf` |
| `TikTok-Live-Companion-iOS` | https://github.com/KikiKari/Projects/tree/TikTok-Live-Companion-iOS | `9ac0a20` |
| `TikTok-Live-Companion-Android` | https://github.com/KikiKari/Projects/tree/TikTok-Live-Companion-Android | `9434e8c` |

Die angegebenen Visualisierungscommits wurden nach dem Push per `git ls-remote` verifiziert und sind in den aktuellen Branchspitzen enthalten.

Der iOS-Branch enthält kein `mobile/android`, der Android-Branch kein `mobile/ios`. Der gemeinsame Branch enthält beide.

---

## 2. Öffentliche Projektziele

| System | Adresse | Status |
|---|---|---|
| GitHub-Repository | https://github.com/KikiKari/Projects | ✅ öffentlich |
| GitHub-Issues offen | https://github.com/KikiKari/Projects/issues | 🔗 |
| GitHub-Issues geschlossen | https://github.com/KikiKari/Projects/issues?q=is%3Aissue+state%3Aclosed | 🔗 |
| Dokumentationssite Deutsch | https://tiktok-live-companion.vercel.app/de | ✅ live |
| Dokumentationssite English | https://tiktok-live-companion.vercel.app/en | ✅ live |
| Interaktive Architektur Deutsch | https://tiktok-live-companion.vercel.app/de/architecture-3d | ✅ live |
| Interaktive Architektur English | https://tiktok-live-companion.vercel.app/en/architecture-3d | ✅ live |
| Architektur-SVG | https://tiktok-live-companion.vercel.app/visualizations/tiktok-live-companion-architecture.svg | ✅ live |
| Architektur-GIF | https://tiktok-live-companion.vercel.app/visualizations/tiktok-live-companion-architecture.gif | ✅ live |
| Linear-Projekt | https://linear.app/0penclaw/project/tiktok-live-companion-ed2f087b24bc | 🔗 |
| Linear-Team 0PE | https://linear.app/0penclaw/team/0PE/active | 🔗 |
| Notion-Projektseite | https://app.notion.com/p/3a18d8ad3db9817f882bd79682fbbc51 | ⚠️ steht auf 0.6.0 |
| Canva-Ordner | https://www.canva.com/folder/FAHPt7Wvb8E | ⚠️ leer, keine Brand Kits |

**Hinweis:** Linear und Notion wurden zuletzt auf den 0.6.0-Kandidaten aktualisiert. Eine Fortschreibung auf den veröffentlichten 0.7.0-Stand steht aus.

---

## 3. Notion-Unterseiten

| Seite | Adresse |
|---|---|
| Überblick / Overview | https://app.notion.com/p/3a18d8ad3db981518b57c1618b2bb827 |
| Installation | https://app.notion.com/p/3a18d8ad3db981e09199f940be4f0f42 |
| Funktionen / Features | https://app.notion.com/p/3a18d8ad3db9818f990ff6e8ddaca655 |
| Architektur / Architecture | https://app.notion.com/p/3a18d8ad3db981fcbe4cdea7c1805049 |
| Sicherheit & Datenschutz | https://app.notion.com/p/3a18d8ad3db981df92cee9f0892234b4 |
| Fehlerbehebung / Troubleshooting | https://app.notion.com/p/3a18d8ad3db9817888d9d6c4188c98e8 |
| Downloads & Release Notes | https://app.notion.com/p/3a18d8ad3db981cba6a7e2590656ba94 |

Übergeordnete Seite: `Onboarding and Project Pages` (`3878d8ad-3db9-8116-a5d4-f68d8c8ad717`)

---

## 4. Aktive Issues

| ID | Thema | Adresse | Fundstelle |
|---|---|---|---|
| 0PE-41 | Low/P3 – Bridge-Payloads byte-begrenzen | https://linear.app/0penclaw/issue/0PE-41/lowp3-bridge-payloads-byte-begrenzen | `content.js:696-708` |
| 0PE-43 | Low/P3 – gzip-Ausgabe und Decode-Parallelität begrenzen | https://linear.app/0penclaw/issue/0PE-43/lowp3-gzip-ausgabe-und-decode-parallelitat-begrenzen | `proto-main.js:208-227` |

Beide sind dem Meilenstein `Security & Release Gate` zugeordnet, Priorität Low, Status Backlog. Die GitHub-Dubletten #1 und #2 wurden geschlossen, nicht gelöscht.

### Linear-Meilensteine

| Meilenstein | Fortschritt |
|---|---|
| Security & Release Gate | 33 % |
| Dokumentation & Website | 100 % |
| Veröffentlichung & Integrationen | 58 % |

---

## 5. Dienst-Erreichbarkeiten

### Lokaler Companion-Service 🔒

| Endpunkt | Zweck |
|---|---|
| `http://127.0.0.1:43117` | Basisadresse |
| `GET /v1/health` | Statusprüfung |
| `POST /v1/tts` | Text → `audio/wav` |
| `POST /v1/recognize` | Audioausschnitt → Songdaten |

Bindet ausschließlich an Loopback. Die Erweiterung akzeptiert nur `127.0.0.1` oder `localhost`. Native Messaging übernimmt die interne Authentifizierung; ein Pairing-Code wird nicht angezeigt oder eingegeben.

### Shazam-Token-Endpunkt ✅

| Feld | Wert |
|---|---|
| Adresse | `POST https://tiktok-live-companion.vercel.app/api/shazam-token` |
| Implementierung | `site/api/shazam-token.mjs` |
| Antwort | `{ "token": "...", "expiresAt": "ISO-8601" }` |
| Fehlercodes | `not_configured`, `rate_limited`, `signing_failed` |
| Signatur | ES256, kurzlebig |

Die SPA-Rewrite-Regel fängt `/api` nicht ab. Apple-Schlüsselmaterial liegt ausschließlich in Vercel-Umgebungsvariablen.

### Konfigurationsablage

| Inhalt | Ort |
|---|---|
| Dienstadresse, Native-Host-Version, AudD-Konfigurationsstatus | `chrome.storage.local` |
| AudD-Token | Dienstkonfiguration unter `%LOCALAPPDATA%` |
| Stream-, Chat-, Caption-, Teilnehmerdaten | `chrome.storage.session` (flüchtig, pro Tab) |
| Einstellungen, dauerhafte Mutes (Browser) | `chrome.storage.local` |
| Erkennungsquelle, dauerhafte Mutes (iOS) | UserDefaults |
| Erkennungsquelle, dauerhafte Mutes (Android) | DataStore |
| Apple Team-ID, Key-ID, Media-ID, privater Schlüssel | ausschließlich Vercel-Umgebungsvariablen |
| ShazamKit-AAR | `mobile/android/app/libs/`, nicht eingecheckt |

---

## 6. Repository-Struktur ✅

Basis: `tiktok-live-companion-project/`

| Pfad | Inhalt |
|---|---|
| `README.md` | Projektüberblick, Schnellstart, Verifikationsbefehle |
| `plugin-source/browser-extension/` | kanonische Erweiterungsquellen |
| `plugin-source/companion-service/` | lokaler Windows-Dienst |
| `plugin-source/mobile-shared/` | gemeinsame WebView-Bridge und Ergebnisschema |
| `plugin-source/scripts/` | Test- und Packaging-Skripte |
| `plugin-source/tests/` | Sidepanel-Harness |
| `plugin-source/skills/` | Codex-Skillbeschreibung |
| `plugin-source/references/architecture.md` | technische Architekturreferenz |
| `plugin-source/SECURITY.md` | Sicherheitsbeschreibung |
| `mobile/ios/` | SwiftUI-App, Xcode-Projekt, XCTest |
| `mobile/android/` | Compose-App, Gradle-Projekt, JUnit/Robolectric |
| `docs/de/`, `docs/en/` | zweisprachige Dokumentation, je sieben Kapitel |
| `docs/diagrams/architecture.mmd` | Mermaid-Quelle |
| `docs/diagrams/tiktok-live-companion-architecture.svg` | reproduzierbares statisches Architekturvisual |
| `docs/diagrams/tiktok-live-companion-architecture.gif` | reproduzierbares rotierendes 36-Frame-Visual |
| `docs/diagrams/tiktok-live-companion-visualization-contract.md` | verbindlicher Visualisierungsvertrag und Textalternative |
| `docs/mobile/mobile-0.7.0-concept.png` | freigegebener Mobile-Entwurf |
| `assets/flow_model.py` | gemeinsames Modell für SVG, GIF und Three.js |
| `site/public/visualizations/` | öffentlich ausgeliefertes Modell sowie SVG-/GIF-Fallbacks |
| `release/0.7.0/` | aktuelle Artefakte und Prüfsummen |
| `release/0.6.0/`, `release/` | frühere Artefakte |
| `security-scan/` | Threat Models, Findings, Release-Reviews |
| `site/` | React-/TypeScript-/Vite-Dokumentationssite |
| `site/api/` | Vercel-Funktionen |

### Test- und Packaging-Skripte

| Datei | Zweck |
|---|---|
| `plugin-source/scripts/test_extension.cjs` | Extension-Struktur und Decoder |
| `plugin-source/scripts/test_mobile_bridge.cjs` | Bridge-Schema und Grenzen |
| `plugin-source/scripts/test_mobile_projects.py` | native Projektprüfung |
| `plugin-source/scripts/package_artifacts.py` | Release-Paketierung |
| `site/api/shazam-token.test.mjs` | Token-Dienst |
| `assets/test_visualizations.py` | Modell-, SVG-, GIF-, Public-Copy- und Mobile-Bild-Prüfung |

### Dokumentationskapitel

| Kapitel | Deutsch | English |
|---|---|---|
| Überblick | `docs/de/overview.md` | `docs/en/overview.md` |
| Installation | `docs/de/installation.md` | `docs/en/installation.md` |
| Funktionen | `docs/de/features.md` | `docs/en/features.md` |
| Architektur | `docs/de/architecture.md` | `docs/en/architecture.md` |
| Sicherheit & Datenschutz | `docs/de/security.md` | `docs/en/security.md` |
| Fehlerbehebung | `docs/de/troubleshooting.md` | `docs/en/troubleshooting.md` |
| Downloads & Release Notes | `docs/de/downloads.md` | `docs/en/downloads.md` |

---

## 7. Release-Artefakte und Prüfsummen

### 0.7.0 ✅ · `release/0.7.0/`

| Artefakt | SHA-256 |
|---|---|
| `tiktok-live-companion-extension-0.7.0.zip` | `a3c818eb63179ad1c0d5896c5bac8263bab0c6732c8621cbcafbd847d5a50b42` |
| `tiktok-live-companion-plugin-0.7.0.zip` | `4644ebf46bbd363edd499a16afc49b9ac7fa2c5cf03a1bae5149614ccbefb3b9` |
| `tiktok-live-companion-service-0.7.0.zip` | `4bb5df40229c72a0e93ab822709182542d31846cc865f89962da3769e652fd1c` |
| `tiktok-live-companion-ios-0.7.0-source.zip` | `3b833ea2969487ea9a82571478a4f273f3e678cffb6a11bde51e94ee0e5bbff3` |
| `tiktok-live-companion-android-0.7.0-source.zip` | `62e57e5d901ffb581fc40dc8a47454fb7e46531c57ffdbd71b82b071f76ad594` |
| `tiktok-live-companion-android-0.7.0-debug.apk` | `00f8df107107661c5bb6204f0fedb9d1f485fdbe5085f19f27e0f8089481d0f5` |

Alle sechs Werte am 18.07.2026 gegen die tatsächlichen Dateien verifiziert. Prüfsummendatei: `release/0.7.0/tiktok-live-companion-0.7.0-SHA256.txt`

Die Archive wurden automatisiert darauf geprüft, dass sie weder ShazamKit-AAR noch `.p8`-Schlüssel noch Build-Caches enthalten.

**Kein IPA** — unter Windows ist weder ein Xcode-Build noch eine Apple-Signierung möglich.

### 0.6.0 · `release/0.6.0/`

| Artefakt | SHA-256 |
|---|---|
| `tiktok-live-companion-extension-0.6.0.zip` | `40721b800a0f1aa4580ebabaa13ad82d10426ce0287eb1559749385f5850dfce` |
| `tiktok-live-companion-plugin-0.6.0.zip` | `c8696754cc06453ad26237cb0d1d641ddeb19b7c21df7df3b06c7ac0b55f457c` |
| `tiktok-live-companion-service-0.6.0.zip` | `617c63288976c8507d2e5cd6cfaf9eb5767f43b4c901e703f29d3aff58aa6c56` |

### 0.5.0 · `release/`

| Artefakt | SHA-256 |
|---|---|
| `tiktok-live-companion-extension-0.5.0.zip` | `9439e21db0e8fc2e874a478079d1243297d4c95e0dbb140795912f75eb250b02` |
| `tiktok-live-companion-plugin-0.5.0.zip` | `a99fdfb14cd0effac4f89468758258e073dc75ed0f59763bc9764c4c380088a0` |

### Downloadkopien der Website

`site/public/downloads/` enthält die 0.5.0-, 0.6.0- und 0.7.0-Artefakte einschließlich APK und aller Prüfsummendateien.

---

## 8. Security

### Bisheriger formaler Scan

9/9 Prüfbereiche · 0 Critical, 0 High, 0 Medium, 2 Low/P3 · Datum 17.07.2026 · **Bezug: Version 0.5.0** · 5 Artefaktdateien.

### Artefakte ✅

| Datei | Inhalt |
|---|---|
| `security-scan/final/report.md` | Abschlussbericht 0.5.0 |
| `security-scan/final/findings.json` | zwei validierte Findings |
| `security-scan/final/results.sarif` | SARIF-Export |
| `security-scan/final/coverage.json` | Abdeckung |
| `security-scan/final/scan-manifest.json` | Scan-Manifest |
| `security-scan/threat_model.md` | Threat Model Browser |
| `security-scan/threat_model_0.7.0.md` | Threat Model 0.7.0 (WebView, Token, Audio) |
| `security-scan/release-review-0.7.0.md` | Release-Review 0.7.0 |

### Offen ⚠️

Ein vollständiger formaler Codex-Security-Scan für 0.7.0 steht aus. Neu hinzugekommene Angriffsflächen: WebView-Bridges auf iOS und Android, der Token-Endpunkt `/api/shazam-token`, der mobile Audiofluss und der Umgang mit signierten Stream-URLs auf Mobilgeräten.

---

## 9. Vercel

| Feld | Wert |
|---|---|
| Team | `OpenClaw's projects` (`team_AHshglW3k9jPfdsJXOGjTwxP`) |
| Projekt | `tiktok-live-companion` (`prj_p7gF1qSWrkzsacutq9ZPY9KX13eP`) |
| Produktionsbranch | `TikTok-Live-Companion` |
| Root Directory | `site` |
| Inspector | https://vercel.com/openclaw-vercel-project/tiktok-live-companion |
| Funktionen | `/api/shazam-token` |
| Interaktive Architektur | `/de/architecture-3d`, `/en/architecture-3d` |
| Visualisierungsdateien | `/visualizations/tiktok-live-companion-architecture.svg`, `.gif`, `tiktok-live-companion-flow-model.json` |

---

## 10. Airtable

| Feld | Wert |
|---|---|
| Workspace | `Mein erster Workspace` (`wsp2Geu90unFepBaG`), Rolle: Owner |
| Bases | derzeit keine |
| PAT | erfolgreich validiert, ohne Ausgabe |
| Ablage im globalen SecretStore | ⚠️ **nicht erfolgt** |

Es ist keine unterstützte globale SecretStore-Schreibschnittstelle verfügbar. Der PAT wurde deshalb **nicht** in einer Klartextdatei oder globalen Umgebungsvariable abgelegt.

---

## 11. Externe Referenzen

| Ressource | Adresse | Bezug |
|---|---|---|
| AudD Datei-/URL-Erkennung | https://docs.audd.io/ | Songerkennung im Browser |
| Apple ShazamKit | https://developer.apple.com/shazamkit/ | mobile Songerkennung |
| ShazamKit Android SDK | https://developer.apple.com/shazamkit/android/index.html | Android-AAR, Kotlin, minSdk 21 |
| SHSession | https://developer.apple.com/documentation/shazamkit/shsession/ | Erkennungssitzung |
| WKUserScript | https://developer.apple.com/documentation/webkit/wkuserscriptinjectiontime | Dokumentstart-Injektion iOS |
| Apple Media-ID und Schlüssel | https://developer.apple.com/help/account/capabilities/create-a-media-identifier-and-private-key | Developer-Token |
| Android WebView-Sicherheit | https://developer.android.com/privacy-and-security/risks/insecure-webview-native-bridges | Bridge-Härtung |
| Origin-beschränkte Bridge | https://developer.android.com/develop/ui/views/layout/webapps/native-api-access-jsbridge | Bridge-Design |

---

## 12. Codex-Sitzungen

| Version | Sitzungs-ID |
|---|---|
| 0.6.0 | `019f7492-6d71-7a91-88d7-4c87cedec9f0` |
| 0.7.0 | `019f7561-ade5-72e3-85e8-75c75b88ca06` |

Deeplink-Schema: `codex://threads/<Sitzungs-ID>`
Visualisierungen: `~/.codex/visualizations/2026/07/18/<Sitzungs-ID>/`

| Bild | Bezug |
|---|---|
| `tiktok-live-companion-0.6.0-sidepanel.png` | Sidepanel-Abnahme |
| `tiktok-live-companion-0.6.0-audience-modal.png` | Zuschauerübersicht |
| `site-0.7.0-desktop.png` | Website Desktop |
| `site-0.7.0-mobile-final.png` | Website 390 px nach Härtung |
| `docs/mobile/mobile-0.7.0-concept.png` | freigegebener Mobile-Entwurf, im Repo |
| `docs/diagrams/tiktok-live-companion-architecture.svg` | generierte statische Plattformarchitektur |
| `docs/diagrams/tiktok-live-companion-architecture.gif` | generierte animierte Plattformarchitektur |

---

## 13. Offene Punkte

| # | Punkt | Status |
|---|---|---|
| 1 | Formaler Security-Scan für 0.7.0 | ⚠️ offen |
| 2 | iOS-Build und XCTest auf macOS mit Xcode | ⚠️ Plattform fehlt |
| 3 | Apple-Capability, Media-ID, privaten Schlüssel und ShazamKit-AAR bereitstellen | ⚠️ Nutzer |
| 4 | Shazam-Produktvariante bauen statt Mock-APK | ⚠️ hängt an Punkt 3 |
| 5 | Physischer HyperOS-Test auf Xiaomi-Gerät | ⚠️ Gerät fehlt |
| 6 | Notion und Linear von 0.6.0 auf 0.7.0 fortschreiben | ⚠️ offen |
| 7 | Canva-Ordner ist leer und ohne Brand Kits | ⚠️ Entscheidung |
| 8 | Globale SecretStore-Ablage für den Airtable-PAT | ⚠️ keine Schnittstelle |
| 9 | Echter AudD-Aufruf am realen LIVE-Stream | ⚠️ kein Token |
| 10 | 0PE-41 und 0PE-43 umsetzen | ⚠️ Backlog |

---

*Ende der Linkliste · TikTok LIVE Companion 0.7.0 · Stand 18. Juli 2026*
