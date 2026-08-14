# Sicherheit und Datenschutz

## Formales Release-Gate

Der vollständige Codex-Security-Scan vom 17. Juli 2026 hat alle neun Prüfumfänge abgeschlossen. Ergebnis: keine kritischen, hohen oder mittleren Findings; zwei validierte niedrige Restrisiken (Low/P3). Sie betreffen fehlende Größenbudgets an der lokalen Seiten-Bridge und bei der Dekompression beobachteter WebSocket-Nachrichten. Beide Pfade setzen bereits Codeausführung im Seitentab beziehungsweise Kontrolle über die WebSocket-Nachricht voraus und führen weder zu Kontoübernahme noch zu Cookie-, Secret- oder Cross-Origin-Zugriff.

Version 0.7.0 ergänzt Mobile-WebView-Bridges, native Mikrofon-/PCM-Wege und einen Android-Token-Endpunkt. Diese neuen Grenzen werden zusätzlich zur Browser-Erweiterung geprüft; nicht auf realer Hardware gebaute oder getestete Plattformstände werden ausdrücklich gekennzeichnet.

## Sicherheitskontrollen

- keine Cookie-Berechtigung und kein Zugriff auf `document.cookie`;
- keine Telemetrie oder Remote-Skripte; nur ein ausdrücklicher Songerkennungs-Klick überträgt einen kurzen Audioausschnitt an AudD;
- Mobile-WebView-Nachrichten nur vom Hauptframe `https://www.tiktok.com`, höchstens 64 KiB und nur für bekannte Ereignis- und Befehlstypen;
- der Media-Services-Private-Key bleibt im Vercel-Secret; Android erhält nur kurzlebige ES256-Developer-Tokens;
- mobile Audioerkennung startet nur durch Nutzeraktion und endet nach spätestens zwölf Sekunden;
- kein `eval`, `new Function` oder Zuweisung an `innerHTML`;
- `webRequest` ohne `webRequestBlocking`;
- maximal 50 bereinigte Chatnachrichten pro Tab;
- Sprachausgabe und Verstärkung lokal; der Begleitdienst bindet nur an `127.0.0.1` und erzwingt Pairing, Origin-Prüfung und Größenlimits;
- der Meldedialog wird nur geöffnet und nie automatisch ausgefüllt oder abgesendet.

## Datenhaltung

Stream-URLs, Chat, Captions, Profile, Teilnehmeraggregate und Diagnosedaten liegen im Browser in `chrome.storage.session` und mobil nur im Arbeitsspeicher. Einstellungen und dauerhafte Mute-Identitäten liegen in `chrome.storage.local`, UserDefaults beziehungsweise DataStore; das AudD-Token verbleibt ausschließlich in der lokalen Dienstkonfiguration.

## Weitere Restrisiken

Eine Seitenskript kann die `postMessage`-Bridge imitieren. Signierte Medien-URLs können während ihrer Gültigkeit Zugriff ermöglichen. TikTok kann DOM, CDN-Domains, Kompression oder Protobuf-Felder ändern und damit Fehlnegative verursachen. Browser können Bild-in-Bild, Vollbild oder Web-Audio-Routing ablehnen.

Der öffentliche Sicherheitsabschnitt enthält keine PoCs oder gültigen signierten URLs.
