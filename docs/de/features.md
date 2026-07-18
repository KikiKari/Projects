# Funktionen

## Chat und Vorlesen

Öffentliche Chatnachrichten werden bereinigt und als zugänglicher Text dargestellt. Emoji-Sequenzen werden aus der kompakten Ansicht entfernt. Die optionale Sprachausgabe bleibt lokal im Browser und ist standardmäßig aus.

## Untertitel

Die Oberfläche trennt drei Signale: angekündigte Caption-Funktion in `caption_info`, gefundener Menüpunkt und tatsächlich empfangene `WebcastCaptionMessage`-Ereignisse. Fehlende Ereignisse beweisen nicht, dass nie gesprochen wurde.

## LIVE-Informationen

Der Hook beobachtet `WebcastRoomUserSeqMessage`, `WebcastLikeMessage` und `WebcastSocialMessage`. Follows seit Hook sind ein lokaler Ereigniszähler; die Followerzahl des Hosts ist ein separater Gesamtwert.

## Player und Pegelschutz

Play/Pause, Neuladen, Lautstärke, Stumm, Bild-in-Bild und Vollbild bedienen TikToks vorhandenen Player. Der optionale lokale Kompressor begrenzt digitale Spitzen. dBFS ist kein kalibrierter dB-SPL-Wert.

## Bildqualität und VLC

Qualitätsstufen stammen aus TikToks Stream-Metadaten. **Automatisch** ist ein Playermodus und hat keinen VLC-Link. Signierte FLV-/HLS-Links können ablaufen und sind bis dahin sensibel.

## Diagnose

Der abschaltbare Debugmodus exportiert bereinigte Ereignisse. Werte signierter URL-Parameter, Chattext, Cookies und API-Keys werden nicht exportiert.
