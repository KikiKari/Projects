# Links und Erreichbarkeiten v0.7.0

**Version:** 0.7.0 · **Stand:** 18. Juli 2026
**Projektwurzel:** `tiktok-live-companion-project/`
**Kanonische Quelle:** GitHub · alle anderen Systeme spiegeln den freigegebenen Stand.

### Status-Legende

| Symbol | Bedeutung |
|---|---|
| ✅ | lokal verifiziert am 18.07.2026 |
| 🔗 | aus dem Sitzungsverlauf übernommen, nicht erneut geprüft |
| ⚠️ | offen, unbestätigt oder klärungsbedürftig |
| 🔒 | lokal, nicht öffentlich erreichbar |

---

## 1. Öffentliche Projektziele

| System | Adresse | Status |
|---|---|---|
| GitHub-Repository | https://github.com/KikiKari/Projects | 🔗 |
| GitHub-Branch | https://github.com/KikiKari/Projects/tree/TikTok-Live-Companion | 🔗 |
| GitHub-iOS-Branch | https://github.com/KikiKari/Projects/tree/TikTok-Live-Companion-iOS | 🔗 |
| GitHub-Android-/HyperOS-Branch | https://github.com/KikiKari/Projects/tree/TikTok-Live-Companion-Android | 🔗 |
| Interaktive 3D-Referenz | https://kikikari.github.io/OpenClaw/mcp-flow.html | 🔗 |
| GitHub-Issues offen | https://github.com/KikiKari/Projects/issues | 🔗 |
| GitHub-Issues geschlossen | https://github.com/KikiKari/Projects/issues?q=is%3Aissue+state%3Aclosed | 🔗 |
| Dokumentationssite | https://tiktok-live-companion.vercel.app | 🔗 |
| Linear-Projekt | https://linear.app/0penclaw/project/tiktok-live-companion-ed2f087b24bc | 🔗 |
| Linear-Team 0PE | https://linear.app/0penclaw/team/0PE/active | 🔗 |
| Notion-Projektseite | https://app.notion.com/p/3a18d8ad3db9817f882bd79682fbbc51 | ⚠️ |
| Canva-Ordner | https://www.canva.com/folder/FAHPt7Wvb8E | ⚠️ |

**Hinweis zum Veröffentlichungsstand:** Version 0.7.0 ist auf dem gemeinsamen Branch sowie den iOS- und Android-/HyperOS-Branches veröffentlicht. Der 0.7.0-Release-Review liegt unter `security-scan/release-review-0.7.0.md`.

**Notion und Canva:** Umsetzung erfolgt durch Codex.

---

## 2. Aktive Issues

| ID | Thema | Adresse |
|---|---|---|
| 0PE-41 | Low/P3 – Bridge-Payloads byte-begrenzen | https://linear.app/0penclaw/issue/0PE-41/lowp3-bridge-payloads-byte-begrenzen |
| 0PE-43 | Low/P3 – gzip-Ausgabe und Decode-Parallelität begrenzen | https://linear.app/0penclaw/issue/0PE-43/lowp3-gzip-ausgabe-und-decode-parallelitat-begrenzen |

Die beiden GitHub-Dubletten (#1 und #2) wurden geschlossen, nicht gelöscht. Aktiv sind ausschließlich die beiden Linear-Issues.

---

## 3. Lokale Dienst-Erreichbarkeiten 🔒

| Dienst | Adresse | Zweck |
|---|---|---|
| Companion-Service | `http://127.0.0.1:43117` | Sprachausgabe und Songerkennung |
| Health-Endpunkt | `GET http://127.0.0.1:43117/v1/health` | Statusprüfung |
| TTS-Endpunkt | `POST http://127.0.0.1:43117/v1/tts` | Text → `audio/wav` |
| Erkennungs-Endpunkt | `POST http://127.0.0.1:43117/v1/recognize` | Audioausschnitt → Songdaten |

Der Dienst bindet ausschließlich an Loopback. Die Erweiterung akzeptiert als Dienstadresse nur `127.0.0.1` oder `localhost`. Zugriff erfordert einen generierten Pairing-Code.

**Konfigurationsablage:**

| Inhalt | Ort |
|---|---|
| Pairing-Code, Dienstadresse | `chrome.storage.local` |
| AudD-Token | benutzerspezifische Dienstkonfiguration unter `%LOCALAPPDATA%` |
| Stream-, Chat-, Caption-, Teilnehmerdaten | `chrome.storage.session` (flüchtig, pro Tab) |
| Einstellungen, dauerhafte Mutes | `chrome.storage.local` |

---

## 4. Repository-Struktur ✅

Basis: `tiktok-live-companion-project/`

| Pfad | Inhalt |
|---|---|
| `README.md` | Projektüberblick, Schnellstart, Verifikationsbefehle |
| `plugin-source/` | reproduzierbarer Plugin-Quellstand |
| `plugin-source/browser-extension/` | kanonische Erweiterungsquellen |
| `plugin-source/companion-service/` | lokaler Windows-Dienst |
| `plugin-source/scripts/` | Test- und Packaging-Skripte |
| `plugin-source/tests/` | Sidepanel-Harness |
| `plugin-source/skills/` | Codex-Skillbeschreibung |
| `plugin-source/references/architecture.md` | technische Architekturreferenz |
| `plugin-source/SECURITY.md` | Sicherheitsbeschreibung |
| `docs/de/`, `docs/en/` | zweisprachige Dokumentation, je sieben Kapitel |
| `docs/diagrams/*.mmd` | reproduzierbare Mermaid-Quellen für Architektur, Erkennung und Deployment |
| `docs/coauthoring-v7.md` | alle 13 freigegebenen CoAuthoring-Bildquellen und Designhistorie |
| `site/public/assets/coauthoring-v7/` | unveränderte PNG-Originale für die Dokumentationssite |
| `release/0.7.0/` | aktuelle Artefakte und Prüfsummen |
| `release/` | 0.5.0-Artefakte und Prüfsummen |
| `security-scan/` | Threat Model, Findings, Abschlussbericht |
| `site/` | statische React-/TypeScript-/Vite-Dokumentationssite |

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

### Weitere Dokumente in der Projektwurzel

| Datei | Inhalt |
|---|---|
| `INSTALLATION-tiktok-live-companion.md` | Installationsanleitung |
| `publication-drafts/EXTERNAL-PUBLISHING.md` | Staging der externen Veröffentlichungsinhalte, nicht Teil des öffentlichen Branch |
| `tiktok-live-companion-SHA256.txt` | Prüfsummen der Altversionen |

---

## 5. Release-Artefakte und Prüfsummen ✅

### 0.7.0 · `tiktok-live-companion-project/release/0.7.0/`

| Artefakt | SHA-256 |
|---|---|
| `tiktok-live-companion-extension-0.7.0.zip` | `a3c818eb63179ad1c0d5896c5bac8263bab0c6732c8621cbcafbd847d5a50b42` |
| `tiktok-live-companion-plugin-0.7.0.zip` | `4644ebf46bbd363edd499a16afc49b9ac7fa2c5cf03a1bae5149614ccbefb3b9` |
| `tiktok-live-companion-service-0.7.0.zip` | `4bb5df40229c72a0e93ab822709182542d31846cc865f89962da3769e652fd1c` |
| `tiktok-live-companion-ios-0.7.0-source.zip` | `3b833ea2969487ea9a82571478a4f273f3e678cffb6a11bde51e94ee0e5bbff3` |
| `tiktok-live-companion-android-0.7.0-source.zip` | `62e57e5d901ffb581fc40dc8a47454fb7e46531c57ffdbd71b82b071f76ad594` |
| `tiktok-live-companion-android-0.7.0-debug.apk` | `00f8df107107661c5bb6204f0fedb9d1f485fdbe5085f19f27e0f8089481d0f5` |

Prüfsummendatei: `release/0.7.0/tiktok-live-companion-0.7.0-SHA256.txt`
Verifiziert am 18.07.2026 gegen die tatsächlichen Dateien.

### 0.5.0 · `tiktok-live-companion-project/release/`

| Artefakt | SHA-256 |
|---|---|
| `tiktok-live-companion-extension-0.5.0.zip` | `9439e21db0e8fc2e874a478079d1243297d4c95e0dbb140795912f75eb250b02` |
| `tiktok-live-companion-plugin-0.5.0.zip` | `a99fdfb14cd0effac4f89468758258e073dc75ed0f59763bc9764c4c380088a0` |

### Downloadkopien der Website

`site/public/downloads/` enthält die 0.5.0- und 0.7.0-Artefakte sowie beide Prüfsummendateien.

### Versionsarchiv der Projektwurzel

`tiktok-live-companion-extension-0.1.0` bis `-0.5.0`, jeweils mit Quelldateien und ZIPs.

---

## 6. Security-Scan

### Ergebnis

9/9 Prüfbereiche · keine kritischen, hohen oder mittleren Findings · 2 × Low/P3 · Laufzeit rund 19 Minuten · Datum 17.07.2026 · Bezug: Version 0.5.0.

### Kanonische Artefakte ✅

| Datei | Inhalt |
|---|---|
| `security-scan/final/report.md` | Abschlussbericht |
| `security-scan/final/findings.json` | zwei validierte Findings |
| `security-scan/final/results.sarif` | SARIF-Export |
| `security-scan/final/coverage.json` | Abdeckung |
| `security-scan/final/scan-manifest.json` | Scan-Manifest |
| `security-scan/threat_model.md` | Threat Model |
| `security-scan/canonical/`, `derived/`, `artifacts/` | Zwischenstände |

Lokale, flüchtige Scan-Exporte sind nicht Teil des Repository. Maßgeblich sind ausschließlich die bereinigten kanonischen Kopien unter `security-scan/final/`.

---

## 7. Externe Referenzen

| Ressource | Adresse | Bezug |
|---|---|---|
| AudD Datei-/URL-Erkennung | https://docs.audd.io/ | verwendete Songerkennung |
| Apple ShazamKit | https://developer.apple.com/shazamkit/ | geprüft und verworfen, keine Windows-/Browser-Unterstützung |

---

## 8. Offene Punkte

| # | Punkt | Zuständig |
|---|---|---|
| 1 | Neuer Security-Scan für 0.7.0 vor externer Veröffentlichung | offen |
| 2 | Notion-Projektseite fertigstellen | Codex |
| 3 | Canva-Präsentation DE erstellen und freigeben | Codex |
| 4 | Canva-Kopie EN nach separater Freigabe | Codex |
| 5 | Entscheidung: 0.7.0 öffentlich veröffentlichen | offen |
| 6 | GitHub-Branch, Site und Downloads von 0.5.0 auf 0.7.0 heben | offen |
| 7 | Gegenseitige Linksynchronisierung aller Zielsysteme | offen |
| 8 | Nachbearbeitete Produkt-Screenshots freigeben und einbinden | offen |
| 9 | Echter AudD-Aufruf und `Force` am realen LIVE-Stream verifizieren | offen |

---

*Ende der Linkliste · TikTok LIVE Companion 0.7.0 · Stand 18. Juli 2026*
