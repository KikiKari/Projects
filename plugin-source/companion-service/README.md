# Lokaler Begleitdienst 0.7.0

Der optionale Windows-Dienst liefert verstärkbares TTS-Audio und reicht ausschließlich manuell aufgenommene Audioausschnitte an AudD weiter. Er bindet nur an `127.0.0.1`.

```powershell
npm run setup
npm start
```

Den ausgegebenen Pairing-Code im Sidepanel eintragen. Das AudD-Token bleibt in `%LOCALAPPDATA%\TikTokLiveCompanion\service.json` und wird nie in der Erweiterung gespeichert.
