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

1. Im Sidepanel **Sprachdienst starten** wählen. Falls die einmalige Einrichtung noch fehlt, erscheint ausschließlich **Installation abschließen!**; Befehle und Erweiterungs-ID werden nicht eingeblendet.
2. **Installation abschließen!** öffnet PowerShell im tatsächlichen Dienstverzeichnis, führt das Setup mit der richtigen Erweiterungs-ID aus und startet den Dienst automatisch.
3. Der lokal erzeugte Pairing-Code wird automatisch in das Sidepanel übernommen. Nach erfolgreichem Health-Check verschwindet der Installationsbutton.
4. Spätere Starts verwenden den registrierten lokalen Aufruf `tiktok-live-companion://start`; ein kurzlebiger Nonce schützt die Pairing-Übergabe.
5. Der Dienst lauscht ausschließlich auf `127.0.0.1:43117`.

Wenn das Sidepanel `Lokaler Dienst ist veraltet` meldet, läuft noch ein Dienst aus einem früher entpackten Paket. Diesen Prozess beenden, die aktuelle entpackte Erweiterung laden und **Installation abschließen!** erneut wählen. Ein zusätzlicher manueller Start ist nicht erforderlich; ein bereits laufender Dienst wird erkannt, statt einen zweiten Prozess zu starten.

Der Pairing-Code wird in `%LOCALAPPDATA%\TikTokLiveCompanion\service.json` gespeichert und bleibt normalerweise gleich. Er ändert sich nur, wenn diese Datei gelöscht oder neu erzeugt wird.

Das optionale Feld **AudD API-Token** speichert den AudD-Schlüssel dauerhaft in derselben lokalen Konfiguration. Deutsch und Englisch sind nach dem Grundsetup verfügbar. Weitere bestätigte Sherpa-ONNX-Stimmen werden erst bei Auswahl geladen; nicht bestätigte Modelle erscheinen nicht.

Pairing-Code und AudD-Token werden vor dem Speichern geprüft; leere, falsche, deaktivierte oder nicht prüfbare Werte werden nicht übernommen. Sobald Sprachdienst und Sherpa erfolgreich aktiv sind, blendet das Sidepanel beide Eingabefelder platzsparend aus. Sollen Pairing-Code oder AudD-Token später geändert oder neu gesetzt werden, das Plugin entfernen und anschließend erneut hinzufügen; danach werden die Einrichtungsfelder wieder angezeigt.

## Erster Einsatz

1. **Seite prüfen** liest Caption-Metadaten, sichtbare Bedienelemente und Stream-Informationen.
2. **Untertitel aktivieren** betätigt nur einen eindeutig erkannten TikTok-Menüpunkt.
3. **Hook setzen** aktiviert die Beobachtung ausschließlich für den aktuellen Tab vor dem Player-Code und lädt diesen Tab neu.
4. Nach dem Reload erscheinen Chat, Caption- und LIVE-Ereignisse, sofern TikTok sie liefert.

**Refresh** erzeugt eine neue tabbezogene Browser-Sitzungs-ID, öffnet den aktuellen LIVE-Stream in einem neuen Tab-/Dokumentkontext, aktiviert dort den Hook und schließt anschließend den bisherigen Tab. Falls der Tab nicht ersetzt werden kann, erhält er trotzdem eine neue Sitzungs-ID und wird ohne Seitencache neu geladen. Cookies, Login und andere TikTok-Tabs bleiben unverändert.

**Abspielen/Pause** bleibt auch dann bedienbar, wenn TikToks Videoelement vorübergehend fehlt oder deaktiviert ist. Die Erweiterung versucht TikToks eigene Playersteuerung erneut auszuführen.

## iOS 15 oder neuer

1. `tiktok-live-companion-ios-0.7.1-source.zip` auf macOS entpacken und `TikTokLiveCompanion.xcodeproj` in Xcode öffnen.
2. Ein Apple-Entwicklerteam und eine App-ID mit aktivierter ShazamKit-Capability auswählen.
3. Auf einem echten Gerät bauen; für die Mikrofonerkennung den Systemdialog erst beim manuellen Start bestätigen.

Unter Windows kann kein verifiziertes iOS-/IPA-Build erzeugt oder signiert werden.

## Android und HyperOS

1. `tiktok-live-companion-android-0.7.1-source.zip` entpacken.
2. Für einen UI-/Bridge-Test `mockDebug` bauen. Dieser zeigt bewusst **ShazamKit nicht konfiguriert**.
3. Für echte Erkennung Apples ShazamKit-AAR als `app/libs/shazamkit-android-release.aar` bereitstellen und `TLC_SHAZAM_TOKEN_URL` auf den konfigurierten HTTPS-Token-Endpunkt setzen.
4. `shazamDebug` bauen und die Mikrofonberechtigung erst beim Erkennungsstart erteilen.
