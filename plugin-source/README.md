# TikTok LIVE Companion

Lokales Codex-Plugin plus entpackbare Manifest-V3-Erweiterung für Edge und Chrome.

## Funktionen

- TikToks vorhandenen Menüpunkt **Untertitel anzeigen** suchen und aktivieren
- die letzten fünf öffentlichen Chatzeilen ohne Emojis und erkannte dreistellige Teamkürzel anzeigen sowie Empfänger und Fragen natürlich vorlesen
- Top-Chatter und bis zu 5.000 im Chat beobachtete Personen mit Nachrichten-, Wort- und Geschenkzählung sowie Stream-/Dauer-Mutes verwalten
- `caption_info` aus eingebetteten JSON-Metadaten erkennen
- optionale, vor dem Reload installierte WebSocket-Beobachtung für `WebcastCaptionMessage`
- LIVE-Informationen aus `WebcastRoomUserSeqMessage`, `WebcastLikeMessage` und `WebcastSocialMessage`: Zuschauer*innen, Aufrufe, Likes, Follows und Teilungen
- FLV-/HLS-Anfragen an TikTok-CDNs passiv erkennen
- eingebettete Stream-URLs einschließlich nicht abgespielter Qualitätsstufen, Codec, Auflösung und Bitrate auslesen
- verfügbare Qualitätsstufen über TikToks vorhandenes Player-Menü wechseln
- den TikTok-Player über Play/Pause, Neuladen, Lautstärke, Stumm, Bild-in-Bild und Vollbild steuern sowie den Meldedialog öffnen, ohne eine Meldung abzusenden
- digitalen Spitzenpegel in dBFS anzeigen und Spitzen mit einem lokalen, einstellbaren Web-Audio-Kompressor oder einem sicheren Lautstärkedeckel begrenzen
- Profilkopfwerte tabübergreifend zwischenspeichern sowie ausdrücklich gelieferte Übersichtskarten-Texte und TikTok-KI-Zusammenfassungen anzeigen
- Profilwerte auf ausdrücklichen Force-Klick über einen vollständigen Profilseitenaufruf aktualisieren
- optional verstärkbares Windows-TTS über den lokalen Begleitdienst und eine manuelle 12-Sekunden-Songerkennung über AudD anbieten
- Mehrgast-Layouts bestmöglich erkennen und den WebSocket-Hook optional browserübergreifend automatisch starten
- vollständiger Tab-Reset ohne Cookie-Löschung, mit erneut aktiviertem Hook und Cache-umgehendem Reload
- Caption-Protokoll als JSONL exportieren
- einen abschaltbaren Diagnosemodus mit bereinigtem JSON-Export bereitstellen

## Datenschutz

Die Erweiterung liest keine Cookies. Für fehlende Profilkopfwerte kann sie die öffentliche TikTok-Profilseite mit `credentials: omit` abrufen oder nach einem ausdrücklichen Force-Klick kurz vollständig öffnen. Erkannte Links, Captions, Diagnosedaten, Teilnehmeraggregate und bis zu 50 öffentliche Chatzeilen werden im flüchtigen Browser-Sitzungsspeicher gehalten. Einstellungen und dauerhafte Mutes liegen im lokalen Speicher. TTS läuft lokal im Browser beziehungsweise im optionalen Windows-Dienst. Nur eine manuell gestartete Songerkennung sendet ungefähr zwölf Sekunden Tab-Audio an AudD; das AudD-Token verbleibt in der lokalen Dienstkonfiguration.

Die dBFS-Anzeige beschreibt den digitalen Signalpegel. Ohne ein kalibriertes Ausgabegerät kann die Erweiterung keinen physikalischen Schalldruckpegel in dB SPL am Ohr messen oder garantieren.
