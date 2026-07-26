"use strict";

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const vm = require("vm");

const root = path.resolve(__dirname, "..");
const extension = path.join(root, "browser-extension");
const manifest = JSON.parse(fs.readFileSync(path.join(extension, "manifest.json"), "utf8"));
const core = require(path.join(extension, "content-core.js"));
const proto = require(path.join(extension, "proto-main.js"));
const mobileBridge = fs.readFileSync(path.join(root, "mobile-shared", "webview-bridge.js"), "utf8");

function concat(...chunks) {
  const size = chunks.reduce((total, chunk) => total + chunk.length, 0);
  const out = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) { out.set(chunk, offset); offset += chunk.length; }
  return out;
}

function varint(value) {
  let current = BigInt(value);
  const bytes = [];
  do {
    let byte = Number(current & 0x7fn);
    current >>= 7n;
    if (current) byte |= 0x80;
    bytes.push(byte);
  } while (current);
  return Uint8Array.from(bytes);
}

function bytesField(number, value) {
  const body = typeof value === "string" ? new TextEncoder().encode(value) : value;
  return concat(varint((BigInt(number) << 3n) | 2n), varint(body.length), body);
}

function intField(number, value) {
  return concat(varint(BigInt(number) << 3n), varint(value));
}

assert.strictEqual(manifest.manifest_version, 3);
assert.strictEqual(manifest.version, "0.7.1");
assert.ok(manifest.permissions.includes("sidePanel"));
assert.ok(manifest.permissions.includes("webRequest"));
assert.ok(manifest.permissions.includes("tabCapture"));
assert.ok(manifest.host_permissions.includes("http://127.0.0.1/*"));
assert.ok(manifest.host_permissions.includes("http://localhost/*"));
assert.ok(!manifest.permissions.includes("cookies"));
assert.ok(!manifest.permissions.includes("webRequestBlocking"));
assert.ok(mobileBridge.includes('location.hostname !== "www.tiktok.com"'));
assert.ok(!mobileBridge.includes("document.cookie"));

for (const relative of [
  manifest.background.service_worker,
  manifest.side_panel.default_path,
  ...manifest.content_scripts.flatMap((item) => item.js)
]) {
  assert.ok(fs.existsSync(path.join(extension, relative)), `Missing manifest file: ${relative}`);
}

const scripts = fs.readdirSync(extension).filter((name) => name.endsWith(".js"));
for (const name of scripts) {
  const source = fs.readFileSync(path.join(extension, name), "utf8");
  new vm.Script(source, { filename: name });
  assert.ok(!/\beval\s*\(/.test(source), `${name} contains eval()`);
  assert.ok(!/new\s+Function\s*\(/.test(source), `${name} contains new Function()`);
  assert.ok(!/\.innerHTML\s*=/.test(source), `${name} assigns innerHTML`);
}

const metadata = {
  room: {
    caption_info: { open: true, support_lang: ["de", "en"], show_type: 1 },
    stream_data: "{\"pull\":\"https:\\/\\/pull-flv-f77.example.tiktokcdn.com\\/stage\\/stream_hd.flv?expire=1\\u0026sign=abc\",\"hls\":\"https:\\/\\/pull-hls.example.tiktokcdn-eu.com\\/stage\\/stream_720p.m3u8?sign=xyz\"}"
  }
};
const inspected = core.inspectMetadata(metadata);
assert.strictEqual(inspected.captionInfo.present, true);
assert.strictEqual(inspected.captionInfo.open, true);
assert.deepStrictEqual(inspected.captionInfo.supportLang, ["de", "en"]);
assert.strictEqual(inspected.media.length, 2);
assert.ok(inspected.media.some((item) => item.protocol === "FLV" && item.quality === "HD"));
assert.ok(inspected.media.some((item) => item.protocol === "HLS" && item.quality === "720p"));
assert.strictEqual(core.classifyMediaUrl("https://evil.example/stream.flv"), null);
assert.strictEqual(core.QUALITY_LABELS.auto, "Automatisch");
assert.strictEqual(core.sanitizeChatText("Hallo 😊 Welt ❤️"), "Hallo Welt");
assert.strictEqual(core.sanitizeChatText("@Nutzer 👍🏽 bleibt hier"), "@Nutzer bleibt hier");
assert.strictEqual(core.wordCount("Hallo 😊 schöne Welt"), 3);
assert.strictEqual(core.teamSuffixCandidate("Miimii tmm"), "tmm");
assert.strictEqual(core.teamSuffixCandidate("Ben"), "");
assert.strictEqual(core.teamSuffixCandidate("das ist gut"), "gut");
assert.strictEqual(core.contentHasToken("@Honey tmm wo is mein Tee?", "tmm"), true);
assert.strictEqual(core.stripTeamTag("@Honey tmm wo is mein Tee?", "tmm"), "@Honey wo is mein Tee?");
assert.strictEqual(core.stripTeamTag("das ist gut", "tmm"), "das ist gut");
assert.strictEqual(core.shortenNickname("Anja Schaarschmidt89"), "Anja");
assert.strictEqual(core.shortenNickname("Team Kimm"), "Team Kimm");
assert.strictEqual(core.shortenNickname("Blitzerbiest"), "Blitzerbiest");
assert.strictEqual(core.shortenNickname("Traumtänzer.der.Nächte"), "Traumtänzer");
assert.strictEqual(core.shortenNickname("Vanny_GioPrimetv"), "Vanny");
assert.strictEqual(core.shortenNickname("Die Löwin"), "Löwin");
assert.strictEqual(core.shortenNickname("liane15"), "liane");
assert.strictEqual(core.shortenNickname("MKU Maskenaufsicht"), "Maskenaufsicht");
assert.strictEqual(core.shortenNickname("Butterfly 004"), "Butterfly");
assert.strictEqual(core.spokenNickname("user572838499281727393816181"), "user572");
assert.strictEqual(core.spokenNickname("Rebecca № 2 💕"), "Rebecca");
assert.strictEqual(core.collapseLaughter("hahahahahahhhhahhhaaaa Gott du Plemmi"), "haha Gott du Plemmi");
assert.strictEqual(core.resolveSpeechLanguage("auto", "de"), "de-DE");
assert.strictEqual(core.resolveSpeechLanguage("en-US", "de"), "en-US");
assert.strictEqual(core.composeSpeechText({ author: "Miimii tmm", content: "@Stivinho danke" }, { teamTag: "tmm" }), "Miimii sagt zu Stivinho danke");
assert.strictEqual(core.composeSpeechText({ author: "Blitzerbiest", content: "@Honey tmm wo is mein Tee ?" }, { teamTag: "tmm" }), "Blitzerbiest fragt Honey wo is mein Tee");
assert.strictEqual(core.composeSpeechText({ author: "Miimii", content: "@ Stivinho danke" }, { speakNames: false }), "Stivinho danke");
assert.strictEqual(core.composeSpeechText({ author: "Anja Schaarschmidt89", content: "Guten Morgen" }, { shortenNames: true }), "Anja sagt Guten Morgen");
assert.strictEqual(core.composeSpeechText({ author: "Mia", content: "Hallo @" }), "Mia sagt Hallo @");
assert.strictEqual(core.gameEventSpeech({ rawText: "Jacky hat 1 Boosterhandschuh gesendet" }), "Booster wurde gesetzt");
assert.strictEqual(core.gameEventSpeech({ rawText: "Jacky hat Rose gesendet x 1" }), "");
assert.strictEqual(core.composeSpeechText({ author: "System", content: "Booster wurde gesetzt", systemSpeechText: "Booster wurde gesetzt" }), "Booster wurde gesetzt");
assert.strictEqual(core.shouldFilterGameModeSpeech(
  { author: "A", content: "Jacky", receivedAtUtc: "2026-07-26T10:00:10.000Z" },
  { jacky: { name: "🫶Jacky🫶", displayId: "jacky" } },
  [
    { content: "Jacky", receivedAtUtc: "2026-07-26T10:00:00.000Z" },
    { content: "🫶 Jacky 🫶", receivedAtUtc: "2026-07-26T10:00:05.000Z" }
  ]
), true);
assert.strictEqual(core.shouldFilterGameModeSpeech(
  { author: "A", content: "@Jacky danke", receivedAtUtc: "2026-07-26T10:00:10.000Z" },
  { jacky: { name: "Jacky", displayId: "jacky" } },
  [{ content: "@Jacky danke", receivedAtUtc: "2026-07-26T10:00:05.000Z" }]
), false);
assert.strictEqual(core.composeSpeechText({ author: "user572838499281727393816181", content: "hahahahahahhhhahhhaaaa bald" }), "user572 sagt haha bald");
assert.strictEqual(core.composeSpeechText({ author: "deroy", content: "@user572838499281727393816181 bald bist du nur noch ein sohn" }), "deroy sagt zu user572 bald bist du nur noch ein sohn");
assert.strictEqual(core.composeSpeechText({ author: "Rebecca № 2 💕", content: "@Vanny_GioPrimetv hallo" }, { shortenNames: true }), "Rebecca sagt zu Vanny hallo");
let team = core.accumulateTeamEvidence({}, "Miimii tmm", "Teilt den Stream", []);
assert.strictEqual(team.teamTag, "");
team = core.accumulateTeamEvidence(team.evidence, "Honey tmm", "wo ist mein Tee?", ["Teilt den Stream"]);
assert.strictEqual(team.teamTag, "tmm");
team = core.accumulateTeamEvidence({}, "Miimii tmm", "danke", []);
team = core.accumulateTeamEvidence(team.evidence, "Stivinho", "tmm hilft", ["danke"]);
assert.strictEqual(team.teamTag, "tmm");
assert.strictEqual(core.accumulateTeamEvidence({}, "Miimii tmm", "tmm danke", []).teamTag, "tmm");
assert.strictEqual(core.accumulateTeamEvidence({}, "Ben", "Ben ist da", []).teamTag, "");
assert.strictEqual(core.streamIdentityChanged({ handle: "demo", roomId: "1" }, { handle: "demo", roomId: "1" }), false);
assert.strictEqual(core.streamIdentityChanged({ handle: "demo", roomId: "1" }, { handle: "demo", roomId: "2" }), true);
assert.strictEqual(core.streamIdentityChanged({ handle: "demo", roomId: "" }, { handle: "other", roomId: "" }), true);
assert.strictEqual(core.sameParticipant({ name: "Anja Schaarschmidt89" }, { nickname: "Anja Schaarschmidt89" }), true);
assert.strictEqual(core.sameParticipant({ userId: "42", name: "Anja" }, { userId: "42", name: "A. Schaarschmidt" }), true);
assert.deepStrictEqual(core.sortParticipants([
  { name: "Zed", messageCount: 2, wordCount: 7 },
  { name: "Ada", messageCount: 3, wordCount: 2 },
  { name: "Ben", messageCount: 2, wordCount: 9 }
]).map((item) => item.name), ["Ada", "Ben", "Zed"]);
assert.deepStrictEqual(
  core.mergeParticipantRecord({ userId: null, displayId: "", name: "Anna", messageCount: 2 }, { userId: "42", displayId: "anna_live", receivedAtUtc: "2026-07-18T10:00:00.000Z" }, "Anna", { wordCount: 7 }),
  { userId: "42", displayId: "anna_live", name: "Anna", messageCount: 2, wordCount: 7, giftEventCount: 0, giftItemCount: 0, lastSeenAtUtc: "2026-07-18T10:00:00.000Z" }
);

const profileAndSummary = core.inspectMetadata({
  live_ai_summary_ui: { vid: "v2" },
  userInfo: {
    uniqueId: "demo",
    nickname: "Demo",
    signature: "Eine Bio",
    stats: { followingCount: 12, followerCount: 345, heartCount: 678 }
  }
});
assert.strictEqual(profileAndSummary.profileInfo.present, true);
assert.strictEqual(profileAndSummary.profileInfo.uniqueId, "demo");
assert.strictEqual(profileAndSummary.profileInfo.followerCount, "345");
assert.strictEqual(profileAndSummary.aiSummaryInfo.featureFlagPresent, true);
assert.strictEqual(profileAndSummary.aiSummaryInfo.text, "");

const actualSummary = core.inspectMetadata({ live_summary_text: "Eine tatsächlich gelieferte Zusammenfassung." });
assert.strictEqual(actualSummary.aiSummaryInfo.text, "Eine tatsächlich gelieferte Zusammenfassung.");

const pullData = {
  options: { qualities: [
    { sdk_key: "origin", name: "Original" },
    { sdk_key: "hd", name: "720p" },
    { sdk_key: "sd", name: "540p" },
    { sdk_key: "ld", name: "360p" }
  ] },
  stream_data: JSON.stringify({
    data: {
      origin: { main: { flv: "https://pull.example.tiktokcdn.com/live/stream_origin.flv", sdk_params: JSON.stringify({ VCodec: "h265", vbitrate: 2600000, width: 1920, height: 1080, fps: 60 }) } },
      hd: { main: { flv: "https://pull.example.tiktokcdn.com/live/stream_hd.flv", hls: "https://pull.example.tiktokcdn.com/live/stream_hd.m3u8", sdk_params: JSON.stringify({ VCodec: "h264", vbitrate: 1800000, width: 1280, height: 720, fps: 30 }) } },
      sd: { main: { flv: "https://pull.example.tiktokcdn.com/live/stream_sd.flv", sdk_params: JSON.stringify({ VCodec: "h264", vbitrate: 900000, width: 960, height: 540, fps: 30 }) } },
      ld: { main: { flv: "https://pull.example.tiktokcdn.com/live/stream_ld.flv", sdk_params: JSON.stringify({ VCodec: "h264", vbitrate: 600000, width: 640, height: 360, fps: 30 }) } }
    }
  })
};
const variants = core.extractStreamVariants(pullData);
assert.strictEqual(variants.length, 5);
assert.ok(variants.some((item) => item.sdkKey === "origin" && item.quality === "Original" && item.height === 1080));
assert.ok(variants.some((item) => item.sdkKey === "hd" && item.quality === "720p" && item.bitrate === 1800000));
assert.ok(variants.some((item) => item.sdkKey === "sd" && item.width === 960 && item.height === 540));
assert.ok(variants.some((item) => item.sdkKey === "ld" && item.quality === "360p" && item.height === 360));

const captionContent = concat(bytesField(1, "de"), bytesField(2, "Guten Abend"));
const captionPayload = concat(
  intField(2, 123456),
  intField(3, 1500),
  bytesField(4, captionContent),
  intField(5, 77),
  intField(6, 3),
  intField(7, 1)
);
const baseMessage = concat(bytesField(1, "WebcastCaptionMessage"), bytesField(2, captionPayload));
const fetchResult = bytesField(1, baseMessage);
const decoded = proto.decodeFetchResult(fetchResult);
assert.strictEqual(decoded.captions.length, 1);
assert.strictEqual(decoded.captions[0].contents[0].lang, "de");
assert.strictEqual(decoded.captions[0].contents[0].text, "Guten Abend");
assert.strictEqual(decoded.captions[0].sentenceId, "77");
assert.strictEqual(decoded.captions[0].definite, true);

const chatUser = concat(intField(1, 123), bytesField(3, "Demo 😊"), bytesField(38, "demo_user"));
const chatPayload = concat(
  bytesField(1, concat(intField(2, 9010))),
  bytesField(2, chatUser),
  bytesField(3, "Guten Abend ❤️"),
  bytesField(14, "de")
);
const chatFetch = bytesField(1, concat(bytesField(1, "WebcastChatMessage"), bytesField(2, chatPayload)));
const chatDecoded = proto.decodeFetchResult(chatFetch).chatMessages;
assert.strictEqual(chatDecoded.length, 1);
assert.strictEqual(chatDecoded[0].messageId, "9010");
assert.strictEqual(chatDecoded[0].nickname, "Demo 😊");
assert.strictEqual(chatDecoded[0].displayId, "demo_user");
assert.strictEqual(chatDecoded[0].content, "Guten Abend ❤️");
assert.strictEqual(chatDecoded[0].contentLanguage, "de");

const giftPayload = concat(
  bytesField(1, concat(intField(2, 9020))),
  intField(2, 777),
  intField(5, 23),
  bytesField(7, chatUser),
  intField(9, 1)
);
const giftFetch = bytesField(1, concat(bytesField(1, "WebcastGiftMessage"), bytesField(2, giftPayload)));
const giftDecoded = proto.decodeFetchResult(giftFetch).giftMessages;
assert.strictEqual(giftDecoded.length, 1);
assert.strictEqual(giftDecoded[0].nickname, "Demo 😊");
assert.strictEqual(giftDecoded[0].repeatCount, "23");

const common = concat(intField(2, 9001), bytesField(8, bytesField(1, "pm_mt_msg_viewer")));
const roomUsers = concat(bytesField(1, common), intField(3, 143), intField(7, 15842));
const likes = concat(bytesField(1, common), intField(2, 10), intField(3, 430200));
const socialCommon = concat(intField(2, 9002), bytesField(8, bytesField(1, "pm_main_follow_message_viewer_2")));
const social = concat(bytesField(1, socialCommon), intField(6, 238800));
const liveFetch = concat(
  bytesField(1, concat(bytesField(1, "WebcastRoomUserSeqMessage"), bytesField(2, roomUsers))),
  bytesField(1, concat(bytesField(1, "WebcastLikeMessage"), bytesField(2, likes))),
  bytesField(1, concat(bytesField(1, "WebcastSocialMessage"), bytesField(2, social)))
);
const liveDecoded = proto.decodeFetchResult(liveFetch).liveEvents;
assert.strictEqual(liveDecoded.length, 3);
assert.strictEqual(liveDecoded[0].viewerCount, "143");
assert.strictEqual(liveDecoded[0].totalViewers, "15842");
assert.strictEqual(liveDecoded[1].likeCount, "430200");
assert.strictEqual(liveDecoded[2].kind, "follow");
assert.strictEqual(liveDecoded[2].followerCount, "238800");

const backgroundSource = fs.readFileSync(path.join(extension, "background.js"), "utf8");
const contentSource = fs.readFileSync(path.join(extension, "content.js"), "utf8");
const hookSource = fs.readFileSync(path.join(extension, "hook.js"), "utf8");
const sidepanelSource = fs.readFileSync(path.join(extension, "sidepanel.js"), "utf8");
const protoMainSource = fs.readFileSync(path.join(extension, "proto-main.js"), "utf8");
assert.ok(/const MAX_CHAT = 50;/.test(backgroundSource));
assert.ok(backgroundSource.includes('case "TLC_CHAT_MESSAGE"'));
assert.ok(backgroundSource.includes('case "TLC_GET_PLAYER_STATE"'));
assert.ok(backgroundSource.includes('case "TLC_CLEAR_CHAT"'));
assert.ok(backgroundSource.includes('case "TLC_REFRESH_PAGE_INFO"'));
assert.ok(backgroundSource.includes('case "TLC_FORCE_PROFILE"'));
assert.ok(backgroundSource.includes('case "TLC_OPEN_EMBED_LIVE"'));
assert.ok(backgroundSource.includes('case "TLC_SET_MUTE"'));
assert.ok(backgroundSource.includes('case "TLC_GIFT_MESSAGE"'));
assert.ok(backgroundSource.includes('case "TLC_SET_AUTOSTART"'));
assert.ok(backgroundSource.includes('case "TLC_SET_QUICK_RECOVER"'));
assert.ok(backgroundSource.includes('case "TLC_QUICK_RECOVER"'));
assert.ok(backgroundSource.includes('case "TLC_PLAYER_STATE_PUSH"'));
assert.ok(backgroundSource.includes('case "TLC_GET_DEBUG_REPORT"'));
assert.ok(backgroundSource.includes('const PROFILE_PREFIX = "tlc-profile-"'));
assert.ok(backgroundSource.includes("hookEnabled: false"));
assert.ok(backgroundSource.includes("quickRecoverEnabled: false"));
assert.ok(backgroundSource.includes("speechEnabled: false"));
assert.ok(backgroundSource.includes("chatSourceTabId: null"));
assert.ok(backgroundSource.includes("chatTargetTabId: null"));
assert.ok(backgroundSource.includes("debugEnabled: false"));
assert.ok(backgroundSource.includes("waitingForTikTok: true"));
assert.ok(backgroundSource.includes("function normalizePlayerState"));
assert.ok(backgroundSource.includes("duplicateMessageId"));
assert.ok(backgroundSource.includes("if (duplicate) {"));
assert.ok(backgroundSource.includes("await setState(tabId, state);"));
assert.ok(backgroundSource.includes("available: booleanValue(playerState.available)"));
assert.ok(backgroundSource.includes("await setSettings({ debugEnabled: Boolean(message.enabled) })"));
assert.ok(backgroundSource.includes("enabled: true"));
assert.ok(backgroundSource.includes("return { armed: Boolean(enabled), waitingForTikTok: settings.waitingForTikTok, reloading: false }"));
assert.ok(backgroundSource.includes("await chrome.tabs.reload(tabId, { bypassCache: true })"));
assert.ok(backgroundSource.includes("www\\.tiktok\\.com\\/@"));
assert.ok(backgroundSource.includes("www\\.tiktok\\.com\\/embed\\/live"));
assert.ok(backgroundSource.includes("function openEmbedLive"));
assert.ok(backgroundSource.includes("function ensureEmbedChatSource"));
assert.ok(backgroundSource.includes("chatTargetTabId: embedTabId"));
assert.ok(backgroundSource.includes("chrome.tabs.create({ url: expectedUrl, active: false"));
assert.ok(backgroundSource.includes('case "TLC_FULLSCREEN_EXITED"'));
assert.ok(!backgroundSource.includes("replacement = await chrome.tabs.create"));
assert.ok(contentSource.includes("function isLivePage()"));
assert.ok(contentSource.includes("^\\/@[^/]+\\/live"));
assert.ok(contentSource.includes("^\\/embed\\/live"));
assert.ok(contentSource.includes("if (!force || !isLivePage())"));
assert.ok(contentSource.includes('action === "open-report"'));
assert.ok(contentSource.includes('action === "set-volume"'));
assert.ok(contentSource.includes('action === "set-limiter"'));
assert.ok(contentSource.includes('createDynamicsCompressor'));
assert.ok(contentSource.includes("createGain"));
assert.ok(contentSource.includes("limiterMakeupCompensation"));
assert.ok(contentSource.includes("captureStream"));
assert.ok(contentSource.includes("createMediaStreamSource"));
assert.ok(contentSource.includes("audio-context-resume-deferred"));
assert.ok(contentSource.includes("continue watching"));
assert.ok(contentSource.includes("video.play().catch"));
assert.ok(contentSource.includes("function quickRecoverReason"));
assert.ok(contentSource.includes("let quickRecoverArmed = false"));
assert.ok(contentSource.includes("quickRecoverArmed = true"));
assert.ok(contentSource.includes("if (!quickRecoverArmed) return \"\";"));
assert.ok(contentSource.includes("const POPUP_GUARD_GRACE_MS = 30;"));
assert.ok(contentSource.includes("const QUICK_RECOVER_INTERVAL_MS = 30;"));
assert.ok(contentSource.includes("const QUICK_RECOVER_RELOAD_COOLDOWN_MS = 300;"));
assert.ok(!contentSource.includes("QUICK_RECOVER_LOCAL_PLAY_MS"));
assert.ok(backgroundSource.includes("Date.now() - lastAt < 300"));
assert.ok(contentSource.includes('type: "TLC_QUICK_RECOVER"'));
assert.ok(contentSource.includes('type: "TLC_FULLSCREEN_EXITED"'));
assert.ok(contentSource.includes('type: "TLC_PLAYER_STATE_PUSH"'));
assert.ok(contentSource.includes("chatSourceOnly"));
assert.ok(contentSource.includes("function playMediaFallback"));
assert.ok(contentSource.includes("tlc-media-fallback"));
assert.ok(contentSource.includes("tlc-media-fallback-status"));
assert.ok(contentSource.includes("VLC Ersatz wird geprüft."));
assert.ok(contentSource.includes('"fullscreenchange"'));
assert.ok(fs.readFileSync(path.join(extension, "popup-guard.js"), "utf8").includes("keepwatching"));
assert.ok(fs.readFileSync(path.join(extension, "popup-guard.js"), "utf8").includes("^\\/embed\\/live"));
assert.ok(!contentSource.includes("video.volume > cap"));
assert.ok(!contentSource.includes("Lautstärkedeckel"));
assert.ok(sidepanelSource.includes('`${volumePercent}%`'));
assert.ok(sidepanelSource.includes('`${value}%`'));
assert.ok(sidepanelSource.includes("function activateSpeech"));
assert.ok(sidepanelSource.includes("function persistSpeechEnabled"));
assert.ok(sidepanelSource.includes("speechEnabled: Boolean(enabled)"));
assert.ok(sidepanelSource.includes("function booleanValue"));
assert.ok(sidepanelSource.includes("booleanValue(playerState.available)"));
assert.ok(!sidepanelSource.includes("const available = Boolean(playerState.available)"));
assert.ok(contentSource.includes('collectRecommendedSummary'));
assert.ok(contentSource.includes('collectProfileFromHover'));
assert.ok(contentSource.includes("function certifiedSvgBadge"));
assert.ok(contentSource.includes('root.querySelectorAll("svg")'));
assert.ok(!contentSource.includes("verified|verifiziert|zertifiziert|certified|official"));
assert.ok(contentSource.includes('credentials: "omit"'));
assert.ok(contentSource.includes('auto: ["Automatisch", "Automatic", "Auto"]'));
assert.ok(!contentSource.includes('credentials: "include"'));
assert.ok(contentSource.includes('debug("dom-chat-scan-error"'));
assert.ok(contentSource.includes('debug("dom-observer-error"'));
assert.ok(contentSource.includes("document.addEventListener(\"DOMContentLoaded\", startTabRuntime, { once: true })"));
assert.ok(!hookSource.includes('sessionStorage.getItem("tlc_ws_hook_enabled")'));
assert.ok(hookSource.includes("currentLiveHandle"));
assert.ok(hookSource.includes("^\\/@([^/]+)\\/live"));
assert.ok(hookSource.includes("^\\/embed\\/live"));
assert.ok(protoMainSource.includes("else if (!root[protoKey])"));
assert.ok(fs.existsSync(path.join(extension, "popup-guard.js")));
assert.ok(backgroundSource.includes('"popup-guard.js", "proto-main.js", "hook.js"'));

const panelHtml = fs.readFileSync(path.join(extension, "sidepanel.html"), "utf8");
assert.ok(panelHtml.includes('id="chat-led"'));
assert.ok(panelHtml.includes('id="speech-led"'));
assert.ok(panelHtml.includes('id="speech-volume"'));
assert.ok(panelHtml.includes('id="hook-led"'));
assert.ok(panelHtml.includes('id="limiter-enabled"'));
assert.ok(panelHtml.includes('id="refresh-page-info"'));
assert.ok(panelHtml.includes('id="force-page-info"'));
assert.ok(panelHtml.includes('id="top-chatters"'));
assert.ok(panelHtml.includes('id="audience-modal"'));
assert.ok(panelHtml.includes('id="speech-language"'));
assert.ok(panelHtml.includes('id="speech-voice"'));
assert.ok(panelHtml.includes('id="audd-token"'));
assert.ok(panelHtml.includes("AudD API-Token"));
assert.ok(!panelHtml.includes("Dienstadresse"));
assert.ok(panelHtml.includes('id="sherpa-action"'));
assert.ok(panelHtml.includes("Sherpa installieren"));
assert.ok(panelHtml.includes('id="game-mode"'));
assert.ok(panelHtml.includes("Chatnamen"));
assert.ok(panelHtml.includes("Chatnamen kürzen"));
assert.ok(panelHtml.includes("Permanent aktiv"));
assert.ok(sidepanelSource.includes("voiceName: speechVoiceName"));
assert.ok(sidepanelSource.includes("DEFAULT_SERVICE_URL"));
assert.ok(sidepanelSource.includes("function sherpaSpeechVoices"));
assert.ok(sidepanelSource.includes("/v1/config/audd-token"));
assert.ok(sidepanelSource.includes("/v1/sherpa/install"));
assert.ok(sidepanelSource.includes("canInstallSherpa"));
assert.ok(sidepanelSource.includes("function installSherpaVoices"));
assert.ok(sidepanelSource.includes("Lokaler Dienst ist veraltet"));
assert.ok(sidepanelSource.includes("Sherpa-Endpunkt fehlt"));
assert.ok(sidepanelSource.includes("cleanSpeechPayload"));
assert.ok(sidepanelSource.includes("function audienceSelectActive"));
assert.ok(sidepanelSource.includes("!audienceSelectActive()"));
assert.ok(!sidepanelSource.includes("CURATED_VOICE_PATTERNS"));
assert.ok(!sidepanelSource.includes("BLOCKED_VOICE_NAMES"));
assert.ok(!sidepanelSource.includes("curatedSpeechVoices"));
assert.ok(!sidepanelSource.includes("nicht gemeldet"));
assert.ok(sidepanelSource.includes("gameModeEnabled"));
assert.ok(backgroundSource.includes("speechVoiceName"));
assert.ok(backgroundSource.includes("gameModeEnabled"));
assert.ok(panelHtml.includes('id="speak-names"'));
assert.ok(panelHtml.includes('id="shorten-names"'));
assert.ok(panelHtml.includes('id="recognize-song"'));
assert.ok(panelHtml.includes('id="hook-autostart"'));
assert.ok(panelHtml.includes("Permanent Hook"));
assert.ok(panelHtml.includes('id="quick-recover"'));
assert.ok(panelHtml.includes("Auto-Reconnect"));
assert.ok(panelHtml.includes('id="open-embed-live"'));
assert.ok(panelHtml.includes('id="open-normal-live"'));
assert.ok(panelHtml.includes(">Embed</button>"));
assert.ok(panelHtml.includes(">Normal</button>"));
assert.ok(panelHtml.includes("Pegelschutz aktivieren"));
assert.ok(panelHtml.includes('id="player-vlc-frame"'));
assert.ok(panelHtml.includes('id="debug-enabled"'));
assert.ok(panelHtml.includes('id="export-debug"'));
assert.ok(panelHtml.includes('>Hook setzen</button>'));
assert.ok(panelHtml.includes('id="reset-tab" class="secondary danger-outline">Refresh</button>'));
assert.ok(!panelHtml.includes("Hook dauerhaft gesetzt lassen"));
assert.ok(!panelHtml.includes("Unterbrechung automatisch schnell beheben"));
assert.ok(!panelHtml.includes("Hook aktivieren"));
assert.ok(!panelHtml.includes("Unterbrechungsfrei aktivieren"));
assert.ok(!panelHtml.includes("Embed öffnen"));
assert.ok(!panelHtml.includes("Digitalen Pegelschutz aktivieren"));
assert.ok(!panelHtml.includes("Es wird nichts aufgenommen oder übertragen."));
assert.ok(!panelHtml.includes("Noch keine manuelle Prüfung ausgeführt."));
assert.ok(!sidepanelSource.includes("Es wird nichts aufgenommen oder übertragen."));
const forbidden071Texts = [
  "Lautstärke, Spitzenpegel und Schutzstärke werden als positive Werte von 0 bis 100 angezeigt.",
  "Nach einem Klick werden etwa 12 Sekunden Tab-Audio über den lokalen Dienst an AudD übertragen. Anbietergebühren können anfallen.",
  "Kein Untertitelschalter gefunden. TikTok stellt für diesen Stream derzeit keine native Untertitelfunktion bereit.",
  "Der Hook wird vor dem Player-Code gesetzt. Der aktuelle Tab wird danach neu geladen.",
  "Refresh leert nur die flüchtigen Daten dieses Tabs, aktiviert den Hook erneut und lädt TikTok ohne Seitencache. Cookies bleiben unverändert.",
  "Follows werden ab Hook-Start gezählt.",
  "Der WebSocket-Hook liefert die Werte nach dem Neuladen des Streams.",
  "dBFS ist ein digitaler Signalpegel",
  "Der Export entfernt Werte signierter URL-Parameter",
  "Bitte einen TikTok-Tab aktivieren.",
  "Das Seitenpanel arbeitet nur auf https://www.tiktok.com/.",
  "Hook vorgemerkt; Tab wird neu geladen.",
  "Hook dauerhaft vorgemerkt",
  "Untertitelschalter gefunden",
  "Untertitelschalter nicht gefunden",
  "Verfügbare Bildqualitäten",
  'id="quality-list"',
  'id="quality-count"',
  'id="quality-action-status"'
];
for (const text of forbidden071Texts) {
  assert.ok(!panelHtml.includes(text), `sidepanel.html contains removed text: ${text}`);
  assert.ok(!sidepanelSource.includes(text), `sidepanel.js contains removed text: ${text}`);
  assert.ok(!contentSource.includes(text), `content.js contains removed text: ${text}`);
}
assert.ok(!panelHtml.includes('<p class="eyebrow">TikTok LIVE</p>'));
assert.ok(!panelHtml.includes("Letzte Chatzeilen"));
assert.ok(!panelHtml.includes("Untertitelstatus"));
assert.ok(!panelHtml.includes("<h1>Companion</h1>"));

console.log(`PASS: manifest 0.7.1, ${scripts.length} scripts, chat speech composition, gifts, audience statistics, service controls and security guards`);
