(function () {
  "use strict";

  const core = globalThis.TLC_CONTENT_CORE;
  const SHOW_CAPTIONS = /(untertitel\s+anzeigen|show\s+captions|turn\s+on\s+captions)/i;
  const HIDE_CAPTIONS = /(untertitel\s+ausblenden|hide\s+captions|turn\s+off\s+captions)/i;
  const SETTINGS = /(einstellungen|settings|player settings|optionen)/i;
  const QUALITY = /(qualität|quality)/i;
  const REPORT = /^(melden|report)$/i;
  const QUALITY_ALIASES = Object.freeze({
    auto: ["Automatisch", "Automatic", "Auto"],
    origin: ["Original"],
    uhd_60: ["1080p60", "1080p 60"],
    uhd: ["1080p"],
    hd_60: ["720p60", "720p 60"],
    hd: ["720p"],
    sd: ["540p"],
    ld: ["360p"]
  });
  const ALL_QUALITY_LABELS = [...new Set(Object.values(QUALITY_ALIASES).flat().map(normalizedLabel))];
  const chatNodeText = new WeakMap();
  const giftNodeText = new WeakMap();
  let lastDomCaptionText = "";
  let scanTimer = null;
  let profilePageCache = null;
  let audioPipeline = null;
  let debugEnabled = false;

  function debug(event, detail = {}) {
    if (!debugEnabled) return;
    chrome.runtime.sendMessage({ type: "TLC_DEBUG_EVENT", event, detail }).catch(() => {});
  }

  function normalizedLabel(value) {
    return String(value || "").trim().toLocaleLowerCase().replace(/\s+/g, "");
  }

  function visibleText(element) {
    return String(element?.innerText || element?.textContent || "").trim().replace(/\s+/g, " ");
  }

  function elementLabel(element) {
    return [
      element?.getAttribute?.("aria-label"),
      element?.getAttribute?.("title"),
      element?.getAttribute?.("data-e2e"),
      visibleText(element)
    ].filter(Boolean).join(" ").trim();
  }

  function isVisible(element) {
    if (!(element instanceof Element) || !element.isConnected) return false;
    const style = getComputedStyle(element);
    if (style.display === "none" || style.visibility === "hidden" || Number(style.opacity) === 0) return false;
    const rect = element.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0;
  }

  function candidateElements(includePlainContainers = false) {
    const selector = includePlainContainers
      ? "button,[role='button'],[role='menuitem'],[role='switch'],[tabindex],[data-e2e],div,span"
      : "button,[role='button'],[role='menuitem'],[role='switch'],[tabindex],[data-e2e]";
    return [...document.querySelectorAll(selector)].filter(isVisible);
  }

  function interactiveTarget(element) {
    let current = element;
    for (let depth = 0; current && depth < 5; depth += 1, current = current.parentElement) {
      if (current.matches?.("button,[role='button'],[role='menuitem'],[role='option'],[tabindex]")) return current;
      if (current.hasAttribute?.("data-e2e") || getComputedStyle(current).cursor === "pointer") return current;
    }
    return element;
  }

  function smallestElement(elements) {
    return [...elements].sort((a, b) => {
      const ar = a.getBoundingClientRect();
      const br = b.getBoundingClientRect();
      return (ar.width * ar.height) - (br.width * br.height) || a.childElementCount - b.childElementCount;
    })[0] || null;
  }

  function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  function waitFor(check, timeoutMs = 3000) {
    return new Promise((resolve) => {
      let finished = false;
      let interval;
      let observer;
      const finish = (value) => {
        if (finished) return;
        finished = true;
        clearTimeout(timeout);
        clearInterval(interval);
        observer?.disconnect();
        resolve(value || null);
      };
      const probe = () => {
        try {
          const value = check();
          if (value) finish(value);
        } catch (_) { /* TikTok may replace nodes while probing. */ }
      };
      const timeout = setTimeout(() => finish(null), timeoutMs);
      interval = setInterval(probe, 100);
      observer = new MutationObserver(probe);
      if (document.documentElement) observer.observe(document.documentElement, { childList: true, subtree: true, attributes: true });
      probe();
    });
  }

  function findCaptionControl() {
    for (const element of candidateElements()) {
      const label = elementLabel(element);
      if (HIDE_CAPTIONS.test(label)) return { element, active: true, label };
      if (SHOW_CAPTIONS.test(label)) return { element, active: false, label };
    }
    return null;
  }

  function findSettingsControl() {
    const found = document.querySelector('[data-e2e="player-settings"]') || candidateElements().find((element) => {
      const dataE2e = element.getAttribute?.("data-e2e") || "";
      return SETTINGS.test(elementLabel(element)) || /(?:player-)?settings?/i.test(dataE2e);
    }) || null;
    return found ? interactiveTarget(found) : null;
  }

  function findQualityMenuControl() {
    const matches = candidateElements(true)
      .filter((element) => QUALITY.test(elementLabel(element)) && !qualityLabelMatch(visibleText(element)))
      .map(interactiveTarget);
    return smallestElement([...new Set(matches)]);
  }

  function aliasesFor(quality, sdkKey) {
    const aliases = QUALITY_ALIASES[sdkKey] || [];
    return [...new Set([quality, core.QUALITY_LABELS[sdkKey], ...aliases].filter(Boolean))];
  }

  function qualityOptionElements() {
    const matches = candidateElements(true).filter((element) => qualityLabelMatch(visibleText(element)));
    const byLabel = new Map();
    for (const element of matches) {
      const label = visibleText(element);
      const key = canonicalQualityKey(label);
      const previous = byLabel.get(key);
      const target = interactiveTarget(element);
      byLabel.set(key, smallestElement([previous, target].filter(Boolean)));
    }
    return [...byLabel.entries()].map(([key, element]) => ({ key, label: visibleText(element), element }));
  }

  function qualityLabelMatch(value) {
    const normalized = normalizedLabel(value);
    return ALL_QUALITY_LABELS.some((label) => normalized === label || normalized.startsWith(`${label}(`));
  }

  function canonicalQualityKey(value) {
    const normalized = normalizedLabel(value);
    return ALL_QUALITY_LABELS.find((label) => normalized === label || normalized.startsWith(`${label}(`)) || normalized;
  }

  function discoveredQualityLabels() {
    return qualityOptionElements().map((item) => item.label);
  }

  function findQualityChoice(quality, sdkKey) {
    const expected = new Set(aliasesFor(quality, sdkKey).map(normalizedLabel));
    return qualityOptionElements().find((item) => expected.has(item.key) || [...expected].some((key) => normalizedLabel(item.label).startsWith(`${key}(`))) || null;
  }

  function labelContainsRequested(label, quality, sdkKey) {
    const normalized = normalizedLabel(label);
    return aliasesFor(quality, sdkKey).some((item) => normalized.includes(normalizedLabel(item)));
  }

  function mergeProfile(current, candidate) {
    if (!candidate?.present) return current;
    const score = (value) => [value.uniqueId, value.nickname, value.signature, value.followingCount, value.followerCount, value.likeCount]
      .filter((item) => item != null && item !== "").length;
    return score(candidate) >= score(current || {}) ? candidate : current;
  }

  function collectMetadata() {
    const media = new Map();
    let captionInfo = core.normalizeCaptionInfo(null);
    let profileInfo = { ...core.EMPTY_PROFILE_INFO };
    let aiSummaryInfo = { ...core.EMPTY_AI_SUMMARY_INFO };
    const addResult = (result) => {
      if (result.captionInfo.present) captionInfo = result.captionInfo;
      profileInfo = mergeProfile(profileInfo, result.profileInfo);
      if (result.aiSummaryInfo?.featureFlagPresent) {
        aiSummaryInfo.featureFlagPresent = true;
        if (result.aiSummaryInfo.featureEnabled != null) {
          aiSummaryInfo.featureEnabled = aiSummaryInfo.featureEnabled === true || result.aiSummaryInfo.featureEnabled;
        }
      }
      if (result.aiSummaryInfo?.text) aiSummaryInfo = { ...aiSummaryInfo, ...result.aiSummaryInfo };
      for (const item of result.media) media.set(item.url, item);
    };

    const profileUniqueId = decodeURIComponent(location.pathname.match(/^\/@([^/]+)/)?.[1] || "");
    for (const script of document.scripts) {
      const value = script.textContent || "";
      if (!value) continue;
      addResult(core.inspectMetadata(value, { maxNodes: 5000, profileUniqueId }));
      if (script.type === "application/json" || /^[\s]*[{[]/.test(value)) {
        try { addResult(core.inspectMetadata(JSON.parse(value), { profileUniqueId })); } catch (_) { /* Not every script is JSON. */ }
      }
    }

    for (const entry of performance.getEntriesByType("resource")) {
      const item = core.classifyMediaUrl(entry.name);
      if (item) media.set(item.url, item);
    }

    const domProfile = collectProfileFromDom();
    profileInfo = mergeProfile(profileInfo, domProfile);
    const domSummary = collectSummaryFromDom();
    if (domSummary) aiSummaryInfo = { ...aiSummaryInfo, text: domSummary, source: "dom" };
    return { captionInfo, profileInfo, aiSummaryInfo, media: [...media.values()] };
  }

  function selectorText(selectors) {
    for (const selector of selectors) {
      const element = document.querySelector(selector);
      const value = visibleText(element);
      if (value) return value;
    }
    return "";
  }

  function collectProfileFromDom() {
    if (!/^\/@[^/]+\/?$/.test(location.pathname)) return { ...core.EMPTY_PROFILE_INFO };
    const uniqueId = selectorText(['[data-e2e="user-subtitle"]']) || decodeURIComponent(location.pathname.slice(2));
    const nickname = selectorText(['[data-e2e="user-title"] h1', '[data-e2e="user-title"]']);
    const signature = selectorText(['[data-e2e="user-bio"]', '[data-e2e="user-signature"]']);
    const followingCount = selectorText(['[data-e2e="following-count"]']);
    const followerCount = selectorText(['[data-e2e="followers-count"]']);
    const likeCount = selectorText(['[data-e2e="likes-count"]']);
    const live = Boolean(document.querySelector('[data-e2e*="live" i]'));
    const present = Boolean(nickname || uniqueId) && Boolean(signature || followingCount || followerCount || likeCount);
    return { present, nickname, uniqueId: uniqueId.replace(/^@/, ""), signature, followingCount: followingCount || null, followerCount: followerCount || null, likeCount: likeCount || null, live, source: present ? "dom" : null };
  }

  async function collectProfileFromHover(force = false) {
    if (!force || !/^\/@[^/]+\/live\/?$/.test(location.pathname)) return { ...core.EMPTY_PROFILE_INFO };
    const handle = currentHandle();
    const expected = `/@${handle.toLocaleLowerCase()}`;
    const link = [...document.querySelectorAll('a[href^="/@"],a[href*="tiktok.com/@"]')].find((item) => {
      try { return decodeURIComponent(new URL(item.href, location.href).pathname).replace(/\/$/, "").toLocaleLowerCase() === expected; }
      catch (_) { return false; }
    });
    if (!link) return { ...core.EMPTY_PROFILE_INFO };
    for (const type of ["pointerover", "mouseover", "mouseenter"]) link.dispatchEvent(new MouseEvent(type, { bubbles: true, view: window }));
    const hasCounts = await waitFor(() => document.querySelector('[data-e2e="following-count"],[data-e2e="followers-count"],[data-e2e="likes-count"]'), 1800);
    if (!hasCounts) return { ...core.EMPTY_PROFILE_INFO };
    const followingCount = selectorText(['[data-e2e="following-count"]']);
    const followerCount = selectorText(['[data-e2e="followers-count"]']);
    const likeCount = selectorText(['[data-e2e="likes-count"]']);
    const signature = selectorText(['[data-e2e="user-bio"]', '[data-e2e="user-signature"]']);
    const nickname = selectorText(['[data-e2e="user-title"] h1', '[data-e2e="user-title"]']) || visibleText(link);
    const present = Boolean(followingCount || followerCount || likeCount);
    return { present, nickname, uniqueId: handle, signature, followingCount: followingCount || null, followerCount: followerCount || null, likeCount: likeCount || null, live: true, source: present ? "Profilkarte" : null };
  }

  async function fetchPublicProfile(force = false) {
    const handle = decodeURIComponent(location.pathname.match(/^\/@([^/]+)/)?.[1] || "");
    if (!handle) return { ...core.EMPTY_PROFILE_INFO };
    const now = Date.now();
    if (!force && profilePageCache?.handle === handle && now - profilePageCache.at < 5 * 60 * 1000) return profilePageCache.profile;
    try {
      const response = await fetch(`https://www.tiktok.com/@${encodeURIComponent(handle)}`, {
        credentials: "omit",
        cache: "no-store",
        redirect: "follow"
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const html = await response.text();
      const page = new DOMParser().parseFromString(html, "text/html");
      let profile = { ...core.EMPTY_PROFILE_INFO };
      for (const script of page.scripts) {
        const value = script.textContent || "";
        if (!value || value.length > 8 * 1024 * 1024) continue;
        try {
          profile = mergeProfile(profile, core.inspectMetadata(JSON.parse(value), { maxNodes: 20000, profileUniqueId: handle }).profileInfo);
        } catch (_) { /* Many profile scripts are not JSON. */ }
      }
      if (profile.present) profile = { ...profile, uniqueId: profile.uniqueId || handle, live: true, source: "öffentliche Profilseite" };
      profilePageCache = { handle, at: now, profile };
      return profile;
    } catch (_) {
      const profile = { ...core.EMPTY_PROFILE_INFO };
      profilePageCache = { handle, at: now, profile };
      return profile;
    }
  }

  function collectSummaryFromDom() {
    if (!/(?:^|\/)live(?:\/|$)/.test(location.pathname)) return "";
    const candidates = [...document.querySelectorAll('[data-e2e*="summary" i],[class*="summary" i]')].filter(isVisible);
    for (const element of candidates) {
      const value = visibleText(element);
      if (!/(zusammenfassung|summary)/i.test(value) || /meldung wird überprüft/i.test(value)) continue;
      const text = value.replace(/^(?:zusammenfassung|summary)\s*[:\-]?\s*/i, "").trim();
      if (text.length >= 12) return text.slice(0, 4000);
    }
    return "";
  }

  function currentHandle() {
    return decodeURIComponent(location.pathname.match(/^\/@([^/]+)/)?.[1] || "");
  }

  function recommendedCardForHandle(handle) {
    const expected = `/@${handle.toLocaleLowerCase()}/live`;
    const links = [...document.querySelectorAll('a[href*="/live"]')].filter((link) => {
      try { return decodeURIComponent(new URL(link.href, location.href).pathname).toLocaleLowerCase() === expected; }
      catch (_) { return false; }
    });
    for (const link of links) {
      let node = link;
      for (let depth = 0; node && depth < 7; depth += 1, node = node.parentElement) {
        const rect = node.getBoundingClientRect?.() || { width: 0, height: 0 };
        const cardLike = node.matches?.('article,li,[data-e2e*="live-card" i]') || node.querySelector?.("video");
        if (cardLike && rect.width >= 120 && rect.width <= 650 && rect.height > 80 && rect.height <= 600) return node;
      }
    }
    return null;
  }

  function explicitCardSummary(card) {
    if (!card) return "";
    const candidates = card.querySelectorAll('[data-e2e*="summary" i],[data-e2e*="description" i],[class*="summary" i],[class*="description" i],[aria-label*="Zusammenfassung" i],[aria-label*="summary" i]');
    for (const element of candidates) {
      const text = visibleText(element).replace(/^(?:ki[- ]?zusammenfassung|zusammenfassung|summary)\s*[:\-]?\s*/i, "").trim();
      if (text.length >= 12 && !/^(?:jetzt anschauen|lets go live|in echtzeit interagieren)/i.test(text)) return text.slice(0, 4000);
    }
    for (const link of card.querySelectorAll('a[href*="/live"][title]')) {
      const title = String(link.getAttribute("title") || "").trim();
      if (title.length >= 5 && !/^(?:jetzt anschauen|lets go live|in echtzeit interagieren)/i.test(title)) return title.slice(0, 4000);
    }
    const whole = visibleText(card);
    const match = whole.match(/(?:KI[- ]?Zusammenfassung|Zusammenfassung|Summary)\s*[:\-]\s*(.{12,2000})/i);
    return match ? match[1].trim().slice(0, 4000) : "";
  }

  async function collectRecommendedSummary(forceHover = false) {
    const card = recommendedCardForHandle(currentHandle());
    if (!card) return { found: false, hovered: false, text: "" };
    let text = explicitCardSummary(card);
    if (!text && forceHover) {
      for (const type of ["pointerover", "mouseover", "mouseenter"]) card.dispatchEvent(new MouseEvent(type, { bubbles: true, view: window }));
      text = await waitFor(() => explicitCardSummary(card), 1500) || "";
    }
    return { found: true, hovered: Boolean(forceHover), text };
  }

  async function scanPage(options = {}) {
    const collected = collectMetadata();
    if (/^\/@[^/]+\/live\/?$/.test(location.pathname) && (options.refreshProfile || !collected.profileInfo?.followerCount)) {
      collected.profileInfo = mergeProfile(collected.profileInfo, await fetchPublicProfile(Boolean(options.refreshProfile)));
      collected.profileInfo = mergeProfile(collected.profileInfo, await collectProfileFromHover(Boolean(options.refreshProfile)));
    }
    const overviewSummary = await collectRecommendedSummary(Boolean(options.refreshProfile));
    collected.aiSummaryInfo.overviewCardFound = overviewSummary.found;
    collected.aiSummaryInfo.overviewCardHovered = overviewSummary.hovered;
    if (overviewSummary.text) collected.aiSummaryInfo = { ...collected.aiSummaryInfo, text: overviewSummary.text, source: "LIVE-Übersichtskarte" };
    const captionControl = findCaptionControl();
    const page = { url: location.href, title: document.title, scannedAtUtc: new Date().toISOString() };
    await chrome.runtime.sendMessage({
      type: "TLC_PAGE_STATE",
      page,
      captionInfo: collected.captionInfo,
      profileInfo: collected.profileInfo,
      aiSummaryInfo: collected.aiSummaryInfo,
      menuCaptionAvailable: Boolean(captionControl),
      menuCaptionActive: Boolean(captionControl?.active),
      media: collected.media
    }).catch(() => {});
    debug("scan", { profile: collected.profileInfo, summary: collected.aiSummaryInfo, mediaCount: collected.media.length });
    return {
      page,
      captionInfo: collected.captionInfo,
      profileInfo: collected.profileInfo,
      aiSummaryInfo: collected.aiSummaryInfo,
      mediaCount: collected.media.length,
      captionControl: Boolean(captionControl)
    };
  }

  function scheduleScan(delay = 250) {
    clearTimeout(scanTimer);
    scanTimer = setTimeout(() => scanPage().catch(() => {}), delay);
  }

  async function enableCaptions() {
    let control = findCaptionControl();
    if (control?.active) return { activated: true, alreadyActive: true, label: control.label };
    if (control) {
      control.element.click();
      scheduleScan(300);
      return { activated: true, alreadyActive: false, label: control.label };
    }

    const settings = findSettingsControl();
    if (settings) {
      settings.click();
      control = await waitFor(findCaptionControl);
      if (control?.active) return { activated: true, alreadyActive: true, label: control.label };
      if (control) {
        control.element.click();
        scheduleScan(300);
        return { activated: true, alreadyActive: false, label: control.label };
      }
      if (settings.isConnected) settings.click();
    }
    scheduleScan(0);
    return { activated: false, reason: "Kein Untertitelschalter gefunden. TikTok stellt für diesen Stream derzeit keine native Untertitelfunktion bereit." };
  }

  async function setQuality(quality, sdkKey) {
    const requested = quality || core.QUALITY_LABELS[sdkKey] || sdkKey;
    let stage = "Ausgangszustand";
    let choice = findQualityChoice(requested, sdkKey);
    let options = discoveredQualityLabels();

    if (!choice || options.length < 2) {
      stage = "Einstellungsmenü";
      let menu = findQualityMenuControl();
      if (!menu) {
        const settings = findSettingsControl();
        if (!settings) return { activated: false, stage, options, reason: "TikToks Einstellungsmenü wurde nicht gefunden." };
        interactiveTarget(settings).click();
        menu = await waitFor(findQualityMenuControl);
      }
      if (!menu) return { activated: false, stage, options: discoveredQualityLabels(), reason: "TikToks Qualitätsmenü wurde nicht gefunden." };
      if (labelContainsRequested(elementLabel(menu), requested, sdkKey)) {
        return { activated: true, verified: true, alreadyActive: true, quality: requested, stage, options: discoveredQualityLabels() };
      }
      stage = "Qualitätsuntermenü";
      interactiveTarget(menu).click();
      const allOptions = await waitFor(() => qualityOptionElements().length >= 2 ? qualityOptionElements() : null);
      choice = allOptions?.find((item) => {
        const expected = new Set(aliasesFor(requested, sdkKey).map(normalizedLabel));
        return expected.has(item.key) || [...expected].some((key) => normalizedLabel(item.label).startsWith(`${key}(`));
      }) || findQualityChoice(requested, sdkKey);
      options = discoveredQualityLabels();
    }

    if (!choice) {
      return { activated: false, stage, options, reason: `Die Qualitätsstufe ${requested} wurde nicht gefunden. Sichtbare Optionen: ${options.join(", ") || "keine"}.` };
    }

    stage = "Auswahl angeklickt";
    interactiveTarget(choice.element).click();
    await waitFor(() => !choice.element.isConnected || !isVisible(choice.element), 1200);
    let verificationMenu = findQualityMenuControl();
    if (!verificationMenu) {
      const settings = findSettingsControl();
      if (settings) {
        interactiveTarget(settings).click();
        verificationMenu = await waitFor(findQualityMenuControl);
      }
    }
    const verified = verificationMenu && labelContainsRequested(elementLabel(verificationMenu), requested, sdkKey) ? verificationMenu : null;
    scheduleScan(400);
    if (!verified) {
      debug("quality-clicked-unverified", { requested, sdkKey, label: choice.label, options });
      return { activated: true, clicked: true, verified: false, verificationPending: true, stage: "Verifikation", quality: requested, label: choice.label, options, reason: `${requested} wurde angeklickt; TikTok hat das Menü geschlossen, bevor die aktive Auswahl technisch bestätigt werden konnte.` };
    }
    return { activated: true, clicked: true, verified: true, alreadyActive: false, quality: requested, label: choice.label, stage: "Verifiziert", options };
  }

  function elapsedText() {
    const control = document.querySelector('[data-e2e="control-bar-id-v2"]');
    const match = visibleText(control).match(/(?:^|\s)(\d{1,3}:\d{2}(?::\d{2})?)(?:\s|$)/);
    if (match) return match[1];
    return "";
  }

  function primaryVideo() {
    return [...document.querySelectorAll("video")].sort((a, b) => {
      const ar = a.getBoundingClientRect();
      const br = b.getBoundingClientRect();
      return (br.width * br.height) - (ar.width * ar.height);
    })[0] || null;
  }

  function connectedStreamState() {
    const videos = [...document.querySelectorAll("video")].filter(isVisible);
    const guestSelectors = [
      '[data-e2e*="multi-guest" i]', '[data-e2e*="guest-user" i]',
      '[data-e2e*="guest-avatar" i]', '[data-e2e*="guest-player" i]'
    ];
    const guestMarkers = [...document.querySelectorAll(guestSelectors.join(","))].filter(isVisible);
    const leafMarkers = guestMarkers.filter((item) => !guestMarkers.some((other) => other !== item && item.contains(other)));
    const multiGuest = videos.length > 1 || guestMarkers.length > 0;
    const connectedStreams = videos.length > 1
      ? videos.length
      : leafMarkers.length > 1 ? leafMarkers.length : multiGuest ? 2 : videos.length ? 1 : 0;
    return { connectedStreams, multiGuest };
  }

  function volumeGainDb(volume) {
    return volume > 0 ? Math.round(20 * Math.log10(volume) * 10) / 10 : null;
  }

  function currentPeakDbfs() {
    if (!audioPipeline?.analyser || audioPipeline.context.state !== "running") return null;
    const values = new Float32Array(audioPipeline.analyser.fftSize);
    audioPipeline.analyser.getFloatTimeDomainData(values);
    let peak = 0;
    for (const value of values) peak = Math.max(peak, Math.abs(value));
    return peak > 0 ? Math.max(-100, Math.round(20 * Math.log10(peak) * 10) / 10) : -100;
  }

  async function ensureAudioPipeline(video) {
    if (audioPipeline?.video === video) {
      if (audioPipeline.context.state === "suspended") await audioPipeline.context.resume();
      return audioPipeline;
    }
    if (audioPipeline?.context) await audioPipeline.context.close().catch(() => {});
    const AudioContextClass = globalThis.AudioContext || globalThis.webkitAudioContext;
    if (!AudioContextClass) throw new Error("Die Web-Audio-API ist in diesem Browser nicht verfügbar.");
    const context = new AudioContextClass();
    const source = context.createMediaElementSource(video);
    const compressor = context.createDynamicsCompressor();
    const makeupGain = context.createGain();
    const analyser = context.createAnalyser();
    analyser.fftSize = 2048;
    compressor.threshold.value = 0;
    compressor.knee.value = 0;
    compressor.ratio.value = 1;
    compressor.attack.value = 0.001;
    compressor.release.value = 0.08;
    makeupGain.gain.value = 1;
    source.connect(compressor).connect(makeupGain).connect(analyser).connect(context.destination);
    audioPipeline = { video, context, source, compressor, makeupGain, analyser, enabled: false, limiterStrength: 30, thresholdDbfs: core.limiterStrengthToDbfs(30) };
    await context.resume();
    return audioPipeline;
  }

  async function configureLimiter(video, enabled, strengthValue) {
    const strength = Math.max(0, Math.min(100, Number(strengthValue ?? 30)));
    const threshold = core.limiterStrengthToDbfs(strength);
    try {
      const pipeline = await ensureAudioPipeline(video);
      pipeline.enabled = Boolean(enabled);
      pipeline.limiterStrength = strength;
      pipeline.thresholdDbfs = threshold;
      pipeline.compressor.threshold.value = pipeline.enabled ? threshold : 0;
      pipeline.compressor.knee.value = 0;
      pipeline.compressor.ratio.value = pipeline.enabled ? 20 : 1;
      pipeline.compressor.attack.value = 0.001;
      pipeline.compressor.release.value = 0.08;
      pipeline.makeupGain.gain.value = pipeline.enabled ? core.limiterMakeupCompensation(threshold, 20) : 1;
      debug("limiter", { mode: "compressor", enabled: pipeline.enabled, strength, threshold });
      return pipeline;
    } catch (error) {
      const detail = String(error?.message || error).slice(0, 300);
      debug("limiter-pipeline-conflict", { strength, threshold, error: detail });
      if (/MediaElementSource|different MediaElementSource|already connected/i.test(detail)) {
        await chrome.runtime.sendMessage({ type: "TLC_AUDIO_PIPELINE_CONFLICT" }).catch(() => {});
      }
      throw error;
    }
  }

  function getPlayerState() {
    const video = primaryVideo();
    const connected = connectedStreamState();
    const volume = Number(video?.volume ?? 1);
    return {
      available: Boolean(video),
      playing: Boolean(video && !video.paused),
      muted: Boolean(video && (video.muted || video.volume === 0)),
      volume,
      volumePercent: Math.round(volume * 100),
      volumeGainDb: volumeGainDb(volume),
      peakDbfs: currentPeakDbfs(),
      limiterEnabled: Boolean(audioPipeline?.video === video && audioPipeline.enabled),
      limiterMode: audioPipeline?.video === video && audioPipeline.enabled ? "Kompressor" : null,
      limiterStrength: audioPipeline?.video === video ? audioPipeline.limiterStrength : 30,
      limiterThresholdDbfs: audioPipeline?.video === video ? audioPipeline.thresholdDbfs : core.limiterStrengthToDbfs(30),
      limiterReductionDb: audioPipeline?.video === video ? Math.round(Number(audioPipeline.compressor.reduction || 0) * 10) / 10 : 0,
      ...connected,
      elapsedText: elapsedText(),
      pipActive: Boolean(video && document.pictureInPictureElement === video),
      fullscreenActive: Boolean(document.fullscreenElement),
      updatedAtUtc: new Date().toISOString()
    };
  }

  async function playerAction(action, payload = {}) {
    const video = primaryVideo();
    if (!video) return { activated: false, action, reason: "Kein TikTok-Videoelement gefunden.", playerState: getPlayerState() };
    try {
      if (action === "toggle-play") {
        if (video.paused) await video.play();
        else video.pause();
      } else if (action === "replay") {
        const replay = document.querySelector('[data-e2e="replay-icon"]');
        if (!replay) return { activated: false, action, reason: "TikToks Player-Neuladen wurde nicht gefunden.", playerState: getPlayerState() };
        replay.click();
      } else if (action === "toggle-mute") {
        const previous = video.muted || video.volume === 0;
        const volume = document.querySelector('[data-e2e="volume-icon"],[data-e2e="volume-icon-id"]');
        if (volume) volume.click();
        await sleep(150);
        if ((video.muted || video.volume === 0) === previous) {
          video.muted = !previous;
          video.dispatchEvent(new Event("volumechange", { bubbles: true }));
        }
      } else if (action === "set-volume") {
        const volume = Math.max(0, Math.min(1, Number(payload.value)));
        if (!Number.isFinite(volume)) return { activated: false, action, reason: "Ungültiger Lautstärkewert.", playerState: getPlayerState() };
        video.volume = volume;
        if (volume > 0) video.muted = false;
        video.dispatchEvent(new Event("volumechange", { bubbles: true }));
      } else if (action === "set-limiter") {
        await configureLimiter(video, payload.enabled, payload.strength);
      } else if (action === "toggle-pip") {
        if (document.pictureInPictureElement) await document.exitPictureInPicture();
        else if (document.pictureInPictureEnabled && typeof video.requestPictureInPicture === "function") await video.requestPictureInPicture();
        else return { activated: false, action, reason: "Bild-in-Bild wird von diesem Browser oder Stream nicht angeboten.", playerState: getPlayerState() };
      } else if (action === "toggle-fullscreen") {
        if (document.fullscreenElement) await document.exitFullscreen();
        else {
          const fullscreen = document.querySelector('[data-e2e="fullscreen-icon"]');
          fullscreen?.click();
          const entered = await waitFor(() => document.fullscreenElement, 1000);
          if (!entered) await (video.closest('[data-e2e*="player" i]') || video).requestFullscreen();
        }
      } else if (action === "open-report") {
        const share = document.querySelector('[data-e2e="room-header-share-btn"]');
        if (!share) return { activated: false, action, reason: "TikToks Teilen-Menü wurde nicht gefunden.", playerState: getPlayerState() };
        share.click();
        const report = await waitFor(() => smallestElement(candidateElements(true).filter((element) => REPORT.test(visibleText(element)))));
        if (!report) return { activated: false, action, reason: "Der Eintrag „Melden“ wurde im Teilen-Menü nicht gefunden.", playerState: getPlayerState() };
        report.click();
        const dialog = await waitFor(() => document.querySelector('[role="dialog"],[data-e2e*="report" i]'));
        return { activated: Boolean(dialog), action, reason: dialog ? null : "„Melden“ wurde angeklickt, der Dialog konnte aber nicht bestätigt werden.", playerState: getPlayerState() };
      } else {
        return { activated: false, action, reason: "Unbekannte Playeraktion.", playerState: getPlayerState() };
      }
      await sleep(120);
      return { activated: true, action, playerState: getPlayerState() };
    } catch (error) {
      const message = String(error?.message || error);
      const gesture = /gesture|activation|permission|allowed/i.test(message)
        ? " Der Browser verlangt möglicherweise einen direkten Klick im Player."
        : "";
      return { activated: false, action, reason: `${message}${gesture}`.slice(0, 500), playerState: getPlayerState() };
    }
  }

  function extractDomChat(element) {
    const owner = element.querySelector('[data-e2e="message-owner-name"]');
    const author = visibleText(owner);
    if (!owner) return null;
    const pieces = [];
    const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      if (owner.contains(node)) continue;
      if (!(owner.compareDocumentPosition(node) & Node.DOCUMENT_POSITION_FOLLOWING)) continue;
      if (node.parentElement?.closest("svg,picture,[aria-hidden='true']")) continue;
      const value = String(node.nodeValue || "").trim();
      if (!value || /^(?:Nr\.\s*\d+|\d+|SHRK|tmm|LIVE\s*Pro)$/i.test(value)) continue;
      pieces.push(value);
    }
    let content = pieces.join(" ").replace(/\s+/g, " ").trim();
    if (!content) {
      const whole = visibleText(element);
      const position = whole.indexOf(author);
      content = position >= 0 ? whole.slice(position + author.length).trim() : whole;
      content = content.replace(/^(?:Nr\.\s*\d+\s*)+/i, "");
    }
    return { author, content, contentLanguage: document.documentElement.lang || "", source: "dom", receivedAtUtc: new Date().toISOString() };
  }

  function scanDomChat() {
    for (const element of [...document.querySelectorAll('[data-e2e="chat-message"]')].slice(-100)) {
      const raw = visibleText(element);
      if (!raw || chatNodeText.get(element) === raw) continue;
      chatNodeText.set(element, raw);
      const chatMessage = extractDomChat(element);
      if (chatMessage?.content) chrome.runtime.sendMessage({ type: "TLC_CHAT_MESSAGE", chatMessage }).catch(() => {});
    }
  }

  function scanDomGifts() {
    const candidates = [...document.querySelectorAll('[data-e2e*="gift" i],[data-e2e*="message" i]')].slice(-150);
    for (const element of candidates) {
      const raw = visibleText(element);
      if (!raw || giftNodeText.get(element) === raw || !/(?:gesendet|sent)\s*x\s*\d+/i.test(raw)) continue;
      giftNodeText.set(element, raw);
      const countMatch = raw.match(/(?:gesendet|sent)\s*x\s*(\d+)/i);
      const owner = visibleText(element.querySelector('[data-e2e="message-owner-name"]'));
      const authorMatch = raw.match(/^(.+?)\s+(?:hat\s+.+?\s+gesendet|sent\s+.+?)\s*x\s*\d+/i);
      const author = owner || authorMatch?.[1] || "";
      if (!author || !countMatch) continue;
      chrome.runtime.sendMessage({
        type: "TLC_GIFT_MESSAGE",
        giftMessage: {
          author,
          repeatCount: countMatch[1],
          rawText: raw,
          source: "dom",
          receivedAtUtc: new Date().toISOString()
        }
      }).catch(() => {});
    }
  }

  function scanDomCaptions() {
    const lines = [...document.querySelectorAll('p[class*="h-[34px]"][class*="leading-[34px]"]')]
      .filter((element) => {
        const row = element.parentElement;
        const viewport = row?.parentElement;
        return isVisible(element)
          && String(row?.className || "").includes("flex-col-reverse")
          && String(viewport?.className || "").includes("absolute")
          && String(viewport?.className || "").includes("overflow-hidden");
      })
      .sort((a, b) => a.getBoundingClientRect().top - b.getBoundingClientRect().top)
      .map(visibleText)
      .filter(Boolean);
    const text = lines.join(" ").replace(/\s+/g, " ").trim();
    if (!text || text === lastDomCaptionText) return;
    lastDomCaptionText = text;
    chrome.runtime.sendMessage({
      type: "TLC_CAPTION",
      caption: {
        method: "DomCaption",
        source: "dom",
        definite: false,
        contents: [{ lang: "", text }],
        receivedAtUtc: new Date().toISOString()
      }
    }).catch(() => {});
  }

  window.addEventListener("message", (event) => {
    if (event.source !== window || event.origin !== location.origin) return;
    const data = event.data;
    if (!data || data.source !== "tiktok-live-companion" || data.version !== 1) return;
    if (data.type === "caption") {
      chrome.runtime.sendMessage({ type: "TLC_CAPTION", caption: data.caption }).catch(() => {});
    } else if (data.type === "live-event") {
      chrome.runtime.sendMessage({ type: "TLC_LIVE_EVENT", liveEvent: data.liveEvent }).catch(() => {});
    } else if (data.type === "chat-message") {
      chrome.runtime.sendMessage({ type: "TLC_CHAT_MESSAGE", chatMessage: data.chatMessage }).catch(() => {});
    } else if (data.type === "gift-message") {
      chrome.runtime.sendMessage({ type: "TLC_GIFT_MESSAGE", giftMessage: data.giftMessage }).catch(() => {});
    } else if (data.type === "hook-status") {
      chrome.runtime.sendMessage({ type: "TLC_HOOK_STATUS", hook: data.hook }).catch(() => {});
    }
  });

  chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.type === "TLC_DEBUG_CONFIG") {
      debugEnabled = Boolean(message.enabled);
      sendResponse({ enabled: debugEnabled });
      return false;
    }
    if (message.type === "TLC_SCAN") {
      scanPage().then((result) => sendResponse(result)).catch((error) => sendResponse({ error: String(error) }));
      return true;
    }
    if (message.type === "TLC_ENABLE_CAPTIONS") {
      enableCaptions().then((result) => sendResponse(result)).catch((error) => sendResponse({ activated: false, error: String(error) }));
      return true;
    }
    if (message.type === "TLC_REFRESH_PAGE_INFO") {
      scanPage({ refreshProfile: true }).then((result) => sendResponse(result)).catch((error) => sendResponse({ activated: false, error: String(error) }));
      return true;
    }
    if (message.type === "TLC_SET_QUALITY") {
      setQuality(message.quality, message.sdkKey).then((result) => sendResponse(result)).catch((error) => sendResponse({ activated: false, error: String(error) }));
      return true;
    }
    if (message.type === "TLC_GET_PLAYER_STATE") {
      sendResponse({ playerState: getPlayerState() });
      return false;
    }
    if (message.type === "TLC_PLAYER_ACTION") {
      playerAction(message.action, message).then((result) => sendResponse(result)).catch((error) => sendResponse({ activated: false, error: String(error), playerState: getPlayerState() }));
      return true;
    }
    return false;
  });

  try {
    const observer = new PerformanceObserver((list) => {
      const media = [];
      for (const entry of list.getEntries()) {
        const item = core.classifyMediaUrl(entry.name);
        if (item) media.push(item);
      }
      if (media.length) chrome.runtime.sendMessage({ type: "TLC_MEDIA_FOUND", source: "performance", media }).catch(() => {});
    });
    observer.observe({ type: "resource", buffered: true });
  } catch (_) { /* Resource observation is optional. */ }

  const start = () => {
    new MutationObserver(() => {
      scanDomChat();
      scanDomGifts();
      scanDomCaptions();
      scheduleScan(1500);
    }).observe(document.documentElement, { childList: true, subtree: true });
    scanDomChat();
    scanDomGifts();
    scanDomCaptions();
    scheduleScan(50);
    chrome.storage.local.get("tlc-settings").then(({ "tlc-settings": settings = {} }) => {
      const apply = async () => {
        const video = primaryVideo();
        if (!video) {
          setTimeout(apply, 500);
          return;
        }
        const volume = Math.max(0, Math.min(100, Number(settings.playerVolume ?? 100))) / 100;
        video.volume = volume;
        if (volume > 0) video.muted = false;
        if (settings.limiterEnabled) await configureLimiter(video, true, settings.limiterStrength ?? 30);
      };
      apply().catch((error) => debug("audio-settings-restore", { error: String(error?.message || error).slice(0, 300) }));
    }).catch(() => {});
  };
  if (document.documentElement) start();
  else document.addEventListener("DOMContentLoaded", start, { once: true });
})();
