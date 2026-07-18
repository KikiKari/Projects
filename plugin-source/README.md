# TikTok LIVE Companion

Lokales Codex-Plugin plus entpackbare Manifest-V3-Erweiterung für Edge und Chrome.

## Funktionen

- TikToks vorhandenen Menüpunkt **Untertitel anzeigen** suchen und aktivieren
- die letzten fünf öffentlichen Chatzeilen ohne Emojis als zugänglichen Text anzeigen, per Refresh leeren und optional auch bei Tabwechseln lokal vorlesen
- `caption_info` aus eingebetteten JSON-Metadaten erkennen
- optionale, vor dem Reload installierte WebSocket-Beobachtung für `WebcastCaptionMessage`
- LIVE-Informationen aus `WebcastRoomUserSeqMessage`, `WebcastLikeMessage` und `WebcastSocialMessage`: Zuschauer*innen, Aufrufe, Likes, Follows und Teilungen
- FLV-/HLS-Anfragen an TikTok-CDNs passiv erkennen
- eingebettete Stream-URLs einschließlich nicht abgespielter Qualitätsstufen, Codec, Auflösung und Bitrate auslesen
- verfügbare Qualitätsstufen über TikToks vorhandenes Player-Menü wechseln
- den TikTok-Player über Play/Pause, Neuladen, Lautstärke, Stumm, Bild-in-Bild und Vollbild steuern sowie den Meldedialog öffnen, ohne eine Meldung abzusenden
- digitalen Spitzenpegel in dBFS anzeigen und Spitzen mit einem lokalen, einstellbaren Web-Audio-Kompressor oder einem sicheren Lautstärkedeckel begrenzen
- Profilkopfwerte tabübergreifend zwischenspeichern sowie ausdrücklich gelieferte Übersichtskarten-Texte und TikTok-KI-Zusammenfassungen anzeigen
- Mehrgast-Layouts bestmöglich erkennen und den WebSocket-Hook optional browserübergreifend automatisch starten
- vollständiger Tab-Reset ohne Cookie-Löschung, mit erneut aktiviertem Hook und Cache-umgehendem Reload
- Caption-Protokoll als JSONL exportieren
- einen abschaltbaren Diagnosemodus mit bereinigtem JSON-Export bereitstellen

## Datenschutz

Die Erweiterung liest keine Cookies und überträgt keine Daten an Drittanbieter. Für fehlende Profilkopfwerte kann sie die öffentliche TikTok-Profilseite mit `credentials: omit` abrufen oder eine sichtbare Profilkarte auswerten. Erkannte Links, Captions, Diagnosedaten und bis zu 50 öffentliche Chatzeilen werden nur im flüchtigen Browser-Sitzungsspeicher gehalten. Im lokalen Speicher liegen ausschließlich Autostart, Vorlese-Fortsetzung und Vorleselautstärke. Sprachausgabe und Pegelschutz laufen lokal im Browser; API-Keys werden nicht benötigt oder verwendet.

Die dBFS-Anzeige beschreibt den digitalen Signalpegel. Ohne ein kalibriertes Ausgabegerät kann die Erweiterung keinen physikalischen Schalldruckpegel in dB SPL am Ohr messen oder garantieren.
