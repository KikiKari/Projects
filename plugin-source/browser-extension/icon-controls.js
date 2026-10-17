(() => {
  "use strict";
  const styles = new Set(["plastisch", "glass", "linear"]);
  const picker = document.getElementById("icon-style");
  let style = "plastisch";
  try { const saved = localStorage.getItem("tlc-icon-style"); if (styles.has(saved)) style = saved; } catch {}
  function apply(value) { style = styles.has(value) ? value : "plastisch"; document.documentElement.dataset.iconStyle = style; picker.value = style; }
  apply(style);
  picker.addEventListener("change", () => { apply(picker.value); try { localStorage.setItem("tlc-icon-style", style); } catch {} });
  const fixed = {"open-normal-live":"browser", "player-vlc-frame":"player", "player-fullscreen":"fullscreen", "player-pip":"pip", "player-report":"report", "scan":"status", "enable-captions":"captions", "player-replay":"reset", "clear":"reset", "clear-debug":"reset", "refresh-chat":"reset", "top-chatters-reset":"reset", "reset-tab":"reset", "refresh-page-info":"reset", "open-speech-settings":"settings", "open-connection-settings":"settings"};
  const counters = new Map();
  function setHeaderLed(dot, active, label) {
    dot.classList.toggle("on", active);
    dot.classList.toggle("off", !active);
    dot.setAttribute("aria-label", label);
    dot.title = label;
  }
  function decorateHeaders() {
    for (const dot of document.querySelectorAll("[data-switch-status]")) {
      const input = document.getElementById(dot.dataset.switchStatus);
      if (input) setHeaderLed(dot, input.checked, `${input.getAttribute("aria-label")}: ${input.checked ? "aktiviert" : "deaktiviert"}`);
    }
    for (const dot of document.querySelectorAll("[data-counter-status]")) {
      const id = dot.dataset.counterStatus;
      const value = Number(document.getElementById(id)?.textContent || 0);
      const previous = counters.get(id);
      const changedAt = previous && value > previous.value ? Date.now() : previous?.changedAt || 0;
      counters.set(id, { value, changedAt });
      setHeaderLed(dot, value > 0 && Date.now() - changedAt < 30000, "Counter: " + (value > 0 && Date.now() - changedAt < 30000 ? "neue Einträge" : "keine neuen Einträge"));
    }
  }
  function decorate() {
    decorateHeaders();
    for (const [id, icon] of Object.entries(fixed)) { const el = document.getElementById(id); if (el) el.dataset.controlIcon = icon; }
    for (const id of ["toggle-speech", "toggle-hook"]) { const el=document.getElementById(id); if(el) { const enabled = el.textContent.trim()==="Off"; el.dataset.controlIcon=enabled ? "on" : "off"; el.setAttribute("aria-pressed", String(enabled)); } }
    for (const [id, pair] of [["player-play", ["Play", "play", "stop"]], ["player-mute", ["Mute", "mute", "unmute"]]]) {
      const el = document.getElementById(id); if (el) { const icon = el.textContent.trim() === pair[0] ? pair[1] : pair[2]; if (el.dataset.controlIcon !== icon) el.dataset.controlIcon = icon; }
    }
    for (const id of [...Object.keys(fixed), "toggle-speech", "toggle-hook", "player-play", "player-mute"]) {
      const el = document.getElementById(id);
      if (!el) continue;
      const text = el.textContent.trim();
      const context = id === "toggle-speech" ? "Vorlesen: " : id === "toggle-hook" ? "Connection: " : "";
      const stateText = context ? (el.getAttribute("aria-pressed") === "true" ? "On" : "Off") : text;
      const label = id === "refresh-page-info" ? "Refresh" : id === "open-speech-settings" ? "Erweiterte Einstellungen öffnen" : id === "open-connection-settings" ? "Connection-Einstellungen öffnen" : context + stateText;
      el.setAttribute("aria-label", label);
      el.setAttribute("title", label);
    }
    for (const el of document.querySelectorAll('button,input[type="checkbox"]')) {
      if (el.type === "checkbox") {
        const names = {"keep-speech-active":"Vorlesen dauerhaft", "hook-autostart":"Hook dauerhaft", "limiter-enabled":"Pegelschutz", "song-enabled":"Songerkennung"};
        const name = names[el.id] || el.getAttribute("aria-label") || el.closest("label")?.textContent.trim();
        if (name) { el.setAttribute("aria-label", name); el.setAttribute("title", `${name}: ${el.checked ? "On" : "Off"}`); }
        continue;
      }
      if (!el.getAttribute("title")) {
        const label = el.getAttribute("aria-label") || el.textContent.trim() || el.closest("label")?.textContent.trim();
        if (label) el.setAttribute("title", label);
      }
    }
  }
  decorate();
  document.addEventListener("change", decorate);
  setInterval(decorateHeaders, 1000);
  new MutationObserver(decorate).observe(document.body, {subtree:true, childList:true, characterData:true});
})();
