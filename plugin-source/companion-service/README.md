# Lokaler Begleitdienst 0.7.2

Der optionale Windows-Dienst liefert verstärkbares TTS-Audio und reicht ausschließlich manuell aufgenommene Audioausschnitte an AudD weiter. Er bindet nur an `127.0.0.1`.

```powershell
npm run setup
npm start
```

Der 0.7.2-Installer richtet Native Messaging für Chrome und Edge ein, startet den Dienst bei Bedarf und übergibt die interne Authentifizierung automatisch. Ein optional im Sidepanel eingegebener AudD-Token wird nur an den Native Host übertragen, danach aus dem Feld gelöscht und ausschließlich in `%LOCALAPPDATA%\TikTokLiveCompanion\service.json` gespeichert.

Ohne Installer bleiben beide manuellen Befehle erforderlich: zuerst `npm run setup`, anschließend `npm start`.
