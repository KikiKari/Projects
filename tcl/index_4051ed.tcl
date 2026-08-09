#!/usr/bin/env tclsh
# index.html — portiert nach tcl
# Quelle: html, Projects@Telegram-Monitor:web/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

proc write_index_html {filename} {
    set f [open $filename w]
    
    puts $f {<!DOCTYPE html>}
    puts $f {<html lang="de">}
    puts $f {<head>}
    puts $f {<meta charset="utf-8">}
    puts $f {<meta name="viewport" content="width=device-width, initial-scale=1">}
    puts $f {<title>Telegram Monitor</title>}
    puts $f {<style>}
    puts $f {  :root\{}
    puts $f {    --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280;}
    puts $f {    --accent:#2481cc; --accent-soft:#e8f2fb; --discord:#5865f2; --discord-soft:#eceefe;}
    puts $f {    --ok:#15803d; --warn:#b45309; --err:#b91c1c;}
    puts $f {    color-scheme: light;}
    puts $f {  \}}
    puts $f {  *\{box-sizing:border-box\}}
    puts $f {  body\{margin:0;background:var(--bg);color:var(--text);}
    puts $f {       font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif\}}
    puts $f {  header\{background:var(--card);border-bottom:1px solid var(--line);padding:14px 20px;}
    puts $f {         display:flex;align-items:center;gap:14px;flex-wrap:wrap;position:sticky;top:0;z-index:5\}}
    puts $f {  header h1\{font-size:17px;margin:0;font-weight:650\}}
    puts $f {  .pill\{font-size:11px;padding:2px 8px;border-radius:99px;background:var(--accent-soft);}
    puts $f {        color:var(--accent);font-weight:600;white-space:nowrap\}}
    puts $f {  .pill.off\{background:#f1f2f4;color:var(--muted)\}}
    puts $f {  .pill.dc\{background:var(--discord-soft);color:var(--discord)\}}
    puts $f {  nav\{display:flex;gap:4px;padding:0 20px;background:var(--card);border-bottom:1px solid var(--line)\}}
    puts $f {  nav button\{border:0;background:none;padding:11px 14px;font:inherit;font-weight:550;}
    puts $f {             color:var(--muted);cursor:pointer;border-bottom:2px solid transparent\}}
    puts $f {  nav button.active\{color:var(--accent);border-bottom-color:var(--accent)\}}
    puts $f {  main\{padding:20px;max-width:1080px;margin:0 auto\}}
    puts $f {  .panel\{display:none\} .panel.active\{display:block\}}
    puts $f {  .row\{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:14px\}}
    puts $f {  input,select\{padding:9px 11px;border:1px solid var(--line);border-radius:8px;font:inherit;}
    puts $f {               background:var(--card);min-width:180px\}}
    puts $f {  input:focus,select:focus\{outline:2px solid var(--accent-soft);border-color:var(--accent)\}}
    puts $f {  button.go\{background:var(--accent);color:#fff;border:0;border-radius:8px;padding:9px 16px;}
    puts $f {            font:inherit;font-weight:600;cursor:pointer\}}
    puts $f {  button.go.sec\{background:var(--card);color:var(--text);border:1px solid var(--line)\}}
    puts $f {  button.go.dc\{background:var(--discord)\}}
    puts $f {  button.go:disabled\{opacity:.5;cursor:default\}}
    puts $f {  .card\{background:var(--card);border:1px solid var(--line);border-radius:12px;}
    puts $f {        padding:14px 16px;margin-bottom:10px\}}
    puts $f {  .card h3\{margin:0 0 2px;font-size:15px;display:flex;align-items:center;gap:8px;flex-wrap:wrap\}}
    puts $f {  .card .meta\{color:var(--muted);font-size:13px\}}
    puts $f {  .card .desc\{margin-top:7px;font-size:13.5px;white-space:pre-wrap\}}
    puts $f {  .avatar\{width:34px;height:34px;border-radius:50%;object-fit:cover;background:#eceff3;flex:none\}}
    puts $f {  .head\{display:flex;gap:11px;align-items:flex-start\}}
    puts $f {  .score\{font-variant-numeric:tabular-nums;font-size:12px;color:var(--muted);}
    puts $f {         border:1px solid var(--line);border-radius:6px;padding:1px 6px\}}
    puts $f {  .tag\{font-size:11px;padding:2px 7px;border-radius:5px;background:#f1f2f4;color:var(--muted);font-weight:600\}}
    puts $f {  .tag.ok\{background:#e7f6ec;color:var(--ok)\} .tag.no\{background:#fdeceb;color:var(--err)\}}
    puts $f {  .post\{border-left:3px solid var(--accent-soft);padding:6px 0 6px 11px;margin:9px 0;font-size:13.5px\}}
    puts $f {  .post .when\{color:var(--muted);font-size:12px\}}
    puts $f {  .post .txt\{white-space:pre-wrap;margin-top:2px\}}
    puts $f {  a\{color:var(--accent);text-decoration:none\} a:hover\{text-decoration:underline\}}
    puts $f {  .empty\{color:var(--muted);padding:22px;text-align:center;border:1px dashed var(--line);border-radius:12px\}}
    puts $f {  .err\{background:#fdeceb;border:1px solid #f5c6c2;color:var(--err);padding:10px 13px;}
    puts $f {       border-radius:8px;margin-bottom:12px;font-size:13.5px\}}
    puts $f {  .spin\{color:var(--muted);padding:16px 0\}}
    puts $f {  table\{width:100%;border-collapse:collapse;font-size:13.5px\}}
    puts $f {  th,td\{text-align:left;padding:8px 10px;border-bottom:1px solid var(--line);vertical-align:top\}}
    puts $f {  th\{color:var(--muted);font-weight:600;font-size:12px;text-transform:uppercase;letter-spacing:.03em\}}
    puts $f {  code\{background:#f1f2f4;padding:1px 5px;border-radius:4px;font-size:12.5px\}}
    puts $f {  .hint\{color:var(--muted);font-size:13px;margin:-4px 0 14px\}}
    puts $f {  .stream\{max-height:460px;overflow:auto;border:1px solid var(--line);border-radius:10px;}
    puts $f {          padding:6px 12px;margin-top:10px;background:var(--card)\}}
    puts $f {  .post.fresh\{border-left-color:var(--ok);background:#f3fbf5\}}
    puts $f {  .post.fresh .when::after\{content:" NEU";color:var(--ok);font-weight:700\}}
    puts $f {  .dot\{width:8px;height:8px;border-radius:50%;background:var(--ok);display:inline-block;}
    puts $f {       margin-right:6px;animation:pulse 2s infinite\}}
    puts $f {  @keyframes pulse\{0%,100%\{opacity:1\}50%\{opacity:.35\}\}}
    puts $f {  .idle\{background:var(--muted)!important;animation:none\}}
    puts $f {  .tt-live\{background:#fe2c55;color:#fff;font-weight:700;font-size:11px;}
    puts $f {           padding:2px 9px;border-radius:99px\}}
    puts $f {  .tt-off\{background:#f1f2f4;color:var(--muted);font-weight:700;font-size:11px;}
    puts $f {          padding:2px 9px;border-radius:99px\}}
    puts $f {  .tt-player\{position:relative;width:100%;max-width:340px;aspect-ratio:9/16;background:#000;}
    puts $f {             border-radius:10px;overflow:hidden;margin-top:10px;border:1px solid var(--line)\}}
    puts $f {  .tt-player iframe\{position:absolute;inset:0;width:100%;height:100%;border:0\}}
    puts $f {  .ev\{display:flex;gap:10px;padding:7px 0;border-bottom:1px solid var(--line);font-size:13.5px\}}
    puts $f {  .ev:last-child\{border-bottom:0\}}
    puts $f {  .ev .k\{font-weight:650;white-space:nowrap\}}
    puts $f {  .ev .k.start\{color:#fe2c55\} .ev .k.end\{color:var(--muted)\}}
    puts $f {</style>}
    puts $f {  <link rel="manifest" href="/manifest.webmanifest">}
    puts $f {  <meta name="theme-color" content="#2481cc">}
    puts $f {  <link rel="icon" href="/icons/monitor-192.png">}
    puts $f {  <meta name="apple-mobile-web-app-capable" content="yes">}
    puts $f {  <meta name="apple-mobile-web-app-title" content="Monitor">}
    puts $f {  <link rel="apple-touch-icon" href="/icons/monitor-192.png">}
    puts $f {</head>}
    puts $f {<body>}
    puts $f {<header>}
    puts $f {  <h1>Telegram Monitor</h1>}
    puts $f {  <span id="statusPills" class="row" style="margin:0;gap:6px"></span>}
    puts $f {  <button id="notifyBtn" style="margin-left:auto;font:inherit;font-weight:600;border:1px solid var(--line);background:var(--bg);color:var(--text);border-radius:8px;padding:6px 12px;cursor:pointer">Meldungen erlauben</button>}
    puts $f {  <button id="installBtn" hidden style="font:inherit;font-weight:600;}
    puts $f {          border:1px solid #2481cc;background:#2481cc;color:#fff;border-radius:8px;}
    puts $f {          padding:6px 12px;cursor:pointer">Als App installieren</button>}
    puts $f {</header>}
    puts $f {<nav>}
    puts $f {  <button data-tab="live" class="active">Live</button>}
    puts $f {  <button data-tab="search">Suche</button>}
    puts $f {  <button data-tab="watch">Watchlist</button>}
    puts $f {  <button data-tab="tiktok">TikTok</button>}
    puts $f {  <button data-tab="discord">Discord</button>}
    puts $f {  <button data-tab="status">Status</button>}
    puts $f {</nav>}
    puts $f {<main>}
    puts $f {}
    puts $f {  <section class="panel active" id="panel-live">}
    puts $f {    <div class="row">}
    puts $f {      <label class="hint" style="margin:0">Aktualisierung alle</label>}
    puts $f {      <select id="liveEvery">}
    puts $f {        <option value="30">30 Sekunden</option>}
    puts $f {        <option value="60" selected>1 Minute</option>}
    puts $f {        <option value="300">5 Minuten</option>}
    puts $f {        <option value="0">nur manuell</option>}
    puts $f {      </select>}
    puts $f {      <button class="go sec" id="btnPollNow">Jetzt abrufen</button>}
    puts $f {      <span class="hint" id="liveState" style="margin:0"></span>}
    puts $f {    </div>}
    puts $f {    <p class="hint">Zeigt den fortlaufenden Verlauf aller Kanaele auf der Watchlist.}
    puts $f {      Der Server fragt im Hintergrund selbstaendig ab; diese Ansicht holt den}
    puts $f {      gesammelten Verlauf. Neue Beitraege werden markiert.</p>}
    puts $f {    <div id="liveOut"></div>}
    puts $f {  </section>}
    puts $f {}
    puts $f {  <section class="panel" id="panel-search">}
    puts $f {    <div class="row">}
    puts $f {      <input id="q" placeholder="Suchbegriff oder @name, z.B. creator" style="flex:1;min-width:240px">}
    puts $f {      <select id="limit"><option>10</option><option selected>20</option><option>40</option></select>}
    puts $f {      <button class="go" id="btnSearch">Suchen</button>}
    puts $f {    </div>}
    puts $f {    <p class="hint">Sucht ueber alle aktiven Methoden gleichzeitig: oeffentliche t.me-Vorschau,}
    puts $f {      Namensvarianten, Websuche, optional Bot-API / MTProto sowie Discord-Invites.</p>}
    puts $f {    <div id="searchOut"></div>}
    puts $f {  </section>}
    puts $f {}
    puts $f {  <section class="panel" id="panel-watch">}
    puts $f {    <div class="row">}
    puts $f {      <select id="wPlatform"><option value="telegram">Telegram</option><option value="discord">Discord</option></select>}
    puts $f {      <input id="wTarget" placeholder="@name / Invite-Code / Kanal-ID">}
    puts $f {      <input id="wNote" placeholder="Notiz (optional)">}
    puts $f {      <button class="go" id="btnAdd">Hinzufuegen</button>}
    puts $f {      <button class="go sec" id="btnScan">Uebersicht laden</button>}
    puts $f {    </div>}
    puts $f {    <div id="watchOut"></div>}
    puts $f {  </section>}
    puts $f {}
    puts $f {  <section class="panel" id="panel-tiktok">}
    puts $f {    <div class="row">}
    puts $f {      <input id="ttUser" placeholder="@name, z.B. creator" style="min-width:200px">}
    puts $f {      <button class="go" id="btnTtCheck">Status prüfen</button>}
    puts $f {      <button class="go sec" id="btnTtWatch">Beobachten</button>}
    puts $f {      <label class="hint" style="margin:0"><input type="checkbox" id="ttEmbed" checked>}
    puts $f {        Player einblenden, wenn live</label>}
    puts $f {    </div>}
    puts $f {    <p class="hint">Zeigt Live-Status, laufende Sendung und die letzten Sendungen.}
    puts $f {      Der Player ist der offizielle TikTok-Embed — ohne Anmeldung, ohne Geschenk-}
    puts $f {      und Kauf-Oberfläche. Beobachtete Konten meldet der Poller beim Livegang.</p>}
    puts $f {    <div id="ttOut"></div>}
    puts $f {    <h3 style="font-size:13px;text-transform:uppercase;letter-spacing:.04em;color:var(--muted);margin:22px 0 8px">Ereignisse</h3>}
    puts $f {    <div id="ttEvents"></div>}
    puts $f {  </section>}
    puts $f {}
    puts $f {  <section class="panel" id="panel-discord">}
    puts $f {    <div class="row">}
    puts $f {      <input id="dInvite" placeholder="discord.gg/code oder nur der Code" style="flex:1;min-width:240px">}
    puts $f {      <button class="go dc" id="btnInvite">Invite pruefen</button>}
    puts $f {      <button class="go sec" id="btnGuilds">Server des Bots</button>}
    puts $f {    </div>}
    puts $f {    <p class="hint">Invite-Pruefung funktioniert ohne Token. Server, Kanaele und Nachrichten}
    puts $f {      brauchen einen Bot-Token (<code>DISCORD_BOT_TOKEN</code>).</p>}
    puts $f {    <div id="discordOut"></div>}
    puts $f {  </section>}
    puts $f {}
    puts $f {  <section class="panel" id="panel-status">}
    puts $f {    <div id="statusOut"></div>}
    puts $f {  </section>}
    puts $f {}
    puts $f {</main>}
    puts $f {<script>}
    puts $f {const \$ = s => document.querySelector(s);}
    puts $f {const esc = s => String(s ?? '').replace(/[&<>"]/g, c => (\{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'\}[c]));}
    puts $f {const num = n => n == null ? '?' : n.toLocaleString('de-DE');}
    puts $f {const when = d => \{ if(!d) return ''; const t = new Date(d);}
    puts $f {  return isNaN(t) ? d : t.toLocaleString('de-DE',\{dateStyle:'medium',timeStyle:'short'\}); \};}
    puts $f {}
    puts $f {async function api(path, opts)\{}
    puts $f {  const r = await fetch(path, opts);}
    puts $f {  const data = await r.json().catch(() => (\{error:'Antwort war kein JSON'\}));}
    puts $f {  if(!r.ok || (data && data.error)) throw new Error(data.error || ('HTTP '+r.status));}
    puts $f {  return data;}
    puts $f {\}}
    puts $f {function busy(el, text)\{ el.innerHTML = '<div class="spin">'+esc(text)+'</div>'; \}}
    puts $f {function fail(el, e)\{ el.innerHTML = '<div class="err">'+esc(e.message)+'</div>'; \}}
    puts $f {}
    puts $f {document.querySelectorAll('nav button').forEach(b => b.onclick = () => \{}
    puts $f {  document.querySelectorAll('nav button').forEach(x => x.classList.toggle('active', x === b));}
    puts $f {  document.querySelectorAll('.panel').forEach(p =>}
    puts $f {    p.classList.toggle('active', p.id === 'panel-' + b.dataset.tab));}
    puts $f {\});}
    puts $f {}
    puts $f {function channelCard(c, extraHtml)\{}
    puts $f {  const dc = c.platform === 'discord';}
    puts $f {  const tags = [];}
    puts $f {  tags.push('<span class="tag">'+esc(c.kind)+'</span>');}
    puts $f {  if(c.readable) tags.push('<span class="tag ok">lesbar</span>');}
    puts $f {  else tags.push('<span class="tag no">nicht lesbar</span>');}
    puts $f {  if(c.verified) tags.push('<span class="tag ok">verifiziert</span>');}
    puts $f {  const av = c.avatar_url ? '<img class="avatar" src="'+esc(c.avatar_url)+'" alt="">'}
    puts $f {                          : '<div class="avatar"></div>';}
    puts $f {  const online = c.online != null ? ' &middot; '+num(c.online)+' online' : '';}
    puts $f {  return '<div class="card"><div class="head">'+av+'<div style="flex:1">'+}
    puts $f {    '<h3>'+esc(c.title || c.username || c.id)+}
    puts $f {      '<span class="pill'+(dc?' dc':'')+'">'+esc(c.platform)+'</span>'+tags.join('')+}
    puts $f {      (c.confidence != null ? '<span class="score">'+c.confidence.toFixed(2)+'</span>' : '')+'</h3>'+}
    puts $f {    '<div class="meta">'+(c.username ? '@'+esc(c.username)+' &middot; ' : '')+}
    puts $f {      num(c.members)+' Mitglieder'+online+' &middot; via '+esc(c.source)+}
    puts $f {      (c.url ? ' &middot; <a href="'+esc(c.url)+'" target="_blank" rel="noopener">oeffnen</a>' : '')+'</div>'+}
    puts $f {    (c.description ? '<div class="desc">'+esc(c.description.slice(0,400))+'</div>' : '')+}
    puts $f {    (c.extra && c.extra.note ? '<div class="meta" style="margin-top:6px">'+esc(c.extra.note)+'</div>' : '')+}
    puts $f {    (extraHtml || '')+}
    puts $f {    '</div></div></div>';}
    puts $f {\}}
    puts $f {function postsHtml(posts)\{}
    puts $f {  if(!posts || !posts.length) return '';}
    puts $f {  return posts.map(p => '<div class="post"><div class="when">'+esc(when(p.date))+}
    puts $f {    (p.views ? ' &middot; '+num(p.views)+' Aufrufe' : '')+}
    puts $f {    (p.author ? ' &middot; '+esc(p.author) : '')+}
    puts $f {    (p.url ? ' &middot; <a href="'+esc(p.url)+'" target="_blank" rel="noopener">Link</a>' : '')+}
    puts $f {    '</div><div class="txt">'+esc((p.text || '(kein Text)').slice(0,600))+'</div>'+}
    puts $f {    (p.media && p.media.length ? '<div class="when">Medien: '+}
    puts $f {      esc(p.media.map(m => m.type).join(', '))+'</div>' : '')+'</div>').join('');}
    puts $f {\}}
    puts $f {}
    puts $f {\$('#btnSearch').onclick = async () => \{}
    puts $f {  const out = \$('#searchOut'), q = \$('#q').value.trim();}
    puts $f {  if(!q) return;}
    puts $f {  busy(out, 'Suche laeuft - pruefe Namensvarianten und oeffentliche Vorschauen ...');}
    puts $f {  try\{}
    puts $f {    const r = await api('/api/search?q='+encodeURIComponent(q)+'&limit='+\$('#limit').value);}
    puts $f {    let html = '<p class="hint">'+r.count+' Treffer &middot; Methoden: '+}
    puts $f {      esc(r.methods_used.join(', '))+'</p>';}
    puts $f {    r.errors.forEach(e => html += '<div class="err">'+esc(e.method+': '+e.error)+'</div>');}
    puts $f {    html += r.results.length}
    puts $f {      ? r.results.map(c => channelCard(c,}
    puts $f {          '<div class="row" style="margin:10px 0 0">'+}
    puts $f {          (c.readable ? '<button class="go sec" data-posts="'+esc(c.username||c.id)+}
    puts $f {            '" data-platform="'+esc(c.platform)+'">Beitraege laden</button>' : '')+}
    puts $f {          '<button class="go sec" data-watch="'+esc(c.username||c.id)+}
    puts $f {            '" data-platform="'+esc(c.platform)+'">Zur Watchlist</button></div>'+}
    puts $f {          '<div class="postbox"></div>')).join('')}
    puts $f {      : '<div class="empty">Keine Treffer.</div>';}
    puts $f {    out.innerHTML = html;}
    puts $f {  \}catch(e)\{ fail(out, e); \}}
    puts $f {\};}
    puts $f {\$('#q').addEventListener('keydown', e => \{ if(e.key === 'Enter') \$('#btnSearch').click(); \});}
    puts $f {}
    puts $f {document.addEventListener('click', async ev => \{}
    puts $f {  const b = ev.target.closest('button[data-posts]');}
    puts $f {  if(b)\{}
    puts $f {    const box = b.closest('.card').querySelector('.postbox');}
    puts $f {    box.innerHTML = '<div class="spin">Lade Beitraege ...</div>';}
    puts $f {    try\{}
    puts $f {      const r = await api('/api/posts?target='+encodeURIComponent(b.dataset.posts)+}
    puts $f {        '&platform='+b.dataset.platform+'&limit=8');}
    puts $f {      box.innerHTML = r.posts.length ? postsHtml(r.posts)}
    puts $f {        : '<div class="meta">Keine Beitraege abrufbar.</div>';}
    puts $f {    \}catch(e)\{ box.innerHTML = '<div class="err">'+esc(e.message)+'</div>'; \}}
    puts $f {  \}}
    puts $f {  const w = ev.target.closest('button[data-watch]');}
    puts $f {  if(w)\{}
    puts $f {    w.disabled = true; w.textContent = 'gemerkt';}
    puts $f {    await api('/api/watchlist', \{method:'POST', headers:\{'Content-Type':'application/json'\},}
    puts $f {      body: JSON.stringify(\{action:'add', platform:w.dataset.platform, target:w.dataset.watch\})\});}
    puts $f {    loadWatch();}
    puts $f {  \}}
    puts $f {  const rm = ev.target.closest('button[data-remove]');}
    puts $f {  if(rm)\{}
    puts $f {    await api('/api/watchlist', \{method:'POST', headers:\{'Content-Type':'application/json'\},}
    puts $f {      body: JSON.stringify(\{action:'remove', platform:rm.dataset.platform, target:rm.dataset.remove\})\});}
    puts $f {    loadWatch();}
    puts $f {  \}}
    puts $f {  const ch = ev.target.closest('button[data-guild]');}
    puts $f {  if(ch)\{}
    puts $f {    const box = ch.closest('.card').querySelector('.postbox');}
    puts $f {    box.innerHTML = '<div class="spin">Lade Kanaele ...</div>';}
    puts $f {    try\{}
    puts $f {      const list = await api('/api/discord/channels?guild_id='+encodeURIComponent(ch.dataset.guild));}
    puts $f {      box.innerHTML = '<table><tr><th>Kanal</th><th>Typ</th><th>Thema</th><th></th></tr>'+}
    puts $f {        list.map(c => '<tr><td>#'+esc(c.title)+'</td><td>'+esc(c.extra.type)+'</td>'+}
    puts $f {          '<td>'+esc((c.description||'').slice(0,90))+'</td><td>'+}
    puts $f {          (c.readable ? '<button class="go sec" data-msg="'+esc(c.id)+'">Nachrichten</button>' : '')+}
    puts $f {          '</td></tr>').join('')+'</table><div class="msgbox"></div>';}
    puts $f {    \}catch(e)\{ box.innerHTML = '<div class="err">'+esc(e.message)+'</div>'; \}}
    puts $f {  \}}
    puts $f {  const mg = ev.target.closest('button[data-msg]');}
    puts $f {  if(mg)\{}
    puts $f {    const box = mg.closest('.postbox').querySelector('.msgbox');}
    puts $f {    box.innerHTML = '<div class="spin">Lade Nachrichten ...</div>';}
    puts $f {    try\{}
    puts $f {      const list = await api('/api/discord/messages?channel_id='+encodeURIComponent(mg.dataset.msg)+'&limit=10');}
    puts $f {      box.innerHTML = postsHtml(list) || '<div class="meta">Keine Nachrichten.</div>';}
    puts $f {    \}catch(e)\{ box.innerHTML = '<div class="err">'+esc(e.message)+'</div>'; \}}
    puts $f {  \}}
    puts $f {\});}
    puts $f {}
    puts $f {async function loadWatch()\{}
    puts $f {  const out = \$('#watchOut');}
    puts $f {  try\{}
    puts $f {    const items = await api('/api/watchlist');}
    puts $f {    out.innerHTML = items.length}
    puts $f {      ? '<table><tr><th>Plattform</th><th>Ziel</th><th>Notiz</th><th></th></tr>'+}
    puts $f {        items.map(i => '<tr><td>'+esc(i.platform)+'</td><td>'+esc(i.target)+'</td>'+}
    puts $f {          '<td>'+esc(i.note||'')+'</td><td><button class="go sec" data-remove="'+esc(i.target)+}
    puts $f {          '" data-platform="'+esc(i.platform)+'">entfernen</button></td></tr>').join('')+'</table>'}
    puts $f {      : '<div class="empty">Watchlist ist leer. Kanaele aus der Suche hinzufuegen.</div>';}
    puts $f {  \}catch(e)\{ fail(out, e); \}}
    puts $f {\}}
    puts $f {\$('#btnAdd').onclick = async () => \{}
    puts $f {  const t = \$('#wTarget').value.trim(); if(!t) return;}
    puts $f {  await api('/api/watchlist', \{method:'POST', headers:\{'Content-Type':'application/json'\},}
    puts $f {    body: JSON.stringify(\{action:'add', platform:\$('#wPlatform').value, target:t, note:\$('#wNote').value\})\});}
    puts $f {  \$('#wTarget').value = ''; \$('#wNote').value = ''; loadWatch();}
    puts $f {\};}
    puts $f {\$('#btnScan').onclick = async () => \{}
    puts $f {  const out = \$('#watchOut');}
    puts $f {  busy(out, 'Hole aktuelle Daten fuer alle Eintraege ...');}
    puts $f {  try\{}
    puts $f {    const r = await api('/api/scan?limit=5');}
    puts $f {    out.innerHTML = r.entries.length ? r.entries.map(e => \{}
    puts $f {      if(e.error) return '<div class="err">'+esc(e.platform+'/'+e.target+': '+e.error)+'</div>';}
    puts $f {      if(!e.channel) return '<div class="card"><b>'+esc(e.target)+'</b>'+}
    puts $f {        '<div class="meta">nicht gefunden</div></div>';}
    puts $f {      return channelCard(e.channel, postsHtml(e.posts));}
    puts $f {    \}).join('') + '<div class="row"><button class="go sec" onclick="loadWatch()">Zurueck zur Liste</button></div>'}
    puts $f {      : '<div class="empty">Watchlist ist leer.</div>';}
    puts $f {  \}catch(e)\{ fail(out, e); \}}
    puts $f {\};}
    puts $f {}
    puts $f {\$('#btnInvite').onclick = async () => \{}
    puts $f {  const out = \$('#discordOut'), v = \$('#dInvite').value.trim(); if(!v) return;}
    puts $f {  busy(out, 'Frage Discord-Invite ab ...');}
    puts $f {  try\{}
    puts $f {    const c = await api('/api/discord/invite?code='+encodeURIComponent(v));}
    puts $f {    out.innerHTML = c ? channelCard(c, '<div class="meta" style="margin-top:8px">Invite-Kanal: '+}
    puts $f {      esc((c.extra && c.extra.invite_channel) || '?')+'</div>')}
    puts $f {      : '<div class="empty">Invite ungueltig oder abgelaufen.</div>';}
    puts $f {  \}catch(e)\{ fail(out, e); \}}
    puts $f {\};}
    puts $f {\$('#btnGuilds').onclick = async () => \{}
    puts $f {  const out = \$('#discordOut');}
    puts $f {  busy(out, 'Lade Server des Bots ...');}
    puts $f {  try\{}
    puts $f {    const list = await api('/api/discord/guilds');}
    puts $f {    out.innerHTML = list.length ? list.map(g => channelCard(g,}
    puts $f {      '<div class="row" style="margin:10px 0 0"><button class="go sec" data-guild="'+}
    puts $f {      esc(g.id)+'">Kanaele anzeigen</button></div><div class="postbox"></div>')).join('')}
    puts $f {      : '<div class="empty">Der Bot ist auf keinem Server. Einladungslink: '+}
    puts $f {        '<code>python cli.py discord invite-url &lt;CLIENT_ID&gt;</code></div>';}
    puts $f {  \}catch(e)\{ fail(out, e); \}}
    puts $f {\};}
    puts $f {}
    puts $f {let liveTimer = null, liveCountdown = null, seenIds = new Set(), firstLiveLoad = true;}
    puts $f {}
    puts $f {function renderLive(entries, poller)\{}
    puts $f {  const out = document.getElementById('liveOut');}
    puts $f {  if(!entries.length)\{}
    puts $f {    out.innerHTML = '<div class="empty">Watchlist ist leer - Kanaele im Reiter Suche hinzufuegen.</div>';}
    puts $f {    return;}
    puts $f {  \}}
    puts $f {  out.innerHTML = entries.map(e => \{}
    puts $f {    const posts = e.posts || [];}
    puts $f {    const head = '<h3><span class="dot'+(posts.length?'':' idle')+'"></span>'+}
    puts $f {      esc(e.target)+'<span class="pill'+(e.platform==='discord'?' dc':'')+'">'+}
    puts $f {      esc(e.platform)+'</span></h3>'+}
    puts $f {      '<div class="meta">'+e.total+' Beitraege gesammelt &middot; '+e.polls+' Abrufe &middot; '+}
    puts $f {      'zuletzt geprueft '+esc(when(e.last_poll))}
    puts $f {      +(e.last_new ? ' &middot; letzter neuer Beitrag '+esc(when(e.last_new)) : '')+'</div>'+}
    puts $f {      (e.errors && e.errors.length ? '<div class="err" style="margin-top:8px">'+}
    puts $f {        esc(e.errors[0].error)+'</div>' : '');}
    puts $f {    const body = posts.length}
    puts $f {      ? '<div class="stream">'+posts.map(p => \{}
    puts $f {          const fresh = !firstLiveLoad && !seenIds.has(p.id);}
    puts $f {          return '<div class="post'+(fresh?' fresh':'')+'"><div class="when">'+esc(when(p.date))+}
    puts $f {            (p.views ? ' &middot; '+num(p.views)+' Aufrufe' : '')+}
    puts $f {            (p.author ? ' &middot; '+esc(p.author) : '')+}
    puts $f {            (p.url ? ' &middot; <a href="'+esc(p.url)+'" target="_blank" rel="noopener">Link</a>' : '')+}
    puts $f {            '</div><div class="txt">'+esc((p.text || '(kein Text)').slice(0,800))+'</div>'+}
    puts $f {            (p.media && p.media.length ? '<div class="when">Medien: '+}
    puts $f {              esc(p.media.map(m=>m.type).join(', '))+'</div>' : '')+'</div>';}
    puts $f {        \}).join('')+'</div>'}
    puts $f {      : '<div class="meta" style="margin-top:8px">Noch keine Beitraege gesammelt. '+}
    puts $f {        'Entweder gibt es keine oeffentliche Vorschau oder der Kanal hat nichts veroeffentlicht.</div>';}
    puts $f {    return '<div class="card">'+head+body+'</div>';}
    puts $f {  \}).join('');}
    puts $f {  entries.forEach(e => (e.posts||[]).forEach(p => seenIds.add(p.id)));}
    puts $f {  firstLiveLoad = false;}
    puts $f {  const st = document.getElementById('liveState');}
    puts $f {  st.textContent = poller && poller.running}
    puts $f {    ? 'Hintergrund-Abfrage aktiv (alle '+poller.interval+' s, '+poller.cycles+' Durchlaeufe)'}
    puts $f {    : 'Hintergrund-Abfrage inaktiv';}
    puts $f {\}}
    puts $f {}
    puts $f {async function loadLive()\{}
    puts $f {  try\{}
    puts $f {    const [data, poller] = await Promise.all([}
    puts $f {      api('/api/live/all?limit=30'), api('/api/poller').catch(() => null)]);}
    puts $f {    renderLive(data.entries || [], poller);}
    puts $f {  \}catch(e)\{ fail(document.getElementById('liveOut'), e); \}}
    puts $f {\}}
    puts $f {}
    puts $f {function scheduleLive()\{}
    puts $f {  if(liveTimer) clearInterval(liveTimer);}
    puts $f {  if(liveCountdown) clearInterval(liveCountdown);}
    puts $f {  const every = parseInt(document.getElementById('liveEvery').value, 10);}
    puts $f {  if(!every) return;}
    puts $f {  let left = every;}
    puts $f {  liveTimer = setInterval(() => \{ left = every; loadLive(); \}, every * 1000);}
    puts $f {  liveCountdown = setInterval(() => \{}
    puts $f {    left = Math.max(0, left - 1);}
    puts $f {    const st = document.getElementById('liveState');}
    puts $f {    if(st && st.textContent) st.dataset.base = st.dataset.base || '';}
    puts $f {  \}, 1000);}
    puts $f {\}}
    puts $f {document.getElementById('liveEvery').addEventListener('change', scheduleLive);}
    puts $f {document.getElementById('btnPollNow').onclick = async () => \{}
    puts $f {  const btn = document.getElementById('btnPollNow');}
    puts $f {  btn.disabled = true; btn.textContent = 'Rufe ab ...';}
    puts $f {  try\{}
    puts $f {    const items = await api('/api/watchlist');}
    puts $f {    await Promise.all(items.map(i => api('/api/live/poll?platform='+i.platform+}
    puts $f {      '&target='+encodeURIComponent(i.target)).catch(() => null)));}
    puts $f {    await loadLive();}
    puts $f {  \}finally\{ btn.disabled = false; btn.textContent = 'Jetzt abrufen'; \}}
    puts $f {\};}
    puts $f {}
    puts $f {}
    puts $f {/* --------------------------------------------------------------- TikTok --- */}
    puts $f {function ttCard(st)\{}
    puts $f {  const live = st.live === true;}
    puts $f {  const player = (live && document.getElementById('ttEmbed').checked)}
    puts $f {    ? '<div class="tt-player"><iframe src="' + esc(st.embed_url) +}
    puts $f {      '" allow="autoplay; encrypted-media; picture-in-picture" referrerpolicy="origin" ' +}
    puts $f {      'title="TikTok Live von @' + esc(st.username) + '"></iframe></div>' : '';}
    puts $f {  const streams = (st.streams || []).slice(0, 8).map(x =>}
    puts $f {    '<div class="post' + (x.is_live ? ' fresh' : '') + '"><div class="when">' +}
    puts $f {    esc(x.day) + ' ' + esc(x.time || '') + (x.duration ? ' · ' + esc(x.duration) : '') +}
    puts $f {    (x.is_live ? ' · läuft' : '') + '</div><div class="txt">' +}
    puts $f {    esc(x.title || '(ohne Titel)') + '</div></div>').join('');}
    puts $f {  return '<div class="card"><h3>@' + esc(st.username) +}
    puts $f {    (live ? '<span class="tt-live">LIVE</span>' : '<span class="tt-off">offline</span>') +}
    puts $f {    '<span class="pill">tiktok</span></h3>' +}
    puts $f {    '<div class="meta">' +}
    puts $f {      (st.title ? esc(st.title) + ' · ' : '') +}
    puts $f {      (st.started_at ? 'Beginn ' + esc(st.started_at.replace('T', ' ')) : '') +}
    puts $f {      (st.since ? ' · seit ca. ' + esc(st.since) : '') +}
    puts $f {      (st.last_seen ? ' · zuletzt gesehen ' + esc(st.last_seen) : '') + '</div>' +}
    puts $f {    '<div class="meta">' + (st.streams_total || '?') + ' Sendungen · ' +}
    puts $f {      esc(st.airtime || '?') + ' Sendezeit · ' + (st.active_days || '?') + ' aktive Tage · ' +}
    puts $f {      '<a href="' + esc(st.live_url) + '" target="_blank" rel="noopener">Live-Seite</a> · ' +}
    puts $f {      '<a href="' + esc(st.embed_url) + '" target="_blank" rel="noopener">Embed</a></div>' +}
    puts $f {    player +}
    puts $f {    (streams ? '<div class="stream" style="max-height:260px">' + streams + '</div>' : '') +}
    puts $f {    '</div>';}
    puts $f {\}}
    puts $f {async function ttCheck()\{}
    puts $f {  const out = document.getElementById('ttOut');}
    puts $f {  const u = document.getElementById('ttUser').value.trim().replace(/^@/, '');}
    puts $f {  busy(out, 'Frage Status ab ...');}
    puts $f {  try\{}
    puts $f {    const r = await api('/api/tiktok/status' + (u ? '?users=' + encodeURIComponent(u) : ''));}
    puts $f {    out.innerHTML = (r.accounts || []).length}
    puts $f {      ? r.accounts.map(ttCard).join('')}
    puts $f {      : '<div class="empty">Kein Konto angegeben und keines auf der Watchlist.</div>';}
    puts $f {  \}catch(e)\{ fail(out, e); \}}
    puts $f {\}}
    puts $f {async function ttEvents()\{}
    puts $f {  const out = document.getElementById('ttEvents');}
    puts $f {  try\{}
    puts $f {    const evs = await api('/api/events?limit=30');}
    puts $f {    out.innerHTML = evs.length ? evs.map(e =>}
    puts $f {      '<div class="ev"><span class="when" style="color:var(--muted);white-space:nowrap">' +}
    puts $f {      esc(when(e.at)) + '</span><span class="k ' +}
    puts $f {      (e.kind === 'live_start' ? 'start' : 'end') + '">' + esc(e.kind) + '</span>' +}
    puts $f {      '<span style="flex:1">' + esc(e.title) + ' — ' + esc(e.text) +}
    puts $f {      (e.url ? ' <a href="' + esc(e.url) + '" target="_blank" rel="noopener">öffnen</a>' : '') +}
    puts $f {      '</span></div>').join('')}
    puts $f {      : '<div class="empty">Noch keine Ereignisse. Der Poller meldet hier den Livegang.</div>';}
    puts $f {  \}catch(e)\{ fail(out, e); \}}
    puts $f {\}}
    puts $f {document.getElementById('btnTtCheck').onclick = ttCheck;}
    puts $f {document.getElementById('ttEmbed').addEventListener('change', ttCheck);}
    puts $f {document.getElementById('ttUser').addEventListener('keydown', e => \{}
    puts $f {  if(e.key === 'Enter') ttCheck();}
    puts $f {\});}
    puts $f {document.getElementById('btnTtWatch').onclick = async () => \{}
    puts $f {  const u = document.getElementById('ttUser').value.trim().replace(/^@/, '');}
    puts $f {  if(!u) return;}
    puts $f {  await api('/api/watchlist', \{method:'POST', headers:\{'Content-Type':'application/json'\},}
    puts $f {    body: JSON.stringify(\{action:'add', platform:'tiktok', target:u, note:'TikTok Live'\})\});}
    puts $f {  loadWatch(); ttCheck();}
    puts $f {\};}
    puts $f {}
    puts $f {async function loadStatus()\{}
    puts $f {  try\{}
    puts $f {    const s = await api('/api/status');}
    puts $f {    \$('#statusPills').innerHTML = s.methods.map(m =>}
    puts $f {      '<span class="pill'+(m.available ? '' : ' off')+'">'+esc(m.name)+'</span>').join('');}
    puts $f {    \$('#statusOut').innerHTML = '<table><tr><th>Methode</th><th>Plattform</th><th>Status</th>'+}
    puts $f {      '<th>Kann</th></tr>'+ s.methods.map(m =>}
    puts $f {      '<tr><td><b>'+esc(m.name)+'</b></td><td>'+esc(m.platform)+'</td>'+}
    puts $f {      '<td>'+(m.available ? '<span class="tag ok">aktiv</span>' : '<span class="tag">inaktiv</span>')+}
    puts $f {      '<div class="meta">'+esc(m.reason)+'</div></td>'+}
    puts $f {      '<td>'+esc(m.capabilities.join(', ') || '-')+'</td></tr>').join('')+'</table>';}
    puts $f {  \}catch(e)\{ fail(\$('#statusOut'), e); \}}
    puts $f {\}}
    puts $f {loadStatus(); loadWatch(); loadLive(); scheduleLive(); ttCheck(); ttEvents();}
    puts $f {setInterval(ttEvents, 60000);}
    puts $f {</script>}
    puts $f {<script>}
    puts $f {/* Als App installierbar machen. Der Service Worker laeuft nur ueber}
    puts $f {   127.0.0.1 oder https — beides ist hier gegeben. */}
    puts $f {if ('serviceWorker' in navigator) \{}
    puts $f {  window.addEventListener('load', () => \{}
    puts $f {    navigator.serviceWorker.register('/sw.js').catch(() => \{\});}
    puts $f {  \});}
    puts $f {\}}
    puts $f {/* Eigener Installationsknopf: Chrome/Edge blenden den eigenen erst spaet ein. */}
    puts $f {let deferredPrompt = null;}
    puts $f {window.addEventListener('beforeinstallprompt', e => \{}
    puts $f {  e.preventDefault();}
    puts $f {  deferredPrompt = e;}
    puts $f {  const b = document.getElementById('installBtn');}
    puts $f {  if (b) \{ b.hidden = false; b.onclick = async () => \{}
    puts $f {    b.hidden = true;}
    puts $f {    deferredPrompt.prompt();}
    puts $f {    await deferredPrompt.userChoice;}
    puts $f {    deferredPrompt = null;}
    puts $f {  \}; \}}
    puts $f {\});}
    puts $f {window.addEventListener('appinstalled', () => \{}
    puts $f {  const b = document.getElementById('installBtn'); if (b) b.hidden = true;}
    puts $f {\});}
    puts $f {</script>}
    puts $f {<script>}
    puts $f {/* ------------------------------------------------------------------------}
    puts $f {   Meldung beim Livegang — auch auf dem Telefon.}
    puts $f {}
    puts $f {   Der Poller im Server erkennt den Wechsel und schreibt ihn nach}
    puts $f {   data/events.json. Diese Seite sieht im Turnus nach und laesst den}
    puts $f {   Service Worker die Meldung anzeigen; dadurch erscheint sie auch, wenn}
    puts $f {   die App im Hintergrund ist. Auf Android verhaelt sie sich damit wie}
    puts $f {   die Meldung einer gewoehnlichen App.}
    puts $f {}
    puts $f {   Bewusst NICHT beim ersten Durchlauf melden: sonst kaeme nach jedem}
    puts $f {   Start eine Welle alter Ereignisse, und der Nutzer schaltet sie ab.}
    puts $f {   ------------------------------------------------------------------------ */}
    puts $f {(() => \{}
    puts $f {  const KEY = 'tm.lastEvent';}
    puts $f {  const btn = document.getElementById('notifyBtn');}
    puts $f {  if (!btn) return;}
    puts $f {}
    puts $f {  const supported = 'Notification' in window && 'serviceWorker' in navigator;}
    puts $f {  if (!supported) \{ btn.hidden = true; return; \}}
    puts $f {}
    puts $f {  function paint() \{}
    puts $f {    const p = Notification.permission;}
    puts $f {    btn.textContent = p === 'granted' ? 'Meldungen an'}
    puts $f {                    : p === 'denied'  ? 'Meldungen blockiert'}
    puts $f {                                      : 'Meldungen erlauben';}
    puts $f {    btn.disabled = p === 'denied';}
    puts $f {    btn.title = p === 'denied'}
    puts $f {      ? 'Im Browser unter Website-Einstellungen wieder freigeben.'}
    puts $f {      : 'Meldet den Livegang, auch wenn diese Seite im Hintergrund ist.';}
    puts $f {  \}}
    puts $f {  paint();}
    puts $f {}
    puts $f {  /* Die Erlaubnis muss aus einer Nutzerhandlung heraus erfragt werden —}
    puts $f {     ungefragt beim Laden lehnen Browser ab. */}
    puts $f {  btn.onclick = async () => \{}
    puts $f {    const p = await Notification.requestPermission();}
    puts $f {    paint();}
    puts $f {    if (p === 'granted') \{}
    puts $f {      localStorage.setItem(KEY, new Date().toISOString());   // ab jetzt, nicht rueckwirkend}
    puts $f {      tick();}
    puts $f {    \}}
    puts $f {  \};}
    puts $f {}
    puts $f {  async function show(ev) \{}
    puts $f {    try \{}
    puts $f {      const reg = await navigator.serviceWorker.ready;}
    puts $f {      reg.active.postMessage(\{}
    puts $f {        type: 'notify',}
    puts $f {        title: ev.title || 'Livegang',}
    puts $f {        body:  ev.text || '',}
    puts $f {        url:   ev.url || '/',}
    puts $f {        tag:   'tm-' + (ev.target || 'x')}
    puts $f {      \});}
    puts $f {    \} catch (_) \{}
    puts $f {      new Notification(ev.title || 'Livegang', \{ body: ev.text || '' \});}
    puts $f {    \}}
    puts $f {  \}}
    puts $f {}
    puts $f {  async function tick() \{}
    puts $f {    if (Notification.permission !== 'granted') return;}
    puts $f {    let evs;}
    puts $f {    try \{}
    puts $f {      const r = await fetch('/api/events?limit=10', \{ cache: 'no-store' \});}
    puts $f {      if (!r.ok) return;}
    puts $f {      evs = await r.json();}
    puts $f {    \} catch (_) \{ return; \}                 // Netzfehler ist kein Ereignis}
    puts $f {    if (!Array.isArray(evs) || !evs.length) return;}
    puts $f {}
    puts $f {    const seit = localStorage.getItem(KEY);}
    puts $f {    if (!seit) \{ localStorage.setItem(KEY, evs[0].at); return; \}   // erster Lauf: nur merken}
    puts $f {}
    puts $f {    const neu = evs.filter(e => e.at > seit && String(e.kind).includes('start'));}
    puts $f {    if (neu.length) \{}
    puts $f {      localStorage.setItem(KEY, evs[0].at);}
    puts $f {      neu.reverse().forEach(show);          // aelteste zuerst}
    puts $f {    \} else if (evs[0].at > seit) \{}
    puts $f {      localStorage.setItem(KEY, evs[0].at); // Ende-Ereignisse still mitfuehren}
    puts $f {    \}}
    puts $f {  \}}
    puts $f {}
    puts $f {  setInterval(tick, 60000);}
    puts $f {  tick();}
    puts $f {\})();}
    puts $f {</script>}
    puts $f {</body>}
    puts $f {</html>}
    
    close $f
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}

write_index_html [lindex $argv 0]
