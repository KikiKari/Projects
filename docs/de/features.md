# Funktionen

## Chat und Vorlesen

Öffentliche Chatnachrichten werden bereinigt und als zugänglicher Text dargestellt. Pro Tab bleiben die neuesten 500 Chatzeilen erhalten; der rote Zähler öffnet eine Übersicht mit diesen Zeilen, während die kompakte Hauptansicht weiterhin die letzten fünf zeigt. **Auto-Chat Refresh** leert diese tabbezogene Chatanzeige im gewählten Abstand von 1 bis 60 Minuten und lädt weder TikTok noch den Browser-Tab neu. Emoji-Sequenzen und sicher erkannte, pro Stream feste Teamkürzel werden beim Vorlesen entfernt. `@`-Empfänger und Fragen werden natürlich formuliert. Für die Sprachausgabe entfallen Sonderzeichen und Zahlen in Nicknamen; technische `user…`-Namen werden auf `user` plus höchstens drei Ziffern begrenzt. Die optionale geeignete Namenskürzung erkennt zusätzlich klare Hauptteile wie `Traumtänzer`, `Vanny`, `Löwin` oder `Maskenaufsicht`. Dieselbe Regel gilt für `@`-Empfänger. Überlange Lachfolgen werden als kurzes `haha` gesprochen. Sprache, Namensansage und geeignete Namenskürzung sind einstellbar. TTS und Warteschlange laufen im MV3-Offscreen-Dokument tabbezogen weiter, wenn das Sidepanel während Vollbild nicht sichtbar ist. Der optionale lokale Windows-Dienst ermöglicht Verstärkung und zusätzliche, erst bei Auswahl installierte Sherpa-Stimmen; ohne Dienst bleibt der Browser-TTS-Fallback erhalten. Die Stimmenauswahl beginnt mit den deutschen und englischen Stimmen (Sherpa Eva zuerst) und trennt weitere Modelle in **Kyrillisch**, **Asiatisch**, **Abjad** und **Indisch**.

## Top-Chatter und beobachtete Personen

Die Erweiterung zählt pro Stream Nachrichten, Wörter und Geschenkereignisse für bis zu 5.000 im Chat sichtbare Personen. Stream-Mutes werden beim Streamwechsel verworfen, dauerhafte Mutes bleiben lokal gespeichert. Diese Liste ist keine vollständige TikTok-Zuschauerliste.

## Songerkennung

Nach ausdrücklicher Aktivierung und Klick nimmt die Erweiterung etwa zwölf Sekunden Tab-Audio auf. Der lokale Dienst sendet nur diesen Ausschnitt an AudD; ohne Klick findet keine Aufnahme oder Übertragung statt.

## Untertitel

Die Oberfläche trennt drei Signale: angekündigte Caption-Funktion in `caption_info`, gefundener Menüpunkt und tatsächlich empfangene `WebcastCaptionMessage`-Ereignisse. Fehlende Ereignisse beweisen nicht, dass nie gesprochen wurde.

## LIVE-Informationen

Der Hook beobachtet `WebcastRoomUserSeqMessage`, `WebcastLikeMessage` und `WebcastSocialMessage`. Follows seit Hook sind ein lokaler Ereigniszähler; die Followerzahl des Hosts ist ein separater Gesamtwert.

## Player und Pegelschutz

Play/Pause, Neuladen, Lautstärke, Stumm, Bild-in-Bild und Vollbild bedienen TikToks vorhandenen Player. Ein VLC-Ersatz belegt die größte sichtbare zentrale Playerfläche und lässt Originalvideo, Mini-Player sowie Media-/VLC-Links unangetastet. Der optionale lokale Kompressor begrenzt digitale Spitzen. dBFS ist kein kalibrierter dB-SPL-Wert.

## Sidepanel und Tab-Isolation

Die Reihenfolge ist: Chat, Top-Chatter, Seiteninformationen; WebSocket-Hook, Untertitel; Playersteuerung, Songerkennung. Hook, Streamstatus, Chat, TTS, Player-Recovery, Debugmodus und Modulaktivität werden pro Tab geführt. Nur Benutzerpräferenzen und Zugangsdaten bleiben global; eine Embed-/Normal-Verknüpfung ist die einzige ausdrückliche Beziehung zwischen zwei Tabs.

## Bildqualität und VLC

Qualitätsstufen stammen aus TikToks Stream-Metadaten. **Automatisch** ist ein Playermodus und hat keinen VLC-Link. Signierte FLV-/HLS-Links können ablaufen und sind bis dahin sensibel.

## Diagnose

Der abschaltbare Debugmodus exportiert bereinigte Ereignisse. Werte signierter URL-Parameter, Chattext, Cookies und API-Keys werden nicht exportiert.

## Profil-Force

Der normale Refresh bleibt nicht unterbrechend. Nach einem Streamwechsel im selben Tab werden Seiteninformationen an den aktuellen Handle gebunden, damit Hostprofil und Badges nicht aus dem vorherigen Stream übernommen werden. `Force` öffnet bewusst kurz die Profilseite des aktuellen Handles, übernimmt die dort geladenen öffentlichen Werte und stellt anschließend die LIVE-URL wieder her.
