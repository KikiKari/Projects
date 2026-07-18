# Fehlerbehebung

## Keine CaptionMessages

Zuerst **Seite prüfen** ausführen. `caption_info` und ein sichtbarer Menüpunkt zeigen nur die Verfügbarkeit an; erst empfangene CaptionMessages bestätigen Ereignisse im Beobachtungszeitraum. Den Hook vor der Player-Verbindung setzen und den Tab neu laden.

## Hook bleibt getrennt

**Refresh** im Hook-Bereich verwenden. Dadurch wird nur der flüchtige Zustand des Tabs gelöscht, der Hook erneut registriert und die Seite ohne Cache geladen. Bei Autostart kann die Registrierung browserübergreifend bestehen bleiben.

## Playeraktion wird abgelehnt

Bild-in-Bild und Vollbild benötigen je nach Browser eine unmittelbare Nutzeraktion. Web Audio kann für einzelne Medienkonfigurationen nicht verfügbar sein; die Erweiterung meldet den Fehler und behauptet dann keinen aktiven Pegelschutz.

## Keine VLC-Links

Ein Stream kann nur HLS, nur FLV oder keine extrahierbare URL liefern. **Automatisch** ist keine konkrete Stream-URL. Erneut **Seite prüfen** ausführen, nachdem der Player geladen ist.

## Diagnoseexport

Debugmodus erst zur Fehlersuche aktivieren. Der Export enthält keinen Chattext und entfernt Werte signierter URL-Parameter.
