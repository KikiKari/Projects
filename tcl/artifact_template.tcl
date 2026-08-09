#!/usr/bin/env tclsh
# artifact_template.html — portiert nach tcl
# Quelle: html, Projects@Telegram-Monitor:web/artifact_template.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 script to generate artifact_template.html
# This script generates the complete HTML document as a string and writes it to a file.

proc generate_html {} {
    set html {<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<title>Telegram Monitor - Live</title>
<style>
  :root{
    --bg:#ffffff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#6b7280;
    --accent:#2481cc; --accent-soft:#e8f2fb; --discord:#5865f2; --discord-soft:#eceefe;
    --ok:#15803d; --ok-soft:#e7f6ec; --err:#b91c1c; --err-soft:#fdeceb;
    --warn:#b45309; --warn-soft:#fdf3e3;
    color-scheme: light;
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);
       font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  .wrap{max-width:940px;margin:0 auto;padding:4px 2px 40px}
  h1{font-size:20px;margin:0 0 4px}
  h2{font-size:14px;margin:26px 0 10px;text-transform:uppercase;letter-spacing:.05em;
     color:var(--muted);font-weight:650}
  .sub{color:var(--muted);font-size:13px;margin:0 0 12px}
  .bar{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin:12px 0 6px}
  select,input{font:inherit;border:1px solid var(--line);border-radius:8px;padding:7px 10px;
               background:var(--bg);color:var(--text)}
  button{font:inherit;font-weight:600;border:1px solid var(--line);background:var(--bg);
         color:var(--text);border-radius:8px;padding:7px 13px;cursor:pointer}
  button.primary{background:var(--accent);border-color:var(--accent);color:#fff}
  button:disabled{opacity:.55;cursor:default}
  .live{display:inline-flex;align-items:center;gap:7px;font-size:12.5px;color:var(--muted);
        font-weight:600}
  .dot{width:9px;height:9px;border-radius:50%;background:var(--ok);
       animation:pulse 1.8s infinite}
  .dot.paused{background:var(--muted);animation:none}
  .dot.err{background:var(--err);animation:none}
  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
  .chips{display:flex;gap:6px;flex-wrap:wrap;margin:8px 0 4px}
  .chip{font-size:11.5px;padding:3px 9px;border-radius:99px;background:var(--ok-soft);
        color:var(--ok);font-weight:650}
  .chip.off{background:var(--soft);color:var(--muted)}
  .chip.mode{background:var(--accent-soft);color:var(--accent)}
  .chip.warn{background:var(--warn-soft);color:var(--warn)}
  .card{border:1px solid var(--line);border-radius:12px;padding:14px 16px;margin-bottom:10px}
  .head{display:flex;gap:11px;align-items:flex-start}
  .avatar{width:38px;height:38px;border-radius:50%;object-fit:cover;background:var(--soft);flex:none}
  .title{font-weight:650;font-size:15px;display:flex;gap:7px;align-items:center;flex-wrap:wrap}
  .meta{color:var(--muted);font-size:12.5px;margin-top:2px}
  .desc{font-size:13.5px;margin-top:7px;white-space:pre-wrap}
  .tag{font-size:11px;padding:2px 7px;border-radius:5px;background:var(--soft);
       color:var(--muted);font-weight:650}
  .tag.tg{background:var(--accent-soft);color:var(--accent)}
  .tag.dc{background:var(--discord-soft);color:var(--discord)}
  .tag.ok{background:var(--ok-soft);color:var(--ok)}
  .tag.no{background:var(--err-soft);color:var(--err)}
  .score{font-variant-numeric:tabular-nums;font-size:11.5px;color:var(--muted);
         border:1px solid var(--line);border-radius:5px;padding:1px 6px}
  .stream{max-height:430px;overflow:auto;border:1px solid var(--line);border-radius:10px;
          padding:4px 12px;margin-top:11px;background:var(--soft)}
  .post{border-left:3px solid var(--accent-soft);padding:6px 0 6px 11px;margin:9px 0;
        background:var(--bg);border-radius:0 6px 6px 0;padding-right:8px}
  .post.fresh{border-left-color:var(--ok);background:#f3fbf5}
  .when{color:var(--muted);font-size:12px}
  .txt{font-size:13.5px;white-space:pre-wrap;margin-top:3px;word-break:break-word}
  .reac{font-size:12px;color:var(--muted);margin-top:4px}
  .new-badge{background:var(--ok);color:#fff;font-size:10.5px;font-weight:700;
             padding:1px 6px;border-radius:4px;margin-left:6px}
  .empty{color:var(--muted);border:1px dashed var(--line);border-radius:10px;
         padding:16px;text-align:center;font-size:13.5px}
  .errbox{background:var(--err-soft);border:1px solid #f5c6c2;color:var(--err);
          padding:9px 12px;border-radius:8px;font-size:13px;margin-top:8px}
  .note{background:var(--soft);border:1px solid var(--line);border-radius:10px;
        padding:12px 14px;font-size:13.5px;color:var(--muted);margin-top:18px}
  .note b{color:var(--text)}
  code{background:var(--soft);padding:1px 5px;border-radius:4px;font-size:12.5px;
       font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
  a{color:var(--accent);text-decoration:none} a:hover{text-decoration:underline}
  details{margin-top:20px;border:1px solid var(--line);border-radius:12px;padding:12px 14px}
  summary{cursor:pointer;font-weight:650;font-size:14px}
</style>
</head>
<body>
<div class="wrap">
  <h1>Telegram Monitor</h1>
  <p class="sub" id="stand"></p>

  <div class="bar">
    <span class="live"><span class="dot" id="dot"></span><span id="liveLabel">bereit</span></span>
    <select id="every">
      <option value="30">alle 30 s</option>
      <option value="60" selected>alle 60 s</option>
      <option value="180">alle 3 min</option>
      <option value="600">alle 10 min</option>
      <option value="0">nur manuell</option>
    </select>
    <button class="primary" id="now">Jetzt abrufen</button>
    <button id="pause">Pause</button>
    <span class="chips" id="modeChips"></span>
  </div>

  <h2>Beobachtete Kanäle</h2>
  <div class="bar" style="margin-top:0">
    <input id="addName" placeholder="@name eines öffentlichen Kanals" style="flex:1;min-width:200px">
    <button id="add">Beobachten</button>
  </div>
  <div id="live"></div>

  <h2>Suchtreffer</h2>
  <p class="sub" id="searchmeta"></p>
  <div id="search"></div>

  <h2>Zugangsmethoden</h2>
  <div class="chips" id="chips"></div>

  <details>
    <summary>Wie die Live-Abfrage funktioniert</summary>
    <p class="sub" style="margin-top:10px">
      Diese Ansicht fragt jeden beobachteten Kanal im eingestellten Turnus selbst ab.
      Zwei Wege, automatisch in dieser Reihenfolge:
    </p>
    <ol class="sub">
      <li><b>Lokales Werkzeug</b> (bevorzugt) — führt <code>cli.py --json live &lt;kanal&gt; --once</code>
        im Projektordner aus. Liefert exakte Zeitstempel, Aufrufzahlen und einen
        dauerhaften Verlauf auf der Festplatte.</li>
      <li><b>Direktabruf der Web-Vorschau</b> — liest <code>t.me/s/&lt;kanal&gt;</code> und wertet
        den Text aus. Funktioniert ohne das lokale Werkzeug, kennt aber nur die
        Uhrzeit, nicht das Datum eines Beitrags.</li>
    </ol>
    <p class="sub">Der gesammelte Verlauf bleibt in dieser Ansicht gespeichert und
      wächst mit jedem Durchlauf. Neue Beiträge werden grün markiert.
      Für Dauerbetrieb im Hintergrund: <code>python server.py --poll-interval 120</code>.</p>
    <div class="bar"><button id="reset">Verlauf in dieser Ansicht löschen</button></div>
  </details>

  <div class="note">
    <b>Reichweite:</b> Öffentliche Kanäle sind vollständig lesbar. Private Nutzerkonten
    liefern nur Name und Bio — dort bleibt der Verlauf leer, das ist eine
    Telegram-Einschränkung. Für nicht-öffentliche Kanäle wird Methode
    <code>mtproto</code> benötigt, für Discord-Nachrichten ein Bot-Token.
  </div>
</div>

<script>
const BAKED = /*__DATA__*/{};
const esc = s => String(s ?? '').replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const num = n => n == null ? '?' : Number(n).toLocaleString('de-DE');
const nowIso = () => new Date().toISOString();
function when(d){
  if(!d) return '';
  const t = new Date(d);
  return isNaN(t) ? String(d) : t.toLocaleString('de-DE',{dateStyle:'medium',timeStyle:'short'});
}

/* ------------------------------------------------------------ Zustand --- */
const LS = 'tgmon.live.v1';
function loadState(){
  try{ const s = localStorage.getItem(LS); if(s) return JSON.parse(s); }catch(e){}
  const channels = ((BAKED.overview && BAKED.overview.entries) || [])
    .map(e => ({platform: e.platform || 'telegram', target: e.target,
                channel: e.channel || null,
                posts: sortPosts((e.posts || []).map(p => Object.assign({}, p, {seen_at: null}))),
                last_poll: null, polls: 0, error: null}));
  return {channels, mode: null, updated: BAKED.generated_at || null};
}
let ST = loadState();
const save = () => { try{ localStorage.setItem(LS, JSON.stringify(ST)); }catch(e){} };

/* ---------------------------------------------------------- Sortierung --- */
// Telegram vergibt fortlaufende Beitragsnummern - sie sind das verlaesslichste
// Ordnungsmerkmal, weil der eingebettete Datenstand und der Live-Abruf sonst
// unterschiedliche Angaben liefern (mal Datum, mal nur Uhrzeit).
function postNo(p){
  if(p.no != null) return Number(p.no);
  const m = String(p.id || '').match(/[\/#](\d+)(?:-|$)/);
  return m ? parseInt(m[1], 10) : null;
}
function sortPosts(list){
  return list.slice().sort((a, b) => {
    const na = postNo(a), nb = postNo(b);
    if(na != null && nb != null && na !== nb) return nb - na;      // neueste zuerst
    const da = a.date ? Date.parse(a.date) : NaN;
    const db = b.date ? Date.parse(b.date) : NaN;
    if(!isNaN(da) && !isNaN(db) && da !== db) return db - da;
    const sa = a.seen_at ? Date.parse(a.seen_at) : 0;
    const sb = b.seen_at ? Date.parse(b.seen_at) : 0;
    return sb - sa;
  });
}

/* ------------------------------------------------------- Werkzeugaufruf --- */
const TAVILY = 'mcp__0ed159c9-d255-4173-8de6-52405fa59915__tavily_extract';
function txt(r){
  if(!r) return '';
  if(typeof r === 'string') return r;
  if(r.content && r.content.length) return r.content.map(c => c.text || '').join('\n');
  return r.error ? String(r.error) : '';
}
async function callTool(name, args){
  if(!window.cowork || typeof window.cowork.callMcpTool !== 'function'){
    throw new Error('Diese Ansicht kann hier keine Werkzeuge aufrufen - ' +
      'bitte im Cowork-Fenster oeffnen oder das lokale Werkzeug nutzen.');
  }
  return await window.cowork.callMcpTool(name, args);
}

/* ------------------------------------------------- Weg 1: lokales Tool --- */
async function viaBash(target){
  // Projektordner selbst finden - egal ob er im Projektverzeichnis oder im
  // Ausgabeordner liegt. Erkennungsmerkmal: das Paket tgmon/ neben cli.py.
  const cmd = 'p=$(ls -d /sessions/*/mnt/*/tgmon /sessions/*/mnt/*/*/tgmon 2>/dev/null | head -1); ' +
    'p=${p%/tgmon}; cd "$p" && python3 cli.py --json live ' +
    JSON.stringify(target) + ' --once --limit 25';
  const r = await callTool('mcp__workspace__bash', {command: cmd});
  if(r.isError) throw new Error('lokales Werkzeug: ' + txt(r));
  const raw = txt(r) || (r.structuredContent ? JSON.stringify(r.structuredContent) : '');
  const a = raw.indexOf('{'), b = raw.lastIndexOf('}');
  if(a < 0 || b < a) throw new Error('lokales Werkzeug: keine JSON-Antwort');
  const data = JSON.parse(raw.slice(a, b + 1));
  const entry = (data.entries || [])[0];
  if(!entry) throw new Error('lokales Werkzeug: leere Antwort');
  return {posts: entry.posts || [], exact: true, total: entry.total};
}

/* ------------------------------------------- Weg 2: Web-Vorschau lesen --- */
function parsePreview(md, target){
  // Beitragsende erkennen: "679 views", "120 voters686 views",
  // optional gefolgt von "[00:11](https://t.me/kanal/259)" (anderes Abrufformat).
  const term = /(?:([\d.,]+[KM]?)\s*voters)?\s*([\d.,]+[KM]?)\s*views(?:\s*\[(\d{1,2}:\d{2})\]\(https:\/\/t\.me\/[A-Za-z0-9_]+\/(\d+)\))?/g;
  const linkRe = new RegExp('https://t\\.me/(' + target.replace(/[^A-Za-z0-9_]/g, '') + ')/(\\d+)', 'g');
  const out = [];
  let prev = 0, m, idx = 0;
  while((m = term.exec(md)) !== null){
    const block = md.slice(prev, m.index);
    prev = term.lastIndex;
    if(!block.trim()) continue;
    const parsed = cleanBlock(block);

    // Beitragsnummer: entweder aus dem Zeitstempel-Link oder aus einem
    // t.me-Link im Block; sonst ersatzweise aus dem Textinhalt.
    let postNo = m[4] || null;
    if(!postNo){
      let l, last = null;
      linkRe.lastIndex = 0;
      while((l = linkRe.exec(block)) !== null) last = l[2];
      postNo = last;
    }
    const id = postNo ? target + '/' + postNo : target + '#' + hash(parsed.text + (parsed.reactions || '') + idx);
    out.push({
      platform: 'telegram', channel: target, id: id,
      url: postNo ? 'https://t.me/' + target + '/' + postNo : '',
      date: null, time: m[3] || null, no: postNo ? parseInt(postNo, 10) : null,
      text: parsed.text,
      views: parseCount(m[2]), voters: m[1] ? parseCount(m[1]) : null,
      reactions: parsed.reactions, media: parsed.media, source: 'web-vorschau'
    });
    idx++;
  }
  // Manche Beitraege haben keinen eigenen Link in der Vorschau. Telegrams
  // Nummerierung hat Luecken, also wird NICHT geraten - stattdessen ein
  // stabiler Schluessel aus letzter bekannter Nummer + Textkennung. Er dient
  // nur der Wiedererkennung; es wird kein falscher Link erzeugt.
  let anchor = 0;
  for(const post of out){
    if(post.no != null){ anchor = post.no; continue; }
    post.id = target + '#' + anchor + '-' + hash(post.text + (post.reactions || ''));
    post.no = anchor + 0.5;                       // Sortierung: direkt nach dem Anker
    post.no_exact = false;
    post.url = 'https://t.me/s/' + target;        // wenigstens die Kanalvorschau
  }

  // Der Kanalname steht in jedem Block als erste Zeile - einmal ermitteln, ueberall entfernen.
  const firsts = {};
  out.forEach(p => { const f = (p.text || '').split('\n')[0]; if(f) firsts[f] = (firsts[f] || 0) + 1; });
  const top = Object.entries(firsts).sort((a, b) => b[1] - a[1])[0];
  if(top && top[1] >= Math.max(2, out.length * 0.6)){
    out.forEach(p => {
      const lines = (p.text || '').split('\n');
      while(lines.length && lines[0] === top[0]) lines.shift();   // ggf. mehrfach
      p.text = lines.join('\n').trim();
      p.channel_title = top[0];
    });
  }
  return out;
}
function hash(str){
  let h = 5381;
  for(let i = 0; i < str.length; i++) h = ((h << 5) + h + str.charCodeAt(i)) | 0;
  return Math.abs(h).toString(36);
}
function parseCount(v){
  if(!v) return null;
  const s = String(v).replace(/\s/g,'');
  const mult = /K$/i.test(s) ? 1000 : (/M$/i.test(s) ? 1000000 : 1);
  const n = parseFloat(s.replace(/[KM]/ig,'').replace(/\./g, mult>1 ? '.' : '').replace(/,/g,'.'));
  return isNaN(n) ? null : Math.round(n * mult);
}
function cleanBlock(raw){
  let t = raw, media = [];
  if(/telesco\.pe\/file\/[^\s)]*\.mp4/.test(t)) media.push('video');
  if(/telesco\.pe\/file\/[^\s)]*\.jpg/.test(t)) media.push('bild');
  t = t.replace(/\[\*!\[\]\([^)]*\)\*\]\([^)]*\)/g, ' ');
  t = t.replace(/\*!\[\]\([^)]*\)\*/g, ' ').replace(/!\[\]\([^)]*\)/g, ' ');
  for(let i = 0; i < 4; i++){
    t = t.replace(/\[([^\[\]]*)\]\((?:[^()]|\([^()]*\))*\)/g, '$1');
  }
  t = t.replace(/<(https?:\/\/[^>]+)>/g, '$1');
  t = t.replace(/https:\/\/cdn\d+\.telesco\.pe\/\S+/g, ' ');
  t = t.replace(/\*{1,3}/g, '');
  t = t.replace(/Please open Telegram to view this post/g, ' ');
  t = t.replace(/VIEW IN TELEGRAM/g, ' ');
  t = t.replace(/This media is not supported in your browser/g, ' ');
  t = t.replace(/Download Telegram|Join\b/g, ' ');
  t = t.split('\n').map(l => l.trim()).filter(l =>
        l.length &&
        !/^\d{1,2}:\d{2}$/.test(l) &&                                   // Videodauer
        !/^[\d.,]+[KM]?\s+(subscribers|members|photos|videos|links|files|abonnenten)$/i.test(l) &&
        !/^(join|download telegram|telegram)$/i.test(l)                  // Seitenkopf
      ).join('\n');

  // Reaktionsleiste am Ende abtrennen (z. B. "❤36🔥3😴2")
  let reactions = '';
  const lines = t.split('\n');
  while(lines.length){
    const last = lines[lines.length - 1];
    if(/^(?:[^\w\s]{1,6}\s?[\d.,]+K?)+$/u.test(last)){ reactions = lines.pop() + ' ' + reactions; }
    else break;
  }
  t = lines.join('\n').replace(/\n{3,}/g, '\n\n').trim();
  return {text: t, reactions: reactions.trim(), media: media.map(x => ({type: x}))};
}
async function viaTavily(target){
  // Ein Aufruf liefert Text, Beitragslinks, Aufrufe und Reaktionen.
  // Der angehaengte Parameter umgeht den Zwischenspeicher des Dienstes.
  const url = 'https://t.me/s/' + encodeURIComponent(target) + '?_=' + Date.now();
  const r = await callTool(TAVILY, {urls: [url], extract_depth: 'advanced', format: 'markdown'});
  if(r.isError) throw new Error('Textabruf: ' + txt(r));
  let data = r.structuredContent;
  if(!data){
    const raw = txt(r);
    const a = raw.indexOf('{'), b = raw.lastIndexOf('}');
    if(a < 0) throw new Error('Textabruf: keine verwertbare Antwort');
    data = JSON.parse(raw.slice(a, b + 1));
  }
  const res = (data.results || [])[0];
  if(!res || !res.raw_content) throw new Error('Textabruf: leeres Ergebnis');
  let posts = parsePreview(res.raw_content, target);
  posts.sort((a, b) => (a.no || 0) - (b.no || 0));
  posts = posts.reverse();                                        // neueste zuerst
  if(!posts.length) throw new Error('Textabruf: keine Beitraege erkannt');
  return {posts, exact: false, total: posts.length};
}

async function viaFetch(target){
  const base = 'https://t.me/s/' + encodeURIComponent(target);
  // Erst mit Cache-Umgehung, sonst schlicht - je nach Umgebung ist nur eine Form erlaubt.
  let r = null, err = '';
  for(const url of [base + '?_=' + Date.now(), base]){
    try{
      r = await callTool('mcp__workspace__web_fetch', {url});
      if(!r.isError) break;
      err = txt(r); r = null;
    }catch(e){ err = e.message; r = null; }
  }
  if(!r) throw new Error('Web-Vorschau: ' + (err || 'Abruf fehlgeschlagen'));
  const md = txt(r);
  if(!/t\.me\//.test(md)) throw new Error('Web-Vorschau: unerwartete Antwort');
  const posts = parsePreview(md, target).reverse();          // neueste zuerst
  return {posts, exact: false, total: posts.length};
}

/* --------------------------------------------------------- Abruflogik --- */
let mode = null, busy = false;

async function pollOne(ch){
  // Private Nutzerkonten haben keine oeffentliche Vorschau - Abruf waere
  // garantiert erfolglos und wuerde nur eine Fehlermeldung erzeugen.
  if(ch.channel && ch.channel.readable === false){
    ch.last_poll = nowIso();
    ch.polls = (ch.polls || 0) + 1;
    ch.error = null;
    ch.skipped = 'Privates Konto ohne oeffentlichen Verlauf - nichts abzurufen.';
    return 0;
  }
  let res, errs = [];
  const order = mode === 'lokal' ? [viaBash, viaTavily, viaFetch]
                                : [viaTavily, viaBash, viaFetch];
  for(const fn of order){
    try{ res = await fn(ch.target); mode = (fn === viaBash) ? 'lokal' : 'web'; errs = []; break; }
    catch(e){ errs.push(e.message); }
  }
  ch.last_poll = nowIso();
  ch.polls = (ch.polls || 0) + 1;
  ch.error = res ? null : errs.join(' · ');
  if(!res) return 0;

  // Zwei Erkennungsmerkmale: Beitrags-ID und Textkennung. Der eingebettete
  // Datenstand nutzt echte IDs, der Live-Abruf teils Ersatzschluessel - ohne
  // Textvergleich stuende derselbe Beitrag sonst doppelt in der Liste.
  const known = new Set();
  (ch.posts || []).forEach(p => {
    known.add(p.id);
    known.add('t:' + hash((p.text || '').slice(0, 140).replace(/\s+/g, ' ').trim()));
  });
  const fresh = res.posts.filter(p =>
    !known.has(p.id) &&
    !known.has('t:' + hash((p.text || '').slice(0, 140).replace(/\s+/g, ' ').trim())));
  fresh.forEach(p => { p.seen_at = nowIso(); p.is_new = true; });
  (ch.posts || []).forEach(p => { p.is_new = false; });
  ch.posts = sortPosts(fresh.concat(ch.posts || [])).slice(0, 300);
  ch.exact = res.exact;
  if(fresh.length) ch.last_new = nowIso();
  return fresh.length;
}

async function pollAll(){
  if(busy) return;
  busy = true;
  setLive('rufe ab ...', 'busy');
  let total = 0;
  for(const ch of ST.channels){
    try{ total += await pollOne(ch); }catch(e){ ch.error = e.message; }
    render();
  }
  ST.updated = nowIso();
  save(); render();
  busy = false;
  setLive(total ? total + ' neue(r) Beitrag/Beiträge' : 'aktuell', total ? 'new' : 'ok');
  return total;
}

/* ------------------------------------------------------------ Anzeige --- */
function setLive(text, kind){
  document.getElementById('liveLabel').textContent = text;
  const dot = document.getElementById('dot');
  dot.className = 'dot' + (kind === 'paused' ? ' paused' : (kind === 'err' ? ' err' : ''));
}
function postHtml(p, exact){
  const stamp = p.date ? when(p.date)
    : (p.time ? p.time + ' Uhr (Datum unbekannt)'
             : (p.no_exact === false ? 'aus der Kanalvorschau'
                                     : (p.no ? 'Beitrag ' + p.no : '')));
  return '<div class="post' + (p.is_new ? ' fresh' : '') + '">' +
    '<div class="when">' + esc(stamp) +
      (p.is_new ? '<span class="new-badge">NEU</span>' : '') +
      (p.views ? ' · ' + num(p.views) + ' Aufrufe' : '') +
      (p.voters ? ' · ' + num(p.voters) + ' Stimmen' : '') +
      (p.author ? ' · ' + esc(p.author) : '') +
      (p.url ? ' · <a href="' + esc(p.url) + '" target="_blank" rel="noopener">' +
        (p.no_exact === false ? 'Kanal öffnen' : 'Beitrag') + '</a>' : '') +
    '</div>' +
    '<div class="txt">' + esc((p.text || '(kein Text)').slice(0, 900)) + '</div>' +
    (p.reactions ? '<div class="reac">' + esc(p.reactions) + '</div>' : '') +
    (p.media && p.media.length ? '<div class="reac">Medien: ' +
      esc(p.media.map(m => m.type).join(', ')) + '</div>' : '') +
    '</div>';
}
function channelHtml(ch){
  const c = ch.channel || {};
  const av = c.avatar_url ? '<img class="avatar" src="' + esc(c.avatar_url) + '" alt="">'
                          : '<div class="avatar"></div>';
  const tags = ['<span class="tag ' + (ch.platform === 'discord' ? 'dc' : 'tg') + '">' +
                esc(ch.platform) + '</span>'];
  if(c.kind) tags.push('<span class="tag">' + esc(c.kind) + '</span>');
  tags.push(c.readable === false ? '<span class="tag no">nicht lesbar</span>'
                                 : '<span class="tag ok">lesbar</span>');
  const posts = sortPosts(ch.posts || []);
  return '<div class="card"><div class="head">' + av + '<div style="flex:1;min-width:0">' +
    '<div class="title">' + esc(c.title || ch.target) + tags.join('') +
      '<button data-drop="' + esc(ch.target) + '" style="margin-left:auto;padding:3px 9px;font-size:12px">entfernen</button>' +
    '</div>' +
    '<div class="meta">@' + esc(ch.target) +
      (c.members ? ' · ' + num(c.members) + ' Abonnenten' : '') +
      ' · ' + posts.length + ' Beiträge gesammelt · ' + (ch.polls || 0) + ' Abrufe' +
      (ch.last_poll ? ' · zuletzt geprüft ' + esc(when(ch.last_poll)) : '') +
      (ch.last_new ? ' · Neues zuletzt ' + esc(when(ch.last_new)) : '') + '</div>' +
    (c.description ? '<div class="desc">' + esc(c.description.slice(0, 260)) + '</div>' : '') +
    (ch.error ? '<div class="errbox">' + esc(ch.error) + '</div>' : '') +
    (posts.length
      ? '<div class="stream">' + posts.map(p => postHtml(p, ch.exact)).join('') + '</div>'
      : '<div class="empty" style="margin-top:10px">' + esc(ch.skipped ||
          'Noch keine Beiträge gesammelt — entweder keine öffentliche Vorschau ' +
          'oder der Kanal hat nichts veröffentlicht.') + '</div>') +
    '</div></div></div>';
}
function render(){
  document.getElementById('stand').textContent =
    'Letzte Aktualisierung: ' + (ST.updated ? when(ST.updated) : 'noch keine') +
    ' · neueste Beiträge oben · Verlauf wird in dieser Ansicht gesammelt';

  document.getElementById('live').innerHTML = ST.channels.length
    ? ST.channels.map(channelHtml).join('')
    : '<div class="empty">Kein Kanal beobachtet — oben einen @namen eintragen.</div>';

  document.getElementById('modeChips').innerHTML =
    (mode ? '<span class="chip mode">Quelle: ' +
      (mode === 'lokal' ? 'lokales Werkzeug (exakte Zeitstempel)'
                        : 'Web-Vorschau (nur Uhrzeit)') + '</span>' : '');

  const s = BAKED.search || {};
  document.getElementById('searchmeta').textContent = s.query
    ? 'Suchbegriff "' + s.query + '" · ' + (s.count || 0) + ' Treffer · Methoden: ' +
      ((s.methods_used || []).join(', ') || '-')
    : '';
  document.getElementById('search').innerHTML = (s.results || []).length
    ? s.results.map(c => '<div class="card"><div class="head">' +
        (c.avatar_url ? '<img class="avatar" src="' + esc(c.avatar_url) + '">' : '<div class="avatar"></div>') +
        '<div style="flex:1;min-width:0"><div class="title">' + esc(c.title || c.username) +
        '<span class="tag ' + (c.platform === 'discord' ? 'dc' : 'tg') + '">' + esc(c.platform) + '</span>' +
        '<span class="tag">' + esc(c.kind) + '</span>' +
        (c.readable ? '<span class="tag ok">lesbar</span>' : '<span class="tag no">nicht lesbar</span>') +
        '<span class="score">' + Number(c.confidence).toFixed(2) + '</span>' +
        (c.readable ? '<button data-watch="' + esc(c.username) + '" style="margin-left:auto;padding:3px 9px;font-size:12px">beobachten</button>' : '') +
        '</div><div class="meta">@' + esc(c.username || '') + ' · ' + num(c.members)
