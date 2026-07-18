# Architektur

Die Erweiterung besteht aus sechs Laufzeitbereichen:

- `content-core.js`: reine Normalisierung und Metadatenanalyse;
- `content.js`: DOM-Prüfung und lokale Player-/Audioaktionen in der isolierten Welt;
- `proto-main.js`: minimaler Protobuf-Decoder für öffentliche LIVE-Ereignisse;
- `hook.js`: MAIN-World-WebSocket-Proxy, der nur Listener ergänzt;
- `background.js`: passives CDN-Monitoring und flüchtiger Tab-Zustand;
- `sidepanel.*`: lokale Darstellung, Export- und Kopieraktionen.

Der Hook ersetzt `WebSocket.send()` nicht. Seiteninhalte gelten als nicht vertrauenswürdig und werden mit `textContent` ausgegeben. Stream-Daten, Captions, Chat und Diagnosen liegen in `storage.session`; `storage.local` enthält nur Autostart-, Vorlese- und Lautstärkepräferenzen.

## Mobile Laufzeitbereiche

- `mobile/ios`: SwiftUI-App mit WKWebView, `WKUserScript` am Dokumentstart, AVSpeechSynthesizer und ShazamKit;
- `mobile/android`: Kotlin-/Compose-App mit AndroidX WebKit, Android Text-to-Speech und ShazamKit-AAR;
- `plugin-source/mobile-shared`: gemeinsame, versionierte Bridge für öffentliche TikTok-DOM-, Metadaten- und WebSocket-Ereignisse;
- `site/api/shazam-token.mjs`: Android-Token-Endpunkt mit kurzlebigen ES256-Tokens. Der Media-Services-Private-Key bleibt ausschließlich in der Serverumgebung.

Mobile Bridge-Nachrichten werden nur vom Hauptframe der Origin `https://www.tiktok.com` angenommen, sind auf 64 KiB begrenzt und verwenden eine feste Ereignis- und Befehlsliste. Die Apps lesen weder Cookies noch Web-Storage aus. Streamdaten bleiben flüchtig; Einstellungen und dauerhafte Mutes liegen in UserDefaults beziehungsweise DataStore.

Die Mikrofonerkennung läuft nur nach einem Klick und höchstens zwölf Sekunden. WebView-PCM ist experimentell; bei CORS-, Codec- oder WebView-Fehlern wird die Funktion beendet und das Mikrofon angeboten.

Siehe [Mermaid-Quelle](../diagrams/architecture.mmd).

## Reproduzierbare Projektvisualisierung

![Isometrische Plattformarchitektur von TikTok LIVE Companion](../diagrams/tiktok-live-companion-architecture.svg)

- [Interaktive Three.js-Ansicht](https://tiktok-live-companion.vercel.app/de/architecture-3d)
- [Rotierendes GIF öffnen](../diagrams/tiktok-live-companion-architecture.gif)
- [SVG-Generator](../../assets/gen_tiktok_live_companion_flow.py)
- [GIF-Generator](../../assets/gen_tiktok_live_companion_flow_gif.py)
- [Gemeinsames Datenmodell](../../assets/flow_model.py)
- [Visualisierungsvertrag](../diagrams/tiktok-live-companion-visualization-contract.md)

Die Darstellung ist projektspezifisch: Tiefe trennt Browser, iOS und Android/HyperOS. Cyan bezeichnet passive Beobachtung, Korallrot ausschließlich nach Nutzeraktion gestartetes Audio und Amber den kurzlebigen Android-Tokenfluss. Die Boxgrößen sind schematisch und keine Leistungs- oder Datenmengenmessung.

## Textalternative

Im Browser liefert der TikTok-Tab öffentliche DOM-/Metadaten an das isolierte Content Script und beobachtete WebSocket-Ereignisse an den MAIN-World-Hook. Beide leiten bereinigte Ergebnisse an den Service Worker weiter. Dieser speichert den Zustand flüchtig pro Tab und sendet ihn an das Seitenpanel. CDN-Anfragen werden ausschließlich passiv beobachtet. Mobil wird derselbe Decoder am Dokumentstart in die erlaubte TikTok-WebView injiziert und gibt nur validierte Ereignisumschläge an den nativen Zustand weiter.
