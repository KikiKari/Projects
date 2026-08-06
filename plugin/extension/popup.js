/* Popup-Steuerung. Nutzt TikTokCompanion aus tiktok-companion.js. */

const $ = s => document.querySelector(s);
const esc = s => String(s ?? '').replace(/[&<>"]/g, c =>
  ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

const ttc = new TikTokCompanion({
  // Der lokale Monitor ist optional. Ist er nicht erreichbar, faellt die
  // Komponente auf den Direktabruf zurueck - dafuer hat die Erweiterung
  // host_permissions, anders als eine lose HTML-Datei.
  apiBase: 'http://127.0.0.1:8765',
  onState: render,
  onError: msg => {
    $('#error').innerHTML = msg
      ? '<div class="err"><b>Status nicht abrufbar.</b><br>' + esc(msg) +
        '<br>Der Player unten funktioniert unabhängig davon.</div>'
      : '';
  }
});

function render(st) {
  const live = st.live === true;
  $('#badge').className = 'badge' + (live ? ' live' : '');
  $('#badgeText').textContent = live ? 'LIVE' : (st.live === false ? 'offline' : '—');

  $('#status').innerHTML =
    (st.title ? '<div class="strong">' + esc(st.title) + '</div>' : '') +
    (st.started_at ? '<div>Beginn ' + esc(st.started_at.replace('T', ' ')) +
      (st.since ? ' · seit ca. ' + esc(st.since) : '') + '</div>' : '') +
    (st.last_seen ? '<div>zuletzt gesehen ' + esc(st.last_seen) + '</div>' : '') +
    (st.streams_total ? '<div>' + st.streams_total + ' Sendungen · ' +
      esc(st.airtime || '') + ' · ' + (st.active_days || '?') + ' aktive Tage</div>' : '') +
    '<div style="margin-top:6px"><a href="' + esc(st.live_url) +
      '" target="_blank" rel="noopener">Live-Seite</a> · <a href="' +
      esc(st.profile_url) + '" target="_blank" rel="noopener">Profil</a></div>';

  $('#streams').innerHTML = (st.streams || []).length
    ? st.streams.slice(0, 8).map(s =>
        '<div class="stream' + (s.is_live ? ' now' : '') + '">' +
        '<span class="when">' + esc(s.day.slice(5)) + ' ' + esc(s.time || '') + '</span>' +
        '<span class="t">' + esc(s.title || '(ohne Titel)') + '</span>' +
        '<span class="when">' + esc(s.duration || '') + '</span></div>').join('')
    : 'keine Daten';

  if (live) mountPlayer(st.username);
  else {
    document.querySelectorAll('#player iframe').forEach(f => f.remove());
    $('#placeholder').style.display = '';
    $('#phText').textContent = st.username
      ? '@' + st.username + ' ist gerade offline.'
      : 'Konto eingeben und „Anzeigen“ drücken.';
  }
}

function mountPlayer(user) {
  const holder = $('#player');
  if (holder.querySelector('iframe')) return;
  const f = document.createElement('iframe');
  f.src = TikTokCompanion.embedUrl(user);
  f.allow = 'autoplay; encrypted-media; picture-in-picture';
  f.referrerPolicy = 'origin';
  f.title = 'TikTok Live von @' + user;
  holder.appendChild(f);
  $('#placeholder').style.display = 'none';
}

async function start() {
  const user = $('#user').value.trim().replace(/^@/, '');
  if (!user) return;
  const minutes = parseInt($('#every').value, 10);
  document.querySelectorAll('#player iframe').forEach(f => f.remove());
  await chrome.storage.local.set({
    user, minutes, notify: $('#notify').checked
  });
  // Hintergrunddienst neu einplanen, damit er dasselbe Konto beobachtet.
  chrome.runtime.sendMessage({ type: 'reschedule' });
  ttc.notifyOnLive = false;              // Meldungen kommen aus dem Hintergrund
  ttc.watch(user, 0);                    // im Popup nur einmalig abfragen
}

$('#go').onclick = start;
$('#user').addEventListener('keydown', e => { if (e.key === 'Enter') start(); });
$('#every').addEventListener('change', start);
$('#notify').addEventListener('change', e =>
  chrome.storage.local.set({ notify: e.target.checked }));
$('#force').onclick = () => {
  const user = $('#user').value.trim().replace(/^@/, '');
  if (user) mountPlayer(user);
};

(async () => {
  const s = await chrome.storage.local.get(['user', 'minutes', 'notify']);
  if (s.user) $('#user').value = s.user;
  if (s.minutes != null) $('#every').value = String(s.minutes);
  $('#notify').checked = s.notify !== false;
  if (s.user) ttc.watch(s.user, 0);
})();
