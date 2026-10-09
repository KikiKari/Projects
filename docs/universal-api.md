# Universal API-Key · Vertragsversion 1

Der Companion-Dienst stellt Daten unter `/v1/pipelines` bereit. Lesende Programme senden `Authorization: Bearer <Universal API-Key>`. Der Schlüssel wird in „Erweiterte Einstellungen“ eingerichtet; der bisherige Speicherschlüssel bleibt erhalten. Das vorhandene Pairing authentifiziert Einrichtung und Datenanlieferung, nicht den lesenden Zugriff externer Verbraucher.

Lokal ist der Dienst über `http://127.0.0.1:43117` erreichbar. Der Dienst kann außerdem auf der vorhandenen Tailscale-Netzwerkschnittstelle lauschen. Für die mobilen Clients eine HTTPS-Adresse des Companion-Dienstes im Tailnet konfigurieren, beispielsweise über Tailscale Serve. Eine öffentliche Freigabe ist nicht erforderlich. Anfragen mit Browser-Origin bleiben auf Erweiterungs-Ursprünge beschränkt.

## Abfragen

| Pfad | Ergebnis |
|---|---|
| `/v1/pipelines` | Pipeline-Verzeichnis, Cursor und Aufbewahrung |
| `/v1/pipelines/sources` | Client-, Sitzungs-, Tab- und Dokumentidentitäten |
| `/v1/pipelines/state` | Letzter Stand und sämtliche aufbewahrten `observations` je Quelle und Pipeline |
| `/v1/pipelines/events` | Ereignisse einschließlich RAW-Daten |
| `/v1/pipelines/export` | JSON; mit `format=jsonl` zeilenweise JSON-Datensätze |
| `/v1/pipelines/stream` | Server-Sent Events mit Ereignis-ID |

Die Filter `clientId`, `sessionId`, `tabId`, `documentId` und `pipeline` sind kombinierbar. `after` setzt hinter einem zuvor gespeicherten Cursor fort; SSE akzeptiert zusätzlich `Last-Event-ID`. Ein gemeinsamer Key bedeutet keine gemeinsame Tabidentität. Beim Reload ändert sich die Dokumentidentität; beim erneuten Öffnen entsteht eine neue Tabidentität.

## Ereignisformat

```json
{
  "schemaVersion": 1,
  "eventId": "synthetic-event-1",
  "cursor": 42,
  "clientId": "synthetic-client",
  "sessionId": "synthetic-session",
  "tabId": "synthetic-tab-a",
  "documentId": "synthetic-document",
  "pipeline": "chat",
  "capturedAt": "2026-10-09T10:00:00.000Z",
  "receivedAt": "2026-10-09T10:00:00.100Z",
  "availability": "available",
  "source": "extension-message",
  "structured": {"content": "Beispielnachricht"},
  "raw": {"content": "Beispielnachricht"},
  "credentialsRedacted": false
}
```

`cursor` ordnet den Eingang im Dienst, `capturedAt` bezeichnet den Quellzeitpunkt. `sourceSequence`, soweit geliefert, ordnet die lokale Erfassung. RAW bezeichnet die unter `source` genannte Quelle: ein Netzwerk-Antwortkörper, ein unverändert übernommenes Decoderereignis oder eine native Bridge-Nachricht. Eine bereits dekodierte Quelle wird nicht als unverändertes Netzwerkpaket bezeichnet.

## Zwölf Pipelines

Alle folgenden Beispiele sind synthetisch; sie beschreiben den jeweiligen Inhalt innerhalb des Ereignisformats.

| Anzeige | Pipeline-ID | Inhalt / synthetisches Beispiel |
|---|---|---|
| Titel | `title` | Untertitel und Quellenstatus, etwa `{"contents":[{"lang":"de","text":"Hallo"}]}` |
| Chat | `chat` | Chatnachricht, etwa `{"nickname":"Beispiel","content":".Text"}` |
| Sprachdienst | `speech-service` | Dienstzustand, etwa `{"tts":"Sherpa-ONNX","ttsAvailable":true}` |
| Sherpa | `sherpa` | Katalog und installierte Stimmen, etwa `{"voices":[{"id":"synthetic-voice","installed":true}]}` |
| Top-Chatter | `top-chatters` | Teilnehmerdaten, etwa `{"synthetic-user":{"messages":2,"words":5}}` |
| PROFIL-Information | `profile` | Beobachtete Profilfelder, etwa `{"uniqueId":"synthetic-user"}` |
| LIVE-Information | `live` | Beobachtete Statistiken, etwa `{"viewerCount":100}` |
| Songs | `songs` | Erkennungsergebnis, etwa `{"match":true,"title":"Beispieltitel"}` |
| VLC-Links | `media-links` | Erkannte Varianten mit Typ/Qualität, etwa `{"quality":"1080p60","protocol":"HLS","url":"https://example.test/live.m3u8"}` |
| LIVE-Logs | `live-logs` | Einzelne Caption-Ereignisse einschließlich RAW-Quelle |
| Debugging-Logs | `debug-logs` | Quellereignisse unabhängig von der Diagnose-Anzeige |
| Browsertab | `browser-tab` | Tabmetadaten, `current-dom` oder `original-document` mit Herkunft und Erfassungszeit |

Original-Dokument und DOM sind unterschiedliche Beobachtungen. Die Browser-Erweiterung nutzt die Debugger-Anbindung für tatsächlich geladene Dokumentantworten. Nicht erfasste Antworten werden als nicht verfügbar ausgewiesen. WebViews melden ausdrücklich, wenn ihre ursprüngliche Dokumentantwort nicht zugänglich ist.

## Vollständigkeit, Wiederverbindung und Aufbewahrung

`availability` ist `available`, `unavailable` oder `gap`. Fehlende Beobachtungen tragen einen Grund und sind keine vermeintlich vollständigen leeren Ergebnisse. Die Anzeigegrenzen der Oberfläche sind kein Exportlimit.

Mobile RAW-Daten können als `pipeline-record` mit `recordId`, `chunkIndex`, `chunkCount` und `encoding: "json-string-fragments"` eintreffen. Teile innerhalb derselben Quellenidentität in Indexreihenfolge zusammensetzen und anschließend JSON parsen. Die Zustandsabfrage setzt vollständige Gruppen zusammen; fehlende Teile ergeben `gap`. Ereignisexporte behalten die einzelnen Quellnachrichten bei.

Der Dienst speichert standardmäßig sieben Tage beziehungsweise bis zu 2 GiB. `pipelineRetentionDays` und `pipelineMaxBytes` in der lokalen Dienstkonfiguration steuern diese Grenzen. `firstAvailableCursor`, `lastCursor` und `gap` machen einen nicht mehr verfügbaren Bereich erkennbar. Clients behalten nicht bestätigte Ereignisse lokal und wiederholen die Anlieferung mit derselben Ereignis-ID; der Dienst dedupliziert innerhalb der noch aufbewahrten Daten.

JSONL beginnt mit einem Metadatensatz, gefolgt von Ereignissen. Für LIVE-Logs mit `pipeline=live-logs` filtern; JSON enthält die gleichen tabbezogenen Quellen einschließlich `raw`. Zugangsdaten werden gezielt entfernt und über `credentialsRedacted` gekennzeichnet. Nicknames und temporäre Medienadressen bleiben erhalten.

## Externes Programm

```python
import json, os, urllib.request
base = os.environ["TLC_SERVICE_URL"].rstrip("/")
key = os.environ["TLC_UNIVERSAL_API_KEY"]
request = urllib.request.Request(
    base + "/v1/pipelines/sources",
    headers={"Authorization": "Bearer " + key},
)
with urllib.request.urlopen(request, timeout=15) as response:
    sources = json.load(response)
for source in sources["sources"]:
    print(source["clientId"], source["sessionId"], source["tabId"], source["documentId"])
```

Schlüssel ausschließlich aus der Laufzeitkonfiguration laden; nicht in Skripte, URLs oder Protokolle schreiben.

## Tailscale HTTPS

Nach `tailscale serve status` einen freien HTTPS-Port verwenden, beispielsweise `tailscale serve --bg --https=8443 http://127.0.0.1:43117`. Dies ist eine Freigabe innerhalb des Tailnets, kein Funnel. Vorhandene Serve-Handler nicht ersetzen. Die angezeigte HTTPS-Adresse in Android und iOS unter „Companion-Dienst (Tailscale HTTPS)“ eintragen; den vorhandenen Pairing-Code und denselben Universal API-Key verwenden.

Der DOM wird beim Dokumentstart und danach minütlich erfasst; jeder Datensatz enthält seinen Erfassungszeitpunkt. Der ursprüngliche Antwortkörper wird separat über die Debugger-Anbindung erfasst. Bereits vor der Anbindung geladene Dokumente können erst nach erneutem Laden vollständig erfasst werden. WebViews kennzeichnen den nicht zugänglichen ursprünglichen Antwortkörper ausdrücklich als nicht verfügbar.
