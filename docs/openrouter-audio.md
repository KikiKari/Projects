# Optionales Cloud-Audio über OpenRouter

Stand: 9. Oktober 2026. Sherpa bleibt die lokale Sprachsynthese. Dieser Vorschlag aktiviert keinen Cloud-Anbieter und löst keine kostenpflichtigen Sprachaufträge aus.

## Eignung

Für Chat-Vorlesen eignet sich `elevenlabs/eleven-v4-turbo`: Der Anbieter positioniert es für schnelle Antworten. `elevenlabs/eleven-v4` ergänzt ausdrucksstarke Sprache und Audio-Tags. `elevenlabs/scribe-v2` ist dagegen Spracherkennung (STT); es ist keine Vorlesestimme. Sprecherzuordnung und Wortzeitstempel wären eigenständige Transkriptionsfunktionen.

Quelle: [OpenRouter-Ankündigung](https://openrouter.ai/blog/announcements/elevenlabs-on-openrouter/).

## Schnittstellen und Formate

TTS: `POST /api/v1/audio/speech` mit `model`, `input`, expliziter `voice` und `response_format: "mp3"`. Die Antwort enthält Audiobytes. Ohne Formatwahl liefert der Dienst PCM; für die vorhandenen mobilen Player ist explizites MP3 der einfachere Integrationsweg. `voice` unterstützt Namen der 21 vorgegebenen Stimmen oder ElevenLabs-Voice-IDs. Eigene geklonte Stimmen erfordern laut Ankündigung BYOK. v4/v4 Turbo haben jeweils 10.000 Zeichen Anfragegrenze und unterstützen keine vom Standard abweichende Geschwindigkeit.

STT: `POST /api/v1/audio/transcriptions`; Audio und Transkriptionsmodell senden, JSON empfangen. Scribe kann Wortzeitstempel, Sprecherlabels und Audioereignisse liefern. Der angekündigte Start umfasst kein Scribe-Realtime-WebSocket. Uploads sind laut Ankündigung auf 25 MB begrenzt; sehr lange Anfragen können am 180-Sekunden-Upstream-Timeout scheitern.

Quellen: [TTS](https://openrouter.ai/docs/guides/overview/multimodal/tts), [STT](https://openrouter.ai/docs/guides/overview/multimodal/stt), [Ankündigung](https://openrouter.ai/blog/announcements/elevenlabs-on-openrouter/).

## Preise und Latenz

Am 9. Oktober 2026 zeigen die Modellseiten folgende Preise. Die API-Werte entsprechen bereits dem angezeigten Aktionspreis; der zusätzlich gemeldete Faktor `discount: 0.5` darf nicht erneut angewendet werden.

| Modell | Angezeigter Aktionspreis USD | Angezeigter Listenpreis USD | Anbieter-P50 |
|---|---:|---:|---:|
| Eleven v4 | 0,04 / 1.000 Zeichen | 0,08 / 1.000 Zeichen | 1,56 s |
| Eleven v4 Turbo | 0,02 / 1.000 Zeichen | 0,04 / 1.000 Zeichen | 0,66 s |
| Scribe v2 | etwa 0,11 / Audiostunde | etwa 0,22 / Audiostunde | 0,67 s |

Die Latenzen sind die auf OpenRouter angezeigten P50-Werte, keine eigenen Messungen und keine garantierte Laufzeit für eine bestimmte Text- oder Audiolänge. Die Provider-API hatte gleichzeitig `latency_last_30m: null`; die Zahlen stammen daher ausdrücklich von den Modellseiten.

Quellen: [Eleven v4](https://openrouter.ai/elevenlabs/eleven-v4), [Eleven v4 Turbo](https://openrouter.ai/elevenlabs/eleven-v4-turbo), [Scribe v2](https://openrouter.ai/elevenlabs/scribe-v2).

Die Modellseiten nennen für alle drei Modelle über 90 Sprachen. Eine vollständige, modellbezogene Sprach-/Regionalvariantenliste wurde dort nicht ausgewiesen; die spätere Auswahl muss die jeweils aktuellen Anbieterangaben verwenden. Die öffentliche Models-API weist für v4 diese 21 `supported_voices` aus: `george`, `sarah`, `adam`, `alice`, `bella`, `bill`, `brian`, `callum`, `charlie`, `chris`, `daniel`, `eric`, `harry`, `jessica`, `laura`, `liam`, `lily`, `matilda`, `river`, `roger`, `will`. Voice-IDs je ausgewähltem Modell aus der [Models-API](https://openrouter.ai/api/v1/models?output_modalities=speech) beziehen. Dort ist `per_request_limits` null; dies ist keine Zusage unbegrenzter Anfrageraten. Kontobezogene Rate-Limits müssen bei Einrichtung berücksichtigt werden.

Die Aktion ist bis 19. Oktober 2026 angekündigt. Die Nutzer-Mail präzisiert 08:00 PT und eine Voraussetzung bezüglich früherer Zahlungen; die Modellseiten sprechen allgemeiner von der Startaktion. Kontoberechtigung und endgültiger Tarif sind deshalb vor einer Kostenentscheidung im betroffenen Konto zu prüfen. Nach Aktionsende keinen unveränderten Rabatt voraussetzen. Audio-Tags zählen zum TTS-Zeichenumfang.

## Integrationsvorschlag

Der Companion-Dienst übernimmt Cloud-Anfragen; Erweiterung und mobile Apps erhalten nur Audio beziehungsweise Ergebnisse. Der OpenRouter-Key gehört ausschließlich in die lokale Laufzeitkonfiguration. Er ist vom Universal API-Key für Daten-Pipelines getrennt und wird weder exportiert noch in Apps oder Images eingebettet.

In den erweiterten Einstellungen wäre „OpenRouter“ ein ausdrücklich aktivierter Anbieter neben Systemstimmen und Sherpa. Die Auswahl speichert Modell-ID und Voice-ID. Die Oberfläche erklärt vor Aktivierung: TTS überträgt Chattext einschließlich gegebenenfalls vorgelesener Namen; STT überträgt Audio. Aufbewahrung und Datenverarbeitung hängen von den aktuell gewählten Anbieterbedingungen ab; eine pauschale Zusage zur Nichtaufbewahrung erfolgt nicht.

Für Chat-TTS: v4 Turbo, explizites MP3, vorhandene Punkt-/Stumm-/Game-Mode-Regeln vor dem Versand, begrenzte Warteschlange, keine zusätzlichen Audio-Tags aus fremdem Chat als Steueranweisung behandeln. Fehler 401/402/429 und Zeitüberschreitungen sichtbar melden. Kein automatischer Wechsel von lokalem Sherpa zu einem kostenpflichtigen Anbieter. Nach unklar abgebrochener Audioanfrage keine blinde Wiederholung mit möglicher Doppelabrechnung.

Vor Aktivierung ein Nutzerbudget und ein Zeichenlimit festlegen; Kosten anhand des aktuellen Tarifs vor Versand abschätzen und erfassen. Budgetüberschreitung stoppt weitere Cloud-Anfragen. STT bleibt separat ausgeschaltet und benötigt einen ausdrücklich gestarteten Audioauftrag. Regionale Sprachunterstützung und Stimmen werden anhand der aktuellen Modelldaten angeboten, nicht aus dem Sherpa-Katalog abgeleitet.
