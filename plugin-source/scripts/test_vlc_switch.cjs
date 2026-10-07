const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../browser-extension/content.js'), 'utf8');
const listeners = new Map();
const native = { muted: false, paused: false, pause() { this.paused = true; }, play() { this.paused = false; return Promise.resolve(); } };
const fallback = { muted: false, paused: false };
const media = [native, fallback];
const unrelatedVideo = { ...native };
const speechAudio = { ...native };
const surface = { querySelectorAll: selector => { assert.equal(selector, 'video'); return media; } };
fallback.closest = () => ({ parentElement: surface });
const gain = { value: 0.7 };
let changed;
const context = vm.createContext({ audioPipeline: { video: native, outputGain: { gain } }, document: {
  querySelectorAll: () => { throw new Error('Must not globally suppress page media'); }, documentElement: {},
  addEventListener: (name, fn) => listeners.set(name, fn),
  removeEventListener: name => listeners.delete(name)
}, MutationObserver: class { constructor(fn) { changed = fn; } observe() {} disconnect() {} } });
vm.runInContext(source.slice(source.indexOf('  function suppressNativeAudio('), source.indexOf('  async function playMediaFallback(')), context);
const release = context.suppressNativeAudio(fallback);
assert.equal(native.muted, true);
assert.equal(native.paused, true);
assert.equal(gain.value, 0);
assert.equal(fallback.muted, false);
assert.equal(fallback.paused, false);
native.paused = false;
listeners.get('play')();
assert.equal(native.paused, true);
const replacement = { ...native, muted: false, paused: false };
media.push(replacement);
changed();
assert.equal(replacement.muted, true);
assert.equal(replacement.paused, true);
release();
assert.equal(native.muted, false);
assert.equal(native.paused, false);
assert.equal(gain.value, 0.7);
assert.equal(listeners.size, 0);
assert.equal(unrelatedVideo.paused, false);
assert.equal(speechAudio.paused, false);
context.audioPipeline.video = unrelatedVideo;
const releaseUnrelated = context.suppressNativeAudio(fallback);
assert.equal(gain.value, 0.7, 'Unrelated audio pipeline must remain unchanged');
releaseUnrelated();
const background = fs.readFileSync(path.join(__dirname, '../browser-extension/background.js'), 'utf8');
const normal = background.slice(background.indexOf('async function openNormalLive('), background.indexOf('chrome.sidePanel.setPanelBehavior'));
assert.match(normal, /await chrome.tabs.update\(tabId, \{ url: normalLiveUrl\(handle\) \}\)/);
assert.doesNotMatch(normal, /if \(reloading\)/);
assert.match(source, /if \(holder\?\.isConnected\) return holder.querySelector\("video"\)/);
console.log('PASS: VLC isolates native audio, suppresses restarted/replaced media, restores on failure; Normal navigates even at same URL; existing fallback reused');
async function exerciseSwitch() {
  const panel = fs.readFileSync(path.join(__dirname, '../browser-extension/sidepanel.js'), 'utf8');
  const clickStart = panel.indexOf('  elements["player-vlc-frame"].addEventListener("click"');
  const clickEnd = panel.indexOf('  elements["player-volume"].addEventListener', clickStart);
  let click;
  let starts = 0;
  const button = { addEventListener: (event, fn) => { click = fn; } };
  const panelContext = vm.createContext({ elements: { 'player-vlc-frame': button },
    installVlcIfNeeded: () => { throw new Error('Internal replacement must not wait for desktop installation'); },
    runPlayer: async (action, target) => { assert.equal(action, 'play-vlc-source'); assert.equal(target, button); starts++; }
  });
  vm.runInContext(panel.slice(clickStart, clickEnd), panelContext);
  await click();
  assert.equal(starts, 1, 'VLC click dispatches internal player immediately');
  const largeNative = { closest: () => null, getBoundingClientRect: () => ({ width: 1000, height: 1000 }) };
  const smallReplacement = { closest: () => ({}), getBoundingClientRect: () => ({ width: 100, height: 100 }) };
  const selection = vm.createContext({ activeMediaFallbackItem: {}, mediaFallbackRunning: false,
    document: { querySelector: () => smallReplacement, querySelectorAll: () => [largeNative, smallReplacement] } });
  vm.runInContext(source.slice(source.indexOf('  function primaryVideo()'), source.indexOf('  function playerToggleControl()')), selection);
  assert.equal(selection.primaryVideo(), smallReplacement, 'Active replacement wins regardless of video size');
  selection.activeMediaFallbackItem = null;
  selection.mediaFallbackRunning = true;
  assert.equal(selection.primaryVideo(), smallReplacement, 'Starting replacement owns player controls');
  selection.mediaFallbackRunning = false;
  assert.equal(selection.primaryVideo(), largeNative, 'Inactive replacement excluded from native selection');
  let navigated = 0;
  const ctx = vm.createContext({ chrome: { tabs: {
    get: async () => ({ url: 'https://www.tiktok.com/@test/live' }),
    update: async () => { navigated++; }
  } }, getState: async () => ({}), pageHandle: () => 'test',
  cancelEmbedSession: async () => {}, cancelRecoveryForModeChange: async () => {},
  closeEmbedChatSource: async () => {}, armLiveTab: async () => {},
  normalLiveUrl: () => 'https://www.tiktok.com/@test/live' });
  vm.runInContext(normal, ctx);
  await ctx.openNormalLive(1);
  assert.equal(navigated, 1, 'Normal must navigate even from the same LIVE URL');
  let released = 0, removed = 0, created = 0;
  const video = { pause() {}, removeAttribute() {}, load() {} };
  const player = vm.createContext({ mediaFallbackRunning: false, mediaFallbackPageUrl: 'live',
    location: { href: 'live' }, attemptedMediaFallbackUrls: new Set(), activeMediaFallbackItem: null,
    releaseNativeAudio: null, mediaFallbackCandidates: x => x, mediaFallbackKey: x => x.url,
    ensureMediaFallbackVideo: () => { created++; return video; },
    suppressNativeAudio: () => () => { released++; }, setMediaFallbackStatus() {},
    destroyMediaFallbackPlayer() {}, tryMediaUrl: async () => ({ ok: false, reason: 'test failure' }),
    getPlayerState: () => ({}), document: { getElementById: () => ({ remove() { removed++; } }) }
  });
  vm.runInContext(source.slice(source.indexOf('  async function playMediaFallback('), source.indexOf('  async function configureLimiter(')), player);
  await player.playMediaFallback([]);
  assert.equal(created, 0, 'No sources must not cover the native player');
  const result = await player.playMediaFallback([{ url: 'test', quality: 'test' }]);
  assert.equal(result.activated, false);
  assert.equal(released, 1, 'Failed startup restores native audio');
  assert.equal(removed, 1, 'Failed startup removes replacement');
  assert.equal(player.mediaFallbackRunning, false);
  console.log('PASS: actual Normal handler navigates same URL; failed VLC startup restores native player; empty sources create no overlay');
}
exerciseSwitch().catch(error => { console.error(error); process.exitCode = 1; });
