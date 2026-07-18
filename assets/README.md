# Reproduzierbare Architekturvisualisierung

Die Generatoren verwenden ein gemeinsames TikTok-LIVE-Companion-Datenmodell:

- `flow_model.py` – 13 Projektknoten, 12 gerichtete Kanten und semantische Farbrollen;
- `gen_tiktok_live_companion_flow.py` – deterministisches, barrierearm beschriftetes SVG;
- `gen_tiktok_live_companion_flow_gif.py` – rotierendes 36-Frame-GIF mit Pillow;
- `test_visualizations.py` – Modell-, SVG-, GIF- und Herkunftsprüfung.

Die isometrische Projektion, Boxflächen und Rotationsidee wurden anhand der vom Nutzer genannten OpenClaw-Generatoren analysiert. Es wurden weder deren MCP-Datenmodell noch deren Texte, Knoten, Kanten oder Ausgabedateien übernommen.

## Erzeugen

```powershell
python assets/gen_tiktok_live_companion_flow.py
python assets/gen_tiktok_live_companion_flow_gif.py
python assets/test_visualizations.py
```

Ausgaben:

- `docs/diagrams/tiktok-live-companion-architecture.svg`
- `docs/diagrams/tiktok-live-companion-architecture.gif`
- `site/public/visualizations/` – dasselbe Modell und dieselben Fallback-Dateien für die interaktive Three.js-Route `/de/architecture-3d` beziehungsweise `/en/architecture-3d`.

Farben bedeuten: Cyan = passive Beobachtung, Korallrot = Audio ausschließlich nach Nutzeraktion, Amber gestrichelt = kurzlebiges Android-Developer-Token.
