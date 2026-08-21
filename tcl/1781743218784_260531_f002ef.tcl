#!/usr/bin/env tclsh
# 1781743218784_260531.pl — portiert nach tcl
# Quelle: perl5, Projects@abstractions:perl5/1781743218784_260531.pl
# Erzeugt: 2026-08-21 durch ABSTRACTIONS_MANAGER.py

# 1781743218784_260531.py — portiert nach perl5
# Quelle: python, Projects@abstractions:python/1781743218784_260531.py
# Erzeugt: 2026-08-18 durch ABSTRACTIONS_MANAGER.py

if {$argc != 1} {
    puts "Usage: [info script] output_file.html"
    exit 1
}

set output_file [lindex $argv 0]

if {[catch {set fp [open $output_file w]}]} {
    error "Could not open file '$output_file': $fp"
}

fconfigure $fp -encoding utf-8

# Write DOCTYPE and main script tag
puts $fp {<!DOCTYPE html>}
puts $fp {<script type="application/json" id="cowork-artifact-meta">}
puts $fp {{}
puts $fp {  "name": "Secret Vault Public",}
puts $fp {  "schemaVersion": 1,}
puts $fp {  "description": "Secret-Vault Public als interaktives Browser-Artefakt: verschlüsselter Secret-Container vollständig client-seitig (WebCrypto, AES-256-GCM + PBKDF2). Öffnen/Anlegen, Anbieter/Felder ergänzen und ersetzen (Rotation), verschlüsseln und als .svpb herunterladen oder Klartext-JSON exportieren. DE/EN nach Browsersprache. Eigenes Format (nicht kompatibel mit dem scrypt-Python-Tool). Keine Secrets eingebettet.",}
puts $fp {  "mcpTools": [],}
puts $fp {  "mcpServerNames": []}
puts $fp {}}</script>

# Write HTML start and head section
puts $fp {<html lang="de">}
puts $fp {<head>}
puts $fp {<meta charset="utf-8">}
puts $fp {<meta name="viewport" content="width=device-width, initial-scale=1">}
puts $fp {<title>Secret-Vault Public</title>}
puts $fp {<style>}
puts $fp {:root{ color-scheme:light; --ink:#1b1c1f; --muted:#6c6e75; --faint:#9a9ca3; --card:#fff; --line:#e9eaee; --accent:#5b5bd6; --accent2:#7c5cff; --ok:#22a06b; --err:#e0533d; --radius:16px; --shadow:0 1px 2px rgba(20,20,40,.04),0 6px 20px rgba(20,20,40,.06);}}
puts $fp {*{box-sizing:border-box;}}
puts $fp {body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;color:var(--ink);min-height:100vh;background:radial-gradient(1100px 560px at 100% -10%,#e8ecff 0%,rgba(232,236,255,0) 55%),linear-gradient(180deg,#eef1f6,#f7f7f8 42%);background-attachment:fixed;}}
puts $fp {.wrap{max-width:820px;margin:0 auto;padding:24px 18px 70px;}}
puts $fp {.brand{display:flex;align-items:center;gap:12px;margin-bottom:4px;}}
puts $fp {.mark{width:32px;height:32px;border-radius:9px;background:linear-gradient(135deg,var(--accent),var(--accent2));box-shadow:0 4px 12px rgba(91,91,214,.35);position:relative;flex:0 0 auto;}}
puts $fp {.mark:after{content:"";position:absolute;inset:8px;border-radius:4px;border:2px solid rgba(255,255,255,.92);}}
puts $fp {h1{font-size:21px;margin:0;font-weight:700;}}
puts $fp {.sub{color:var(--muted);font-size:13px;margin:2px 0 16px;}}
puts $fp {.card{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);padding:16px;margin-bottom:14px;}}
puts $fp {.card h2{font-size:14px;margin:0 0 10px;}}
puts $fp {label.lab{display:block;font-size:12px;font-weight:600;color:var(--muted);margin:8px 0 3px;}}
puts $fp {input,textarea{width:100%;font-size:13px;padding:8px 10px;border:1px solid var(--line);border-radius:9px;font-family:ui-monospace,Menlo,Consolas,monospace;background:#fff;}}
puts $fp {textarea{min-height:90px;white-space:pre;overflow:auto;}}
puts $fp {.row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;}}
puts $fp {.btn{font-size:13px;font-weight:600;padding:8px 14px;border:1px solid var(--line);border-radius:10px;background:#fff;cursor:pointer;box-shadow:var(--shadow);transition:transform .1s;}}
puts $fp {.btn:hover{transform:translateY(-1px);}}
puts $fp {.btn.primary{background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;border-color:transparent;}}
puts $fp {.btn.sm{padding:5px 9px;font-size:12px;}}
puts $fp {.msg{font-size:12px;margin-left:6px;}}
puts $fp {.msg.ok{color:var(--ok);} .msg.err{color:var(--err);}}
puts $fp {.prov{border:1px solid var(--line);border-radius:12px;padding:10px 12px;margin-bottom:10px;}}
puts $fp {.prov h3{margin:0 0 6px;font-size:13.5px;display:flex;align-items:center;gap:8px;}}
puts $fp {.kv{display:grid;grid-template-columns:180px 1fr auto;gap:6px;margin:4px 0;align-items:center;}}
puts $fp {.kv input{font-size:12px;padding:5px 7px;}}
puts $fp {.kv .k{color:var(--muted);font-weight:600;}}
puts $fp {.muted{color:var(--faint);font-size:13px;}}
puts $fp {.hide{display:none;}}
puts $fp {.foot{color:var(--faint);font-size:11.5px;text-align:center;margin-top:18px;line-height:1.5;}}
puts $fp {a{color:var(--accent);}}
puts $fp {</style>}
puts $fp {</head>}

# Write body content
puts $fp {<body>}
puts $fp {<div class="wrap">}
puts $fp {  <div class="brand"><div class="mark"></div><h1 id="title">Secret-Vault Public</h1></div>}
puts $fp {  <div class="sub" id="sub">Verschlüsselte Secret-Vault (AES-256-GCM, PBKDF2) — alles im Browser, kein Server.</div>}

# Card: Open or new
puts $fp {  <div class="card">}
puts $fp {    <h2 id="h-open">Öffnen oder neu</h2>}
puts $fp {    <label class="lab" id="l-pass">Passphrase</label>}
puts $fp {    <input id="pass" type="password" placeholder="Passphrase…">}
puts $fp {    <label class="lab" id="l-file">Vault laden (Datei oder Base64 einfügen)</label>}
puts $fp {    <input id="file" type="file" accept=".svpb,.txt,.vault,.b64">}
puts $fp {    <textarea id="blob" placeholder="…oder Base64 hier einfügen"></textarea>}
puts $fp {    <div class="row" style="margin-top:10px">}
puts $fp {      <button class="btn primary" id="openBtn">Öffnen / Entschlüsseln</button>}
puts $fp {      <button class="btn" id="newBtn">Neuer leerer Vault</button>}
puts $fp {      <span class="msg" id="openMsg"></span>}
puts $fp {    </div>}
puts $fp {  </div>}

# Card: Editor (hidden by default)
puts $fp {  <div class="card hide" id="editor">}
puts $fp {    <h2 id="h-edit">Inhalt</h2>}
puts $fp {    <div id="provs"></div>}
puts $fp {    <div class="row" style="margin-top:8px">}
puts $fp {      <input id="newProv" placeholder="Neuer Anbieter (Name)" style="max-width:280px">}
puts $fp {      <button class="btn sm" id="addProvBtn">+ Anbieter</button>}
puts $fp {    </div>}
puts $fp {  </div>}

# Card: Save/Export (hidden by default)
puts $fp {  <div class="card hide" id="out">}
puts $fp {    <h2 id="h-save">Speichern / Export</h2>}
puts $fp {    <div class="row">}
puts $fp {      <button class="btn primary" id="encBtn">Verschlüsseln</button>}
puts $fp {      <button class="btn" id="dlBtn">Als .svpb herunterladen</button>}
puts $fp {      <button class="btn" id="expBtn">Klartext-JSON exportieren</button>}
puts $fp {      <span class="msg" id="saveMsg"></span>}
puts $fp {    </div>}
puts $fp {    <label class="lab" id="l-result">Ergebnis (zum Kopieren/Speichern)</label>}
puts $fp {    <textarea id="result" readonly></textarea>}
puts $fp {  </div>}

# Footer
puts $fp {  <div class="foot" id="foot"></div>}
puts $fp {</div>}

# JavaScript section
puts $fp {<script>}
puts $fp {const L = ((navigator.language||"en").toLowerCase().startsWith("de"))?"de":"en";}
puts $fp {const T = {}
puts $fp { title:{de:"Secret-Vault Public",en:"Secret-Vault Public"},}
puts $fp { sub:{de:"Verschlüsselte Secret-Vault (AES-256-GCM, PBKDF2) — alles im Browser, kein Server.",en:"Encrypted secret vault (AES-256-GCM, PBKDF2) — fully in the browser, no server."},}
puts $fp { hOpen:{de:"Öffnen oder neu",en:"Open or new"},}
puts $fp { pass:{de:"Passphrase",en:"Passphrase"},}
puts $fp { file:{de:"Vault laden (Datei oder Base64 einfügen)",en:"Load vault (file or paste Base64)"},}
puts $fp { blob:{de:"…oder Base64 hier einfügen",en:"…or paste Base64 here"},}
puts $fp { open:{de:"Öffnen / Entschlüsseln",en:"Open / Decrypt"},}
puts $fp { neu:{de:"Neuer leerer Vault",en:"New empty vault"},}
puts $fp { hEdit:{de:"Inhalt",en:"Content"},}
puts $fp { newProv:{de:"Neuer Anbieter (Name)",en:"New provider (name)"},}
puts $fp { addProv:{de:"+ Anbieter",en:"+ Provider"},}
puts $fp { hSave:{de:"Speichern / Export",en:"Save / Export"},}
puts $fp { enc:{de:"Verschlüsseln",en:"Encrypt"},}
puts $fp { dl:{de:"Als .svpb herunterladen",en:"Download as .svpb"},}
puts $fp { exp:{de:"Klartext-JSON exportieren",en:"Export plaintext JSON"},}
puts $fp { result:{de:"Ergebnis (zum Kopieren/Speichern)",en:"Result (to copy/save)"},}
puts $fp { foot:{de:"Eigenes Format (PBKDF2). Nicht kompatibel mit dem scrypt-Python-Tool. Sicherheit liegt in der Passphrase; Inhalt ohne sie nicht wiederherstellbar.",en:"Own format (PBKDF2). Not compatible with the scrypt Python tool. Security rests on the passphrase; content is unrecoverable without it."},}
puts $fp { needPass:{de:"Passphrase eingeben.",en:"Enter a passphrase."},}
puts $fp { noInput:{de:"Datei laden oder Base64 einfügen.",en:"Load a file or paste Base64."},}
puts $fp { bad:{de:"Falsche Passphrase oder ungültiger Vault.",en:"Wrong passphrase or invalid vault."},}
puts $fp { opened:{de:"Geöffnet.",en:"Opened."},}
puts $fp { created:{de:"Neuer Vault angelegt.",en:"New vault created."},}
puts $fp { encrypted:{de:"Verschlüsselt — unten kopieren oder herunterladen.",en:"Encrypted — copy below or download."},}
puts $fp { needOpen:{de:"Erst öffnen/anlegen.",en:"Open/create first."},}
puts $fp { field:{de:"Feld",en:"field"}, value:{de:"Wert",en:"value"},}
puts $fp { addField:{de:"+ Feld",en:"+ field"}, del:{de:"✕",en:"✕"},}
puts $fp { newField:{de:"neues Feld",en:"new field"}, newValue:{de:"Wert",en:"value"}}
puts $fp {};}
puts $fp {const tr=k=>T[k][L];}
puts $fp {// apply static i18n}
puts $fp {title.textContent=tr("title"); sub.textContent=tr("sub"); document.title=tr("title");}
puts $fp {document.getElementById("h-open").textContent=tr("hOpen");}
puts $fp {document.getElementById("l-pass").textContent=tr("pass");}
puts $fp {document.getElementById("l-file").textContent=tr("file");}
puts $fp {blob.placeholder=tr("blob");}
puts $fp {openBtn.textContent=tr("open"); newBtn.textContent=tr("neu");}
puts $fp {document.getElementById("h-edit").textContent=tr("hEdit");}
puts $fp {newProv.placeholder=tr("newProv"); addProvBtn.textContent=tr("addProv");}
puts $fp {document.getElementById("h-save").textContent=tr("hSave");}
puts $fp {encBtn.textContent=tr("enc"); dlBtn.textContent=tr("dl"); expBtn.textContent=tr("exp");}
puts $fp {document.getElementById("l-result").textContent=tr("result");}
puts $fp {foot.textContent=tr("foot");}
puts $fp {}
puts $fp {let VAULT=null; // {meta, providers:{}}}
puts $fp {}
puts $fp {const enc=new TextEncoder(), dec=new TextDecoder();}
puts $fp {function u8b64(u8){ let s=""; for(let i=0;i<u8.length;i+=0x8000) s+=String.fromCharCode.apply(null,u8.subarray(i,i+0x8000)); return btoa(s); }}
puts $fp {function b64u8(b64){ const s=atob(b64.trim()); const u=new Uint8Array(s.length); for(let i=0;i<s.length;i++) u[i]=s.charCodeAt(i); return u; }}
puts $fp {async function deriveKey(pw,salt){}
puts $fp {  const km=await crypto.subtle.importKey("raw",enc.encode(pw),"PBKDF2",false,["deriveKey"]);}
puts $fp {  return crypto.subtle.deriveKey({name:"PBKDF2",salt,iterations:210000,hash:"SHA-256"},km,{name:"AES-GCM",length:256},false,["encrypt","decrypt"]);}
puts $fp {}}}
puts $fp {async function encryptObj(obj,pw){}
puts $fp {  const salt=crypto.getRandomValues(new Uint8Array(16)), iv=crypto.getRandomValues(new Uint8Array(12));}
puts $fp {  const key=await deriveKey(pw,salt);}
puts $fp {  const ct=new Uint8Array(await crypto.subtle.encrypt({name:"AES-GCM",iv},key,enc.encode(JSON.stringify(obj,null,2))));}
puts $fp {  const magic=enc.encode("SVPB1"); const out=new Uint8Array(5+16+12+ct.length);}
puts $fp {  out.set(magic,0); out.set(salt,5); out.set(iv,21); out.set(ct,33); return u8b64(out);}
puts $fp {}}}
puts $fp {async function decryptB64(b64,pw){}
puts $fp {  const raw=b64u8(b64); if(dec.decode(raw.slice(0,5))!=="SVPB1") throw new Error("magic");}
puts $fp {  const key=await deriveKey(pw,raw.slice(5,21));}
puts $fp {  const pt=await crypto.subtle.decrypt({name:"AES-GCM",iv:raw.slice(21,33)},key,raw.slice(33));}
puts $fp {  return JSON.parse(dec.decode(pt));}
puts $fp {}}}
puts $fp {function esc(s){return (s==null?"":String(s)).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;'>':'&gt;','"':'&quot;'}[c]));}}
puts $fp {}
puts $fp {function renderEditor(){}
puts $fp {  document.getElementById("editor").classList.remove("hide");}
puts $fp {  document.getElementById("out").classList.remove("hide");}
puts $fp {  const P=VAULT.providers||{}; const root=document.getElementById("provs"); root.innerHTML="";}
puts $fp {  Object.keys(P).forEach(name=>{}
puts $fp {    const d=document.createElement("div"); d.className="prov";}
puts $fp {    let rows="";}
puts $fp {    Object.keys(P[name]).forEach(k=>{ rows+=`<div class="kv"><span class="k">${esc(k)}</span><input data-p="${esc(name)}" data-k="${esc(k)}" value="${esc(P[name][k])}"><button class="btn sm" data-del="${esc(name)}|${esc(k)}">${tr("del")}</button></div>`; });}
puts $fp {    d.innerHTML=`<h3>${esc(name)} <button class="btn sm" data-delp="${esc(name)}">${tr("del")}</button></h3>${rows}
      <div class="row" style="margin-top:6px"><input class="nf" data-np="${esc(name)}" placeholder="${tr("newField")}" style="max-width:180px"><input class="nv" data-np="${esc(name)}" placeholder="${tr("newValue")}" style="max-width:260px"><button class="btn sm" data-addf="${esc(name)}">${tr("addField")}</button></div>`;}
puts $fp {    root.appendChild(d);}
puts $fp {  });}
puts $fp {  root.querySelectorAll("input[data-k]").forEach(i=>i.onchange=()=>{ VAULT.providers[i.dataset.p][i.dataset.k]=i.value; });}
puts $fp {  root.querySelectorAll("button[data-del]").forEach(b=>b.onclick=()=>{ const [p,k]=b.dataset.del.split("|"); delete VAULT.providers[p][k]; renderEditor(); });}
puts $fp {  root.querySelectorAll("button[data-delp]").forEach(b=>b.onclick=()=>{ delete VAULT.providers[b.dataset.delp]; renderEditor(); });}
puts $fp {  root.querySelectorAll("button[data-addf]").forEach(b=>b.onclick=()=>{ const p=b.dataset.addf; const nf=root.querySelector(`.nf[data-np="${CSS.escape(p)}"]`).value.trim(); const nv=root.querySelector(`.nv[data-np="${CSS.escape(p)}"]`).value; if(nf){ VAULT.providers[p][nf]=nv; renderEditor(); } });}
puts $fp {}}}
puts $fp {}
puts $fp {document.getElementById("file").onchange=e=>{ const f=e.target.files[0]; if(!f)return; const r=new FileReader(); r.onload=()=>{ blob.value=r.result.trim(); }; r.readAsText(f); };}
puts $fp {openBtn.onclick=async()=>{}
puts $fp {  const m=document.getElementById("openMsg"); m.className="msg"; m.textContent="";}
puts $fp {  if(!pass.value){ m.className="msg err"; m.textContent=tr("needPass"); return; }}
puts $fp {  if(!blob.value.trim()){ m.className="msg err"; m.textContent=tr("noInput"); return; }}
puts $fp {  try{ VAULT=await decryptB64(blob.value,pass.value); if(!VAULT.providers)VAULT.providers={}; renderEditor(); m.className="msg ok"; m.textContent=tr("opened"); }}
puts $fp {  catch(err){ m.className="msg err"; m.textContent=tr("bad"); }}
puts $fp {}};}
puts $fp {newBtn.onclick=()=>{}
puts $fp {  const m=document.getElementById("openMsg");}
puts $fp {  if(!pass.value){ m.className="msg err"; m.textContent=tr("needPass"); return; }}
puts $fp {  VAULT={meta:{created:new Date().toISOString().slice(0,10),format:"SVPB1"},providers:{}}; renderEditor();}
puts $fp {  m.className="msg ok"; m.textContent=tr("created");}
puts $fp {}};}
puts $fp {addProvBtn.onclick=()=>{ if(!VAULT){ return; } const n=newProv.value.trim(); if(n){ VAULT.providers[n]=VAULT.providers[n]||{}; newProv.value=""; renderEditor(); } };}
puts $fp {encBtn.onclick=async()=>{}
puts $fp {  const m=document.getElementById("saveMsg"); m.className="msg";}
puts $fp {  if(!VAULT){ m.className="msg err"; m.textContent=tr("needOpen"); return; }}
puts $fp {  if(!pass.value){ m.className="msg err"; m.textContent=tr("needPass"); return; }}
puts $fp {  result.value=await encryptObj(VAULT,pass.value); m.className="msg ok"; m.textContent=tr("encrypted");}
puts $fp {}};}
puts $fp {dlBtn.onclick=()=>{ if(!result.value)return; try{ const b=new Blob([result.value],{type:"text/plain"}); const u=URL.createObjectURL(b); const a=document.createElement("a"); a.href=u; a.download="vault.svpb"; document.body.appendChild(a); a.click(); a.remove(); setTimeout(()=>URL.revokeObjectURL(u),1500);}catch(e){} };}
puts $fp {expBtn.onclick=()=>{ if(!VAULT)return; result.value=JSON.stringify(VAULT,null,2); };}
puts $fp {</script>}
puts $fp {</body>}
puts $fp {</html>}

close $fp
puts "HTML file generated: $output_file"
