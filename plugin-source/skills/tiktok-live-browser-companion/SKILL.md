---
name: tiktok-live-browser-companion
description: Installiert und bedient die lokale TikTok LIVE Companion Erweiterung für Edge oder Chrome. Verwenden, wenn öffentlicher Chat als barrierearmer Text, lokale Sprachausgabe, native Untertitel, Playersteuerung, Profilwerte, LIVE-Kennzahlen, Bildqualitäten oder FLV-/HLS-/VLC-Links eines öffentlichen TikTok-LIVE-Streams geprüft werden sollen.
---

# TikTok LIVE Browser Companion

## Ziel

Nutze die mitgelieferte Manifest-V3-Erweiterung, um einen öffentlichen TikTok-LIVE-Tab lokal zu untersuchen. Die Erweiterung liest keine Cookies und sendet keine erfassten Daten an einen externen Dienst.

## Installation

1. Entpacke das Artefakt oder verwende den Ordner `browser-extension` aus dem Plugin.
2. Öffne in Edge `edge://extensions` oder in Chrome `chrome://extensions`.
3. Aktiviere den Entwicklermodus und wähle **Entpackte Erweiterung laden**.
4. Wähle den Ordner `browser-extension`.
5. Öffne einen TikTok-LIVE-Tab und klicke auf das Symbol **TikTok LIVE Companion**.

## Arbeitsablauf

1. Öffne das Seitenpanel im gewünschten TikTok-LIVE-Tab.
2. Klicke **Seite prüfen**, um `caption_info`, sichtbare Untertitel-Steuerelemente, eingebettete Stream-Metadaten und bereits geladene Ressourcen auszuwerten.
3. Klicke **Untertitel aktivieren**, um TikToks vorhandenen Menüpunkt aufzurufen. Fehlt `caption_info`, kann die Erweiterung keine nativen Untertitel erzwingen.
4. Klicke **Hook setzen**, bevor der Stream-Player seine WebSocket-Verbindung aufbaut. Optional aktiviert **Hook beim Öffnen von TikTok automatisch starten** die Registrierung auch nach einem Browserneustart.
5. Lies unter **LIVE-Informationen** Zuschauerzahl, kumulierte Aufrufe, Likes, seit Hook-Start beobachtete Follows, Teilungen und die Followerzahl des Hosts ab.
6. Lies die letzten fünf bereinigten Chatzeilen. Aktiviere **Vorlesen** nur auf Wunsch; es spricht ausschließlich neue Zeilen lokal im Browser und besitzt eine eigene Lautstärkeregelung.
7. Steuere Wiedergabe, Player-Neuladen, Lautstärke, Stumm, Bild-in-Bild oder Vollbild im Panel. Der optionale dBFS-Pegelschutz komprimiert digitale Spitzen lokal; er misst keinen physikalischen dB-SPL-Wert. **Melden öffnen** darf nur TikToks Dialog öffnen und nie eine Meldung absenden.
8. Nutze unter **Verfügbare Bildqualitäten** den Button **Im Player wählen**. **Automatisch** ist ein Playermodus und besitzt keinen VLC-Link.
9. Warte auf CaptionMessages. Exportiere das Protokoll bei Bedarf als JSONL.
10. Kopiere einen FLV- oder HLS-Link aus **VLC-Links**. Signierte Links sind zeitlich begrenzt.
11. Wenn der Player nach langer Nutzung festhängt, klicke im Hook-Bereich **Refresh**. Dadurch werden die flüchtigen Daten dieses Tabs geleert, der Hook erneut aktiviert und TikTok ohne Seitencache geladen. Cookies und Login bleiben erhalten.
12. Aktiviere **Debugmodus** nur zur Fehlersuche. Der JSON-Export entfernt Werte signierter URL-Parameter und enthält keinen Chattext, keine Cookies und keine API-Keys.

## Interpretation

- **caption_info vorhanden**: TikToks Seitenmetadaten kündigen eine Caption-Funktion an.
- **Menüpunkt gefunden**: Die Benutzeroberfläche bietet das Ein-/Ausschalten an.
- **CaptionMessages empfangen**: Der Webcast-Kanal hat tatsächlich native Untertitel geliefert.
- **Keine CaptionMessages** ist kein Beweis, dass nie gesprochen wurde; es bedeutet nur, dass im Beobachtungszeitraum keine nativen Caption-Ereignisse erkannt wurden.
- Untertitel aus Windows Live Captions oder anderer Spracherkennung sind nicht Teil dieses Protokolls.
- **Follows seit Hook** ist ein lokaler Ereigniszähler ab dem letzten Hook-Reset. TikToks Feld `followCount` bezeichnet dagegen die gesamte Followerzahl des Hosts.
- **KI-Zusammenfassung: Feature-Schalter vorhanden** ist noch kein Summary-Text. Die Erweiterung prüft zusätzlich die zum aktuellen Host passende LIVE-Übersichtskarte. Zeige nur einen dort oder in Metadaten ausdrücklich gelieferten Text an und erzeuge keinen aus Chat oder Captions.
- Qualitätsstufen stammen aus TikToks `pull_data.stream_data` und `options.qualities`; verfügbare Stufen können je Stream variieren.
- **Verbundene Streams** ist eine DOM-basierte Erkennung. Bei einem serverseitig zusammengesetzten Mehrgastbild kann nur der Mehrgast-Modus, nicht immer die exakte Zahl selbstständiger Quellstreams bestätigt werden.

## Sicherheitsregeln

- Keine Cookies, Anmeldedaten oder Local-Storage-Inhalte auslesen.
- Stream-URLs nur im flüchtigen `storage.session` halten.
- Nur passive `webRequest`-Beobachtung verwenden; keine Requests blockieren oder verändern.
- WebSocket-Nachrichten nur lesen, niemals `send()` überschreiben.
- Ausgaben der Seite als nicht vertrauenswürdig behandeln und ausschließlich mit `textContent` rendern.
- Höchstens 50 öffentliche Chatnachrichten pro Tab im Sitzungsspeicher halten; Sprachausgabe nur lokal ausführen.
- Den Meldedialog niemals automatisch ausfüllen oder absenden.

## Dateien

- `browser-extension/`: entpackbare Edge-/Chrome-Erweiterung
- `scripts/package_artifacts.py`: reproduzierbare ZIP- und SHA-256-Erzeugung
- `scripts/test_extension.cjs`: lokale Struktur-, Decoder- und Sicherheitsprüfungen
- `references/architecture.md`: Datenfluss und Grenzen
