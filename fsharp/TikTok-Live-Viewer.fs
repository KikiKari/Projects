// abstraction-provenance: {"artifact_sha256": "20ab6f47f7ede7eaaeb513c8023cb4fc25120343814acf30e1541039c5a33cac", "source_sha256": "83117e76f05b08bc4554d3f4feb0f928c62429bbccc6f556ec336643a33b2a1a", "target_language": "fsharp"}
// TikTok-Live-Viewer.html — portiert nach fsharp
// Quelle: html, Projects@Telegram-Monitor:TikTok-Live-Viewer.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

type HtmlElement = {
    tag: string
    attributes: Map<string, string>
    children: HtmlNode list
}

and HtmlNode =
    | Element of HtmlElement
    | Text of string
    | RawHtml of string

type HtmlDocument = {
    doctype: string
    root: HtmlElement
}

module Html =
    let elem tag attrs children = 
        Element { tag = tag; attributes = Map attrs; children = children }
    
    let text s = Text s
    let raw s = RawHtml s
    
    let attr (name: string) (value: string) = (name, value)
    
    let private escape (s: string) =
        s.Replace("&", "&amp;")
         .Replace("<", "&lt;")
         .Replace(">", "&gt;")
         .Replace("\"", "&quot;")
    
    let rec private renderNode (node: HtmlNode) (sb: StringBuilder) =
        match node with
        | Text s -> sb.Append(escape s) |> ignore
        | RawHtml s -> sb.Append(s) |> ignore
        | Element e ->
            sb.Append("<").Append(e.tag) |> ignore
            e.attributes
            |> Map.iter (fun k v -> 
                sb.Append(" ").Append(k).Append("=\"").Append(escape v).Append("\"") |> ignore)
            
            if e.children.IsEmpty then
                sb.Append(">") |> ignore
            else
                sb.Append(">") |> ignore
                e.children |> List.iter (renderNode >> ignore)
                sb.Append("</").Append(e.tag).Append(">") |> ignore
    
    let renderDocument (doc: HtmlDocument) =
        let sb = StringBuilder()
        sb.Append("<!DOCTYPE ").Append(doc.doctype).Append(">\n") |> ignore
        renderNode (Element doc.root) sb
        sb.ToString()

let createDocument() =
    let css = """
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
"""
    
    let js = """
const $ = s => document.querySelector(s);
const esc = s => String(s ?? '').replace(/[&<>"]/g, c =>
  ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const num = n => n == null ? '?' : Number(n).toLocaleString('de-DE');
const clean = s => String(s || '').trim()
  .replace(/^https?:\/\/(www\.)?tiktok\.com\/@?/i, '')
  .replace(/\/live.*$/i, '').replace(/^@/, '').trim();

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
  const base = $('#api').value.trim().replace(/\/+$/, '');
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
"""

    {
        doctype = "html"
        root = {
            tag = "html"
            attributes = Map [("lang", "de")]
            children = [
                Element {
                    tag = "head"
                    attributes = Map []
                    children = [
                        Element { tag = "meta"; attributes = Map [("charset", "utf-8")]; children = [] }
                        Element { tag = "meta"; attributes = Map [("name", "viewport"); ("content", "width=device-width, initial-scale=1")]; children = [] }
                        Element { tag = "title"; attributes = Map []; children = [Text "TikTok Live Companion — Viewer"] }
                        Element { tag = "style"; attributes = Map []; children = [RawHtml css] }
                    ]
                }
                Element {
                    tag = "body"
                    attributes = Map []
                    children = [
                        Element {
                            tag = "div"
                            attributes = Map [("class", "wrap")]
                            children = [
                                Element {
                                    tag = "header"
                                    attributes = Map []
                                    children = [
                                        Element { tag = "h1"; attributes = Map []; children = [Text "TikTok Live Companion — Viewer"] }
                                        Element {
                                            tag = "span"
                                            attributes = Map [("class", "badge"); ("id", "badge")]
                                            children = [
                                                Element { tag = "span"; attributes = Map [("class", "dot")]; children = [] }
                                                Element { tag = "span"; attributes = Map [("id", "badgeText")]; children = [Text "bereit"] }
                                            ]
                                        }
                                        Element { tag = "span"; attributes = Map [("class", "meta"); ("id", "checked")]; children = [] }
                                    ]
                                }
                                Element {
                                    tag = "div"
                                    attributes = Map [("class", "row")]
                                    children = [
                                        Element { tag = "input"; attributes = Map [("id", "user"); ("placeholder", "@name eingeben — beliebiges öffentliches Konto"); ("autofocus", "")]; children = [] }
                                        Element { tag = "button"; attributes = Map [("class", "primary"); ("id", "go")]; children = [Text "Anzeigen"] }
                                        Element { tag = "button"; attributes = Map [("id", "clear")]; children = [Text "Leeren"] }
                                        Element {
                                            tag = "select"
                                            attributes = Map [("id", "every")]
                                            children = [
                                                Element { tag = "option"; attributes = Map [("value", "0"); ("selected", "")]; children = [Text "Status: nur manuell"] }
                                                Element { tag = "option"; attributes = Map [("value", "60")]; children = [Text "Status alle 60 s"] }
                                                Element { tag = "option"; attributes = Map [("value", "120")]; children = [Text "alle 2 min"] }
                                                Element { tag = "option"; attributes = Map [("value", "300")]; children = [Text "alle 5 min"] }
                                            ]
                                        }
                                        Element { tag = "input"; attributes = Map [("id", "api"); ("value", "http://127.0.0.1:8765"); ("placeholder", "Monitor-Adresse"); ("style", "min-width:250px")]; children = [] }
                                    ]
                                }
                                Element {
                                    tag = "div"
                                    attributes = Map [("class", "grid")]
                                    children = [
                                        Element {
                                            tag = "div"
                                            attributes = Map []
                                            children = [
                                                Element {
                                                    tag = "div"
                                                    attributes = Map [("class", "player"); ("id", "player")]
                                                    children = [
                                                        Element {
                                                            tag = "div"
                                                            attributes = Map [("class", "ph"); ("id", "ph")]
                                                            children = [
                                                                Element { tag = "div"; attributes = Map [("style", "font-size:34px")]; children = [Text "📺"] }
                                                                Element { tag = "div"; attributes = Map [("id", "phText")]; children = [Text "Namen eintragen und „Anzeigen“ drücken —\nder Player startet sofort."] }
                                                            ]
                                                        }
                                                    ]
                                                }
                                                Element {
                                                    tag = "p"
                                                    attributes = Map [("class", "hint")]
                                                    children = [
                                                        Text "Eingebettet wird der offizielle TikTok-Live-Player "
                                                        Element { tag = "code"; attributes = Map [("id", "curUrl")]; children = [Text "tiktok.com/embed/live/@name"] }
                                                        Text " — "
                                                        Element { tag = "b"; attributes = Map []; children = [Text "keine Anmeldung, keine Geschenk- oder Kauf-Oberfläche"] }
                                                        Text ". Ist das Konto offline, zeigt der Rahmen eine Fehlerseite von TikTok; das ist das Offline-Zeichen."
                                                    ]
                                                }
                                            ]
                                        }
                                        Element {
                                            tag = "div"
                                            attributes = Map []
                                            children = [
                                                Element {
                                                    tag = "div"
                                                    attributes = Map [("class", "card")]
                                                    children = [
                                                        Element { tag = "h2"; attributes = Map []; children = [Text "Aufruf"] }
                                                        Element { tag = "div"; attributes = Map [("class", "meta"); ("id", "links")]; children = [Text "noch kein Konto gewählt"] }
                                                    ]
                                                }
                                                Element {
                                                    tag = "div"
                                                    attributes = Map [("class", "card"); ("style", "margin-top:12px")]
                                                    children = [
                                                        Element { tag = "h2"; attributes = Map []; children = [Text "Status"] }
                                                        Element { tag = "div"; attributes = Map [("class", "meta"); ("id", "status")]; children = [Text "Läuft gerade / seit wann / letzte Sendungen kommen aus dem lokalen Monitor. Ohne ihn zeigt diese Seite nur den Player — eine lokale Datei darf im Browser keine fremden Server abfragen."] }
                                                        Element {
                                                            tag = "div"
                                                            attributes = Map [("class", "hint")]
                                                            children = [
                                                                Text "Monitor starten: "
                                                                Element { tag = "code"; attributes = Map []; children = [Text "python server.py --poll-interval 120"] }
                                                                Text " im Projektordner, dann oben "
                                                                Element { tag = "code"; attributes = Map []; children = [Text "http://127.0.0.1:8765"] }
                                                                Text " eintragen und „Anzeigen“ drücken."
                                                            ]
                                                        }
                                                    ]
                                                }
                                                Element {
                                                    tag = "div"
                                                    attributes = Map [("class", "card"); ("style", "margin-top:12px")]
                                                    children = [
                                                        Element { tag = "h2"; attributes = Map []; children = [Text "Letzte Sendungen"] }
                                                        Element { tag = "div"; attributes = Map [("class", "meta"); ("id", "streams")]; children = [Text "—"] }
                                                    ]
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                        Element { tag = "script"; attributes = Map []; children = [RawHtml js] }
                    ]
                }
            ]
        }
    }

let generateHtml outputPath =
    let doc = createDocument()
    let htmlContent = Html.renderDocument doc
    File.WriteAllText(outputPath, htmlContent, Text.Encoding.UTF8)

[<EntryPoint>]
let main argv =
    let outputPath = 
        if argv.Length > 0 then argv.[0]
        else "TikTok-Live-Viewer.html"
    
    generateHtml outputPath
    printfn "HTML file generated at: %s" outputPath
    0
