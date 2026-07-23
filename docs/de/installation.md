# Installation

## Voraussetzungen

- Microsoft Edge oder Google Chrome ab Version 114
- ein öffentlicher TikTok-LIVE-Tab
- die entpackte Erweiterung aus `tiktok-live-companion-extension-0.7.2.zip`

## Schritte

1. ZIP-Datei entpacken.
2. `edge://extensions` oder `chrome://extensions` öffnen.
3. **Entwicklermodus** aktivieren.
4. **Entpackte Erweiterung laden** wählen.
5. Den Ordner auswählen, in dem `manifest.json` liegt.
6. Einen öffentlichen TikTok-LIVE-Tab öffnen und auf das Erweiterungssymbol klicken.

## Optionaler lokaler Sprach- und Songdienst

1. Den sichtbaren Installer `tiktok-live-companion-setup-0.7.2-unsigned-dev.exe` bewusst starten. Das Entwicklungsartefakt ist nicht codesigniert.
2. Danach im Sidepanel **Verbinden** wählen. Native Messaging übernimmt die interne Authentifizierung; ein Pairing-Code wird nicht eingegeben.
3. Falls Songerkennung verwendet wird, den optionalen **AudD API-Token** im Sidepanel einmalig eingeben. Das Feld wird danach geleert und der Token ausschließlich in der lokalen Dienstkonfiguration gespeichert.
4. Der Dienst lauscht ausschließlich auf `127.0.0.1:43117`.

Manueller Fallback ohne Installer: `tiktok-live-companion-service-0.7.2.zip` entpacken, zuerst `npm run setup` und danach ausdrücklich `npm start` ausführen.

## Erster Einsatz

1. **Seite prüfen** liest Caption-Metadaten, sichtbare Bedienelemente und Stream-Informationen.
2. **Untertitel aktivieren** betätigt nur einen eindeutig erkannten TikTok-Menüpunkt.
3. **Hook setzen** registriert die Beobachtung vor dem Player-Code und lädt den Tab neu.
4. Nach dem Reload erscheinen Chat, Caption- und LIVE-Ereignisse, sofern TikTok sie liefert.

**Refresh** leert nur flüchtige Erweiterungsdaten des aktuellen Tabs, aktiviert den Hook erneut und lädt TikTok ohne Seitencache. Cookies und Login bleiben unverändert.

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
