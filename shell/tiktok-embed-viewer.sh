#!/bin/bash
# tiktok-embed-viewer.html — portiert nach shell
# Quelle: html, Projects@Telegram-Monitor:plugin/tiktok-embed-viewer.html
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Portierte Version von tiktok-embed-viewer.html nach Bash
# Erzeugt das HTML-Dokument und schreibt es in eine Datei

output_file="${1:-tiktok-embed-viewer.html}"

cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>TikTok Live — Embed-Viewer</title>
<style>
  :root{
    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;
    --accent:#25f4ee; --accent2:#fe2c55; --ok:#22c55e; --off:#6b7280;
    color-scheme: dark;
  }
  @media (prefers-color-scheme: light){
    :root{ --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);
       font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  .wrap{max-width:1120px;margin:0 auto;padding:16px}
  header{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin-bottom:14px}
  h1{font-size:17px;margin:0;font-weight:650}
  .badge{display:inline-flex;align-items:center;gap:6px;font-size:12px;font-weight:700;
         padding:3px 10px;border-radius:99px;background:#2a2f3a;color:var(--muted)}
  .badge.live{background:var(--accent2);color:#fff}
  .badge .dot{width:7px;height:7px;border-radius:50%;background:currentColor}
  .badge.live .dot{animation:pulse 1.6s infinite}
  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}
  input,select,button{font:inherit;border-radius:8px;border:1px solid var(--line);
                      background:var(--card);color:var(--text);padding:8px 11px}
  button{cursor:pointer;font-weight:600}
  button.primary{background:var(--accent2);border-color:var(--accent2);color:#fff}
  .row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:12px}
  .grid{display:grid;grid-template-columns:minmax(0,2fr) minmax(260px,1fr);gap:14px}
  @media (max-width:860px){ .grid{grid-template-columns:1fr} }
  .card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px}
  .player{position:relative;width:100%;aspect-ratio:9/16;max-height:78vh;background:#000;
          border-radius:12px;overflow:hidden;border:1px solid var(--line)}
  .player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
  .placeholder{position:absolute;inset:0;display:flex;flex-direction:column;gap:8px;
               align-items:center;justify-content:center;color:var(--muted);text-align:center;padding:24px}
  h2{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);
     margin:0 0 8px;font-weight:650}
  .meta{color:var(--muted);font-size:13px}
  .stream{display:flex;gap:10px;padding:7px 0;border-bottom:1px solid var(--line);font-size:13.5px}
  .stream:last-child{border-bottom:0}
  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}
  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
  .stream.now{color:var(--accent2);font-weight:600}
  .note{font-size:12.5px;color:var(--muted);margin-top:10px;line-height:1.45}
  a{color:var(--accent2)} a:hover{text-decoration:underline}
  .err{background:#3a1d22;border:1px solid #5c2a33;color:#ffb4c0;padding:9px 12px;
       border-radius:8px;font-size:13px;margin-bottom:10px}
  @media (prefers-color-scheme: light){ .err{background:#fdeceb;border-color:#f5c6c2;color:#b91c1c} }
</style>
</head>
<body>
<div class="wrap">
  <header>
    <h1>TikTok Live — Embed-Viewer</h1>
    <span class="badge" id="badge"><span class="dot"></span><span id="badgeText">unbekannt</span></span>
    <span class="meta" id="checked"></span>
  </header>

  <div class="row">
    <input id="user" placeholder="@name" style="min-width:180px">
    <button class="primary" id="go">Anzeigen</button>
    <select id="every">
      <option value="60">Status alle 60 s</option>
      <option value="120" selected>alle 2 min</option>
      <option value="300">alle 5 min</option>
      <option value="0">nur manuell</option>
    </select>
    <label class="meta"><input type="checkbox" id="notify"> bei Livegang benachrichtigen</label>
    <label class="meta"><input type="checkbox" id="autoplay" checked> Player automatisch laden</label>
    <button id="force">Player trotzdem laden</button>
  </div>

  <div id="error"></div>

  <div class="grid">
    <div>
      <div class="player" id="player">
        <div class="placeholder" id="placeholder">
          <div style="font-size:34px">📺</div>
          <div id="phText">Konto eingeben und „Anzeigen“ drücken.</div>
        </div>
      </div>
      <p class="note">
        Eingebettet wird der offizielle TikTok-Live-Player
        (<code>tiktok.com/embed/live/@name</code>). Er ist auf reines Zuschauen
        ausgelegt: <b>keine Anmeldung, keine Geschenk- oder Kauf-Oberfläche</b>.
        Damit entfallen die kostenpflichtigen Aktionen, die im normalen Frontend
        erreichbar wären — brauchbar für Mitschauen ohne Konto und ohne Kaufrisiko.
      </p>
    </div>

    <div>
      <div class="card">
        <h2>Status</h2>
        <div id="status" class="meta">—</div>
      </div>
      <div class="card" style="margin-top:12px">
        <h2>Letzte Sendungen</h2>
        <div id="streams" class="meta">—</div>
      </div>
      <div class="card" style="margin-top:12px">
        <h2>Datenquelle</h2>
        <div class="meta" id="source">
          Statusdaten über den lokalen Monitor
          (<code>/api/tiktok/status</code>) oder direkt von der öffentlichen
          Profilseite eines Aufzeichnungsdienstes. Kein Konto, keine Umgehung
          von Zugangskontrollen.
        </div>
      </div>
    </div>
  </div>
</div>

<script src="./tiktok-companion.js"></script>
<script>
  // Standalone-Betrieb: Parameter aus der URL (?user=creator&api=http://127.0.0.1:8765)
  const params = new URLSearchParams(location.search);
  window.TTC = new TikTokCompanion({
    apiBase: params.get('api') || 'http://127.0.0.1:8765',
    onState: renderState,
    onError: msg => {
      const box = document.getElementById('error');
      if(!msg){ box.innerHTML = ''; return; }
      const local = location.protocol === 'file:';
      box.innerHTML = '<div class="err"><b>Status nicht abrufbar.</b><br>' + esc(msg) +
        '<br><br>Der Browser lässt aus dieser Seite heraus keinen direkten Abruf ' +
        'fremder Server zu' + (local ? ' (lokale Datei, Herkunft „null“)' : '') + '. Zwei Wege:' +
        '<br>• <b>Monitor starten</b> — im Projektordner <code>python server.py</code>, ' +
        'dann hier neu laden. Er liefert den Status und erlaubt den Zugriff ausdrücklich.' +
        '<br>• <b>Als Erweiterung laden</b> — mit <code>host_permissions</code> für ' +
        '<code>streamrecorder.io</code>, siehe plugin/README.md.' +
        '<br><br>Der Player unten funktioniert unabhängig davon: „Player trotzdem laden“.</div>';
    }
  });

  const $ = s => document.querySelector(s);
  const esc = s => String(s ?? '').replace(/[&<>"]/g, c =>
    ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));

  function renderState(st){
    const live = st.live === true;
    $('#badge').className = 'badge' + (live ? ' live' : '');
    $('#badgeText').textContent = live ? 'LIVE' : (st.live === false ? 'offline' : 'unbekannt');
    $('#checked').textContent = st.checked_at
      ? 'geprüft ' + new Date(st.checked_at).toLocaleTimeString('de-DE') : '';

    $('#status').innerHTML =
      (st.title ? '<div style="color:var(--text);font-weight:600">' + esc(st.title) + '</div>' : '') +
      (st.started_at ? '<div>Beginn ' + esc(st.started_at.replace('T', ' ')) +
        (st.since ? ' · seit ca. ' + esc(st.since) : '') + '</div>' : '') +
      (st.last_seen ? '<div>zuletzt gesehen ' + esc(st.last_seen) + '</div>' : '') +
      (st.streams_total ? '<div>' + st.streams_total + ' Sendungen · ' +
        esc(st.airtime || '') + ' Sendezeit · ' + (st.active_days || '?') + ' aktive Tage</div>' : '') +
      '<div style="margin-top:8px"><a href="' + esc(st.profile_url || '#') +
        '" target="_blank" rel="noopener">Profil</a> · <a href="' +
        esc(st.live_url || '#') + '" target="_blank" rel="noopener">Live-Seite</a></div>';

    $('#streams').innerHTML = (st.streams || []).length
      ? st.streams.slice(0, 10).map(s =>
          '<div class="stream' + (s.is_live ? ' now' : '') + '">' +
          '<span class="when">' + esc(s.day.slice(5)) + ' ' + esc(s.time || '') + '</span>' +
          '<span class="t">' + esc(s.title || '(ohne Titel)') + '</span>' +
          '<span class="when">' + esc(s.duration || '') + '</span></div>').join('')
      : 'keine Daten';

    const wantPlayer = live && $('#autoplay').checked;
    const holder = $('#player');
    if(wantPlayer && !holder.querySelector('iframe')){
      const f = document.createElement('iframe');
      f.src = st.embed_url;
      f.allow = 'autoplay; encrypted-media; picture-in-picture';
      f.referrerPolicy = 'origin';
      f.title = 'TikTok Live von @' + st.username;
      holder.appendChild(f);
      $('#placeholder').style.display = 'none';
    } else if(!live){
      holder.querySelectorAll('iframe').forEach(f => f.remove());
      $('#placeholder').style.display = '';
      $('#phText').textContent = st.username
        ? '@' + st.username + ' ist gerade offline.'
        : 'Konto eingeben und „Anzeigen“ drücken.';
    }
  }

  $('#go').onclick = () => {
    const u = $('#user').value.trim().replace(/^@/, '');
    if(!u) return;
    document.querySelectorAll('#player iframe').forEach(f => f.remove());
    localStorage.setItem('ttc.user', u);
    window.TTC.watch(u, parseInt($('#every').value, 10));
  };
  $('#user').addEventListener('keydown', e => { if(e.key === 'Enter') $('#go').click(); });
  $('#force').onclick = () => {
    const u = $('#user').value.trim().replace(/^@/, '');
    if(!u) return;
    const holder = $('#player');
    holder.querySelectorAll('iframe').forEach(f => f.remove());
    const f = document.createElement('iframe');
    f.src = TikTokCompanion.embedUrl(u);
    f.allow = 'autoplay; encrypted-media; picture-in-picture';
    f.referrerPolicy = 'origin';
    f.title = 'TikTok Live von @' + u;
    holder.appendChild(f);
    $('#placeholder').style.display = 'none';
  };
  $('#every').addEventListener('change', () => $('#go').click());
  $('#notify').addEventListener('change', async e => {
    window.TTC.notifyOnLive = e.target.checked;
    if(e.target.checked && 'Notification' in window && Notification.permission === 'default'){
      await Notification.requestPermission();
    }
  });

  const saved = params.get('user') || localStorage.getItem('ttc.user');
  if(saved){ $('#user').value = saved; $('#go').click(); }
</script>
</body>
</html>
EOF

echo "HTML-Datei wurde erfolgreich erstellt: $output_file"
