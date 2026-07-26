# Lokaler Begleitdienst 0.7.0

Der optionale Windows-Dienst liefert verstärkbares TTS-Audio und reicht ausschließlich manuell aufgenommene Audioausschnitte an AudD weiter. Er bindet nur an `127.0.0.1`.

```powershell
npm run setup
npm start
```

`npm run setup` speichert die lokale Konfiguration, installiert fehlende Sherpa-ONNX-Stimmen aus dem offiziellen k2-fsa-Release, richtet den Sidepanel-Button **Sprachdienst installieren** als lokalen Windows-Startaufruf ein und führt abschließend `npm start` verborgen aus. Den ausgegebenen Pairing-Code im Sidepanel eintragen.

Der Dienst bleibt fest auf `http://127.0.0.1:43117`. Das AudD-Token wird im Sidepanel-Feld **AudD API-Token** gespeichert oder leer gelassen; es liegt danach in `%LOCALAPPDATA%\TikTokLiveCompanion\service.json`. Sherpa-Modelle und die kuratierte Stimmenliste liegen unter `%LOCALAPPDATA%\TikTokLiveCompanion\sherpa-onnx` und `%LOCALAPPDATA%\TikTokLiveCompanion\sherpa-voices.json`.

Falls der automatische Hintergrundstart nicht verfügbar ist, bleiben beide manuellen Befehle möglich: zuerst `npm run setup`, anschließend `npm start`.
