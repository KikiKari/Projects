# 0PE-177: Native Audioanbindung

Status: in Umsetzung; kein Laufzeit- oder Release-Nachweis.

## Nachgewiesener Zugriff

Android bindet libvlc-all 3.7.5 ein. Die Java-API hat keine PCM-Callback-Methode,
aber `MediaPlayer.getInstance()` ist öffentlich. Die tatsächlich eingebundene
x86_64-Bibliothek wurde mit `javap`, `nm` und `objdump` geprüft: Der Getter
liefert denselben nativen Player-Zeiger, den `MediaPlayer.nativePlay` an
`libvlc_media_player_play` übergibt. `libvlc_audio_set_callbacks` und
`libvlc_audio_set_format` sind in libvlc.so exportiert.
Die Anbindung darf den Java-Wrapper nicht freigeben, solange Callbacks laufen.
Es werden keine privaten Java-Felder oder fest codierten Struktur-Offsets verwendet.

MobileVLCKit 3.7.3 wird separat anhand seines tatsächlich ausgelieferten Headers
geprüft. Der Android-Nachweis überträgt sich nicht auf iOS.

## Gemeinsamer Signalvertrag

`mobile/shared/native/tlc_peak_limiter.h` verarbeitet interleaved Float-PCM mit
demselben Algorithmus wie `createPeakLimiter` im Browser: 5 ms Vorlauf,
stereogekoppelte Spitzenbegrenzung, 60 ms Freigabezeit, Stärke 0–100,
Grenze -4 bis -30 dBFS. Kein dauerhafter Makeup-Gain.
Allokation erfolgt beim Formatwechsel, nicht pro Sample. Flush setzt den
Verlauf zurück. Drain muss den Vorlauf ausgeben. Ein deaktivierter Schutz
gibt das um denselben Vorlauf verzögerte Originalsignal aus.

36 PCM-Vergleiche gegen die JavaScript-Implementierung bestehen bei
44,1/48/96 kHz, 1/2/6 Kanälen, aus/25/75/100 Prozent, einschließlich
Blockgrenzen, Impulsen, hochfrequenten Signalen und ungültigen Samples.
Maximale erlaubte Sample-Abweichung: 1e-7; C-Prüfung mit UndefinedBehaviorSanitizer.

## Adapter und Lebenszyklus

Die libVLC-Audio-Callbacks ersetzen die VLC-Audioausgabe vollständig. Daher
gehören ein tatsächlicher Audio-Sink, PTS-Zuordnung, Pause/Resume, Flush,
Drain, Lautstärkeregelung und Abbruch zur Integration. Ein Callback, der nur
Messwerte berechnet und die ursprüngliche Audioausgabe weiterlaufen lässt,
erfüllt den Schutz nicht.

Android verwendet AudioTrack; iOS benötigt eine native Audioausgabe mit
kontrolliertem PCM-Zugriff. Callback-Registrierung erfolgt vor `play`.
Stop muss alle Callbacks beenden, bevor Sink, JNI-Referenz oder Limiter
freigegeben werden. UI-Konfigurationswechsel werden atomar übernommen.
Fehler melden Schutz nicht verfügbar; sie dürfen keinen aktiven Schalter
bestätigen. WebView-Telemetrie darf den Zustand des aktiven VLC-Pfads nicht
überschreiben.

## Noch erforderliche Abnahmen

- Native Ausgabe enthält tatsächlich die begrenzten PCM-Samples.
- Gleiches Testmaterial mit Schutz aus/25/75/100 auf beiden Plattformen.
- Pause/Resume, Seek/Flush, Streamwechsel, Browser/Player-Wechsel und Abbau
  ohne Restton, Callback nach Freigabe oder blockierte UI.
- Gemessene zusätzliche Verzögerung höchstens 10 ms; A/V-Synchronität getrennt.
- Sprache und gemischtes Material auf Pumpen und Verzerrung abhören.
- Android-Gerät und iOS-Simulator funktional ausführen.

Die bisherigen JVM-/Simulator-Vertragstests ersetzen diese Abnahmen nicht.
