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
  const POPUP_GUARD_GRACE_MS = 30;
  const QUICK_RECOVER_INTERVAL_MS = 30;
  const QUICK_RECOVER_RELOAD_COOLDOWN_MS = 300;
  let lastDomCaptionText = "";
  let scanTimer = null;
  let profilePageCache = null;
  let audioPipeline = null;
  let fallbackLimiter = null;
  let debugEnabled = false;
  let tabActive = false;
  let chatSourceOnly = false;
  let quickRecoverEnabled = false;
  let quickRecoverArmed = false;
  let tabRuntimeStarted = false;
  let quickRecoverFailures = 0;
  let lastQuickRecoverAt = 0;
  let fullscreenWasActive = false;
  const popupGuardStartedAt = Date.now();

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
    const winner = score(candidate) >= score(current || {}) ? candidate : current;
    return {
      ...winner,
      live: Boolean(winner?.live || current?.live || candidate?.live),
      verified: Boolean(winner?.verified || current?.verified || candidate?.verified),
      verifiedLabel: winner?.verifiedLabel || current?.verifiedLabel || candidate?.verifiedLabel || "",
      livePro: Boolean(winner?.livePro || current?.livePro || candidate?.livePro),
      liveProLabel: winner?.liveProLabel || current?.liveProLabel || candidate?.liveProLabel || ""
    };
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

  function currentPathHandle() {
    const path = decodeURIComponent(location.pathname);
    return path.match(/^\/@([^/]+)(?:\/live)?\/?$/i)?.[1] || path.match(/^\/embed\/live\/@?([^/?#]+)\/?$/i)?.[1] || "";
  }

  function colorIsCertified(value) {
    const raw = String(value || "");
    const match = raw.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/i);
    if (!match) return /#(?:00b|0af|20d5ec|25f4ee|2af|5ad|0dd)/i.test(raw);
    const red = Number(match[1]);
    const green = Number(match[2]);
    const blue = Number(match[3]);
    return blue >= 170 && green >= 120 && red <= 90;
  }

  function certifiedSvgBadge(element) {
    if (String(element?.tagName || "").toLowerCase() !== "svg") return false;
    if (!isVisible(element)) return false;
    const rect = element.getBoundingClientRect();
    if (rect.width < 8 || rect.height < 8 || rect.width > 24 || rect.height > 24) return false;
    const circles = [...element.querySelectorAll("circle")];
    const paths = [...element.querySelectorAll("path")];
    const hasBlueCircle = circles.some((circle) =>
      colorIsCertified(circle.getAttribute("fill")) || colorIsCertified(getComputedStyle(circle).fill)
    );
    const hasWhiteMark = paths.some((path) => /(?:^|[;,\s])(?:#fff|#ffffff|white)(?:$|[;,\s])/i.test(String(path.getAttribute("fill") || getComputedStyle(path).fill || "")));
    return hasBlueCircle && hasWhiteMark;
  }

  function certifiedBadgePresent(root = document) {
    const handle = currentPathHandle().toLocaleLowerCase();
    for (const svg of root.querySelectorAll("svg")) {
      if (!certifiedSvgBadge(svg)) continue;
      const profileLink = svg.closest('a[href^="/@"],a[href*="tiktok.com/@"]');
      const textScope = svg.closest('h1,h2,h3,p,[data-e2e="user-title"],[data-e2e="user-subtitle"],[data-e2e*="user" i]') || svg.parentElement;
      const nearby = visibleText(textScope?.parentElement || textScope || svg.parentElement).toLocaleLowerCase();
      let linkedHandle = "";
      try { linkedHandle = profileLink ? decodeURIComponent(new URL(profileLink.href, location.href).pathname).replace(/^\/@/, "").replace(/\/$/, "").toLocaleLowerCase() : ""; }
      catch (_) { linkedHandle = ""; }
      if (!handle || linkedHandle === handle || nearby.includes(handle)) return true;
    }
    return false;
  }

  function liveProBadgePresent(root = document) {
    if (!isLivePage()) return false;
    const handle = currentPathHandle().toLocaleLowerCase();
    const scopes = [...root.querySelectorAll('[data-e2e="live-header-container"],header,[role="link"],a[href^="/@"],a[href*="tiktok.com/@"]')]
      .filter((element) => isVisible(element));
    for (const scope of scopes.slice(0, 20)) {
      const text = visibleText(scope).replace(/\s+/g, " ").trim();
      if (!/\bLIVE\s+Pro\b/i.test(text) && !/Anerkannt von TikTok LIVE/i.test(text)) continue;
      if (!handle || text.toLocaleLowerCase().includes(handle) || scope.querySelector('a[href^="/@"],a[href*="tiktok.com/@"],svg')) return true;
    }
    return false;
  }

  function collectDomLiveStats() {
    const text = visibleText(document.body);
    const pattern = "([0-9][0-9.,\\s]*\\s*[KMB]?)";
    const clean = (value) => value ? value.replace(/\s+/g, "") : null;
    const viewerCount = clean(text.match(new RegExp(`Zuschauer\\*innen\\s*[·:]?\\s*${pattern}`, "i"))?.[1]);
    const totalViewers = clean(text.match(new RegExp(`Aufrufe\\s+gesamt\\s*[·:]?\\s*${pattern}`, "i"))?.[1]);
    const likeCount = clean(text.match(new RegExp(`Likes?\\s*[·:]?\\s*${pattern}`, "i"))?.[1]);
    return viewerCount || totalViewers || likeCount
      ? { viewerCount, totalViewers, likeCount, lastUpdatedUtc: new Date().toISOString() }
      : null;
  }

  function collectProfileFromDom() {
    const handle = currentPathHandle();
    const profilePage = /^\/@[^/]+\/?$/i.test(location.pathname);
    const livePage = isLivePage();
    if (!profilePage && !livePage) return { ...core.EMPTY_PROFILE_INFO };
    const uniqueId = selectorText(['[data-e2e="user-subtitle"]']) || handle;
    const nickname = selectorText(['[data-e2e="user-title"] h1', '[data-e2e="user-title"]']);
    const signature = selectorText(['[data-e2e="user-bio"]', '[data-e2e="user-signature"]']);
    const followingCount = selectorText(['[data-e2e="following-count"]']);
    const followerCount = selectorText(['[data-e2e="followers-count"]']);
    const likeCount = selectorText(['[data-e2e="likes-count"]']);
    const verified = certifiedBadgePresent();
    const livePro = livePage && liveProBadgePresent();
    const live = Boolean(livePage || document.querySelector('[data-e2e*="live" i]'));
    const present = Boolean(nickname || uniqueId) && Boolean(signature || followingCount || followerCount || likeCount || verified || livePro || livePage);
    return { present, nickname, uniqueId: uniqueId.replace(/^@/, ""), signature, followingCount: followingCount || null, followerCount: followerCount || null, likeCount: likeCount || null, live, verified, verifiedLabel: verified ? "Zertifiziert" : "", livePro, liveProLabel: livePro ? "Live Pro" : "", source: present ? "dom" : null };
  }

  async function collectProfileFromHover(force = false) {
    if (!force || !isLivePage()) return { ...core.EMPTY_PROFILE_INFO };
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
    const verified = certifiedBadgePresent();
    const livePro = liveProBadgePresent();
    const present = Boolean(followingCount || followerCount || likeCount);
    return { present, nickname, uniqueId: handle, signature, followingCount: followingCount || null, followerCount: followerCount || null, likeCount: likeCount || null, live: true, verified, verifiedLabel: verified ? "Zertifiziert" : "", livePro, liveProLabel: livePro ? "Live Pro" : "", source: present ? "Profilkarte" : null };
  }

  async function fetchPublicProfile(force = false) {
    const handle = currentPathHandle();
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
      const verified = certifiedBadgePresent(page);
      if (profile.present || verified) profile = { ...profile, present: true, uniqueId: profile.uniqueId || handle, live: true, verified: Boolean(profile.verified || verified), verifiedLabel: profile.verifiedLabel || (verified ? "Zertifiziert" : ""), source: "öffentliche Profilseite" };
      profilePageCache = { handle, at: now, profile };
      return profile;
    } catch (_) {
      const profile = { ...core.EMPTY_PROFILE_INFO };
      profilePageCache = { handle, at: now, profile };
      return profile;
    }
  }

  function collectSummaryFromDom() {
    if (!isLivePage()) return "";
    const candidates = [...document.querySelectorAll('[data-e2e*="summary" i],[class*="summary" i]')].filter(isVisible);
    for (const element of candidates) {
      const value = visibleText(element);
      if (!/(zusammenfassung|summary)/i.test(value) || /meldung wird überprüft/i.test(value)) continue;
      const text = value.replace(/^(?:zusammenfassung|summary)\s*[:\-]?\s*/i, "").trim();
      if (text.length >= 12) return text.slice(0, 4000);
    }
    return "";
  }

  function isLivePage() {
    return /^\/@[^/]+\/live\/?$/i.test(location.pathname) || /^\/embed\/live\/@?[^/?#]+\/?$/i.test(location.pathname);
  }

  function currentHandle() {
    const path = decodeURIComponent(location.pathname);
    return path.match(/^\/@([^/]+)\/live\/?$/i)?.[1] || path.match(/^\/embed\/live\/@?([^/?#]+)\/?$/i)?.[1] || "";
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
    if (isLivePage() && (options.refreshProfile || !collected.profileInfo?.followerCount)) {
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
      liveStats: collectDomLiveStats(),
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
    return { activated: false, reason: "" };
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

  function playerToggleControl() {
    const selectors = [
      '[data-e2e="play-icon"]',
      '[data-e2e="pause-icon"]',
      '[data-testid="control-container"][role="button"]',
      '[data-e2e="play-icon-id"]',
      '[data-e2e="pause-icon-id"]',
      '[aria-label*="play" i]',
      '[aria-label*="pause" i]',
      '[aria-label*="abspielen" i]',
      '[aria-label*="paus" i]'
    ];
    const controls = [...document.querySelectorAll(selectors.join(","))]
      .filter(isVisible)
      .map(interactiveTarget);
    return smallestElement([...new Set(controls)]);
  }

  function clickPlayerControl(control) {
    if (!control) return false;
    const target = interactiveTarget(control);
    if ((target instanceof HTMLButtonElement && target.disabled) || target.getAttribute("aria-disabled") === "true") {
      target.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true, view: window }));
    } else {
      target.click();
    }
    return true;
  }

  function revealPlayerControls() {
    const surface = primaryVideo()?.closest('[data-e2e*="player" i]')
      || document.querySelector('[data-e2e="control-bar-id-v2"]')?.parentElement
      || document.documentElement;
    for (const type of ["pointermove", "mousemove"]) {
      surface.dispatchEvent(new MouseEvent(type, { bubbles: true, cancelable: false, view: window }));
    }
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

  function clearFallbackLimiter(video) {
    if (!fallbackLimiter?.video || (video && fallbackLimiter.video !== video)) return;
    if (fallbackLimiter.enforce) fallbackLimiter.video.removeEventListener("volumechange", fallbackLimiter.enforce);
    fallbackLimiter = null;
  }

  async function resumeAudioContext(pipeline) {
    if (!pipeline?.context || pipeline.context.state !== "suspended") return;
    await pipeline.context.resume().catch((error) => {
      debug("audio-context-resume-deferred", { error: String(error?.message || error).slice(0, 300) });
    });
  }

  function attachAudioResumeHandlers(pipeline) {
    const resume = () => resumeAudioContext(pipeline);
    pipeline.video.addEventListener("play", resume);
    pipeline.video.addEventListener("volumechange", resume);
    document.addEventListener("pointerdown", resume, { capture: true, passive: true });
    pipeline.cleanupResumeHandlers = () => {
      pipeline.video.removeEventListener("play", resume);
      pipeline.video.removeEventListener("volumechange", resume);
      document.removeEventListener("pointerdown", resume, { capture: true });
    };
  }

  function wireAudioPipeline(video, context, source, captureMode = false, stream = null) {
    const compressor = context.createDynamicsCompressor();
    const makeup = context.createGain();
    const outputGain = context.createGain();
    const analyser = context.createAnalyser();
    analyser.fftSize = 2048;
    compressor.threshold.value = 0;
    compressor.knee.value = 0;
    compressor.ratio.value = 1;
    compressor.attack.value = 0.003;
    compressor.release.value = 0.25;
    makeup.gain.value = 1;
    outputGain.gain.value = captureMode && video.muted ? 0 : Number(video.volume || 1);
    source.connect(compressor).connect(makeup).connect(analyser).connect(outputGain).connect(context.destination);
    const pipeline = {
      video, context, source, compressor, makeup, outputGain, analyser,
      captureMode, stream, enabled: false, thresholdDbfs: -6,
      userVolume: Number(video.volume || 1), userMuted: Boolean(video.muted)
    };
    if (captureMode) {
      pipeline.restoreVolume = pipeline.userVolume;
      pipeline.restoreMuted = pipeline.userMuted;
      video.muted = true;
    }
    attachAudioResumeHandlers(pipeline);
    return pipeline;
  }

  async function destroyAudioPipeline(pipeline) {
    if (!pipeline) return;
    pipeline.cleanupResumeHandlers?.();
    if (pipeline.captureMode && pipeline.video) {
      pipeline.video.volume = Math.max(0, Math.min(1, Number(pipeline.userVolume ?? pipeline.restoreVolume ?? 1)));
      pipeline.video.muted = Boolean(pipeline.userMuted ?? pipeline.restoreMuted);
      pipeline.video.dispatchEvent(new Event("volumechange", { bubbles: true }));
    }
    pipeline.stream?.getTracks?.().forEach((track) => track.stop());
    await pipeline.context?.close?.().catch(() => {});
  }

  function setPipelineVolume(pipeline, volume) {
    pipeline.userVolume = volume;
    if (volume > 0) pipeline.userMuted = false;
    pipeline.outputGain.gain.value = pipeline.userMuted ? 0 : volume;
  }

  function setPipelineMuted(pipeline, muted) {
    pipeline.userMuted = Boolean(muted);
    if (!pipeline.userMuted && pipeline.userVolume <= 0) pipeline.userVolume = Math.max(0.01, Number(pipeline.restoreVolume || 1));
    pipeline.outputGain.gain.value = pipeline.userMuted ? 0 : pipeline.userVolume;
  }

  async function ensureAudioPipeline(video) {
    if (audioPipeline?.video === video) {
      await resumeAudioContext(audioPipeline);
      return audioPipeline;
    }
    if (audioPipeline?.context) await destroyAudioPipeline(audioPipeline);
    audioPipeline = null;
    const AudioContextClass = globalThis.AudioContext || globalThis.webkitAudioContext;
    if (!AudioContextClass) throw new Error("Die Web-Audio-API ist in diesem Browser nicht verfügbar.");
    let context = new AudioContextClass();
    try {
      audioPipeline = wireAudioPipeline(video, context, context.createMediaElementSource(video));
    } catch (sourceError) {
      await context.close().catch(() => {});
      const captureStream = video.captureStream || video.mozCaptureStream;
      if (typeof captureStream !== "function") throw sourceError;
      const stream = captureStream.call(video);
      if (!stream?.getAudioTracks?.().length) throw sourceError;
      context = new AudioContextClass();
      audioPipeline = wireAudioPipeline(video, context, context.createMediaStreamSource(stream), true, stream);
      debug("limiter-capture-fallback", { reason: String(sourceError?.message || sourceError).slice(0, 300) });
    }
    await resumeAudioContext(audioPipeline);
    return audioPipeline;
  }

  function dismissTimedLiveInterruption() {
    if (!isLivePage() || Date.now() - popupGuardStartedAt < POPUP_GUARD_GRACE_MS) return;
    const dialogs = [...document.querySelectorAll('[role="dialog"],[aria-modal="true"]')].filter(isVisible);
    const interruption = dialogs.find((dialog) => /(?:bei tiktok anmelden|log in to tiktok|sign in to tiktok|vollständige[sn]? erlebnis|full experience|continue watching|keep watching|watch more|weiter ansehen|weiterschauen|weiter schauen|app öffnen|open app|in app ansehen|view in app)/i.test(visibleText(dialog)));
    if (!interruption) return;
    const action = [...document.querySelectorAll('button,[role="button"],a')].find((button) => {
      if (!isVisible(button)) return false;
      const label = `${button.getAttribute("aria-label") || ""} ${button.getAttribute("title") || ""} ${visibleText(button)}`.trim();
      return /(?:^(?:schließen|close|x)$|not now|maybe later|später|nicht jetzt|continue watching|keep watching|weiter ansehen|weiterschauen|weiter schauen)/i.test(label);
    });
    if (action) {
      action.click();
      const video = primaryVideo();
      if (video?.paused && !video.ended && !video.error) video.play().catch(() => {});
      debug("timed-live-interruption-dismissed", { label: visibleText(interruption).slice(0, 120) });
    }
  }

  function timedLiveInterruptionReason() {
    if (!isLivePage() || Date.now() - popupGuardStartedAt < POPUP_GUARD_GRACE_MS) return "";
    const dialogs = [...document.querySelectorAll('[role="dialog"],[aria-modal="true"]')].filter(isVisible);
    const interruption = dialogs.find((dialog) => /(?:bei tiktok anmelden|log in to tiktok|sign in to tiktok|vollständige[sn]? erlebnis|full experience|continue watching|keep watching|watch more|weiter ansehen|weiterschauen|weiter schauen|app öffnen|open app|in app ansehen|view in app)/i.test(visibleText(dialog)));
    if (interruption) return "login-dialog";
    if (/anmelden|log in|login|sign in/i.test(document.title || "") && !primaryVideo()) return "login-page-no-video";
    return "";
  }

  function quickRecoverReason() {
    if (!quickRecoverEnabled || !tabActive || !isLivePage()) return "";
    const video = primaryVideo();
    if (video && !video.error && !video.ended && video.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA) {
      quickRecoverArmed = true;
    }
    if (!quickRecoverArmed) return "";
    const interruption = timedLiveInterruptionReason();
    if (interruption) return interruption;
    if (!video) return "";
    if (video.error) return "video-error";
    if (video.ended) return "video-ended";
    if (Date.now() - popupGuardStartedAt < POPUP_GUARD_GRACE_MS) return "";
    if (video.paused) return "video-paused";
    if (video.readyState < HTMLMediaElement.HAVE_CURRENT_DATA) return "video-not-ready";
    return "";
  }

  async function tryQuickRecover(reason) {
    dismissTimedLiveInterruption();
    quickRecoverFailures += 1;
    if (quickRecoverFailures < 1 || Date.now() - lastQuickRecoverAt < QUICK_RECOVER_RELOAD_COOLDOWN_MS) return;
    quickRecoverFailures = 0;
    lastQuickRecoverAt = Date.now();
    chrome.runtime.sendMessage({ type: "TLC_QUICK_RECOVER", reason }).catch(() => {});
  }

  function monitorQuickRecover() {
    setInterval(() => {
      const reason = quickRecoverReason();
      if (!reason) {
        quickRecoverFailures = 0;
        return;
      }
      tryQuickRecover(reason).catch((error) => debug("quick-recover-error", { reason, error: String(error?.message || error).slice(0, 300) }));
    }, QUICK_RECOVER_INTERVAL_MS);
  }

  function pushFullscreenState(reason) {
    const fullscreenActive = Boolean(document.fullscreenElement);
    if (fullscreenWasActive && !fullscreenActive) {
      chrome.runtime.sendMessage({ type: "TLC_FULLSCREEN_EXITED", reason }).catch(() => {});
    }
    fullscreenWasActive = fullscreenActive;
    setTimeout(() => pushPlayerState(reason), 50);
  }

  function pushPlayerState(reason) {
    chrome.runtime.sendMessage({ type: "TLC_PLAYER_STATE_PUSH", reason, playerState: getPlayerState() }).catch(() => {});
  }

  function playerSurface() {
    return primaryVideo()?.closest('[data-e2e*="player" i]')
      || document.querySelector('[data-e2e="control-bar-id-v2"]')?.parentElement
      || document.querySelector("main")
      || document.body
      || document.documentElement;
  }

  function mediaFallbackCandidates(media = []) {
    const usable = (media || []).filter((item) => item?.url && !item.audioOnly);
    return usable.sort((a, b) => {
      const protocolScore = (item) => /hls/i.test(item.protocol || "") ? 0 : /flv/i.test(item.protocol || "") ? 1 : 2;
      const height = (item) => Number(item.height || String(item.quality || "").match(/\d+/)?.[0] || 0);
      return protocolScore(a) - protocolScore(b) || height(b) - height(a);
    });
  }

  function setMediaFallbackStatus(text) {
    const status = document.getElementById("tlc-media-fallback-status");
    if (status) status.textContent = text;
  }

  function ensureMediaFallbackVideo() {
    let holder = document.getElementById("tlc-media-fallback");
    if (!holder) {
      holder = document.createElement("div");
      holder.id = "tlc-media-fallback";
      holder.style.cssText = "position:absolute;inset:0;z-index:2147483646;display:grid;grid-template-rows:minmax(0,1fr) auto;background:#000;";
      const video = document.createElement("video");
      video.controls = true;
      video.autoplay = true;
      video.playsInline = true;
      video.muted = false;
      video.style.cssText = "width:100%;height:100%;object-fit:contain;background:#000;";
      const status = document.createElement("div");
      status.id = "tlc-media-fallback-status";
      status.style.cssText = "padding:10px 14px;color:#fff;background:rgba(0,0,0,.82);font:600 13px system-ui,sans-serif;text-align:center;";
      status.textContent = "VLC Ersatz wird geprüft.";
      holder.append(video, status);
    }
    const surface = playerSurface();
    const style = getComputedStyle(surface);
    if (style.position === "static") surface.style.position = "relative";
    if (holder.parentElement !== surface) surface.append(holder);
    return holder.querySelector("video");
  }

  function tryMediaUrl(video, item) {
    return new Promise((resolve) => {
      let finished = false;
      const done = (ok, reason = "") => {
        if (finished) return;
        finished = true;
        clearTimeout(timeout);
        video.removeEventListener("canplay", onCanPlay);
        video.removeEventListener("playing", onPlaying);
        video.removeEventListener("error", onError);
        resolve({ ok, item, reason });
      };
      const onCanPlay = () => done(true);
      const onPlaying = () => done(true);
      const onError = () => done(false, video.error?.message || "media-error");
      const timeout = setTimeout(() => done(false, "timeout"), 4500);
      video.addEventListener("canplay", onCanPlay);
      video.addEventListener("playing", onPlaying);
      video.addEventListener("error", onError);
      video.src = item.url;
      video.load();
      video.play().catch(() => {});
    });
  }

  async function playMediaFallback(media = []) {
    const candidates = mediaFallbackCandidates(media);
    const video = ensureMediaFallbackVideo();
    if (!candidates.length) {
      setMediaFallbackStatus("Keine Video-Links erkannt.");
      return { activated: false, action: "play-vlc-source", reason: "Keine Video-Links erkannt.", playerState: getPlayerState() };
    }
    setMediaFallbackStatus(`Prüfe ${candidates.length} Video-Link(s).`);
    const failures = [];
    for (const item of candidates) {
      setMediaFallbackStatus(`Prüfe ${item.quality || "Video"} ${item.protocol || ""}.`.trim());
      const result = await tryMediaUrl(video, item);
      if (result.ok) {
        setMediaFallbackStatus(`${item.quality || "Video"} wird abgespielt.`);
        debug("media-fallback", { protocol: item.protocol, quality: item.quality, hostname: item.hostname || "" });
        return { activated: true, action: "play-vlc-source", media: { protocol: item.protocol, quality: item.quality, hostname: item.hostname || "" }, playerState: getPlayerState() };
      }
      failures.push(`${item.quality || "?"} ${item.protocol || "?"}: ${result.reason}`);
    }
    const reason = `Kein Link konnte im Browser-Player abgespielt werden. ${failures.slice(0, 3).join("; ")}`;
    setMediaFallbackStatus(reason);
    return { activated: false, action: "play-vlc-source", reason, playerState: getPlayerState() };
  }

  async function configureLimiter(video, enabled, thresholdDbfs) {
    const threshold = Math.max(-30, Math.min(-1, Number(thresholdDbfs ?? -6)));
    clearFallbackLimiter(video);
    if (!enabled && audioPipeline?.video === video) {
      const pipeline = audioPipeline;
      pipeline.enabled = false;
      pipeline.thresholdDbfs = threshold;
      pipeline.compressor.threshold.value = 0;
      pipeline.compressor.knee.value = 0;
      pipeline.compressor.ratio.value = 1;
      pipeline.makeup.gain.value = 1;
      if (pipeline.captureMode) {
        await destroyAudioPipeline(pipeline);
        audioPipeline = null;
      }
      debug("limiter", { mode: "off", enabled: false, threshold });
      return { enabled: false, thresholdDbfs: threshold };
    }
    try {
      const pipeline = await ensureAudioPipeline(video);
      pipeline.enabled = Boolean(enabled);
      pipeline.thresholdDbfs = threshold;
      pipeline.compressor.threshold.value = pipeline.enabled ? threshold : 0;
      pipeline.compressor.knee.value = pipeline.enabled ? 1 : 0;
      pipeline.compressor.ratio.value = pipeline.enabled ? 20 : 1;
      pipeline.makeup.gain.value = pipeline.enabled ? core.limiterMakeupCompensation(threshold, 20) : 1;
      debug("limiter", { mode: "compressor", enabled: pipeline.enabled, threshold });
      return pipeline;
    } catch (error) {
      fallbackLimiter = { video, enabled: false, thresholdDbfs: threshold, error: String(error?.message || error).slice(0, 300) };
      debug("limiter-unavailable", { threshold, enabled: Boolean(enabled), error: fallbackLimiter.error });
      return fallbackLimiter;
    }
  }

  function getPlayerState() {
    const video = primaryVideo();
    const toggleControl = playerToggleControl();
    const connected = connectedStreamState();
    const pipeline = audioPipeline?.video === video ? audioPipeline : null;
    const volume = pipeline?.captureMode ? Number(pipeline.userVolume ?? 1) : Number(video?.volume ?? 1);
    return {
      available: Boolean(video || toggleControl),
      videoAvailable: Boolean(video),
      controlAvailable: Boolean(toggleControl),
      playing: Boolean(video && !video.paused),
      muted: Boolean(video && (pipeline?.captureMode ? pipeline.userMuted || pipeline.userVolume === 0 : video.muted || video.volume === 0)),
      volume,
      volumePercent: Math.round(volume * 100),
      volumeGainDb: volumeGainDb(volume),
      peakDbfs: currentPeakDbfs(),
      limiterEnabled: Boolean(pipeline?.enabled),
      limiterMode: pipeline?.enabled ? "Kompressor" : null,
      limiterStrength: core.limiterDbfsToStrength(pipeline ? pipeline.thresholdDbfs : -6),
      limiterThresholdDbfs: pipeline ? pipeline.thresholdDbfs : -6,
      limiterReductionDb: pipeline ? Math.round(Number(pipeline.compressor.reduction || 0) * 10) / 10 : 0,
      limiterError: fallbackLimiter?.video === video ? fallbackLimiter.error : null,
      ...connected,
      elapsedText: elapsedText(),
      pipActive: Boolean(video && document.pictureInPictureElement === video),
      fullscreenActive: Boolean(document.fullscreenElement),
      updatedAtUtc: new Date().toISOString()
    };
  }

  async function playerAction(action, payload = {}) {
    let video = primaryVideo();
    let toggleControl = playerToggleControl();
    if (action === "play-vlc-source") return playMediaFallback(payload.media || []);
    if (!video && action !== "toggle-play") {
      return { activated: false, action, reason: "Kein TikTok-Videoelement gefunden.", playerState: getPlayerState() };
    }
    try {
      if (action === "toggle-play") {
        if (!toggleControl) {
          revealPlayerControls();
          await sleep(100);
          toggleControl = playerToggleControl();
        }
        if (!video) {
          if (!clickPlayerControl(toggleControl)) {
            return { activated: false, action, reason: "TikToks Play/Pause-Steuerung wurde nicht gefunden.", playerState: getPlayerState() };
          }
          video = await waitFor(primaryVideo, 1200);
          if (video?.paused) await video.play().catch(() => {});
          await sleep(250);
          if (!video || video.paused) {
            return { activated: false, action, reason: "TikToks Play-Steuerung wurde ausgeführt, der Stream startete jedoch nicht.", playerState: getPlayerState() };
          }
        } else {
          const stalled = Boolean(video.ended || video.error || video.readyState < 2);
          if (!video.paused && !stalled) {
            video.pause();
          } else {
            let directError = null;
            try {
              if (video.ended && Number.isFinite(video.duration)) video.currentTime = Math.max(0, video.duration - 0.1);
              await video.play();
            } catch (error) {
              directError = error;
            }
            await sleep(250);
            if (video.paused || video.ended || video.error || video.readyState < 2) {
              clickPlayerControl(toggleControl);
              await sleep(350);
            }
            if (video.paused || video.ended || video.error || video.readyState < 2) {
              const replay = document.querySelector('[data-e2e="replay-icon"]');
              if (replay) {
                interactiveTarget(replay).click();
                await sleep(350);
                await video.play().catch(() => {});
              }
            }
            if (video.paused || video.ended || video.error || video.readyState < 2) {
              const message = String(directError?.message || "Der unterbrochene Stream ließ sich im TikTok-Player nicht starten.");
              return { activated: false, action, reason: message.slice(0, 500), playerState: getPlayerState() };
            }
          }
        }
      } else if (action === "replay") {
        const replay = document.querySelector('[data-e2e="replay-icon"]');
        if (!replay) return { activated: false, action, reason: "TikToks Player-Neuladen wurde nicht gefunden.", playerState: getPlayerState() };
        replay.click();
      } else if (action === "toggle-mute") {
        if (audioPipeline?.video === video && audioPipeline.captureMode) {
          setPipelineMuted(audioPipeline, !(audioPipeline.userMuted || audioPipeline.userVolume === 0));
          video.dispatchEvent(new Event("volumechange", { bubbles: true }));
          await resumeAudioContext(audioPipeline);
          return { activated: true, action, playerState: getPlayerState() };
        }
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
        clearFallbackLimiter(video);
        if (audioPipeline?.video === video && audioPipeline.captureMode) {
          setPipelineVolume(audioPipeline, volume);
          await resumeAudioContext(audioPipeline);
        } else {
          video.volume = volume;
          if (volume > 0) video.muted = false;
        }
        video.dispatchEvent(new Event("volumechange", { bubbles: true }));
      } else if (action === "set-limiter") {
        const limiter = await configureLimiter(video, payload.enabled, payload.thresholdDbfs);
        if (payload.enabled && !limiter?.enabled) {
          return { activated: false, action, reason: limiter?.error || "Pegelschutz konnte nicht aktiviert werden.", playerState: getPlayerState() };
        }
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
    try {
      if (!(element instanceof Element) || !element.isConnected) return null;
      const owner = element.querySelector('[data-e2e="message-owner-name"]');
      if (!owner) return null;
      const author = visibleText(owner);
      if (!author) return null;
      const pieces = [];
      const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT);
      let node;
      while ((node = walker.nextNode())) {
        if (!owner.isConnected || !element.isConnected) return null;
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
      return { author, content, contentLanguage: document.documentElement?.lang || "", source: "dom", receivedAtUtc: new Date().toISOString() };
    } catch (error) {
      debug("dom-chat-scan-error", { error: String(error?.message || error).slice(0, 300) });
      return null;
    }
  }

  function scanDomChat() {
    for (const element of [...document.querySelectorAll('[data-e2e="chat-message"]')].slice(-100)) {
      try {
        const raw = visibleText(element);
        if (!raw || chatNodeText.get(element) === raw) continue;
        chatNodeText.set(element, raw);
        const chatMessage = extractDomChat(element);
        if (chatMessage?.content) chrome.runtime.sendMessage({ type: "TLC_CHAT_MESSAGE", chatMessage }).catch(() => {});
      } catch (error) {
        debug("dom-chat-loop-error", { error: String(error?.message || error).slice(0, 300) });
      }
    }
  }

  function scanDomGifts() {
    const candidates = [...document.querySelectorAll('[data-e2e*="gift" i],[data-e2e*="message" i]')].slice(-150);
    for (const element of candidates) {
      const raw = visibleText(element);
      if (!raw || giftNodeText.get(element) === raw || !/(?:gesendet|sent)(?:\s*x\s*\d+)?/i.test(raw)) continue;
      giftNodeText.set(element, raw);
      const countMatch = raw.match(/(?:gesendet|sent)\s*x\s*(\d+)/i) || raw.match(/\bhat\s+(\d+)\s+.+?\s+gesendet/i) || raw.match(/\bsent\s+(\d+)\s+.+/i);
      const owner = visibleText(element.querySelector('[data-e2e="message-owner-name"]'));
      const authorMatch = raw.match(/^(.+?)\s+(?:hat\s+.+?\s+gesendet|sent\s+.+?)(?:\s*x\s*\d+)?/i);
      const giftNameMatch = raw.match(/\bhat\s+\d+\s+(.+?)\s+gesendet/i) || raw.match(/\bhat\s+(.+?)\s+gesendet(?:\s*x\s*\d+)?/i);
      const author = owner || authorMatch?.[1] || "";
      if (!author) continue;
      chrome.runtime.sendMessage({
        type: "TLC_GIFT_MESSAGE",
        giftMessage: {
          author,
          giftName: giftNameMatch?.[1] || "",
          repeatCount: countMatch?.[1] || "1",
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
    if (!tabActive) return;
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
    if (message.type === "TLC_SET_TAB_ACTIVE") {
      tabActive = Boolean(message.enabled);
      debugEnabled = Boolean(message.debugEnabled);
      quickRecoverEnabled = Boolean(message.quickRecoverEnabled);
      chatSourceOnly = Boolean(message.chatSourceOnly);
      if (tabActive) startTabRuntime();
      sendResponse({ enabled: tabActive });
      return false;
    }
    if (message.type === "TLC_QUICK_RECOVER_CONFIG") {
      quickRecoverEnabled = Boolean(message.enabled);
      sendResponse({ enabled: quickRecoverEnabled });
      return false;
    }
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

  function startTabRuntime() {
    if (!tabActive || tabRuntimeStarted) return;
    if (!document.documentElement) {
      document.addEventListener("DOMContentLoaded", startTabRuntime, { once: true });
      return;
    }
    tabRuntimeStarted = true;
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
    new MutationObserver(() => {
      try {
        scanDomChat();
        scanDomGifts();
        scanDomCaptions();
        dismissTimedLiveInterruption();
        scheduleScan(1500);
      } catch (error) {
        debug("dom-observer-error", { error: String(error?.message || error).slice(0, 300) });
      }
    }).observe(document.documentElement, { childList: true, subtree: true });
    scanDomChat();
    scanDomGifts();
    scanDomCaptions();
    setInterval(dismissTimedLiveInterruption, QUICK_RECOVER_INTERVAL_MS);
    monitorQuickRecover();
    for (const eventName of ["fullscreenchange", "visibilitychange", "focus", "pageshow"]) {
      window.addEventListener(eventName, () => pushFullscreenState(eventName));
    }
    scheduleScan(50);
    chrome.storage.local.get("tlc-settings").then(({ "tlc-settings": settings = {} }) => {
      quickRecoverEnabled = Boolean(settings.quickRecoverEnabled);
      const apply = async () => {
        const video = primaryVideo();
        if (!video) {
          setTimeout(apply, 500);
          return;
        }
        const volume = Math.max(0, Math.min(100, Number(settings.playerVolume ?? 100))) / 100;
        if (chatSourceOnly) {
          video.volume = 0;
          video.muted = true;
        } else {
          video.volume = volume;
          if (volume > 0) video.muted = false;
          if (settings.limiterEnabled) await configureLimiter(video, true, core.limiterStrengthToDbfs(settings.limiterStrength ?? 30));
        }
      };
      apply().catch((error) => debug("audio-settings-restore", { error: String(error?.message || error).slice(0, 300) }));
    }).catch(() => {});
  }

  chrome.runtime.sendMessage({ type: "TLC_GET_TAB_ACTIVATION" }).then((response) => {
    tabActive = Boolean(response?.enabled);
    if (!tabActive) return;
    if (document.documentElement) startTabRuntime();
    else document.addEventListener("DOMContentLoaded", startTabRuntime, { once: true });
  }).catch(() => {});
})();
