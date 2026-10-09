# Lokaler Companion-Dienst 0.8.2

Der Windows-Dienst stellt Sherpa-Sprachausgabe, optionale AudD-Erkennung und die zwölf Universal-API-Pipelines bereit. Er lauscht lokal an Loopback und zusätzlich an der vorhandenen Tailscale-Netzwerkschnittstelle.

## Installation und wiederholte Einrichtung

Die aktuelle Erweiterungs-ZIP vollständig entpacken. `companion-service\Sprachdienst-reparieren.cmd` aus diesem Paket starten. Die Einrichtung übernimmt vorhandene Kopplung, Erweiterungs-ID, Dienstport, API-Einstellungen und Sherpa-Stimmen. Eine gültige gespeicherte Erweiterungs-ID wird nicht erneut abgefragt.

Die Einrichtung erneuert `start-service.ps1`, `install-service.ps1` und `protocol-handler.cmd` unter `%LOCALAPPDATA%\TikTokLiveCompanion` sowie die Windows-Protokollregistrierung. Alle Starter zeigen danach auf das aktuelle entpackte Paket. Den Paketordner deshalb anschließend nicht verschieben.

Ein bereits laufender Dienst wird über seinen authentifizierten Health-Endpunkt und den zugehörigen Node-Prozess erkannt und für das Update neu gestartet. Anführungszeichen und absolute Skriptpfade werden berücksichtigt. Ein fremder Prozess auf dem Dienstport wird nicht beendet. Nach dem Start muss der Companion seine Erreichbarkeit bestätigen.

```powershell
npm run setup -- -ExtensionId <Erweiterungs-ID>
```

Erstinstallationen verwenden Port 43117 und richten die Standardstimmen ein. Bei wiederholter Einrichtung wird `port` aus `service.json` übernommen; bestehende Stimmen werden nicht erneut installiert. Der gespeicherte Pairing-Code bleibt erhalten. Der kurzlebige Bootstrap-Nonce übergibt ihn automatisch an die gebundene Erweiterung.

## Lokaler Port und Tailscale

Standard lokal: `http://127.0.0.1:43117`. Ein bereits konfigurierter abweichender lokaler Port bleibt erhalten. Die Dienstadresse in den erweiterten Einstellungen muss diesen lokalen Port verwenden.

Tailscale Serve kann einen eigenen HTTPS-Port verwenden, beispielsweise 8443, und auf den lokalen Dienstport weiterleiten. Die beiden Ports haben unterschiedliche Aufgaben:

```powershell
tailscale serve status
tailscale serve --bg --https=8443 http://127.0.0.1:43117
```

Vorhandene Serve-Freigaben erhalten und den Proxy-Zielport an den tatsächlich konfigurierten lokalen Port anpassen. Die angezeigte HTTPS-Adresse in Android und iOS als Companion-Dienst eintragen. Keine öffentliche Freigabe erforderlich.

## Konfiguration und Stimmen

`%LOCALAPPDATA%\TikTokLiveCompanion\service.json` enthält die lokale Laufzeitkonfiguration. Zugangsdaten nicht in Quellcode, Pakete oder Dokumentation übernehmen. Sherpa-Dateien liegen unter `sherpa-onnx`, die installierten Stimmen unter `sherpa-voices.json` im selben Konfigurationsverzeichnis.

Zusätzliche Stimmen werden einzeln aus dem gemeinsamen Katalog installiert. Französisch, Spanisch, Italienisch, Portugiesisch (Brasilien), Niederländisch, Polnisch und Türkisch ergänzen die vorhandene Auswahl. Der Katalog nennt Sprache, Sprecher, Größe, SHA-256, Modellbezug und Lizenzquelle. Archive werden vor ihrer Übernahme aus einem temporären Verzeichnis validiert. Bestehende Stimmen-IDs und Auswahl bleiben erhalten.

Pairing und AudD werden in „Erweiterte Einstellungen“ verwaltet. Ohne AudD-Token bleibt die optionale Songerkennung ausgeschaltet; Sherpa benötigt keinen Cloud-Key. Android und iOS können die WAV-Ausgabe des Dienstes über Tailscale HTTPS abspielen.

## Universal API-Key

Lesende Programme verwenden `Authorization: Bearer <Universal API-Key>` unter `/v1/pipelines`. Pairing authentifiziert Einrichtung und Datenanlieferung. Tab-, Sitzungs- und Dokumentidentitäten trennen die zwölf Pipelines. SSE, JSON und JSONL ermöglichen Weiterverarbeitung ohne UI-Scraping.

Die Standardaufbewahrung beträgt sieben Tage mit insgesamt höchstens 2 GiB. `pipelineRetentionDays` und `pipelineMaxBytes` sind konfigurierbar. Lücken und fehlende Quellen werden ausdrücklich ausgewiesen; Zugangsdaten werden aus Nutzlasten entfernt.
