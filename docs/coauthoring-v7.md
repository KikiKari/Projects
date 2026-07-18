# CoAuthoring V7 – freigegebene visuelle Quellen

**Stand:** 18. Juli 2026 · **Version:** 0.7.0 · **Quelle:** vom Nutzer freigegebene CoAuthoring-Anhänge

Alle 13 PNG-Dateien wurden unverändert unter `site/public/assets/coauthoring-v7/` übernommen. Bilder mit sichtbarer Versionsangabe 0.5.0 dokumentieren frühere Entwurfsstufen. Für den finalen 0.7.0-Stand sind insbesondere die V7-Übersicht und die Mobile-ShazamKit-Ansicht maßgeblich.

## Maßgebliche V7-Ansichten

![Finalisierte V7-Übersicht mit Plattformmatrix](../site/public/assets/coauthoring-v7/coauthoring-v7-overview.png)

![iOS- und Android-/HyperOS-Oberfläche für manuelle ShazamKit-Erkennung](../site/public/assets/coauthoring-v7/mobile-shazamkit-ios-android.png)

## Browserfunktionen und Sicherheit

![Bereinigte Chatzeilen, Vorlesen und Top-Chatter](../site/public/assets/coauthoring-v7/browser-chat-top-chatter.png)

![Modal mit im Chat beobachteten Personen und Mute-Modi](../site/public/assets/coauthoring-v7/browser-observed-people.png)

![Historischer Codex-Security-Scan](../site/public/assets/coauthoring-v7/codex-security-scan.png)

![Finalisierte Installationsreferenz](../site/public/assets/coauthoring-v7/installation-browser-tiktok.png)

![Finalisierte Browser-Sicherheitsarchitektur](../site/public/assets/coauthoring-v7/architecture-browser-tiktok.png)

## Designhistorie

Die folgenden Motive bleiben als nachvollziehbare Designvarianten erhalten:

- [Funktionsseite – Coral](../site/public/assets/coauthoring-v7/features-player-coral.png)
- [Architektur – Coral](../site/public/assets/coauthoring-v7/architecture-browser-coral.png)
- [Installation – Coral](../site/public/assets/coauthoring-v7/installation-browser-coral.png)
- [Übersicht – Coral](../site/public/assets/coauthoring-v7/overview-browser-coral.png)
- [Funktionsseite – Cyan](../site/public/assets/coauthoring-v7/features-player-cyan.png)
- [Übersicht – Cyan](../site/public/assets/coauthoring-v7/overview-browser-cyan.png)

## Reproduzierbare Diagramme

- [Gesamtarchitektur als Mermaid](diagrams/architecture.mmd)
- [Songerkennungssequenz als Mermaid](diagrams/recognition-flow.mmd)
- [Plattform-Deployment als Mermaid](diagrams/platform-deployment.mmd)

```mermaid
flowchart LR
    Public["Öffentliche TikTok-LIVE-Seite"] --> Browser["Edge / Chrome · AudD"]
    Public --> IOS["iOS · ShazamKit"]
    Public --> Android["Android / HyperOS · ShazamKit"]
    Android --> Token["kurzlebiges ES256-Token"]
```

🧊 [**Interaktive 3D-Ansicht öffnen**](https://kikikari.github.io/OpenClaw/mcp-flow.html) — drehbar und zoombar (Three.js, Branch [gh-pages](https://github.com/KikiKari/OpenClaw/tree/gh-pages)).

Die externe 3D-Ansicht dient als Interaktionsreferenz. Die TikTok-LIVE-Companion-Systemwahrheit bleibt in den versionskontrollierten Mermaid-Dateien und deren Textalternativen.

Reproduktionswerkzeuge der 3D-Referenz:

- [assets/gen_mcp_flow.py](https://github.com/KikiKari/OpenClaw/blob/main/assets/gen_mcp_flow.py) – SVG
- [assets/gen_mcp_flow_gif.py](https://github.com/KikiKari/OpenClaw/blob/main/assets/gen_mcp_flow_gif.py) – GIF
