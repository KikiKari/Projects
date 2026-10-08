# 0PE-177: Arbeitsstand, keine Freigabe

Ausgangspunkt: Browserbranch `0a1ae811b74f8a8333c61ab9e86eb1eb2ba5324a`.
Die sechs Lieferdateien aus 0.8.1 wurden lokal gegen die vorhandene SHA-256-Liste geprüft.
Der Browser-Liefercommit `190b0907` unterscheidet sich vom Ausgangspunkt nur im Releasebericht.
Die älteren, teilweise uncommitteten Checkouts wurden nicht verändert.

## Implementiert im Kandidaten

- Gemeinsamer, stereogekoppelter Sample-Peak-Limiter für Browser und mobile WebViews.
- 5 ms Vorlauf, 60 ms Freigabezeit; Stärke 0–100 bildet auf -4 bis -30 dBFS ab.
- AudioParam-Steuerung verhindert die beim Offline-Rendern nachgewiesene Race Condition mit einer initialen Port-Nachricht.
- Keine statische Makeup-Absenkung. Signale unter dem Grenzwert bleiben nach Erholung unverändert.
- Gemeinsamer Befehl `set-limiter { enabled, strength }`; alte Grenzwert-Payloads bleiben lesbar.
- Android stellt die Stärke aus dem bisherigen gespeicherten Grenzwert wieder her.
- Eingang, Ausgang, Dämpfung und Vorlauf sind Messwerte; fehlende Messwerte bleiben unbekannt.
- Mobile UI nimmt einen fehlgeschlagenen Web-Audio-Schutz nicht als aktiv an.

## Synthetische Prüfkriterien

Der gerenderte Ausgang darf die Sollgrenze höchstens um 0,05 dB überschreiten.
Mit steigender Stärke muss dieselbe Spitze monoton stärker gedämpft werden.
Ein 220-Hz-Signal mit -40 dBFS darf höchstens 0,05 dB verändert werden.
Der digitale Vorlauf muss unter 10 ms bleiben. Dies ist kein True-Peak-/Intersample-Peak-Nachweis.

Im eingebauten Chromium-Browser mit OfflineAudioContext gemessener einzelner Impuls:

| Stärke | Ohne Schutz | 0.8.1-Kompressor | Kandidat |
|---|---:|---:|---:|
| 25 % | -0,45 dBFS | -5,98 dBFS | -10,50 dBFS |
| 75 % | -0,45 dBFS | -17,40 dBFS | -23,50 dBFS |
| 100 % | -0,45 dBFS | -20,08 dBFS | -30,00 dBFS |

Alle 28 Renderfälle des Harness wurden ausgeführt; seine Begrenzungs- und Leisesignalprüfungen bestanden.
Das leise Sinussignal ist ein technisches Sprachband-Testsignal, keine Sprachverständlichkeitsabnahme.
Reproduzierbar über `plugin-source/tests/peak-limiter.html` auf einem lokalen HTTP-Server.
DSP-Tests: `node --test plugin-source/scripts/test_peak_limiter.cjs`.

## Offene Voraussetzungen

- Native VLC-Adapter sind als Kandidat angeschlossen (Android/JNI/AudioTrack, iOS/AVAudioEngine). Der erste Gerätetest deckte einen PCM-Formatfehler auf; die S16N-Korrektur muss erneut bestehen. Siehe `native-audio-integration.md`. Bisherige grüne native Grenzwerttests ohne Eingangskontrolle gelten nicht als Abnahme.
- Keine Abnahme mit installierter Erweiterung und realem Stream; keine Hörprüfung auf Pumpen/Verzerrung und keine A/V-Synchronitätsabnahme.
- Android-Testbuild wurde als Upgrade über 0.8.1 auf dem Redmi installiert; der Hash der Einstellungsdatei blieb identisch. Der native Gerätetest ist wegen des gefundenen Formatfehlers noch nicht abgenommen. Die iOS-Simulator-Vertragstests bestanden; eine vollständige Audio-/Player-Abnahme ist offen.
- Die AudioWorklet-Ladbarkeit unter der tatsächlichen TikTok-/WebView-Policy muss noch geprüft werden.
- Die mobilen Branches sind noch nicht mit diesem Kandidaten synchronisiert.

0PE-177 und das Release-Gate bleiben offen. 0PE-175/176 und die Veröffentlichung 0.8.2 sind noch nicht umgesetzt.
Die bestehende Versionsnummer bleibt bis zum Release-Gate unverändert.
