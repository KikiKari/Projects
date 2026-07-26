# Lokaler Begleitdienst 0.7.1

Der optionale Windows-Dienst liefert verstärkbares TTS-Audio und reicht ausschließlich manuell aufgenommene Audioausschnitte an AudD weiter. Er bindet nur an `127.0.0.1`.

## Aktualisierung von einem alten entpackten Paket

Wenn das Sidepanel meldet `Lokaler Dienst ist veraltet`, läuft auf `127.0.0.1:43117` noch ein alter Dienst. In der alten PowerShell zuerst `Ctrl+C` drücken und danach aus dem aktuell entpackten 0.7.1-Paket starten:

```powershell
cd "C:\Users\silve\Downloads\tiktok-live-companion-extension-0.7.1"
npm run setup
npm start
```

`npm run setup` speichert die lokale Konfiguration, installiert fehlende Sherpa-ONNX-Stimmen aus dem offiziellen k2-fsa-Release, richtet den Sidepanel-Button **Sprachdienst installieren** als lokalen Windows-Startaufruf ein und führt abschließend `npm start` verborgen aus. Den ausgegebenen Pairing-Code im Sidepanel eintragen.

Der Pairing-Code wird aus `%LOCALAPPDATA%\TikTokLiveCompanion\service.json` wiederverwendet und ändert sich normalerweise nicht. Er ändert sich nur, wenn diese Konfigurationsdatei gelöscht oder neu erzeugt wird. Die PowerShell mit `npm start` muss während der Nutzung offen bleiben, wenn der Dienst nicht über den registrierten Protokollstarter im Hintergrund läuft.

Der Dienst bleibt fest auf `http://127.0.0.1:43117`. Das AudD-Token wird im Sidepanel-Feld **AudD API-Token** gespeichert oder leer gelassen; es liegt danach in `%LOCALAPPDATA%\TikTokLiveCompanion\service.json`. Sherpa-Modelle und die kuratierte Stimmenliste liegen unter `%LOCALAPPDATA%\TikTokLiveCompanion\sherpa-onnx` und `%LOCALAPPDATA%\TikTokLiveCompanion\sherpa-voices.json`. Wenn Sherpa-ONNX noch fehlt, startet der aktuelle Dienst die Installation im Hintergrund automatisch. Der Sidepanel-Button **Sherpa installieren** löst denselben Vorgang manuell aus; die Stimmen erscheinen nach Abschluss oder beim nächsten Öffnen der Erweiterung.

Falls die automatische Installation auf einem System blockiert wird, kann sie manuell aus dem entpackten Paket gestartet werden:

```powershell
cd "C:\Users\silve\Downloads\tiktok-live-companion-extension-0.7.1\companion-service"
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-sherpa.ps1
npm run setup
npm start
```

Die deutsche Sherpa-Auswahl verwendet Piper-basierte Modelle wie Kerstin sowie maennliche Stimmen wie Thorsten/Karlsson, sofern sie installiert sind. Fuer AudD ist nur der eigene API-Token erforderlich; ohne Token bleibt die Songerkennung deaktiviert, Chat-TTS funktioniert trotzdem.
