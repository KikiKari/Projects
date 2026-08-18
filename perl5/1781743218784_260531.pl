#!/usr/bin/perl
# 1781743218784_260531.py — portiert nach perl5
# Quelle: python, Projects@abstractions:python/1781743218784_260531.py
# Erzeugt: 2026-08-18 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON;

sub main {
    my @args = @ARGV;
    if (@args != 1) {
        print "Usage: $0 output_file.html\n";
        exit 1;
    }

    my $output_file = $args[0];

    open(my $fp, '>:encoding(UTF-8)', $output_file) or die "Could not open file '$output_file' $!";

    # Write DOCTYPE and main script tag
    print $fp '<!DOCTYPE html>' . "\n";
    print $fp '<script type="application/json" id="cowork-artifact-meta">' . "\n";
    print $fp '{' . "\n";
    print $fp '  "name": "Secret Vault Public",' . "\n";
    print $fp '  "schemaVersion": 1,' . "\n";
    print $fp '  "description": "Secret-Vault Public als interaktives Browser-Artefakt: verschlüsselter Secret-Container vollständig client-seitig (WebCrypto, AES-256-GCM + PBKDF2). Öffnen/Anlegen, Anbieter/Felder ergänzen und ersetzen (Rotation), verschlüsseln und als .svpb herunterladen oder Klartext-JSON exportieren. DE/EN nach Browsersprache. Eigenes Format (nicht kompatibel mit dem scrypt-Python-Tool). Keine Secrets eingebettet.",' . "\n";
    print $fp '  "mcpTools": [],' . "\n";
    print $fp '  "mcpServerNames": []' . "\n";
    print $fp '}' . "\n";
    print $fp '</script>' . "\n";

    # Write HTML start and head section
    print $fp '<html lang="de">' . "\n";
    print $fp '<head>' . "\n";
    print $fp '<meta charset="utf-8">' . "\n";
    print $fp '<meta name="viewport" content="width=device-width, initial-scale=1">' . "\n";
    print $fp '<title>Secret-Vault Public</title>' . "\n";
    print $fp '<style>' . "\n";
    print $fp ':root{ color-scheme:light; --ink:#1b1c1f; --muted:#6c6e75; --faint:#9a9ca3; --card:#fff; --line:#e9eaee; --accent:#5b5bd6; --accent2:#7c5cff; --ok:#22a06b; --err:#e0533d; --radius:16px; --shadow:0 1px 2px rgba(20,20,40,.04),0 6px 20px rgba(20,20,40,.06);}' . "\n";
    print $fp '*{box-sizing:border-box;}' . "\n";
    print $fp 'body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;color:var(--ink);min-height:100vh;background:radial-gradient(1100px 560px at 100% -10%,#e8ecff 0%,rgba(232,236,255,0) 55%),linear-gradient(180deg,#eef1f6,#f7f7f8 42%);background-attachment:fixed;}' . "\n";
    print $fp '.wrap{max-width:820px;margin:0 auto;padding:24px 18px 70px;}' . "\n";
    print $fp '.brand{display:flex;align-items:center;gap:12px;margin-bottom:4px;}' . "\n";
    print $fp '.mark{width:32px;height:32px;border-radius:9px;background:linear-gradient(135deg,var(--accent),var(--accent2));box-shadow:0 4px 12px rgba(91,91,214,.35);position:relative;flex:0 0 auto;}' . "\n";
    print $fp '.mark:after{content:"";position:absolute;inset:8px;border-radius:4px;border:2px solid rgba(255,255,255,.92);}' . "\n";
    print $fp 'h1{font-size:21px;margin:0;font-weight:700;}' . "\n";
    print $fp '.sub{color:var(--muted);font-size:13px;margin:2px 0 16px;}' . "\n";
    print $fp '.card{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);padding:16px;margin-bottom:14px;}' . "\n";
    print $fp '.card h2{font-size:14px;margin:0 0 10px;}' . "\n";
    print $fp 'label.lab{display:block;font-size:12px;font-weight:600;color:var(--muted);margin:8px 0 3px;}' . "\n";
    print $fp 'input,textarea{width:100%;font-size:13px;padding:8px 10px;border:1px solid var(--line);border-radius:9px;font-family:ui-monospace,Menlo,Consolas,monospace;background:#fff;}' . "\n";
    print $fp 'textarea{min-height:90px;white-space:pre;overflow:auto;}' . "\n";
    print $fp '.row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;}' . "\n";
    print $fp '.btn{font-size:13px;font-weight:600;padding:8px 14px;border:1px solid var(--line);border-radius:10px;background:#fff;cursor:pointer;box-shadow:var(--shadow);transition:transform .1s;}' . "\n";
    print $fp '.btn:hover{transform:translateY(-1px);}' . "\n";
    print $fp '.btn.primary{background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;border-color:transparent;}' . "\n";
    print $fp '.btn.sm{padding:5px 9px;font-size:12px;}' . "\n";
    print $fp '.msg{font-size:12px;margin-left:6px;}' . "\n";
    print $fp '.msg.ok{color:var(--ok);} .msg.err{color:var(--err);}' . "\n";
    print $fp '.prov{border:1px solid var(--line);border-radius:12px;padding:10px 12px;margin-bottom:10px;}' . "\n";
    print $fp '.prov h3{margin:0 0 6px;font-size:13.5px;display:flex;align-items:center;gap:8px;}' . "\n";
    print $fp '.kv{display:grid;grid-template-columns:180px 1fr auto;gap:6px;margin:4px 0;align-items:center;}' . "\n";
    print $fp '.kv input{font-size:12px;padding:5px 7px;}' . "\n";
    print $fp '.kv .k{color:var(--muted);font-weight:600;}' . "\n";
    print $fp '.muted{color:var(--faint);font-size:13px;}' . "\n";
    print $fp '.hide{display:none;}' . "\n";
    print $fp '.foot{color:var(--faint);font-size:11.5px;text-align:center;margin-top:18px;line-height:1.5;}' . "\n";
    print $fp 'a{color:var(--accent);}' . "\n";
    print $fp '</style>' . "\n";
    print $fp '</head>' . "\n";

    # Write body content
    print $fp '<body>' . "\n";
    print $fp '<div class="wrap">' . "\n";
    print $fp '  <div class="brand"><div class="mark"></div><h1 id="title">Secret-Vault Public</h1></div>' . "\n";
    print $fp '  <div class="sub" id="sub">Verschlüsselte Secret-Vault (AES-256-GCM, PBKDF2) — alles im Browser, kein Server.</div>' . "\n";

    # Card: Open or new
    print $fp '  <div class="card">' . "\n";
    print $fp '    <h2 id="h-open">Öffnen oder neu</h2>' . "\n";
    print $fp '    <label class="lab" id="l-pass">Passphrase</label>' . "\n";
    print $fp '    <input id="pass" type="password" placeholder="Passphrase…">' . "\n";
    print $fp '    <label class="lab" id="l-file">Vault laden (Datei oder Base64 einfügen)</label>' . "\n";
    print $fp '    <input id="file" type="file" accept=".svpb,.txt,.vault,.b64">' . "\n";
    print $fp '    <textarea id="blob" placeholder="…oder Base64 hier einfügen"></textarea>' . "\n";
    print $fp '    <div class="row" style="margin-top:10px">' . "\n";
    print $fp '      <button class="btn primary" id="openBtn">Öffnen / Entschlüsseln</button>' . "\n";
    print $fp '      <button class="btn" id="newBtn">Neuer leerer Vault</button>' . "\n";
    print $fp '      <span class="msg" id="openMsg"></span>' . "\n";
    print $fp '    </div>' . "\n";
    print $fp '  </div>' . "\n";

    # Card: Editor (hidden by default)
    print $fp '  <div class="card hide" id="editor">' . "\n";
    print $fp '    <h2 id="h-edit">Inhalt</h2>' . "\n";
    print $fp '    <div id="provs"></div>' . "\n";
    print $fp '    <div class="row" style="margin-top:8px">' . "\n";
    print $fp '      <input id="newProv" placeholder="Neuer Anbieter (Name)" style="max-width:280px">' . "\n";
    print $fp '      <button class="btn sm" id="addProvBtn">+ Anbieter</button>' . "\n";
    print $fp '    </div>' . "\n";
    print $fp '  </div>' . "\n";

    # Card: Save/Export (hidden by default)
    print $fp '  <div class="card hide" id="out">' . "\n";
    print $fp '    <h2 id="h-save">Speichern / Export</h2>' . "\n";
    print $fp '    <div class="row">' . "\n";
    print $fp '      <button class="btn primary" id="encBtn">Verschlüsseln</button>' . "\n";
    print $fp '      <button class="btn" id="dlBtn">Als .svpb herunterladen</button>' . "\n";
    print $fp '      <button class="btn" id="expBtn">Klartext-JSON exportieren</button>' . "\n";
    print $fp '      <span class="msg" id="saveMsg"></span>' . "\n";
    print $fp '    </div>' . "\n";
    print $fp '    <label class="lab" id="l-result">Ergebnis (zum Kopieren/Speichern)</label>' . "\n";
    print $fp '    <textarea id="result" readonly></textarea>' . "\n";
    print $fp '  </div>' . "\n";

    # Footer
    print $fp '  <div class="foot" id="foot"></div>' . "\n";
    print $fp '</div>' . "\n";

    # JavaScript section
    print $fp '<script>' . "\n";
    print $fp 'const L = ((navigator.language||"en").toLowerCase().startsWith("de"))?"de":"en";' . "\n";
    print $fp 'const T = {' . "\n";
    print $fp ' title:{de:"Secret-Vault Public",en:"Secret-Vault Public"},' . "\n";
    print $fp ' sub:{de:"Verschlüsselte Secret-Vault (AES-256-GCM, PBKDF2) — alles im Browser, kein Server.",en:"Encrypted secret vault (AES-256-GCM, PBKDF2) — fully in the browser, no server."},' . "\n";
    print $fp ' hOpen:{de:"Öffnen oder neu",en:"Open or new"},' . "\n";
    print $fp ' pass:{de:"Passphrase",en:"Passphrase"},' . "\n";
    print $fp ' file:{de:"Vault laden (Datei oder Base64 einfügen)",en:"Load vault (file or paste Base64)"},' . "\n";
    print $fp ' blob:{de:"…oder Base64 hier einfügen",en:"…or paste Base64 here"},' . "\n";
    print $fp ' open:{de:"Öffnen / Entschlüsseln",en:"Open / Decrypt"},' . "\n";
    print $fp ' neu:{de:"Neuer leerer Vault",en:"New empty vault"},' . "\n";
    print $fp ' hEdit:{de:"Inhalt",en:"Content"},' . "\n";
    print $fp ' newProv:{de:"Neuer Anbieter (Name)",en:"New provider (name)"},' . "\n";
    print $fp ' addProv:{de:"+ Anbieter",en:"+ Provider"},' . "\n";
    print $fp ' hSave:{de:"Speichern / Export",en:"Save / Export"},' . "\n";
    print $fp ' enc:{de:"Verschlüsseln",en:"Encrypt"},' . "\n";
    print $fp ' dl:{de:"Als .svpb herunterladen",en:"Download as .svpb"},' . "\n";
    print $fp ' exp:{de:"Klartext-JSON exportieren",en:"Export plaintext JSON"},' . "\n";
    print $fp ' result:{de:"Ergebnis (zum Kopieren/Speichern)",en:"Result (to copy/save)"},' . "\n";
    print $fp ' foot:{de:"Eigenes Format (PBKDF2). Nicht kompatibel mit dem scrypt-Python-Tool. Sicherheit liegt in der Passphrase; Inhalt ohne sie nicht wiederherstellbar.",en:"Own format (PBKDF2). Not compatible with the scrypt Python tool. Security rests on the passphrase; content is unrecoverable without it."},' . "\n";
    print $fp ' needPass:{de:"Passphrase eingeben.",en:"Enter a passphrase."},' . "\n";
    print $fp ' noInput:{de:"Datei laden oder Base64 einfügen.",en:"Load a file or paste Base64."},' . "\n";
    print $fp ' bad:{de:"Falsche Passphrase oder ungültiger Vault.",en:"Wrong passphrase or invalid vault."},' . "\n";
    print $fp ' opened:{de:"Geöffnet.",en:"Opened."},' . "\n";
    print $fp ' created:{de:"Neuer Vault angelegt.",en:"New vault created."},' . "\n";
    print $fp ' encrypted:{de:"Verschlüsselt — unten kopieren oder herunterladen.",en:"Encrypted — copy below or download."},' . "\n";
    print $fp ' needOpen:{de:"Erst öffnen/anlegen.",en:"Open/create first."},' . "\n";
    print $fp ' field:{de:"Feld",en:"field"}, value:{de:"Wert",en:"value"},' . "\n";
    print $fp ' addField:{de:"+ Feld",en:"+ field"}, del:{de:"✕",en:"✕"},' . "\n";
    print $fp ' newField:{de:"neues Feld",en:"new field"}, newValue:{de:"Wert",en:"value"}' . "\n";
    print $fp '};' . "\n";
    print $fp 'const tr=k=>T[k][L];' . "\n";
    print $fp '// apply static i18n' . "\n";
    print $fp 'title.textContent=tr("title"); sub.textContent=tr("sub"); document.title=tr("title");' . "\n";
    print $fp 'document.getElementById("h-open").textContent=tr("hOpen");' . "\n";
    print $fp 'document.getElementById("l-pass").textContent=tr("pass");' . "\n";
    print $fp 'document.getElementById("l-file").textContent=tr("file");' . "\n";
    print $fp 'blob.placeholder=tr("blob");' . "\n";
    print $fp 'openBtn.textContent=tr("open"); newBtn.textContent=tr("neu");' . "\n";
    print $fp 'document.getElementById("h-edit").textContent=tr("hEdit");' . "\n";
    print $fp 'newProv.placeholder=tr("newProv"); addProvBtn.textContent=tr("addProv");' . "\n";
    print $fp 'document.getElementById("h-save").textContent=tr("hSave");' . "\n";
    print $fp 'encBtn.textContent=tr("enc"); dlBtn.textContent=tr("dl"); expBtn.textContent=tr("exp");' . "\n";
    print $fp 'document.getElementById("l-result").textContent=tr("result");' . "\n";
    print $fp 'foot.textContent=tr("foot");' . "\n";
    print $fp '' . "\n";
    print $fp 'let VAULT=null; // {meta, providers:{}}' . "\n";
    print $fp '' . "\n";
    print $fp 'const enc=new TextEncoder(), dec=new TextDecoder();' . "\n";
    print $fp 'function u8b64(u8){ let s=""; for(let i=0;i<u8.length;i+=0x8000) s+=String.fromCharCode.apply(null,u8.subarray(i,i+0x8000)); return btoa(s); }' . "\n";
    print $fp 'function b64u8(b64){ const s=atob(b64.trim()); const u=new Uint8Array(s.length); for(let i=0;i<s.length;i++) u[i]=s.charCodeAt(i); return u; }' . "\n";
    print $fp 'async function deriveKey(pw,salt){' . "\n";
    print $fp '  const km=await crypto.subtle.importKey("raw",enc.encode(pw),"PBKDF2",false,["deriveKey"]);' . "\n";
    print $fp '  return crypto.subtle.deriveKey({name:"PBKDF2",salt,iterations:210000,hash:"SHA-256"},km,{name:"AES-GCM",length:256},false,["encrypt","decrypt"]);' . "\n";
    print $fp '}' . "\n";
    print $fp 'async function encryptObj(obj,pw){' . "\n";
    print $fp '  const salt=crypto.getRandomValues(new Uint8Array(16)), iv=crypto.getRandomValues(new Uint8Array(12));' . "\n";
    print $fp '  const key=await deriveKey(pw,salt);' . "\n";
    print $fp '  const ct=new Uint8Array(await crypto.subtle.encrypt({name:"AES-GCM",iv},key,enc.encode(JSON.stringify(obj,null,2))));' . "\n";
    print $fp '  const magic=enc.encode("SVPB1"); const out=new Uint8Array(5+16+12+ct.length);' . "\n";
    print $fp '  out.set(magic,0); out.set(salt,5); out.set(iv,21); out.set(ct,33); return u8b64(out);' . "\n";
    print $fp '}' . "\n";
    print $fp 'async function decryptB64(b64,pw){' . "\n";
    print $fp '  const raw=b64u8(b64); if(dec.decode(raw.slice(0,5))!=="SVPB1") throw new Error("magic");' . "\n";
    print $fp '  const key=await deriveKey(pw,raw.slice(5,21));' . "\n";
    print $fp '  const pt=await crypto.subtle.decrypt({name:"AES-GCM",iv:raw.slice(21,33)},key,raw.slice(33));' . "\n";
    print $fp '  return JSON.parse(dec.decode(pt));' . "\n";
    print $fp '}' . "\n";
    print $fp 'function esc(s){return (s==null?"":String(s)).replace(/[&<>"]/g,c=>({\'&\':\'&amp;\',\'<\':\'&lt;\',\'>\':\'&gt;\',\'"\':\'&quot;\'}[c]));}' . "\n";
    print $fp '' . "\n";
    print $fp 'function renderEditor(){' . "\n";
    print $fp '  document.getElementById("editor").classList.remove("hide");' . "\n";
    print $fp '  document.getElementById("out").classList.remove("hide");' . "\n";
    print $fp '  const P=VAULT.providers||{}; const root=document.getElementById("provs"); root.innerHTML="";' . "\n";
    print $fp '  Object.keys(P).forEach(name=>{' . "\n";
    print $fp '    const d=document.createElement("div"); d.className="prov";' . "\n";
    print $fp '    let rows="";' . "\n";
    print $fp '    Object.keys(P[name]).forEach(k=>{ rows+=`<div class="kv"><span class="k">${esc(k)}</span><input data-p="${esc(name)}" data-k="${esc(k)}" value="${esc(P[name][k])}"><button class="btn sm" data-del="${esc(name)}|${esc(k)}">${tr("del")}</button></div>`; });' . "\n";
    print $fp '    d.innerHTML=`<h3>${esc(name)} <button class="btn sm" data-delp="${esc(name)}">${tr("del")}</button></h3>${rows}' . "\n";
    print $fp '      <div class="row" style="margin-top:6px"><input class="nf" data-np="${esc(name)}" placeholder="${tr("newField")}" style="max-width:180px"><input class="nv" data-np="${esc(name)}" placeholder="${tr("newValue")}" style="max-width:260px"><button class="btn sm" data-addf="${esc(name)}">${tr("addField")}</button></div>`;' . "\n";
    print $fp '    root.appendChild(d);' . "\n";
    print $fp '  });' . "\n";
    print $fp '  root.querySelectorAll("input[data-k]").forEach(i=>i.onchange=()=>{ VAULT.providers[i.dataset.p][i.dataset.k]=i.value; });' . "\n";
    print $fp '  root.querySelectorAll("button[data-del]").forEach(b=>b.onclick=()=>{ const [p,k]=b.dataset.del.split("|"); delete VAULT.providers[p][k]; renderEditor(); });' . "\n";
    print $fp '  root.querySelectorAll("button[data-delp]").forEach(b=>b.onclick=()=>{ delete VAULT.providers[b.dataset.delp]; renderEditor(); });' . "\n";
    print $fp '  root.querySelectorAll("button[data-addf]").forEach(b=>b.onclick=()=>{ const p=b.dataset.addf; const nf=root.querySelector(`.nf[data-np="${CSS.escape(p)}"]`).value.trim(); const nv=root.querySelector(`.nv[data-np="${CSS.escape(p)}"]`).value; if(nf){ VAULT.providers[p][nf]=nv; renderEditor(); } });' . "\n";
    print $fp '}' . "\n";
    print $fp '' . "\n";
    print $fp 'document.getElementById("file").onchange=e=>{ const f=e.target.files[0]; if(!f)return; const r=new FileReader(); r.onload=()=>{ blob.value=r.result.trim(); }; r.readAsText(f); };' . "\n";
    print $fp 'openBtn.onclick=async()=>{' . "\n";
    print $fp '  const m=document.getElementById("openMsg"); m.className="msg"; m.textContent="";' . "\n";
    print $fp '  if(!pass.value){ m.className="msg err"; m.textContent=tr("needPass"); return; }' . "\n";
    print $fp '  if(!blob.value.trim()){ m.className="msg err"; m.textContent=tr("noInput"); return; }' . "\n";
    print $fp '  try{ VAULT=await decryptB64(blob.value,pass.value); if(!VAULT.providers)VAULT.providers={}; renderEditor(); m.className="msg ok"; m.textContent=tr("opened"); }' . "\n";
    print $fp '  catch(err){ m.className="msg err"; m.textContent=tr("bad"); }' . "\n";
    print $fp '};' . "\n";
    print $fp 'newBtn.onclick=()=>{' . "\n";
    print $fp '  const m=document.getElementById("openMsg");' . "\n";
    print $fp '  if(!pass.value){ m.className="msg err"; m.textContent=tr("needPass"); return; }' . "\n";
    print $fp '  VAULT={meta:{created:new Date().toISOString().slice(0,10),format:"SVPB1"},providers:{}}; renderEditor();' . "\n";
    print $fp '  m.className="msg ok"; m.textContent=tr("created");' . "\n";
    print $fp '};' . "\n";
    print $fp 'addProvBtn.onclick=()=>{ if(!VAULT){ return; } const n=newProv.value.trim(); if(n){ VAULT.providers[n]=VAULT.providers[n]||{}; newProv.value=""; renderEditor(); } };' . "\n";
    print $fp 'encBtn.onclick=async()=>{' . "\n";
    print $fp '  const m=document.getElementById("saveMsg"); m.className="msg";' . "\n";
    print $fp '  if(!VAULT){ m.className="msg err"; m.textContent=tr("needOpen"); return; }' . "\n";
    print $fp '  if(!pass.value){ m.className="msg err"; m.textContent=tr("needPass"); return; }' . "\n";
    print $fp '  result.value=await encryptObj(VAULT,pass.value); m.className="msg ok"; m.textContent=tr("encrypted");' . "\n";
    print $fp '};' . "\n";
    print $fp 'dlBtn.onclick=()=>{ if(!result.value)return; try{ const b=new Blob([result.value],{type:"text/plain"}); const u=URL.createObjectURL(b); const a=document.createElement("a"); a.href=u; a.download="vault.svpb"; document.body.appendChild(a); a.click(); a.remove(); setTimeout(()=>URL.revokeObjectURL(u),1500);}catch(e){} };' . "\n";
    print $fp 'expBtn.onclick=()=>{ if(!VAULT)return; result.value=JSON.stringify(VAULT,null,2); };' . "\n";
    print $fp '</script>' . "\n";
    print $fp '</body>' . "\n";
    print $fp '</html>' . "\n";

    close($fp);
    print "HTML file generated: $output_file\n";
}

main();
