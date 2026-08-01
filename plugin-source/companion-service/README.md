# Lokaler Begleitdienst 0.7.1

Der optionale Windows-Dienst liefert verstärkbares TTS-Audio und reicht ausschließlich manuell aufgenommene Audioausschnitte an AudD weiter. Er bindet nur an `127.0.0.1`.

## Aktualisierung von einem alten entpackten Paket

Wenn das Sidepanel meldet `Lokaler Dienst ist veraltet`, läuft auf `127.0.0.1:43117` noch ein alter Dienst. In der alten PowerShell zuerst `Ctrl+C` drücken und danach aus dem aktuell entpackten 0.7.1-Paket starten:

```powershell
cd "C:\Users\silve\Downloads\tiktok-live-companion-extension-0.7.1"
npm run setup -- -ExtensionId <Erweiterungs-ID-aus-dem-Sidepanel>
npm start
```

Der im Sidepanel erzeugte Befehl `npm run setup -- -ExtensionId …` ist der einmalige technische PowerShell-Schritt: Er bindet die lokale Konfiguration an genau diese Erweiterung, installiert die deutschen und englischen Standardstimmen, registriert `tiktok-live-companion://start` und führt abschließend `npm start` verborgen aus. Danach startet der Sidepanel-Button den eingerichteten Dienst automatisch. Ein kurzlebiger lokaler Bootstrap-Nonce übergibt den bereits lokal erzeugten Pairing-Code einmalig an die gebundene Erweiterung; er muss nicht abgetippt werden.

Der Pairing-Code wird aus `%LOCALAPPDATA%\TikTokLiveCompanion\service.json` wiederverwendet und ändert sich normalerweise nicht. Er ändert sich nur, wenn diese Konfigurationsdatei gelöscht oder neu erzeugt wird. Die PowerShell mit `npm start` muss während der Nutzung offen bleiben, wenn der Dienst nicht über den registrierten Protokollstarter im Hintergrund läuft.

Der Dienst bleibt fest auf `http://127.0.0.1:43117`. Das AudD-Token ist optional und wird nur für die manuelle Songerkennung in `%LOCALAPPDATA%\TikTokLiveCompanion\service.json` gespeichert. Sherpa-Modelle und die kuratierte Stimmenliste liegen unter `%LOCALAPPDATA%\TikTokLiveCompanion\sherpa-onnx` und `%LOCALAPPDATA%\TikTokLiveCompanion\sherpa-voices.json`. Deutsch und Englisch werden beim Grundsetup installiert. Weitere im mitgelieferten `voice-catalog.json` bestätigte Stimmen werden erst nach ihrer Auswahl über den authentifizierten Loopback-Endpunkt `/v1/voices/install` geladen. Jedes freigegebene Archiv ist an Größe und SHA-256 gebunden, wird vor dem Entpacken auf sichere Pfade und Linkeinträge geprüft und erst aus einem temporären Staging-Verzeichnis übernommen. Nicht bestätigte Modelle werden nicht angeboten.

Falls die automatische Installation auf einem System blockiert wird, kann sie manuell aus dem entpackten Paket gestartet werden:

```powershell
cd "C:\Users\silve\Downloads\tiktok-live-companion-extension-0.7.1\companion-service"
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-sherpa.ps1
npm run setup -- -ExtensionId <Erweiterungs-ID-aus-dem-Sidepanel>
npm start
```

Die deutsche Sherpa-Auswahl verwendet Piper-basierte Modelle wie Kerstin sowie männliche Stimmen wie Thorsten/Karlsson, sofern sie installiert sind. Für AudD ist nur der eigene API-Token erforderlich; ohne Token bleibt die Songerkennung deaktiviert, Chat-TTS funktioniert trotzdem.
