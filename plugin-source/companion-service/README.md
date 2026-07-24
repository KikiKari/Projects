# Lokaler Begleitdienst 0.7.0

Der optionale Windows-Dienst liefert verstärkbares TTS-Audio und reicht ausschließlich manuell aufgenommene Audioausschnitte an AudD weiter. Er bindet nur an `127.0.0.1`.

```powershell
npm run setup
npm start
```

`npm run setup` speichert die lokale Konfiguration, richtet den Sidepanel-Button **Sprachdienst installieren** als lokalen Windows-Startaufruf ein und führt abschließend `npm start` verborgen aus. Den ausgegebenen Pairing-Code im Sidepanel eintragen. Das AudD-Token bleibt in `%LOCALAPPDATA%\TikTokLiveCompanion\service.json`.

Falls der automatische Hintergrundstart nicht verfügbar ist, bleiben beide manuellen Befehle möglich: zuerst `npm run setup`, anschließend `npm start`.
