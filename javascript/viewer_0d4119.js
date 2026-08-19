#!/usr/bin/env node
// viewer.html — portiert nach javascript
// Quelle: html, Projects@Telegram-Monitor:plugin/extension/viewer.html
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Helper to get __dirname in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function createHTMLDocument() {
  // Create the document
  const doc = {
    doctype: '<!DOCTYPE html>',
    html: {
      attributes: { lang: 'de' },
      head: {
        children: [
          { tag: 'meta', attributes: { charset: 'utf-8' } },
          { tag: 'meta', attributes: { name: 'viewport', content: 'width=device-width, initial-scale=1' } },
          { tag: 'title', text: 'TikTok Live Companion — Viewer' },
          { tag: 'style', text: `
  :root{
    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;
    --tt:#fe2c55; --ok:#22c55e; --warn:#f59e0b;
    color-scheme: dark;
  }
  @media (prefers-color-scheme: light){
    :root{ --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);
       font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  .wrap{max-width:1180px;margin:0 auto;padding:16px}
  header{display:flex;gap:12px;align-items:center;flex-wrap:wrap;margin-bottom:12px}
  h1{font-size:17px;margin:0;font-weight:650}
  .badge{display:inline-flex;align-items:center;gap:6px;font-size:11.5px;font-weight:700;
         padding:3px 10px;border-radius:99px;background:#2a2f3a;color:var(--muted)}
  .badge.live{background:var(--tt);color:#fff}
  .badge .dot{width:6px;height:6px;border-radius:50%;background:currentColor}
  .badge.live .dot{animation:pulse 1.6s infinite}
  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}
  input,select,button{font:inherit;border-radius:8px;border:1px solid var(--line);
                      background:var(--card);color:var(--text);padding:9px 12px}
  input{min-width:220px}
  button{cursor:pointer;font-weight:600}
  button.primary{background:var(--tt);border-color:var(--tt);color:#fff}
  .row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:10px}
  .grid{display:grid;grid-template-columns:minmax(0,2fr) minmax(280px,1fr);gap:14px}
  @media (max-width:900px){ .grid{grid-template-columns:1fr} }
  .card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px}
  .player{position:relative;width:100%;aspect-ratio:9/16;max-height:80vh;background:#000;
          border-radius:12px;overflow:hidden;border:1px solid var(--line)}
  .player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
  .ph{position:absolute;inset:0;display:flex;flex-direction:column;gap:10px;
      align-items:center;justify-content:center;color:var(--muted);text-align:center;padding:26px}
  h2{font-size:11.5px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);
     margin:0 0 8px;font-weight:650}
  .meta{color:var(--muted);font-size:13px}
  .strong{color:var(--text);font-weight:600}
  .stream{display:flex;gap:10px;padding:6px 0;border-bottom:1px solid var(--line);font-size:13px}
  .stream:last-child{border-bottom:0}
  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}
  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
  .stream.now{color:var(--tt);font-weight:650}
  .hint{font-size:12.5px;color:var(--muted);line-height:1.45;margin-top:10px}
  a{color:var(--tt)} a:hover{text-decoration:underline}
  code{background:rgba(127,127,127,.15);padding:1px 5px;border-radius:4px;font-size:12.5px;
       font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
` }
        ]
      },
      body: {
        children: [
          {
            tag: 'div',
            attributes: { class: 'wrap' },
            children: [
              {
                tag: 'header',
                children: [
                  { tag: 'h1', text: 'TikTok Live Companion — Viewer' },
                  {
                    tag: 'span',
                    attributes: { class: 'badge', id: 'badge' },
                    children: [
                      { tag: 'span', attributes: { class: 'dot' } },
                      { tag: 'span', attributes: { id: 'badgeText' }, text: 'bereit' }
                    ]
                  },
                  { tag: 'span', attributes: { class: 'meta', id: 'checked' } }
                ]
              },
              {
                tag: 'div',
                attributes: { class: 'row' },
                children: [
                  { tag: 'input', attributes: { id: 'user', placeholder: '@name eingeben — beliebiges öffentliches Konto', autofocus: '' } },
                  { tag: 'button', attributes: { class: 'primary', id: 'go' }, text: 'Anzeigen' },
                  { tag: 'button', attributes: { id: 'clear' }, text: 'Leeren' },
                  {
                    tag: 'select',
                    attributes: { id: 'every' },
                    children: [
                      { tag: 'option', attributes: { value: '0', selected: '' }, text: 'Status: nur manuell' },
                      { tag: 'option', attributes: { value: '60' }, text: 'Status alle 60 s' },
                      { tag: 'option', attributes: { value: '120' }, text: 'alle 2 min' },
                      { tag: 'option', attributes: { value: '300' }, text: 'alle 5 min' }
                    ]
                  },
                  { tag: 'input', attributes: { id: 'api', placeholder: 'Monitor, z. B. http://127.0.0.1:8765 (optional)', style: 'min-width:270px' } }
                ]
              },
              {
                tag: 'div',
                attributes: { class: 'grid' },
                children: [
                  {
                    tag: 'div',
                    children: [
                      {
                        tag: 'div',
                        attributes: { class: 'player', id: 'player' },
                        children: [
                          {
                            tag: 'div',
                            attributes: { class: 'ph', id: 'ph' },
                            children: [
                              { tag: 'div', attributes: { style: 'font-size:34px' }, text: '📺' },
                              { tag: 'div', attributes: { id: 'phText' }, text: 'Namen eintragen und „Anzeigen“ drücken —<br>der Player startet sofort.' }
                            ]
                          }
                        ]
                      },
                      {
                        tag: 'p',
                        attributes: { class: 'hint' },
                        children: [
                          { text: 'Eingebettet wird der offizielle TikTok-Live-Player ' },
                          { tag: 'code', attributes: { id: 'curUrl' }, text: 'tiktok.com/embed/live/@name' },
                          { text: ' — ' },
                          { tag: 'b', text: 'keine Anmeldung, keine Geschenk- oder Kauf-Oberfläche' },
                          { text: '. Ist das Konto offline, zeigt der Rahmen eine Fehlerseite von TikTok; das ist das Offline-Zeichen.' }
                        ]
                      }
                    ]
                  },
                  {
                    tag: 'div',
                    children: [
                      {
                        tag: 'div',
                        attributes: { class: 'card' },
                        children: [
                          { tag: 'h2', text: 'Aufruf' },
                          { tag: 'div', attributes: { class: 'meta', id: 'links' }, text: 'noch kein Konto gewählt' }
                        ]
                      },
                      {
                        tag: 'div',
                        attributes: { class: 'card', style: 'margin-top:12px' },
                        children: [
                          { tag: 'h2', text: 'Status' },
                          {
                            tag: 'div',
                            attributes: { class: 'meta', id: 'status' },
                            text: 'Läuft gerade / seit wann / letzte Sendungen kommen aus dem lokalen Monitor. Ohne ihn zeigt diese Seite nur den Player — eine lokale Datei darf im Browser keine fremden Server abfragen.'
                          },
                          {
                            tag: 'div',
                            attributes: { class: 'hint' },
                            children: [
                              { text: 'Monitor starten: ' },
                              { tag: 'code', text: 'python server.py --poll-interval 120' },
                              { text: ' im Projektordner, dann oben ' },
                              { tag: 'code', text: 'http://127.0.0.1:8765' },
                              { text: ' eintragen und „Anzeigen“ drücken.' }
                            ]
                          }
                        ]
                      },
                      {
                        tag: 'div',
                        attributes: { class: 'card', style: 'margin-top:12px' },
                        children: [
                          { tag: 'h2', text: 'Letzte Sendungen' },
                          { tag: 'div', attributes: { class: 'meta', id: 'streams' }, text: '—' }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          },
          {
            tag: 'script',
            text: `
const $ = s => document.querySelector(s);
const esc = s => String(s ?? '').replace(/[&<>"]/g, c =>
  ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const num = n => n == null ? '?' : Number(n).toLocaleString('de-DE');
const clean = s => String(s || '').trim()
  .replace(/^https?:\\/\\/(www\\.)?tiktok\\.com\\/\\@?/i, '')
  .replace(/\\/live.*$/i, '').replace(/^\\@/, '').trim();

let timer = null;

function embedUrl(user){
  return 'https://www.tiktok.com/embed/live/@' + encodeURIComponent(user);
}

/* Player sofort einbetten — ohne jede Statusabfrage. */
function mount(user){
  const holder = $('#player');
  holder.querySelectorAll('iframe').forEach(f => f.remove());
  const f = document.createElement('iframe');
  f.src = embedUrl(user);
  f.allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen';
  f.referrerPolicy = 'origin';
  f.title = 'TikTok Live von @' + user;
  holder.appendChild(f);
  $('#ph').style.display = 'none';
  $('#curUrl').textContent = 'tiktok.com/embed/live/@' + user;
  $('#links').innerHTML =
    '<div class="strong">@' + esc(user) + '</div>' +
    '<div style="margin-top:6px">' +
    '<a href="https://www.tiktok.com/@' + esc(user) + '/live" target="_blank" rel="noopener">Live-Seite</a> · ' +
    '<a href="https://www.tiktok.com/@' + esc(user) + '" target="_blank" rel="noopener">Profil</a> · ' +
    '<a href="' + esc(embedUrl(user)) + '" target="_blank" rel="noopener">Player einzeln</a></div>';
}

function setBadge(live){
  $('#badge').className = 'badge' + (live === true ? ' live' : '');
  $('#badgeText').textContent = live === true ? 'LIVE'
    : (live === false ? 'offline' : 'Status unbekannt');
}

/* Status nur, wenn ein Monitor eingetragen ist. */
async function fetchStatus(user){
  const base = $('#api').value.trim().replace(/\\/+$/, '');
  if(!base){ setBadge(null); return; }
  try{
    const r = await fetch(base + '/api/tiktok/status?users=' + encodeURIComponent(user),
                          { cache: 'no-store' });
    if(!r.ok) throw new Error('HTTP ' + r.status);
    const d = await r.json();
    const st = (d.accounts || [])[0];
    if(!st) throw new Error('keine Daten');
    render(st);
  }catch(e){
    setBadge(null);
    $('#status').innerHTML = '<span style="color:var(--warn)">Monitor nicht erreichbar (' +
      esc(e.message) + ').</span><br>Der Player oben läuft davon unabhängig weiter.';
  }
}

function render(st){
  setBadge(st.live);
  $('#checked').textContent = st.checked_at
    ? 'geprüft ' + new Date(st.checked_at).toLocaleTimeString('de-DE') : '';
  $('#status').innerHTML =
    (st.title ? '<div class="strong">' + esc(st.title) + '</div>' : '') +
    (st.started_at ? '<div>Beginn ' + esc(st.started_at.replace('T',' ')) +
      (st.since ? ' · seit ca. ' + esc(st.since) : '') + '</div>' : '') +
    (st.last_seen ? '<div>zuletzt gesehen ' + esc(st.last_seen) + '</div>' : '') +
    (st.streams_total ? '<div>' + num(st.streams_total) + ' Sendungen · ' +
      esc(st.airtime || '') + ' · ' + num(st.active_days) + ' aktive Tage</div>' : '');
  $('#streams').innerHTML = (st.streams || []).length
    ? st.streams.slice(0, 12).map(s =>
        '<div class="stream' + (s.is_live ? ' now' : '') + '">' +
        '<span class="when">' + esc(String(s.day).slice(5)) + ' ' + esc(s.time || '') + '</span>' +
        '<span class="t">' + esc(s.title || '(ohne Titel)') + '</span>' +
        '<span class="when">' + esc(s.duration || '') + '</span></div>').join('')
    : 'keine Daten';
}

function start(){
  const user = clean($('#user').value);
  if(!user){ $('#user').focus(); return; }
  $('#user').value = user;
  try{
    localStorage.setItem('ttv.user', user);
    localStorage.setItem('ttv.api', $('#api').value.trim());
  }catch(e){}
  mount(user);
  fetchStatus(user);
  if(timer) clearInterval(timer);
  const every = parseInt($('#every').value, 10);
  if(every > 0) timer = setInterval(() => fetchStatus(user), every * 1000);
}

$('#go').onclick = start;
$('#user').addEventListener('keydown', e => { if(e.key === 'Enter') start(); });
$('#every').addEventListener('change', start);
$('#clear').onclick = () => {
  if(timer) clearInterval(timer);
  document.querySelectorAll('#player iframe').forEach(f => f.remove());
  $('#ph').style.display = '';
  $('#user').value = '';
  $('#links').textContent = 'noch kein Konto gewählt';
  $('#streams').textContent = '—';
  $('#curUrl').textContent = 'tiktok.com/embed/live/@name';
  setBadge(null);
  try{ localStorage.removeItem('ttv.user'); }catch(e){}
  $('#user').focus();
};

/* Nichts fest eingebaut — nur das zuletzt selbst eingegebene Konto. */
try{
  const savedApi = localStorage.getItem('ttv.api');
  if(savedApi) $('#api').value = savedApi;
  const savedUser = localStorage.getItem('ttv.user');
  if(savedUser){ $('#user').value = savedUser; start(); }
}catch(e){}
`
          }
        ]
      }
    }
  };

  return doc;
}

function renderElement(element) {
  if (typeof element === 'string') {
    return element;
  }

  if (element.text && !element.children) {
    return element.text;
  }

  let html = '';
  
  if (element.tag) {
    html += `<${element.tag}`;
    
    if (element.attributes) {
      for (const [key, value] of Object.entries(element.attributes)) {
        if (value === '') {
          html += ` ${key}`;
        } else {
          html += ` ${key}="${value}"`;
        }
      }
    }
    
    if (element.children) {
      html += '>';
      for (const child of element.children) {
        html += renderElement(child);
      }
      html += `</${element.tag}>`;
    } else if (element.text) {
      html += `>${element.text}</${element.tag}>`;
    } else {
      html += '></' + element.tag + '>';
    }
  } else if (element.text) {
    html += element.text;
  }

  return html;
}

function generateHTML(doc) {
  let html = doc.doctype + '\n';
  html += '<html lang="' + doc.html.attributes.lang + '">\n';
  html += '<head>\n';
  for (const child of doc.html.head.children) {
    if (child.tag === 'style') {
      html += '  <style>\n' + child.text + '\n  </style>\n';
    } else if (child.tag) {
      html += '  ';
      if (child.text) {
        html += `<${child.tag}`;
        if (child.attributes) {
          for (const [key, value] of Object.entries(child.attributes)) {
            if (value === '') {
              html += ` ${key}`;
            } else {
              html += ` ${key}="${value}"`;
            }
          }
        }
        html += `>${child.text}</${child.tag}>\n`;
      } else {
        html += `<${child.tag}`;
        if (child.attributes) {
          for (const [key, value] of Object.entries(child.attributes)) {
            if (value === '') {
              html += ` ${key}`;
            } else {
              html += ` ${key}="${value}"`;
            }
          }
        }
        html += '>\n';
      }
    }
  }
  html += '</head>\n';
  html += '<body>\n';
  for (const child of doc.html.body.children) {
    if (child.tag === 'script') {
      html += '  <script>\n' + child.text + '\n  </script>\n';
    } else {
      html += '  ' + renderElement(child) + '\n';
    }
  }
  html += '</body>\n';
  html += '</html>\n';
  
  return html;
}

// Main execution
if (process.argv.length < 3) {
  console.error('Usage: node ' + path.basename(__filename) + ' <output-file>');
  process.exit(1);
}

const outputFile = process.argv[2];
const doc = createHTMLDocument();
const htmlContent = generateHTML(doc);

try {
  fs.writeFileSync(outputFile, htmlContent, 'utf8');
  console.log('HTML file generated successfully: ' + outputFile);
} catch (error) {
  console.error('Error writing file:', error.message);
  process.exit(1);
}
