# Architektur

Die Erweiterung besteht aus sechs Laufzeitbereichen:

- `content-core.js`: reine Normalisierung und Metadatenanalyse;
- `content.js`: DOM-Prüfung und lokale Player-/Audioaktionen in der isolierten Welt;
- `proto-main.js`: minimaler Protobuf-Decoder für öffentliche LIVE-Ereignisse;
- `hook.js`: MAIN-World-WebSocket-Proxy, der nur Listener ergänzt;
- `background.js`: passives CDN-Monitoring und flüchtiger Tab-Zustand;
- `sidepanel.*`: lokale Darstellung, Export- und Kopieraktionen.

Der Hook ersetzt `WebSocket.send()` nicht. Seiteninhalte gelten als nicht vertrauenswürdig und werden mit `textContent` ausgegeben. Stream-Daten, Captions, Chat und Diagnosen liegen in `storage.session`; `storage.local` enthält nur Autostart-, Vorlese- und Lautstärkepräferenzen.

Siehe [Mermaid-Quelle](../diagrams/architecture.mmd).

## Textalternative

Der TikTok-Tab liefert öffentliche DOM-/Metadaten an das isolierte Content Script und beobachtete WebSocket-Ereignisse an den MAIN-World-Hook. Beide leiten bereinigte Ergebnisse an den Service Worker weiter. Dieser speichert den Zustand flüchtig pro Tab und sendet ihn an das Seitenpanel. CDN-Anfragen werden ausschließlich passiv beobachtet.
