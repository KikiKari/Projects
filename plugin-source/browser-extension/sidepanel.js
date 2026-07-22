(function () {
  "use strict";

  const elements = Object.fromEntries([
    "page-title", "chat-list", "chat-count", "chat-led", "refresh-chat", "toggle-speech", "speech-led", "speech-status", "speech-volume", "speech-volume-output", "keep-speech-active",
    "speech-language", "speak-names", "shorten-names", "service-url", "pairing-code", "service-status",
    "top-chatters", "team-tag-status", "open-audience", "audience-modal", "close-audience", "audience-list", "audience-limit",
    "song-enabled", "song-led", "recognize-song", "song-status", "song-result",
    "caption-status", "hook-status", "hook-led", "hook-autostart", "media-list", "media-count", "caption-list", "caption-count",
    "notice", "caption-action-status", "live-stats", "stats-status", "stats-live",
    "player-time", "player-status", "player-play", "player-replay", "player-mute", "player-pip", "player-fullscreen", "player-report",
    "player-volume", "player-volume-output", "player-peak", "limiter-enabled", "limiter-threshold", "limiter-threshold-output", "multi-guest-status",
    "page-info-section", "page-info-source", "profile-info", "summary-info", "refresh-page-info", "force-page-info",
    "quality-list", "quality-count", "quality-action-status", "scan", "enable-captions",
    "enable-hook", "disable-hook", "reset-tab", "export-log", "clear", "debug-enabled", "debug-count", "export-debug", "clear-debug"
  ].map((id) => [id, document.getElementById(id)]));
  const PLAYER_BUTTONS = ["player-play", "player-replay", "player-mute", "player-pip", "player-fullscreen", "player-report"];
  const QUALITY_DISPLAY = Object.freeze({ auto: "Automatisch", origin: "Original", uhd_60: "1080p60", uhd: "1080p", hd_60: "720p60", hd: "720p", sd: "540p", ld: "360p" });
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
  let speakNames = true;
  let shortenNames = false;
  let serviceUrl = "http://127.0.0.1:43117";
  let pairingCode = "";
  let permanentMutes = new Set();
  let speechAudioContext = null;
  let speechAudioSource = null;
  const knownSpeechKeys = new Set();

  async function activeTab() {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    return tab;
  }

  async function send(type, payload = {}) {
    if (!Number.isInteger(activeTabId)) throw new Error("Kein aktiver Tab gefunden.");
    const response = await chrome.runtime.sendMessage({ type, tabId: activeTabId, ...payload });
    if (!response?.ok) throw new Error(response?.error || "Aktion fehlgeschlagen");
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

  function chatKey(item) {
    return String(item.messageId || item.dedupeKey || `${item.receivedAtUtc || ""}|${item.author || ""}|${item.content || ""}`);
  }

  function setLed(element, active, activeLabel, inactiveLabel) {
    element.classList.toggle("on", active);
    element.classList.toggle("off", !active);
    const label = active ? activeLabel : inactiveLabel;
    element.setAttribute("aria-label", label);
    element.title = label;
  }

  function formatDb(value, suffix = "dB") {
    if (value == null || !Number.isFinite(Number(value))) return `– ${suffix}`;
    return `${Number(value).toLocaleString("de-DE", { maximumFractionDigits: 1 })} ${suffix}`.replace("-", "−");
  }

  function stopSpeech(message = "Vorlesen ist ausgeschaltet.") {
    speechEnabled = false;
    speechBusy = false;
    speechQueue = [];
    speechTabId = null;
    globalThis.speechSynthesis?.cancel();
    try { speechAudioSource?.stop(); } catch (_) { /* Already stopped. */ }
    speechAudioSource = null;
    elements["toggle-speech"].textContent = "Vorlesen an";
    elements["toggle-speech"].setAttribute("aria-pressed", "false");
    setLed(elements["speech-led"], false, "Vorlesen aktiv", "Vorlesen inaktiv");
    elements["speech-status"].textContent = message;
  }

  function serviceHeaders(extra = {}) {
    return { "Authorization": `Bearer ${pairingCode}`, "X-TLC-Client": "sidepanel-0.7.0", ...extra };
  }

  function speechText(item) {
    return core.composeSpeechText(item, {
      teamTag: currentState?.stream?.teamTag || "",
      speakNames,
      shortenNames
    });
  }

  function speechLang(item) {
    return core.resolveSpeechLanguage(speechLanguage, item.contentLanguage);
  }

  async function browserSpeech(text, lang) {
    if (!globalThis.speechSynthesis || typeof SpeechSynthesisUtterance !== "function") throw new Error("Keine Browser-Sprachausgabe verfügbar.");
    await new Promise((resolve) => {
      const utterance = new SpeechSynthesisUtterance(text);
      if (lang) utterance.lang = lang;
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
      body: JSON.stringify({ text, language: lang || "auto" })
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

  async function speakItem(item) {
    const text = speechText(item);
    if (!text) return;
    const lang = speechLang(item);
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
    for (const item of items || []) {
      const key = chatKey(item);
      if (knownSpeechKeys.has(key)) continue;
      knownSpeechKeys.add(key);
      if (item.muted) continue;
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
      ? `Letzte Statistik: ${new Date(stats.lastUpdatedUtc).toLocaleTimeString()} · Follows werden ab Hook-Start gezählt.`
      : "Noch keine Statistiknachricht empfangen. Hook setzen und den Tab neu laden.";
  }

  function renderPlayer(playerState = {}) {
    const available = Boolean(playerState.available);
    elements["player-time"].textContent = playerState.elapsedText || "–";
    elements["player-play"].textContent = playerState.playing ? "Pause" : "Abspielen";
    elements["player-mute"].textContent = playerState.muted ? "Ton an" : "Stumm";
    elements["player-pip"].textContent = playerState.pipActive ? "PiP beenden" : "Bild-in-Bild";
    elements["player-fullscreen"].textContent = playerState.fullscreenActive ? "Vollbild beenden" : "Vollbild";
    const volumePercent = Number.isFinite(Number(playerState.volumePercent)) ? Number(playerState.volumePercent) : 100;
    elements["player-volume"].value = String(volumePercent);
    elements["player-volume-output"].textContent = `${volumePercent}% · ${formatDb(playerState.volumeGainDb)}`;
    elements["player-peak"].textContent = formatDb(playerState.peakDbfs, "dBFS");
    elements["limiter-enabled"].checked = Boolean(playerState.limiterEnabled);
    elements["limiter-threshold"].value = String(playerState.limiterThresholdDbfs ?? -6);
    elements["limiter-threshold-output"].textContent = formatDb(playerState.limiterThresholdDbfs ?? -6, "dBFS");
    elements["multi-guest-status"].textContent = playerState.multiGuest
      ? `Verbundene Streams: ${playerState.connectedStreams || "mehrere"} · Mehrgast-Modus erkannt.`
      : `Verbundene Streams: ${playerState.connectedStreams || (available ? 1 : 0)}.`;
    for (const id of PLAYER_BUTTONS) elements[id].disabled = !available;
    for (const id of ["player-volume", "limiter-enabled", "limiter-threshold"]) elements[id].disabled = !available;
    elements["player-status"].textContent = available
      ? `${playerState.playing ? "Wiedergabe läuft" : "Wiedergabe pausiert"} · ${playerState.muted ? "stumm" : "Ton aktiv"}${playerState.limiterEnabled ? ` · Pegelschutz ${formatDb(playerState.limiterThresholdDbfs, "dBFS")} (${playerState.limiterMode || "aktiv"})` : ""}.`
      : "Warte auf den TikTok-Player.";
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

  function qualityRank(item) {
    const order = ["auto", "origin", "uhd_60", "uhd", "hd_60", "hd", "sd", "ld"];
    const keyIndex = order.indexOf(item.sdkKey);
    if (keyIndex >= 0) return keyIndex;
    const match = String(item.quality || "").match(/(\d{3,4})p/);
    return match ? 10000 - Number(match[1]) : 20000;
  }

  function normalizedQuality(value) {
    return String(value || "").toLocaleLowerCase().replace(/\s+/g, "");
  }

  function renderQualities(items, selectedQuality, playerState) {
    const groups = new Map();
    for (const item of items.filter((entry) => !entry.audioOnly)) {
      const key = item.sdkKey || item.quality;
      if (!key || item.quality === "unbekannt") continue;
      const genericQuality = normalizedQuality(item.quality) === normalizedQuality(item.sdkKey) || /^(?:sd|hd|ld|uhd)$/i.test(String(item.quality || ""));
      const existing = groups.get(key) || { ...item, quality: genericQuality ? (QUALITY_DISPLAY[item.sdkKey] || item.quality) : item.quality, protocols: new Set() };
      existing.protocols.add(item.protocol);
      for (const detail of ["bitrate", "codec", "width", "height", "fps", "sdkKey", "quality"]) {
        if (item[detail] != null && detail !== "quality") existing[detail] = item[detail];
      }
      groups.set(key, existing);
    }
    const qualities = [...groups.values()];
    if ((qualities.length || playerState?.available) && !groups.has("auto")) qualities.push({ sdkKey: "auto", quality: "Automatisch", protocols: new Set(), synthetic: true });
    qualities.sort((a, b) => qualityRank(a) - qualityRank(b));
    elements["quality-count"].textContent = String(qualities.length);
    clearChildren(elements["quality-list"]);
    elements["quality-list"].classList.toggle("empty", !qualities.length);
    if (!qualities.length) {
      elements["quality-list"].textContent = "Noch keine Qualitätsstufen aus den Stream-Metadaten erkannt.";
      return;
    }
    for (const item of qualities) {
      const active = selectedQuality && normalizedQuality(selectedQuality) === normalizedQuality(item.quality);
      const row = document.createElement("article");
      row.className = `item${active ? " quality-active" : ""}`;
      const head = document.createElement("div");
      head.className = "item-head";
      const title = document.createElement("div");
      title.className = "item-title";
      title.textContent = item.quality;
      const choose = document.createElement("button");
      choose.className = active ? "ghost" : "secondary";
      choose.textContent = active ? "Ausgewählt" : "Im Player wählen";
      choose.disabled = Boolean(active);
      choose.addEventListener("click", async () => {
        choose.disabled = true;
        choose.textContent = "Wechsle …";
        try {
          const response = await send("TLC_SET_QUALITY", { quality: item.quality, sdkKey: item.sdkKey });
          const result = response.response || {};
          elements["quality-action-status"].textContent = result.activated
            ? result.verificationPending
              ? `${result.quality || item.quality} wurde im TikTok-Menü angeklickt; TikTok schloss das Menü vor der Bestätigung.`
              : `${result.quality || item.quality} ist ${result.alreadyActive ? "bereits aktiv" : "im TikTok-Player ausgewählt und bestätigt"}.`
            : result.reason || result.error || "Qualität konnte nicht gewechselt werden.";
          await refresh();
        } catch (error) {
          elements["quality-action-status"].textContent = String(error?.message || error);
        } finally {
          choose.disabled = false;
          choose.textContent = "Im Player wählen";
        }
      });
      head.append(title, choose);
      const details = document.createElement("div");
      details.className = "quality-details";
      if (item.synthetic) {
        details.textContent = "TikTok wählt die Qualität automatisch · kein eigener VLC-Link";
      } else {
        const parts = [[...item.protocols].join("/"), item.codec?.toUpperCase()];
        if (item.width && item.height) parts.push(`${item.width}×${item.height}`);
        if (item.fps) parts.push(`${item.fps} fps`);
        if (item.bitrate) parts.push(`${(item.bitrate / 1000000).toLocaleString("de-DE", { maximumFractionDigits: 2 })} Mbit/s`);
        details.textContent = parts.flat().filter(Boolean).join(" · ") || "Stream-Metadaten erkannt";
      }
      row.append(head, details);
      elements["quality-list"].append(row);
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
    elements["page-title"].textContent = state.page?.title || state.page?.url || "TikTok LIVE";
    renderChat(state.chatMessages || [], !speechEnabled || speechTabId === activeTabId);
    renderTopChatters(state);
    if (!elements["audience-modal"].hidden) renderAudience(state);
    renderStatuses(state);
    renderLiveStats(state);
    renderPlayer(state.playerState || {});
    renderPageInfo(state);
    renderQualities(state.media || [], state.selectedQuality, state.playerState);
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
      : hook.armed ? "Hook vorgemerkt; Tab wird neu geladen."
      : "Hook ist nicht aktiviert.";
  }

  async function refresh() {
    const tab = await activeTab();
    activeTabId = tab?.id ?? null;
    if (previousTabId != null && previousTabId !== activeTabId && speechEnabled && !keepSpeechActive) {
      stopSpeech("Vorlesen wurde wegen des Tabwechsels ausgeschaltet.");
      speechInitialized = false;
      knownSpeechKeys.clear();
    }
    previousTabId = activeTabId;
    const isTikTok = tab?.url?.startsWith("https://www.tiktok.com/");
    activeIsTikTok = Boolean(isTikTok);
    for (const id of ["scan", "enable-captions", "enable-hook", "disable-hook", "reset-tab", "clear", "refresh-chat", "refresh-page-info", "force-page-info", ...PLAYER_BUTTONS]) {
      elements[id].disabled = !isTikTok;
    }
    if (!isTikTok) {
      elements["page-title"].textContent = "Bitte einen TikTok-Tab aktivieren.";
      elements.notice.textContent = "Das Seitenpanel arbeitet nur auf https://www.tiktok.com/.";
      return;
    }
    elements.notice.textContent = "";
    const response = await send("TLC_GET_STATE");
    render(response.state);
  }

  async function loadSettings() {
    const response = await send("TLC_GET_SETTINGS");
    keepSpeechActive = Boolean(response.settings?.keepSpeechActive);
    speechVolume = Math.max(0, Math.min(1, Number(response.settings?.speechVolume ?? 0.5)));
    speechLanguage = response.settings?.speechLanguage || "auto";
    speakNames = response.settings?.speakNames !== false;
    shortenNames = Boolean(response.settings?.shortenNames);
    serviceUrl = response.settings?.serviceUrl || "http://127.0.0.1:43117";
    pairingCode = response.settings?.pairingCode || "";
    permanentMutes = new Set(response.settings?.permanentMutes || []);
    elements["keep-speech-active"].checked = keepSpeechActive;
    elements["speech-volume"].value = String(Math.round(speechVolume * 100));
    elements["speech-volume-output"].textContent = `${Math.round(speechVolume * 100)}%`;
    elements["speech-language"].value = speechLanguage;
    elements["speak-names"].checked = speakNames;
    elements["shorten-names"].checked = shortenNames;
    elements["shorten-names"].disabled = !speakNames;
    elements["service-url"].value = serviceUrl;
    elements["pairing-code"].value = pairingCode;
    elements["song-enabled"].checked = Boolean(response.settings?.songRecognitionEnabled);
    elements["recognize-song"].disabled = !elements["song-enabled"].checked;
    setLed(elements["song-led"], elements["song-enabled"].checked, "Songerkennung aktiviert", "Songerkennung inaktiv");
    elements["hook-autostart"].checked = Boolean(response.settings?.autoHook);
    await checkService();
  }

  async function checkService() {
    try {
      const response = await fetch(`${serviceUrl}/v1/health`, { headers: serviceHeaders() });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const health = await response.json();
      elements["service-status"].textContent = `Lokaler Dienst bereit · ${health.tts || "Windows-Stimmen"}${health.auddConfigured ? " · AudD bereit" : " · AudD-Token fehlt"}.`;
      return health;
    } catch (_) {
      elements["service-status"].textContent = "Lokaler Dienst nicht erreichbar; Vorlesen nutzt den Browser-Fallback.";
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
        const control = result.captionControl ? "Untertitelschalter gefunden" : "Untertitelschalter nicht gefunden";
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
  elements["enable-hook"].addEventListener("click", () => run("TLC_ENABLE_HOOK", "Hook gesetzt; Tab wird neu geladen."));
  elements["disable-hook"].addEventListener("click", async () => {
    elements["hook-autostart"].checked = false;
    await send("TLC_SET_AUTOSTART", { enabled: false });
    await run("TLC_DISABLE_HOOK", "Hook deaktiviert; Tab wird neu geladen.");
  });
  elements["reset-tab"].addEventListener("click", () => {
    if (!keepSpeechActive) stopSpeech("Vorlesen wurde wegen des Refreshs ausgeschaltet.");
    else {
      speechQueue = [];
      globalThis.speechSynthesis?.cancel();
      elements["speech-status"].textContent = "Vorlesen bleibt aktiv und wartet nach dem Refresh auf neue Chatzeilen.";
    }
    run("TLC_RESET_TAB", "Tab wird mit aktivem Hook neu geladen.");
  });
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
      if (activeTabId != null && activeIsTikTok) {
        await run(enabled ? "TLC_ENABLE_HOOK" : "TLC_DISABLE_HOOK", enabled ? "Autostart aktiviert; TikTok wird neu geladen." : "Autostart deaktiviert; TikTok wird neu geladen.");
      }
    } catch (error) {
      elements.notice.textContent = String(error?.message || error);
      elements["hook-autostart"].checked = !enabled;
    }
  });
  elements["toggle-speech"].addEventListener("click", () => {
    if (speechEnabled) {
      stopSpeech();
      return;
    }
    speechEnabled = true;
    speechTabId = activeTabId;
    speechQueue = [];
    for (const item of currentState?.chatMessages || []) knownSpeechKeys.add(chatKey(item));
    elements["toggle-speech"].textContent = "Vorlesen aus";
    elements["toggle-speech"].setAttribute("aria-pressed", "true");
    setLed(elements["speech-led"], true, "Vorlesen aktiv", "Vorlesen inaktiv");
    elements["speech-status"].textContent = "Vorlesen ist aktiv; neue Chatzeilen werden vorgelesen.";
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
  elements["speak-names"].addEventListener("change", async () => {
    speakNames = elements["speak-names"].checked;
    elements["shorten-names"].disabled = !speakNames;
    await send("TLC_SET_SPEECH_PREFERENCE", { speakNames });
  });
  elements["shorten-names"].addEventListener("change", async () => {
    shortenNames = elements["shorten-names"].checked;
    await send("TLC_SET_SPEECH_PREFERENCE", { shortenNames });
  });
  const saveServiceSettings = async () => {
    serviceUrl = elements["service-url"].value.trim().replace(/\/$/, "") || "http://127.0.0.1:43117";
    pairingCode = elements["pairing-code"].value.trim();
    await send("TLC_SET_SPEECH_PREFERENCE", { serviceUrl, pairingCode });
    await checkService();
  };
  elements["service-url"].addEventListener("change", saveServiceSettings);
  elements["pairing-code"].addEventListener("change", saveServiceSettings);
  elements["song-enabled"].addEventListener("change", async () => {
    const enabled = elements["song-enabled"].checked;
    elements["recognize-song"].disabled = !enabled;
    setLed(elements["song-led"], enabled, "Songerkennung aktiviert", "Songerkennung inaktiv");
    elements["song-status"].textContent = enabled ? "Bereit für eine manuelle 12-Sekunden-Erkennung." : "Es wird nichts aufgenommen oder übertragen.";
    await send("TLC_SET_SPEECH_PREFERENCE", { songRecognitionEnabled: enabled });
  });
  elements["recognize-song"].addEventListener("click", recognizeSong);
  elements["player-play"].addEventListener("click", () => runPlayer("toggle-play", elements["player-play"]));
  elements["player-replay"].addEventListener("click", () => runPlayer("replay", elements["player-replay"]));
  elements["player-mute"].addEventListener("click", () => runPlayer("toggle-mute", elements["player-mute"]));
  elements["player-pip"].addEventListener("click", () => runPlayer("toggle-pip", elements["player-pip"]));
  elements["player-fullscreen"].addEventListener("click", () => runPlayer("toggle-fullscreen", elements["player-fullscreen"]));
  elements["player-report"].addEventListener("click", () => runPlayer("open-report", elements["player-report"]));
  elements["player-volume"].addEventListener("input", () => {
    const value = Number(elements["player-volume"].value);
    const gain = value > 0 ? 20 * Math.log10(value / 100) : null;
    elements["player-volume-output"].textContent = `${value}% · ${formatDb(gain)}`;
  });
  elements["player-volume"].addEventListener("change", () => runPlayer("set-volume", elements["player-mute"], { value: Number(elements["player-volume"].value) / 100 }));
  elements["limiter-threshold"].addEventListener("input", () => {
    elements["limiter-threshold-output"].textContent = formatDb(Number(elements["limiter-threshold"].value), "dBFS");
  });
  const applyLimiter = () => runPlayer("set-limiter", elements["limiter-enabled"], {
    enabled: elements["limiter-enabled"].checked,
    thresholdDbfs: Number(elements["limiter-threshold"].value)
  });
  elements["limiter-enabled"].addEventListener("change", applyLimiter);
  elements["limiter-threshold"].addEventListener("change", () => {
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
    else if (speechEnabled && keepSpeechActive && message.tabId === speechTabId) processSpeechItems(message.state?.chatMessages || []);
  });
  chrome.tabs.onActivated.addListener(() => refresh().catch(() => {}));
  window.addEventListener("beforeunload", () => globalThis.speechSynthesis?.cancel());
  refresh().then(loadSettings).then(refreshPlayer).catch((error) => { elements.notice.textContent = String(error?.message || error); });
  setInterval(refreshPlayer, 1500);
  setInterval(() => refresh().catch(() => {}), 5000);
})();
