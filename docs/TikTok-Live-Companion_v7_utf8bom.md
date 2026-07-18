# TikTok LIVE Companion – Dokumentation v0.7.0

**Version:** 0.7.0 · **Stand:** 18. Juli 2026 · **Sprache:** Deutsch
**Projektwurzel:** `tiktok-live-companion-project/`
**Kanonische Quelle:** `tiktok-live-companion-project/`

> TikTok LIVE Companion ist ein unabhängiges Projekt. Es ist nicht mit TikTok verbunden und wird nicht von TikTok unterstützt.

---

## Inhalt

1. [Überblick](#1-überblick)
2. [Installation](#2-installation)
3. [Funktionen](#3-funktionen)
4. [Architektur](#4-architektur)
5. [Sicherheit und Datenschutz](#5-sicherheit-und-datenschutz)
6. [Fehlerbehebung](#6-fehlerbehebung)
7. [Downloads und Release](#7-downloads-und-release)

---

## 1. Überblick

TikTok LIVE Companion 0.7.0 ist eine lokale Manifest-V3-Erweiterung für Microsoft Edge und Google Chrome. Sie macht öffentliche TikTok-LIVE-Streams zugänglicher und bündelt in einem Seitenpanel: bereinigten Chattext, natürliches Vorlesen, Top-Chatter, beobachtete Personen, Geschenkzählung, native Untertitelprüfung, LIVE-Informationen, Playersteuerung, optionale manuelle Songerkennung, digitalen Pegelschutz, Bildqualitäten sowie FLV-/HLS-Links.

### Leistungsumfang

- zeigt die letzten fünf bereinigten öffentlichen Chatzeilen und hält höchstens 50 Sitzungseinträge pro Tab;
- spricht nur neue Chatzeilen über den lokalen Windows-Dienst oder als Fallback über Web Speech vor;
- erkennt pro Stream feste dreistellige Teamkürzel und verwaltet Stream- sowie Dauer-Mutes;
- unterscheidet `caption_info`, sichtbaren Untertitelschalter und tatsächlich empfangene CaptionMessages;
- liest Zuschauerzahl, Aufrufe, Likes, Follows und Teilungen aus beobachteten LIVE-Ereignissen;
- steuert TikToks vorhandenen Player, ohne Meldungen automatisch abzusenden;
- erkennt Stream-Varianten, Codecs, Auflösung, Bitrate und zeitlich begrenzte FLV-/HLS-URLs;
- exportiert Caption-Protokolle als JSONL und bereinigte Diagnosedaten als JSON.

### Grenzen

Die Erweiterung erzeugt keine Untertitel selbst. Fehlen TikToks native Caption-Ereignisse, kann sie diese nicht erzwingen. Der WebSocket-Bridge-Inhalt ist ein Beobachtungsprotokoll und kein kryptografisch authentifizierter Nachweis. Der Pegel wird in dBFS gemessen; ohne kalibriertes Ausgabegerät kann kein dB-SPL-Wert am Ohr garantiert werden.

Die Erweiterung liest keine Cookies, benötigt kein Konto und verwendet keinen API-Key.

---

## 2. Installation

### Voraussetzungen

- Microsoft Edge oder Google Chrome ab Version 114
- ein öffentlicher TikTok-LIVE-Tab
- die entpackte Erweiterung aus `tiktok-live-companion-extension-0.7.0.zip`

### Schritte

1. ZIP-Datei entpacken.
2. `edge://extensions` oder `chrome://extensions` öffnen.
3. **Entwicklermodus** aktivieren.
4. **Entpackte Erweiterung laden** wählen.
5. Den Ordner auswählen, in dem `manifest.json` liegt.
6. Einen öffentlichen TikTok-LIVE-Tab öffnen und auf das Erweiterungssymbol klicken.

### Optionaler lokaler Sprach- und Songdienst

1. `tiktok-live-companion-service-0.7.0.zip` entpacken und PowerShell in diesem Ordner öffnen.
2. `npm run setup` ausführen; ein AudD-Token ist ausschließlich für die Songerkennung erforderlich.
3. Den Dienst mit `npm start` starten.
4. Den ausgegebenen Pairing-Code im Sidepanel eintragen.

Der Dienst lauscht ausschließlich auf `127.0.0.1:43117`.

### Erster Einsatz

1. **Seite prüfen** liest Caption-Metadaten, sichtbare Bedienelemente und Stream-Informationen.
2. **Untertitel aktivieren** betätigt nur einen eindeutig erkannten TikTok-Menüpunkt.
3. **Hook setzen** registriert die Beobachtung vor dem Player-Code und lädt den Tab neu.
4. Nach dem Reload erscheinen Chat-, Caption- und LIVE-Ereignisse, sofern TikTok sie liefert.

**Refresh** leert nur flüchtige Erweiterungsdaten des aktuellen Tabs, aktiviert den Hook erneut und lädt TikTok ohne Seitencache. Cookies und Login bleiben unverändert.

---

## 3. Funktionen

### 3.1 Chat und Vorlesen

Öffentliche Chatnachrichten werden bereinigt und als zugänglicher Text dargestellt. Emoji-Sequenzen und sicher erkannte, pro Stream feste Teamkürzel werden beim Vorlesen entfernt. `@`-Empfänger und Fragen werden natürlich formuliert. Sprache, Namensansage und geeignete Namenskürzung sind einstellbar. Der optionale lokale Windows-Dienst ermöglicht Verstärkung; ohne Dienst bleibt der Browser-TTS-Fallback erhalten.

**Formulierungsbeispiele:**

| Chatzeile | Gesprochene Ausgabe |
|---|---|
| `Miimii tmm: @Stivinho danke` | Miimii sagt zu Stivinho danke |
| `Blitzerbiest: @Honey tmm wo is mein Tee ?` | Blitzerbiest fragt Honey wo is mein Tee |

**Teamkürzel-Heuristik:** Erkannt wird genau eine dreistellige alphanumerische Zeichenfolge pro Stream – entweder als Suffix bei mindestens zwei verschiedenen Namen oder bei einem Namen zuzüglich eigenständigem Vorkommen im Chat. Häufige gewöhnliche Drei-Buchstaben-Wörter genügen nicht. Bei Streamwechsel wird die Erkennung zurückgesetzt.

**Namenskürzung:** Für die Sprachausgabe entfallen Sonderzeichen und Zahlen. Technische Systemnamen wie `user5728384…` werden als `user572` gesprochen. Bei aktivierter geeigneter Kürzung werden klare Hauptteile erkannt, etwa `Traumtänzer.der.Nächte` → `Traumtänzer`, `Vanny_GioPrimetv` → `Vanny`, `Die Löwin` → `Löwin`, `liane15` → `liane`, `MKU Maskenaufsicht` → `Maskenaufsicht` und `Butterfly 004` → `Butterfly`. Dieselbe Regel gilt für Namen nach `@`. Generische Präfixe wie „Team", „Official" oder „The" sowie ungeeignete einteilige Namen bleiben unverändert.

**Lachspam:** Überlange, ausschließlich aus `h` und `a` aufgebaute Lachfolgen werden für die Sprachausgabe zu `haha` zusammengefasst.

**TTS-Einstellungen:** Sprache `Auto` / `Deutsch` / `Englisch`; `Chatnamen vorlesen` (Standard: an); `Geeignete Namen kürzen` (Standard: aus, nur bei aktivierten Chatnamen verfügbar).

**Lautstärke:** Der Regler bleibt bei 0–100 %. 50 % entspricht dem bisherigen normalen Maximalpegel, 100 % bis zu +6 dB, abgesichert durch einen lokalen Limiter gegen Clipping. Ohne laufenden Dienst ist oberhalb 50 % keine zusätzliche Verstärkung möglich; der Status weist darauf hin.

### 3.2 Top-Chatter und beobachtete Personen

Die Erweiterung zählt pro Stream Nachrichten, Wörter und Geschenkereignisse für bis zu 5.000 im Chat sichtbare Personen. Die Top-Chatter-Box unter „Chatzeilen" zeigt die fünf führenden Personen, sortiert nach Nachrichtenzahl, dann Wortzahl, dann Name.

Der Button **Zuschauer\*innen** öffnet ein zugängliches Modal mit allen während des Streams beobachteten Personen: Name, Nachrichten, Wörter, Geschenkereignisse, summierte `xN`-Geschenkanzahl, zuletzt gesehen und Mute-Modus.

**Mute-Modi:** `Aktiv`, `Für diesen Stream stumm`, `Dauerhaft stumm`. Stream-Mutes werden beim Streamwechsel verworfen, dauerhafte Mutes bleiben lokal gespeichert und nutzen bevorzugt `userId`/`displayId`.

Diese Liste ist ausdrücklich keine vollständige TikTok-Zuschauerliste, sondern die Menge der im Chat beobachteten Personen. TikToks WebSocket liefert nur aggregierte Zuschauerzahlen.

### 3.3 Songerkennung

Nach ausdrücklicher Aktivierung und Klick nimmt die Erweiterung etwa zwölf Sekunden Tab-Audio auf. Das Tab-Audio bleibt während der Aufnahme über einen AudioContext hörbar. Der lokale Dienst sendet nur diesen Ausschnitt an AudD und löscht temporäre Audiodaten unmittelbar nach Erfolg oder Fehler. Ohne Klick findet keine Aufnahme oder Übertragung statt.

Eine automatische Dauerüberwachung ist nicht enthalten. Das AudD-Token wird ausschließlich über das interaktive Dienst-Setup gespeichert.

### 3.4 Untertitel

Die Oberfläche trennt drei Signale: angekündigte Caption-Funktion in `caption_info`, gefundener Menüpunkt und tatsächlich empfangene `WebcastCaptionMessage`-Ereignisse. Fehlende Ereignisse beweisen nicht, dass nie gesprochen wurde.

### 3.5 LIVE-Informationen

Der Hook beobachtet `WebcastRoomUserSeqMessage`, `WebcastLikeMessage` und `WebcastSocialMessage`. Follows seit Hook sind ein lokaler Ereigniszähler; die Followerzahl des Hosts ist ein separater Gesamtwert.

### 3.6 Player und Pegelschutz

Play/Pause, Neuladen, Lautstärke, Stumm, Bild-in-Bild und Vollbild bedienen TikToks vorhandenen Player. Der optionale lokale Kompressor begrenzt digitale Spitzen. dBFS ist kein kalibrierter dB-SPL-Wert.

### 3.7 Bildqualität und VLC

Qualitätsstufen stammen aus TikToks Stream-Metadaten. **Automatisch** ist ein Playermodus und hat keinen VLC-Link. Signierte FLV-/HLS-Links können ablaufen und sind bis dahin sensibel.

### 3.8 Diagnose

Der abschaltbare Debugmodus exportiert bereinigte Ereignisse. Werte signierter URL-Parameter, Chattext, Cookies und API-Keys werden nicht exportiert.

### 3.9 Profil-Force

Der normale Refresh bleibt nicht unterbrechend. `Force` speichert die LIVE-URL, öffnet bewusst kurz die Profilseite ohne `/live`, wartet begrenzt auf vollständiges Laden und Profilscan, übernimmt die dort geladenen öffentlichen Werte und stellt anschließend die LIVE-URL wieder her. Statistiken bleiben erhalten; Hook und Player verbinden sich neu. Bei Timeout oder Benutzerabbruch wird die LIVE-URL wiederhergestellt und ein Fehler angezeigt.

---

## 4. Architektur

Die Erweiterung besteht aus sechs Laufzeitbereichen:

| Datei | Aufgabe |
|---|---|
| `content-core.js` | reine Normalisierung und Metadatenanalyse |
| `content.js` | DOM-Prüfung und lokale Player-/Audioaktionen in der isolierten Welt |
| `proto-main.js` | minimaler Protobuf-Decoder für öffentliche LIVE-Ereignisse |
| `hook.js` | MAIN-World-WebSocket-Proxy, der nur Listener ergänzt |
| `background.js` | passives CDN-Monitoring und flüchtiger Tab-Zustand |
| `sidepanel.*` | lokale Darstellung, Export- und Kopieraktionen |

Der Hook ersetzt `WebSocket.send()` nicht. Seiteninhalte gelten als nicht vertrauenswürdig und werden mit `textContent` ausgegeben. Stream-Daten, Captions, Chat und Diagnosen liegen in `storage.session`; `storage.local` enthält nur Autostart-, Vorlese- und Lautstärkepräferenzen sowie dauerhafte Mute-Identitäten.

Mermaid-Quelle: `docs/diagrams/architecture.mmd`

### Textalternative zum Diagramm

Der TikTok-Tab liefert öffentliche DOM-/Metadaten an das isolierte Content Script und beobachtete WebSocket-Ereignisse an den MAIN-World-Hook. Beide leiten bereinigte Ergebnisse an den Service Worker weiter. Dieser speichert den Zustand flüchtig pro Tab und sendet ihn an das Seitenpanel. CDN-Anfragen werden ausschließlich passiv beobachtet.

### Lokaler Begleitdienst

Windows-orientierter Node.js-Dienst, gebunden ausschließlich an `127.0.0.1`. Sprachsynthese über installierte Windows-DE-/EN-Stimmen mittels fester PowerShell-Synthese.

| Endpunkt | Beschreibung |
|---|---|
| `GET /v1/health` | Statusprüfung |
| `POST /v1/tts` | Text plus `auto` \| `de-DE` \| `en-US`; Antwort `audio/wav` |
| `POST /v1/recognize` | kurzer Audioausschnitt; Antwort mit Titel, Interpret, Album, Link, Erkennungsstatus |

Pairing-Code und Dienstadresse liegen in `chrome.storage.local`; externe Zugangsdaten verbleiben ausschließlich in einer benutzerspezifischen Dienstkonfiguration unter `%LOCALAPPDATA%`.

### Berechtigungen (Manifest V3)

**Permissions:** `activeTab`, `scripting`, `sidePanel`, `storage`, `tabCapture`, `tabs`, `webRequest`

**Host-Permissions:** `https://www.tiktok.com/*`, `http://127.0.0.1/*`, `http://localhost/*`, `*://*.tiktokcdn.com/*`, `*://*.tiktokcdn-eu.com/*`, `*://*.tiktokcdn-us.com/*`, `*://*.tiktokcdn-in.com/*`, `*://*.ttlivecdn.com/*`

Keine Cookie-Berechtigung. `webRequest` wird ohne `webRequestBlocking` verwendet.

---

## 5. Sicherheit und Datenschutz

### 5.1 Formales Release-Gate

Der vollständige Codex-Security-Scan vom 17. Juli 2026 hat alle neun Prüfumfänge abgeschlossen. Ergebnis: keine kritischen, hohen oder mittleren Findings; zwei validierte niedrige Restrisiken (Low/P3). Sie betreffen fehlende Größenbudgets an der lokalen Seiten-Bridge und bei der Dekompression beobachteter WebSocket-Nachrichten. Beide Pfade setzen bereits Codeausführung im Seitentab beziehungsweise Kontrolle über die WebSocket-Nachricht voraus und führen weder zu Kontoübernahme noch zu Cookie-, Secret- oder Cross-Origin-Zugriff.

> **Wichtig:** Die durchgeführte Prüfung bezog sich auf 0.5.0. Version 0.7.0 begrenzt Teilnehmerdaten und Dienst-Anfragegrößen, ergänzt aber einen lokalen Pairing-Dienst und `tabCapture`. Vor einer externen Veröffentlichung ist deshalb ein neuer Release-Scan erforderlich.

### 5.2 Sicherheitskontrollen

- keine Cookie-Berechtigung und kein Zugriff auf `document.cookie`;
- keine Telemetrie oder Remote-Skripte; nur ein ausdrücklicher Songerkennungs-Klick überträgt einen kurzen Audioausschnitt an AudD;
- kein `eval`, `new Function` oder Zuweisung an `innerHTML`;
- `webRequest` ohne `webRequestBlocking`;
- maximal 50 bereinigte Chatnachrichten pro Tab;
- Sprachausgabe und Verstärkung lokal; der Begleitdienst bindet nur an `127.0.0.1` und erzwingt Pairing, Origin-Prüfung und Größenlimits;
- die Dienstadresse akzeptiert ausschließlich echte Loopback-URLs (`127.0.0.1` / `localhost`);
- der Meldedialog wird nur geöffnet und nie automatisch ausgefüllt oder abgesendet.

### 5.3 Datenhaltung

Stream-URLs, Chat, Captions, Profile, Teilnehmeraggregate und Diagnosedaten liegen in `chrome.storage.session`. Einstellungen und dauerhafte Mute-Identitäten liegen in `chrome.storage.local`; das AudD-Token verbleibt ausschließlich in der lokalen Dienstkonfiguration.

### 5.4 Offene Restrisiken

- Ein Seitenskript kann die `postMessage`-Bridge imitieren.
- Signierte Medien-URLs können während ihrer Gültigkeit Zugriff ermöglichen.
- TikTok kann DOM, CDN-Domains, Kompression oder Protobuf-Felder ändern und damit Fehlnegative verursachen.
- Browser können Bild-in-Bild, Vollbild oder Web-Audio-Routing ablehnen.

Der öffentliche Sicherheitsabschnitt enthält keine Proof-of-Concepts und keine gültigen signierten URLs.

### 5.5 Externe Datenübertragung

Einzige externe Übertragung ist der AudD-Aufruf nach ausdrücklichem Klick. Übertragen wird ausschließlich ein rund zwölfsekündiger Audioausschnitt. Diese Übertragung und mögliche Anbietergebühren werden vor der ersten Nutzung in der Oberfläche ausgewiesen.

---

## 6. Fehlerbehebung

### Keine CaptionMessages

Zuerst **Seite prüfen** ausführen. `caption_info` und ein sichtbarer Menüpunkt zeigen nur die Verfügbarkeit an; erst empfangene CaptionMessages bestätigen Ereignisse im Beobachtungszeitraum. Den Hook vor der Player-Verbindung setzen und den Tab neu laden.

### Hook bleibt getrennt

**Refresh** im Hook-Bereich verwenden. Dadurch wird nur der flüchtige Zustand des Tabs gelöscht, der Hook erneut registriert und die Seite ohne Cache geladen. Bei Autostart kann die Registrierung browserübergreifend bestehen bleiben.

### Playeraktion wird abgelehnt

Bild-in-Bild und Vollbild benötigen je nach Browser eine unmittelbare Nutzeraktion. Web Audio kann für einzelne Medienkonfigurationen nicht verfügbar sein; die Erweiterung meldet den Fehler und behauptet dann keinen aktiven Pegelschutz.

### Keine VLC-Links

Ein Stream kann nur HLS, nur FLV oder keine extrahierbare URL liefern. **Automatisch** ist keine konkrete Stream-URL. Erneut **Seite prüfen** ausführen, nachdem der Player geladen ist.

### Vorlesen nicht lauter als bisher

Oberhalb 50 % ist Verstärkung nur mit laufendem lokalem Dienst möglich. Dienststatus im Sidepanel prüfen: Dienstadresse, Pairing-Code und `npm start`.

### Songerkennung ohne Ergebnis

Mögliche Ursachen: fehlendes AudD-Token, verweigerte Tab-Audioaufnahme, nicht erreichbarer Dienst oder tatsächlich kein Treffer. Die Oberfläche unterscheidet diese Zustände.

### Diagnoseexport

Debugmodus erst zur Fehlersuche aktivieren. Der Export enthält keinen Chattext und entfernt Werte signierter URL-Parameter.

---

## 7. Downloads und Release

### 7.1 Artefakte 0.7.0

| Datei | Inhalt |
|---|---|
| `tiktok-live-companion-extension-0.7.0.zip` | entpackbare Edge-/Chrome-Erweiterung |
| `tiktok-live-companion-plugin-0.7.0.zip` | Codex-Plugin einschließlich Skill, Referenzen und Tests |
| `tiktok-live-companion-service-0.7.0.zip` | optionaler lokaler Windows-Dienst |
| `tiktok-live-companion-0.7.0-SHA256.txt` | Integritätswerte |

Ablage: `tiktok-live-companion-project/release/0.7.0/`

### 7.2 SHA-256-Prüfsummen

```text
40721b800a0f1aa4580ebabaa13ad82d10426ce0287eb1559749385f5850dfce  tiktok-live-companion-extension-0.7.0.zip
c8696754cc06453ad26237cb0d1d641ddeb19b7c21df7df3b06c7ac0b55f457c  tiktok-live-companion-plugin-0.7.0.zip
617c63288976c8507d2e5cd6cfaf9eb5767f43b4c901e703f29d3aff58aa6c56  tiktok-live-companion-service-0.7.0.zip
```

Diese Werte wurden am 18. Juli 2026 gegen die tatsächlichen Dateien im Release-Verzeichnis verifiziert.

### 7.3 Änderungen in 0.7.0

Version 0.7.0 ergänzt natürliche Chat-Aufbereitung mit Teamkürzel- und Empfängererkennung, Top-Chatter, beobachtete Personen, Mutes, Geschenkstatistik, DE-/EN-/Auto-TTS, den optionalen gepaarten Windows-Sprachdienst, manuelle AudD-Songerkennung und Profil-Force.

### 7.4 Prüfstand

| Prüfung | Ergebnis |
|---|---|
| Extension-Struktur und Decoder | bestanden |
| Diensttests (7) | bestanden |
| Windows-WAV-Ausgabe inkl. Stimmen-Fallback | bestanden |
| Dokumentations-UI-Tests (21) | bestanden |
| TypeScript-Typprüfung | bestanden |
| Produktionsbuild | bestanden |
| Paketprüfsummen | bestanden |
| Sidepanel-Sichtprüfung 383 × 900 px | bestanden, ein horizontaler Überlauf behoben |
| Modal-Fokus, Fokus-Rückgabe, Escape | bestanden |
| Hell- und Dunkelmodus | bestanden |

**Nicht extern ausgeführt:** ein echter AudD-Aufruf (kein Token) sowie `Force` auf einem realen LIVE-Stream (kein aktiver Teststream). Fehler-, Sicherheits- und UI-Pfade wurden lokal geprüft.

### 7.5 Verifikation durch Dritte

```powershell
node plugin-source/scripts/test_extension.cjs
cd plugin-source/companion-service
npm test
cd ../../site
npm ci
npm run typecheck
npm test
npm run build
```

---

## Versionshistorie

| Version | Schwerpunkt |
|---|---|
| 0.7.0 | Chat-TTS-Aufbereitung, Zuschauerstatistik, Songerkennung, Profil-Force, lokaler Dienst |
| 0.5.0 | öffentlich veröffentlichter Stand mit zweisprachiger Dokumentation und Website |
| 0.4.0 – 0.1.0 | frühere Entwicklungsstände, archiviert in der Projektwurzel |

---

*Ende der Dokumentation · TikTok LIVE Companion 0.7.0 · Stand 18. Juli 2026*
