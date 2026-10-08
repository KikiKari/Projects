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

- Native VLC-Adapter sind als Kandidat angeschlossen (Android/JNI/AudioTrack, iOS/AVAudioEngine). Der erste Gerätetest deckte einen PCM-Formatfehler auf; die S16N-Korrektur besteht auf dem Redmi (Nachweis unten), der korrigierte iOS-Simulatorlauf besteht ebenfalls. Siehe `native-audio-integration.md`. Bisherige grüne native Grenzwerttests ohne Eingangskontrolle gelten nicht als Abnahme.
- Edge-Live-Abnahme am 2026-10-09 vom Auftraggeber als vollständig bestanden bestätigt. Nachweisart: Nutzerabnahme. Kein offener Edge-Release-Punkt.
- Android-Testbuild wurde als Upgrade über 0.8.1 auf dem Redmi installiert; der Hash der Einstellungsdatei blieb identisch. Der korrigierte native PCM-Gerätetest besteht; die vollständige Live-/Audio-Abnahme bleibt offen. 40 iOS-Simulatortests einschließlich nativer PCM-Ausgabe und Stop bestanden; eine vollständige Audio-/Player-Abnahme ist offen.
- Die AudioWorklet-Ladbarkeit in den mobilen WebViews muss noch geprüft werden.
- Die mobilen Branches sind noch nicht mit diesem Kandidaten synchronisiert.

0PE-177 und das Release-Gate bleiben offen. 0PE-175/176 und die Veröffentlichung 0.8.2 sind noch nicht umgesetzt.
Die bestehende Versionsnummer bleibt bis zum Release-Gate unverändert.

## Redmi: korrigierter PCM-Test am 2026-10-08

Kandidat `e5b3b2f519554cfbf46debbc3d12b317fc8da9fe`, vorhandene Debug-Signatur,
Version weiterhin 0.8.1 / Build 9. Die manuell installierte Test-App konnte
anschließend per ADB aktualisiert werden. Instrumentation auf Redmi Note 11S:
`NativeVlcAudioTest.decodedPcmPassesThroughLimiterAndOutputStops`: OK (1 test).

| Schutz | Eingang dBFS | Ausgang dBFS |
|---|---:|---:|
| aus | -1.731407 | -1.731407 |
| 25 % | -1.731407 | -10.5 |
| 75 % | -1.731407 | -23.5 |
| 100 % | -1.731407 | -30.0 |

Nachweis: bekannte PCM16-WAV-Datei durch VLC-Decoder, JNI, gemeinsamen Limiter
und AudioTrack-Schreibpfad sowie Stop. Kein Nachweis der physischen
Lautsprecherausgabe, Sprachqualität, Live-Streams oder A/V-Synchronität.
Lokale Dateien: `.artifacts/0pe177-native-e5b3b2f/` im Projektarbeitsverzeichnis.

SHA-256:
- app.apk: `0c1d6b56255f5dda49dd51026ae86eb48ed58324af38ac97c29ab0dd23b3cfae`
- test.apk: `7a26a8d51d1db1f24188df71592884dbf5bfaee2684fe36a12f552e8a70ffd1c`

Der iOS-Lauf auf e5b3b2f scheiterte vor Testbeginn an einem ungültigen UTF-8-Byte
in ContentView.swift. Korrektur: `5738cf8`; erneuter Simulatorlauf 37849630208.

## iOS-Simulator: bestätigter Lauf

Commit `5738cf829777b02880043e2a9d5d3e72ef4e1280`, GitHub Actions
[37849630208](https://github.com/KikiKari/Projects/actions/runs/37849630208): SUCCESS.
40 Testfälle auf iPhone-16-Pro-Simulator bestanden. Der native Test
`testNativeVlcPcmIsLimitedAndStops` lief 3,507 Sekunden und prüft bekannte
PCM16-Eingangsspitzen, Bypass, 25/75/100-Prozent-Grenzen sowie Stop nach jeder Stufe.
Die Ausgabe-Meldung erfolgt nach AVAudioPlayerNode DataPlayedBack.
Persistenz-/Migrationsprüfungen bestanden ebenfalls. Vollständige UI-,
Player-Lebenszyklus- und A/V-Abnahme bleiben getrennte Prüfpunkte.
