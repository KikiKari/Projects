# Überblick

TikTok LIVE Companion 0.7.0 ist eine lokale Browser-Erweiterung für öffentliche TikTok-LIVE-Streams. Sie bündelt bereinigten Chattext, natürliches Vorlesen, Top-Chatter, beobachtete Personen, Geschenkzählung, native Untertitelprüfung, LIVE-Informationen, Playersteuerung, optional manuelle Songerkennung, digitalen Pegelschutz, Bildqualitäten und FLV-/HLS-Links in einem Seitenpanel.

Ergänzend enthält 0.7.0 native Quellprojekte für iOS 15+ sowie Android/HyperOS ab API 21. Sie bilden die Companion-Funktionen in einer abgesicherten TikTok-WebView ab und verwenden ShazamKit für die ausschließlich manuell gestartete Songerkennung. Der Browser verwendet weiterhin AudD.

Der [finalisierte CoAuthoring-V7-Stand](../coauthoring-v7.md) dokumentiert die verbindliche Mobile-Oberfläche, die 0.7.0-Plattformmatrix sowie alle freigegebenen Browser-, Installations- und Sicherheitsmotive. Bilder mit sichtbarer Angabe 0.5.0 bleiben als Designhistorie erhalten.

## Was die Erweiterung leistet

- zeigt die letzten fünf bereinigten öffentlichen Chatzeilen und hält höchstens 50 Sitzungseinträge pro Tab;
- spricht nur neue Chatzeilen über den lokalen Windows-Dienst oder als Fallback über Web Speech vor;
- erkennt pro Stream feste dreistellige Teamkürzel und verwaltet Stream-/Dauer-Mutes;
- unterscheidet `caption_info`, sichtbaren Untertitelschalter und tatsächlich empfangene CaptionMessages;
- liest Zuschauerzahl, Aufrufe, Likes, Follows und Teilungen aus beobachteten LIVE-Ereignissen;
- steuert TikToks vorhandenen Player, ohne Meldungen automatisch abzusenden;
- erkennt Stream-Varianten, Codecs, Auflösung, Bitrate und zeitlich begrenzte FLV-/HLS-URLs;
- exportiert Caption-Protokolle als JSONL und bereinigte Diagnosedaten als JSON.

## Grenzen

Die Erweiterung erzeugt keine Untertitel selbst. Fehlen TikToks native Caption-Ereignisse, kann sie diese nicht erzwingen. Der WebSocket-Bridge-Inhalt ist ein Beobachtungsprotokoll und kein kryptografisch authentifizierter Nachweis. Der Pegel wird in dBFS gemessen; ohne kalibriertes Ausgabegerät kann kein dB-SPL-Wert am Ohr garantiert werden.

Die Erweiterung liest keine Cookies, benötigt kein Konto und verwendet keinen API-Key.

Die mobilen Apps lesen ebenfalls keine Cookies oder Web-Storage-Inhalte aus. WebView-Funktionen, die TikTok oder die Plattform ablehnen, bleiben sichtbar und erhalten einen eindeutigen Status statt einer scheinbaren Erfolgsmeldung.
