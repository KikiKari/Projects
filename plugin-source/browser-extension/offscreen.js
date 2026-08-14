(function () {
  "use strict";

  const pending = [];
  let active = null;
  let audioContext = null;
  let audioSource = null;

  function queueDepth(tabId) {
    return pending.filter((item) => item.tabId === tabId).length + (active?.tabId === tabId ? 1 : 0);
  }

  function report(tabId, status) {
    chrome.runtime.sendMessage({
      type: "TLC_OFFSCREEN_STATUS",
      tabId,
      status,
      queueDepth: queueDepth(tabId)
    }).catch(() => {});
  }

  function browserVoice(name) {
    if (!name || !globalThis.speechSynthesis?.getVoices) return null;
    return globalThis.speechSynthesis.getVoices().find((voice) => voice.name === name) || null;
  }

  async function browserSpeech(item) {
    if (!globalThis.speechSynthesis || typeof SpeechSynthesisUtterance !== "function") throw new Error("Keine Browser-Sprachausgabe verfügbar.");
    await new Promise((resolve) => {
      const utterance = new SpeechSynthesisUtterance(item.text);
      utterance.lang = item.language || "";
      utterance.volume = Math.min(1, Number(item.volume || 0) * 2);
      const voice = browserVoice(item.voiceName);
      if (voice) utterance.voice = voice;
      utterance.onend = resolve;
      utterance.onerror = resolve;
      item.utterance = utterance;
      globalThis.speechSynthesis.speak(utterance);
    });
  }

  async function serviceSpeech(item) {
    if (!item.pairingCode) throw new Error("Kein Pairing-Code eingerichtet.");
    const response = await fetch(`${item.serviceUrl}/v1/tts`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${item.pairingCode}`,
        "X-TLC-Client": "offscreen-0.8.0",
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ text: item.text, language: item.language || "auto", voiceName: item.voiceName || "" })
    });
    if (!response.ok) throw new Error(`Sprachdienst HTTP ${response.status}`);
    const bytes = await response.arrayBuffer();
    audioContext ||= new AudioContext();
    if (audioContext.state === "suspended") await audioContext.resume();
    const buffer = await audioContext.decodeAudioData(bytes.slice(0));
    const source = audioContext.createBufferSource();
    const gain = audioContext.createGain();
    const limiter = audioContext.createDynamicsCompressor();
    gain.gain.value = item.volume <= 0.5 ? item.volume / 0.5 : 1 + ((item.volume - 0.5) / 0.5);
    limiter.threshold.value = -3;
    limiter.knee.value = 4;
    limiter.ratio.value = 20;
    limiter.attack.value = 0.003;
    limiter.release.value = 0.18;
    source.buffer = buffer;
    source.connect(gain).connect(limiter).connect(audioContext.destination);
    audioSource = source;
    await new Promise((resolve) => { source.onended = resolve; source.start(); });
    audioSource = null;
  }

  async function pump() {
    if (active || !pending.length) return;
    active = pending.shift();
    report(active.tabId, "Vorlesen aktiv · Ausgabe läuft.");
    try {
      await serviceSpeech(active).catch(() => browserSpeech(active));
      report(active.tabId, pending.some((item) => item.tabId === active.tabId)
        ? "Vorlesen aktiv · weitere Zeilen vorgemerkt."
        : "Vorlesen ist aktiv; warte auf neue Chatzeilen.");
    } catch (error) {
      report(active.tabId, `Vorlesen fehlgeschlagen: ${String(error?.message || error).slice(0, 180)}`);
    } finally {
      active = null;
      pump();
    }
  }

  function enqueue(message) {
    const tabId = Number(message.tabId);
    if (!Number.isInteger(tabId) || !String(message.text || "").trim()) return;
    const tabItems = pending.filter((item) => item.tabId === tabId);
    if (tabItems.length >= 5) pending.splice(pending.indexOf(tabItems[0]), 1);
    pending.push({
      tabId,
      text: String(message.text).slice(0, 1200),
      language: String(message.language || "auto").slice(0, 24),
      voiceName: String(message.voiceName || "").slice(0, 160),
      volume: Math.max(0, Math.min(1, Number(message.volume ?? 0.5))),
      serviceUrl: String(message.serviceUrl || "http://127.0.0.1:43117"),
      pairingCode: String(message.pairingCode || "")
    });
    report(tabId, "Vorlesen aktiv · Zeile vorgemerkt.");
    pump();
  }

  function cancel(tabId) {
    for (let index = pending.length - 1; index >= 0; index -= 1) if (pending[index].tabId === tabId) pending.splice(index, 1);
    if (active?.tabId === tabId) {
      globalThis.speechSynthesis?.cancel();
      try { audioSource?.stop(); } catch (_) { /* Ausgabe ist bereits beendet. */ }
      audioSource = null;
    }
    report(tabId, "Vorlesen ist ausgeschaltet.");
  }

  chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (sender.id !== chrome.runtime.id) return false;
    if (message?.target !== "offscreen") return false;
    if (message.type === "TLC_OFFSCREEN_SPEAK") enqueue(message);
    if (message.type === "TLC_OFFSCREEN_CANCEL") cancel(Number(message.tabId));
    sendResponse({ ok: true });
    return false;
  });
})();
