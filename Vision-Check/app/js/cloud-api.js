// ═══════════════════════════════════════════
// Vision-Check — Cloud Vision APIs (Schicht 3)
// OpenAI GPT-4o | Gemini 2.5 Pro | Claude Opus 4.8 / Fable 5
// + iNaturalist (Schicht 0, kein Key nötig)
// ═══════════════════════════════════════════

'use strict';

const CloudAPI = (() => {

  // ── Basis-Prompt für Tier-/Insekten-Analyse ──────
  const SYSTEM_PROMPT = `Du bist ein hochpräziser Naturkundler und Biologe mit Expertise in Entomologie, Ornithologie und allgemeiner Zoologie. 
Analysiere das Bild und identifiziere alle sichtbaren Tiere, Insekten oder Lebewesen.

Antworte strukturiert auf Deutsch mit:
1. **Erkannte Arten** (Name + wissenschaftlicher Name falls bekannt)
2. **Erkennungsmerkmale** (warum glaubst du das?)
3. **Sicherheit** (hoch/mittel/niedrig)
4. **Lebensraum-Kontext** (Was zeigt der Hintergrund?)
5. **Besonderheiten / Verhaltenshinweise**

Falls kein Tier sichtbar: kurze Beschreibung der Szene.`;

  // ── Bild-Daten aufbereiten ────────────────────────
  function dataURLtoBase64(dataURL) {
    return dataURL.split(',')[1];
  }

  // ── iNaturalist Computer Vision API (Schicht 0) ──
  async function analyzeINaturalist(imageDataURL) {
    // iNaturalist CV API nimmt einen Bild-Upload entgegen
    // Wir nutzen die öffentliche /computervision/score_image Endpunkt
    const base64 = dataURLtoBase64(imageDataURL);
    const blob = await (await fetch(imageDataURL)).blob();

    const formData = new FormData();
    formData.append('image', blob, 'capture.jpg');

    try {
      const res = await fetch('https://api.inaturalist.org/v1/computervision/score_image', {
        method: 'POST',
        body: formData,
        headers: {
          'Accept': 'application/json'
        }
      });

      if (!res.ok) throw new Error(`iNaturalist API Fehler: ${res.status}`);
      const json = await res.json();

      // Ergebnisse aufbereiten
      const results = (json.results || []).slice(0, 5).map(r => ({
        name: r.taxon?.preferred_common_name || r.taxon?.name || 'Unbekannt',
        scientificName: r.taxon?.name,
        score: r.combined_score,
        rank: r.taxon?.rank,
        photoUrl: r.taxon?.default_photo?.square_url,
        taxonId: r.taxon?.id
      }));

      return { ok: true, source: 'iNaturalist', results };
    } catch (err) {
      return { ok: false, source: 'iNaturalist', error: err.message };
    }
  }

  // ── OpenAI GPT-4o Vision (detail:high) ───────────
  async function analyzeOpenAI(imageDataURL, apiKey) {
    if (!apiKey) return { ok: false, source: 'OpenAI', error: 'Kein API-Key konfiguriert' };

    const base64 = dataURLtoBase64(imageDataURL);

    const payload = {
      model: 'gpt-4o',
      max_tokens: 1500,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        {
          role: 'user',
          content: [
            {
              type: 'image_url',
              image_url: {
                url: `data:image/jpeg;base64,${base64}`,
                detail: 'high'
              }
            },
            {
              type: 'text',
              text: 'Bitte analysiere dieses Bild. Fokus auf Tiere, Insekten oder Lebewesen im Wald/Strauch/Baum-Kontext.'
            }
          ]
        }
      ]
    };

    try {
      const res = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        body: JSON.stringify(payload)
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error?.message || `HTTP ${res.status}`);
      }

      const json = await res.json();
      return {
        ok: true,
        source: 'OpenAI GPT-4o',
        model: json.model,
        text: json.choices[0]?.message?.content || '',
        tokens: json.usage
      };
    } catch (err) {
      return { ok: false, source: 'OpenAI', error: err.message };
    }
  }

  // ── Google Gemini 2.5 Pro Vision ─────────────────
  async function analyzeGemini(imageDataURL, apiKey) {
    if (!apiKey) return { ok: false, source: 'Gemini', error: 'Kein API-Key konfiguriert' };

    const base64 = dataURLtoBase64(imageDataURL);
    const model = 'gemini-2.5-pro';
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    const payload = {
      contents: [
        {
          role: 'user',
          parts: [
            {
              inlineData: {
                mimeType: 'image/jpeg',
                data: base64
              }
            },
            {
              text: SYSTEM_PROMPT + '\n\nBitte analysiere das Bild oben.'
            }
          ]
        }
      ],
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 2048
      }
    };

    try {
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error?.message || `HTTP ${res.status}`);
      }

      const json = await res.json();
      const text = json.candidates?.[0]?.content?.parts?.[0]?.text || '';

      return { ok: true, source: 'Gemini 2.5 Pro', model, text };
    } catch (err) {
      return { ok: false, source: 'Gemini', error: err.message };
    }
  }

  // ── Claude Opus 4.8 / Fable 5 (via CORS-Proxy) ───
  async function analyzeClaude(imageDataURL, apiKey, proxyURL, model = 'claude-opus-4-8') {
    if (!apiKey) return { ok: false, source: 'Claude', error: 'Kein API-Key konfiguriert' };

    const base64 = dataURLtoBase64(imageDataURL);

    // Direkt oder via CORS-Proxy
    // Wenn proxyURL gesetzt: POST an proxyURL, der leitet an api.anthropic.com weiter
    // Proxy-Format: { url, headers, body } → Proxy sendet an Anthropic
    const targetURL = proxyURL
      ? proxyURL
      : 'https://api.anthropic.com/v1/messages';

    const payload = {
      model,
      max_tokens: 2048,
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'image',
              source: {
                type: 'base64',
                media_type: 'image/jpeg',
                data: base64
              }
            },
            {
              type: 'text',
              text: 'Analysiere dieses Bild. Fokus: Tiere, Insekten, Lebewesen im Wald/Strauch/Baum-Kontext. Nutze dein biologisches Domänenwissen.'
            }
          ]
        }
      ]
    };

    const headers = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01'
    };

    // Bei Proxy: Payload ggf. einwickeln
    let body, fetchHeaders;
    if (proxyURL && proxyURL !== 'https://api.anthropic.com/v1/messages') {
      // Cloudflare Worker erwartet normalen Anthropic-Request als Pass-Through
      body = JSON.stringify(payload);
      fetchHeaders = headers;
    } else {
      body = JSON.stringify(payload);
      fetchHeaders = headers;
    }

    try {
      const res = await fetch(targetURL, {
        method: 'POST',
        headers: fetchHeaders,
        body
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error?.message || `HTTP ${res.status}`);
      }

      const json = await res.json();
      const text = json.content?.[0]?.text || '';

      return {
        ok: true,
        source: `Claude ${model}`,
        model,
        text,
        tokens: { input: json.usage?.input_tokens, output: json.usage?.output_tokens }
      };
    } catch (err) {
      return { ok: false, source: 'Claude', error: err.message };
    }
  }

  // ── Alle aktivierten APIs parallel aufrufen ───────
  async function analyzeAll(imageDataURL, settings, onProgress) {
    const tasks = [];

    // Schicht 0: iNaturalist (immer, wenn aktiviert)
    if (settings.inat !== false) {
      tasks.push(analyzeINaturalist(imageDataURL).then(r => {
        onProgress && onProgress('iNaturalist', r);
        return r;
      }));
    }

    // Schicht 3: OpenAI
    if (settings.openaiKey) {
      tasks.push(analyzeOpenAI(imageDataURL, settings.openaiKey).then(r => {
        onProgress && onProgress('OpenAI', r);
        return r;
      }));
    }

    // Schicht 3: Gemini
    if (settings.geminiKey) {
      tasks.push(analyzeGemini(imageDataURL, settings.geminiKey).then(r => {
        onProgress && onProgress('Gemini', r);
        return r;
      }));
    }

    // Schicht 3: Claude
    if (settings.claudeKey) {
      tasks.push(analyzeClaude(
        imageDataURL,
        settings.claudeKey,
        settings.claudeProxy || null,
        settings.claudeModel || 'claude-opus-4-8'
      ).then(r => {
        onProgress && onProgress('Claude', r);
        return r;
      }));
    }

    return Promise.allSettled(tasks).then(results =>
      results.map(r => r.status === 'fulfilled' ? r.value : { ok: false, error: r.reason })
    );
  }

  return {
    analyzeINaturalist,
    analyzeOpenAI,
    analyzeGemini,
    analyzeClaude,
    analyzeAll
  };

})();
