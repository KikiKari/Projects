# Installation

## Voraussetzungen

- Microsoft Edge oder Google Chrome ab Version 114
- ein öffentlicher TikTok-LIVE-Tab
- die entpackte Erweiterung aus `tiktok-live-companion-extension-0.7.1.zip`

## Schritte

1. ZIP-Datei entpacken.
2. `edge://extensions` oder `chrome://extensions` öffnen.
3. **Entwicklermodus** aktivieren.
4. **Entpackte Erweiterung laden** wählen.
5. Den Ordner auswählen, in dem `manifest.json` liegt.
6. Einen öffentlichen TikTok-LIVE-Tab öffnen und auf das Erweiterungssymbol klicken.

## Optionaler lokaler Sprach- und Songdienst

1. Den Ordner `companion-service` aus dem aktuell entpackten `tiktok-live-companion-extension-0.7.1` öffnen und `npm run setup` ausführen.
2. Das Setup speichert die Konfiguration, richtet den lokalen Startaufruf für den Sidepanel-Button ein und führt abschließend `npm start` im Hintergrund aus.
3. Den ausgegebenen Pairing-Code im Sidepanel eintragen.
4. Mit **Sprachdienst installieren** kann der eingerichtete Dienst später erneut im Hintergrund gestartet werden.
5. Der Dienst lauscht ausschließlich auf `127.0.0.1:43117`.

Wenn das Sidepanel `Lokaler Dienst ist veraltet` meldet, läuft noch ein alter Dienst aus einem früher entpackten Paket. In der alten PowerShell zuerst `Ctrl+C` drücken, dann den aktuellen Dienst starten:

```powershell
cd "C:\Users\silve\Downloads\tiktok-live-companion-extension-0.7.1\companion-service"
npm run setup
npm start
```

Der Pairing-Code wird in `%LOCALAPPDATA%\TikTokLiveCompanion\service.json` gespeichert und bleibt normalerweise gleich. Er ändert sich nur, wenn diese Datei gelöscht oder neu erzeugt wird. Die PowerShell mit `npm start` muss laufen, solange der lokale Dienst nicht über den registrierten Protokollstarter im Hintergrund gestartet wurde.

Das Feld **AudD API-Token** speichert den AudD-Schlüssel dauerhaft in derselben lokalen Konfiguration. Sherpa-ONNX-Stimmen werden durch den aktuellen 0.7.1-Dienst automatisch installiert oder per **Sherpa installieren** angestoßen. Falls die automatische Installation blockiert wird:

```powershell
cd "C:\Users\silve\Downloads\tiktok-live-companion-extension-0.7.1\companion-service"
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-sherpa.ps1
npm run setup
npm start
```

## Erster Einsatz

1. **Seite prüfen** liest Caption-Metadaten, sichtbare Bedienelemente und Stream-Informationen.
2. **Untertitel aktivieren** betätigt nur einen eindeutig erkannten TikTok-Menüpunkt.
3. **Hook setzen** aktiviert die Beobachtung ausschließlich für den aktuellen Tab vor dem Player-Code und lädt diesen Tab neu.
4. Nach dem Reload erscheinen Chat, Caption- und LIVE-Ereignisse, sofern TikTok sie liefert.

**Refresh** erzeugt eine neue tabbezogene Browser-Sitzungs-ID, öffnet den aktuellen LIVE-Stream in einem neuen Tab-/Dokumentkontext, aktiviert dort den Hook und schließt anschließend den bisherigen Tab. Falls der Tab nicht ersetzt werden kann, erhält er trotzdem eine neue Sitzungs-ID und wird ohne Seitencache neu geladen. Cookies, Login und andere TikTok-Tabs bleiben unverändert.

**Abspielen/Pause** bleibt auch dann bedienbar, wenn TikToks Videoelement vorübergehend fehlt oder deaktiviert ist. Die Erweiterung versucht TikToks eigene Playersteuerung erneut auszuführen.

## iOS 15 oder neuer

1. `tiktok-live-companion-ios-0.7.0-source.zip` auf macOS entpacken und `TikTokLiveCompanion.xcodeproj` in Xcode öffnen.
2. Ein Apple-Entwicklerteam und eine App-ID mit aktivierter ShazamKit-Capability auswählen.
3. Auf einem echten Gerät bauen; für die Mikrofonerkennung den Systemdialog erst beim manuellen Start bestätigen.

Unter Windows kann kein verifiziertes iOS-/IPA-Build erzeugt oder signiert werden.

## Android und HyperOS

1. `tiktok-live-companion-android-0.7.0-source.zip` entpacken.
2. Für einen UI-/Bridge-Test `mockDebug` bauen. Dieser zeigt bewusst **ShazamKit nicht konfiguriert**.
3. Für echte Erkennung Apples ShazamKit-AAR als `app/libs/shazamkit-android-release.aar` bereitstellen und `TLC_SHAZAM_TOKEN_URL` auf den konfigurierten HTTPS-Token-Endpunkt setzen.
4. `shazamDebug` bauen und die Mikrofonberechtigung erst beim Erkennungsstart erteilen.
