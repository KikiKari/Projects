(function () {
  "use strict";

  const elements = Object.fromEntries([
    "page-title", "chat-list", "chat-count", "chat-led", "refresh-chat", "toggle-speech", "speech-led", "speech-status", "speech-volume", "speech-volume-output", "keep-speech-active",
    "speech-language", "speech-voice", "speak-names", "game-mode", "shorten-names", "audd-token", "pairing-code", "service-action", "sherpa-action", "service-status", "service-setup", "copy-service-setup",
    "top-chatters", "team-tag-status", "open-audience", "audience-modal", "close-audience", "audience-list", "audience-limit",
    "song-enabled", "song-led", "recognize-song", "song-status", "song-result",
    "caption-status", "hook-status", "hook-led", "hook-autostart", "quick-recover", "media-list", "media-count", "caption-list", "caption-count",
    "notice", "caption-action-status", "live-stats", "stats-status", "stats-live",
    "player-time", "player-status", "player-play", "player-replay", "player-mute", "player-pip", "player-fullscreen", "player-report", "player-vlc-frame",
    "player-volume", "player-volume-output", "player-peak", "limiter-enabled", "limiter-strength", "limiter-strength-output", "multi-guest-status",
    "page-info-section", "page-info-source", "profile-info", "summary-info", "refresh-page-info", "force-page-info",
    "scan", "enable-captions",
    "enable-hook", "disable-hook", "reset-tab", "open-embed-live", "open-normal-live", "export-log", "clear", "debug-enabled", "debug-count", "export-debug", "clear-debug"
  ].map((id) => [id, document.getElementById(id)]));
  const PLAYER_BUTTONS = ["player-play", "player-replay", "player-mute", "player-pip", "player-fullscreen", "player-report"];
  const DEFAULT_SERVICE_URL = "http://127.0.0.1:43117";
  const core = globalThis.TLC_CONTENT_CORE;
  let activeTabId = null;
  let activeIsTikTok = false;
  let previousTabId = null;
  let currentState = null;
  let speechEnabled = false;
  let speechBusy = false;
  let speechInitialized = false;
  let speechQueue = [];
  let keepSpeechActive = false;
  let speechTabId = null;
  let speechVolume = 0.5;
  let speechLanguage = "auto";
  let speechVoiceName = "";
  let speakNames = true;
  let gameModeEnabled = false;
  let shortenNames = false;
  let serviceUrl = DEFAULT_SERVICE_URL;
  let pairingCode = "";
  let auddApiToken = "";
  let sherpaInstallStarted = false;
  let voiceCatalog = [];
  let permanentMutes = new Set();
  let speechAudioContext = null;
  let speechAudioSource = null;
  const knownSpeechKeys = new Set();
  const recentSpokenKeys = new Map();
  const SPEECH_REPEAT_WINDOW_MS = 20000;
  const TAB_OPTIONAL_MESSAGES = new Set(["TLC_GET_SETTINGS", "TLC_SET_AUTOSTART", "TLC_SET_QUICK_RECOVER", "TLC_ENABLE_HOOK", "TLC_DISABLE_HOOK", "TLC_SET_DEBUG"]);

  async function activeTab() {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    return tab;
  }

  async function send(type, payload = {}) {
    if (!Number.isInteger(activeTabId) && !TAB_OPTIONAL_MESSAGES.has(type)) throw new Error("Kein aktiver Tab gefunden.");
    const response = await chrome.runtime.sendMessage({ type, ...(Number.isInteger(activeTabId) ? { tabId: activeTabId } : {}), ...payload });
    if (!response?.ok) throw Object.assign(new Error(response?.error || "Aktion fehlgeschlagen"), { code: response?.code || "UNKNOWN" });
    return response;
  }

  function clearChildren(node) {
    while (node.firstChild) node.removeChild(node.firstChild);
  }

  function statusCard(label, value, tone) {
    const card = document.createElement("div");
    card.className = `status ${tone}`;
    const labelNode = document.createElement("span");
    labelNode.className = "status-label";
    labelNode.textContent = label;
    const valueNode = document.createElement("span");
    valueNode.className = "status-value";
    valueNode.textContent = value;
    card.append(labelNode, valueNode);
    return card;
  }

  function formatCount(value) {
    if (value == null || value === "") return "–";
    try { return new Intl.NumberFormat("de-DE").format(BigInt(value)); }
    catch (_) { return String(value); }
  }

  function booleanValue(value) {
    if (typeof value === "boolean") return value;
    if (typeof value === "number") return value !== 0;
    if (typeof value === "string") return /^(?:1|true|yes|ja|on)$/i.test(value.trim());
    return Boolean(value);
  }

  function chatKey(item) {
    return String(item.messageId || item.dedupeKey || `${item.receivedAtUtc || ""}|${item.author || ""}|${item.content || ""}`);
  }

  function speechRepeatKey(item) {
    return `${core.spokenNickname(item.author || item.nickname || item.displayId || "")}|${speechText(item)}`.toLocaleLowerCase("de-DE").replace(/\s+/g, " ").trim();
  }

  function shouldSkipRecentSpeech(item, now = Date.now()) {
    const key = speechRepeatKey(item);
    if (!key || key.endsWith("|")) return false;
    for (const [existing, lastAt] of recentSpokenKeys) {
      if (now - lastAt > SPEECH_REPEAT_WINDOW_MS) recentSpokenKeys.delete(existing);
    }
    const lastAt = recentSpokenKeys.get(key) || 0;
    recentSpokenKeys.set(key, now);
    return now - lastAt <= SPEECH_REPEAT_WINDOW_MS;
  }

  function setLed(element, active, activeLabel, inactiveLabel) {
    element.classList.toggle("on", active);
    element.classList.toggle("off", !active);
    const label = active ? activeLabel : inactiveLabel;
    element.setAttribute("aria-label", label);
    element.title = label;
  }

  function persistSpeechEnabled(enabled, tabId = speechTabId ?? activeTabId) {
    if (!Number.isInteger(tabId)) return Promise.resolve();
    return chrome.runtime.sendMessage({ type: "TLC_SET_TAB_SPEECH", tabId, enabled: Boolean(enabled) }).catch(() => {});
  }

  function activateSpeech(message = "Vorlesen ist aktiv; neue Chatzeilen werden vorgelesen.", persist = true) {
    speechEnabled = true;
    speechTabId = activeTabId;
    speechQueue = [];
    for (const item of currentState?.chatMessages || []) knownSpeechKeys.add(chatKey(item));
    elements["toggle-speech"].textContent = "Vorlesen aus";
    elements["toggle-speech"].setAttribute("aria-pressed", "true");
    setLed(elements["speech-led"], true, "Vorlesen aktiv", "Vorlesen inaktiv");
    elements["speech-status"].textContent = message;
    if (persist) persistSpeechEnabled(true);
  }

  function stopSpeech(message = "Vorlesen ist ausgeschaltet.", persist = true, tabId = speechTabId ?? activeTabId) {
    speechEnabled = false;
    speechBusy = false;
    speechQueue = [];
    speechTabId = null;
    recentSpokenKeys.clear();
    globalThis.speechSynthesis?.cancel();
    try { speechAudioSource?.stop(); } catch (_) { /* Already stopped. */ }
    speechAudioSource = null;
    elements["toggle-speech"].textContent = "Vorlesen an";
    elements["toggle-speech"].setAttribute("aria-pressed", "false");
    setLed(elements["speech-led"], false, "Vorlesen aktiv", "Vorlesen inaktiv");
    elements["speech-status"].textContent = message;
    if (persist) persistSpeechEnabled(false, tabId);
  }

  function serviceHeaders(extra = {}) {
    return { "Authorization": `Bearer ${pairingCode}`, "X-TLC-Client": "sidepanel-0.7.1", ...extra };
  }

  function speechText(item) {
    return cleanSpeechPayload(core.composeSpeechText(item, {
      teamTag: currentState?.stream?.teamTag || "",
      speakNames,
      shortenNames
    }));
  }

  function cleanSpeechPayload(value) {
    return String(value || "")
      .normalize("NFC")
      .replace(/[\u0000-\u001f\u007f-\u009f]/g, " ")
      .replace(/[\u200b-\u200f\u202a-\u202e\u2060-\u206f\ufeff]/g, "")
      .replace(/[\ufe00-\ufe0f\u200d]/g, "")
      .replace(/[\u{1f000}-\u{1faff}\u{2600}-\u{27bf}]/gu, " ")
      .replace(/\s+/g, " ")
      .trim();
  }

  function hasGermanSpecialChars(value) {
    const text = String(value || "");
    for (const code of [0x00E4, 0x00F6, 0x00FC, 0x00C4, 0x00D6, 0x00DC, 0x00DF]) {
      if (text.indexOf(String.fromCharCode(code)) >= 0) return true;
    }
    return false;
  }

  function speechLang(item, text = "") {
    if (speechLanguage === "auto" && hasGermanSpecialChars(text)) return "de-DE";
    return core.resolveSpeechLanguage(speechLanguage, item.contentLanguage);
  }

  function browserVoiceByName(name) {
    if (!name || !globalThis.speechSynthesis?.getVoices) return null;
    return globalThis.speechSynthesis.getVoices().find((voice) => voice.name === name) || null;
  }

  async function browserSpeech(text, lang) {
    if (!globalThis.speechSynthesis || typeof SpeechSynthesisUtterance !== "function") throw new Error("Keine Browser-Sprachausgabe verfügbar.");
    await new Promise((resolve) => {
      const utterance = new SpeechSynthesisUtterance(text);
      if (lang) utterance.lang = lang;
      const voice = browserVoiceByName(speechVoiceName);
      if (voice) utterance.voice = voice;
      utterance.volume = Math.min(1, speechVolume * 2);
      utterance.onend = resolve;
      utterance.onerror = resolve;
      globalThis.speechSynthesis.speak(utterance);
    });
    if (speechVolume > 0.5) elements["service-status"].textContent = "Browser-Fallback aktiv: oberhalb 50 % ist keine Zusatzverstärkung möglich.";
  }

  async function serviceSpeech(text, lang) {
    if (!pairingCode) throw new Error("Kein Pairing-Code eingerichtet.");
    const response = await fetch(`${serviceUrl}/v1/tts`, {
      method: "POST",
      headers: serviceHeaders({ "Content-Type": "application/json" }),
      body: JSON.stringify({ text, language: lang || "auto", voiceName: speechVoiceName })
    });
    if (!response.ok) throw new Error(`Sprachdienst HTTP ${response.status}`);
    const data = await response.arrayBuffer();
    speechAudioContext ||= new AudioContext();
    if (speechAudioContext.state === "suspended") await speechAudioContext.resume();
    const buffer = await speechAudioContext.decodeAudioData(data.slice(0));
    const source = speechAudioContext.createBufferSource();
    const gain = speechAudioContext.createGain();
    const limiter = speechAudioContext.createDynamicsCompressor();
    gain.gain.value = speechVolume <= 0.5 ? speechVolume / 0.5 : 1 + ((speechVolume - 0.5) / 0.5);
    limiter.threshold.value = -3;
    limiter.knee.value = 4;
    limiter.ratio.value = 20;
    limiter.attack.value = 0.003;
    limiter.release.value = 0.18;
    source.buffer = buffer;
    source.connect(gain).connect(limiter).connect(speechAudioContext.destination);
    speechAudioSource = source;
    await new Promise((resolve) => { source.onended = resolve; source.start(); });
    speechAudioSource = null;
    elements["service-status"].textContent = `Lokaler Sprachdienst aktiv · ${lang || "Auto"}.`;
  }

  function sherpaSpeechVoices(voices = [], catalog = voiceCatalog) {
    const installedById = new Map(voices.map((voice) => [String(voice.id || voice.name || ""), voice]));
    return (catalog.length ? catalog : voices).map((voice) => {
      const id = String(voice.id || voice.name || "").trim();
      const installedVoice = installedById.get(id);
      return {
        ...voice,
        ...installedVoice,
        id,
        name: String(voice.name || installedVoice?.name || id),
        installed: Boolean(voice.installed || installedVoice)
      };
    }).filter((voice) => voice.id && voice.name).sort((a, b) => String(a.culture).localeCompare(String(b.culture)) || a.name.localeCompare(b.name));
  }

  function setSpeechVoiceOptions(voices = [], catalog = voiceCatalog) {
    const select = elements["speech-voice"];
    const selected = speechVoiceName || select.value || "";
    clearChildren(select);
    const standard = document.createElement("option");
    standard.value = "";
    standard.textContent = "Standard";
    select.append(standard);
    const seen = new Set();
    let resolvedSelected = selected;
    for (const voice of sherpaSpeechVoices(voices, catalog)) {
      const name = String(voice?.name || voice?.id || "").trim();
      const id = String(voice?.id || name).trim();
      if (!id || seen.has(id)) continue;
      seen.add(id);
      const option = document.createElement("option");
      option.value = id;
      option.dataset.installed = String(Boolean(voice.installed));
      option.textContent = `${name}${voice?.culture ? ` (${voice.culture})` : ""}${voice.installed ? "" : " · installieren"}`;
      select.append(option);
      if (selected === name) resolvedSelected = id;
    }
    if ((voices.length || catalog.length) && resolvedSelected && !seen.has(resolvedSelected)) {
      speechVoiceName = "";
      send("TLC_SET_SPEECH_PREFERENCE", { voiceName: "" }).catch(() => {});
    }
    select.value = seen.has(resolvedSelected) ? resolvedSelected : "";
  }

  async function loadSpeechVoices() {
    try {
      const response = await fetch(`${serviceUrl}/v1/voices`, { headers: serviceHeaders() });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const payload = await response.json();
      voiceCatalog = payload.catalog || [];
      setSpeechVoiceOptions(payload.voices || [], voiceCatalog);
    } catch (_) {
      voiceCatalog = [];
      setSpeechVoiceOptions([]);
    }
  }

  async function installSpeechVoice(voiceId) {
    const entry = voiceCatalog.find((voice) => String(voice.id || "") === voiceId);
    if (!entry || entry.installed) return false;
    elements["speech-voice"].disabled = true;
    elements["service-status"].textContent = `${entry.name || voiceId} wird installiert …`;
    try {
      const response = await fetch(`${serviceUrl}/v1/voices/install`, {
        method: "POST",
        headers: { ...serviceHeaders(), "Content-Type": "application/json" },
        body: JSON.stringify({ voiceId })
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      elements["service-status"].textContent = `${entry.name || voiceId} wird im Hintergrund installiert.`;
      for (let attempt = 0; attempt < 12; attempt += 1) {
        await new Promise((resolve) => setTimeout(resolve, 5000));
        await loadSpeechVoices();
        const current = voiceCatalog.find((voice) => String(voice.id || "") === voiceId);
        if (current?.installed) {
          elements["service-status"].textContent = `Sprachdienst aktiv! ${current.name || voiceId} ist installiert.`;
          return true;
        }
      }
      elements["service-status"].textContent = "Installation läuft weiter; die Stimme erscheint nach Abschluss oder beim nächsten Öffnen.";
      return true;
    } catch (error) {
      elements["service-status"].textContent = `Stimme konnte nicht installiert werden: ${String(error?.message || error)}`;
      return false;
    } finally {
      elements["speech-voice"].disabled = false;
    }
  }

  async function installSherpaVoices(manual = false) {
    if (!pairingCode || sherpaInstallStarted) return false;
    sherpaInstallStarted = true;
    elements["sherpa-action"].disabled = true;
    elements["service-status"].textContent = manual ? "Sherpa-ONNX wird installiert …" : "Sherpa-ONNX fehlt; Installation läuft im Hintergrund …";
    try {
      const response = await fetch(`${serviceUrl}/v1/sherpa/install`, { method: "POST", headers: serviceHeaders() });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const payload = await response.json();
      elements["service-status"].textContent = payload.running
        ? "Sherpa-ONNX wird im Hintergrund installiert; Stimmen erscheinen nach Abschluss oder beim nächsten Öffnen."
        : "Sherpa-ONNX ist bereits installiert.";
      return true;
    } catch (error) {
      const message = String(error?.message || error);
      elements["service-status"].textContent = message.includes("HTTP 404")
        ? "Sherpa-Endpunkt fehlt: lokaler Dienst ist veraltet; bitte setup.ps1 aus dem aktuellen 0.7.1-Paket ausführen."
        : `Sherpa-Installation konnte nicht gestartet werden: ${message}`;
      return false;
    } finally {
      setTimeout(() => {
        sherpaInstallStarted = false;
        elements["sherpa-action"].disabled = false;
        loadSpeechVoices().catch(() => {});
      }, 5000);
    }
  }

  async function speakItem(item) {
    const text = speechText(item);
    if (!text) return;
    const lang = speechLang(item, text);
    try { await serviceSpeech(text, lang); }
    catch (_) { await browserSpeech(text, lang); }
  }

  async function pumpSpeech() {
    if (!speechEnabled || speechBusy || !speechQueue.length) return;
    const item = speechQueue.shift();
    speechBusy = true;
    try { await speakItem(item); }
    catch (error) { elements["speech-status"].textContent = `Vorlesen fehlgeschlagen: ${String(error?.message || error)}`; }
    finally {
      speechBusy = false;
      if (speechEnabled && !speechQueue.length) elements["speech-status"].textContent = "Vorlesen ist aktiv; warte auf neue Chatzeilen.";
      pumpSpeech();
    }
  }

  function enqueueSpeech(item) {
    if (!speechEnabled) return;
    if (speechQueue.length >= 5) speechQueue.shift();
    speechQueue.push(item);
    elements["speech-status"].textContent = speechQueue.length ? `Vorlesen aktiv · ${speechQueue.length} Zeile(n) vorgemerkt.` : "Vorlesen ist aktiv.";
    pumpSpeech();
  }

  function processSpeechItems(items) {
    if (!speechInitialized) {
      for (const item of items || []) knownSpeechKeys.add(chatKey(item));
      speechInitialized = true;
      return;
    }
    const allItems = items || [];
    for (const item of allItems) {
      const key = chatKey(item);
      if (knownSpeechKeys.has(key)) continue;
      knownSpeechKeys.add(key);
      if (item.muted) continue;
      if (gameModeEnabled && core.shouldFilterGameModeSpeech(item, currentState?.participants || {}, allItems)) continue;
      if (shouldSkipRecentSpeech(item)) continue;
      enqueueSpeech(item);
    }
  }

  function renderChat(items, allowSpeech = true) {
    const recent = (items || []).slice(-5);
    elements["chat-count"].textContent = String(items?.length || 0);
    const latestAt = Date.parse(items?.at(-1)?.receivedAtUtc || "") || 0;
    const chatActive = Boolean(items?.length && Date.now() - latestAt < 2 * 60 * 1000);
    setLed(elements["chat-led"], chatActive, "Chat empfängt Nachrichten", "Keine aktuellen Chatnachrichten");
    const currentNodes = new Map([...elements["chat-list"].querySelectorAll("[data-chat-key]")].map((node) => [node.dataset.chatKey, node]));
    const wantedKeys = new Set(recent.map(chatKey));
    for (const [key, node] of currentNodes) {
      if (!wantedKeys.has(key)) node.remove();
    }
    if (!recent.length) {
      clearChildren(elements["chat-list"]);
      elements["chat-list"].classList.add("empty");
      elements["chat-list"].textContent = "Noch keine Chatnachrichten erkannt.";
    } else {
      if (elements["chat-list"].classList.contains("empty")) clearChildren(elements["chat-list"]);
      elements["chat-list"].classList.remove("empty");
      for (const item of recent) {
        const key = chatKey(item);
        let row = elements["chat-list"].querySelector(`[data-chat-key="${CSS.escape(key)}"]`);
        if (!row) {
          row = document.createElement("p");
          row.className = "chat-line";
          row.dataset.chatKey = key;
          const author = document.createElement("span");
          author.className = "chat-author";
          author.textContent = `${item.author || "Chat"}: `;
          const content = document.createElement("span");
          content.textContent = item.content || "";
          row.append(author, content);
          elements["chat-list"].append(row);
        } else {
          elements["chat-list"].append(row);
        }
      }
    }

    if (allowSpeech) processSpeechItems(items);
  }

  function sortedParticipants(state = currentState) {
    return core.sortParticipants(Object.values(state?.participants || {}));
  }

  function muteScope(participant, state = currentState) {
    if (permanentMutes.has(participant.key)) return "permanent";
    if ((state?.streamMutes || []).includes(participant.key)) return "stream";
    return "active";
  }

  async function setMute(participantKey, scope) {
    const response = await send("TLC_SET_MUTE", { participantKey, scope });
    permanentMutes = new Set(response.settings?.permanentMutes || []);
    if (response.state) render(response.state);
  }

  function renderTopChatters(state) {
    const items = sortedParticipants(state).slice(0, 5);
    clearChildren(elements["top-chatters"]);
    elements["top-chatters"].classList.toggle("empty", !items.length);
    elements["team-tag-status"].textContent = state.stream?.teamTag
      ? `Teamkürzel erkannt: ${state.stream.teamTag}`
      : "Teamkürzel: noch nicht sicher erkannt.";
    if (!items.length) {
      elements["top-chatters"].textContent = "Noch keine Personen im Chat beobachtet.";
      return;
    }
    for (const participant of items) {
      const row = document.createElement("div");
      row.className = "chatter-row";
      const name = document.createElement("span");
      name.className = "chatter-name";
      name.textContent = participant.name;
      name.title = participant.name;
      const metrics = document.createElement("span");
      metrics.className = "chatter-metrics";
      metrics.textContent = `${participant.messageCount} N · ${participant.wordCount} W`;
      const label = document.createElement("label");
      label.className = "mute-toggle";
      const checkbox = document.createElement("input");
      checkbox.type = "checkbox";
      checkbox.checked = muteScope(participant, state) !== "active";
      checkbox.addEventListener("change", () => setMute(participant.key, checkbox.checked ? "stream" : "active").catch((error) => { elements.notice.textContent = String(error); }));
      label.append(checkbox, document.createTextNode("stumm"));
      row.append(name, metrics, label);
      elements["top-chatters"].append(row);
    }
  }

  function renderAudience(state = currentState) {
    clearChildren(elements["audience-list"]);
    const participants = sortedParticipants(state);
    elements["audience-limit"].textContent = state?.participantsTruncated
      ? "Grenze von 5.000 Personen erreicht; weitere neue Namen werden nicht aufgenommen."
      : `${participants.length} Person(en) während dieses Streams beobachtet.`;
    if (!participants.length) {
      elements["audience-list"].textContent = "Noch keine Personen beobachtet.";
      return;
    }
    for (const participant of participants) {
      const row = document.createElement("article");
      row.className = "audience-row";
      const head = document.createElement("div");
      head.className = "audience-row-head";
      const name = document.createElement("strong");
      name.textContent = participant.name;
      const select = document.createElement("select");
      select.setAttribute("aria-label", `Mute-Modus für ${participant.name}`);
      for (const [value, label] of [["active", "Aktiv"], ["stream", "Stream stumm"], ["permanent", "Dauerhaft stumm"]]) {
        const option = document.createElement("option");
        option.value = value;
        option.textContent = label;
        select.append(option);
      }
      select.value = muteScope(participant, state);
      select.addEventListener("change", () => setMute(participant.key, select.value).then(() => renderAudience()).catch((error) => { elements.notice.textContent = String(error); }));
      head.append(name, select);
      const metrics = document.createElement("div");
      metrics.className = "audience-metrics";
      const lastSeen = participant.lastSeenAtUtc ? new Date(participant.lastSeenAtUtc).toLocaleTimeString() : "–";
      metrics.textContent = `${participant.messageCount} Nachrichten · ${participant.wordCount} Wörter · ${participant.giftEventCount} Geschenkereignisse · ${participant.giftItemCount} gesendet · zuletzt ${lastSeen}`;
      row.append(head, metrics);
      elements["audience-list"].append(row);
    }
  }

  function renderStatuses(state) {
    clearChildren(elements["caption-status"]);
    const info = state.captionInfo || {};
    const observedCaptions = Boolean(state.captions?.length || info.observed);
    const sourceLabel = info.source === "dom" ? "Playertext" : observedCaptions ? "Datenstrom" : info.present ? "Seitenmetadaten" : "nicht gefunden";
    elements["caption-status"].append(
      statusCard("Untertitelquelle", sourceLabel, info.present || observedCaptions ? "good" : "bad"),
      statusCard("TikTok-Menü", state.menuCaptionActive ? "aktiv" : state.menuCaptionAvailable ? "verfügbar" : "nicht gefunden", state.menuCaptionActive ? "good" : state.menuCaptionAvailable ? "warn" : "bad"),
      statusCard("Sprachen", info.supportLang?.length ? info.supportLang.join(", ") : "keine Angabe", info.supportLang?.length ? "good" : "warn"),
      statusCard("Messages", String(state.captions?.length || 0), state.captions?.length ? "good" : "warn")
    );
  }

  function renderLiveStats(state) {
    const stats = state.liveStats || {};
    const hasData = stats.lastUpdatedUtc != null;
    clearChildren(elements["live-stats"]);
    elements["live-stats"].append(
      statusCard("Zuschauer*innen", formatCount(stats.viewerCount), stats.viewerCount != null ? "good" : "warn"),
      statusCard("Aufrufe gesamt", formatCount(stats.totalViewers), stats.totalViewers != null ? "good" : "warn"),
      statusCard("Likes", formatCount(stats.likeCount), stats.likeCount != null ? "good" : "warn"),
      statusCard("Follows seit Hook", formatCount(stats.followEvents || 0), hasData ? "good" : "warn"),
      statusCard("Teilungen", formatCount(stats.shareCount ?? stats.shareEvents ?? 0), hasData ? "good" : "warn"),
      statusCard("Follower gesamt", formatCount(stats.followerCount ?? state.profileInfo?.followerCount), (stats.followerCount ?? state.profileInfo?.followerCount) != null ? "good" : "warn")
    );
    elements["stats-live"].textContent = hasData ? "Datenstrom" : "warte";
    elements["stats-live"].classList.toggle("active", hasData);
    elements["stats-status"].textContent = hasData
      ? `Letzte Statistik: ${new Date(stats.lastUpdatedUtc).toLocaleTimeString()}`
      : "Noch keine Statistiknachricht empfangen. Hook setzen und den Tab neu laden.";
  }

  function renderPlayer(playerState = {}) {
    const available = booleanValue(playerState.available);
    const videoAvailable = booleanValue(playerState.videoAvailable ?? playerState.available);
    const playing = booleanValue(playerState.playing);
    const muted = booleanValue(playerState.muted);
    const pipActive = booleanValue(playerState.pipActive);
    const fullscreenActive = booleanValue(playerState.fullscreenActive);
    const limiterEnabled = booleanValue(playerState.limiterEnabled);
    const multiGuest = booleanValue(playerState.multiGuest);
    elements["player-time"].textContent = playerState.elapsedText || "–";
    elements["player-play"].textContent = playing ? "Pause" : "Abspielen";
    elements["player-mute"].textContent = muted ? "Ton an" : "Stumm";
    elements["player-pip"].textContent = pipActive ? "PiP beenden" : "Bild-in-Bild";
    elements["player-fullscreen"].textContent = fullscreenActive ? "Vollbild beenden" : "Vollbild";
    const volumePercent = Number.isFinite(Number(playerState.volumePercent)) ? Number(playerState.volumePercent) : 100;
    elements["player-volume"].value = String(volumePercent);
    elements["player-volume-output"].textContent = `${volumePercent}%`;
    const peakPercent = Number.isFinite(Number(playerState.peakDbfs))
      ? Math.max(0, Math.min(100, Math.round(Math.pow(10, Number(playerState.peakDbfs) / 20) * 100)))
      : null;
    elements["player-peak"].textContent = peakPercent == null ? "–" : `${peakPercent}%`;
    elements["limiter-enabled"].checked = limiterEnabled;
    const limiterStrength = Number.isFinite(Number(playerState.limiterStrength)) ? Number(playerState.limiterStrength) : 30;
    elements["limiter-strength"].value = String(limiterStrength);
    elements["limiter-strength-output"].textContent = `${limiterStrength}%`;
    elements["multi-guest-status"].textContent = multiGuest
      ? `Verbundene Streams: ${playerState.connectedStreams || "mehrere"} · Mehrgast-Modus erkannt.`
      : `Verbundene Streams: ${playerState.connectedStreams || (available ? 1 : 0)}.`;
    for (const id of PLAYER_BUTTONS) elements[id].disabled = !videoAvailable;
    elements["player-play"].disabled = !activeIsTikTok;
    elements["player-vlc-frame"].disabled = !activeIsTikTok || !(currentState?.media || []).some((item) => item?.url && !item.audioOnly);
    for (const id of ["player-volume", "limiter-enabled", "limiter-strength"]) elements[id].disabled = !videoAvailable;
    elements["player-status"].textContent = available
      ? `${playing ? "Wiedergabe läuft" : "Wiedergabe pausiert"} · ${muted ? "stumm" : "Ton aktiv"}${limiterEnabled ? ` · Pegelschutz ${limiterStrength}%` : ""}.`
      : "Warte auf den TikTok-Player.";
  }

  function audienceSelectActive() {
    return !elements["audience-modal"].hidden
      && document.activeElement?.tagName === "SELECT"
      && elements["audience-modal"].contains(document.activeElement);
  }

  function profileStat(value, label) {
    const card = document.createElement("div");
    card.className = "profile-stat";
    const number = document.createElement("strong");
    number.textContent = formatCount(value);
    const caption = document.createElement("span");
    caption.textContent = label;
    card.append(number, caption);
    return card;
  }

  function renderPageInfo(state) {
    const profile = state.profileInfo || {};
    const summary = state.aiSummaryInfo || {};
    const visible = Boolean(profile.present || summary.featureFlagPresent || summary.text);
    let livePageUrl = false;
    try {
      const path = decodeURIComponent(new URL(state.page?.url || "").pathname);
      livePageUrl = /^\/@[^/]+\/live\/?$/i.test(path) || /^\/embed\/live\/@?[^/?#]+\/?$/i.test(path);
    } catch (_) { livePageUrl = false; }
    elements["page-info-section"].hidden = false;
    elements["page-info-source"].textContent = profile.source || summary.source || "Diagnose";
    elements["profile-info"].hidden = !profile.present;
    clearChildren(elements["profile-info"]);
    if (profile.present) {
      const title = document.createElement("p");
      title.className = "profile-heading";
      title.textContent = `${profile.nickname || profile.uniqueId || "TikTok-Profil"}${profile.live ? " · LIVE" : ""}`;
      const handle = document.createElement("p");
      handle.className = "profile-handle";
      handle.textContent = profile.uniqueId ? `@${profile.uniqueId}` : "";
      const stats = document.createElement("div");
      stats.className = "profile-stats";
      stats.append(profileStat(profile.followingCount, "Gefolgt"), profileStat(profile.followerCount, "Follower"), profileStat(profile.likeCount, "Likes"));
      elements["profile-info"].append(title, handle, stats);
      if (profile.verified) {
        const verified = document.createElement("p");
        verified.className = "profile-bio";
        verified.textContent = profile.verifiedLabel || "Zertifiziert";
        elements["profile-info"].append(verified);
      }
      if (profile.livePro && livePageUrl) {
        const livePro = document.createElement("p");
        livePro.className = "profile-bio";
        livePro.textContent = profile.liveProLabel || "Live Pro";
        elements["profile-info"].append(livePro);
      }
      if (profile.sponsoredContent && livePageUrl) {
        const sponsored = document.createElement("p");
        sponsored.className = "profile-bio";
        sponsored.textContent = profile.sponsoredContentLabel || "Werbeinhalt";
        elements["profile-info"].append(sponsored);
      }
      if (profile.paidPartnership && livePageUrl) {
        const partnership = document.createElement("p");
        partnership.className = "profile-bio";
        partnership.textContent = profile.paidPartnershipLabel || "Bezahlte Partnerschaft";
        elements["profile-info"].append(partnership);
      }
      if (profile.signature) {
        const bio = document.createElement("p");
        bio.className = "profile-bio";
        bio.textContent = profile.signature;
        elements["profile-info"].append(bio);
      }
    }
    clearChildren(elements["summary-info"]);
    if (!visible) {
      elements["summary-info"].textContent = "Noch keine Profil- oder Zusammenfassungsinformationen gefunden.";
      return;
    }
    const summaryLabel = document.createElement("strong");
    summaryLabel.textContent = "KI-Zusammenfassung: ";
    const summaryStatus = document.createElement("span");
    summaryStatus.textContent = summary.text
      ? "Text gefunden"
      : summary.overviewCardFound ? "LIVE-Übersichtskarte gefunden, kein Summary-Text"
      : summary.featureFlagPresent ? "Feature-Schalter vorhanden, kein Text" : "nicht angekündigt";
    elements["summary-info"].append(summaryLabel, summaryStatus);
    if (summary.text) {
      const text = document.createElement("p");
      text.className = "summary-text";
      text.textContent = summary.text;
      elements["summary-info"].append(text);
    }
  }

  function renderMedia(items) {
    elements["media-count"].textContent = String(items.length);
    clearChildren(elements["media-list"]);
    elements["media-list"].classList.toggle("empty", !items.length);
    if (!items.length) {
      elements["media-list"].textContent = "Noch keine FLV-/HLS-Links erkannt.";
      return;
    }
    for (const item of items) {
      const row = document.createElement("article");
      row.className = "item";
      const head = document.createElement("div");
      head.className = "item-head";
      const title = document.createElement("div");
      title.className = "item-title";
      title.textContent = `${item.quality} · ${item.protocol}${item.audioOnly ? " · Audio" : ""}`;
      const copy = document.createElement("button");
      copy.className = "secondary copy";
      copy.textContent = "Kopieren";
      copy.addEventListener("click", async () => {
        await navigator.clipboard.writeText(item.url);
        copy.textContent = "Kopiert";
        setTimeout(() => { copy.textContent = "Kopieren"; }, 1200);
      });
      head.append(title, copy);
      const meta = document.createElement("div");
      meta.className = "item-meta";
      meta.textContent = `${item.source || "unbekannt"} · ${item.hostname}`;
      const url = document.createElement("div");
      url.className = "item-url";
      url.textContent = item.url;
      row.append(head, meta, url);
      elements["media-list"].append(row);
    }
  }

  function renderCaptions(items) {
    elements["caption-count"].textContent = String(items.length);
    clearChildren(elements["caption-list"]);
    elements["caption-list"].classList.toggle("empty", !items.length);
    if (!items.length) {
      elements["caption-list"].textContent = "Noch keine CaptionMessages empfangen.";
      return;
    }
    for (const item of items.slice(-100).reverse()) {
      const row = document.createElement("article");
      row.className = "item";
      const meta = document.createElement("div");
      meta.className = "caption-meta";
      const time = item.receivedAtUtc ? new Date(item.receivedAtUtc).toLocaleTimeString() : "–";
      meta.textContent = `${time} · Satz ${item.sentenceId || "–"} · ${item.definite ? "final" : "vorläufig"}`;
      const body = document.createElement("p");
      body.className = "caption-text";
      body.textContent = (item.contents || []).map((content) => `${content.lang || "?"}: ${content.text}`).join("\n") || "(leere Caption)";
      row.append(meta, body);
      elements["caption-list"].append(row);
    }
  }

  function render(state) {
    currentState = state;
    const tabSpeechEnabled = Boolean(state.speech?.enabled);
    if (tabSpeechEnabled) {
      speechEnabled = true;
      speechTabId = activeTabId;
      elements["toggle-speech"].textContent = "Vorlesen aus";
      elements["toggle-speech"].setAttribute("aria-pressed", "true");
      setLed(elements["speech-led"], true, "Vorlesen aktiv", "Vorlesen inaktiv");
      elements["speech-status"].textContent = state.speech?.status || "Vorlesen ist aktiv; warte auf neue Chatzeilen.";
    } else {
      speechEnabled = false;
      speechTabId = null;
      elements["toggle-speech"].textContent = "Vorlesen an";
      elements["toggle-speech"].setAttribute("aria-pressed", "false");
      setLed(elements["speech-led"], false, "Vorlesen aktiv", "Vorlesen inaktiv");
      elements["speech-status"].textContent = state.speech?.status || "Vorlesen ist ausgeschaltet.";
    }
    elements["page-title"].textContent = state.page?.title || state.page?.url || "TikTok LIVE";
    renderChat(state.chatMessages || [], false);
    renderTopChatters(state);
    if (!elements["audience-modal"].hidden && !audienceSelectActive()) renderAudience(state);
    renderStatuses(state);
    renderLiveStats(state);
    renderPlayer(state.playerState || {});
    renderPageInfo(state);
    renderMedia(state.media || []);
    renderCaptions(state.captions || []);
    elements["debug-enabled"].checked = Boolean(state.debug?.enabled);
    elements["debug-count"].textContent = String(state.debug?.entries?.length || 0);
    const hook = state.hook || {};
    setLed(elements["hook-led"], Boolean(hook.connected || hook.installed), "Hook aktiv", "Hook inaktiv");
    elements["hook-status"].textContent = hook.lastError
      ? `Fehler: ${hook.lastError}`
      : hook.connected ? "Hook aktiv, WebSocket verbunden."
      : hook.installed ? "Hook installiert; warte auf WebSocket."
      : hook.armed ? "Hook wartet auf den nächsten TikTok-Ladevorgang."
      : "Hook ist nicht aktiviert.";
    elements["hook-autostart"].checked = Boolean(hook.armed);
  }

  async function refresh() {
    const tab = await activeTab();
    const nextTabId = tab?.id ?? null;
    if (activeTabId != null && activeTabId !== nextTabId && speechEnabled && !keepSpeechActive) {
      await persistSpeechEnabled(false, activeTabId);
      stopSpeech("Vorlesen wurde wegen des Tabwechsels ausgeschaltet.", false, activeTabId);
      speechInitialized = false;
      knownSpeechKeys.clear();
    }
    activeTabId = nextTabId;
    previousTabId = activeTabId;
    const isTikTok = tab?.url?.startsWith("https://www.tiktok.com/");
    activeIsTikTok = Boolean(isTikTok);
    for (const id of ["scan", "enable-captions", "enable-hook", "disable-hook", "reset-tab", "open-embed-live", "open-normal-live", "clear", "refresh-chat", "refresh-page-info", "force-page-info", "player-vlc-frame", ...PLAYER_BUTTONS]) {
      elements[id].disabled = !isTikTok;
    }
    elements["enable-hook"].disabled = false;
    elements["disable-hook"].disabled = false;
    const settingsResponse = await send("TLC_GET_SETTINGS");
    elements["hook-autostart"].checked = Boolean(settingsResponse.settings?.hookEnabled || settingsResponse.settings?.autoHook);
    elements["quick-recover"].checked = Boolean(settingsResponse.settings?.quickRecoverEnabled);
    elements["debug-enabled"].checked = Boolean(settingsResponse.settings?.debugEnabled);
    if (!isTikTok) {
      elements["page-title"].textContent = "TikTok LIVE Companion";
      elements.notice.textContent = "";
      return;
    }
    elements.notice.textContent = "";
    await send("TLC_ACTIVATE_TAB");
    const response = await send("TLC_GET_STATE");
    elements["quick-recover"].checked = Boolean(settingsResponse.settings?.quickRecoverEnabled);
    render(response.state);
  }

  async function loadSettings() {
    const response = await send("TLC_GET_SETTINGS");
    keepSpeechActive = Boolean(response.settings?.keepSpeechActive);
    speechVolume = Math.max(0, Math.min(1, Number(response.settings?.speechVolume ?? 0.5)));
    speechLanguage = response.settings?.speechLanguage || "auto";
    speechVoiceName = response.settings?.speechVoiceName || "";
    speakNames = response.settings?.speakNames !== false;
    gameModeEnabled = Boolean(response.settings?.gameModeEnabled);
    shortenNames = Boolean(response.settings?.shortenNames);
    serviceUrl = DEFAULT_SERVICE_URL;
    pairingCode = response.settings?.pairingCode || "";
    auddApiToken = response.settings?.auddApiToken || "";
    permanentMutes = new Set(response.settings?.permanentMutes || []);
    elements["keep-speech-active"].checked = keepSpeechActive;
    elements["speech-volume"].value = String(Math.round(speechVolume * 100));
    elements["speech-volume-output"].textContent = `${Math.round(speechVolume * 100)}%`;
    elements["speech-language"].value = speechLanguage;
    setSpeechVoiceOptions();
    elements["speak-names"].checked = speakNames;
    elements["game-mode"].checked = gameModeEnabled;
    elements["shorten-names"].checked = shortenNames;
    elements["shorten-names"].disabled = !speakNames;
    elements["audd-token"].value = auddApiToken;
    elements["pairing-code"].value = pairingCode;
    elements["song-enabled"].checked = Boolean(response.settings?.songRecognitionEnabled);
    elements["recognize-song"].disabled = !elements["song-enabled"].checked;
    setLed(elements["song-led"], elements["song-enabled"].checked, "Songerkennung aktiviert", "Songerkennung inaktiv");
    await checkService();
    await loadSpeechVoices();
    if (currentState?.speech?.enabled) activateSpeech(currentState.speech.status || "Vorlesen ist aktiv; neue Chatzeilen werden vorgelesen.", false);
  }

  async function checkService() {
    try {
      const response = await fetch(`${serviceUrl}/v1/health`, { headers: serviceHeaders() });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const health = await response.json();
      elements["service-status"].textContent = `Lokaler Dienst bereit · ${health.tts || "Standard"}${health.auddConfigured ? " · AudD bereit" : " · AudD-Token fehlt"}.`;
      elements["service-action"].textContent = "Sprachdienst aktiv!";
      elements["service-action"].disabled = false;
      elements["sherpa-action"].textContent = health.sherpaConfigured ? "Sherpa aktiv!" : "Sherpa installieren";
      elements["sherpa-action"].disabled = Boolean(health.sherpaConfigured);
      await loadSpeechVoices();
      if (!Object.prototype.hasOwnProperty.call(health, "canInstallSherpa")) {
        elements["service-status"].textContent = "Lokaler Dienst ist veraltet; bitte setup.ps1 aus dem aktuellen 0.7.1-Paket ausführen.";
        return health;
      }
      if (!health.sherpaConfigured && health.canInstallSherpa) installSherpaVoices(false).catch(() => {});
      return health;
    } catch (_) {
      elements["service-status"].textContent = "Lokaler Dienst nicht erreichbar; Vorlesen nutzt den Browser-Fallback.";
      elements["service-action"].textContent = "Sprachdienst starten";
      elements["service-action"].disabled = false;
      elements["sherpa-action"].textContent = "Sherpa installieren";
      elements["sherpa-action"].disabled = false;
      return null;
    }
  }

  async function refreshPlayer() {
    if (!Number.isInteger(activeTabId)) return;
    try {
      const response = await send("TLC_GET_PLAYER_STATE");
      if (response.response?.playerState) renderPlayer(response.response.playerState);
    } catch (_) { /* The content script may briefly be unavailable during reload. */ }
  }

  function setButtonBusy(button, busy, normalText, busyText) {
    button.disabled = busy;
    button.textContent = busy ? busyText : normalText;
  }

  async function run(type, successText, button = null) {
    elements.notice.textContent = "";
    if (button) setButtonBusy(button, true, button.dataset.normalText, button.dataset.busyText);
    try {
      const response = await send(type);
      if (type === "TLC_SCAN") {
        const result = response.response || {};
        const time = new Date().toLocaleTimeString();
        const captionInfo = result.captionInfo?.present ? "caption_info vorhanden" : "caption_info nicht gefunden";
        const control = result.captionControl ? "Schalter ja" : "Schalter nein";
        elements["caption-action-status"].textContent = `${time}: geprüft · ${captionInfo} · ${control} · ${result.mediaCount || 0} Medienlinks in der Seite`;
      } else if (type === "TLC_ENABLE_CAPTIONS" && response.response && !response.response.activated) {
        elements["caption-action-status"].textContent = response.response.reason || response.response.error || "Untertitel konnten nicht aktiviert werden.";
      } else if (type === "TLC_ENABLE_CAPTIONS" && response.response?.activated) {
        elements["caption-action-status"].textContent = response.response.alreadyActive ? "TikToks Untertitel waren bereits aktiviert." : "TikToks vorhandener Untertitelschalter wurde betätigt.";
      } else if (successText) {
        elements.notice.textContent = successText;
      }
      if (!response.reloading) await refresh();
    } catch (error) {
      elements.notice.textContent = String(error?.message || error);
    } finally {
      if (button) setButtonBusy(button, false, button.dataset.normalText, button.dataset.busyText);
    }
  }

  async function runPlayer(action, button, payload = {}) {
    const original = button.textContent;
    button.disabled = true;
    elements["player-status"].textContent = "Aktion wird ausgeführt …";
    try {
      const response = await send("TLC_PLAYER_ACTION", { action, ...payload });
      const result = response.response || {};
      if (result.playerState) renderPlayer(result.playerState);
      elements["player-status"].textContent = result.activated ? "Playeraktion ausgeführt." : result.reason || result.error || "Playeraktion fehlgeschlagen.";
    } catch (error) {
      elements["player-status"].textContent = String(error?.message || error);
    } finally {
      button.disabled = false;
      if (!currentState?.playerState?.available) button.textContent = original;
      await refreshPlayer();
    }
  }

  function captureCurrentTabAudio() {
    return new Promise((resolve, reject) => {
      chrome.tabCapture.capture({ audio: true, video: false }, (stream) => {
        const error = chrome.runtime.lastError;
        if (error || !stream) reject(new Error(error?.message || "Tab-Audio konnte nicht aufgenommen werden."));
        else resolve(stream);
      });
    });
  }

  async function recordSongSample() {
    const stream = await captureCurrentTabAudio();
    let monitorContext = null;
    try {
      monitorContext = new AudioContext();
      const monitorSource = monitorContext.createMediaStreamSource(stream);
      monitorSource.connect(monitorContext.destination);
      const mimeType = MediaRecorder.isTypeSupported("audio/webm;codecs=opus") ? "audio/webm;codecs=opus" : "audio/webm";
      const recorder = new MediaRecorder(stream, { mimeType });
      const chunks = [];
      recorder.ondataavailable = (event) => { if (event.data.size) chunks.push(event.data); };
      const stopped = new Promise((resolve) => { recorder.onstop = resolve; });
      recorder.start(1000);
      for (let remaining = 12; remaining > 0; remaining -= 1) {
        elements["song-status"].textContent = `Aufnahme läuft · noch ${remaining} Sekunden …`;
        await new Promise((resolve) => setTimeout(resolve, 1000));
      }
      recorder.stop();
      await stopped;
      return new Blob(chunks, { type: mimeType });
    } finally {
      stream.getTracks().forEach((track) => track.stop());
      await monitorContext?.close().catch(() => {});
    }
  }

  async function recognizeSong() {
    const button = elements["recognize-song"];
    button.disabled = true;
    elements["song-result"].hidden = true;
    try {
      const sample = await recordSongSample();
      elements["song-status"].textContent = "Audioausschnitt wird erkannt …";
      const response = await fetch(`${serviceUrl}/v1/recognize`, {
        method: "POST",
        headers: serviceHeaders({ "Content-Type": sample.type || "application/octet-stream" }),
        body: sample
      });
      const result = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(result.error || `Songerkennung HTTP ${response.status}`);
      if (!result.match) {
        elements["song-status"].textContent = "Kein passender Song erkannt.";
        return;
      }
      clearChildren(elements["song-result"]);
      const title = document.createElement("strong");
      title.textContent = result.title || "Unbekannter Titel";
      const artist = document.createElement("span");
      artist.textContent = result.artist || "Unbekannter Interpret";
      const album = document.createElement("span");
      album.textContent = result.album || "";
      elements["song-result"].append(title, artist, album);
      if (result.link) {
        const link = document.createElement("a");
        link.href = result.link;
        link.target = "_blank";
        link.rel = "noreferrer";
        link.textContent = "Song öffnen";
        elements["song-result"].append(link);
      }
      elements["song-result"].hidden = false;
      elements["song-status"].textContent = "Song erkannt; der Audioausschnitt wurde verworfen.";
    } catch (error) {
      elements["song-status"].textContent = String(error?.message || error);
    } finally {
      button.disabled = !elements["song-enabled"].checked;
    }
  }

  elements.scan.dataset.normalText = "Seite prüfen";
  elements.scan.dataset.busyText = "Prüfe …";
  elements["enable-captions"].dataset.normalText = "Untertitel aktivieren";
  elements["enable-captions"].dataset.busyText = "Suche Schalter …";
  elements.scan.addEventListener("click", () => run("TLC_SCAN", null, elements.scan));
  elements["enable-captions"].addEventListener("click", () => run("TLC_ENABLE_CAPTIONS", null, elements["enable-captions"]));
  elements["enable-hook"].addEventListener("click", () => run("TLC_ENABLE_HOOK", "Hook bleibt aktiv."));
  elements["disable-hook"].addEventListener("click", async () => {
    elements["hook-autostart"].checked = false;
    await run("TLC_DISABLE_HOOK", "Hook deaktiviert.");
  });
  elements["reset-tab"].addEventListener("click", () => {
    if (!keepSpeechActive) stopSpeech("Vorlesen wurde wegen des Refreshs ausgeschaltet.");
    else {
      speechQueue = [];
      globalThis.speechSynthesis?.cancel();
      elements["speech-status"].textContent = "Vorlesen bleibt aktiv und wartet nach dem Refresh auf neue Chatzeilen.";
    }
    run("TLC_RESET_TAB", "LIVE-Tab wird neu geladen.");
  });
  elements["open-embed-live"].addEventListener("click", () => run("TLC_OPEN_EMBED_LIVE", "Embed-LIVE wird geöffnet."));
  elements["open-normal-live"].addEventListener("click", () => run("TLC_OPEN_NORMAL_LIVE", "Normale LIVE-Seite wird geöffnet."));
  elements.clear.addEventListener("click", () => run("TLC_CLEAR"));
  elements["refresh-chat"].addEventListener("click", async () => {
    knownSpeechKeys.clear();
    speechInitialized = false;
    await run("TLC_CLEAR_CHAT", "Chatanzeige wurde geleert.");
  });
  elements["refresh-page-info"].addEventListener("click", async () => {
    const button = elements["refresh-page-info"];
    const original = button.textContent;
    button.disabled = true;
    button.textContent = "Prüfe …";
    elements["page-info-source"].textContent = "lädt";
    try {
      const response = await send("TLC_REFRESH_PAGE_INFO");
      elements.notice.textContent = response.response?.error || "Seiteninformationen wurden neu abgefragt.";
      await refresh();
    } catch (error) {
      elements.notice.textContent = String(error?.message || error);
    } finally {
      button.disabled = false;
      button.textContent = original;
    }
  });
  elements["force-page-info"].addEventListener("click", async () => {
    const button = elements["force-page-info"];
    button.disabled = true;
    button.textContent = "Force läuft …";
    elements.notice.textContent = "Profilseite wird vollständig geladen; der LIVE-Tab wird anschließend wiederhergestellt.";
    try {
      await send("TLC_FORCE_PROFILE");
      elements.notice.textContent = "Profilwerte wurden erzwungen; der LIVE-Stream wird wieder geladen.";
    } catch (error) {
      elements.notice.textContent = String(error?.message || error);
    } finally {
      button.disabled = false;
      button.textContent = "Force";
    }
  });
  elements["open-audience"].addEventListener("click", () => {
    renderAudience();
    elements["audience-modal"].hidden = false;
    elements["close-audience"].focus();
  });
  elements["close-audience"].addEventListener("click", () => {
    elements["audience-modal"].hidden = true;
    elements["open-audience"].focus();
  });
  elements["audience-modal"].addEventListener("click", (event) => {
    if (event.target === elements["audience-modal"]) elements["close-audience"].click();
  });
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && !elements["audience-modal"].hidden) elements["close-audience"].click();
    if (event.key === "Tab" && !elements["audience-modal"].hidden) {
      const focusable = [...elements["audience-modal"].querySelectorAll('button,select,[href],input:not([disabled])')];
      if (!focusable.length) return;
      const first = focusable[0];
      const last = focusable.at(-1);
      if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
      else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
    }
  });
  elements["keep-speech-active"].addEventListener("change", async () => {
    keepSpeechActive = elements["keep-speech-active"].checked;
    await send("TLC_SET_SPEECH_PREFERENCE", { enabled: keepSpeechActive });
    elements["speech-status"].textContent = keepSpeechActive
      ? "Dauerhaftes Vorlesen ist zugelassen; aktivieren Sie Vorlesen an."
      : speechEnabled ? "Vorlesen wird beim nächsten Tabwechsel beendet." : "Vorlesen ist ausgeschaltet.";
  });
  elements["hook-autostart"].addEventListener("change", async () => {
    const enabled = elements["hook-autostart"].checked;
    try {
      await send("TLC_SET_AUTOSTART", { enabled });
      elements.notice.textContent = enabled ? "Hook bleibt aktiv." : "Hook ist deaktiviert.";
    } catch (error) {
    elements.notice.textContent = String(error?.message || error);
      elements["hook-autostart"].checked = !enabled;
    }
  });
  elements["quick-recover"].addEventListener("change", async () => {
    const enabled = elements["quick-recover"].checked;
    try {
      await send("TLC_SET_QUICK_RECOVER", { enabled });
      elements.notice.textContent = enabled ? "Schnelle Unterbrechungsbehebung aktiv." : "Schnelle Unterbrechungsbehebung aus.";
    } catch (error) {
      elements.notice.textContent = String(error?.message || error);
      elements["quick-recover"].checked = !enabled;
    }
  });
  elements["toggle-speech"].addEventListener("click", () => {
    if (speechEnabled) {
      stopSpeech();
      return;
    }
    activateSpeech();
  });
  elements["speech-volume"].addEventListener("input", () => {
    elements["speech-volume-output"].textContent = `${elements["speech-volume"].value}%`;
  });
  elements["speech-volume"].addEventListener("change", async () => {
    speechVolume = Math.max(0, Math.min(1, Number(elements["speech-volume"].value) / 100));
    await send("TLC_SET_SPEECH_PREFERENCE", { volume: speechVolume });
  });
  elements["speech-language"].addEventListener("change", async () => {
    speechLanguage = elements["speech-language"].value;
    await send("TLC_SET_SPEECH_PREFERENCE", { language: speechLanguage });
  });
  elements["speech-voice"].addEventListener("change", async () => {
    speechVoiceName = elements["speech-voice"].value;
    await send("TLC_SET_SPEECH_PREFERENCE", { voiceName: speechVoiceName });
    await installSpeechVoice(speechVoiceName);
  });
  elements["speak-names"].addEventListener("change", async () => {
    speakNames = elements["speak-names"].checked;
    elements["shorten-names"].disabled = !speakNames;
    await send("TLC_SET_SPEECH_PREFERENCE", { speakNames });
  });
  elements["game-mode"].addEventListener("change", async () => {
    gameModeEnabled = elements["game-mode"].checked;
    await send("TLC_SET_SPEECH_PREFERENCE", { gameModeEnabled });
  });
  elements["shorten-names"].addEventListener("change", async () => {
    shortenNames = elements["shorten-names"].checked;
    await send("TLC_SET_SPEECH_PREFERENCE", { shortenNames });
  });
  const savePairingCode = async () => {
    pairingCode = elements["pairing-code"].value.trim();
    await send("TLC_SET_SPEECH_PREFERENCE", { pairingCode });
    await checkService();
    await loadSpeechVoices();
  };
  const saveAuddToken = async () => {
    const token = elements["audd-token"].value.trim();
    auddApiToken = token;
    await send("TLC_SET_SPEECH_PREFERENCE", { auddApiToken: token });
    if (!pairingCode) {
      elements["service-status"].textContent = token ? "AudD-Token lokal gespeichert; Pairing-Code fehlt für den Sprachdienst." : "AudD-Token geleert.";
      return;
    }
    try {
      const response = await fetch(`${serviceUrl}/v1/config/audd-token`, {
        method: "POST",
        headers: serviceHeaders({ "Content-Type": "application/json" }),
        body: JSON.stringify({ auddApiToken: token })
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      await checkService();
    } catch (error) {
      elements["service-status"].textContent = `AudD-Token konnte nicht gespeichert werden: ${String(error?.message || error)}`;
    }
  };
  elements["pairing-code"].addEventListener("change", savePairingCode);
  elements["audd-token"].addEventListener("change", saveAuddToken);
  elements["service-action"].addEventListener("click", async () => {
    const ready = await checkService();
    if (ready) {
      elements["service-status"].textContent = `Lokaler Dienst bereit · ${ready.tts || "Standard"}${ready.auddConfigured ? " · AudD bereit" : " · AudD-Token fehlt"}.`;
      return;
    }
    elements["service-status"].textContent = "Lokaler Sprachdienst wird im Hintergrund gestartet …";
    try {
      const startResult = await send("TLC_START_LOCAL_SERVICE");
      const setupCommand = String(startResult.setupCommand || "");
      elements["service-setup-command"].textContent = setupCommand;
      elements["service-setup"].dataset.setupCommand = setupCommand;
      if (startResult.pairingCode) {
        pairingCode = startResult.pairingCode;
        elements["pairing-code"].value = pairingCode;
        elements["service-setup"].hidden = true;
      }
      await new Promise((resolve) => setTimeout(resolve, 1200));
      const health = await checkService();
      if (health?.canInstallSherpa && !health.sherpaConfigured) await installSherpaVoices(false);
      if (!health) {
        elements["service-setup"].hidden = false;
        elements["service-status"].textContent = "Einmaliges Setup fehlt. PowerShell im Dienstordner öffnen, beide Befehle ausführen und danach erneut auf den Button klicken.";
      }
    } catch (error) {
      elements["service-status"].textContent = String(error?.message || error);
    }
  });
  elements["copy-service-setup"].addEventListener("click", async () => {
    const setupCommand = String(elements["service-setup"].dataset.setupCommand || "");
    if (!setupCommand) return;
    await navigator.clipboard.writeText(setupCommand);
    elements["copy-service-setup"].textContent = "Kopiert";
    setTimeout(() => { elements["copy-service-setup"].textContent = "Befehle kopieren"; }, 1200);
  });
  elements["sherpa-action"].addEventListener("click", () => installSherpaVoices(true));
  elements["song-enabled"].addEventListener("change", async () => {
    const enabled = elements["song-enabled"].checked;
    elements["recognize-song"].disabled = !enabled;
    setLed(elements["song-led"], enabled, "Songerkennung aktiviert", "Songerkennung inaktiv");
    elements["song-status"].textContent = enabled ? "Bereit für eine manuelle 12-Sekunden-Erkennung." : "";
    await send("TLC_SET_SPEECH_PREFERENCE", { songRecognitionEnabled: enabled });
  });
  elements["recognize-song"].addEventListener("click", recognizeSong);
  elements["player-play"].addEventListener("click", () => runPlayer("toggle-play", elements["player-play"]));
  elements["player-replay"].addEventListener("click", () => runPlayer("replay", elements["player-replay"]));
  elements["player-mute"].addEventListener("click", () => runPlayer("toggle-mute", elements["player-mute"]));
  elements["player-pip"].addEventListener("click", () => runPlayer("toggle-pip", elements["player-pip"]));
  elements["player-fullscreen"].addEventListener("click", () => runPlayer("toggle-fullscreen", elements["player-fullscreen"]));
  elements["player-report"].addEventListener("click", () => runPlayer("open-report", elements["player-report"]));
  elements["player-vlc-frame"].addEventListener("click", () => runPlayer("play-vlc-source", elements["player-vlc-frame"]));
  elements["player-volume"].addEventListener("input", () => {
    const value = Number(elements["player-volume"].value);
    elements["player-volume-output"].textContent = `${value}%`;
  });
  elements["player-volume"].addEventListener("change", () => runPlayer("set-volume", elements["player-mute"], { value: Number(elements["player-volume"].value) / 100 }));
  elements["limiter-strength"].addEventListener("input", () => {
    elements["limiter-strength-output"].textContent = `${elements["limiter-strength"].value}%`;
  });
  const applyLimiter = () => runPlayer("set-limiter", elements["limiter-enabled"], {
    enabled: elements["limiter-enabled"].checked,
    thresholdDbfs: core.limiterStrengthToDbfs(Number(elements["limiter-strength"].value))
  });
  elements["limiter-enabled"].addEventListener("change", applyLimiter);
  elements["limiter-strength"].addEventListener("change", () => {
    if (elements["limiter-enabled"].checked) applyLimiter();
  });
  elements["debug-enabled"].addEventListener("change", async () => {
    const response = await send("TLC_SET_DEBUG", { enabled: elements["debug-enabled"].checked });
    if (response.state) render(response.state);
  });
  elements["clear-debug"].addEventListener("click", async () => {
    await send("TLC_CLEAR_DEBUG");
    elements["debug-count"].textContent = "0";
    elements.notice.textContent = "Diagnoseprotokoll wurde geleert.";
  });
  elements["export-debug"].addEventListener("click", async () => {
    const response = await send("TLC_GET_DEBUG_REPORT");
    if (!response.report) {
      elements.notice.textContent = "Das Diagnoseprotokoll konnte nicht erstellt werden.";
      return;
    }
    const blob = new Blob([JSON.stringify(response.report, null, 2)], { type: "application/json" });
    const href = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = href;
    link.download = `tiktok-live-companion-debug-${new Date().toISOString().replace(/[:.]/g, "-")}.json`;
    link.click();
    URL.revokeObjectURL(href);
    elements.notice.textContent = "Diagnoseprotokoll wurde exportiert.";
  });
  elements["export-log"].addEventListener("click", () => {
    const records = currentState?.captions || [];
    if (!records.length) {
      elements.notice.textContent = "Es sind keine CaptionMessages zum Exportieren vorhanden.";
      return;
    }
    const payload = records.map((record) => JSON.stringify(record)).join("\n") + "\n";
    const link = document.createElement("a");
    link.href = URL.createObjectURL(new Blob([payload], { type: "application/x-ndjson" }));
    link.download = `tiktok-live-captions-${new Date().toISOString().replace(/[:.]/g, "-")}.jsonl`;
    link.click();
    setTimeout(() => URL.revokeObjectURL(link.href), 1000);
  });

  chrome.runtime.onMessage.addListener((message) => {
    if (message.type !== "TLC_STATE_UPDATED") return;
    if (message.tabId === activeTabId) render(message.state);
  });
  globalThis.speechSynthesis?.addEventListener?.("voiceschanged", () => loadSpeechVoices().catch(() => {}));
  chrome.tabs.onActivated.addListener(() => refresh().catch(() => {}));
  refresh().then(loadSettings).then(refreshPlayer).catch((error) => { elements.notice.textContent = String(error?.message || error); });
  setInterval(refreshPlayer, 1500);
  setInterval(() => refresh().catch(() => {}), 5000);
})();
