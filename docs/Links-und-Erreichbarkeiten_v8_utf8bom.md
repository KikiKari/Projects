# Links und Erreichbarkeiten v0.7.1

**Version:** 0.7.1 · **Dokumentrevision:** v8 · **Status:** finalisiert · **Stand:** 2. August 2026, 17:00 Uhr
**Projektwurzel:** `C:\Users\silve\Documents\Codex\TikTok-Live-Companion`
**Kanonische Quelle:** GitHub · alle anderen Systeme spiegeln den freigegebenen Stand.
**Fortschreibende Codex-Sitzung:** `019fbedc-9c0a-79c2-810f-8a32946de772` · `codex://threads/019fbedc-9c0a-79c2-810f-8a32946de772`
**CoAuthoring:** Claude Dispatcher (Versenden) · Übergabe an Codex zur Ausarbeitung von 0.8.0 am 08.08.2026

### Status-Legende

| Symbol | Bedeutung |
|---|---|
| ✅ | verifiziert bis 02.08.2026 |
| 🔗 | aus dem Sitzungsverlauf übernommen, nicht unabhängig nachgeprüft |
| ⚠️ | offen oder klärungsbedürftig |
| 🔒 | lokal beziehungsweise nur mit Anmeldung erreichbar |

Linear-Status: live aus Linear am 02.08.2026, 17:00 Uhr abgeglichen. GHCR-Sichtbarkeit: Package Settings der drei Pakete.

### Fortschreibung 02.08.2026, Nachmittag · 0PE-94 bis 0PE-103

Veröffentlichter Endstand dieser Sitzung: Browser `809de33`, Android `0bebb07` (getesteter Funktionsstand `8cd5c3d`), iOS `6efa242`. `0PE-97`, `0PE-98`, `0PE-102` und `0PE-94` sind `Done`. Neu erfasst und offen sind `0PE-93`, `0PE-95`, `0PE-96`, `0PE-99`, `0PE-100`, `0PE-101` und `0PE-103`; `0PE-72` wurde wieder geöffnet. Releases und GHCR-Packages bleiben ausdrücklich bis zum 08.08.2026 als `0.7.1 alpha` markiert.

---

### Fortschreibung 30.07. – 02.08.2026 · finalisiert

Diese Revision v8 ist die **abgeschlossene, übergabefähige Linkliste** zum 0.7.1-Stand. Sie ersetzt die zuvor als „veröffentlicht" markierte v8-Fassung vom 30.07.2026 vollständig und führt den weiteren Arbeitsverlauf der Codex-Sitzung `019fbedc-9c0a-79c2-810f-8a32946de772` nach. Die Zwischenrevision v9 im veröffentlichten Checkout bleibt als Arbeitsspur bestehen.

Umgesetzt wurden `0PE-73`, `0PE-78`, `0PE-79`, `0PE-85`, `0PE-86`, `0PE-87`, `0PE-88`, `0PE-89`, `0PE-90` sowie die neu erfassten `0PE-91`, `0PE-92` und `0PE-93`. Lokale Änderungen, Commits, Pushes, CI, Pakete, Registry und Deployment sind getrennt ausgewiesen. Der veröffentlichte Browser-Stand ist `f44f946`; Android steht auf `b3d1770`, iOS auf `0a4fc63`.

---

## 1. Veröffentlichte Branches

| Branch | Adresse | Produkt- und Artefakt-Commit | Status |
|---|---|---|---|
| `TikTok-Live-Companion` | https://github.com/KikiKari/Projects/tree/TikTok-Live-Companion | `809de33` | ✅ Push und Remote bestätigt |
| `TikTok-Live-Companion-Android` | https://github.com/KikiKari/Projects/tree/TikTok-Live-Companion-Android | `0bebb07` | ✅ Push und Remote bestätigt; getesteter Funktionsstand `8cd5c3d` |
| `TikTok-Live-Companion-iOS` | https://github.com/KikiKari/Projects/tree/TikTok-Live-Companion-iOS | `6efa242` | ✅ Push und vollständiger nativer Actions-Lauf `30748478805` bestätigt |

Das Repository `KikiKari/Projects` ist laut GitHub-API `private=False`, `visibility=public`. Alle drei Branches sind öffentlich sichtbar.

Der iOS-Branch enthält kein `mobile/android`, der Android-Branch kein `mobile/ios`. Der gemeinsame Branch enthält beide.

Der Android-Wert wurde mit `git fetch --all` und `git ls-remote --heads origin` gegen das Remote bestätigt. Das Remote-Tracking-Ref in einer nicht aktualisierten Arbeitskopie kann weiterhin einen älteren Stand anzeigen; maßgeblich ist das Ergebnis von `git ls-remote`.

### Commit-Kette des Browser-Branches (Sitzung `019fbedc-…`)

| Commit | Inhalt |
|---|---|
| `280f478` | Ausgangsstand der v8-Fassung vom 30.07.2026 |
| `35a0651` | Fachimplementierung der neun aktiven 0.7.1-Issues |
| `40c74de` | Release der verifizierten Artefakte und des Security-Seals (`0PE-84`, `0PE-91`) |
| `29f1d8a` | Sidepanel-Hotfix `service-setup-command` (`0PE-92`) |
| `039ec54` | Installations- und Release-Nachweis |
| `f44f946` | `0PE-93` — CSS-Ursache der sichtbaren Pairing-/AudD-Felder |
| `3534bb5` | Issue-Korrekturen nach Anlage von `0PE-94` bis `0PE-96` |
| `3476d17` | `0PE-97`, `0PE-98`, `0PE-102` — VLC-Platzierung, LIVE-Informationen, Top-Chatter |
| `4fda3fd` | Release-Paketierung der drei Issues |
| `809de33` | `docs: finalize OPE-97 98 102 evidence` — **aktueller Stand** |

### Frühere Commit-Kette

| Commit | Inhalt |
|---|---|
| `280f478` | Ausgangsstand der v8-Fassung vom 30.07.2026 |
| `35a0651` | Fachimplementierung der neun aktiven 0.7.1-Issues |
| `40c74de` | Release-Veröffentlichung der verifizierten Artefakte und des Security-Seals (`0PE-84`, `0PE-91`) |
| `29f1d8a` | Sidepanel-Hotfix `service-setup-command` (`0PE-92`) |
| `faabada` | Remote- und Dokumentationsstand nach dem Hotfix |
| `039ec54` | `docs: record service install release evidence` — veröffentlichter Vorgänger |
| `f44f946` | `fix(browser): finalize 0.7.1 service and chat controls` — **aktueller veröffentlichter Stand** |

Der lokale Arbeitsbaum in `.publish-repo/` enthält nur noch unversionierte reproduzierbare Bauausgaben unter `.artifacts/`; der Quell- und Dokumentationsstand ist veröffentlicht.

### Lokale Arbeitskopien

| Pfad | Branch |
|---|---|
| `.publish-repo/` | `TikTok-Live-Companion` |
| `android-implementation/` | `TikTok-Live-Companion-Android` |
| `ios-implementation/` | `TikTok-Live-Companion-iOS` |

Die Mobile-Verzeichnisse sind Git-Worktrees des veröffentlichten Checkouts. Der Workspace-Root selbst ist **kein** gültiges Git-Repository; sein `.git`-Verzeichnis ist leer. Alle Git-Operationen laufen über `.publish-repo` oder die beiden Worktrees.

### Weitere Remote-Branches

| Branch | Spitze | Bezug |
|---|---|---|
| `audit-android` | `ad202dd` (21.07.) | Audit-Zweig, nicht Teil des Release |
| `audit-ios` | `41353f0` (21.07.) | Audit-Zweig, nicht Teil des Release |

---

## 2. Öffentliche Projektziele

| System | Adresse | Status |
|---|---|---|
| GitHub-Repository | https://github.com/KikiKari/Projects | ✅ öffentlich |
| GitHub-Issues offen | https://github.com/KikiKari/Projects/issues | 🔗 |
| GitHub-Issues geschlossen | https://github.com/KikiKari/Projects/issues?q=is%3Aissue+state%3Aclosed | 🔗 |
| GitHub-Releases | https://github.com/KikiKari/Projects/releases | ✅ drei 0.7.1-Alpha-Releases |
| GitHub-Actions | https://github.com/KikiKari/Projects/actions | ✅ iOS-Workflow läuft |
| Dokumentationssite Deutsch | https://tiktok-live-companion.vercel.app/de | ✅ live |
| Dokumentationssite English | https://tiktok-live-companion.vercel.app/en | ✅ live |
| Interaktive Architektur Deutsch | https://tiktok-live-companion.vercel.app/de/architecture-3d | ✅ live |
| Interaktive Architektur English | https://tiktok-live-companion.vercel.app/en/architecture-3d | ✅ live |
| Architektur-SVG | https://tiktok-live-companion.vercel.app/visualizations/tiktok-live-companion-architecture.svg | ✅ live |
| Architektur-GIF | https://tiktok-live-companion.vercel.app/visualizations/tiktok-live-companion-architecture.gif | ✅ live |
| Flow-Modell JSON | https://tiktok-live-companion.vercel.app/visualizations/tiktok-live-companion-flow-model.json | ✅ live |
| Vercel-Inspector | https://vercel.com/openclaw-vercel-project/tiktok-live-companion | 🔒 Anmeldung |
| Linear-Projekt | https://linear.app/0penclaw/project/tiktok-live-companion-ed2f087b24bc/overview | 🔒 Anmeldung |
| Linear-Team 0PE | https://linear.app/0penclaw/team/0PE/active | 🔒 Anmeldung |
| Notion-Projektseite | https://app.notion.com/p/kikikari/TikTok-LIVE-Companion-3a18d8ad3db9817f882bd79682fbbc51 | 🔒 Anmeldung, Inhalt auf 0.7.1 |
| Canva-Ordner | https://www.canva.com/folder/FAHPt7Wvb8E | 🔒 Anmeldung, zwei 0.7.1-Decks |

**Hinweis zur Öffentlichkeit:** Vercel und GitHub sind ohne Anmeldung erreichbar und wurden bytegenau geprüft. Linear und Notion liefern ohne eingeloggten Kontext nur eine Login- beziehungsweise App-Shell mit HTTP 200 — sie sind damit **nicht** als öffentlich lesbare Projektseiten verifiziert, sondern nur als vorhanden und aktualisiert.

---

## 3. GitHub Releases 0.7.1 ✅

| Release | Tag | Assets |
|---|---|---|
| Browser Alpha | https://github.com/KikiKari/Projects/releases/tag/tlc-browser-v0.7.1-alpha | Extension-ZIP, Plugin-ZIP, Service-ZIP, SHA-Datei |
| Android Alpha | https://github.com/KikiKari/Projects/releases/tag/tlc-android-v0.7.1-alpha | Android-APK, Android-Source-ZIP |
| iOS Alpha | https://github.com/KikiKari/Projects/releases/tag/tlc-ios-v0.7.1-alpha | iOS-Source-ZIP |

Alle drei sind ausdrücklich als `alpha` gekennzeichnet. Es existieren keine Store-Einträge und keine signierten Store-Pakete.

---

## 4. GHCR-Container-Pakete ✅

Übersicht: https://github.com/KikiKari?tab=packages&repo_name=Projects

| Paket | Referenz | Sichtbarkeit | Quellrepository |
|---|---|---|---|
| Browser | `ghcr.io/kikikari/tiktok-live-companion-browser:0.7.1-alpha` | ✅ `public` | ✅ `KikiKari/Projects` |
| Android | `ghcr.io/kikikari/tiktok-live-companion-android:0.7.1-alpha` | ✅ `public` | ✅ `KikiKari/Projects` |
| iOS | `ghcr.io/kikikari/tiktok-live-companion-ios:0.7.1-alpha` | ✅ `public` | ✅ `KikiKari/Projects` |

OCI-Index-Digests des Endstandes: Android `sha256:1a34ab9849769aa8c3bc86a29197ab5a3aa0bffeb39b58635303393c50981df1` (nach `0PE-94`). Vorherige Digests der Sitzung: Browser `sha256:3822dc57c1b850149b6825c5892476c6383ae05cbe116fc16f071509a0865752`, Android `sha256:6cbb85768154f7d5ac5faffcf5cb72c1ca8233cfa41b444ffda9000324c443a2`, iOS `sha256:eb1d69ebff7c4bb20737cc5159bafedbe756c10ea39d8734b676f3cc9921b1ad`.

Package-Settings-Adressen: `https://github.com/users/KikiKari/packages/container/tiktok-live-companion-{browser,android,ios}/settings`

Die Images enthalten die jeweiligen Release-Artefakte unter `/artifacts` auf einer gemeinsamen Alpine-Schicht. Alle drei Pakete sind auf dem Packages-Tab des Kontos gelistet.

**Sichtbarkeit:** Alle drei Pakete stehen laut Package Settings auf `public` („This package is currently public"). Damit sind die Artefakte ohne Anmeldung abrufbar.

**Zugriffssteuerung je Paket:**

| Einstellung | Wert |
|---|---|
| Repository source | `KikiKari/Projects`, verifiziert über das Label `org.opencontainers.image.source = "https://github.com/KikiKari/Projects"` im Dockerfile |
| Inherit access from source repository | ✅ aktiviert, 0 zusätzliche Mitglieder |
| Manage Actions access | `Projects`, Rolle `Read` |
| Manage Codespaces access | `Projects`, Rolle `Read` |

Die REST-Umschaltung der Sichtbarkeit hatte zuvor mit `404` geantwortet; das entspricht dem dokumentierten GitHub-Verhalten für Container-Pakete, deren Sichtbarkeit über `Package settings` → `Danger Zone` → `Change package visibility` im UI gesetzt wird. Dieser Schritt ist erfolgt.

Referenzen: [GitHub Packages access and visibility](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility) · [GitHub REST Packages](https://docs.github.com/en/rest/packages/packages)

---

## 5. Notion-Seiten

| Seite | Adresse | Stand |
|---|---|---|
| Projektseite | https://app.notion.com/p/3a18d8ad3db9817f882bd79682fbbc51 | ✅ Nachtrag 29.07.2026 |
| Überblick / Overview | https://app.notion.com/p/3a18d8ad3db981518b57c1618b2bb827 | 🔗 |
| Installation | https://app.notion.com/p/3a18d8ad3db981e09199f940be4f0f42 | 🔗 |
| Funktionen / Features | https://app.notion.com/p/3a18d8ad3db9818f990ff6e8ddaca655 | 🔗 |
| Architektur / Architecture | https://app.notion.com/p/3a18d8ad3db981fcbe4cdea7c1805049 | 🔗 |
| Sicherheit & Datenschutz | https://app.notion.com/p/3a18d8ad3db981df92cee9f0892234b4 | 🔗 |
| Fehlerbehebung / Troubleshooting | https://app.notion.com/p/3a18d8ad3db9817888d9d6c4188c98e8 | 🔗 |
| Downloads & Release Notes | https://app.notion.com/p/3a18d8ad3db981cba6a7e2590656ba94 | ✅ Nachtrag 29.07.2026 |

Übergeordnete Seite: `Onboarding and Project Pages` (`3878d8ad-3db9-8116-a5d4-f68d8c8ad717`)

Die Fortschreibung erfolgte als klar abgegrenzter Nachtrag auf den **bestehenden** Seiten. Es wurden keine neuen Seiten angelegt und keine Notion-spezifische Markdown-Syntax verwendet, weil die zugehörige Spec-Ressource in der Umgebung nicht lesbar war.

---

## 6. Canva 🔒

| Design | Sprache | Ansehen | Bearbeiten |
|---|---|---|---|
| `TikTok LIVE Companion 0.7.1 - Präsentation DE` | Deutsch | https://www.canva.com/d/yWFtIdIQ36QLnp7 | https://www.canva.com/d/eWIoy9X7YsjFjN3 |
| `TikTok LIVE Companion 0.7.1 - Presentation EN` | English | https://www.canva.com/d/mGa0Zh350SVob0n | https://www.canva.com/d/U4_fnCNvF5o3X8V |

| Feld | Wert |
|---|---|
| Ordner | https://www.canva.com/folder/FAHPt7Wvb8E |
| Quelldesign | `DAHP0Nu_IHE` |
| Englische Kopie | `DAHQznKIxTo` |
| Umfang | je 11 Folien |
| Kurzlink | https://canva.link/i5nbpdrwhbd4gvx |

Inhalt beider Decks: Titel und Status, Qualität und Verifikation, Release-Matrix 0.7.1, Artefakte und Prüfsummen, Architektur und Datenfluss, Browser-Erweiterung, Sprachdienst mit Sherpa und AudD, Mobile-Apps, nächste Schritte, Projektlinks.

Der Ordner ist damit **nicht mehr leer**; der v7-Vermerk „leer, keine Brand Kits" ist überholt. Brand Kits sind weiterhin nicht angelegt.

**Wichtig:** Das Einfügen der Canva-View-/Edit-Links in Linear-Kommentare wurde als Risiko abgelehnt, weil damit Zugriffslinks in ein externes System geschrieben würden. Die Links sind deshalb ausschließlich hier und im Canva-Ordner geführt.

---

## 7. Linear

Grundlage dieses Abschnitts ist der Live-Abgleich mit Linear vom 02.08.2026.

| Statusverteilung | Anzahl |
|---|---|
| `Done` | 44 |
| `In Review` | 1 |
| `In Progress` | 2 |
| `Todo` | 6 |
| `Backlog` | 7 |
| `Canceled` | 2 |

### 7.1 Offen ⚠️

| ID | Status | Priorität | Thema |
|---|---|---|---|
| [0PE-96](https://linear.app/0penclaw/issue/0PE-96) | `Todo` | `Urgent` | **0.8.0 Release-Gate** — Browser, Android und iOS vollständig konsolidieren; Zieltermin 08.08.2026, Meilenstein `Aug 8` |
| [0PE-93](https://linear.app/0penclaw/issue/0PE-93) | `Todo` | `High` | Browser: Pairing-, AudD- und Chat-Einstellungen über Einstellungsrad öffnen |
| [0PE-103](https://linear.app/0penclaw/issue/0PE-103) | `Todo` | `High` | Debugmodus: neue Komponenten und Elemente in Browser, Android und iOS erfassen |
| [0PE-99](https://linear.app/0penclaw/issue/0PE-99) | `Todo` | `Medium` | Untertitel: RAW-Datenstrom und JSON-Export für externe Verarbeitungssysteme |
| [0PE-100](https://linear.app/0penclaw/issue/0PE-100) | `Todo` | `Low` | Android: Songerkennung wirksam umsetzen und Installationspfad bereitstellen |
| [0PE-101](https://linear.app/0penclaw/issue/0PE-101) | `Todo` | `Low` | iOS: Songerkennung wirksam umsetzen und Installationspfad bereitstellen |
| [0PE-85](https://linear.app/0penclaw/issue/0PE-85) | `In Review` | `Medium` | Browser: VLC-Ersatz ersetzt den großen Videoframe nicht vollständig |
| [0PE-89](https://linear.app/0penclaw/issue/0PE-89) | `In Progress` | `High` | Browser: Vollbildmodus deaktiviert Sidepanel und aktives Vorlesen |
| [0PE-90](https://linear.app/0penclaw/issue/0PE-90) | `In Progress` | `High` | Browser: Tabs müssen vollständig getrennt arbeiten |
| [0PE-72](https://linear.app/0penclaw/issue/0PE-72) | `Backlog` | `High` | Browser: Songerkennung scheitert trotz gültigem AudD-/Pairing-Setup — wieder geöffnet |
| [0PE-95](https://linear.app/0penclaw/issue/0PE-95) | `Backlog` | `High` | iOS: `workflow:iOS` — 16 Workflow-Läufe prüfen und korrigieren |
| [0PE-58](https://linear.app/0penclaw/issue/0PE-58) | `Backlog` | `Medium` | Mobil: TikTok-Seitenelemente aus dem Videoframe ausblenden |
| [0PE-70](https://linear.app/0penclaw/issue/0PE-70) | `Backlog` | `Medium` | Mobil: Zweites Antippen muss die Vollbildansicht wieder schließen |
| [0PE-80](https://linear.app/0penclaw/issue/0PE-80) | `Backlog` | `Medium` | Mobil: Wiederkehrende Pop-ups unterbrechen laufende TikTok-Streams |
| [0PE-41](https://linear.app/0penclaw/issue/0PE-41) | `Backlog` | `Low` | Low/P3 — Bridge-Payloads byte-begrenzen |
| [0PE-43](https://linear.app/0penclaw/issue/0PE-43) | `Backlog` | `Low` | Low/P3 — gzip-Ausgabe und Decode-Parallelität begrenzen |

Fachliche Präzisierung:

- **0PE-96** ist das verbindliche Release-Gate für 0.8.0: einheitliche Softwareversion, Versions- und Buildnummern, Funktionen, Komponenten, Module, gemeinsame Bridge-Kopien, Installations- und Upgradeprozeduren sowie Konfigurations- und Debugpfade über alle drei Varianten. Ein vollständiger neuer nativer iOS-Actions-Lauf gehört verbindlich dazu.
- **0PE-93** ersetzt die frühere Vorgabe, Pairing- und AudD-Felder auszublenden. Rechts neben `Sherpa aktiv!` erscheint ein Einstellungsrad, das ein Pop-up nach dem Muster von `Zuschauer*innen` öffnet. Darin liegen `AudD API-Token`, `Pairing-Code`, ein vorbereiteter `Universal API-Key` sowie die drei verschobenen Checkboxen `Chatnamen sprechen`, `Chatnamen kürzen` und `Game-Mode`. Die beiden übrigen Checkboxen bleiben unverändert.
- **0PE-99** nutzt den in `0PE-93` vorbereiteten `Universal API-Key` und liefert Text, Daten, Quellen, Sprachen, Messages, Datenströme, Playertexte, Caption-Protokolle und JSON-Export.
- **0PE-100 / 0PE-101** orientieren sich am vorhandenen Setup des Sprachdienstes der Browsererweiterung: vorhandene native und alternative Erkennungswege prüfen, fehlende Shazam-Komponenten berücksichtigen, anwenderfreundlichen Installations- und Konfigurationspfad ausarbeiten.
- **0PE-72** ist wieder geöffnet: `Extension has not been invoked for the current page (see activeTab permission). Chrome pages cannot be captured.` — Berechtigungen wurden in Edge geprüft und freigegeben. Zusätzlich fehlt Shazam in der Browserversion.
- **0PE-95** trennt die drei aktuellen erfolgreichen Läufe (`#16` `2323a6f`, `#15` `bd4c206`, `#14` `34e0dbb`) von den 13 historisch fehlgeschlagenen.
- **0PE-85 / 0PE-89 / 0PE-90** sind implementiert; es fehlt jeweils nur die reale Browserabnahme.
- **0PE-41 / 0PE-43** sind die beiden Low/P3-Findings des formalen 0.5.0-Scans, Meilenstein `Security & Release Gate`.

### 7.1a Am 02.08.2026 abgeschlossen ✅

| ID | Thema | Nachweis |
|---|---|---|
| [0PE-97](https://linear.app/0penclaw/issue/0PE-97) | Browser: `VLC Ersatz` unter WebSocket-Hook rechts neben `Normal`; VLC bei Bedarf installieren | Browser `3476d17`; Windows-Installationspfad über den stabilen VideoLAN-x64-Installer mit SHA-256- und Authenticode-Prüfung |
| [0PE-98](https://linear.app/0penclaw/issue/0PE-98) | Browser: `LIVE-Informationen` direkt unter `Seiteninformationen` | Browser `3476d17` |
| [0PE-102](https://linear.app/0penclaw/issue/0PE-102) | Browser: Top-Chatter mit `mehr…`, `Reset` und Stummschaltung | Browser `3476d17`; 5 → 15 → 25 → 35 → 45 → max. 50, tab- und streambezogen |
| [0PE-94](https://linear.app/0penclaw/issue/0PE-94) | Android: bekannten Strukturtestfehler beheben | Android-Player-Bridge wiederhergestellt, Shared-Mobile-Kopie synchronisiert; Actions-Lauf `30752210199` mit `31/31` Tests; Branch `0bebb07`, getesteter Stand `8cd5c3d` |

### 7.1b Zuvor in der Sitzung abgeschlossen ✅

| ID | Status | Thema | Abgeschlossen |
|---|---|---|---|
| [0PE-73](https://linear.app/0penclaw/issue/0PE-73) | `Done` | Browser: Vorhandenes Dienst-Setup um npm start und Startbutton ergänzen | 2026-08-01 |
| [0PE-87](https://linear.app/0penclaw/issue/0PE-87) | `Done` | Browser: Sprachdienst installieren muss `setup.ps1` automatisch ausführen | 2026-08-01 |
| [0PE-78](https://linear.app/0penclaw/issue/0PE-78) | `Done` | Mobil: Hinweis zu temporären TikTok-Media-URLs ersatzlos entfernen | 2026-08-01 |
| [0PE-79](https://linear.app/0penclaw/issue/0PE-79) | `Done` | Mobil: Ausführlichen Hinweis im Tab Mehr ersatzlos entfernen | 2026-08-01 |
| [0PE-86](https://linear.app/0penclaw/issue/0PE-86) | `Done` | Vorlesen: fehlende Schriftsysteme über Sherpa-ONNX ergänzen | 2026-08-02 |
| [0PE-88](https://linear.app/0penclaw/issue/0PE-88) | `Done` | Browser: Sidepanel-Elemente in die vorgegebene Reihenfolge bringen | 2026-08-02 |

### 7.1b Neu erfasste Issues ✅

| ID | Status | Thema | Nachweis |
|---|---|---|---|
| [0PE-91](https://linear.app/0penclaw/issue/0PE-91) | `Done` | Vercel: iOS-Deployment bleibt im Dashboard auf „Building" | Deployments `dpl_U4Fjgw5cZAzumhZy6HgrkGznsY5M` und `dpl_82hQgMVHTa45fS68Qb2VxHQNkMAR` beide `READY`; serverseitig war kein Build mehr aktiv |
| [0PE-92](https://linear.app/0penclaw/issue/0PE-92) | `Done` | Browser: Sprachdienst-Start wirft `textContent`-Fehler | Ursache `service-setup-command` fehlte in der zentralen DOM-Elementzuordnung; Fix-Commit `29f1d8a`, Regressionstest ergänzt |
| [0PE-94](https://linear.app/0penclaw/issue/0PE-94) | `Todo` | Android: bekannter Strukturtestfehler der Android-Suite | 30 Tests, ein Fehler in `MobileUiStructureTest.mobilePlayerFocusUsesCenterFrameThenLiveOverviewAndPureFullscreen`; OPE-65/OPE-67 sind als fachlicher Bezug verknüpft |
| [0PE-95](https://linear.app/0penclaw/issue/0PE-95) | `Todo` | iOS: `workflow:iOS` mit 16 Workflow-Läufen prüfen und korrigieren | Vollständiger zweiter Screenshot angehängt; aktuelle grüne Läufe und historische Fehlversuche werden getrennt ausgewiesen |
| [0PE-96](https://linear.app/0penclaw/issue/0PE-96) | `Todo` | 0.8.0 Release-Gate: Browser, Android und iOS vollständig konsolidieren | Zieltermin 08.08.2026; vollständiger nativer iOS-Actions-Lauf ist verbindlicher Bestandteil |

### 7.2 Abgeschlossen ✅

Release- und Dokumentationsgate:

| ID | Thema | Abgeschlossen |
|---|---|---|
| [0PE-44](https://linear.app/0penclaw/issue/0PE-44) | Branch und unveränderte 0.5.0-Artefakte veröffentlichen | 2026-07-18 |
| [0PE-45](https://linear.app/0penclaw/issue/0PE-45) | Canva-Kopie ins Englische übersetzen | 2026-07-29 |
| [0PE-46](https://linear.app/0penclaw/issue/0PE-46) | DE/EN-Dokumentationssite fertigstellen | 2026-07-18 |
| [0PE-47](https://linear.app/0penclaw/issue/0PE-47) | Notion-Projektseite und sieben Unterseiten anlegen | 2026-07-18 |
| [0PE-48](https://linear.app/0penclaw/issue/0PE-48) | Canva-Präsentation DE erstellen und freigeben | 2026-07-29 |
| [0PE-49](https://linear.app/0penclaw/issue/0PE-49) | Vercel-Projekt verbinden und deployen | 2026-07-18 |
| [0PE-50](https://linear.app/0penclaw/issue/0PE-50) | Desktop-, Mobil-, Tastatur- und Download-QA abschließen | 2026-07-18 |
| [0PE-51](https://linear.app/0penclaw/issue/0PE-51) | Projektindex und alle Links synchronisieren | 2026-07-29 |

Mobil-Reihe mit Label `mobile`:

| ID | Thema | Abgeschlossen |
|---|---|---|
| [0PE-52](https://linear.app/0penclaw/issue/0PE-52) | Mobil: Chat-Tab bleibt leer — TTS nicht aktivierbar, TTS-Einstellungen unsichtbar | 2026-07-21 |
| [0PE-53](https://linear.app/0penclaw/issue/0PE-53) | Mobil: Song-Tab zeigt die drei Live-Status doppelt | 2026-07-21 |
| [0PE-54](https://linear.app/0penclaw/issue/0PE-54) | Mobil: Player-Tab „Vollbild" ohne Funktion; Pegelschutz-Einstellungen fehlen | 2026-07-21 |
| [0PE-55](https://linear.app/0penclaw/issue/0PE-55) | Mobil: „Force" (Tab Mehr) kehrt wegen Pop-ups nicht automatisch zum LIVE-Stream zurück | 2026-07-21 |
| [0PE-56](https://linear.app/0penclaw/issue/0PE-56) | Mobil: Querformat/flache Geräte — nur Menüband sichtbar, Inhalt nicht scrollbar | 2026-07-21 |
| [0PE-57](https://linear.app/0penclaw/issue/0PE-57) | Mobil: Fehlende Bereiche — Top-Chatter, LIVE-Informationen, Seiteninformationen | 2026-07-21 |
| [0PE-58](https://linear.app/0penclaw/issue/0PE-58) | Mobil: TikTok-Seitenelemente aus dem Videoframe ausblenden | 2026-07-21 |
| [0PE-59](https://linear.app/0penclaw/issue/0PE-59) | Mobil: LIVE-Stream nach explizitem Öffnen hörbar starten | 2026-07-21 |
| [0PE-60](https://linear.app/0penclaw/issue/0PE-60) | Mobil: erkannte Media-/VLC-URLs kopierbar anzeigen | 2026-07-21 |
| [0PE-61](https://linear.app/0penclaw/issue/0PE-61) | Mobil: Audio bei Appwechsel und Displaysperre fortsetzen | 2026-07-21 |
| [0PE-62](https://linear.app/0penclaw/issue/0PE-62) | Mobil: Chat- und LIVE-Tab-Inhalte korrekt zuordnen | 2026-07-21 |
| [0PE-63](https://linear.app/0penclaw/issue/0PE-63) | Mobil: Debugmodus ergänzen | 2026-07-21 |
| [0PE-64](https://linear.app/0penclaw/issue/0PE-64) | Mobil-Hotfix: Chat darf den Videoframe nicht übernehmen | 2026-07-29 |
| [0PE-65](https://linear.app/0penclaw/issue/0PE-65) | Mobil: In allen Ansichten wird die Homepage statt des mittleren LIVE-Video-Frames ausgewählt | 2026-07-22 |
| [0PE-66](https://linear.app/0penclaw/issue/0PE-66) | Mobil: TikTok-Cookie-Abfrage dauerhaft behandeln und Wiederholung verhindern | 2026-07-22 |
| [0PE-67](https://linear.app/0penclaw/issue/0PE-67) | Mobil: Vollbildansicht auf zuvor korrekte reine Player-Darstellung zurückführen | 2026-07-29 |

0.7.1-Reihe:

| ID | Label | Thema | Abgeschlossen |
|---|---|---|---|
| [0PE-68](https://linear.app/0penclaw/issue/0PE-68) | Feature | Game Mode filtert Nickname-Spam vor der Chat-Sprachausgabe | 2026-07-29 |
| [0PE-69](https://linear.app/0penclaw/issue/0PE-69) | Bug | Unmittelbare 1:1-Duplikate in der TTS-Ausgabe unterdrücken | 2026-07-29 |
| [0PE-70](https://linear.app/0penclaw/issue/0PE-70) | Bug, mobile | Mobil: Zweites Antippen muss die Vollbildansicht wieder schließen | 2026-07-29 |
| [0PE-72](https://linear.app/0penclaw/issue/0PE-72) | Bug | Browser: Songerkennung über vorhandenen lokalen Dienst und AudD reparieren | 2026-07-29 |
| [0PE-75](https://linear.app/0penclaw/issue/0PE-75) | Bug | Browser: Lautstärke und Pegelschutz mit positiven 0–100-Werten anzeigen | 2026-07-29 |
| [0PE-76](https://linear.app/0penclaw/issue/0PE-76) | Improvement | Browser: Qualitätsbox und wörtlich benannte Texte ersatzlos entfernen | 2026-07-29 |
| [0PE-77](https://linear.app/0penclaw/issue/0PE-77) | Bug | Dreistellige Teamabkürzungen werden beim Vorlesen wieder mitgesprochen | 2026-07-29 |
| [0PE-80](https://linear.app/0penclaw/issue/0PE-80) | Bug, mobile | Mobil: Wiederkehrende Pop-ups unterbrechen laufende TikTok-Streams | 2026-07-29 |
| [0PE-81](https://linear.app/0penclaw/issue/0PE-81) | Bug | Browser: Installierte Erweiterung zeigt weiterhin Version 0.7.0 | 2026-07-29 |
| [0PE-83](https://linear.app/0penclaw/issue/0PE-83) | — | iOS: GitHub-Actions-Workflow für Simulator-Build und Tests anlegen | 2026-07-29 |
| [0PE-84](https://linear.app/0penclaw/issue/0PE-84) | — | CI: Linear Releases automatisch aus GitHub Actions befüllen | 2026-07-29 |

### 7.3 Commit-Zuordnung der Mobil-Behebungen

| ID | Umsetzung | Android-Commit | iOS-Commit |
|---|---|---|---|
| 0PE-52 | Chat-Bridge, 50er-Grenze, persistente TTS-Kernoptionen, Fünfer-Queue | `3a42427` | `75da436` |
| 0PE-53 | Capability-Status ausschließlich im LIVE-Tab, Strukturtest ergänzt | `8f0844c` | `30e6ffa` |
| 0PE-54 | Nativer Vollbildmodus, Pegelschutz, PiP entfernt, Audio ohne Doppelausgabe | `962fd56` | `cc88da9` |
| 0PE-55 | Force-Retries, Popup-Behandlung, 20-s-Watchdog, manuelle Recovery | `80ec203` | `8b05d76` |
| 0PE-56 | Querformat mit 96-dp/pt-Inhaltsreserve und Scroll-Unterstützung | `801f7b0` | `ff46ce4` |
| 0PE-57 | Top-Chatter, 5.000er-Limit, vollständige LIVE- und Seiteninformationen | `3fec8da` | `d45c1bf` |

### 7.4 Vollbild-Rückkehr in Linear erfasst

| Befund | Plattform | Beschreibung |
|---|---|---|
| Vollbild-Rückkehr verliert die Erweiterung | Edge / Chrome | Als `0PE-89` in `In Progress` erfasst; Offscreen-TTS und Wiederherstellung aus dem Tabzustand sind implementiert, reale Browserabnahme steht aus. |

Der Befund ist das Browser-Gegenstück zum mobilen `0PE-70` und wird unter `0PE-89` geführt.

### 7.4a Neu in Linear erfasst

| Befund | Quelle | Status |
|---|---|---|
| [0PE-93](https://linear.app/0penclaw/issue/0PE-93) Pairing- und AudD-Felder bleiben bei aktivem Sprachdienst und Sherpa sichtbar statt ausgeblendet | Nutzeranforderung und Screenshot vom 02.08.2026 | ✅ CSS-Ursache mit Browser-Commit `f44f946` veröffentlicht |

Der nachgereichte Export `tiktok-live-companion-debug-2026-08-02T07-08-45-137Z.json` ist ausschließlich ein Funktionsnachweis. Seine Unterbrechungen durch Tab-/Streamwechsel und erneutes Aktivieren des Debugmodus werden nicht als Fehler oder Dauerlauf gewertet.

### 7.5 Nicht weiterverfolgt

| ID | Status | Thema |
|---|---|---|
| 0PE-74 | `Canceled` | Release-Gate: einheitlicher Stand aller Apps, Plugins, Skills und Module |
| [0PE-42](https://linear.app/0penclaw/issue/0PE-42) | `Canceled` | Formalen Security-Scan abschließen — vom Nutzer am 01.08.2026 abgebrochen. Das bereits erstellte Seal für 0.7.1 (`security-scan/0.7.1/report.md`) bleibt gültig; ein zweiter Scan wurde nicht fertiggestellt. |

### 7.6 Linear-Meilensteine

| Meilenstein | Inhalt | Fortschritt |
|---|---|---|
| Security & Release Gate | Formaler Scan, Findings-Validierung, Freigabe der unveränderten 0.5.0-Artefakte | 33 % (Projektupdate 18.07.) |
| Dokumentation & Website | Zweisprachige Dokumentation, statische Vite-Site, barrierearme Browser-QA | 100 % |
| Veröffentlichung & Integrationen | GitHub, Notion, Canva, Vercel, systemübergreifende Link-Synchronisierung | 58 % (Projektupdate 18.07.) |

Projektstatus laut letztem Update vom 18.07.2026: 🟡 **At risk**, Priorität `High`. Die Prozentwerte sind seit diesem Update nicht neu erhoben.

### 7.7 Linear-Kennungen

| Feld | Wert |
|---|---|
| Projekt | `TikTok LIVE Companion` (`501de42c-ccb0-4470-9226-4e93c4301fce`) |
| Team | `0penClaw` (`da801f77-5ed3-4b38-9916-2e0257a17628`) |
| Nutzer, Lead, Assignee | `karimkiki@gmx.de` (`02822537-91ba-4793-b22f-a1b724ecbf06`) |
| Statuswerte | `Backlog`, `Todo`, `In Progress`, `In Review`, `Done`, `Canceled`, `Duplicate` |
| Labels | `mobile`, `Feature`, `Bug`, `Improvement` |
| Meilenstein-ID Veröffentlichung | `7dd0a17f-5b83-4fd1-8423-4f0787e74e9a` |
---

## 8. Dienst-Erreichbarkeiten

### Lokaler Companion-Service 🔒

| Endpunkt | Zweck |
|---|---|
| `http://127.0.0.1:43117` | Basisadresse |
| `GET /v1/health` | Statusprüfung inklusive `sherpaConfigured` |
| `GET /v1/voices` | verfügbare Stimmen mit Kultur, Geschlecht, Alter |
| `GET /v1/config` | Dienstkonfiguration ohne Geheimnisse |
| `POST /v1/tts` | Text und Stimm-ID → `audio/wav` |
| `POST /v1/sherpa` | Sherpa-ONNX installieren und Status abfragen |
| `POST /v1/recognize` | Audioausschnitt → Songdaten |

Bindet ausschließlich an Loopback, Node.js ab Version 20. Die Erweiterung akzeptiert nur `127.0.0.1` oder `localhost`. Zugriff erfordert einen generierten Pairing-Code. Startwege: Sidepanel-Button, Protokollhandler `tiktok-live-companion://start`, Fallback `npm start`.

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
| Pairing-Code, Dienstadresse | `chrome.storage.local` |
| Stimmauswahl, Lautstärke, Schutzstärke, Game Mode | `chrome.storage.local` |
| AudD-Token | Dienstkonfiguration unter `%LOCALAPPDATA%` |
| Sherpa-ONNX-Modelldateien | lokaler Dienstpfad, nicht eingecheckt |
| Stream-, Chat-, Caption-, Teilnehmerdaten | `chrome.storage.session` (flüchtig, pro Tab) |
| Einstellungen, dauerhafte Mutes (Browser) | `chrome.storage.local` |
| Erkennungsquelle, dauerhafte Mutes (iOS) | UserDefaults |
| Erkennungsquelle, dauerhafte Mutes (Android) | DataStore |
| Apple Team-ID, Key-ID, Media-ID, privater Schlüssel | ausschließlich Vercel-Umgebungsvariablen |
| ShazamKit-AAR | `mobile/android/app/libs/`, nicht eingecheckt |

---

## 9. Repository-Struktur ✅

Basis: `.publish-repo/`

| Pfad | Inhalt |
|---|---|
| `README.md` | Projektüberblick 0.7.1, Schnellstart, Verifikationsbefehle |
| `plugin-source/browser-extension/` | kanonische Erweiterungsquellen |
| `plugin-source/companion-service/` | lokaler Windows-Dienst inklusive Sherpa-Installer |
| `plugin-source/mobile-shared/` | gemeinsame WebView-Bridge und Ergebnisschema |
| `plugin-source/scripts/` | Test- und Packaging-Skripte |
| `plugin-source/tests/` | Sidepanel-Harness |
| `plugin-source/skills/` | Codex-Skillbeschreibung |
| `plugin-source/references/architecture.md` | technische Architekturreferenz |
| `plugin-source/SECURITY.md` | Sicherheitsbeschreibung |
| `mobile/ios/` | SwiftUI-App, Xcode-Projekt, geteiltes Scheme, XCTest |
| `mobile/android/` | Compose-App, Gradle-Projekt, JUnit/Robolectric |
| `docs/de/`, `docs/en/` | zweisprachige Dokumentation, je sieben Kapitel |
| `docs/*_v6_utf8bom.md`, `docs/*_v7_utf8bom.md` | archivierte Dokumentrevisionen |
| `docs/diagrams/architecture.mmd` | Mermaid-Quelle |
| `docs/diagrams/tiktok-live-companion-architecture.svg` | reproduzierbares statisches Architekturvisual |
| `docs/diagrams/tiktok-live-companion-architecture.gif` | reproduzierbares rotierendes 36-Frame-Visual |
| `docs/diagrams/tiktok-live-companion-visualization-contract.md` | verbindlicher Visualisierungsvertrag und Textalternative |
| `docs/mobile/mobile-0.7.0-concept.png` | freigegebener Mobile-Entwurf, unverändert gültig |
| `assets/flow_model.py` | gemeinsames Modell für SVG, GIF und Three.js |
| `site/` | React-/TypeScript-/Vite-Dokumentationssite |
| `site/api/` | Vercel-Funktionen |
| `site/public/visualizations/` | öffentlich ausgeliefertes Modell sowie SVG-/GIF-Fallbacks |
| `site/public/downloads/` | Downloadkopien 0.5.0 bis 0.7.1 |
| `release/0.7.1/` | aktuelle Artefakte und Prüfsummen |
| `release/0.7.0/`, `release/0.6.0/`, `release/` | frühere Artefakte |
| `security-scan/` | Threat Models, Findings, Release-Reviews |
| `.github/workflows/` | `linear-release-sync.yml`; auf dem iOS-Branch zusätzlich `ios.yml` |

### Browser-Erweiterung, Dateiliste

`manifest.json` · `background.js` · `content-core.js` · `content.js` · `hook.js` · `popup-guard.js` · `proto-main.js` · `sidepanel.html` · `sidepanel.css` · `sidepanel.js`

`popup-guard.js` ist mit 0.7.1 neu hinzugekommen.

### Companion-Service, Dateiliste

`package.json` (`version 0.7.1`, `node >=20`) · `server.mjs` · `setup.ps1` · `install-sherpa.ps1` · `voices.ps1` · `synthesize.ps1` · `README.md` · `test/service.test.mjs`

### Test- und Packaging-Skripte

| Datei | Zweck |
|---|---|
| `plugin-source/scripts/test_extension.cjs` | Extension-Struktur, Decoder, entfernte Texte, 0–100-Regler |
| `plugin-source/scripts/test_mobile_bridge.cjs` | Bridge-Schema, Grenzen, Dedupe-Fenster |
| `plugin-source/scripts/test_mobile_projects.py` | native Projektprüfung inklusive XCTest-Membership |
| `plugin-source/scripts/package_artifacts.py` | Release-Paketierung |
| `plugin-source/companion-service/test/service.test.mjs` | Dienst-Endpunkte |
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

## 10. Release-Artefakte und Prüfsummen

### 0.7.1 ✅ · `release/0.7.1/`

**Veröffentlichter Endstand · Browser `809de33`, Android `0bebb07`, iOS `6efa242`**

| Artefakt | SHA-256 |
|---|---|
| `tiktok-live-companion-extension-0.7.1.zip` | `67e61580df9309844901b6c73bd1e63aad5dc08df2dd698d4de8fdf856936725` |
| `tiktok-live-companion-plugin-0.7.1.zip` | `6f8b0334240d1e3c0b9ff2ba012d87c63102b54c5b2e4dc992294cbffa3f9894` |
| `tiktok-live-companion-service-0.7.1.zip` | `53370c64966ba6f323f276e5b9c305968533e0cc513c11b8e78b4dbbe6947ce2` |
| `tiktok-live-companion-ios-0.7.1-source.zip` | `8aecd3fb450f9e0c00d67fe10dd9de41bae82a099d689709627012204a79c1cf` |
| `tiktok-live-companion-android-0.7.1-source.zip` | `b9547af7c086f72f76999a4ddcb34f04f50dedc24113d3a9892218102ec52583` |
| `tiktok-live-companion-android-0.7.1.apk` | `dcbda38884534a899cc71c0a5fdfbba302153f3b478065cbbc75f6f3d275c65d` |

Reproduktionsverzeichnis: `.publish-repo/.artifacts/0.7.1-ope94-20260802/`. APK-Größe `119.648.191` Bytes. Eine verlustfreie Komprimierung der nativen Bibliotheken wurde verworfen, weil sie das Paket um `3.793` Bytes vergrößerte; R8 und Resource-Shrinking wurden ohne Verlustfreiheitsnachweis nicht aktiviert.

**Vorheriger Zwischenstand · Commit `f44f946` (`0PE-93`)**

| Artefakt | SHA-256 |
|---|---|
| `tiktok-live-companion-extension-0.7.1.zip` | `7ef3070c93be727a7669512a655a27858e5745646ebeecdd8d1a32e675f2efa4` |
| `tiktok-live-companion-plugin-0.7.1.zip` | `77a29bbda6b131f5646ebcded88bff1af62d7b5f2a55fb4243fc7c251841a477` |
| `tiktok-live-companion-service-0.7.1.zip` | `c48af6d574ecd7169bb0312093fa2cef53cda6ac8306c7ec3c2c01fe6a2d0ed5` |
| `tiktok-live-companion-ios-0.7.1-source.zip` | `ef70b876ba02a13b00f91a426ffb1eb91e3da0643311e9119afb31ba7ba7d302` |
| `tiktok-live-companion-android-0.7.1-source.zip` | `98910a52f101b98be2a8c43d972fc656c0a7ada1ce4bcf06ae169386ceddec2f` |
| `tiktok-live-companion-android-0.7.1.apk` | `ebda082ac39b441483ec9472e130bf104ef743335864a14bc42378f8196d734d` |

Der Stand liegt in `release/0.7.1/`, den Website-Downloads und in der Projektwurzel. Zwei unabhängige Paketläufe waren bytegleich. Die Browser-Assets wurden im bestehenden Alpha-Release ersetzt; Android- und iOS-Artefakte blieben bytegleich.

Prüfsummendatei: `release/0.7.1/tiktok-live-companion-0.7.1-SHA256.txt`, identisch als `tiktok-live-companion-0.7.1-SHA256.txt` in der Projektwurzel; die Kopie unter `site/public/downloads/` führt weiterhin den veröffentlichten Stand.

Alle sechs Werte wurden am 02.08.2026 in zwei unabhängigen Paketläufen bytegleich reproduziert und gegen `release/0.7.1/` geprüft. GitHub Releases und GHCR sind aktualisiert. Produktionsdeployment `dpl_DX2zq2nHYu5VPSbs6FUkqq9sx386` für Commit `f44f946` ist `READY`. Die Archive wurden automatisiert darauf geprüft, dass sie weder ShazamKit-AAR noch `.p8`-Schlüssel noch Build-Caches enthalten.

Der Sidepanel-Hotfix für den fehlenden `service-setup-command`-DOM-Bezug wurde anschließend erneut reproduzierbar paketiert. Für Extension und Plugin gelten deshalb die aktualisierten SHA-256-Werte in der Tabelle; Mobile-, Dienst- und APK-Bytes bleiben unverändert.

Die APK trägt die Package-ID `app.tiktoklivecompanion.android` und überschreibt damit eine vorhandene Installation. Frühere `-mock-debug`- und `.test`-Varianten wurden entfernt.

**Kein IPA** — unter Windows ist weder ein Xcode-Build noch eine Apple-Signierung möglich.

### 0.7.0 · `release/0.7.0/`

| Artefakt | SHA-256 |
|---|---|
| `tiktok-live-companion-extension-0.7.0.zip` | `a3c818eb63179ad1c0d5896c5bac8263bab0c6732c8621cbcafbd847d5a50b42` |
| `tiktok-live-companion-plugin-0.7.0.zip` | `4644ebf46bbd363edd499a16afc49b9ac7fa2c5cf03a1bae5149614ccbefb3b9` |
| `tiktok-live-companion-service-0.7.0.zip` | `4bb5df40229c72a0e93ab822709182542d31846cc865f89962da3769e652fd1c` |
| `tiktok-live-companion-ios-0.7.0-source.zip` | `3b833ea2969487ea9a82571478a4f273f3e678cffb6a11bde51e94ee0e5bbff3` |
| `tiktok-live-companion-android-0.7.0-source.zip` | `62e57e5d901ffb581fc40dc8a47454fb7e46531c57ffdbd71b82b071f76ad594` |
| `tiktok-live-companion-android-0.7.0-debug.apk` | `00f8df107107661c5bb6204f0fedb9d1f485fdbe5085f19f27e0f8089481d0f5` |

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

### Downloadkopien der Website ✅

`site/public/downloads/` enthält die Artefakte von 0.5.0 bis 0.7.1 einschließlich APK und aller vier Prüfsummendateien. Alle 0.7.1-Downloads wurden auf HTTP 200 und bytegenaue SHA-256-Gleichheit geprüft.

---

## 11. Entwicklungsumgebung, CI und Übertragung

### Websuche in Entwicklungsumgebung und Docker ✅

| Feld | Wert |
|---|---|
| Primäre Websuche | **Perplexity Pro** — dauerhaft in CDE und lokalem Docker |
| Rückfall | Tavily |
| Übergabe | Umgebungsvariable `PERPLEXITY_API_KEY` im Container |
| Prüfung | erfolgreicher Aufruf gegen `https://api.perplexity.ai/search` ohne Offenlegung des Wertes |
| Vault-Passphrase | ⚠️ wird ausdrücklich **nicht** verwendet; die zur Prüfung gesetzte Benutzer-Umgebungsvariable wurde wieder entfernt |

### Persistente Container-Umgebung 🔒

| Feld | Wert |
|---|---|
| Container | `tlc-cde-cde-1` |
| Image | `tlc-cde:full` |
| Restart-Policy | `unless-stopped` |
| Compose-Datei | `.cde-current.compose.yml` |
| Arbeitsverzeichnis | `.publish-repo` als `/workspace` |
| Android-SDK | `ANDROID_HOME=/opt/android-sdk`, Java 17, Build-Tools 35 |
| Persistente Volumes | `tlc-cde_tlc-android-sdk` → `/opt/android-sdk`, `tlc-gradle-cache`, `tlc-site-node-modules` |
| Site-Vorschau | http://localhost:5173/de (HTTP 200) |
| Enthaltene CLIs | `gh`, `vercel` (per `docker commit` festgeschrieben) |

**Docker Desktop 4.84.0, Engine läuft.** Weitere sichtbare Container neben der CDE: `telegram-monitor` (`8765`), `onboardingandp` mit `frontend-1` (`node:22-alpine`, `3000`) und `backend-1` (`8000`) — alle gestoppt und fachfremd, sie bleiben unangetastet.

Lokale Windows-CLIs: `gh 2.76.2`, `vercel 58.3.0`. `gh` wurde ohne `winget` über das offizielle Release-ZIP mit `gh.cmd`/`gh.ps1`-Wrappern in `C:\Users\silve\AppData\Roaming\npm` eingerichtet.

### GitHub-Actions-Workflows

| Workflow | Branch | Status |
|---|---|---|
| `.github/workflows/ios.yml` | `TikTok-Live-Companion-iOS` | ✅ OPE-83: vollständiger nativer Simulator-Build und Tests, Run `30717416888`, Commit `2323a6f`, `success`; die Liste mit 16 Läufen wird getrennt in OPE-95 nachgearbeitet |
| `.github/workflows/linear-release-sync.yml` | Browser `f44f946` | ✅ Run `30742243393`, `success` |
| `.github/workflows/linear-release-sync.yml` | Android `b3d1770`, iOS `0a4fc63` | ⚠️ Runs `30742462119` / `30742461997` planbedingt ohne `LINEAR_ACCESS_KEY` fehlgeschlagen; kein Produktcode-Fehler |
| `workflow:iOS` | iOS `6efa242` | ✅ Run `30748478805`, vollständiger nativer Lauf `success` |
| `workflow:Android` | Android `fe3cd84` | ⚠️ Run `30748539909`: APK gebaut, Abbruch ausschließlich am getrennt geführten `0PE-94`-Strukturgate |
| `workflow:Android` (Asset-Übernahme) | Android `fe3cd84` | ✅ Run `30749884929` übernahm das APK-Artefakt ohne Neubau in das bestehende Prerelease |
| `workflow:Android` | Android `0bebb07` | ✅ Run `30752210199`, `31/31` Tests, Shared-Mobile-Verträge und APK-Build erfolgreich |

Direktlinks:
- https://github.com/KikiKari/Projects/blob/TikTok-Live-Companion-iOS/.github/workflows/ios.yml
- https://github.com/KikiKari/Projects/blob/TikTok-Live-Companion-iOS/mobile/ios/TikTokLiveCompanion.xcodeproj/xcshareddata/xcschemes/TikTokLiveCompanion.xcscheme

Der iOS-Workflow läuft auf `macos-15`, Timeout 30 Minuten, ohne Secrets und mit `CODE_SIGNING_ALLOWED=NO`. Der Linear-Sync benötigt das GitHub-Secret `LINEAR_ACCESS_KEY`, das ohne Linear-Business-Plan nicht erzeugt werden kann.

### Tailnet und Übertragung 🔒

Tailnet `kikikari.github`, 7 Maschinen, Expiry für alle deaktiviert.

| Maschine | Adresse | Plattform | Bemerkung |
|---|---|---|---|
| `claude-sandbox` | `100.73.106.108` | Linux 6.18.5, Tailscale 1.98.8 | SSH; bei Bedarf als zusätzliche Ausführungsumgebung verfügbar |
| `lenovo-node7` | `100.103.140.35` | Windows 11 25H2, 1.98.10 | Arbeitsplatz mit Projektwurzel und CDE |
| `openclaw-node2` | `100.109.255.27` | Linux 7.0.0-28-generic, 1.98.4 | SSH |
| `openclaw-node3` | `100.73.154.125` | Linux 4.18.0-553, 1.98.10 | SSH |
| `v2202604104722446711` | `100.64.80.9` | Linux 7.0.0-28-generic, 1.92.5 | SSH |
| `v2202604104722449961` | `100.82.198.122` | Linux 7.0.0-27-generic, 1.92.5 | SSH |
| `redmi-note-11s` | `100.94.134.39` | Android 13, 1.98.8 | ✅ Taildrop-Ziel der APK |

| Feld | Wert |
|---|---|
| Taildrop-Ziel | `redmi-note-11s` · `100.94.134.39` |
| Übertragene Datei | `tiktok-live-companion-android-0.7.1.apk` |
| Ergebnis | ✅ Exit-Code `0`, zuletzt nach `0PE-94` wiederholt |

---

## 12. Vercel

| Feld | Wert |
|---|---|
| Team | `OpenClaw's projects` (`team_AHshglW3k9jPfdsJXOGjTwxP`) |
| Projekt | `tiktok-live-companion` (`prj_p7gF1qSWrkzsacutq9ZPY9KX13eP`) |
| Produktionsbranch | `TikTok-Live-Companion` |
| Root Directory | `site` |
| Production | ✅ `Ready` |
| Produkt-Deployment | ✅ `dpl_3Ls7APNmduNotHr52gnAfbySrAH7`, Endstand `0PE-97`/`0PE-98`/`0PE-102`, Ziel `production`, `READY` |
| Release-Deployment | ✅ `dpl_9xkFZBKZexpPYyM4oqG1bdPcSsrx`, Commit `4fda3fd`, Ziel `production`, `READY` |
| Früheres Produkt-Deployment | ✅ `dpl_DX2zq2nHYu5VPSbs6FUkqq9sx386`, Commit `f44f946`, Ziel `production`, `READY` |
| Dokumentations-Deployment | ✅ `dpl_76mjqgPmG6DF6NSADmvKqURfFyNN`, Commit `8039ae4`, Ziel `production`, `READY` |
| Mobile-Dokumentationspreviews | ✅ Android `dpl_D4UXqfTUxozxy9gN4amD9dEaGUoz` (`03a0488`) und iOS `dpl_BR5STRXgE5gtqsTDbM6vt7a98JvD` (`80957a4`), beide `READY` |
| Native iOS-Abnahme | ✅ Nicht Vercel: `0PE-83` / GitHub Actions Run `30717416888` (`2323a6f`) und zuletzt Run `30748478805` (`6efa242`), jeweils vollständiger Simulator-Build und Tests `success`. Der iOS-Branch bleibt bei Vercel ein reines `READY`-Dokumentationspreview |
| Dashboard-Issue | [0PE-91](https://linear.app/0penclaw/issue/0PE-91/071-vercel-ios-deployment-bleibt-im-dashboard-auf-building) — Serverstatus und Logs waren bereits erfolgreich; veraltete „Building“-Anzeige dokumentiert |
| Inspector | https://vercel.com/openclaw-vercel-project/tiktok-live-companion |
| Funktionen | `/api/shazam-token` |
| Interaktive Architektur | `/de/architecture-3d`, `/en/architecture-3d` |
| Visualisierungsdateien | `/visualizations/tiktok-live-companion-architecture.svg`, `.gif`, `tiktok-live-companion-flow-model.json` |
| Downloads | `/downloads/…` für 0.5.0 bis 0.7.1 |
| Branch-Alias Browser | `tiktok-live-companion-git-tiktok-0d875b-openclaw-vercel-project.vercel.app` |
| Branch-Alias Android | `tiktok-live-companion-git-tiktok-5f8bc1-openclaw-vercel-project.vercel.app` |
| Branch-Alias iOS | `tiktok-live-companion-git-tiktok-b8d0c9-openclaw-vercel-project.vercel.app` |

---

## 13. Externe Referenzen

| Ressource | Adresse | Bezug |
|---|---|---|
| VideoLAN VLC | https://github.com/videolan/vlc | verbindliche Quelle für `0PE-97`, Branch `master` |
| VideoLAN GitLab | https://code.videolan.org/videolan/vlc | zweite verbindliche Quelle, Branch `master` |
| VLC-Downloads Windows | https://get.videolan.org/vlc/last/win64/ | ausschließlich stabiler x64-Installer, keine Beta |
| VLC für Android | https://github.com/videolan/vlc-android | `org.videolan.android:libvlc-all:3.7.5` |
| VLCKit für iOS | https://github.com/videolan/vlckit | `MobileVLCKit 3.7.3` |
| Android JNI-Library-Packaging | https://developer.android.com/reference/tools/gradle-api/8.4/com/android/build/api/dsl/JniLibsPackaging | Grundlage der APK-Größenbewertung |
| Perplexity API | https://api.perplexity.ai/search | primäre Websuche in CDE und Docker |
| AudD Datei-/URL-Erkennung | https://docs.audd.io/ | Songerkennung im Browser |
| AudD Dashboard | https://dashboard.audd.io/ | Token-Verwaltung |
| Shazam | https://www.shazam.com/ | Katalogreferenz |
| Apple ShazamKit | https://developer.apple.com/shazamkit/ | mobile Songerkennung |
| ShazamKit Android SDK | https://developer.apple.com/shazamkit/android/index.html | Android-AAR, Kotlin, minSdk 21 |
| SHSession | https://developer.apple.com/documentation/shazamkit/shsession/ | Erkennungssitzung |
| WKUserScript | https://developer.apple.com/documentation/webkit/wkuserscriptinjectiontime | Dokumentstart-Injektion iOS |
| Apple Media-ID und Schlüssel | https://developer.apple.com/help/account/capabilities/create-a-media-identifier-and-private-key | Developer-Token |
| Android WebView-Sicherheit | https://developer.android.com/privacy-and-security/risks/insecure-webview-native-bridges | Bridge-Härtung |
| Origin-beschränkte Bridge | https://developer.android.com/develop/ui/views/layout/webapps/native-api-access-jsbridge | Bridge-Design |
| sherpa-onnx | https://github.com/k2-fsa/sherpa-onnx | lokale Sprachsynthese |
| sherpa-onnx TTS | https://k2-fsa.github.io/sherpa/onnx/tts/index.html | Stimmen und Modelle |
| sherpa-onnx Installation | https://k2-fsa.github.io/sherpa/onnx/install/index.html | Installer-Grundlage |
| sherpa-onnx Android | https://k2-fsa.github.io/sherpa/onnx/android/index.html | mobile Referenz |
| sherpa-onnx iOS | https://k2-fsa.github.io/sherpa/onnx/ios/index.html | mobile Referenz |
| ElevenLabs API | https://elevenlabs.io/app/api | optionale Premium-Stimme, nicht ausgeliefert |
| VLC | https://github.com/videolan/vlc | Wiedergabe extrahierter Stream-Links |
| VLC 3.0 | https://github.com/videolan/vlc-3.0 | Kompatibilitätsreferenz |
| VLC Entwicklerseite | https://images.videolan.org/developers/vlc.html | Wiedergabeparameter |
| GitHub Actions | https://docs.github.com/de/actions | CI-Grundlage |
| GitHub REST Repos | https://docs.github.com/rest/repos | Branch- und Sichtbarkeitsprüfung |
| GitHub REST Codespaces | https://docs.github.com/en/rest/codespaces | Umgebungsverwaltung |
| GitHub Packages Sichtbarkeit | https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility | GHCR-Freischaltung |
| Docker AI Sandboxes | https://docs.docker.com/ai/sandboxes/ | Container-Entwicklungsumgebung |
| Docker Sandboxes für Codex | https://docs.docker.com/ai/sandboxes/agents/codex/ | Agent-Anbindung |
| Composio Docker Hub Toolkit | https://composio.dev/toolkits/docker_hub/framework/codex | Registry-Anbindung |

---

## 14. Codex-Sitzungen

| Version | Sitzungs-ID |
|---|---|
| 0.6.0 | `019f7492-6d71-7a91-88d7-4c87cedec9f0` |
| 0.7.0 | `019f7561-ade5-72e3-85e8-75c75b88ca06` |
| 0.7.1 (Extension-Fortsetzung) | `019f9957-6532-7483-adbf-56aceeb5c310` |
| 0.7.1 (Versions- und Branchprüfung, Umsetzung der neun aktiven Issues) | `019fbedc-9c0a-79c2-810f-8a32946de772` |

Deeplink-Schema: `codex://threads/<Sitzungs-ID>`
Visualisierungen: `~/.codex/visualizations/<Jahr>/<Monat>/<Tag>/<Sitzungs-ID>/`

### Sitzungsprotokolle im Arbeitsverzeichnis

| Datei | Inhalt |
|---|---|
| `Arbeitsstand der Extension fortset.md` | Fortsetzung ab dem 26.07.2026 17:34, Konsolidierung 0.7.1, Releases, GHCR, Notion, Canva |
| `Erweiterung und Sprachdienst aktual.md` | Sprachdienst, Sherpa, AudD, Pegelschutz, TTS-Dedupe |
| `Behebe sechs Mobil-Issues.md` | 0PE-52 bis 0PE-57 |
| `Erweitere Version 0.7.0 für iOS und.md` | Mobile-Ausbau |
| `Add iOS Cl simulator workflow.md` | 0PE-83, iOS-Workflow und geteiltes Scheme |
| `Automatisiere Linear Releases in Cl.md` | 0PE-84, Linear-Release-Sync und Plan-Blocker |
| `Browserplugin-Start und Hook repari.md` | Startbutton und Hook-Reparatur |
| `Prüfe Version 0.7.1 und Branches-Vervollständigung V8.md` | Sitzung `019fbedc-…`, vollständiger Verlauf bis 02.08.2026 17:00: `0PE-93` bis `0PE-103`, VLC-Umplatzierung und -Installation, Top-Chatter-Erweiterung, Android-Strukturtestbehebung, Perplexity-Priorisierung |
| `Codex Session Log_Prüfe Version 0.7.1 und Branches.md` | Sitzung `019fbedc-…`: Bestandsaufnahme aller Branches, Umsetzung der aktiven 0.7.1-Issues, Release bis `f44f946`, Sidepanel- und Installations-Hotfixes, Stimmen-Gruppierung, 500 Chatzeilen, AudD-Beschriftungen, CMD-Installation |

### Referenzbilder

| Bild | Bezug |
|---|---|
| `docs/mobile/mobile-0.7.0-concept.png` | freigegebener Mobile-Entwurf, weiterhin verbindlich |
| `docs/diagrams/tiktok-live-companion-architecture.svg` | generierte statische Plattformarchitektur |
| `docs/diagrams/tiktok-live-companion-architecture.gif` | generierte animierte Plattformarchitektur |
| `tiktok-live-companion-0.6.0-sidepanel.png` | Sidepanel-Abnahme |
| `tiktok-live-companion-0.6.0-audience-modal.png` | Zuschauerübersicht |
| `site-0.7.0-desktop.png` | Website Desktop |
| `site-0.7.0-mobile-final.png` | Website 390 px nach Härtung |

---

## 15. Offene Punkte

| # | Punkt | Verantwortung | Status |
|---|---|---|---|
| 1 | **Reale Browserabnahme** für Zwei-Tab, Embed und Vollbild mit laufender TTS (0PE-85, 0PE-89, 0PE-90) | Entwicklung / Nutzer | ⚠️ implementiert; Abnahme offen. Die lokale Extensiondatei wurde vom in-app Browser gemäß URL-Sicherheitsrichtlinie nicht geöffnet, eine Umgehung wurde nicht vorgenommen |
| 2 | **Veröffentlichter Folgestand vom 02.08.2026** — 500 Chatzeilen, Chat-Popup, Auto-Chat Refresh, Checkbox-Anordnung, Stimmen-Gruppierung, AudD-Beschriftungen, Feld-Ausblendung, Validierung, CMD-Installation, `localService`-Debugfelder | Entwicklung | ✅ Browser `f44f946`, Android `b3d1770`, iOS `0a4fc63`; Releases, GHCR und Vercel aktualisiert |
| 3 | [0PE-93](https://linear.app/0penclaw/issue/0PE-93): Pairing- und AudD-Felder bleiben bei aktivem Sprachdienst und Sherpa sichtbar | Entwicklung | ✅ CSS-Fix mit `f44f946` veröffentlicht |
| 4 | 0PE-41 und 0PE-43 umsetzen | Entwicklung | ⚠️ `Todo` |
| 5 | Mobile Backlog-Issues 0PE-58, 0PE-70 und 0PE-80 bearbeiten | Entwicklung | ⚠️ `Backlog` |
| 6 | Zweiter formaler Security-Scan (0PE-42) | Security | ⚠️ `Canceled` auf Nutzeranweisung; das Seal für 0.7.1 mit 0 Critical, 0 High, 0 Medium und 2 behobenen Low/P3 bleibt gültig |
| 7 | [0PE-94](https://linear.app/0penclaw/issue/0PE-94): Android-Gesamtsuite normalisieren | Entwicklung | ✅ `Done` — Player-Bridge wiederhergestellt, Shared-Mobile-Kopie synchronisiert, Run `30752210199` mit `31/31` Tests |
| 8 | [0PE-95](https://linear.app/0penclaw/issue/0PE-95): 16 iOS-Workflow-Läufe prüfen und korrigieren | Entwicklung | ⚠️ `Backlog`, `High`; die Läufe `30717416888` und `30748478805` sind erfolgreich, 13 historische Läufe bleiben offen |
| 9 | Apple-Capability, Media-ID, privaten Schlüssel und ShazamKit-AAR bereitstellen | Nutzer | ⚠️ offen |
| 10 | Shazam-Produktvariante bauen statt Mock-APK | Entwicklung | ⚠️ hängt an Punkt 9 |
| 11 | Echter AudD-Aufruf am realen LIVE-Stream | Nutzer | ⚠️ kein Token im Prüflauf |
| 12 | Linear-Release-Sync aktivieren (`LINEAR_ACCESS_KEY`) | Nutzer | ⚠️ Business-Plan erforderlich; der Workflow endet ohne Secret als ausdrücklicher Skip |
| 13 | Canva Brand Kits anlegen | Nutzer | ⚠️ Entscheidung |
| 14 | Mobile-Entwurfsbild auf 0.8.0 fortschreiben | Design | ⚠️ Datei trägt weiterhin `0.7.0` |
| 15 | Meilenstein-Prozentwerte neu erheben | Projekt | ⚠️ Stand 18.07.2026 |
| 16 | GitHub-CLI-Token erneuern | Nutzer | ⚠️ `gh auth status` meldet einen ungültigen gespeicherten Token; Git-Zugang und GitHub-App funktionieren |
| 17 | [0PE-96](https://linear.app/0penclaw/issue/0PE-96): Browser, Android und iOS für 0.8.0 vollständig konsolidieren | Entwicklung | ⚠️ `Todo`, `Urgent`, Zieltermin 08.08.2026, Meilenstein `Aug 8` |
| 18 | [0PE-93](https://linear.app/0penclaw/issue/0PE-93): Einstellungsrad mit Konfigurations-Pop-up statt Ausblenden der Felder | Entwicklung | ⚠️ `Todo`, `High` — die frühere Ausblendlösung ist damit aufgehoben |
| 19 | [0PE-103](https://linear.app/0penclaw/issue/0PE-103): Debugmodus um die neuen Komponenten in allen drei Branches erweitern | Entwicklung | ⚠️ `Todo`, `High` |
| 20 | [0PE-99](https://linear.app/0penclaw/issue/0PE-99): Untertitel-RAW-Datenstrom und JSON-Export | Entwicklung | ⚠️ `Todo`, benötigt den `Universal API-Key` aus 0PE-93 |
| 21 | [0PE-100](https://linear.app/0penclaw/issue/0PE-100) / [0PE-101](https://linear.app/0penclaw/issue/0PE-101): Songerkennung für Android und iOS wirksam umsetzen | Entwicklung | ⚠️ `Todo` |
| 22 | [0PE-72](https://linear.app/0penclaw/issue/0PE-72): Browser-Songerkennung scheitert mit `activeTab`-Capture-Fehler; Shazam fehlt in der Browserversion | Entwicklung | ⚠️ `Backlog`, `High` — wieder geöffnet |
| 23 | Reale Windows-UAC-Installation von VLC über `VLC Ersatz` | Nutzer | ⚠️ Installationspfad implementiert und geprüft, tatsächliche Installation nicht durchgeführt |

### Mit 0.7.1 erledigte Punkte der vorherigen v8-Fassung ✅

| Punkt | Erledigung |
|---|---|
| VLC-Ersatz umplatzieren und VLC bei Bedarf installieren | 0PE-97 `Done` am 02.08.2026, Browser `3476d17` |
| LIVE-Informationen unter Seiteninformationen | 0PE-98 `Done` am 02.08.2026 |
| Top-Chatter mit `mehr…`, `Reset` und Stummschaltung | 0PE-102 `Done` am 02.08.2026 |
| Bekannter Android-Strukturtestfehler | 0PE-94 `Done` am 02.08.2026, Run `30752210199` mit `31/31` Tests |
| Perplexity als primäre Websuche einrichten | dauerhaft in CDE und lokalem Docker konfiguriert, Tavily bleibt Rückfall |
| Sprachdienst-Start über Setup-Bindung, Protokollstarter und Health-Check | 0PE-73 und 0PE-87 `Done` am 01.08.2026 |
| Zusätzliche bestätigte Sherpa-Schriftsysteme | 0PE-86 `Done` am 02.08.2026; 26 Stimmen in fester Gruppierung |
| Sidepanel-Reihenfolge | 0PE-88 `Done` am 02.08.2026 |
| Mobile Textentfernungen unter Player und Mehr | 0PE-78 und 0PE-79 `Done`; Android `b3d1770`, iOS-Abwesenheit in `0a4fc63` bestätigt |
| Formales Security-Seal für 0.7.1 | abgeschlossen: 0 Critical, 0 High, 0 Medium, 2 Low/P3, beide vor Veröffentlichung behoben |
| Vercel-Deployment des iOS-Branches | 0PE-91 `Done`; der Vercel-Dokumentationspreview ist `READY`. Der davon getrennte native iOS-Nachweis stammt aus OPE-83 / Actions Run `30717416888` und ist ebenfalls erfolgreich |
| Sidepanel-Fehler `Cannot set properties of undefined` | 0PE-92 `Done`; Fix-Commit `29f1d8a` |
| Taildrop der aktuellen APK auf das Android-Gerät | ausgeführt an `Redmi Note 11S` (`100.94.134.39`), Exit-Code `0` |

### In v7 offene Punkte, die mit 0.7.1 erledigt sind ✅

| v7-Punkt | Erledigung |
|---|---|
| Notion und Linear von 0.6.0 auf 0.7.0 fortschreiben | Notion und Linear stehen auf 0.7.1; Issue-Status am 30.07.2026 einzeln bestätigt |
| Canva-Ordner ist leer und ohne Brand Kits | Ordner enthält zwei 0.7.1-Decks (DE/EN); Brand Kits bleiben offen |
| Physischer HyperOS-Test auf Xiaomi-Gerät | durchgeführt |
| GHCR-Pakete öffentlich stellen | alle drei auf `public`, Vererbung aktiv |
| Mobil: Vollbild durch zweites Antippen schließen | 0PE-70 `Done` am 29.07.2026 |
| Globale SecretStore-Ablage für den Airtable-PAT | entfällt, Airtable ist nicht mehr Teil des Projektumfangs |

---

*Ende der Linkliste · TikTok LIVE Companion 0.7.1 · Dokumentrevision v8, finalisiert · Stand 2. August 2026, 17:00 Uhr · CoAuthoring Claude Dispatcher (Versenden) · Übergabe an Codex für 0.8.0 am 08.08.2026 · Release-Gate 0PE-96*
