# Zusätzliche Sherpa-Stimmen · 0.8.2

Die zusätzlichen Modelle werden einzeln über „Erweiterte Einstellungen“ aus dem gemeinsamen Companion-Katalog installiert. Modell und SHA-256 werden vor der Übernahme aus dem temporären Installationsverzeichnis geprüft. Gespeichert wird die stabile Stimmen-ID. Die Synthese läuft auf dem Windows-Companion-Dienst; Android und iOS spielen dessen WAV-Ausgabe über Tailscale HTTPS ab. Systemstimmen bleiben verfügbar.

| ID / Sprache | Archivgröße | Lizenzangabe der Quelldaten | SHA-256 |
|---|---:|---|---|
| `vits-piper-fr_FR-siwis-medium` · fr-FR | 67207459 Bytes | [CC-BY-4.0](https://huggingface.co/rhasspy/piper-voices/raw/main/fr/fr_FR/siwis/medium/MODEL_CARD) | `375909aa30842b3a4efa10b1beb1d761af792960ae6873b4d53889f96c66195b` |
| `vits-piper-es_ES-davefx-medium` · es-ES | 67184952 Bytes | [CC0-1.0](https://huggingface.co/rhasspy/piper-voices/raw/main/es/es_ES/davefx/medium/MODEL_CARD) | `a3f6beb54a9cb893279f72978a22f807a4d9fc9c7848157b524d5cc7b7f58b22` |
| `vits-piper-it_IT-paola-medium` · it-IT | 67221173 Bytes | [CC0-1.0](https://huggingface.co/rhasspy/piper-voices/raw/main/it/it_IT/paola/medium/MODEL_CARD) | `7541f75778afa164e44e34baaef63befad7698595df26a95ca944b63ef1a16b4` |
| `vits-piper-pt_BR-faber-medium` · pt-BR | 67183065 Bytes | [CC0-1.0](https://huggingface.co/rhasspy/piper-voices/raw/main/pt/pt_BR/faber/medium/MODEL_CARD) | `7add3f923ad6bc25ca8a192805fd1a64d1b3893e4611c4a9719545a825039a83` |
| `vits-piper-nl_NL-pim-medium` · nl-NL | 67240538 Bytes | [CC0-1.0](https://huggingface.co/rhasspy/piper-voices/raw/main/nl/nl_NL/pim/medium/MODEL_CARD) | `e78ed301bf6fc66561a04c110754cd6928d772630a3b80b09a83f89410130171` |
| `vits-piper-pl_PL-gosia-medium` · pl-PL | 67211182 Bytes | [CC0-1.0](https://huggingface.co/rhasspy/piper-voices/raw/main/pl/pl_PL/gosia/medium/MODEL_CARD) | `75bd34dcbdc4dd98d763954756b4b34b4208100497c836381542e4d73dcefa9c` |
| `vits-piper-tr_TR-dfki-medium` · tr-TR | 67201221 Bytes | [CC-BY-NC-SA-4.0](https://huggingface.co/rhasspy/piper-voices/raw/main/tr/tr_TR/dfki/medium/MODEL_CARD) | `b63babaefcdd63202c7079aba25b72a2013825ad5895e2aeff03d1ae5a5b3bbf` |

Die Lizenzspalte gibt die im jeweiligen Upstream-Modellblatt ausgewiesene Datenlizenz wieder. Insbesondere Türkisch enthält eine Einschränkung auf nichtkommerzielle Nutzung. Die verlinkten Modellblätter und ihre Hinweise sind vor Nutzung maßgeblich.

Alle sieben Einträge: ein Sprecher, 22.050 Hz, CPU-Ausführung mit Sherpa-ONNX 1.13.2 auf Windows x64. Der installierte Umfang enthält ONNX-Modell, tokens.txt und espeak-ng-data. Archivgröße und entpackter Speicherbedarf sind unterschiedliche Größen. Download-URLs, Quellen und Laufzeitanforderungen stehen im versionierten `voice-catalog.json`.

Französisch: Siwis; Spanisch: Davefx; Italienisch: Paola; Portugiesisch: Faber (Brasilien); Niederländisch: Pim; Polnisch: Gosia; Türkisch: DFKI. Bestehende Stimmen und ihre IDs bleiben erhalten.

Fehlt das ausgewählte Modell oder ist der Dienst nicht erreichbar, zeigt die App den Fehler. Ein Cloud-Anbieter wird nicht automatisch eingeschaltet.
