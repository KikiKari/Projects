// ═══════════════════════════════════════════
// Vision-Check — Einstellungen & API-Key-Management
// Alle Daten bleiben lokal im Browser (localStorage)
// ═══════════════════════════════════════════

'use strict';

const Settings = (() => {
  const KEY = 'vision-check-settings';

  const DEFAULTS = {
    // API Keys (lokal, kein Backend)
    openaiKey:   '',
    geminiKey:   '',
    claudeKey:   '',
    claudeProxy: '',        // Cloudflare Worker URL
    claudeModel: 'claude-opus-4-8',

    // Feature-Flags
    inat: true,             // iNaturalist als Stufe 0
    autoAnalyze: false,     // Analyse direkt nach Snapshot

    // Filter-Defaults
    brightness: 0,
    saturation: 1.2,
    clahe: 1.5,
    unsharp: 2,

    // UI
    loupeEnabled: true,
    loupeZoom: 8
  };

  function load() {
    try {
      const raw = localStorage.getItem(KEY);
      if (!raw) return { ...DEFAULTS };
      return { ...DEFAULTS, ...JSON.parse(raw) };
    } catch {
      return { ...DEFAULTS };
    }
  }

  function save(data) {
    try {
      localStorage.setItem(KEY, JSON.stringify({ ...load(), ...data }));
      return true;
    } catch (err) {
      console.error('Settings-Speicherung fehlgeschlagen:', err);
      return false;
    }
  }

  function clear() {
    localStorage.removeItem(KEY);
  }

  // Sicherheitsprüfung: Keys loggen NIE in die Konsole
  function hasKeys(s) {
    const cfg = s || load();
    return {
      openai: !!cfg.openaiKey,
      gemini: !!cfg.geminiKey,
      claude: !!cfg.claudeKey,
      proxy:  !!cfg.claudeProxy
    };
  }

  // Settings-Modal befüllen & speichern
  function bindModal(modalEl, onSave) {
    const get = id => modalEl.querySelector(`#${id}`);

    const cfg = load();

    // Werte in Felder schreiben (Keys gemaskert)
    const setMasked = (el, val) => {
      if (el) el.value = val ? '••••••••' + val.slice(-4) : '';
    };

    // Für Keys: Platzhalter zeigen wenn bereits gesetzt
    const keyFields = ['openai-key', 'gemini-key', 'claude-key'];
    keyFields.forEach(id => {
      const el = get(id);
      if (!el) return;
      const cfgKey = id.replace('-key', '').replace('-', '') + 'Key';
      // Leerfeld = noch nicht gesetzt, sonst Maske
      if (cfg[cfgKey]) el.placeholder = '(bereits gesetzt — neu eingeben zum Ändern)';
    });

    const proxyEl = get('claude-proxy');
    if (proxyEl) proxyEl.value = cfg.claudeProxy || '';

    const modelEl = get('claude-model');
    if (modelEl) modelEl.value = cfg.claudeModel || 'claude-opus-4-8';

    const inatEl = get('inat-toggle');
    if (inatEl) inatEl.checked = cfg.inat !== false;

    const autoEl = get('auto-analyze');
    if (autoEl) autoEl.checked = !!cfg.autoAnalyze;

    // Speichern
    const saveBtn = get('settings-save');
    if (saveBtn) {
      saveBtn.addEventListener('click', () => {
        const updates = {};

        // Keys: nur speichern wenn Feld nicht leer UND nicht Platzhalter
        const openaiEl = get('openai-key');
        if (openaiEl?.value && !openaiEl.value.startsWith('••')) {
          updates.openaiKey = openaiEl.value.trim();
        }

        const geminiEl = get('gemini-key');
        if (geminiEl?.value && !geminiEl.value.startsWith('••')) {
          updates.geminiKey = geminiEl.value.trim();
        }

        const claudeEl = get('claude-key');
        if (claudeEl?.value && !claudeEl.value.startsWith('••')) {
          updates.claudeKey = claudeEl.value.trim();
        }

        if (proxyEl) updates.claudeProxy = proxyEl.value.trim();
        if (modelEl) updates.claudeModel = modelEl.value;
        if (inatEl)  updates.inat = inatEl.checked;
        if (autoEl)  updates.autoAnalyze = autoEl.checked;

        save(updates);
        onSave && onSave(load());
        closeModal(modalEl);

        // Toast
        showToast('Einstellungen gespeichert ✓');
      });
    }

    // Schließen
    const closeBtn = get('settings-close');
    if (closeBtn) {
      closeBtn.addEventListener('click', () => closeModal(modalEl));
    }

    modalEl.addEventListener('click', e => {
      if (e.target === modalEl) closeModal(modalEl);
    });
  }

  function openModal(modalEl) {
    modalEl.classList.add('open');
  }

  function closeModal(modalEl) {
    modalEl.classList.remove('open');
  }

  function showToast(msg, duration = 3000) {
    let t = document.getElementById('vc-toast');
    if (!t) {
      t = document.createElement('div');
      t.id = 'vc-toast';
      Object.assign(t.style, {
        position: 'fixed', bottom: '24px', left: '50%',
        transform: 'translateX(-50%)',
        background: 'rgba(99,179,237,0.9)',
        color: '#0a0f1e',
        padding: '8px 20px',
        borderRadius: '8px',
        fontSize: '13px',
        fontWeight: '600',
        zIndex: '9999',
        opacity: '0',
        transition: 'opacity 0.3s'
      });
      document.body.appendChild(t);
    }
    t.textContent = msg;
    t.style.opacity = '1';
    clearTimeout(t._timer);
    t._timer = setTimeout(() => t.style.opacity = '0', duration);
  }

  return { load, save, clear, hasKeys, bindModal, openModal, closeModal, showToast, DEFAULTS };
})();
