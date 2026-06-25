# Vision-Check — PWA

KI-gestützte Biodiversitätserkennung via Smartphone-Kamera + On-Device-KI + Cloud Vision APIs.

## Live-Versionen

| Umgebung | URL |
|---|---|
| Vercel (Production) | https://vision-check-pink.vercel.app |
| pplx.app Preview | https://www.perplexity.ai/computer/a/vision-check-bJmwUjACSgCbVcNgHgWI9A |

## Technischer Stack

- **On-Device KI:** TensorFlow.js 4.22 + COCO-SSD v2 (WebGPU → WebGL → CPU)
- **Filter-Pipeline:** CLAHE-Simulation (4×) + Unsharp Mask (5 Stufen) + Pixel-Lupe (8×)
- **Schicht 0:** iNaturalist Computer Vision API (kostenlos, kein Key)
- **Schicht 3 — Basis:** OpenAI GPT-4o · Gemini 2.5 Pro · Claude Opus 4.8 / Fable 5
- **Schicht 3 — Erweitert:** OpenRouter · NVIDIA NIM (LLaMA 3.2 90B Vision)
- **Funktions-Extras:** ElevenLabs TTS · WaveSpeed Real-ESRGAN 2× Upscaling · Perplexity sonar-pro Artenbeschreibung
- **PWA:** Service Worker + Manifest (offline-fähig, installierbar)

## Sicherheit

Alle API-Keys bleiben ausschließlich lokal im Browser (localStorage, AES-GCM-verschlüsselter Export).
Kein Backend, keine Weiterleitung, kein Tracking.

## Starten (lokal)

```bash
cd app
npx serve .
# → http://localhost:3000
```

## Projektlinks

- [Linear-Projekt](https://linear.app/0penclaw/project/vision-check-c9501da64334)
- [Notion-Seite](https://app.notion.com/p/37d8d8ad3db981448a70d5f2c3e79261)
- [Canva-Ordner](https://www.canva.com/folder/FAHNmu4BFyU)
