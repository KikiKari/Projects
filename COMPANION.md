# Telegram Monitor Companion

Zweite Ausbaustufe: der Monitor als eigenständige Anwendung unter
`http://127.0.0.1:8765`, gestartet per Doppelklick, installierbar als App.

## Dauerbetrieb im Container (empfohlen)

Der Doppelklick-Starter läuft nur, solange niemand das Fenster schließt und
der Rechner nicht neu startet. Für Dauerbetrieb:

| Datei | was passiert |
|---|---|
| `Telegram Monitor - Docker.cmd` | baut das Abbild, startet den Container, wartet auf Antwort, öffnet die Oberfläche |
| `Telegram Monitor - Docker anhalten.cmd` | hält ihn an; der Verlauf bleibt erhalten |

Von Hand:

```
docker compose up -d --build     starten
docker compose logs -f           zusehen
docker compose down              anhalten
```

Der Container hört auf `0.0.0.0:8765`, veröffentlicht wird der Port aber nur
an `127.0.0.1` — von anderen Rechnern ist er also nicht erreichbar. Der
gesammelte Verlauf liegt im Volume `monitor-data` und überlebt jedes
Neubauen.

**Damit es den Neustart übersteht**, muss in Docker Desktop unter
*Settings → General* die Option **„Start Docker Desktop when you sign in"*
aktiv sein. `restart: unless-stopped` greift nur, wenn der Docker-Dienst
selbst läuft.

**Was im Container fehlt:** Ein Linux-Container kann keine Windows-Meldung
erzeugen. Es bleiben das Ereignisprotokoll (immer), ein Webhook
(`notify.webhook_url` in `config.json`, z. B. nach Discord) und die Meldung
der installierten App, solange sie geöffnet ist. Der Systembefehl ist in
`config.json` deshalb leer.

**Wenn der Container nicht startet:** Fehlt `config.json` beim ersten Mal,
legt Docker beim Einhängen einen *Ordner* mit diesem Namen an. Ordner löschen,
`copy config.example.json config.json`, neu starten. Der Docker-Starter macht
das von selbst.

## Starten (ohne Container)

| Datei | was passiert |
|---|---|
| `Telegram Monitor Companion.cmd` | startet den Monitor unsichtbar, wartet auf Antwort, öffnet ein eigenes Fenster |
| `Telegram Monitor Companion - beenden.cmd` | beendet ihn wieder |
| `Telegram Monitor Companion - Fehlersuche.cmd` | wie oben, aber mit sichtbarem Serverfenster |

Der Starter prüft zuerst, ob Python vorhanden ist (`py -3`, sonst `python`).
Fehlt es, nennt er den Downloadlink und den nötigen Haken
**„Add python.exe to PATH“**. Läuft der Monitor bereits, wird er nicht ein
zweites Mal gestartet — dann öffnet sich nur das Fenster.

Weitere Schalter:

```
.\TelegramMonitorCompanion.ps1 -Status        nachsehen, ob er läuft
.\TelegramMonitorCompanion.ps1 -Port 8790     anderer Port
.\TelegramMonitorCompanion.ps1 -NoBrowser     nur starten, kein Fenster
.\TelegramMonitorCompanion.ps1 -Console       mit sichtbarem Fenster
```

Die Prozessnummer liegt in `data\companion.pid`, die Ausgabe in
`data\companion.log` und `data\companion.log.err`.

## Als App installieren

Läuft der Monitor, erscheint oben rechts **Als App installieren**. Danach liegt
er als eigenes Programm im Startmenü, ohne Adressleiste, mit eigenem Symbol.

Technisch: `web/manifest.webmanifest` (Anzeigemodus `standalone`, drei Symbole,
drei Sprungziele) und `web/sw.js`. Der Service Worker legt nur die Hülle in den
Zwischenspeicher — alles unter `/api/` wird immer frisch geholt, weil ein
zwischengespeicherter Livestatus schlimmer wäre als gar keiner.

Nötig dafür war auch, dass der Server die richtigen MIME-Typen sendet:
ein Manifest nur als `application/manifest+json`, ein Service Worker nur als
`text/javascript`. Sonst lehnt der Browser die Installation ab.

## Drei Zugänge, ein Monitor

| Zugang | wofür |
|---|---|
| Artefakt **Telegram Monitor Companion** | Fernbedienung in Claude: Status, Verlauf, Ereignisse, Kanäle verwalten |
| installierte App / Browser | vollständige Oberfläche mit allen Reitern |
| Browser-Erweiterung `plugin/extension/` | Meldung beim Livegang ohne offenen Tab |

## Beispiele

In allen Beispielen, Vorlagen und Texten steht `creator` als Platzhalter.
Es gibt kein fest eingebautes Konto — Kanalname und Adresse werden überall
eingegeben.

## Auf dem Telefon

Eine PWA hat **keine Installationsdatei** — es gibt keine APK, die man
verschicken könnte. Sie wird direkt aus dem Browser installiert.

Voraussetzung: Das Telefon muss den Monitor erreichen können, und zwar über
HTTPS. Eine rohe Adresse wie `http://100.x.x.x:8765` genügt nicht — Chrome
lässt dort weder die Installation noch Meldungen zu, aus demselben Grund wie
bei einer lokalen Datei.

| Datei | was passiert |
|---|---|
| `Telegram Monitor - Handy freigeben.cmd` | richtet `tailscale serve` ein und nennt die fertige https-Adresse |
| `Telegram Monitor - Handy sperren.cmd` | hebt die Freigabe wieder auf |

Dann auf dem Telefon:

1. Die genannte `https://…ts.net`-Adresse in Chrome öffnen
2. Menü → **App installieren** (bzw. „Zum Startbildschirm hinzufügen")
3. In der App einmal auf **Meldungen erlauben** tippen

Danach liegt der Monitor mit eigenem Symbol im App-Drawer, startet ohne
Adressleiste und meldet den Livegang wie eine gewöhnliche App — auch wenn er
im Hintergrund ist.

**Am Container ändert sich dabei nichts.** `tailscale serve` läuft auf dem
Windows-Rechner und greift über dessen Loopback auf `127.0.0.1:8765` zu. Die
Portbindung bleibt also wie sie ist, im LAN ist weiterhin nichts offen, und
erreichbar ist der Monitor nur für deine eigenen Geräte.

**Wenn `tailscale serve` mit einem Zertifikatsfehler abbricht:** In der
Tailscale-Verwaltung unter *DNS → HTTPS Certificates* die Ausstellung
einschalten; MagicDNS muss ebenfalls aktiv sein.

**Eine öffentliche Freigabe (Funnel) ist hier die falsche Antwort.** Der
Monitor hat keine Anmeldung — wer von außen herankommen soll, gehört ins
Tailnet.
