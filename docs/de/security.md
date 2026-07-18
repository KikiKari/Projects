# Sicherheit und Datenschutz

## Formales Release-Gate

Der vollständige Codex-Security-Scan vom 17. Juli 2026 hat alle neun Prüfumfänge abgeschlossen. Ergebnis: keine kritischen, hohen oder mittleren Findings; zwei validierte niedrige Restrisiken (Low/P3). Sie betreffen fehlende Größenbudgets an der lokalen Seiten-Bridge und bei der Dekompression beobachteter WebSocket-Nachrichten. Beide Pfade setzen bereits Codeausführung im Seitentab beziehungsweise Kontrolle über die WebSocket-Nachricht voraus und führen weder zu Kontoübernahme noch zu Cookie-, Secret- oder Cross-Origin-Zugriff.

Die gelieferten 0.5.0-Artefakte wurden für die Prüfung nicht verändert. Die empfohlenen Größen-, Parallelitäts- und Speicherbudgets werden für eine nachfolgende Version verfolgt.

## Sicherheitskontrollen

- keine Cookie-Berechtigung und kein Zugriff auf `document.cookie`;
- keine Telemetrie, Remote-Skripte oder Uploads;
- kein `eval`, `new Function` oder Zuweisung an `innerHTML`;
- `webRequest` ohne `webRequestBlocking`;
- maximal 50 bereinigte Chatnachrichten pro Tab;
- Sprachausgabe und Audioverarbeitung ausschließlich lokal;
- der Meldedialog wird nur geöffnet und nie automatisch ausgefüllt oder abgesendet.

## Datenhaltung

Stream-URLs, Chat, Captions, Profile und Diagnosedaten liegen nur in `chrome.storage.session`. Dauerhaft gespeichert werden ausschließlich `autoHook`, Vorlese-Fortsetzung und Vorleselautstärke.

## Weitere Restrisiken

Eine Seitenskript kann die `postMessage`-Bridge imitieren. Signierte Medien-URLs können während ihrer Gültigkeit Zugriff ermöglichen. TikTok kann DOM, CDN-Domains, Kompression oder Protobuf-Felder ändern und damit Fehlnegative verursachen. Browser können Bild-in-Bild, Vollbild oder Web-Audio-Routing ablehnen.

Der öffentliche Sicherheitsabschnitt enthält keine PoCs oder gültigen signierten URLs.
