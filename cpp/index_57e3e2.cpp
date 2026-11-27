// abstraction-provenance: {"artifact_sha256": "0b5c70934be2043bd718c263b498bb227048dfe4012fe584f4e6b160fdaa830c", "source_sha256": "57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c", "target_language": "cpp"}
// index.html — portiert nach cpp
// Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <map>
#include <vector>
#include <filesystem>
#include <ctime>

class HtmlGenerator {
private:
    std::ostringstream html;
    
public:
    void generateHtml(const std::string& filename) {
        html.str("");
        html.clear();
        
        // Generate the complete HTML structure
        html << "<!DOCTYPE html>\n";
        html << "<script type=\"application/json\" id=\"cowork-artifact-meta\">\n";
        html << "{\n";
        html << "  \"name\": \"Tagesstatus Live Public\",\n";
        html << "  \"schemaVersion\": 1,\n";
        html << "  \"description\": \"Öffentliche, umgebungs-unabhängige Status-Seite ohne eingebettete Keys. Fragt Tokens beim Öffnen ab (nur localStorage), zeigt ohne Key keine Daten. Holt Daten per direktem Browser-Abruf (GitHub, OpenRouter, OpenAI, Anthropic, Tailscale, ClawHub) — funktioniert voll nur gehostet/lokal außerhalb der Sandbox; CORS-geschützte Quellen brauchen ggf. einen Proxy.\",\n";
        html << "  \"mcpTools\": [],\n";
        html << "  \"mcpServerNames\": []\n";
        html << "}\n";
        html << "</script>\n";
        html << "<html lang=\"de\">\n";
        html << "<head>\n";
        html << "<meta charset=\"utf-8\">\n";
        html << "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n";
        html << "<title>Tagesstatus Live — Public</title>\n";
        html << "<style>\n";
        html << ":root { color-scheme: light; }\n";
        html << "* { box-sizing: border-box; }\n";
        html << "body { margin:0; font-family:-apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,Helvetica,Arial,sans-serif; background:#f7f7f5; color:#1d1c1a; }\n";
        html << ".wrap { max-width:880px; margin:0 auto; padding:20px 16px 60px; }\n";
        html << "h1 { font-size:22px; margin:0 0 2px; }\n";
        html << ".sub { color:#6b6a66; font-size:13px; margin-bottom:16px; }\n";
        html << ".bar { display:flex; gap:10px; align-items:center; margin-bottom:16px; flex-wrap:wrap; }\n";
        html << "button { font-size:13px; font-weight:600; padding:7px 13px; border:1px solid #d9d8d3; border-radius:8px; background:#fff; cursor:pointer; }\n";
        html << "button:hover { background:#f2f1ec; }\n";
        html << "button.primary { background:#1d1c1a; color:#fff; border-color:#1d1c1a; }\n";
        html << ".note { background:#fffdf4; border:1px solid #f0e9c8; border-radius:10px; padding:12px 14px; font-size:13px; color:#4a4734; margin-bottom:16px; line-height:1.5; }\n";
        html << ".section { background:#fff; border:1px solid #e8e7e3; border-radius:12px; margin-bottom:14px; overflow:hidden; }\n";
        html << ".section > h2 { font-size:15px; margin:0; padding:13px 16px; border-bottom:1px solid #efeee9; display:flex; align-items:center; gap:9px; }\n";
        html << ".section > h2 .badge { margin-left:auto; font-size:12px; font-weight:600; background:#efeee9; color:#5a5852; padding:2px 9px; border-radius:20px; }\n";
        html << ".body { padding:8px 16px 14px; font-size:14px; }\n";
        html << ".muted { color:#8a8884; }\n";
        html << ".err { color:#c0392b; }\n";
        html << ".kv { display:flex; justify-content:space-between; padding:4px 0; border-bottom:1px solid #f4f3ee; }\n";
        html << ".kv:last-child { border:none; }\n";
        html << ".kv .k { color:#6b6a66; } .kv .v { font-weight:600; }\n";
        html << "a { color:#2b5cc4; text-decoration:none; } a:hover { text-decoration:underline; }\n";
        html << "/* settings modal */\n";
        html << ".modal { position:fixed; inset:0; background:rgba(0,0,0,.35); display:none; align-items:flex-start; justify-content:center; padding:40px 16px; overflow:auto; }\n";
        html << ".modal.open { display:flex; }\n";
        html << ".card { background:#fff; border-radius:14px; max-width:560px; width:100%; padding:20px; }\n";
        html << ".card h3 { margin:0 0 4px; font-size:17px; }\n";
        html << ".card p.hint { margin:0 0 16px; font-size:12px; color:#8a8884; }\n";
        html << ".field { margin-bottom:12px; }\n";
        html << ".field label { display:block; font-size:12px; font-weight:600; color:#5a5852; margin-bottom:3px; }\n";
        html << ".field input { width:100%; font-size:13px; padding:7px 9px; border:1px solid #d9d8d3; border-radius:7px; font-family:ui-monospace,Menlo,monospace; }\n";
        html << ".field .desc { font-size:11px; color:#a8a6a1; margin-top:2px; }\n";
        html << ".actions { display:flex; gap:10px; justify-content:flex-end; margin-top:8px; }\n";
        html << ".warn { background:#fdf3f3; border:1px solid #f3d9d9; color:#9a3b3b; border-radius:8px; padding:10px 12px; font-size:12px; margin-bottom:14px; }\n";
        html << "</style>\n";
        html << "</head>\n";
        html << "<body>\n";
        html << "<div class=\"wrap\">\n";
        html << "  <h1>Tagesstatus Live — Public</h1>\n";
        html << "  <div class=\"sub\" id=\"sub\">Eigenständige Version · keine Daten ohne hinterlegte Keys</div>\n";
        html << "\n";
        html << "  <div class=\"bar\">\n";
        html << "    <button class=\"primary\" id=\"cfgBtn\">🔑 Keys eingeben / verwalten</button>\n";
        html << "    <button id=\"reloadBtn\">↻ Aktualisieren</button>\n";
        html << "    <button id=\"clearBtn\">Keys löschen</button>\n";
        html << "  </div>\n";
        html << "\n";
        html << "  <div class=\"note\">\n";
        html << "    Diese Seite ist <b>nicht</b> mit einer Umgebung verbunden und enthält <b>keine</b> eingebetteten Keys.\n";
        html << "    Beim ersten Öffnen fragt sie deine Tokens ab; sie werden nur lokal im Browser (localStorage) gespeichert.\n";
        html << "    Ohne hinterlegten Key zeigt der jeweilige Abschnitt „keine Daten\". Daten werden direkt per Browser-Abruf\n";
        html << "    bei den Anbietern geholt — das funktioniert nur außerhalb eingeschränkter Sandboxes (also als gehostete/lokale Datei).\n";
        html << "  </div>\n";
        html << "  <div class=\"warn\">\n";
        html << "    Sicherheit: Keys liegen im Klartext im Browser dieses Geräts. Manche Anbieter (OpenAI, Anthropic, Tailscale)\n";
        html << "    blockieren Browser-Abrufe per CORS bzw. raten von Client-seitigen Keys ab — dort kann statt Daten ein\n";
        html << "    CORS-/401-Fehler erscheinen. Für solche Quellen ist ein kleiner Server-Proxy nötig.\n";
        html << "  </div>\n";
        html << "\n";
        html << "  <div id=\"sections\"></div>\n";
        html << "</div>\n";
        html << "\n";
        html << "<div class=\"modal\" id=\"modal\">\n";
        html << "  <div class=\"card\">\n";
        html << "    <h3>Zugangsdaten</h3>\n";
        html << "    <p class=\"hint\">Leer lassen = Quelle wird übersprungen. Speicherung nur lokal (localStorage).</p>\n";
        html << "    <div class=\"field\"><label>GitHub Repo (owner/repo)</label><input id=\"f_ghrepo\" placeholder=\"KikiKari/OpenClaw\"><div class=\"desc\">Öffentliche Repos gehen ohne Token.</div></div>\n";
        html << "    <div class=\"field\"><label>GitHub Token (optional, für privat/Codespaces)</label><input id=\"f_ghtoken\" placeholder=\"github_pat_… oder ghp_…\"></div>\n";
        html << "    <div class=\"field\"><label>OpenRouter API Key</label><input id=\"f_or\" placeholder=\"sk-or-v1-…\"><div class=\"desc\">Verbrauch & Restguthaben.</div></div>\n";
        html << "    <div class=\"field\"><label>OpenAI Admin Key</label><input id=\"f_oai\" placeholder=\"sk-admin-…\"><div class=\"desc\">Org-Kosten (CORS evtl. blockiert).</div></div>\n";
        html << "    <div class=\"field\"><label>Anthropic Admin Key</label><input id=\"f_anth\" placeholder=\"sk-ant-admin…\"><div class=\"desc\">Claude Kosten/Nutzung (CORS evtl. blockiert).</div></div>\n";
        html << "    <div class=\"field\"><label>Tailscale API Token + Tailnet</label><input id=\"f_ts\" placeholder=\"tskey-api-…\"><input id=\"f_tsnet\" placeholder=\"Tailnet, z.B. example.org oder -\" style=\"margin-top:6px\"><div class=\"desc\">Geräte/Status (CORS evtl. blockiert).</div></div>\n";
        html << "    <div class=\"field\"><label>ClawHub Skill-Slugs (kommagetrennt)</label><input id=\"f_clawhub\" placeholder=\"cluster-gateway, mcp-tool-utils, json-utils\"><div class=\"desc\">Öffentliche ClawHub-API je Skill (kein Token nötig, CORS erlaubt) — Version, Downloads, Scan-Status.</div></div>\n";
        html << "    <div class=\"actions\"><button id=\"cancelBtn\">Abbrechen</button><button class=\"primary\" id=\"saveBtn\">Speichern & laden</button></div>\n";
        html << "  </div>\n";
        html << "</div>\n";
        html << "\n";
        html << "<script>\n";
        html << "const LS = \"tsl_public_keys\";\n";
        html << "const esc = s => (s==null?\"\":String(s)).replace(/[&<>\\\"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','\\\"':'&quot;'}[c]));\n";
        html << "function getKeys(){ try { return JSON.parse(localStorage.getItem(LS)||\"{}\")); } catch(e){ return {}; } }\n";
        html << "function setKeys(o){ localStorage.setItem(LS, JSON.stringify(o)); }\n";
        html << "\n";
        html << "// ---- Modal ----\n";
        html << "const modal = document.getElementById(\"modal\");\n";
        html << "function openCfg(){\n";
        html << "  const k = getKeys();\n";
        html << "  f_ghrepo.value=k.ghrepo||\"\"; f_ghtoken.value=k.ghtoken||\"\"; f_or.value=k.or||\"\";\n";
        html << "  f_oai.value=k.oai||\"\"; f_anth.value=k.anth||\"\"; f_ts.value=k.ts||\"\"; f_tsnet.value=k.tsnet||\"\"; f_clawhub.value=k.clawhub||\"\";\n";
        html << "  modal.classList.add(\"open\");\n";
        html << "}\n";
        html << "function closeCfg(){ modal.classList.remove(\"open\"); }\n";
        html << "cfgBtn.onclick=openCfg; cancelBtn.onclick=closeCfg;\n";
        html << "saveBtn.onclick=()=>{ setKeys({ ghrepo:f_ghrepo.value.trim(), ghtoken:f_ghtoken.value.trim(), or:f_or.value.trim(), oai:f_oai.value.trim(), anth:f_anth.value.trim(), ts:f_ts.value.trim(), tsnet:f_tsnet.value.trim(), clawhub:f_clawhub.value.trim() }); closeCfg(); loadAll(); };\n";
        html << "clearBtn.onclick=()=>{ if(confirm(\"Alle hinterlegten Keys löschen?\")){ localStorage.removeItem(LS); loadAll(); } };\n";
        html << "reloadBtn.onclick=()=>loadAll();\n";
        html << "\n";
        html << "// ---- Sections scaffold ----\n";
        html << "const SECTIONS = [\n";
        html << "  {id:\"github\", title:\"GitHub — PRs & Branches\"},\n";
        html << "  {id:\"openrouter\", title:\"OpenRouter — Verbrauch & Guthaben\"},\n";
        html << "  {id:\"openai\", title:\"OpenAI — Kosten (30 Tage)\"},\n";
        html << "  {id:\"anthropic\", title:\"Claude / Anthropic — Kosten (30 Tage)\"},\n";
        html << "  {id:\"tailscale\", title:\"Tailscale — Geräte\"},\n";
        html << "  {id:\"clawhub\", title:\"ClawHub — meine Skills\"},\n";
        html << "  {id:\"perplexity\", title:\"Perplexity — Hinweis\"}\n";
        html << "];\n";
        html << "function scaffold(){\n";
        html << "  document.getElementById(\"sections\").innerHTML = SECTIONS.map(s =>\n";
        html << "    '<div class=\"section\"><h2>'+esc(s.title)+'<span class=\"badge\" id=\"b-'+s.id+'\">–</span></h2>'+\n";
        html << "    '<div class=\"body\" id=\"c-'+s.id+'\"><span class=\"muted\">…</span></div></div>').join(\"\");\n";
        html << "}\n";
        html << "function setB(id,v){ const e=document.getElementById(\"b-\"+id); if(e) e.textContent=v; }\n";
        html << "function render(id,html){ const e=document.getElementById(\"c-\"+id); if(e) e.innerHTML=html; }\n";
        html << "const noKey = id => { setB(id,\"–\"); render(id,'<span class=\"muted\">Kein Token hinterlegt — keine Daten.</span>'); };\n";
        html << "\n";
        html << "async function fetchJson(url, headers){\n";
        html << "  const r = await fetch(url, { headers: headers||{} });\n";
        html << "  const txt = await r.text();\n";
        html << "  let data=null; try { data = JSON.parse(txt); } catch(e){}\n";
        html << "  if(!r.ok) throw new Error(\"HTTP \"+r.status+(data&&data.error?(\" · \"+(data.error.message||data.error)) : \"\"));\n";
        html << "  return data;\n";
        html << "}\n";
        html << "\n";
        html << "async function loadGitHub(){\n";
        html << "  const k=getKeys(); const repo=k.ghrepo||\"\";\n";
        html << "  if(!repo){ noKey(\"github\"); return; }\n";
        html << "  try {\n";
        html << "    const h = k.ghtoken ? {Authorization:\"Bearer \"+k.ghtoken, Accept:\"application/vnd.github+json\"} : {Accept:\"application/vnd.github+json\"};\n";
        html << "    const [prs, br] = await Promise.all([\n";
        html << "      fetchJson(\"https://api.github.com/repos/\"+repo+\"/pulls?state=open&per_page=20\", h),\n";
        html << "      fetchJson(\"https://api.github.com/repos/\"+repo+\"/branches?per_page=100\", h)\n";
        html << "    ]);\n";
        html << "    setB(\"github\", (prs||[]).length);\n";
        html << "    let html = (prs&&prs.length) ? prs.map(p=>'<div class=\"kv\"><span class=\"k\"><a href=\"'+esc(p.html_url)+'\" target=\"_blank\">#'+p.number+' '+esc(p.title)+'</a></span><span class=\"v\">'+esc((p.user&&p.user.login)||\"\")+'</span></div>').join(\"\") : '<span class=\"muted\">Keine offenen PRs.</span>';\n";
        html << "    if(br&&br.length) html+='<div class=\"kv\"><span class=\"k\">Branches</span><span class=\"v\">'+br.length+'</span></div>';\n";
        html << "    render(\"github\", html);\n";
        html << "  } catch(e){ setB(\"github\",\"!\"); render(\"github\",'<span class=\"err\">'+esc(e.message)+'</span>'); }\n";
        html << "}\n";
        html << "async function loadOpenRouter(){\n";
        html << "  const k=getKeys(); if(!k.or){ noKey(\"openrouter\"); return; }\n";
        html << "  try {\n";
        html << "    const d = await fetchJson(\"https://openrouter.ai/api/v1/key\", {Authorization:\"Bearer \"+k.or});\n";
        html << "    const x = (d&&d.data)||{};\n";
        html << "    setB(\"openrouter\",\"ok\");\n";
        html << "    render(\"openrouter\",\n";
        html << "      '<div class=\"kv\"><span class=\"k\">Verbraucht (gesamt)</span><span class=\"v\">'+esc(x.usage)+'</span></div>'+\n";
        html << "      '<div class=\"kv\"><span class=\"k\">Heute / Woche / Monat</span><span class=\"v\">'+esc(x.usage_daily)+' / '+esc(x.usage_weekly)+' / '+esc(x.usage_monthly)+'</span></div>'+\n";
        html << "      '<div class=\"kv\"><span class=\"k\">Limit / Rest</span><span class=\"v\">'+esc(x.limit==null?\"∞\":x.limit)+' / '+esc(x.limit_remaining==null?\"∞\":x.limit_remaining)+'</span></div>');\n";
        html << "  } catch(e){ setB(\"openrouter\",\"!\"); render(\"openrouter\",'<span class=\"err\">'+esc(e.message)+'</span>'); }\n";
        html << "}\n";
        html << "function iso30(){ const d=new Date(); d.setDate(d.getDate()-30); return d.toISOString().slice(0,10); }\n";
        html << "async function loadOpenAI(){\n";
        html << "  const k=getKeys(); if(!k.oai){ noKey(\"openai\"); return; }\n";
        html << "  try {\n";
        html << "    const start = Math.floor((Date.now()-30*864e5)/1000);\n";
        html << "    const d = await fetchJson(\"https://api.openai.com/v1/organization/costs?start_time=\"+start+\"&limit=30\", {Authorization:\"Bearer \"+k.oai});\n";
        html << "    let total=0; (d&&d.data||[]).forEach(b=>(b.results||[]).forEach(r=>{ total += (r.amount&&r.amount.value)||0; }));\n";
        html << "    setB(\"openai\",\"ok\");\n";
        html << "    render(\"openai\",'<div class=\"kv\"><span class=\"k\">Kosten 30 Tage (USD)</span><span class=\"v\">'+total.toFixed(2)+'</span></div>');\n";
        html << "  } catch(e){ setB(\"openai\",\"!\"); render(\"openai\",'<span class=\"err\">'+esc(e.message)+' (oft CORS/Admin-Key nötig)</span>'); }\n";
        html << "}\n";
        html << "async function loadAnthropic(){\n";
        html << "  const k=getKeys(); if(!k.anth){ noKey(\"anthropic\"); return; }\n";
        html << "  try {\n";
        html << "    const d = await fetchJson(\"https://api.anthropic.com/v1/organizations/cost_report?starting_at=\"+iso30(), {\"x-api-key\":k.anth,\"anthropic-version\":\"2023-06-01\"});\n";
        html << "    setB(\"anthropic\",\"ok\");\n";
        html << "    render(\"anthropic\",'<div class=\"kv\"><span class=\"k\">Cost-Report</span><span class=\"v\">'+esc(JSON.stringify(d).slice(0,80))+'…</span></div>');\n";
        html << "  } catch(e){ setB(\"anthropic\",\"!\"); render(\"anthropic\",'<span class=\"err\">'+esc(e.message)+' (Browser-CORS oft blockiert)</span>'); }\n";
        html << "}\n";
        html << "async function loadTailscale(){\n";
        html << "  const k=getKeys(); if(!k.ts){ noKey(\"tailscale\"); return; }\n";
        html << "  try {\n";
        html << "    const net = k.tsnet||\"-\";\n";
        html << "    const d = await fetchJson(\"https://api.tailscale.com/api/v2/tailnet/\"+encodeURIComponent(net)+\"/devices\", {Authorization:\"Bearer \"+k.ts});\n";
        html << "    const dev = (d&&d.devices)||[];\n";
        html << "    setB(\"tailscale\", dev.length);\n";
        html << "    render(\"tailscale\", dev.length ? dev.map(x=>'<div class=\"kv\"><span class=\"k\">'+esc(x.hostname||x.name)+'</span><span class=\"v\">'+(x.lastSeen?esc(x.lastSeen.slice(0,10)):\"\")+'</span></div>').join(\"\") : '<span class=\"muted\">Keine Geräte.</span>');\n";
        html << "  } catch(e){ setB(\"tailscale\",\"!\"); render(\"tailscale\",'<span class=\"err\">'+esc(e.message)+' (Browser-CORS oft blockiert)</span>'); }\n";
        html << "}\n";
        html << "async function loadClawHub(){\n";
        html << "  const k=getKeys(); const slugs=(k.clawhub||\"\").split(\",\").map(s=>s.trim()).filter(Boolean);\n";
        html << "  if(!slugs.length){ noKey(\"clawhub\"); return; }\n";
        html << "  const rows=[]; let okc=0, total=0;\n";
        html << "  for(const slug of slugs){\n";
        html << "    try {\n";
        html << "      const d = await fetchJson(\"https://clawhub.ai/api/v1/skills/\"+encodeURIComponent(slug));\n";
        html << "      const sk=(d&&d.skill)||{}; const ver=(d&&d.latestVersion&&d.latestVersion.version)||(sk.tags&&sk.tags.latest)||\"?\";\n";
        html << "      const dl=(sk.stats&&(sk.stats.downloads!=null?sk.stats.downloads:sk.stats.downloadsAllTime));\n";
        html << "      const verdict=(d&&d.moderation&&d.moderation.verdict)|| (d&&d.moderation&&d.moderation.isSuspicious?\"suspicious\":\"clean\");\n";
        html << "      total+=(dl||0);\n";
        html << "      rows.push('<div class=\"kv\"><span class=\"k\"><a href=\"https://clawhub.ai/'+esc(sk.ownerHandle||\"\")+'/'+esc(slug)+'\" target=\"_blank\">'+esc(sk.displayName||slug)+'</a> · v'+esc(ver)+'</span><span class=\"v\">'+(dl!=null?dl+' DL':'')+' · '+esc(verdict)+'</span></div>');\n";
        html << "      okc++;\n";
        html << "    } catch(e){ rows.push('<div class=\"kv\"><span class=\"k\">'+esc(slug)+'</span><span class=\"v err\">'+esc(e.message)+'</span></div>'); }\n";
        html << "  }\n";
        html << "  setB(\"clawhub\", okc+\"/\"+slugs.length);\n";
        html << "  render(\"clawhub\", rows.join(\"\") + (total?'<div class=\"kv\"><span class=\"k\">Downloads gesamt</span><span class=\"v\">'+total+'</span></div>':''));\n";
        html << "}\n";
        html << "function loadPerplexity(){\n";
        html << "  setB(\"perplexity\",\"i\");\n";
        html << "  render(\"perplexity\",'<span class=\"muted\">Perplexity bietet keinen Verbrauchs-/Credits-Endpunkt. Credits nur im Dashboard sichtbar — daher hier keine Live-Daten.</span>');\n";
        html << "}\n";
        html << "\n";
        html << "function loadAll(){\n";
        html << "  scaffold();\n";
        html << "  const k=getKeys();\n";
        html << "  document.getElementById(\"sub\").textContent = Object.values(k).some(Boolean) ? \"Eigenständige Version · \"+(new Date()).toLocaleString(\"de-DE\") : \"Eigenständige Version · keine Keys hinterlegt — klicke \\\"Keys eingeben\\\".\";\n";
        html << "  loadGitHub(); loadOpenRouter(); loadOpenAI(); loadAnthropic(); loadTailscale(); loadClawHub(); loadPerplexity();\n";
        html << "}\n";
        html << "\n";
        html << "scaffold();\n";
        html << "if(!Object.values(getKeys()).some(Boolean)) openCfg();\n";
        html << "loadAll();\n";
        html << "</script>\n";
        html << "</body>\n";
        html << "</html>\n";
        
        // Write to file
        std::ofstream file(filename);
        if (file.is_open()) {
            file << html.str();
            file.close();
        } else {
            std::cerr << "Unable to open file: " << filename << std::endl;
        }
    }
};

int main(int argc, char* argv[]) {
    std::string filename = "index.html";
    
    if (argc > 1) {
        filename = argv[1];
    }
    
    HtmlGenerator generator;
    generator.generateHtml(filename);
    
    std::cout << "Generated HTML file: " << filename << std::endl;
    
    return 0;
}
