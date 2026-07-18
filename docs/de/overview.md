# Überblick

TikTok LIVE Companion 0.5.0 ist eine lokale Browser-Erweiterung für öffentliche TikTok-LIVE-Streams. Sie bündelt barrierearmen Chattext, lokale Sprachausgabe, native Untertitelprüfung, LIVE-Informationen, Playersteuerung, digitalen Pegelschutz, Bildqualitäten und FLV-/HLS-Links in einem Seitenpanel.

## Was die Erweiterung leistet

- zeigt die letzten fünf bereinigten öffentlichen Chatzeilen und hält höchstens 50 Sitzungseinträge pro Tab;
- spricht nur neue Chatzeilen lokal über die Web Speech API vor;
- unterscheidet `caption_info`, sichtbaren Untertitelschalter und tatsächlich empfangene CaptionMessages;
- liest Zuschauerzahl, Aufrufe, Likes, Follows und Teilungen aus beobachteten LIVE-Ereignissen;
- steuert TikToks vorhandenen Player, ohne Meldungen automatisch abzusenden;
- erkennt Stream-Varianten, Codecs, Auflösung, Bitrate und zeitlich begrenzte FLV-/HLS-URLs;
- exportiert Caption-Protokolle als JSONL und bereinigte Diagnosedaten als JSON.

## Grenzen

Die Erweiterung erzeugt keine Untertitel selbst. Fehlen TikToks native Caption-Ereignisse, kann sie diese nicht erzwingen. Der WebSocket-Bridge-Inhalt ist ein Beobachtungsprotokoll und kein kryptografisch authentifizierter Nachweis. Der Pegel wird in dBFS gemessen; ohne kalibriertes Ausgabegerät kann kein dB-SPL-Wert am Ohr garantiert werden.

Die Erweiterung liest keine Cookies, benötigt kein Konto und verwendet keinen API-Key.
