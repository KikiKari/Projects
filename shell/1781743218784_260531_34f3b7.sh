#!/usr/bin/env bash
# 1781743218784_260531.pl — portiert nach shell
# Quelle: perl5, Projects@abstractions:perl5/1781743218784_260531.pl
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# 1781743218784_260531.ps1 — portiert nach perl5
# Quelle: powershell, Projects@abstractions:powershell/1781743218784_260531.ps1
# Erzeugt: 2026-08-21 durch ABSTRACTIONS_MANAGER.py

# 1781743218784_260531.js — portiert nach powershell
# Quelle: javascript, Projects@abstractions:javascript/1781743218784_260531.js
# Erzeugt: 2026-08-18 durch ABSTRACTIONS_MANAGER.py

# 1781743218784.tcl — portiert nach javascript
# Quelle: tcl, Projects@abstractions:tcl/1781743218784.tcl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# 1781743218784.html — portiert nach tcl
# Quelle: html, Projects@secret-vault-public:secret-vault-public/versions/1781743218784.html
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 script to generate the Secret Vault Public HTML file
# Usage: tclsh this_script.tcl output_file.html

output_file="${1:-}"

if [[ -z "$output_file" ]]; then
    echo "Usage: bash this_script.sh output_file.html" >&2
    exit 1
fi

{
    # Write DOCTYPE and main script tag
    echo "<!DOCTYPE html>"
    echo "<script type=\"application/json\" id=\"cowork-artifact-meta\">"
    echo
    echo "{"
    echo "  \"name\": \"Secret Vault Public\","
    echo "  \"schemaVersion\": 1,"
    echo "  \"description\": \"Secret-Vault Public als interaktives Browser-Artefakt: verschlüsselter Secret-Container vollständig client-seitig (WebCrypto, AES-256-GCM + PBKDF2). Öffnen/Anlegen, Anbieter/Felder ergänzen und ersetzen (Rotation), verschlüsseln und als .svpb herunterladen oder Klartext-JSON exportieren. DE/EN nach Browsersprache. Eigenes Format (nicht kompatibel mit dem scrypt-Python-Tool). Keine Secrets eingebettet.\","
    echo "  \"mcpTools\": [],"
    echo "  \"mcpServerNames\": []"
    echo "}"
    echo
    echo "</script>"

    # Write HTML start and head section
    echo "<html lang=\"de\">"
    echo "<head>"
    echo "<meta charset=\"utf-8\">"
    echo "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
    echo "<title>Secret-Vault Public</title>"
    echo "<style>"
    echo ":root{ color-scheme:light; --ink:#1b1c1f; --muted:#6c6e75; --faint:#9a9ca3; --card:#fff; --line:#e9eaee; --accent:#5b5bd6; --accent2:#7c5cff; --ok:#22a06b; --err:#e0533d; --radius:16px; --shadow:0 1px 2px rgba(20,20,40,.04),0 6px 20px rgba(20,20,40,.06);}"
    echo "*{box-sizing:border-box;}"
    echo "body{margin:0;font-family:-apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,Helvetica,Arial,sans-serif;color:var(--ink);min-height:100vh;background:radial-gradient(1100px 560px at 100% -10%,#e8ecff 0%,rgba(232,236,255,0) 55%),linear-gradient(180deg,#eef1f6,#f7f7f8 42%);background-attachment:fixed;}"
    echo ".wrap{max-width:820px;margin:0 auto;padding:24px 18px 70px;}"
    echo ".brand{display:flex;align-items:center;gap:12px;margin-bottom:4px;}"
    echo ".mark{width:32px;height:32px;border-radius:9px;background:linear-gradient(135deg,var(--accent),var(--accent2));box-shadow:0 4px 12px rgba(91,91,214,.35);position:relative;flex:0 0 auto;}"
    echo ".mark:after{content:\"\";position:absolute;inset:8px;border-radius:4px;border:2px solid rgba(255,255,255,.92);}"
    echo "h1{font-size:21px;margin:0;font-weight:700;}"
    echo ".sub{color:var(--muted);font-size:13px;margin:2px 0 16px;}"
    echo ".card{background:var(--card);border:1px solid var(--line);border-radius:var(--radius);box-shadow:var(--shadow);padding:16px;margin-bottom:14px;}"
    echo ".card h2{font-size:14px;margin:0 0 10px;}"
    echo "label.lab{display:block;font-size:12px;font-weight:600;color:var(--muted);margin:8px 0 3px;}"
    echo "input,textarea{width:100%;font-size:13px;padding:8px 10px;border:1px solid var(--line);border-radius:9px;font-family:ui-monospace,Menlo,Consolas,monospace;background:#fff;}"
    echo "textarea{min-height:90px;white-space:pre;overflow:auto;}"
    echo ".row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;}"
    echo ".btn{font-size:13px;font-weight:600;padding:8px 14px;border:1px solid var(--line);border-radius:10px;background:#fff;cursor:pointer;box-shadow:var(--shadow);transition:transform .1s;}"
    echo ".btn:hover{transform:translateY(-1px);}"
    echo ".btn.primary{background:linear-gradient(135deg,var(--accent),var(--accent2));color:#fff;border-color:transparent;}"
    echo ".btn.sm{padding:5px 9px;font-size:12px;}"
    echo ".msg{font-size:12px;margin-left:6px;}"
    echo ".msg.ok{color:var(--ok);} .msg.err{color:var(--err);}"
    echo ".prov{border:1px solid var(--line);border-radius:12px;padding:10px 12px;margin-bottom:10px;}"
    echo ".prov h3{margin:0 0 6px;font-size:13.5px;display:flex;align-items:center;gap:8px;}"
    echo ".kv{display:grid;grid-template-columns:180px 1fr auto;gap:6px;margin:4px 0;align-items:center;}"
    echo ".kv input{font-size:12px;padding:5px 7px;}"
    echo ".kv .k{color:var(--muted);font-weight:600;}"
    echo ".muted{color:var(--faint);font-size:13px;}"
    echo ".hide{display:none;}"
    echo ".foot{color:var(--faint);font-size:11.5px;text-align:center;margin-top:18px;line-height:1.5;}"
    echo "a{color:var(--accent);}"
    echo "</style>"
    echo "</head>"

    # Write body content
    echo "<body>"
    echo "<div class=\"wrap\">"
    echo "  <div class=\"brand\"><div class=\"mark\"></div><h1 id=\"title\">Secret-Vault Public</h1></div>"
    echo "  <div class=\"sub\" id=\"sub\">Verschlüsselte Secret-Vault (AES-256-GCM, PBKDF2) — alles im Browser, kein Server.</div>"

    # Card: Open or new
    echo
    echo "  <div class=\"card\">"
    echo "    <h2 id=\"h-open\">Öffnen oder neu</h2>"
    echo "    <label class=\"lab\" id=\"l-pass\">Passphrase</label>"
    echo "    <input id=\"pass\" type=\"password\" placeholder=\"Passphrase…\">"
    echo "    <label class=\"lab\" id=\"l-file\">Vault laden (Datei oder Base64 einfügen)</label>"
    echo "    <input id=\"file\" type=\"file\" accept=\".svpb,.txt,.vault,.b64\">"
    echo "    <textarea id=\"blob\" placeholder=\"…oder Base64 hier einfügen\"></textarea>"
    echo "    <div class=\"row\" style=\"margin-top:10px\">"
    echo "      <button class=\"btn primary\" id=\"openBtn\">Öffnen / Entschlüsseln</button>"
    echo "      <button class=\"btn\" id=\"newBtn\">Neuer leerer Vault</button>"
    echo "      <span class=\"msg\" id=\"openMsg\"></span>"
    echo "    </div>"
    echo "  </div>"
    echo

    # Card: Editor (hidden by default)
    echo "  <div class=\"card hide\" id=\"editor\">"
    echo "    <h2 id=\"h-edit\">Inhalt</h2>"
    echo "    <div id=\"provs\"></div>"
    echo "    <div class=\"row\" style=\"margin-top:8px\">"
    echo "      <input id=\"newProv\" placeholder=\"Neuer Anbieter (Name)\" style=\"max-width:280px\">"
    echo "      <button class=\"btn sm\" id=\"addProvBtn\">+ Anbieter</button>"
    echo "    </div>"
    echo "  </div>"
    echo

    # Card: Save/Export (hidden by default)
    echo "  <div class=\"card hide\" id=\"out\">"
    echo "    <h2 id=\"h-save\">Speichern / Export</h2>"
    echo "    <div class=\"row\">"
    echo "      <button class=\"btn primary\" id=\"encBtn\">Verschlüsseln</button>"
    echo "      <button class=\"btn\" id=\"dlBtn\">Als .svpb herunterladen</button>"
    echo "      <button class=\"btn\" id=\"expBtn\">Klartext-JSON exportieren</button>"
    echo "      <span class=\"msg\" id=\"saveMsg\"></span>"
    echo "    </div>"
    echo "    <label class=\"lab\" id=\"l-result\">Ergebnis (zum Kopieren/Speichern)</label>"
    echo "    <textarea id=\"result\" readonly></textarea>"
    echo "  </div>"
    echo

    # Footer
    echo "  <div class=\"foot\" id=\"foot\"></div>"
    echo "</div>"

    # JavaScript section
    echo "<script>"
    echo
    echo "const L = ((navigator.language||\"en\").toLowerCase().startsWith(\"de\"))?\"de\":\"en\";"
    echo "const T = {"
    echo " title:{de:\"Secret-Vault Public\",en:\"Secret-Vault Public\"},"
    echo " sub:{de:\"Verschlüsselte Secret-Vault (AES-256-GCM, PBKDF2) — alles im Browser, kein Server.\",en:\"Encrypted secret vault (AES-256-GCM, PBKDF2) — fully in the browser, no server.\"},"
    echo " hOpen:{de:\"Öffnen oder neu\",en:\"Open or new\"},"
    echo " pass:{de:\"Passphrase\",en:\"Passphrase\"},"
    echo " file:{de:\"Vault laden (Datei oder Base64 einfügen)\",en:\"Load vault (file or paste Base64)\"},"
    echo " blob:{de:\"…oder Base64 hier einfügen\",en:\"…or paste Base64 here\"},"
    echo " open:{de:\"Öffnen / Entschlüsseln\",en:\"Open / Decrypt\"},"
    echo " neu:{de:\"Neuer leerer Vault\",en:\"New empty vault\"},"
    echo " hEdit:{de:\"Inhalt\",en:\"Content\"},"
    echo " newProv:{de:\"Neuer Anbieter (Name)\",en:\"New provider (name)\"},"
    echo " addProv:{de:\"+ Anbieter\",en:\"+ Provider\"},"
    echo " hSave:{de:\"Speichern / Export\",en:\"Save / Export\"},"
    echo " enc:{de:\"Verschlüsseln\",en:\"Encrypt\"},"
    echo " dl:{de:\"Als .svpb herunterladen\",en:\"Download as .svpb\"},"
    echo " exp:{de:\"Klartext-JSON exportieren\",en:\"Export plaintext JSON\"},"
    echo " result:{de:\"Ergebnis (zum Kopieren/Speichern)\",en:\"Result (to copy/save)\"},"
    echo " foot:{de:\"Eigenes Format (PBKDF2). Nicht kompatibel mit dem scrypt-Python-Tool. Sicherheit liegt in der Passphrase; Inhalt ohne sie nicht wiederherstellbar.\",en:\"Own format (PBKDF2). Not compatible with the scrypt Python tool. Security rests on the passphrase; content is unrecoverable without it.\"},"
    echo " needPass:{de:\"Passphrase eingeben.\",en:\"Enter a passphrase.\"},"
    echo " noInput:{de:\"Datei laden oder Base64 einfügen.\",en:\"Load a file or paste Base64.\"},"
    echo " bad:{de:\"Falsche Passphrase oder ungültiger Vault.\",en:\"Wrong passphrase or invalid vault.\"},"
    echo " opened:{de:\"Geöffnet.\",en:\"Opened.\"},"
    echo " created:{de:\"Neuer Vault angelegt.\",en:\"New vault created.\"},"
    echo " encrypted:{de:\"Verschlüsselt — unten kopieren oder herunterladen.\",en:\"Encrypted — copy below or download.\"},"
    echo " needOpen:{de:\"Erst öffnen/anlegen.\",en:\"Open/create first.\"},"
    echo " field:{de:\"Feld\",en:\"field\"}, value:{de:\"Wert\",en:\"value\"},"
    echo " addField:{de:\"+ Feld\",en:\"+ field\"}, del:{de:\"✕\",en:\"✕\"},"
    echo " newField:{de:\"neues Feld\",en:\"new field\"}, newValue:{de:\"Wert\",en:\"value\"}"
    echo "};"
    echo "const tr=k=>T[k][L];"
    echo "// apply static i18n"
    echo "title.textContent=tr(\"title\"); sub.textContent=tr(\"sub\"); document.title=tr(\"title\");"
    echo "document.getElementById(\"h-open\").textContent=tr(\"hOpen\");"
    echo "document.getElementById(\"l-pass\").textContent=tr(\"pass\");"
    echo "document.getElementById(\"l-file\").textContent=tr(\"file\");"
    echo "blob.placeholder=tr(\"blob\");"
    echo "openBtn.textContent=tr(\"open\"); newBtn.textContent=tr(\"neu\");"
    echo "document.getElementById(\"h-edit\").textContent=tr(\"hEdit\");"
    echo "newProv.placeholder=tr(\"newProv\"); addProvBtn.textContent=tr(\"addProv\");"
    echo "document.getElementById(\"h-save\").textContent=tr(\"hSave\");"
    echo "encBtn.textContent=tr(\"enc\"); dlBtn.textContent=tr(\"dl\"); expBtn.textContent=tr(\"exp\");"
    echo "document.getElementById(\"l-result\").textContent=tr(\"result\");"
    echo "foot.textContent=tr(\"foot\");"
    echo
    echo "let VAULT=null; // {meta, providers:{}}"
    echo
    echo "const enc=new TextEncoder(), dec=new TextDecoder();"
    echo "function u8b64(u8){ let s=\"\"; for(let i=0;i<u8.length;i+=0x8000) s+=String.fromCharCode.apply(null,u8.subarray(i,i+0x8000)); return btoa(s); }"
    echo "function b64u8(b64){ const s=atob(b64.trim()); const u=new Uint8Array(s.length); for(let i=0;i<s.length;i++) u[i]=s.charCodeAt(i); return u; }"
    echo "async function deriveKey(pw,salt){"
    echo "  const km=await crypto.subtle.importKey(\"raw\",enc.encode(pw),\"PBKDF2\",false,[\"deriveKey\"]);"
    echo "  return crypto.subtle.deriveKey({name:\"PBKDF2\",salt,iterations:210000,hash:\"SHA-256\"},km,{name:\"AES-GCM\",length:256},false,[\"encrypt\",\"decrypt\"]);"
    echo "}"
    echo "async function encryptObj(obj,pw){"
    echo "  const salt=crypto.getRandomValues(new Uint8Array(16)), iv=crypto.getRandomValues(new Uint8Array(12));"
    echo "  const key=await deriveKey(pw,salt);"
    echo "  const ct=new Uint8Array(await crypto.subtle.encrypt({name:\"AES-GCM\",iv},key,enc.encode(JSON.stringify(obj,null,2))));"
    echo "  const magic=enc.encode(\"SVPB1\"); const out=new Uint8Array(5+16+12+ct.length);"
    echo "  out.set(magic,0); out.set(salt,5); out.set(iv,21); out.set(ct,33); return u8b64(out);"
    echo "}"
    echo "async function decryptB64(b64,pw){"
    echo "  const raw=b64u8(b64); if(dec.decode(raw.slice(0,5))!==\"SVPB1\") throw new Error(\"magic\");"
    echo "  const key=await deriveKey(pw,raw.slice(5,21));"
    echo "  const pt=await crypto.subtle.decrypt({name:\"AES-GCM\",iv:raw.slice(21,33)},key,raw.slice(33));"
    echo "  return JSON.parse(dec.decode(pt));"
    echo "}"
    echo "function esc(s){return (s==null?\"\":String(s)).replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}[c]));}"
    echo
    echo "function renderEditor(){"
    echo "  document.getElementById(\"editor\").classList.remove(\"hide\");"
    echo "  document.getElementById(\"out\").classList.remove(\"hide\");"
    echo "  const P=VAULT.providers||{}; const root=document.getElementById(\"provs\"); root.innerHTML=\"\";"
    echo "  Object.keys(P).forEach(name=>{"
    echo "    const d=document.createElement(\"div\"); d.className=\"prov\";"
    echo "    let rows=\"\";"
    echo "    Object.keys(P[name]).forEach(k=>{ rows+=\`<div class=\"kv\"><span class=\"k\">\${esc(k)}</span><input data-p=\"\${esc(name)}\" data-k=\"\${esc(k)}\" value=\"\${esc(P[name][k])}\"><button class=\"btn sm\" data-del=\"\${esc(name)}|\${esc(k)}\">\${tr(\"del\")}</button></div>\`; });"
    echo "    d.innerHTML=\`<h3>\${esc(name)} <button class=\"btn sm\" data-delp=\"\${esc(name)}\">\${tr(\"del\")}</button></h3>\${rows}\`"
    echo "      +\`<div class=\"row\" style=\"margin-top:6px\"><input class=\"nf\" data-np=\"\${esc(name)}\" placeholder=\"\${tr(\"newField\")}\" style=\"max-width:180px\"><input class=\"nv\" data-np=\"\${esc(name)}\" placeholder=\"\${tr(\"newValue\")}\" style=\"max-width:260px\"><button class=\"btn sm\" data-addf=\"\${esc(name)}\">\${tr(\"addField\")}</button></div>\`;"
    echo "    root.appendChild(d);"
    echo "  });"
    echo "  root.querySelectorAll(\"input[data-k]\").forEach(i=>i.onchange=()=>{ VAULT.providers[i.dataset.p][i.dataset.k]=i.value; });"
    echo "  root.querySelectorAll(\"button[data-del]\").forEach(b=>b.onclick=()=>{ const [p,k]=b.dataset.del.split(\"|\"); delete VAULT.providers[p][k]; renderEditor(); });"
    echo "  root.querySelectorAll(\"button[data-delp]\").forEach(b=>b.onclick=()=>{ delete VAULT.providers[b.dataset.delp]; renderEditor(); });"
    echo "  root.querySelectorAll(\"button[data-addf]\").forEach(b=>b.onclick=()=>{ const p=b.dataset.addf; const nf=root.querySelector(\`.nf[data-np=\"\${CSS.escape(p)}\"]\`).value.trim(); const nv=root.querySelector(\`.nv[data-np=\"\${CSS.escape(p)}\"]\`).value; if(nf){ VAULT.providers[p][nf]=nv; renderEditor(); } });"
    echo "}"
    echo
    echo "document.getElementById(\"file\").onchange=e=>{ const f=e.target.files[0]; if(!f)return; const r=new FileReader(); r.onload=()=>{ blob.value=r.result.trim(); }; r.readAsText(f); };"
    echo "openBtn.onclick=async()=>{"
    echo "  const m=document.getElementById(\"openMsg\"); m.className=\"msg\"; m.textContent=\"\";"
    echo "  if(!pass.value){ m.className=\"msg err\"; m.textContent=tr(\"needPass\"); return; }"
    echo "  if(!blob.value.trim()){ m.className=\"msg err\"; m.textContent=tr(\"noInput\"); return; }"
    echo "  try{ VAULT=await decryptB64(blob.value,pass.value); if(!VAULT.providers)VAULT.providers={}; renderEditor(); m.className=\"msg ok\"; m.textContent=tr(\"opened\"); }"
    echo "  catch(err){ m.className=\"msg err\"; m.textContent=tr(\"bad\"); }"
    echo "};"
    echo "newBtn.onclick=()=>{"
    echo "  const m=document.getElementById(\"openMsg\");"
    echo "  if(!pass.value){ m.className=\"msg err\"; m.textContent=tr(\"needPass\"); return; }"
    echo "  VAULT={meta:{created:new Date().toISOString().slice(0,10),format:\"SVPB1\"},providers:{}}; renderEditor();"
    echo "  m.className=\"msg ok\"; m.textContent=tr(\"created\");"
    echo "};"
    echo "addProvBtn.onclick=()=>{ if(!VAULT){ return; } const n=newProv.value.trim(); if(n){ VAULT.providers[n]=VAULT.providers[n]||{}; newProv.value=\"\"; renderEditor(); } };"
    echo "encBtn.onclick=async()=>{"
    echo "  const m=document.getElementById(\"saveMsg\"); m.className=\"msg\";"
    echo "  if(!VAULT){ m.className=\"msg err\"; m.textContent=tr(\"needOpen\"); return; }"
    echo "  if(!pass.value){ m.className=\"msg err\"; m.textContent=tr(\"needPass\"); return; }"
    echo "  result.value=await encryptObj(VAULT,pass.value); m.className=\"msg ok\"; m.textContent=tr(\"encrypted\");"
    echo "};"
    echo "dlBtn.onclick=()=>{ if(!result.value)return; try{ const b=new Blob([result.value],{type:\"text/plain\"}); const u=URL.createObjectURL(b); const a=document.createElement(\"a\"); a.href=u; a.download=\"vault.svpb\"; document.body.appendChild(a); a.click(); a.remove(); setTimeout(()=>URL.revokeObjectURL(u),1500);}catch(e){} };"
    echo "expBtn.onclick=()=>{ if(!VAULT)return; result.value=JSON.stringify(VAULT,null,2); };"
    echo
    echo "</script>"
    echo "</body>"
    echo "</html>"
} > "$output_file"

echo "HTML file generated: $output_file"
