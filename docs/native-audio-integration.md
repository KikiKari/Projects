# 0PE-177: Native Audioanbindung

Status: in Umsetzung; kein Laufzeit- oder Release-Nachweis.

## Im Gerätetest gefundener Formatfehler

Der erste Redmi-Lauf des Kandidaten meldete zunächst einen Monotoniefehler.
Die ergänzte Diagnose zeigte 498,49 dBFS für eine WAV-Datei mit etwa -1,73 dBFS.
Das war ein echter Adapterfehler: S16N-Bytes wurden als Float-PCM interpretiert.
Der daraufhin grüne reine Grenzwertvergleich ist **kein gültiger Abnahmenachweis**.
Auch der vorherige iOS-Test bei 100 Prozent genügt ohne Eingangskontrolle nicht.

Die [offizielle VLC-3-Implementierung von amem](https://github.com/videolan/vlc/blob/3.0.x/modules/audio_output/amem.c)
unterstützt S16N; eine FL32-Anforderung stellt dessen Sampledaten nicht auf Float um.
Beide Adapter fordern nun S16N an und konvertieren genau die gelieferten Samples
mit `sample / 32768.0` in den gemeinsamen Float-Limiter. Die nativen Tests prüfen
zusätzlich den bekannten Eingangspegel des PCM16-WAV-Testmaterials.
Diese Korrektur muss noch auf Gerät und Simulator erneut bestehen.

## Nachgewiesener Zugriff

Android bindet libvlc-all 3.7.5 ein. Die Java-API hat keine PCM-Callback-Methode,
aber `MediaPlayer.getInstance()` ist öffentlich. Die tatsächlich eingebundene
x86_64-Bibliothek wurde mit `javap`, `nm` und `objdump` geprüft: Der Getter
liefert denselben nativen Player-Zeiger, den `MediaPlayer.nativePlay` an
`libvlc_media_player_play` übergibt. `libvlc_audio_set_callbacks` und
`libvlc_audio_set_format` sind in libvlc.so exportiert.
Die Anbindung darf den Java-Wrapper nicht freigeben, solange Callbacks laufen.
Es werden keine privaten Java-Felder oder fest codierten Struktur-Offsets verwendet.

Der tatsächlich ausgelieferte MobileVLCKit-3.7.3-Header bietet
`initWithLibVLCInstance:andLibrary:` öffentlich an. Die zugehörige
[Implementierung bei 319ed2c0](https://github.com/videolan/vlckit/blob/319ed2c0/Sources/VLCMediaPlayer.m)
übernimmt den Zeiger ohne zusätzlichen Retain und gibt ihn im Deallocator frei.
Ihr `stop` ist asynchron. Der iOS-Adapter bleibt deshalb bis zum bestätigten
Stop-Ereignis erhalten. Androids geprüfte nativeStop-Methode ruft dagegen
`libvlc_media_player_stop` synchron auf.

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

Der Arbeitsstand verbindet Android mit AudioTrack und iOS mit AVAudioEngine /
AVAudioPlayerNode. Beide erhalten begrenztes Float-PCM aus dem gemeinsamen Kernel.
Callback-Registrierung erfolgt vor `play`.
Stop muss alle Callbacks beenden, bevor Sink, JNI-Referenz oder Limiter
freigegeben werden. UI-Konfigurationswechsel werden atomar übernommen.
Fehler melden Schutz nicht verfügbar; sie dürfen keinen aktiven Schalter
bestätigen. WebView-Telemetrie darf den Zustand des aktiven VLC-Pfads nicht
überschreiben.
