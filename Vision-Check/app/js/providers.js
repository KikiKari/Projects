// ═══════════════════════════════════════════
// Vision-Check — Erweiterter Provider-Layer
// IVisionProvider Interface + neue Anbieter:
//   OpenRouter · NVIDIA NIM · Perplexity sonar-pro
//   ElevenLabs TTS · WaveSpeed Upscaling
// ═══════════════════════════════════════════
// Alle Keys verbleiben im Browser (localStorage).
// Kein Backend, keine Weiterleitung.
'use strict';

// ── IVisionProvider-Interface (JS-Duck-Typing) ───────
// Jeder Provider implementiert:
//   providerName: string
//   providerColor: string (CSS var oder hex)
//   requiresProxy: boolean
//   isConfigured(keys): boolean
//   analyze(base64, keys): Promise<AnalysisResult>

const VISION_PROMPT = `Du bist ein hochpräziser Naturkundler mit Expertise in Entomologie, Ornithologie und Zoologie.
Analysiere das Bild und identifiziere alle sichtbaren Tiere, Insekten oder Lebewesen.

Antworte strukturiert auf Deutsch:
1. **Erkannte Arten** (Name + wissenschaftlicher Name)
2. **Erkennungsmerkmale**
3. **Sicherheit** (hoch/mittel/niedrig)
4. **Lebensraum-Kontext**
5. **Besonderheiten**

Falls kein Tier sichtbar: kurze Szenen-Beschreibung.`;

// ── OpenRouter (Multi-Model Gateway) ─────────────────
const OpenRouterProvider = {
  providerName: 'OpenRouter',
  providerColor: '#7c3aed',
  requiresProxy: false,

  isConfigured: keys => !!keys.openrouterKey,

  async analyze(base64, keys) {
    const model = keys.openrouterModel || 'anthropic/claude-opus-4';
    const payload = {
      model,
      max_tokens: 1500,
      messages: [{
        role: 'user',
        content: [
          { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${base64}`, detail: 'high' } },
          { type: 'text', text: VISION_PROMPT }
        ]
      }]
    };

    try {
      const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${keys.openrouterKey}`,
          'HTTP-Referer': location.origin,
          'X-Title': 'Vision-Check'
        },
        body: JSON.stringify(payload)
      });
      if (!res.ok) {
        const e = await res.json().catch(() => ({}));
        throw new Error(e.error?.message || `HTTP ${res.status}`);
      }
      const json = await res.json();
      return {
        ok: true, source: `OpenRouter (${model.split('/')[1] || model})`,
        model, text: json.choices[0]?.message?.content || '',
        tokens: json.usage
      };
    } catch (err) {
      return { ok: false, source: 'OpenRouter', error: err.message };
    }
  }
};

// ── NVIDIA NIM (llama-3.2-90b-vision) ────────────────
const NvidiaProvider = {
  providerName: 'NVIDIA NIM',
  providerColor: '#76b900',
  requiresProxy: false,

  isConfigured: keys => !!keys.nvidiaKey,

  async analyze(base64, keys) {
    const model = 'meta/llama-3.2-90b-vision-instruct';
    const payload = {
      model,
      max_tokens: 1024,
      messages: [{
        role: 'user',
        content: [
          { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${base64}` } },
          { type: 'text', text: VISION_PROMPT }
        ]
      }]
    };

    try {
      const res = await fetch('https://integrate.api.nvidia.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${keys.nvidiaKey}`
        },
        body: JSON.stringify(payload)
      });
      if (!res.ok) {
        const e = await res.json().catch(() => ({}));
        throw new Error(e.detail || e.error?.message || `HTTP ${res.status}`);
      }
      const json = await res.json();
      return {
        ok: true, source: 'NVIDIA NIM (LLaMA 3.2 90B Vision)',
        model, text: json.choices[0]?.message?.content || '',
        tokens: json.usage
      };
    } catch (err) {
      return { ok: false, source: 'NVIDIA NIM', error: err.message };
    }
  }
};

// ── Perplexity sonar-pro (mit Web-Grounding) ──────────
// sonar-pro kann beim Bild-Upload nicht direkt ein Bild erhalten,
// aber wir nutzen es für Artenbeschreibung nach iNaturalist-Treffern.
// Für direkte Vision: sonar nutzt intern GPT-4o/Claude-Backbone.
const PerplexityProvider = {
  providerName: 'Perplexity sonar-pro',
  providerColor: '#20b2aa',
  requiresProxy: false,

  isConfigured: keys => !!keys.perplexityKey,

  // Spezial-Modus: Artenbeschreibung per Text + aktuelles Web-Grounding
  async describeSpecies(speciesName, keys) {
    const payload = {
      model: 'sonar-pro',
      messages: [
        {
          role: 'system',
          content: 'Du bist ein Biologe. Beantworte präzise auf Deutsch. Nutze aktuelle Web-Quellen.'
        },
        {
          role: 'user',
          content: `Beschreibe die Art "${speciesName}" detailliert: Verbreitung in Mitteleuropa, Erkennungsmerkmale, Lebensraum, Besonderheiten, Gefährdungsstatus (Rote Liste). Verlinke aktuelle Quellen.`
        }
      ]
    };

    try {
      const res = await fetch('https://api.perplexity.ai/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${keys.perplexityKey}`
        },
        body: JSON.stringify(payload)
      });
      if (!res.ok) {
        const e = await res.json().catch(() => ({}));
        throw new Error(e.error?.message || `HTTP ${res.status}`);
      }
      const json = await res.json();
      const text = json.choices[0]?.message?.content || '';
      const citations = json.citations || [];
      return { ok: true, source: 'Perplexity sonar-pro', text, citations };
    } catch (err) {
      return { ok: false, source: 'Perplexity', error: err.message };
    }
  },

  // Vision-Analyse via sonar (Text-only mit Beschreibungsaufforderung)
  async analyze(base64, keys) {
    // Perplexity sonar-pro unterstützt noch kein Bild-Input direkt im Standard-Endpoint.
    // Wir liefern eine erklärende Nachricht zurück.
    return {
      ok: false,
      source: 'Perplexity sonar-pro',
      error: 'Direktes Bild-Input nicht unterstützt. Nutze "Artenbeschreibung" nach iNaturalist-Erkennung.'
    };
  }
};

// ── ElevenLabs TTS ────────────────────────────────────
const ElevenLabsTTS = {
  providerName: 'ElevenLabs TTS',

  isConfigured: keys => !!keys.elevenlabsKey,

  async speak(text, keys) {
    const voiceId = keys.elevenlabsVoiceId || 'pNInz6obpgDQGcFmaJgB'; // Adam (Deutsch ok)
    const payload = {
      text: text.slice(0, 2500), // Limit
      model_id: 'eleven_multilingual_v2',
      voice_settings: { stability: 0.5, similarity_boost: 0.75 }
    };

    try {
      const res = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': keys.elevenlabsKey
        },
        body: JSON.stringify(payload)
      });
      if (!res.ok) throw new Error(`ElevenLabs HTTP ${res.status}`);

      const audioBlob = await res.blob();
      const audioUrl = URL.createObjectURL(audioBlob);
      const audio = new Audio(audioUrl);
      audio.play();
      return { ok: true, audioUrl };
    } catch (err) {
      return { ok: false, error: err.message };
    }
  }
};

// ── WaveSpeed Upscaling (Super-Resolution) ────────────
const WaveSpeedUpscaler = {
  providerName: 'WaveSpeed SR',

  isConfigured: keys => !!keys.wavespeedKey,

  async upscale(base64, keys) {
    // WaveSpeed REST-API: /api/v3/{model_uuid}
    // SR-Modell: ByteDance/SDXL-Lightning-4step oder RealESRGAN
    const modelUuid = 'wavespeed-ai/real-esrgan-x2plus'; // 2× Upscaling
    const payload = {
      image: `data:image/jpeg;base64,${base64}`,
      scale: 2
    };

    try {
      const res = await fetch(`https://api.wavespeed.ai/api/v3/${modelUuid}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${keys.wavespeedKey}`
        },
        body: JSON.stringify(payload)
      });
      if (!res.ok) throw new Error(`WaveSpeed HTTP ${res.status}`);

      const json = await res.json();
      // Async: Status-Polling wenn nötig
      if (json.status === 'completed' || json.output) {
        return { ok: true, source: 'WaveSpeed Real-ESRGAN', imageUrl: json.output || json.outputs?.[0] };
      }
      // Poll wenn queued
      if (json.id) {
        return await WaveSpeedUpscaler._poll(json.id, keys);
      }
      return { ok: false, source: 'WaveSpeed', error: 'Unbekannte Antwort' };
    } catch (err) {
      return { ok: false, source: 'WaveSpeed', error: err.message };
    }
  },

  async _poll(requestId, keys, maxAttempts = 20) {
    for (let i = 0; i < maxAttempts; i++) {
      await new Promise(r => setTimeout(r, 1500));
      try {
        const res = await fetch(`https://api.wavespeed.ai/api/v3/requests/${requestId}/outputs`, {
          headers: { 'Authorization': `Bearer ${keys.wavespeedKey}` }
        });
        if (!res.ok) continue;
        const json = await res.json();
        if (json.status === 'completed' && (json.output || json.outputs?.[0])) {
          return { ok: true, source: 'WaveSpeed Real-ESRGAN x2', imageUrl: json.output || json.outputs[0] };
        }
        if (json.status === 'failed') {
          return { ok: false, source: 'WaveSpeed', error: 'Upscaling fehlgeschlagen' };
        }
      } catch {}
    }
    return { ok: false, source: 'WaveSpeed', error: 'Timeout beim Upscaling' };
  }
};

// ── Provider-Registry ─────────────────────────────────
const ProviderRegistry = {
  vision: [OpenRouterProvider, NvidiaProvider],
  tts: ElevenLabsTTS,
  upscale: WaveSpeedUpscaler,
  search: PerplexityProvider,

  getActiveVisionProviders(keys) {
    return this.vision.filter(p => p.isConfigured(keys));
  },

  async analyzeAll(base64, keys, onProgress) {
    const tasks = this.vision
      .filter(p => p.isConfigured(keys))
      .map(p =>
        p.analyze(base64, keys).then(r => {
          onProgress && onProgress(p.providerName, r);
          return r;
        })
      );
    return Promise.allSettled(tasks).then(rs => rs.map(r => r.status === 'fulfilled' ? r.value : { ok: false }));
  }
};
