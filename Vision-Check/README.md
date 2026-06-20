# Technische Architektur

## Bilderfassung (Kamera)
* **API**: Nutzt die `MediaStream API` mit `getUserMedia()`.
* **Auflösung**: Fordert aktiv bis zu 4K (3840×2160) an.
* **Fallback**: Moderne Browser liefern die maximal verfügbare Auflösung der Handy-Kamera.
* **UI-Features**: 
  * Auflösungs-Auswahl (4K → HD) eingebaut.
  * Geräte-Dropdown bei mehreren Kameras vorhanden.

---

## Schicht 1 — Lokale KI (On-Device, kein Cloud-Upload)
* **Framework**: `TensorFlow.js` + `COCO-SSD v2` läuft vollständig im Browser.
* **Backend**: Aktuell via `WebGL-Backend`.
* **Zukunft**: Ab 2026 ist `WebGPU` der neue Standard mit 2–3× Speedup gegenüber WebGL.
* **Performance**: Echtzeit-Detektion per `requestAnimationFrame` Loop ist eingebaut.

---

## Schicht 2 — Bildverbesserung / Interpolation
* **Pipeline**: Canvas-Filter-Pipeline.
* **CLAHE-Simulation**: Kontrastverstärkung bis 4×.
* **Unsharp-Mask**: Konfigurierbarer Kernel (5 Stufen, echte Pixelmatrix-Operation).
* **Anpassungen**: Helligkeit und Sättigung.
* **Fokus Insektenerkennung**: Kontrast-Anhebung ist entscheidend. Feine Strukturen werden erst bei 2,5–4× sichtbar.

---

## Schicht 3 — Cloud Vision APIs (kostenpflichtig)

| Anbieter | Modell | Stärke Insekten/Tiere |
| :--- | :--- | :--- |
| **OpenAI** | GPT-4o | `detail:high` Hochauflösendes Tile-Processing (512×512 Segmente) |
| **Google Gemini** | gemini-2.5-pro | Bounding-Box + Segmentierung, Object Detection nativ |
| **Anthropic Claude** | claude-opus-4-5 | Stärkstes biologisches Domänenwissen, via CORS-Proxy |

---

## Pixel-Inspektor
* **Zoom**: 8× Echtzeit-Zoom-Lupe mit Mausverfolgung.
* **Analyse**: RGB-Werte, Hex-Code und Helligkeitswert für präzise Pixelauswertung.
* **Target**: Funktioniert direkt auf dem aufgenommenen Bild.

---

## API-Keys eintragen
* **OpenAI**: `sk-proj-…` aus [://openai.com](https://://openai.com) — direkt im Browser-Tab.
* **Gemini**: `AIza…` aus [://google.com](https://://google.com).
* **Claude**: `sk-ant-…` aus [://anthropic.com](https://://anthropic.com) — CORS-Proxy in Einstellungen nötig.
* **Sicherheit**: Alle Keys bleiben lokal im Browser — kein Backend, keine Weiterleitung.