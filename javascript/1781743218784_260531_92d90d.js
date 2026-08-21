#!/usr/bin/env node
// 1781743218784_260531.ps1 — portiert nach javascript
// Quelle: powershell, Projects@abstractions:powershell/1781743218784_260531.ps1
// Erzeugt: 2026-08-21 durch ABSTRACTIONS_MANAGER.py

// 1781743218784_260531.js — portiert nach powershell
// Quelle: javascript, Projects@abstractions:javascript/1781743218784_260531.js
// Erzeugt: 2026-08-18 durch ABSTRACTIONS_MANAGER.py

// 1781743218784.tcl — portiert nach javascript
// Quelle: tcl, Projects@abstractions:tcl/1781743218784.tcl
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// 1781743218784.html — portiert nach tcl
// Quelle: html, Projects@secret-vault-public:secret-vault-public/versions/1781743218784.html
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// Node.js script to generate the Secret Vault Public HTML file
// Usage: node this_script.js output_file.html

import { writeFileSync } from 'fs';
import { argv } from 'process';

if (argv.length !== 3) {
    console.error('Usage: node this_script.js output_file.html');
    process.exit(1);
}

const outputFile = argv[2];

try {
    let content = '';
    
    // Write DOCTYPE and main script tag
    content += '<!DOCTYPE html>\n';
    content += '<script type="application/json" id="cowork-artifact-meta">\n';
    content += '\n';
    content += '{\n';
    content += '  "name": "Secret Vault Public",\n';
    content += '  "schemaVersion": 1,\n';
    content += '  "description": "Secret-Vault Public als interaktives Browser-Artefakt: verschlüsselter Secret-Container vollständig client-seitig (WebCrypto, AES-256-GCM + PBKDF2). Öffnen/Anlegen, Anbieter/Felder ergänzen und ersetzen (Rotation), verschlüsseln und als .svpb herunterladen oder Klartext-JSON exportieren. DE/EN nach Browsersprache. Eigenes Format (nicht kompatibel mit dem scrypt-Python-Tool). Keine Secrets eingebettet.",\n';
    content += '  "mcpTools": [],\n';
    content += '  "mcpServerNames": []\n';
    content += '}\n';
    content += '\n';
    content += '</script>\n';
    
    // Write HTML start and head section
    content += '<html lang="de">\n';
    content += '<head>\n';
    content += '<meta charset="utf-8">\n';
    content += '<meta name="viewport" content="width=device-width, initial-scale=1">\n';
    content += '<title>Secret-Vault Public</title>\n';
    content += '<style>\n';
    content += ':root{ color-scheme:light; --ink:#1b1c1f; --muted:#6c6e75; --faint:#9a9ca3; --card:#fff; --line:#e9eaee; --accent:#5b5bd6; --accent2:#7c5cff; --ok:#22a06b; --err:#e0533d; --radius:16px; --shadow:0 1px 2px rgba(20,20,40,.04),0 6px 20px rgba(20,20,40,.06);}\n';
    content += '*{box-sizing:border-box;}\n';
    content += 'body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;color:var(--ink);min-height:100vh;background:radial-gradient(1100px 560px at 100% -10%,#e8ecff 0%,rgba(232,236,255,0) 55%),linear-gradient(180deg,#eef1f6,#f7f7f8 42%);background-attachment:fixed;}\n';
    content += '.wrap{max-width:820px;margin:0 auto;padding:24px 18px 70px;}\n';
    content += '.brand{display:flex;align-items:center;gap:12px;margin-bottom:4px;}\n';
    content += '.mark{width:32px;height:32px;border-radius:9px;background:linear-gradient(135deg,var(--accent),var(--accent2));box-shadow:0 4px 12px rgba(91,91,214,.35);position:relative;flex:0 0 auto;}\n';
    content += '.mark:after{content:"";position:absolute;inset:8px;border-radius:4px;border:2px solid rgba(255,255,255,.92);}\n';
    content += 'h1{font-size:21px;margin:0;font-weight:700;}\n';
    content += '.sub{color:var(--muted);font-size:13px;margin:2px 0 16px;}\n';
    content += '.card{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);padding:16px;margin-bottom:14px;}\n';
    content += '.card h2{font-size:14px;margin:0 0 10px;}\n';
    content += 'label.lab{display:block;font-size:12px;font-weight:600;color:var(--muted);margin:8px 0 3px;}\n';
    content += 'input,textarea{width:100%;font-size:13px;padding:8px 10px;border:1px solid var(--line);border-radius:9px;font-family:ui-monospace,Menlo,Consolas,monospace;background:#fff;}\n';
    content += 'textarea{min-height:90px;white-space:pre;overflow:auto;}\n';
    content += '.row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;}\n';
    content += '.btn{font-size:13px;font-weight:600;padding:8px 14px;border:1px solid var(--line);border-radius:10px;background:#fff;cursor:pointer;box-shadow:var(--shadow);transition:transform .1s;}\n';
    content += '.btn:hover{transform:translateY(-1px);}\n';
    content += '.btn.primary{background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;border-color:transparent;}\n';
    content += '.btn.sm{padding:5px 9px;font-size:12px;}\n';
    content += '.msg{font-size:12px;margin-left:6px;}\n';
    content += '.msg.ok{color:var(--ok);} .msg.err{color:var(--err);}\n';
    content += '.prov{border:1px solid var(--line);border-radius:12px;padding:10px 12px;margin-bottom:10px;}\n';
    content += '.prov h3{margin:0 0 6px;font-size:13.5px;display:flex;align-items:center;gap:8px;}\n';
    content += '.kv{display:grid;grid-template-columns:180px 1fr auto;gap:6px;margin:4px 0;align-items:center;}\n';
    content += '.kv input{font-size:12px;padding:5px 7px;}\n';
    content += '.kv .k{color:var(--muted);font-weight:600;}\n';
    content += '.muted{color:var(--faint);font-size:13px;}\n';
    content += '.hide{display:none;}\n';
    content += '.foot{color:var(--faint);font-size:11.5px;text-align:center;margin-top:18px;line-height:1.5;}\n';
    content += 'a{color:var(--accent);}\n';
    content += '</style>\n';
    content += '</head>\n';
    
    // Write body content
    content += '<body>\n';
    content += '<div class="wrap">\n';
    content += '  <div class="brand"><div class="mark"></div><h1 id="title">Secret-Vault Public</h1></div>\n';
    content += '  <div class="sub" id="sub">Verschlüsselte Secret-Vault (AES-256-GCM, PBKDF2) — alles im Browser, kein Server.</div>\n';
    
    // Card: Open or new
    content += '\n';
    content += '  <div class="card">\n';
    content += '    <h2 id="h-open">Öffnen oder neu</h2>\n';
    content += '    <label class="lab" id="l-pass">Passphrase</label>\n';
    content += '    <input id="pass" type="password" placeholder="Passphrase…">\n';
    content += '    <label class="lab" id="l-file">Vault laden (Datei oder Base64 einfügen)</label>\n';
    content += '    <input id="file" type="file" accept=".svpb,.txt,.vault,.b64">\n';
    content += '    <textarea id="blob" placeholder="…oder Base64 hier einfügen"></textarea>\n';
    content += '    <div class="row" style="margin-top:10px">\n';
    content += '      <button class="btn primary" id="openBtn">Öffnen / Entschlüsseln</button>\n';
    content += '      <button class="btn" id="newBtn">Neuer leerer Vault</button>\n';
    content += '      <span class="msg" id="openMsg"></span>\n';
    content += '    </div>\n';
    content += '  </div>\n';
    content += '\n';
    
    // Card: Editor (hidden by default)
    content += '  <div class="card hide" id="editor">\n';
    content += '    <h2 id="h-edit">Inhalt</h2>\n';
    content += '    <div id="provs"></div>\n';
    content += '    <div class="row" style="margin-top:8px">\n';
    content += '      <input id="newProv" placeholder="Neuer Anbieter (Name)" style="max-width:280px">\n';
    content += '      <button class="btn sm" id="addProvBtn">+ Anbieter</button>\n';
    content += '    </div>\n';
    content += '  </div>\n';
    content += '\n';
    
    // Card: Save/Export (hidden by default)
    content += '  <div class="card hide" id="out">\n';
    content += '    <h2 id="h-save">Speichern / Export</h2>\n';
    content += '    <div class="row">\n';
    content += '      <button class="btn primary" id="encBtn">Verschlüsseln</button>\n';
    content += '      <button class="btn" id="dlBtn">Als .svpb herunterladen</button>\n';
    content += '      <button class="btn" id="expBtn">Klartext-JSON exportieren</button>\n';
    content += '      <span class="msg" id="saveMsg"></span>\n';
    content += '    </div>\n';
    content += '    <label class="lab" id="l-result">Ergebnis (zum Kopieren/Speichern)</label>\n';
    content += '    <textarea id="result" readonly></textarea>\n';
    content += '  </div>\n';
    content += '\n';
    
    // Footer
    content += '  <div class="foot" id="foot"></div>\n';
    content += '</div>\n';
    
    // JavaScript section
    content += '<script>\n';
    content += '\n';
    content += 'const L = ((navigator.language||"en").toLowerCase().startsWith("de"))?"de":"en";\n';
    content += 'const T = {\n';
    content += ' title:{de:"Secret-Vault Public",en:"Secret-Vault Public"},\n';
    content += ' sub:{de:"Verschlüsselte Secret-Vault (AES-256-GCM, PBKDF2) — alles im Browser, kein Server.",en:"Encrypted secret vault (AES-256-GCM, PBKDF2) — fully in the browser, no server."},\n';
    content += ' hOpen:{de:"Öffnen oder neu",en:"Open or new"},\n';
    content += ' pass:{de:"Passphrase",en:"Passphrase"},\n';
    content += ' file:{de:"Vault laden (Datei oder Base64 einfügen)",en:"Load vault (file or paste Base64)"},\n';
    content += ' blob:{de:"…oder Base64 hier einfügen",en:"…or paste Base64 here"},\n';
    content += ' open:{de:"Öffnen / Entschlüsseln",en:"Open / Decrypt"},\n';
    content += ' neu:{de:"Neuer leerer Vault",en:"New empty vault"},\n';
    content += ' hEdit:{de:"Inhalt",en:"Content"},\n';
    content += ' newProv:{de:"Neuer Anbieter (Name)",en:"New provider (name)"},\n';
    content += ' addProv:{de:"+ Anbieter",en:"+ Provider"},\n';
    content += ' hSave:{de:"Speichern / Export",en:"Save / Export"},\n';
    content += ' enc:{de:"Verschlüsseln",en:"Encrypt"},\n';
    content += ' dl:{de:"Als .svpb herunterladen",en:"Download as .svpb"},\n';
    content += ' exp:{de:"Klartext-JSON exportieren",en:"Export plaintext JSON"},\n';
    content += ' result:{de:"Ergebnis (zum Kopieren/Speichern)",en:"Result (to copy/save)"},\n';
    content += ' foot:{de:"Eigenes Format (PBKDF2). Nicht kompatibel mit dem scrypt-Python-Tool. Sicherheit liegt in der Passphrase; Inhalt ohne sie nicht wiederherstellbar.",en:"Own format (PBKDF2). Not compatible with the scrypt Python tool. Security rests on the passphrase; content is unrecoverable without it."},\n';
    content += ' needPass:{de:"Passphrase eingeben.",en:"Enter a passphrase."},\n';
    content += ' noInput:{de:"Datei laden oder Base64 einfügen.",en:"Load a file or paste Base64."},\n';
    content += ' bad:{de:"Falsche Passphrase oder ungültiger Vault.",en:"Wrong passphrase or invalid vault."},\n';
    content += ' opened:{de:"Geöffnet.",en:"Opened."},\n';
    content += ' created:{de:"Neuer Vault angelegt.",en:"New vault created."},\n';
    content += ' encrypted:{de:"Verschlüsselt — unten kopieren oder herunterladen.",en:"Encrypted — copy below or download."},\n';
    content += ' needOpen:{de:"Erst öffnen/anlegen.",en:"Open/create first."},\n';
    content += ' field:{de:"Feld",en:"field"}, value:{de:"Wert",en:"value"},\n';
    content += ' addField:{de:"+ Feld",en:"+ field"}, del:{de:"✕",en:"✕"},\n';
    content += ' newField:{de:"neues Feld",en:"new field"}, newValue:{de:"Wert",en:"value"}\n';
    content += '};\n';
    content += 'const tr=k=>T[k][L];\n';
    content += '// apply static i18n\n';
    content += 'title.textContent=tr("title"); sub.textContent=tr("sub"); document.title=tr("title");\n';
    content += 'document.getElementById("h-open").textContent=tr("hOpen");\n';
    content += 'document.getElementById("l-pass").textContent=tr("pass");\n';
    content += 'document.getElementById("l-file").textContent=tr("file");\n';
    content += 'blob.placeholder=tr("blob");\n';
    content += 'openBtn.textContent=tr("open"); newBtn.textContent=tr("neu");\n';
    content += 'document.getElementById("h-edit").textContent=tr("hEdit");\n';
    content += 'newProv.placeholder=tr("newProv"); addProvBtn.textContent=tr("addProv");\n';
    content += 'document.getElementById("h-save").textContent=tr("hSave");\n';
    content += 'encBtn.textContent=tr("enc"); dlBtn.textContent=tr("dl"); expBtn.textContent=tr("exp");\n';
    content += 'document.getElementById("l-result").textContent=tr("result");\n';
    content += 'foot.textContent=tr("foot");\n';
    content += '\n';
    content += 'let VAULT=null; // {meta, providers:{}}\n';
    content += '\n';
    content += 'const enc=new TextEncoder(), dec=new TextDecoder();\n';
    content += 'function u8b64(u8){ let s=""; for(let i=0;i<u8.length;i+=0x8000) s+=String.fromCharCode.apply(null,u8.subarray(i,i+0x8000)); return btoa(s); }\n';
    content += 'function b64u8(b64){ const s=atob(b64.trim()); const u=new Uint8Array(s.length); for(let i=0;i<s.length;i++) u[i]=s.charCodeAt(i); return u; }\n';
    content += 'async function deriveKey(pw,salt){\n';
    content += '  const km=await crypto.subtle.importKey("raw",enc.encode(pw),"PBKDF2",false,["deriveKey"]);\n';
    content += '  return crypto.subtle.deriveKey({name:"PBKDF2",salt,iterations:210000,hash:"SHA-256"},km,{name:"AES-GCM",length:256},false,["encrypt","decrypt"]);\n';
    content += '}\n';
    content += 'async function encryptObj(obj,pw){\n';
    content += '  const salt=crypto.getRandomValues(new Uint8Array(16)), iv=crypto.getRandomValues(new Uint8Array(12));\n';
    content += '  const key=await deriveKey(pw,salt);\n';
    content += '  const ct=new Uint8Array(await crypto.subtle.encrypt({name:"AES-GCM",iv},key,enc.encode(JSON.stringify(obj,null,2))));\n';
    content += '  const magic=enc.encode("SVPB1"); const out=new Uint8Array(5+16+12+ct.length);\n';
    content += '  out.set(magic,0); out.set(salt,5); out.set(iv,21); out.set(ct,33); return u8b64(out);\n';
    content += '}\n';
    content += 'async function decryptB64(b64,pw){\n';
    content += '  const raw=b64u8(b64); if(dec.decode(raw.slice(0,5))!=="SVPB1") throw new Error("magic");\n';
    content += '  const key=await deriveKey(pw,raw.slice(5,21));\n';
    content += '  const pt=await crypto.subtle.decrypt({name:"AES-GCM",iv:raw.slice(21,33)},key,raw.slice(33));\n';
    content += '  return JSON.parse(dec.decode(pt));\n';
    content += '}\n';
    content += 'function esc(s){return (s==null?"":String(s)).replace(/[&<>]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",\'"\':"&quot;"}[c]));}\n';
    content += '\n';
    content += 'function renderEditor(){\n';
    content += '  document.getElementById("editor").classList.remove("hide");\n';
    content += '  document.getElementById("out").classList.remove("hide");\n';
    content += '  const P=VAULT.providers||{}; const root=document.getElementById("provs"); root.innerHTML="";\n';
    content += '  Object.keys(P).forEach(name=>{\n';
    content += '    const d=document.createElement("div"); d.className="prov";\n';
    content += '    let rows="";\n';
    content += '    Object.keys(P[name]).forEach(k=>{ rows+=`<div class="kv"><span class="k">${esc(k)}</span><input data-p="${esc(name)}" data-k="${esc(k)}" value="${esc(P[name][k])}"><button class="btn sm" data-del="${esc(name)}|${esc(k)}">${tr("del")}</button></div>`; });\n';
    content += '    d.innerHTML=`<h3>${esc(name)} <button class="btn sm" data-delp="${esc(name)}">${tr("del")}</button></h3>${rows}`\n';
    content += '      + `<div class="row" style="margin-top:6px"><input class="nf" data-np="${esc(name)}" placeholder="${tr("newField")}" style="max-width:180px"><input class="nv" data-np="${esc(name)}" placeholder="${tr("newValue")}" style="max-width:260px"><button class="btn sm" data-addf="${esc(name)}">${tr("addField")}</button></div>`;\n';
    content += '    root.appendChild(d);\n';
    content += '  });\n';
    content += '  root.querySelectorAll("input[data-k]").forEach(i=>i.onchange=()=>{ VAULT.providers[i.dataset.p][i.dataset.k]=i.value; });\n';
    content += '  root.querySelectorAll("button[data-del]").forEach(b=>b.onclick=()=>{ const [p,k]=b.dataset.del.split("|"); delete VAULT.providers[p][k]; renderEditor(); });\n';
    content += '  root.querySelectorAll("button[data-delp]").forEach(b=>b.onclick=()=>{ delete VAULT.providers[b.dataset.delp]; renderEditor(); });\n';
    content += '  root.querySelectorAll("button[data-addf]").forEach(b=>b.onclick=()=>{ const p=b.dataset.addf; const nf=root.querySelector(`.nf[data-np="${CSS.escape(p)}"]`).value.trim(); const nv=root.querySelector(`.nv[data-np="${CSS.escape(p)}"]`).value; if(nf){ VAULT.providers[p][nf]=nv; renderEditor(); } });\n';
    content += '}\n';
    content += '\n';
    content += 'document.getElementById("file").onchange=e=>{ const f=e.target.files[0]; if(!f)return; const r=new FileReader(); r.onload=()=>{ blob.value=r.result.trim(); }; r.readAsText(f); };\n';
    content += 'openBtn.onclick=async()=>{\n';
    content += '  const m=document.getElementById("openMsg"); m.className="msg"; m.textContent="";\n';
    content += '  if(!pass.value){ m.className="msg err"; m.textContent=tr("needPass"); return; }\n';
    content += '  if(!blob.value.trim()){ m.className="msg err"; m.textContent=tr("noInput"); return; }\n';
    content += '  try{ VAULT=await decryptB64(blob.value,pass.value); if(!VAULT.providers)VAULT.providers={}; renderEditor(); m.className="msg ok"; m.textContent=tr("opened"); }\n';
    content += '  catch(err){ m.className="msg err"; m.textContent=tr("bad"); }\n';
    content += '};\n';
    content += 'newBtn.onclick=()=>{\n';
    content += '  const m=document.getElementById("openMsg");\n';
    content += '  if(!pass.value){ m.className="msg err"; m.textContent=tr("needPass"); return; }\n';
    content += '  VAULT={meta:{created:new Date().toISOString().slice(0,10),format:"SVPB1"},providers:{}}; renderEditor();\n';
    content += '  m.className="msg ok"; m.textContent=tr("created");\n';
    content += '};\n';
    content += 'addProvBtn.onclick=()=>{ if(!VAULT){ return; } const n=newProv.value.trim(); if(n){ VAULT.providers[n]=VAULT.providers[n]||{}; newProv.value=""; renderEditor(); } };\n';
    content += 'encBtn.onclick=async()=>{\n';
    content += '  const m=document.getElementById("saveMsg"); m.className="msg";\n';
    content += '  if(!VAULT){ m.className="msg err"; m.textContent=tr("needOpen"); return; }\n';
    content += '  if(!pass.value){ m.className="msg err"; m.textContent=tr("needPass"); return; }\n';
    content += '  result.value=await encryptObj(VAULT,pass.value); m.className="msg ok"; m.textContent=tr("encrypted");\n';
    content += '};\n';
    content += 'dlBtn.onclick=()=>{ if(!result.value)return; try{ const b=new Blob([result.value],{type:"text/plain"}); const u=URL.createObjectURL(b); const a=document.createElement("a"); a.href=u; a.download="vault.svpb"; document.body.appendChild(a); a.click(); a.remove(); setTimeout(()=>URL.revokeObjectURL(u),1500);}catch(e){} };\n';
    content += 'expBtn.onclick=()=>{ if(!VAULT)return; result.value=JSON.stringify(VAULT,null,2); };\n';
    content += '\n';
    content += '</script>\n';
    content += '</body>\n';
    content += '</html>\n';
    
    writeFileSync(outputFile, content);
    
    console.log(`HTML file generated: ${outputFile}`);
} catch (error) {
    console.error(`Error generating HTML file: ${error.message}`);
    process.exit(1);
}
