/* Hintergrunddienst: prüft im Turnus und meldet den Livegang.
   Läuft ohne offenen Tab — der Browser weckt den Dienst über einen Alarm. */

importScripts('tiktok-companion.js');

const ALARM = 'ttc-check';

const companion = new TikTokCompanion({
  apiBase: 'http://127.0.0.1:8765',      // optional; sonst Direktabruf
  onError: () => {}                       // Fehler still, sonst spammt es
});

async function settings() {
  const s = await chrome.storage.local.get(['user', 'minutes', 'notify', 'lastLive']);
  return {
    user: s.user || '',
    minutes: s.minutes == null ? 2 : Number(s.minutes),
    notify: s.notify !== false,
    lastLive: !!s.lastLive
  };
}

async function schedule() {
  const { minutes } = await settings();
  await chrome.alarms.clear(ALARM);
  if (minutes > 0) {
    chrome.alarms.create(ALARM, { periodInMinutes: Math.max(1, minutes) });
  }
}

async function check() {
  const { user, notify, lastLive } = await settings();
  if (!user) return;

  companion.user = user;
  let st = null;
  try {
    st = await companion.refresh();
  } catch (e) {
    return;                               // naechster Durchlauf versucht es erneut
  }
  if (!st || st.live == null) return;

  const isLive = st.live === true;
  await chrome.storage.local.set({ lastLive: isLive, lastState: st });

  // Kennzeichen am Symbol: sichtbar, ohne zu stoeren.
  chrome.action.setBadgeText({ text: isLive ? 'LIVE' : '' });
  chrome.action.setBadgeBackgroundColor({ color: '#fe2c55' });

  if (isLive && !lastLive && notify) {
    chrome.notifications.create('ttc-' + user + '-' + Date.now(), {
      type: 'basic',
      iconUrl: 'icons/icon128.png',
      title: '@' + user + ' ist live',
      message: st.title || 'Die Sendung läuft.',
      priority: 1
    });
  }
}

chrome.runtime.onInstalled.addListener(() => { schedule(); check(); });
chrome.runtime.onStartup.addListener(() => { schedule(); check(); });
chrome.alarms.onAlarm.addListener(a => { if (a.name === ALARM) check(); });

chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (msg && msg.type === 'reschedule') {
    schedule().then(check).then(() => sendResponse({ ok: true }));
    return true;                          // asynchrone Antwort
  }
  if (msg && msg.type === 'checkNow') {
    check().then(() => sendResponse({ ok: true }));
    return true;
  }
});

// Klick auf die Meldung öffnet die Live-Seite.
chrome.notifications.onClicked.addListener(async () => {
  const { user } = await settings();
  if (user) chrome.tabs.create({ url: 'https://www.tiktok.com/@' + user + '/live' });
});
