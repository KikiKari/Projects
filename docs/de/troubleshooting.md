# Fehlerbehebung

## Keine CaptionMessages

Zuerst **Seite prüfen** ausführen. `caption_info` und ein sichtbarer Menüpunkt zeigen nur die Verfügbarkeit an; erst empfangene CaptionMessages bestätigen Ereignisse im Beobachtungszeitraum. Den Hook vor der Player-Verbindung setzen und den Tab neu laden.

## Hook bleibt getrennt

**Refresh** im Hook-Bereich verwenden. Dadurch erhält der aktuelle LIVE-Stream eine neue tabbezogene Browser-Sitzungs-ID und wird in einem neuen Tab-/Dokumentkontext mit aktivem Hook geöffnet; der bisherige Tab wird danach geschlossen. Nur wenn das Ersetzen nicht möglich ist, wird derselbe Tab mit neuer Sitzungs-ID ohne Cache geladen. Cookies, Login und andere TikTok-Tabs bleiben unverändert.

## Playeraktion wird abgelehnt

Bild-in-Bild und Vollbild benötigen je nach Browser eine unmittelbare Nutzeraktion. Web Audio kann für einzelne Medienkonfigurationen nicht verfügbar sein; die Erweiterung meldet den Fehler und behauptet dann keinen aktiven Pegelschutz.

## Keine VLC-Links

Ein Stream kann nur HLS, nur FLV oder keine extrahierbare URL liefern. **Automatisch** ist keine konkrete Stream-URL. Erneut **Seite prüfen** ausführen, nachdem der Player geladen ist.

## Diagnoseexport

Debugmodus erst zur Fehlersuche aktivieren. Der Export enthält keinen Chattext und entfernt Werte signierter URL-Parameter.
