#!/usr/bin/env node
// 1781743218784.tcl — portiert nach javascript
// Quelle: tcl, Projects@abstractions:tcl/1781743218784.tcl
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// 1781743218784.html — portiert nach tcl
// Quelle: html, Projects@secret-vault-public:secret-vault-public/versions/1781743218784.html
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// Tcl 8.6 script to generate the Secret Vault Public HTML file
// Usage: tclsh this_script.tcl output_file.html

if (process.argv.length !== 3) {
    console.log("Usage: node " + process.argv[1] + " output_file.html");
    process.exit(1);
}

const fs = require('fs');
const outputFile = process.argv[2];
const fd = fs.openSync(outputFile, 'w');

// Write DOCTYPE and main script tag
fs.writeSync(fd, "<!DOCTYPE html>\n");
fs.writeSync(fd, "<script type=\"application/json\" id=\"cowork-artifact-meta\">\n");
fs.writeSync(fd, "\n");
fs.writeSync(fd, "{\n");
fs.writeSync(fd, "  \"name\": \"Secret Vault Public\",\n");
fs.writeSync(fd, "  \"schemaVersion\": 1,\n");
fs.writeSync(fd, "  \"description\": \"Secret-Vault Public als interaktives Browser-Artefakt: verschlüsselter Secret-Container vollständig client-seitig (WebCrypto, AES-256-GCM + PBKDF2). Öffnen/Anlegen, Anbieter/Felder ergänzen und ersetzen (Rotation), verschlüsseln und als .svpb herunterladen oder Klartext-JSON exportieren. DE/EN nach Browsersprache. Eigenes Format (nicht kompatibel mit dem scrypt-Python-Tool). Keine Secrets eingebettet.\",\n");
fs.writeSync(fd, "  \"mcpTools\": [],\n");
fs.writeSync(fd, "  \"mcpServerNames\": []\n");
fs.writeSync(fd, "}\n");
fs.writeSync(fd, "\n");
fs.writeSync(fd, "</script>\n");

// Write HTML start and head section
fs.writeSync(fd, "<html lang=\"de\">\n");
fs.writeSync(fd, "<head>\n");
fs.writeSync(fd, "<meta charset=\"utf-8\">\n");
fs.writeSync(fd, "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
fs.writeSync(fd, "<title>Secret-Vault Public</title>\n");
fs.writeSync(fd, "<style>\n");
fs.writeSync(fd, ":root{ color-scheme:light; --ink:#1b1c1f; --muted:#6c6e75; --faint:#9a9ca3; --card:#fff; --line:#e9eaee; --accent:#5b5bd6; --accent2:#7c5cff; --ok:#22a06b; --err:#e0533d; --radius:16px; --shadow:0 1px 2px rgba(20,20,40,.04),0 6px 20px rgba(20,20,40,.06);}\n");
fs.writeSync(fd, "*{box-sizing:border-box;}\n");
fs.writeSync(fd, "body{margin:0;font-family:-apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,Helvetica,Arial,sans-serif;color:var(--ink);min-height:100vh;background:radial-gradient(1100px 560px at 100% -10%,#e8ecff 0%,rgba(232,236,255,0) 55%),linear-gradient(180deg,#eef1f6,#f7f7f8 42%);background-attachment:fixed;}\n");
fs.writeSync(fd, ".wrap{max-width:820px;margin:0 auto;padding:24px 18px 70px;}\n");
fs.writeSync(fd, ".brand{display:flex;align-items:center;gap:12px;margin-bottom:4px;}\n");
fs.writeSync(fd, ".mark{width:32px;height:32px;border-radius:9px;background:linear-gradient(135deg,var(--accent),var(--accent2));box-shadow:0 4px 12px rgba(91,91,214,.35);position:relative;flex:0 0 auto;}\n");
fs.writeSync(fd, ".mark:after{content:\"\";position:absolute;inset:8px;border-radius:4px;border:2px solid rgba(255,255,255,.92);}\n");
fs.writeSync(fd, "h1{font-size:21px;margin:0;font-weight:700;}\n");
fs.writeSync(fd, ".sub{color:var(--muted);font-size:13px;margin:2px 0 16px;}\n");
fs.writeSync(fd, ".card{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);padding:16px;margin-bottom:14px;}\n");
fs.writeSync(fd, ".card h2{font-size:14px;margin:0 0 10px;}\n");
fs.writeSync(fd, "label.lab{display:block;font-size:12px;font-weight:600;color:var(--muted);margin:8px 0 3px;}\n");
fs.writeSync(fd, "input,textarea{width:100%;font-size:13px;padding:8px 10px;border:1px solid var(--line);border-radius:9px;font-family:ui-monospace,Menlo,Consolas,monospace;background:#fff;}\n");
fs.writeSync(fd, "textarea{min-height:90px;white-space:pre;overflow:auto;}\n");
fs.writeSync(fd, ".row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;}\n");
fs.writeSync(fd, ".btn{font-size:13px;font-weight:600;padding:8px 14px;border:1px solid var(--line);border-radius:10px;background:#fff;cursor:pointer;box-shadow:var(--shadow);transition:transform .1s;}\n");
fs.writeSync(fd, ".btn:hover{transform:translateY(-1px);}\n");
fs.writeSync(fd, ".btn.primary{background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;border-color:transparent;}\n");
fs.writeSync(fd, ".btn.sm{padding:5px 9px;font-size:12px;}\n");
fs.writeSync(fd, ".msg{font-size:12px;margin-left:6px;}\n");
fs.writeSync(fd, ".msg.ok{color:var(--ok);} .msg.err{color:var(--err);}\n");
fs.writeSync(fd, ".prov{border:1px solid var(--line);border-radius:12px;padding:10px 12px;margin-bottom:10px;}\n");
fs.writeSync(fd, ".prov h3{margin:0 0 6px;font-size:13.5px;display:flex;align-items:center;gap:8px;}\n");
fs.writeSync(fd, ".kv{display:grid;grid-template-columns:180px 1fr auto;gap:6px;margin:4px 0;align-items:center;}\n");
fs.writeSync(fd, ".kv input{font-size:12px;padding:5px 7px;}\n");
fs.writeSync(fd, ".kv .k{color:var(--muted);font-weight:600;}\n");
fs.writeSync(fd, ".muted{color:var(--faint);font-size:13px;}\n");
fs.writeSync(fd, ".hide{display:none;}\n");
fs.writeSync(fd, ".foot{color:var(--faint);font-size:11.5px;text-align:center;margin-top:18px;line-height:1.5;}\n");
fs.writeSync(fd, "a{color:var(--accent);}\n");
fs.writeSync(fd, "</style>\n");
fs.writeSync(fd, "</head>\n");

// Write body content
fs.writeSync(fd, "<body>\n");
fs.writeSync(fd, "<div class=\"wrap\">\n");
fs.writeSync(fd, "  <div class=\"brand\"><div class=\"mark\"></div><h1 id=\"title\">Secret-Vault Public</h1></div>\n");
fs.writeSync(fd, "  <div class=\"sub\" id=\"sub\">Verschlüsselte Secret-Vault (AES-256-GCM, PBKDF2) — alles im Browser, kein Server.</div>\n");

// Card: Open or new
fs.writeSync(fd, "\n");
fs.writeSync(fd, "  <div class=\"card\">\n");
fs.writeSync(fd, "    <h2 id=\"h-open\">Öffnen oder neu</h2>\n");
fs.writeSync(fd, "    <label class=\"lab\" id=\"l-pass\">Passphrase</label>\n");
fs.writeSync(fd, "    <input id=\"pass\" type=\"password\" placeholder=\"Passphrase…\">\n");
fs.writeSync(fd, "    <label class=\"lab\" id=\"l-file\">Vault laden (Datei oder Base64 einfügen)</label>\n");
fs.writeSync(fd, "    <input id=\"file\" type=\"file\" accept=\".svpb,.txt,.vault,.b64\">\n");
fs.writeSync(fd, "    <textarea id=\"blob\" placeholder=\"…oder Base64 hier einfügen\"></textarea>\n");
fs.writeSync(fd, "    <div class=\"row\" style=\"margin-top:10px\">\n");
fs.writeSync(fd, "      <button class=\"btn primary\" id=\"openBtn\">Öffnen / Entschlüsseln</button>\n");
fs.writeSync(fd, "      <button class=\"btn\" id=\"newBtn\">Neuer leerer Vault</button>\n");
fs.writeSync(fd, "      <span class=\"msg\" id=\"openMsg\"></span>\n");
fs.writeSync(fd, "    </div>\n");
fs.writeSync(fd, "  </div>\n");
fs.writeSync(fd, "\n");

// Card: Editor (hidden by default)
fs.writeSync(fd, "  <div class=\"card hide\" id=\"editor\">\n");
fs.writeSync(fd, "    <h2 id=\"h-edit\">Inhalt</h2>\n");
fs.writeSync(fd, "    <div id=\"provs\"></div>\n");
fs.writeSync(fd, "    <div class=\"row\" style=\"margin-top:8px\">\n");
fs.writeSync(fd, "      <input id=\"newProv\" placeholder=\"Neuer Anbieter (Name)\" style=\"max-width:280px\">\n");
fs.writeSync(fd, "      <button class=\"btn sm\" id=\"addProvBtn\">+ Anbieter</button>\n");
fs.writeSync(fd, "    </div>\n");
fs.writeSync(fd, "  </div>\n");
fs.writeSync(fd, "\n");

// Card: Save/Export (hidden by default)
fs.writeSync(fd, "  <div class=\"card hide\" id=\"out\">\n");
fs.writeSync(fd, "    <h2 id=\"h-save\">Speichern / Export</h2>\n");
fs.writeSync(fd, "    <div class=\"row\">\n");
fs.writeSync(fd, "      <button class=\"btn primary\" id=\"encBtn\">Verschlüsseln</button>\n");
fs.writeSync(fd, "      <button class=\"btn\" id=\"dlBtn\">Als .svpb herunterladen</button>\n");
fs.writeSync(fd, "      <button class=\"btn\" id=\"expBtn\">Klartext-JSON exportieren</button>\n");
fs.writeSync(fd, "      <span class=\"msg\" id=\"saveMsg\"></span>\n");
fs.writeSync(fd, "    </div>\n");
fs.writeSync(fd, "    <label class=\"lab\" id=\"l-result\">Ergebnis (zum Kopieren/Speichern)</label>\n");
fs.writeSync(fd, "    <textarea id=\"result\" readonly></textarea>\n");
fs.writeSync(fd, "  </div>\n");
fs.writeSync(fd, "\n");

// Footer
fs.writeSync(fd, "  <div class=\"foot\" id=\"foot\"></div>\n");
fs.writeSync(fd, "</div>\n");

// JavaScript section
fs.writeSync(fd, "<script>\n");
fs.writeSync(fd, "\n");
fs.writeSync(fd, "const L = ((navigator.language||\"en\").toLowerCase().startsWith(\"de\"))?\"de\":\"en\";\n");
fs.writeSync(fd, "const T = {\n");
fs.writeSync(fd, " title:{de:\"Secret-Vault Public\",en:\"Secret-Vault Public\"},\n");
fs.writeSync(fd, " sub:{de:\"Verschlüsselte Secret-Vault (AES-256-GCM, PBKDF2) — alles im Browser, kein Server.\",en:\"Encrypted secret vault (AES-256-GCM, PBKDF2) — fully in the browser, no server.\"},\n");
fs.writeSync(fd, " hOpen:{de:\"Öffnen oder neu\",en:\"Open or new\"},\n");
fs.writeSync(fd, " pass:{de:\"Passphrase\",en:\"Passphrase\"},\n");
fs.writeSync(fd, " file:{de:\"Vault laden (Datei oder Base64 einfügen)\",en:\"Load vault (file or paste Base64)\"},\n");
fs.writeSync(fd, " blob:{de:\"…oder Base64 hier einfügen\",en:\"…or paste Base64 here\"},\n");
fs.writeSync(fd, " open:{de:\"Öffnen / Entschlüsseln\",en:\"Open / Decrypt\"},\n");
fs.writeSync(fd, " neu:{de:\"Neuer leerer Vault\",en:\"New empty vault\"},\n");
fs.writeSync(fd, " hEdit:{de:\"Inhalt\",en:\"Content\"},\n");
fs.writeSync(fd, " newProv:{de:\"Neuer Anbieter (Name)\",en:\"New provider (name)\"},\n");
fs.writeSync(fd, " addProv:{de:\"+ Anbieter\",en:\"+ Provider\"},\n");
fs.writeSync(fd, " hSave:{de:\"Speichern / Export\",en:\"Save / Export\"},\n");
fs.writeSync(fd, " enc:{de:\"Verschlüsseln\",en:\"Encrypt\"},\n");
fs.writeSync(fd, " dl:{de:\"Als .svpb herunterladen\",en:\"Download as .svpb\"},\n");
fs.writeSync(fd, " exp:{de:\"Klartext-JSON exportieren\",en:\"Export plaintext JSON\"},\n");
fs.writeSync(fd, " result:{de:\"Ergebnis (zum Kopieren/Speichern)\",en:\"Result (to copy/save)\"},\n");
fs.writeSync(fd, " foot:{de:\"Eigenes Format (PBKDF2). Nicht kompatibel mit dem scrypt-Python-Tool. Sicherheit liegt in der Passphrase; Inhalt ohne sie nicht wiederherstellbar.\",en:\"Own format (PBKDF2). Not compatible with the scrypt Python tool. Security rests on the passphrase; content is unrecoverable without it.\"},\n");
fs.writeSync(fd, " needPass:{de:\"Passphrase eingeben.\",en:\"Enter a passphrase.\"},\n");
fs.writeSync(fd, " noInput:{de:\"Datei laden oder Base64 einfügen.\",en:\"Load a file or paste Base64.\"},\n");
fs.writeSync(fd, " bad:{de:\"Falsche Passphrase oder ungültiger Vault.\",en:\"Wrong passphrase or invalid vault.\"},\n");
fs.writeSync(fd, " opened:{de:\"Geöffnet.\",en:\"Opened.\"},\n");
fs.writeSync(fd, " created:{de:\"Neuer Vault angelegt.\",en:\"New vault created.\"},\n");
fs.writeSync(fd, " encrypted:{de:\"Verschlüsselt — unten kopieren oder herunterladen.\",en:\"Encrypted — copy below or download.\"},\n");
fs.writeSync(fd, " needOpen:{de:\"Erst öffnen/anlegen.\",en:\"Open/create first.\"},\n");
fs.writeSync(fd, " field:{de:\"Feld\",en:\"field\"}, value:{de:\"Wert\",en:\"value\"},\n");
fs.writeSync(fd, " addField:{de:\"+ Feld\",en:\"+ field\"}, del:{de:\"✕\",en:\"✕\"},\n");
fs.writeSync(fd, " newField:{de:\"neues Feld\",en:\"new field\"}, newValue:{de:\"Wert\",en:\"value\"}\n");
fs.writeSync(fd, "};\n");
fs.writeSync(fd, "const tr=k=>T[k][L];\n");
fs.writeSync(fd, "// apply static i18n\n");
fs.writeSync(fd, "title.textContent=tr(\"title\"); sub.textContent=tr(\"sub\"); document.title=tr(\"title\");\n");
fs.writeSync(fd, "document.getElementById(\"h-open\").textContent=tr(\"hOpen\");\n");
fs.writeSync(fd, "document.getElementById(\"l-pass\").textContent=tr(\"pass\");\n");
fs.writeSync(fd, "document.getElementById(\"l-file\").textContent=tr(\"file\");\n");
fs.writeSync(fd, "blob.placeholder=tr(\"blob\");\n");
fs.writeSync(fd, "openBtn.textContent=tr(\"open\"); newBtn.textContent=tr(\"neu\");\n");
fs.writeSync(fd, "document.getElementById(\"h-edit\").textContent=tr(\"hEdit\");\n");
fs.writeSync(fd, "newProv.placeholder=tr(\"newProv\"); addProvBtn.textContent=tr(\"addProv\");\n");
fs.writeSync(fd, "document.getElementById(\"h-save\").textContent=tr(\"hSave\");\n");
fs.writeSync(fd, "encBtn.textContent=tr(\"enc\"); dlBtn.textContent=tr(\"dl\"); expBtn.textContent=tr(\"exp\");\n");
fs.writeSync(fd, "document.getElementById(\"l-result\").textContent=tr(\"result\");\n");
fs.writeSync(fd, "foot.textContent=tr(\"foot\");\n");
fs.writeSync(fd, "\n");
fs.writeSync(fd, "let VAULT=null; // {meta, providers:{}}\n");
fs.writeSync(fd, "\n");
fs.writeSync(fd, "const enc=new TextEncoder(), dec=new TextDecoder();\n");
fs.writeSync(fd, "function u8b64(u8){ let s=\"\"; for(let i=0;i<u8.length;i+=0x8000) s+=String.fromCharCode.apply(null,u8.subarray(i,i+0x8000)); return btoa(s); }\n");
fs.writeSync(fd, "function b64u8(b64){ const s=atob(b64.trim()); const u=new Uint8Array(s.length); for(let i=0;i<s.length;i++) u[i]=s.charCodeAt(i); return u; }\n");
fs.writeSync(fd, "async function deriveKey(pw,salt){\n");
fs.writeSync(fd, "  const km=await crypto.subtle.importKey(\"raw\",enc.encode(pw),\"PBKDF2\",false,[\"deriveKey\"]);\n");
fs.writeSync(fd, "  return crypto.subtle.deriveKey({name:\"PBKDF2\",salt,iterations:210000,hash:\"SHA-256\"},km,{name:\"AES-GCM\",length:256},false,[\"encrypt\",\"decrypt\"]);\n");
fs.writeSync(fd, "}\n");
fs.writeSync(fd, "async function encryptObj(obj,pw){\n");
fs.writeSync(fd, "  const salt=crypto.getRandomValues(new Uint8Array(16)), iv=crypto.getRandomValues(new Uint8Array(12));\n");
fs.writeSync(fd, "  const key=await deriveKey(pw,salt);\n");
fs.writeSync(fd, "  const ct=new Uint8Array(await crypto.subtle.encrypt({name:\"AES-GCM\",iv},key,enc.encode(JSON.stringify(obj,null,2))));\n");
fs.writeSync(fd, "  const magic=enc.encode(\"SVPB1\"); const out=new Uint8Array(5+16+12+ct.length);\n");
fs.writeSync(fd, "  out.set(magic,0); out.set(salt,5); out.set(iv,21); out.set(ct,33); return u8b64(out);\n");
fs.writeSync(fd, "}\n");
fs.writeSync(fd, "async function decryptB64(b64,pw){\n");
fs.writeSync(fd, "  const raw=b64u8(b64); if(dec.decode(raw.slice(0,5))!==\"SVPB1\") throw new Error(\"magic\");\n");
fs.writeSync(fd, "  const key=await deriveKey(pw,raw.slice(5,21));\n");
fs.writeSync(fd, "  const pt=await crypto.subtle.decrypt({name:\"AES-GCM\",iv:raw.slice(21,33)},key,raw.slice(33));\n");
fs.writeSync(fd, "  return JSON.parse(dec.decode(pt));\n");
fs.writeSync(fd, "}\n");
fs.writeSync(fd, "function esc(s){return (s==null?\"\":String(s)).replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));}\n");
fs.writeSync(fd, "\n");
fs.writeSync(fd, "function renderEditor(){\n");
fs.writeSync(fd, "  document.getElementById(\"editor\").classList.remove(\"hide\");\n");
fs.writeSync(fd, "  document.getElementById(\"out\").classList.remove(\"hide\");\n");
fs.writeSync(fd, "  const P=VAULT.providers||{}; const root=document.getElementById(\"provs\"); root.innerHTML=\"\";\n");
fs.writeSync(fd, "  Object.keys(P).forEach(name=>{\n");
fs.writeSync(fd, "    const d=document.createElement(\"div\"); d.className=\"prov\";\n");
fs.writeSync(fd, "    let rows=\"\";\n");
fs.writeSync(fd, "    Object.keys(P[name]).forEach(k=>{ rows+=`<div class=\"kv\"><span class=\"k\">${esc(k)}</span><input data-p=\"${esc(name)}\" data-k=\"${esc(k)}\" value=\"${esc(P[name][k])}\"><button class=\"btn sm\" data-del=\"${esc(name)}|${esc(k)}\">${tr(\"del\")}</button></div>`; });\n");
fs.writeSync(fd, "    d.innerHTML=`<h3>${esc(name)} <button class=\"btn sm\" data-delp=\"${esc(name)}\">${tr(\"del\")}</button></h3>${rows}\n");
fs.writeSync(fd, "      <div class=\"row\" style=\"margin-top:6px\"><input class=\"nf\" data-np=\"${esc(name)}\" placeholder=\"${tr(\"newField\")}\" style=\"max-width:180px\"><input class=\"nv\" data-np=\"${esc(name)}\" placeholder=\"${tr(\"newValue\")}\" style=\"max-width:260px\"><button class=\"btn sm\" data-addf=\"${esc(name)}\">${tr(\"addField\")}</button></div>`;\n");
fs.writeSync(fd, "    root.appendChild(d);\n");
fs.writeSync(fd, "  });\n");
fs.writeSync(fd, "  root.querySelectorAll(\"input[data-k]\").forEach(i=>i.onchange=()=>{ VAULT.providers[i.dataset.p][i.dataset.k]=i.value; });\n");
fs.writeSync(fd, "  root.querySelectorAll(\"button[data-del]\").forEach(b=>b.onclick=()=>{ const [p,k]=b.dataset.del.split(\"|\"); delete VAULT.providers[p][k]; renderEditor(); });\n");
fs.writeSync(fd, "  root.querySelectorAll(\"button[data-delp]\").forEach(b=>b.onclick=()=>{ delete VAULT.providers[b.dataset.delp]; renderEditor(); });\n");
fs.writeSync(fd, "  root.querySelectorAll(\"button[data-addf]\").forEach(b=>b.onclick=()=>{ const p=b.dataset.addf; const nf=root.querySelector(`.nf[data-np=\"${CSS.escape(p)}\"]`).value.trim(); const nv=root.querySelector(`.nv[data-np=\"${CSS.escape(p)}\"]`).value; if(nf){ VAULT.providers[p][nf]=nv; renderEditor(); } });\n");
fs.writeSync(fd, "}\n");
fs.writeSync(fd, "\n");
fs.writeSync(fd, "document.getElementById(\"file\").onchange=e=>{ const f=e.target.files[0]; if(!f)return; const r=new FileReader(); r.onload=()=>{ blob.value=r.result.trim(); }; r.readAsText(f); };\n");
fs.writeSync(fd, "openBtn.onclick=async()=>{\n");
fs.writeSync(fd, "  const m=document.getElementById(\"openMsg\"); m.className=\"msg\"; m.textContent=\"\";\n");
fs.writeSync(fd, "  if(!pass.value){ m.className=\"msg err\"; m.textContent=tr(\"needPass\"); return; }\n");
fs.writeSync(fd, "  if(!blob.value.trim()){ m.className=\"msg err\"; m.textContent=tr(\"noInput\"); return; }\n");
fs.writeSync(fd, "  try{ VAULT=await decryptB64(blob.value,pass.value); if(!VAULT.providers)VAULT.providers={}; renderEditor(); m.className=\"msg ok\"; m.textContent=tr(\"opened\"); }\n");
fs.writeSync(fd, "  catch(err){ m.className=\"msg err\"; m.textContent=tr(\"bad\"); }\n");
fs.writeSync(fd, "};\n");
fs.writeSync(fd, "newBtn.onclick=()=>{\n");
fs.writeSync(fd, "  const m=document.getElementById(\"openMsg\");\n");
fs.writeSync(fd, "  if(!pass.value){ m.className=\"msg err\"; m.textContent=tr(\"needPass\"); return; }\n");
fs.writeSync(fd, "  VAULT={meta:{created:new Date().toISOString().slice(0,10),format:\"SVPB1\"},providers:{}}; renderEditor();\n");
fs.writeSync(fd, "  m.className=\"msg ok\"; m.textContent=tr(\"created\");\n");
fs.writeSync(fd, "};\n");
fs.writeSync(fd, "addProvBtn.onclick=()=>{ if(!VAULT){ return; } const n=newProv.value.trim(); if(n){ VAULT.providers[n]=VAULT.providers[n]||{}; newProv.value=\"\"; renderEditor(); } };\n");
fs.writeSync(fd, "encBtn.onclick=async()=>{\n");
fs.writeSync(fd, "  const m=document.getElementById(\"saveMsg\"); m.className=\"msg\";\n");
fs.writeSync(fd, "  if(!VAULT){ m.className=\"msg err\"; m.textContent=tr(\"needOpen\"); return; }\n");
fs.writeSync(fd, "  if(!pass.value){ m.className=\"msg err\"; m.textContent=tr(\"needPass\"); return; }\n");
fs.writeSync(fd, "  result.value=await encryptObj(VAULT,pass.value); m.className=\"msg ok\"; m.textContent=tr(\"encrypted\");\n");
fs.writeSync(fd, "};\n");
fs.writeSync(fd, "dlBtn.onclick=()=>{ if(!result.value)return; try{ const b=new Blob([result.value],{type:\"text/plain\"}); const u=URL.createObjectURL(b); const a=document.createElement(\"a\"); a.href=u; a.download=\"vault.svpb\"; document.body.appendChild(a); a.click(); a.remove(); setTimeout(()=>URL.revokeObjectURL(u),1500);}catch(e){} };\n");
fs.writeSync(fd, "expBtn.onclick=()=>{ if(!VAULT)return; result.value=JSON.stringify(VAULT,null,2); };\n");
fs.writeSync(fd, "\n");
fs.writeSync(fd, "</script>\n");
fs.writeSync(fd, "</body>\n");
fs.writeSync(fd, "</html>\n");

fs.closeSync(fd);

console.log("HTML file generated: " + outputFile);
