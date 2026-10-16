# Sherpa-Stimmen

Der Katalog enthält 50 auswählbare Stimmen. Die bestehenden 33 IDs bleiben erhalten.
Kyrillisch, Asiatisch, Abjad und Indisch enthalten jeweils drei zusätzliche Stimmen.
„Effekt Stimmen“ bietet fünf Sprecherstile („Stil 1“ bis „Stil 5“), keine Nachbildungen
benannter Personen. Diese Stile verwenden Deutsch und die Supertonic-Sprecher-IDs 5–9.

Modelle werden bei Auswahl installiert. Mehrere Supertonic-Stimmen teilen dasselbe
Modellverzeichnis; Sprache und Sprecher-ID werden pro Stimme gespeichert. Die
Modelldateien sind nicht Bestandteil der Extension oder der mobilen Apps.

Unter Windows verwendet die Synthese die offizielle Sherpa-ONNX-Python-API 1.13.4
mit UTF-8-JSON über stdin. Damit bleiben nichtlateinische Texte erhalten. Der
Installer benötigt einen vorhandenen Python-3-Launcher und richtet eine separate
virtuelle Umgebung unter dem Modellverzeichnis ein. Getestet wurde Python 3.14
auf Windows x64. Die Paketversionen stehen in `sherpa-runtime-requirements.txt`.
Eine globale Python-Installation oder bestehende Modellverzeichnisse werden nicht ersetzt.

Bestehende Stimmen-IDs und Dienstkopplung bleiben erhalten. Ein neuer Dienstkatalog
ist erforderlich, damit die zusätzlichen Stimmen auf Browser, Android und iOS
angeboten werden. Ein App-Update allein ersetzt den laufenden Companion-Dienst nicht.

## Herkunft und Lizenzen

Jeder neue Katalogeintrag enthält Originalquelle, Archiv-URL, Größe, SHA-256,
Sprache, Sprecher-ID und Lizenzquelle. Die beigefügten Modellkarten unterscheiden
zwischen Datensatz- und Modelllizenz. Die MIT-Lizenz des Sherpa-Codes ersetzt
keine modellspezifischen Bedingungen.

- Denis, Dmitri, Ganji und Reza Ibrahim: Modellkarten nennen CC0 für die Datensätze.
- Ruslan und Pratham: CC BY-NC-SA 4.0 laut Modellkarten.
- Xiao Ya: nichtkommerzielle Nutzung laut Data-Baker-/Modellkarte.
- Nepali Google: CC BY-SA 4.0, 18 Sprecher; der Katalogeintrag verwendet Sprecher 0.
- Gyro: ursprüngliche Modellveröffentlichung von gyroing nennt MIT.
- Rohan: IIT Madras Indic TTS EULA; die Modellkarte verweist auf den Lizenztext.
- Supertonic 3: OpenRAIL-M für die Modelle; die im konvertierten Archiv enthaltene
  MIT-Datei ist nicht als Ersatz für die Modelllizenz zu verstehen.

Rohan/Indic-TTS-Zuschreibung:

COPYRIGHT 2016 TTS Consortium, TDIL, Meity represented by Hema A Murthy & S Umesh,
Department of Computer Science and Engineering and Electrical Engineering,
IIT Madras. ALL RIGHTS RESERVED.

Die Original-Modellkarten und Supertonic-Modelllizenz liegen in `model-notices`.
Der vollständige Indic-TTS-Text wurde über eine gepinnte Spiegelkopie gesichert;
der in der Modellkarte genannte IITM-Endpunkt war beim Abruf nicht erreichbar.
Diese Herkunftsgrenze ist in den Liefernachweisen dokumentiert.
