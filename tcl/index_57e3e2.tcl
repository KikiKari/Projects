#!/usr/bin/env tclsh
# index.html — portiert nach tcl
# Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 script to generate the HTML document
# Usage: tclsh generate_html.tcl output.html

proc generate_html {filename} {
    set fp [open $filename w]
    
    puts $fp {<!DOCTYPE html>}
    puts $fp {<script type="application/json" id="cowork-artifact-meta">}
    puts $fp {{"name": "Tagesstatus Live Public","schemaVersion": 1,"description": "Öffentliche, umgebungs-unabhängige Status-Seite ohne eingebettete Keys. Fragt Tokens beim Öffnen ab (nur localStorage), zeigt ohne Key keine Daten. Holt Daten per direktem Browser-Abruf (GitHub, OpenRouter, OpenAI, Anthropic, Tailscale, ClawHub) — funktioniert voll nur gehostet/lokal außerhalb der Sandbox; CORS-geschützte Quellen brauchen ggf. einen Proxy.","mcpTools": [],"mcpServerNames": []}}
    puts $fp {</script>}
    puts $fp {<html lang="de">}
    puts $fp {<head>}
    puts $fp {<meta charset="utf-8">}
    puts $fp {<meta name="viewport" content="width=device-width, initial-scale=1">}
    puts $fp {<title>Tagesstatus Live — Public</title>}
    puts $fp {<style>}
    puts $fp {:root { color-scheme: light; }}
    puts $fp {* { box-sizing: border-box; }}
    puts $fp {body { margin:0; font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif; background:#f7f7f5; color:#1d1c1a; }}
    puts $fp {.wrap { max-width:880px; margin:0 auto; padding:20px 16px 60px; }}
    puts $fp {h1 { font-size:22px; margin:0 0 2px; }}
    puts $fp {.sub { color:#6b6a66; font-size:13px; margin-bottom:16px; }}
    puts $fp {.bar { display:flex; gap:10px; align-items:center; margin-bottom:16px; flex-wrap:wrap; }}
    puts $fp {button { font-size:13px; font-weight:600; padding:7px 13px; border:1px solid #d9d8d3; border-radius:8px; background:#fff; cursor:pointer; }}
    puts $fp {button:hover { background:#f2f1ec; }}
    puts $fp {button.primary { background:#1d1c1a; color:#fff; border-color:#1d1c1a; }}
    puts $fp {.note { background:#fffdf4; border:1px solid #f0e9c8; border-radius:10px; padding:12px 14px; font-size:13px; color:#4a4734; margin-bottom:16px; line-height:1.5; }}
    puts $fp {.section { background:#fff; border:1px solid #e8e7e3; border-radius:12px; margin-bottom:14px; overflow:hidden; }}
    puts $fp {.section > h2 { font-size:15px; margin:0; padding:13px 16px; border-bottom:1px solid #efeee9; display:flex; align-items:center; gap:9px; }}
    puts $fp {.section > h2 .badge { margin-left:auto; font-size:12px; font-weight:600; background:#efeee9; color:#5a5852; padding:2px 9px; border-radius:20px; }}
    puts $fp {.body { padding:8px 16px 14px; font-size:14px; }}
    puts $fp {.muted { color:#8a8884; }}
    puts $fp {.err { color:#c0392b; }}
    puts $fp {.kv { display:flex; justify-content:space-between; padding:4px 0; border-bottom:1px solid #f4f3ee; }}
    puts $fp {.kv:last-child { border:none; }}
    puts $fp {.kv .k { color:#6b6a66; } .kv .v { font-weight:600; }}
    puts $fp {a { color:#2b5cc4; text-decoration:none; } a:hover { text-decoration:underline; }}
    puts $fp {/* settings modal */}
    puts $fp {.modal { position:fixed; inset:0; background:rgba(0,0,0,.35); display:none; align-items:flex-start; justify-content:center; padding:40px 16px; overflow:auto; }}
    puts $fp {.modal.open { display:flex; }}
    puts $fp {.card { background:#fff; border-radius:14px; max-width:560px; width:100%; padding:20px; }}
    puts $fp {.card h3 { margin:0 0 4px; font-size:17px; }}
    puts $fp {.card p.hint { margin:0 0 16px; font-size:12px; color:#8a8884; }}
    puts $fp {.field { margin-bottom:12px; }}
    puts $fp {.field label { display:block; font-size:12px; font-weight:600; color:#5a5852; margin-bottom:3px; }}
    puts $fp {.field input { width:100%; font-size:13px; padding:7px 9px; border:1px solid #d9d8d3; border-radius:7px; font-family:ui-monospace,Menlo,monospace; }}
    puts $fp {.field .desc { font-size:11px; color:#a8a6a1; margin-top:2px; }}
    puts $fp {.actions { display:flex; gap:10px; justify-content:flex-end; margin-top:8px; }}
    puts $fp {.warn { background:#fdf3f3; border:1px solid #f3d9d9; color:#9a3b3b; border-radius:8px; padding:10px 12px; font-size:12px; margin-bottom:14px; }}
    puts $fp {</style>}
    puts $fp {</head>}
    puts $fp {<body>}
    puts $fp {<div class="wrap">}
    puts $fp {  <h1>Tagesstatus Live — Public</h1>}
    puts $fp {  <div class="sub" id="sub">Eigenständige Version · keine Daten ohne hinterlegte Keys</div>}
    puts $fp {}
    puts $fp {  <div class="bar">}
    puts $fp {    <button class="primary" id="cfgBtn">🔑 Keys eingeben / verwalten</button>}
    puts $fp {    <button id="reloadBtn">↻ Aktualisieren</button>}
    puts $fp {    <button id="clearBtn">Keys löschen</button>}
    puts $fp {  </div>}
    puts $fp {}
    puts $fp {  <div class="note">}
    puts $fp {    Diese Seite ist <b>nicht</b> mit einer Umgebung verbunden und enthält <b>keine</b> eingebetteten Keys.}
    puts $fp {    Beim ersten Öffnen fragt sie deine Tokens ab; sie werden nur lokal im Browser (localStorage) gespeichert.}
    puts $fp {    Ohne hinterlegten Key zeigt der jeweilige Abschnitt „keine Daten". Daten werden direkt per Browser-Abruf}
    puts $fp {    bei den Anbietern geholt — das funktioniert nur außerhalb eingeschränkter Sandboxes (also als gehostete/lokale Datei).}
    puts $fp {  </div>}
    puts $fp {  <div class="warn">}
    puts $fp {    Sicherheit: Keys liegen im Klartext im Browser dieses Geräts. Manche Anbieter (OpenAI, Anthropic, Tailscale)}
    puts $fp {    blockieren Browser-Abrufe per CORS bzw. raten von Client-seitigen Keys ab — dort kann statt Daten ein}
    puts $fp {    CORS-/401-Fehler erscheinen. Für solche Quellen ist ein kleiner Server-Proxy nötig.}
    puts $fp {  </div>}
    puts $fp {}
    puts $fp {  <div id="sections"></div>}
    puts $fp {</div>}
    puts $fp {}
    puts $fp {<div class="modal" id="modal">}
    puts $fp {  <div class="card">}
    puts $fp {    <h3>Zugangsdaten</h3>}
    puts $fp {    <p class="hint">Leer lassen = Quelle wird übersprungen. Speicherung nur lokal (localStorage).</p>}
    puts $fp {    <div class="field"><label>GitHub Repo (owner/repo)</label><input id="f_ghrepo" placeholder="KikiKari/OpenClaw"><div class="desc">Öffentliche Repos gehen ohne Token.</div></div>}
    puts $fp {    <div class="field"><label>GitHub Token (optional, für privat/Codespaces)</label><input id="f_ghtoken" placeholder="github_pat_… oder ghp_…"></div>}
    puts $fp {    <div class="field"><label>OpenRouter API Key</label><input id="f_or" placeholder="sk-or-v1-…"><div class="desc">Verbrauch & Restguthaben.</div></div>}
    puts $fp {    <div class="field"><label>OpenAI Admin Key</label><input id="f_oai" placeholder="sk-admin-…"><div class="desc">Org-Kosten (CORS evtl. blockiert).</div></div>}
    puts $fp {    <div class="field"><label>Anthropic Admin Key</label><input id="f_anth" placeholder="sk-ant-admin…"><div class="desc">Claude Kosten/Nutzung (CORS evtl. blockiert).</div></div>}
    puts $fp {    <div class="field"><label>Tailscale API Token + Tailnet</label><input id="f_ts" placeholder="tskey-api-…"><input id="f_tsnet" placeholder="Tailnet, z.B. example.org oder -" style="margin-top:6px"><div class="desc">Geräte/Status (CORS evtl. blockiert).</div></div>}
    puts $fp {    <div class="field"><label>ClawHub Skill-Slugs (kommagetrennt)</label><input id="f_clawhub" placeholder="cluster-gateway, mcp-tool-utils, json-utils"><div class="desc">Öffentliche ClawHub-API je Skill (kein Token nötig, CORS erlaubt) — Version, Downloads, Scan-Status.</div></div>}
    puts $fp {    <div class="actions"><button id="cancelBtn">Abbrechen</button><button class="primary" id="saveBtn">Speichern & laden</button></div>}
    puts $fp {  </div>}
    puts $fp {</div>}
    puts $fp {}
    puts $fp {<script>}
    puts $fp {const LS = "tsl_public_keys";}
    puts $fp {const esc = s => (s==null?"":String(s)).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));}
    puts $fp {function getKeys(){ try { return JSON.parse(localStorage.getItem(LS)||"{}"); } catch(e){ return {}; } }}
    puts $fp {function setKeys(o){ localStorage.setItem(LS, JSON.stringify(o)); }}
    puts $fp {}
    puts $fp {// ---- Modal ----}
    puts $fp {const modal = document.getElementById("modal");}
    puts $fp {function openCfg(){}
    puts $fp {  const k = getKeys();}
    puts $fp {  f_ghrepo.value=k.ghrepo||""; f_ghtoken.value=k.ghtoken||""; f_or.value=k.or||"";}
    puts $fp {  f_oai.value=k.oai||""; f_anth.value=k.anth||""; f_ts.value=k.ts||""; f_tsnet.value=k.tsnet||""; f_clawhub.value=k.clawhub||"";}
    puts $fp {  modal.classList.add("open");}
    puts $fp {}}
    puts $fp {function closeCfg(){ modal.classList.remove("open"); }}
    puts $fp {cfgBtn.onclick=openCfg; cancelBtn.onclick=closeCfg;}
    puts $fp {saveBtn.onclick=()=>{ setKeys({ ghrepo:f_ghrepo.value.trim(), ghtoken:f_ghtoken.value.trim(), or:f_or.value.trim(), oai:f_oai.value.trim(), anth:f_anth.value.trim(), ts:f_ts.value.trim(), tsnet:f_tsnet.value.trim(), clawhub:f_clawhub.value.trim() }); closeCfg(); loadAll(); };}
    puts $fp {clearBtn.onclick=()=>{ if(confirm("Alle hinterlegten Keys löschen?")){ localStorage.removeItem(LS); loadAll(); } };}
    puts $fp {reloadBtn.onclick=()=>loadAll();}
    puts $fp {}
    puts $fp {// ---- Sections scaffold ----}
    puts $fp {const SECTIONS = [}
    puts $fp {  {id:"github", title:"GitHub — PRs & Branches"},}
    puts $fp {  {id:"openrouter", title:"OpenRouter — Verbrauch & Guthaben"},}
    puts $fp {  {id:"openai", title:"OpenAI — Kosten (30 Tage")},}
    puts $fp {  {id:"anthropic", title:"Claude / Anthropic — Kosten (30 Tage")},}
    puts $fp {  {id:"tailscale", title:"Tailscale — Geräte"},}
    puts $fp {  {id:"clawhub", title:"ClawHub — meine Skills"},}
    puts $fp {  {id:"perplexity", title:"Perplexity — Hinweis"}}
    puts $fp {];}
    puts $fp {function scaffold(){}
    puts $fp {  document.getElementById("sections").innerHTML = SECTIONS.map(s =>}
    puts $fp {    '<div class="section"><h2>'+esc(s.title)+'<span class="badge" id="b-'+s.id+'">–</span></h2>'+}
    puts $fp {    '<div class="body" id="c-'+s.id+'"><span class="muted">…</span></div></div>').join("");}}
    puts $fp {function setB(id,v){ const e=document.getElementById("b-"+id); if(e) e.textContent=v; }}
    puts $fp {function render(id,html){ const e=document.getElementById("c-"+id); if(e) e.innerHTML=html; }}
    puts $fp {const noKey = id => { setB(id,"–"); render(id,'<span class="muted">Kein Token hinterlegt — keine Daten.</span>'); };}
    puts $fp {}
    puts $fp {async function fetchJson(url, headers){}
    puts $fp {  const r = await fetch(url, { headers: headers||{} });}
    puts $fp {  const txt = await r.text();}
    puts $fp {  let data=null; try { data = JSON.parse(txt); } catch(e){}}
    puts $fp {  if(!r.ok) throw new Error("HTTP "+r.status+(data&&data.error?(" · "+(data.error.message||data.error)) : ""));}
    puts $fp {  return data;}
    puts $fp {}}}
    puts $fp {}
    puts $fp {async function loadGitHub(){}
    puts $fp {  const k=getKeys(); const repo=k.ghrepo||"";}
    puts $fp {  if(!repo){ noKey("github"); return; }}
    puts $fp {  try {}}}
    puts $fp {    const h = k.ghtoken ? {Authorization:"Bearer "+k.ghtoken, Accept:"application/vnd.github+json"} : {Accept:"application/vnd.github+json"};}
    puts $fp {    const [prs, br] = await Promise.all([}
    puts $fp {      fetchJson("https://api.github.com/repos/"+repo+"/pulls?state=open&per_page=20", h),}
    puts $fp {      fetchJson("https://api.github.com/repos/"+repo+"/branches?per_page=100", h)}
    puts $fp {    ]);}
    puts $fp {    setB("github", (prs||[]).length);}
    puts $fp {    let html = (prs&&prs.length) ? prs.map(p=>'<div class="kv"><span class="k"><a href="'+esc(p.html_url)+'" target="_blank">#'+p.number+' '+esc(p.title)+'</a></span><span class="v">'+esc((p.user&&p.user.login)||"")+'</span></div>').join("") : '<span class="muted">Keine offenen PRs.</span>';}
    puts $fp {    if(br&&br.length) html+='<div class="kv"><span class="k">Branches</span><span class="v">'+br.length+'</span></div>';}
    puts $fp {    render("github", html);}
    puts $fp {  } catch(e){ setB("github","!"); render("github",'<span class="err">'+esc(e.message)+'</span>'); }}
    puts $fp {}}}
    puts $fp {async function loadOpenRouter(){}
    puts $fp {  const k=getKeys(); if(!k.or){ noKey("openrouter"); return; }}
    puts $fp {  try {}}}
    puts $fp {    const d = await fetchJson("https://openrouter.ai/api/v1/key", {Authorization:"Bearer "+k.or});}
    puts $fp {    const x = (d&&d.data)||{};}
    puts $fp {    setB("openrouter","ok");}
    puts $fp {    render("openrouter",}
    puts $fp {      '<div class="kv"><span class="k">Verbraucht (gesamt)</span><span class="v">'+esc(x.usage)+'</span></div>'+}
    puts $fp {      '<div class="kv"><span class="k">Heute / Woche / Monat</span><span class="v">'+esc(x.usage_daily)+' / '+esc(x.usage_weekly)+' / '+esc(x.usage_monthly)+'</span></div>'+}
    puts $fp {      '<div class="kv"><span class="k">Limit / Rest</span><span class="v">'+esc(x.limit==null?"∞":x.limit)+' / '+esc(x.limit_remaining==null?"∞":x.limit_remaining)+'</span></div>');}
    puts $fp {  } catch(e){ setB("openrouter","!"); render("openrouter",'<span class="err">'+esc(e.message)+'</span>'); }}
    puts $fp {}}}
    puts $fp {function iso30(){ const d=new Date(); d.setDate(d.getDate()-30); return d.toISOString().slice(0,10); }}
    puts $fp {async function loadOpenAI(){}
    puts $fp {  const k=getKeys(); if(!k.oai){ noKey("openai"); return; }}
    puts $fp {  try {}}}
    puts $fp {    const start = Math.floor((Date.now()-30*864e5)/1000);}
    puts $fp {    const d = await fetchJson("https://api.openai.com/v1/organization/costs?start_time="+start+"&limit=30", {Authorization:"Bearer "+k.oai});}
    puts $fp {    let total=0; (d&&d.data||[]).forEach(b=>(b.results||[]).forEach(r=>{ total += (r.amount&&r.amount.value)||0; }));}
    puts $fp {    setB("openai","ok");}
    puts $fp {    render("openai",'<div class="kv"><span class="k">Kosten 30 Tage (USD)</span><span class="v">'+total.toFixed(2)+'</span></div>');}
    puts $fp {  } catch(e){ setB("openai","!"); render("openai",'<span class="err">'+esc(e.message)+' (oft CORS/Admin-Key nötig)</span>'); }}
    puts $fp {}}}
    puts $fp {async function loadAnthropic(){}
    puts $fp {  const k=getKeys(); if(!k.anth){ noKey("anthropic"); return; }}
    puts $fp {  try {}}}
    puts $fp {    const d = await fetchJson("https://api.anthropic.com/v1/organizations/cost_report?starting_at="+iso30(), {"x-api-key":k.anth,"anthropic-version":"2023-06-01"});}
    puts $fp {    setB("anthropic","ok");}
    puts $fp {    render("anthropic",'<div class="kv"><span class="k">Cost-Report</span><span class="v">'+esc(JSON.stringify(d).slice(0,80))+'…</span></div>');}
    puts $fp {  } catch(e){ setB("anthropic","!"); render("anthropic",'<span class="err">'+esc(e.message)+' (Browser-CORS oft blockiert)</span>'); }}
    puts $fp {}}}
    puts $fp {async function loadTailscale(){}
    puts $fp {  const k=getKeys(); if(!k.ts){ noKey("tailscale"); return; }}
    puts $fp {  try {}}}
    puts $fp {    const net = k.tsnet||"-";}
    puts $fp {    const d = await fetchJson("https://api.tailscale.com/api/v2/tailnet/"+encodeURIComponent(net)+"/devices", {Authorization:"Bearer "+k.ts});}
    puts $fp {    const dev = (d&&d.devices)||[];}
    puts $fp {    setB("tailscale", dev.length);}
    puts $fp {    render("tailscale", dev.length ? dev.map(x=>'<div class="kv"><span class="k">'+esc(x.hostname||x.name)+'</span><span class="v">'+(x.lastSeen?esc(x.lastSeen.slice(0,10)):"")+'</span></div>').join("") : '<span class="muted">Keine Geräte.</span>');}
    puts $fp {  } catch(e){ setB("tailscale","!"); render("tailscale",'<span class="err">'+esc(e.message)+' (Browser-CORS oft blockiert)</span>'); }}
    puts $fp {}}}
    puts $fp {async function loadClawHub(){}
    puts $fp {  const k=getKeys(); const slugs=(k.clawhub||"").split(",").map(s=>s.trim()).filter(Boolean);}
    puts $fp {  if(!slugs.length){ noKey("clawhub"); return; }}
    puts $fp {  const rows=[]; let okc=0, total=0;}
    puts $fp {  for(const slug of slugs){}
    puts $fp {    try {}}}
    puts $fp {      const d = await fetchJson("https://clawhub.ai/api/v1/skills/"+encodeURIComponent(slug));}
    puts $fp {      const sk=(d&&d.skill)||{}; const ver=(d&&d.latestVersion&&d.latestVersion.version)||(sk.tags&&sk.tags.latest)||"?";}
    puts $fp {      const dl=(sk.stats&&(sk.stats.downloads!=null?sk.stats.downloads:sk.stats.downloadsAllTime));}
    puts $fp {      const verdict=(d&&d.moderation&&d.moderation.verdict)|| (d&&d.moderation&&d.moderation.isSuspicious?"suspicious":"clean");}
    puts $fp {      total+=(dl||0);}
    puts $fp {      rows.push('<div class="kv"><span class="k"><a href="https://clawhub.ai/'+esc(sk.ownerHandle||"")+'/'+esc(slug)+'" target="_blank">'+esc(sk.displayName||slug)+'</a> · v'+esc(ver)+'</span><span class="v">'+(dl!=null?dl+' DL':'')+' · '+esc(verdict)+'</span></div>');}
    puts $fp {      okc++;}
    puts $fp {    } catch(e){ rows.push('<div class="kv"><span class="k">'+esc(slug)+'</span><span class="v err">'+esc(e.message)+'</span></div>'); }}
    puts $fp {  }}
    puts $fp {  setB("clawhub", okc+"/"+slugs.length);}
    puts $fp {  render("clawhub", rows.join("") + (total?'<div class="kv"><span class="k">Downloads gesamt</span><span class="v">'+total+'</span></div>':''));}
    puts $fp {}}}
    puts $fp {function loadPerplexity(){}
    puts $fp {  setB("perplexity","i");}
    puts $fp {  render("perplexity",'<span class="muted">Perplexity bietet keinen Verbrauchs-/Credits-Endpunkt. Credits nur im Dashboard sichtbar — daher hier keine Live-Daten.</span>');}
    puts $fp {}}}
    puts $fp {}
    puts $fp {function loadAll(){}
    puts $fp {  scaffold();}
    puts $fp {  const k=getKeys();}
    puts $fp {  document.getElementById("sub").textContent = Object.values(k).some(Boolean) ? "Eigenständige Version · "+(new Date()).toLocaleString("de-DE") : "Eigenständige Version · keine Keys hinterlegt — klicke „Keys eingeben"".;}
    puts $fp {  loadGitHub(); loadOpenRouter(); loadOpenAI(); loadAnthropic(); loadTailscale(); loadClawHub(); loadPerplexity();}
    puts $fp {}}}
    puts $fp {}
    puts $fp {scaffold();}
    puts $fp {if(!Object.values(getKeys()).some(Boolean)) openCfg();}
    puts $fp {loadAll();}
    puts $fp {</script>}
    puts $fp {</body>}
    puts $fp {</html>}
    
    close $fp
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: $argv0 output.html"
    exit 1
}

generate_html [lindex $argv 0]
