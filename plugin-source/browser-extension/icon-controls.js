(() => {
  "use strict";
  const styles = new Set(["plastisch", "glass", "linear"]);
  const picker = document.getElementById("icon-style");
  let style = "plastisch";
  try { const saved = localStorage.getItem("tlc-icon-style"); if (styles.has(saved)) style = saved; } catch {}
  function apply(value) { style = styles.has(value) ? value : "plastisch"; document.documentElement.dataset.iconStyle = style; picker.value = style; }
  apply(style);
  picker.addEventListener("change", () => { apply(picker.value); try { localStorage.setItem("tlc-icon-style", style); } catch {} });
  const fixed = {"open-normal-live":"browser", "player-vlc-frame":"player", "player-fullscreen":"fullscreen", "player-pip":"pip", "player-report":"report", "scan":"status", "enable-captions":"captions", "player-replay":"reset", "refresh-chat":"reset", "top-chatters-reset":"reset", "reset-tab":"reset", "refresh-page-info":"reset", "open-speech-settings":"settings", "open-connection-settings":"settings"};
  function decorate() {
    for (const [id, icon] of Object.entries(fixed)) { const el = document.getElementById(id); if (el) el.dataset.controlIcon = icon; }
    for (const id of ["toggle-speech", "toggle-hook"]) { const el=document.getElementById(id); if(el) el.dataset.controlIcon=el.textContent.trim()==="Off" ? "off" : "on"; }
    for (const [id, pair] of [["player-play", ["Play", "play", "stop"]], ["player-mute", ["Mute", "mute", "unmute"]]]) {
      const el = document.getElementById(id); if (el) { const icon = el.textContent.trim() === pair[0] ? pair[1] : pair[2]; if (el.dataset.controlIcon !== icon) el.dataset.controlIcon = icon; }
    }
    for (const id of [...Object.keys(fixed), "toggle-speech", "toggle-hook", "player-play", "player-mute"]) {
      const el = document.getElementById(id);
      if (!el) continue;
      const text = el.textContent.trim();
      const context = id === "toggle-speech" ? "Vorlesen: " : id === "toggle-hook" ? "Connection: " : "";
      const label = id === "refresh-page-info" ? "Refresh" : id === "open-speech-settings" ? "Erweiterte Einstellungen öffnen" : id === "open-connection-settings" ? "Connection-Einstellungen öffnen" : context + text;
      el.setAttribute("aria-label", label);
      el.setAttribute("title", label);
    }
    for (const el of document.querySelectorAll('button,input[type="checkbox"]')) {
      if (!el.getAttribute("title")) {
        const label = el.getAttribute("aria-label") || el.textContent.trim() || el.closest("label")?.textContent.trim();
        if (label) el.setAttribute("title", label);
      }
    }
  }
  decorate();
  new MutationObserver(decorate).observe(document.body, {subtree:true, childList:true, characterData:true});
})();
