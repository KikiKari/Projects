# 0PE-175 und 0PE-176 — Umsetzung

Stand: 2026-10-09, Browser/Android/iOS im gemeinsamen Implementierungscheckout.

## 0PE-175

`filterExternalSpeechTriggers` ist standardmäßig aus und wird dauerhaft gespeichert.
Die Prüfung erfolgt am Chatinhalt vor Namenszusätzen und vor der Sprachausgabe:
Ein Punkt nach vorangestellten Leerzeichen unterdrückt die Companion-Ausgabe.
Automatisches und manuelles Vorlesen verwenden diese Regel. Normale Texte und
Punkte innerhalb eines Satzes bleiben unverändert. Chatdarstellung und Protokolle
werden durch den Filter nicht entfernt. Game-Mode bleibt unabhängig schaltbar.

## 0PE-176

Titel und Buttontexte folgen der Zuordnung im Issue. Vorlesen und Connection
verwenden jeweils einen On/Off-Schalter. Der Browser bestätigt den Schaltauftrag,
bevor er den Vorlesezustand ändert; ein fehlgeschlagener Connection-Reload setzt
den vorherigen Zustand zurück. Die mobilen Connection-Schalter übernehmen die
Bestätigung aus der Bridge. Off unterdrückt die Companion-Datenzufuhr auch über
den Recovery-Pfad und Subframes; die Stream-Wiedergabe bleibt bedienbar.

Auto-Chat Refresh und Minutenwert liegen in den Sprach-/Chat-Einstellungen.
Das Rad direkt nach Player öffnet die Connection-Einstellungen mit Hook-Reconnect,
Player-Recovery und ihren Sekundenwerten. Die bisherigen Statuszeilen bleiben
im Modul. Bestehende Browser- und Recovery-Speicherschlüssel werden weiterverwendet.
Die nativen Apps speichern die zusätzliche Refresh-Konfiguration ebenfalls.
Browser beendet auf Android/iOS den internen VLC-Player und kehrt zur WebView zurück.

## Reproduzierbare Prüfungen

- `node plugin-source/scripts/test_extension.cjs`: Bestanden; 55 Worker-Tests,
  14 Punktfilterfälle und 4 gezielte Tests für manuelle/automatische Ausgabe,
  Schaltfehler, Dialogfokus und Tab/Shift+Tab. Bestehende Player-Wechseltests bestehen.
- `node plugin-source/scripts/test_android_recovery.cjs`: 8 Tests bestanden,
  einschließlich Connection Off/On für beide nativen Bridge-Empfänger.
- `node plugin-source/scripts/test_mobile_bridge.cjs`: Bestanden, einschließlich
  Vergleich der Bridge-Kopien.
- `python plugin-source/scripts/test_mobile_projects.py`: Bestanden.
- Android: 48 Unit-Tests ohne Fehler im bestehenden Docker-SDK bestanden;
  APK-Bau und abschließender Lauf für `df64fb3` bestanden (48/48).
- iOS: 45 Simulator-Tests für `df64fb3` bestanden:
  https://github.com/KikiKari/Projects/actions/runs/37855704600.
  Abschließende iOS-Textkorrektur `b0c5754`: ebenfalls 45/45 Simulator-Tests bestanden
  https://github.com/KikiKari/Projects/actions/runs/37856439444.


## SHA-256 der gemeinsamen Quelldateien

- Core (Browser/Android/iOS): `b6f0da2aba8e9ab36a7b413cd82e39fb997954de8b5218d2a46066672cb2f017`
- WebView-Bridge (gemeinsame Quelle/Android/iOS): `88db1ace22f4990b9d2c6de67ee1e8faebf6ba80d3fae0564f28d3ecef75b9d4`
- Mobile Recovery (Android/iOS): `5be82703b10290871466a718049728046b8ad92a7767128e4c1257848a00debb`
