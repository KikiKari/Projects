// ═══════════════════════════════════════════
// Vision-Check — Zentrales .env-Management
// AES-GCM verschlüsselter Export/Import
// Alle Secrets bleiben lokal im Browser
// ═══════════════════════════════════════════
'use strict';

const EnvManager = (() => {
  const STORAGE_KEY = 'vision-check-env-v2';

  // Vollständiges Schema aller unterstützten Keys
  const ENV_SCHEMA = [
    // ── Tier 1: Basis ────────────────────────────────
    {
      group: 'Basis Vision-APIs',
      color: 'var(--accent)',
      fields: [
        { key: 'openaiKey',    label: 'OpenAI API-Key',    placeholder: 'sk-proj-…',  type: 'password', hint: 'platform.openai.com/api-keys — GPT-4o Vision' },
        { key: 'geminiKey',    label: 'Google Gemini Key', placeholder: 'AIzaSy…',    type: 'password', hint: 'aistudio.google.com — Gemini 2.5 Pro' },
        { key: 'claudeKey',    label: 'Anthropic Claude',  placeholder: 'sk-ant-…',   type: 'password', hint: 'console.anthropic.com' },
        { key: 'claudeProxy',  label: 'Claude CORS-Proxy', placeholder: 'https://…workers.dev', type: 'url', hint: 'Cloudflare Worker URL (nötig für Browser → Claude)' },
        { key: 'claudeModel',  label: 'Claude Modell',     placeholder: '',           type: 'select',
          options: ['claude-opus-4-8', 'claude-fable-5', 'claude-sonnet-4-5'],
          hint: 'Opus 4.8 = beste Bildanalyse' }
      ]
    },
    // ── Tier 2: Erweiterte Anbieter ──────────────────
    {
      group: 'Erweiterte Anbieter',
      color: '#7c3aed',
      fields: [
        { key: 'openrouterKey',   label: 'OpenRouter Key',      placeholder: 'sk-or-…',   type: 'password', hint: 'openrouter.ai — Zugang zu 200+ Modellen (claude, llava, gemma…)' },
        { key: 'openrouterModel', label: 'OpenRouter Modell',   placeholder: '',           type: 'text',     hint: 'z.B. anthropic/claude-opus-4, meta-llama/llama-3.2-90b-vision' },
        { key: 'nvidiaKey',       label: 'NVIDIA NIM Key',      placeholder: 'nvapi-…',    type: 'password', hint: 'build.nvidia.com — LLaMA 3.2 90B Vision' },
        { key: 'perplexityKey',   label: 'Perplexity API-Key',  placeholder: 'pplx-…',     type: 'password', hint: 'perplexity.ai/settings/api — sonar-pro für Artenbeschreibung' }
      ]
    },
    // ── Tier 3: Funktions-Erweiterungen ─────────────
    {
      group: 'Funktions-Erweiterungen',
      color: 'var(--accent-warn)',
      fields: [
        { key: 'elevenlabsKey',     label: 'ElevenLabs TTS Key',     placeholder: 'el-…',  type: 'password', hint: 'elevenlabs.io — Analyseergebnis vorlesen (deutsch)' },
        { key: 'elevenlabsVoiceId', label: 'ElevenLabs Voice-ID',    placeholder: 'pNInz…', type: 'text',    hint: 'Standard: Adam (multilingual). Voice-ID aus elevenlabs.io/voice-lab' },
        { key: 'wavespeedKey',      label: 'WaveSpeed SR Key',       placeholder: 'ws-…',   type: 'password', hint: 'wavespeed.ai — Real-ESRGAN 2× Bild-Upscaling vor Analyse' }
      ]
    },
    // ── Feature-Flags ────────────────────────────────
    {
      group: 'Funktionen',
      color: 'var(--accent-ok)',
      fields: [
        { key: 'inat',         label: 'iNaturalist (kostenlos)', type: 'toggle', default: true,  hint: 'Artenbestimmung ohne API-Key' },
        { key: 'autoAnalyze',  label: 'Auto-Analyse nach Snapshot', type: 'toggle', default: false },
        { key: 'ttsEnabled',   label: 'Ergebnis vorlesen (ElevenLabs)', type: 'toggle', default: false },
        { key: 'upscaleEnabled', label: 'Upscaling vor Analyse (WaveSpeed)', type: 'toggle', default: false },
        { key: 'openrouterEnabled', label: 'OpenRouter aktivieren', type: 'toggle', default: false },
        { key: 'nvidiaEnabled',  label: 'NVIDIA NIM aktivieren', type: 'toggle', default: false },
        { key: 'pplxDescribe',   label: 'Perplexity Artenbeschreibung aktivieren', type: 'toggle', default: false },
        { key: 'loupeEnabled',   label: 'Pixel-Lupe aktivieren', type: 'toggle', default: true },
        { key: 'brightness',  label: 'Helligkeit',       type: 'range', min: -80, max: 80,  default: 0 },
        { key: 'saturation',  label: 'Sättigung',        type: 'range', min: 0,   max: 3,   default: 1.2, step: 0.1 },
        { key: 'clahe',       label: 'CLAHE-Stärke',     type: 'range', min: 1,   max: 4,   default: 1.5, step: 0.1 },
        { key: 'unsharp',     label: 'Schärfe (Unsharp)',type: 'range', min: 0,   max: 5,   default: 2,   step: 1 },
        { key: 'loupeZoom',   label: 'Lupe Zoom-Faktor', type: 'range', min: 2,   max: 16,  default: 8,   step: 1 }
      ]
    }
  ];

  // ── Speichern / Laden ─────────────────────────────
  function load() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return getDefaults();
      return { ...getDefaults(), ...JSON.parse(raw) };
    } catch { return getDefaults(); }
  }

  function save(data) {
    try {
      const current = load();
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ ...current, ...data }));
      return true;
    } catch (err) {
      console.error('EnvManager.save:', err);
      return false;
    }
  }

  function getDefaults() {
    const d = {};
    ENV_SCHEMA.forEach(group => {
      group.fields.forEach(f => {
        if (f.default !== undefined) d[f.key] = f.default;
        else if (f.type === 'toggle') d[f.key] = false;
        else if (f.type === 'text' || f.type === 'password' || f.type === 'url') d[f.key] = '';
        else if (f.type === 'select') d[f.key] = f.options?.[0] || '';
        else if (f.type === 'range') d[f.key] = f.default ?? 0;
      });
    });
    return d;
  }

  // ── AES-GCM Export/Import ─────────────────────────
  async function exportEncrypted(passphrase) {
    const data = load();
    // Keys herausfiltern (nicht Flags/Range)
    const exportData = {};
    ENV_SCHEMA.forEach(g => g.fields.forEach(f => {
      if (data[f.key] !== undefined) exportData[f.key] = data[f.key];
    }));

    const enc = new TextEncoder();
    const keyMaterial = await crypto.subtle.importKey('raw', enc.encode(passphrase), 'PBKDF2', false, ['deriveKey']);
    const salt = crypto.getRandomValues(new Uint8Array(16));
    const iv   = crypto.getRandomValues(new Uint8Array(12));
    const key  = await crypto.subtle.deriveKey(
      { name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' },
      keyMaterial,
      { name: 'AES-GCM', length: 256 },
      false, ['encrypt']
    );
    const ciphertext = await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, enc.encode(JSON.stringify(exportData)));

    const out = {
      v: 1,
      salt: btoa(String.fromCharCode(...salt)),
      iv:   btoa(String.fromCharCode(...iv)),
      data: btoa(String.fromCharCode(...new Uint8Array(ciphertext)))
    };
    return JSON.stringify(out, null, 2);
  }

  async function importEncrypted(jsonStr, passphrase) {
    try {
      const { v, salt, iv, data } = JSON.parse(jsonStr);
      if (v !== 1) throw new Error('Unbekannte Version');

      const b64 = s => Uint8Array.from(atob(s), c => c.charCodeAt(0));
      const enc = new TextEncoder();
      const keyMaterial = await crypto.subtle.importKey('raw', enc.encode(passphrase), 'PBKDF2', false, ['deriveKey']);
      const key = await crypto.subtle.deriveKey(
        { name: 'PBKDF2', salt: b64(salt), iterations: 100000, hash: 'SHA-256' },
        keyMaterial,
        { name: 'AES-GCM', length: 256 },
        false, ['decrypt']
      );
      const plaintext = await crypto.subtle.decrypt({ name: 'AES-GCM', iv: b64(iv) }, key, b64(data));
      const imported = JSON.parse(new TextDecoder().decode(plaintext));
      save(imported);
      return { ok: true, count: Object.keys(imported).length };
    } catch (err) {
      return { ok: false, error: err.message };
    }
  }

  // Unverschlüsselter Export (nur Flags, keine Keys)
  function exportSettings() {
    const d = load();
    const safe = {};
    ENV_SCHEMA.forEach(g => g.fields.forEach(f => {
      if (f.type === 'toggle' || f.type === 'range') safe[f.key] = d[f.key];
    }));
    return JSON.stringify(safe, null, 2);
  }

  // ── Settings-Modal HTML generieren ───────────────
  function buildModalContent(containerEl) {
    const keys = load();
    containerEl.innerHTML = '';

    // Tab-Bar
    const tabBar = document.createElement('div');
    tabBar.className = 'tab-bar';
    tabBar.style.marginBottom = '16px';

    const tabContents = [];
    ENV_SCHEMA.forEach((group, i) => {
      const tabBtn = document.createElement('button');
      tabBtn.className = 'tab' + (i === 0 ? ' active' : '');
      tabBtn.textContent = group.group;
      tabBtn.dataset.tab = `env-tab-${i}`;
      tabBtn.style.setProperty('--tab-color', group.color);
      tabBtn.addEventListener('click', () => {
        containerEl.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        tabBtn.classList.add('active');
        tabContents.forEach(tc => tc.style.display = 'none');
        tabContents[i].style.display = 'block';
      });
      tabBar.appendChild(tabBtn);
    });
    containerEl.appendChild(tabBar);

    // Inhalt pro Gruppe
    ENV_SCHEMA.forEach((group, i) => {
      const div = document.createElement('div');
      div.style.display = i === 0 ? 'block' : 'none';

      group.fields.forEach(field => {
        const val = keys[field.key];
        const row = document.createElement('div');
        row.style.marginBottom = '14px';

        const label = document.createElement('label');
        label.className = 'settings-label';
        label.textContent = field.label;
        row.appendChild(label);

        if (field.type === 'toggle') {
          const wrap = document.createElement('div');
          wrap.style.cssText = 'display:flex;align-items:center;gap:10px';
          const toggleLabel = document.createElement('label');
          toggleLabel.className = 'toggle-switch';
          const inp = document.createElement('input');
          inp.type = 'checkbox';
          inp.id = `env-${field.key}`;
          inp.checked = !!val;
          const track = document.createElement('div');
          track.className = 'toggle-track';
          const thumb = document.createElement('div');
          thumb.className = 'toggle-thumb';
          toggleLabel.append(inp, track, thumb);
          wrap.appendChild(toggleLabel);
          if (field.hint) {
            const hint = document.createElement('span');
            hint.style.cssText = 'font-size:10px;color:var(--text-dim)';
            hint.textContent = field.hint;
            wrap.appendChild(hint);
          }
          row.appendChild(wrap);

        } else if (field.type === 'range') {
          const rangeWrap = document.createElement('div');
          rangeWrap.className = 'slider-row';
          rangeWrap.style.cssText = 'display:flex;align-items:center;gap:8px';
          const inp = document.createElement('input');
          inp.type = 'range';
          inp.id = `env-${field.key}`;
          inp.min = field.min; inp.max = field.max;
          inp.step = field.step || 1;
          inp.value = val ?? field.default ?? 0;
          inp.style.flex = '1';
          const valSpan = document.createElement('span');
          valSpan.className = 'slider-value';
          valSpan.textContent = inp.value;
          inp.addEventListener('input', () => valSpan.textContent = inp.value);
          rangeWrap.append(inp, valSpan);
          row.appendChild(rangeWrap);

        } else if (field.type === 'select') {
          const sel = document.createElement('select');
          sel.id = `env-${field.key}`;
          sel.className = 'settings-input';
          (field.options || []).forEach(opt => {
            const o = document.createElement('option');
            o.value = opt; o.textContent = opt;
            if (val === opt) o.selected = true;
            sel.appendChild(o);
          });
          row.appendChild(sel);
          if (field.hint) {
            const hint = document.createElement('p');
            hint.className = 'settings-hint';
            hint.textContent = field.hint;
            row.appendChild(hint);
          }

        } else {
          // text / password / url
          const inp = document.createElement('input');
          inp.type = field.type;
          inp.id = `env-${field.key}`;
          inp.className = 'settings-input';
          inp.autocomplete = 'off';
          inp.autocapitalize = 'off';
          inp.spellcheck = false;
          if (val && field.type === 'password') {
            inp.placeholder = '(gesetzt — neu eingeben zum Ändern)';
          } else {
            inp.placeholder = field.placeholder || '';
            if (val && field.type !== 'password') inp.value = val;
          }
          row.appendChild(inp);
          if (field.hint) {
            const hint = document.createElement('p');
            hint.className = 'settings-hint';
            hint.innerHTML = field.hint;
            row.appendChild(hint);
          }
        }

        div.appendChild(row);
      });

      // Export/Import-Sektion in letzter Gruppe
      if (i === ENV_SCHEMA.length - 1) {
        const sep = document.createElement('hr');
        sep.style.cssText = 'border:none;border-top:1px solid var(--border);margin:16px 0';
        div.appendChild(sep);

        const title = document.createElement('div');
        title.className = 'settings-section-title';
        title.textContent = 'Backup & Import';
        div.appendChild(title);

        const exportWrap = document.createElement('div');
        exportWrap.style.cssText = 'display:flex;gap:8px;flex-wrap:wrap;margin-bottom:10px';

        const exportBtn = document.createElement('button');
        exportBtn.className = 'btn btn-sm';
        exportBtn.textContent = '↓ Exportieren (verschlüsselt)';
        exportBtn.addEventListener('click', async () => {
          const pass = prompt('Exportpasswort (AES-GCM):');
          if (!pass) return;
          const json = await exportEncrypted(pass);
          const blob = new Blob([json], { type: 'application/json' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url; a.download = 'vision-check-env.json';
          a.click();
          URL.revokeObjectURL(url);
        });

        const importBtn = document.createElement('button');
        importBtn.className = 'btn btn-sm';
        importBtn.textContent = '↑ Importieren';
        importBtn.addEventListener('click', () => {
          const fi = document.createElement('input');
          fi.type = 'file'; fi.accept = '.json';
          fi.onchange = async e => {
            const text = await e.target.files[0].text();
            const pass = prompt('Import-Passwort:');
            if (!pass) return;
            const result = await importEncrypted(text, pass);
            if (result.ok) {
              alert(`✓ ${result.count} Einstellungen importiert. Seite neu laden.`);
              location.reload();
            } else {
              alert('Import fehlgeschlagen: ' + result.error);
            }
          };
          fi.click();
        });

        exportWrap.append(exportBtn, importBtn);
        div.appendChild(exportWrap);

        const hint = document.createElement('p');
        hint.className = 'settings-hint';
        hint.textContent = 'AES-256-GCM Verschlüsselung. Passwort wird nicht gespeichert.';
        div.appendChild(hint);
      }

      containerEl.appendChild(div);
      tabContents.push(div);
    });
  }

  // ── Werte aus Modal lesen und speichern ───────────
  function collectAndSave(containerEl) {
    const updates = {};
    ENV_SCHEMA.forEach(group => {
      group.fields.forEach(field => {
        const el = containerEl.querySelector(`#env-${field.key}`);
        if (!el) return;

        if (field.type === 'toggle') {
          updates[field.key] = el.checked;
        } else if (field.type === 'range') {
          updates[field.key] = parseFloat(el.value);
        } else if (field.type === 'select') {
          updates[field.key] = el.value;
        } else if (field.type === 'password') {
          // Nur speichern wenn neu eingegeben (nicht der Platzhalter)
          if (el.value && !el.value.startsWith('(')) {
            updates[field.key] = el.value.trim();
          }
        } else {
          if (el.value !== undefined) updates[field.key] = el.value.trim();
        }
      });
    });
    save(updates);
    return updates;
  }

  // Alle konfigurierten Keys als Status-Übersicht
  function getStatus() {
    const d = load();
    return {
      openai:       !!d.openaiKey,
      gemini:       !!d.geminiKey,
      claude:       !!d.claudeKey,
      claudeProxy:  !!d.claudeProxy,
      openrouter:   !!d.openrouterKey && d.openrouterEnabled,
      nvidia:       !!d.nvidiaKey && d.nvidiaEnabled,
      perplexity:   !!d.perplexityKey && d.pplxDescribe,
      elevenlabs:   !!d.elevenlabsKey && d.ttsEnabled,
      wavespeed:    !!d.wavespeedKey && d.upscaleEnabled,
      inat:         d.inat !== false,
      autoAnalyze:  !!d.autoAnalyze
    };
  }

  return {
    load, save, getDefaults, getStatus,
    buildModalContent, collectAndSave,
    exportEncrypted, importEncrypted, exportSettings,
    ENV_SCHEMA
  };
})();
