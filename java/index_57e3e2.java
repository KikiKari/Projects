// abstraction-provenance: {"artifact_sha256": "1f4f060350501bd625fb4e4d261d83fc8a8e1582f0a8d1e93f43b5cb6103933a", "source_sha256": "57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c", "target_language": "java"}
// index.html — portiert nach java
// Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import com.google.gson.*;

public class IndexGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java IndexGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        try {
            String htmlContent = generateHTML();
            Files.write(Paths.get(outputFile), htmlContent.getBytes(StandardCharsets.UTF_8));
            System.out.println("HTML file generated successfully: " + outputFile);
        } catch (Exception e) {
            System.err.println("Error generating HTML: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static String generateHTML() {
        StringBuilder html = new StringBuilder();
        
        // DOCTYPE
        html.append("<!DOCTYPE html>\n");
        
        // Script tag with JSON metadata
        html.append("<script type=\"application/json\" id=\"cowork-artifact-meta\">\n");
        html.append("{\n");
        html.append("  \"name\": \"Tagesstatus Live Public\",\n");
        html.append("  \"schemaVersion\": 1,\n");
        html.append("  \"description\": \"Öffentliche, umgebungs-unabhängige Status-Seite ohne eingebettete Keys. Fragt Tokens beim Öffnen ab (nur localStorage), zeigt ohne Key keine Daten. Holt Daten per direktem Browser-Abruf (GitHub, OpenRouter, OpenAI, Anthropic, Tailscale, ClawHub) — funktioniert voll nur gehostet/lokal außerhalb der Sandbox; CORS-geschützte Quellen brauchen ggf. einen Proxy.\",\n");
        html.append("  \"mcpTools\": [],\n");
        html.append("  \"mcpServerNames\": []\n");
        html.append("}\n");
        html.append("</script>\n");
        
        // HTML start
        html.append("<html lang=\"de\">\n");
        html.append("<head>\n");
        html.append("<meta charset=\"utf-8\">\n");
        html.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
        html.append("<title>Tagesstatus Live — Public</title>\n");
        html.append("<style>\n");
        html.append(":root { color-scheme: light; }\n");
        html.append("* { box-sizing: border-box; }\n");
        html.append("body { margin:0; font-family:-apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,Helvetica,Arial,sans-serif; background:#f7f7f5; color:#1d1c1a; }\n");
        html.append(".wrap { max-width:880px; margin:0 auto; padding:20px 16px 60px; }\n");
        html.append("h1 { font-size:22px; margin:0 0 2px; }\n");
        html.append(".sub { color:#6b6a66; font-size:13px; margin-bottom:16px; }\n");
        html.append(".bar { display:flex; gap:10px; align-items:center; margin-bottom:16px; flex-wrap:wrap; }\n");
        html.append("button { font-size:13px; font-weight:600; padding:7px 13px; border:1px solid #d9d8d3; border-radius:8px; background:#fff; cursor:pointer; }\n");
        html.append("button:hover { background:#f2f1ec; }\n");
        html.append("button.primary { background:#1d1c1a; color:#fff; border-color:#1d1c1a; }\n");
        html.append(".note { background:#fffdf4; border:1px solid #f0e9c8; border-radius:10px; padding:12px 14px; font-size:13px; color:#4a4734; margin-bottom:16px; line-height:1.5; }\n");
        html.append(".section { background:#fff; border:1px solid #e8e7e3; border-radius:12px; margin-bottom:14px; overflow:hidden; }\n");
        html.append(".section > h2 { font-size:15px; margin:0; padding:13px 16px; border-bottom:1px solid #efeee9; display:flex; align-items:center; gap:9px; }\n");
        html.append(".section > h2 .badge { margin-left:auto; font-size:12px; font-weight:600; background:#efeee9; color:#5a5852; padding:2px 9px; border-radius:20px; }\n");
        html.append(".body { padding:8px 16px 14px; font-size:14px; }\n");
        html.append(".muted { color:#8a8884; }\n");
        html.append(".err { color:#c0392b; }\n");
        html.append(".kv { display:flex; justify-content:space-between; padding:4px 0; border-bottom:1px solid #f4f3ee; }\n");
        html.append(".kv:last-child { border:none; }\n");
        html.append(".kv .k { color:#6b6a66; } .kv .v { font-weight:600; }\n");
        html.append("a { color:#2b5cc4; text-decoration:none; } a:hover { text-decoration:underline; }\n");
        html.append("/* settings modal */\n");
        html.append(".modal { position:fixed; inset:0; background:rgba(0,0,0,.35); display:none; align-items:flex-start; justify-content:center; padding:40px 16px; overflow:auto; }\n");
        html.append(".modal.open { display:flex; }\n");
        html.append(".card { background:#fff; border-radius:14px; max-width:560px; width:100%; padding:20px; }\n");
        html.append(".card h3 { margin:0 0 4px; font-size:17px; }\n");
        html.append(".card p.hint { margin:0 0 16px; font-size:12px; color:#8a8884; }\n");
        html.append(".field { margin-bottom:12px; }\n");
        html.append(".field label { display:block; font-size:12px; font-weight:600; color:#5a5852; margin-bottom:3px; }\n");
        html.append(".field input { width:100%; font-size:13px; padding:7px 9px; border:1px solid #d9d8d3; border-radius:7px; font-family:ui-monospace,Menlo,monospace; }\n");
        html.append(".field .desc { font-size:11px; color:#a8a6a1; margin-top:2px; }\n");
        html.append(".actions { display:flex; gap:10px; justify-content:flex-end; margin-top:8px; }\n");
        html.append(".warn { background:#fdf3f3; border:1px solid #f3d9d9; color:#9a3b3b; border-radius:8px; padding:10px 12px; font-size:12px; margin-bottom:14px; }\n");
        html.append("</style>\n");
        html.append("</head>\n");
        html.append("<body>\n");
        html.append("<div class=\"wrap\">\n");
        html.append("  <h1>Tagesstatus Live — Public</h1>\n");
        html.append("  <div class=\"sub\" id=\"sub\">Eigenständige Version · keine Daten ohne hinterlegte Keys</div>\n");
        html.append("\n");
        html.append("  <div class=\"bar\">\n");
        html.append("    <button class=\"primary\" id=\"cfgBtn\">🔑 Keys eingeben / verwalten</button>\n");
        html.append("    <button id=\"reloadBtn\">↻ Aktualisieren</button>\n");
        html.append("    <button id=\"clearBtn\">Keys löschen</button>\n");
        html.append("  </div>\n");
        html.append("\n");
        html.append("  <div class=\"note\">\n");
        html.append("    Diese Seite ist <b>nicht</b> mit einer Umgebung verbunden und enthält <b>keine</b> eingebetteten Keys.\n");
        html.append("    Beim ersten Öffnen fragt sie deine Tokens ab; sie werden nur lokal im Browser (localStorage) gespeichert.\n");
        html.append("    Ohne hinterlegten Key zeigt der jeweilige Abschnitt „keine Daten\". Daten werden direkt per Browser-Abruf\n");
        html.append("    bei den Anbietern geholt — das funktioniert nur außerhalb eingeschränkter Sandboxes (also als gehostete/lokale Datei).\n");
        html.append("  </div>\n");
        html.append("  <div class=\"warn\">\n");
        html.append("    Sicherheit: Keys liegen im Klartext im Browser dieses Geräts. Manche Anbieter (OpenAI, Anthropic, Tailscale)\n");
        html.append("    blockieren Browser-Abrufe per CORS bzw. raten von Client-seitigen Keys ab — dort kann statt Daten ein\n");
        html.append("    CORS-/401-Fehler erscheinen. Für solche Quellen ist ein kleiner Server-Proxy nötig.\n");
        html.append("  </div>\n");
        html.append("\n");
        html.append("  <div id=\"sections\"></div>\n");
        html.append("</div>\n");
        html.append("\n");
        html.append("<div class=\"modal\" id=\"modal\">\n");
        html.append("  <div class=\"card\">\n");
        html.append("    <h3>Zugangsdaten</h3>\n");
        html.append("    <p class=\"hint\">Leer lassen = Quelle wird übersprungen. Speicherung nur lokal (localStorage).</p>\n");
        html.append("    <div class=\"field\"><label>GitHub Repo (owner/repo)</label><input id=\"f_ghrepo\" placeholder=\"KikiKari/OpenClaw\"><div class=\"desc\">Öffentliche Repos gehen ohne Token.</div></div>\n");
        html.append("    <div class=\"field\"><label>GitHub Token (optional, für privat/Codespaces)</label><input id=\"f_ghtoken\" placeholder=\"github_pat_… oder ghp_…\"></div>\n");
        html.append("    <div class=\"field\"><label>OpenRouter API Key</label><input id=\"f_or\" placeholder=\"sk-or-v1-…\"><div class=\"desc\">Verbrauch & Restguthaben.</div></div>\n");
        html.append("    <div class=\"field\"><label>OpenAI Admin Key</label><input id=\"f_oai\" placeholder=\"sk-admin-…\"><div class=\"desc\">Org-Kosten (CORS evtl. blockiert).</div></div>\n");
        html.append("    <div class=\"field\"><label>Anthropic Admin Key</label><input id=\"f_anth\" placeholder=\"sk-ant-admin…\"><div class=\"desc\">Claude Kosten/Nutzung (CORS evtl. blockiert).</div></div>\n");
        html.append("    <div class=\"field\"><label>Tailscale API Token + Tailnet</label><input id=\"f_ts\" placeholder=\"tskey-api-…\"><input id=\"f_tsnet\" placeholder=\"Tailnet, z.B. example.org oder -\" style=\"margin-top:6px\"><div class=\"desc\">Geräte/Status (CORS evtl. blockiert).</div></div>\n");
        html.append("    <div class=\"field\"><label>ClawHub Skill-Slugs (kommagetrennt)</label><input id=\"f_clawhub\" placeholder=\"cluster-gateway, mcp-tool-utils, json-utils\"><div class=\"desc\">Öffentliche ClawHub-API je Skill (kein Token nötig, CORS erlaubt) — Version, Downloads, Scan-Status.</div></div>\n");
        html.append("    <div class=\"actions\"><button id=\"cancelBtn\">Abbrechen</button><button class=\"primary\" id=\"saveBtn\">Speichern & laden</button></div>\n");
        html.append("  </div>\n");
        html.append("</div>\n");
        html.append("\n");
        html.append("<script>\n");
        html.append("const LS = \"tsl_public_keys\";\n");
        html.append("const esc = s => (s==null?\"\":String(s)).replace(/[&<>\\\"]/g,c=>({\'&\':\'&amp;\',\'<\':\'&lt;\',\'>\':\'&gt;\',\'\\\"\':\'&quot;\'}[c]));\n");
        html.append("function getKeys(){ try { return JSON.parse(localStorage.getItem(LS)||\"{}\")); } catch(e){ return {}; } }\n");
        html.append("function setKeys(o){ localStorage.setItem(LS, JSON.stringify(o)); }\n");
        html.append("\n");
        html.append("// ---- Modal ----\n");
        html.append("const modal = document.getElementById(\"modal\");\n");
        html.append("function openCfg(){\n");
        html.append("  const k = getKeys();\n");
        html.append("  f_ghrepo.value=k.ghrepo||\"\"; f_ghtoken.value=k.ghtoken||\"\"; f_or.value=k.or||\"\";\n");
        html.append("  f_oai.value=k.oai||\"\"; f_anth.value=k.anth||\"\"; f_ts.value=k.ts||\"\"; f_tsnet.value=k.tsnet||\"\"; f_clawhub.value=k.clawhub||\"\";\n");
        html.append("  modal.classList.add(\"open\");\n");
        html.append("}\n");
        html.append("function closeCfg(){ modal.classList.remove(\"open\"); }\n");
        html.append("cfgBtn.onclick=openCfg; cancelBtn.onclick=closeCfg;\n");
        html.append("saveBtn.onclick=()=>{ setKeys({ ghrepo:f_ghrepo.value.trim(), ghtoken:f_ghtoken.value.trim(), or:f_or.value.trim(), oai:f_oai.value.trim(), anth:f_anth.value.trim(), ts:f_ts.value.trim(), tsnet:f_tsnet.value.trim(), clawhub:f_clawhub.value.trim() }); closeCfg(); loadAll(); };\n");
        html.append("clearBtn.onclick=()=>{ if(confirm(\"Alle hinterlegten Keys löschen?\")){ localStorage.removeItem(LS); loadAll(); } };\n");
        html.append("reloadBtn.onclick=()=>loadAll();\n");
        html.append("\n");
        html.append("// ---- Sections scaffold ----\n");
        html.append("const SECTIONS = [\n");
        html.append("  {id:\"github\", title:\"GitHub — PRs & Branches\"},\n");
        html.append("  {id:\"openrouter\", title:\"OpenRouter — Verbrauch & Guthaben\"},\n");
        html.append("  {id:\"openai\", title:\"OpenAI — Kosten (30 Tage)\"},\n");
        html.append("  {id:\"anthropic\", title:\"Claude / Anthropic — Kosten (30 Tage)\"},\n");
        html.append("  {id:\"tailscale\", title:\"Tailscale — Geräte\"},\n");
        html.append("  {id:\"clawhub\", title:\"ClawHub — meine Skills\"},\n");
        html.append("  {id:\"perplexity\", title:\"Perplexity — Hinweis\"}\n");
        html.append("];\n");
        html.append("function scaffold(){\n");
        html.append("  document.getElementById(\"sections\").innerHTML = SECTIONS.map(s =>\n");
        html.append("    '<div class=\"section\"><h2>'+esc(s.title)+'<span class=\"badge\" id=\"b-'+s.id+'\">–</span></h2>'+");
        html.append("    '<div class=\"body\" id=\"c-'+s.id+'\"><span class=\"muted\">…</span></div></div>').join(\"\");\n");
        html.append("}\n");
        html.append("function setB(id,v){ const e=document.getElementById(\"b-\"+id); if(e) e.textContent=v; }\n");
        html.append("function render(id,html){ const e=document.getElementById(\"c-\"+id); if(e) e.innerHTML=html; }\n");
        html.append("const noKey = id => { setB(id,\"–\"); render(id,'<span class=\"muted\">Kein Token hinterlegt — keine Daten.</span>'); };\n");
        html.append("\n");
        html.append("async function fetchJson(url, headers){\n");
        html.append("  const r = await fetch(url, { headers: headers||{} });\n");
        html.append("  const txt = await r.text();\n");
        html.append("  let data=null; try { data = JSON.parse(txt); } catch(e){}\n");
        html.append("  if(!r.ok) throw new Error(\"HTTP \"+r.status+(data&&data.error?(\" · \"+(data.error.message||data.error)) : \"\"));\n");
        html.append("  return data;\n");
        html.append("}\n");
        html.append("\n");
        html.append("async function loadGitHub(){\n");
        html.append("  const k=getKeys(); const repo=k.ghrepo||\"\";\n");
        html.append("  if(!repo){ noKey(\"github\"); return; }\n");
        html.append("  try {\n");
        html.append("    const h = k.ghtoken ? {Authorization:\"Bearer \"+k.ghtoken, Accept:\"application/vnd.github+json\"} : {Accept:\"application/vnd.github+json\"};\n");
        html.append("    const [prs, br] = await Promise.all([\n");
        html.append("      fetchJson(\"https://api.github.com/repos/\"+repo+\"/pulls?state=open&per_page=20\", h),\n");
        html.append("      fetchJson(\"https://api.github.com/repos/\"+repo+\"/branches?per_page=100\", h)\n");
        html.append("    ]);\n");
        html.append("    setB(\"github\", (prs||[]).length);\n");
        html.append("    let html = (prs&&prs.length) ? prs.map(p=>'<div class=\"kv\"><span class=\"k\"><a href=\"'+esc(p.html_url)+'\" target=\"_blank\">#'+p.number+' '+esc(p.title)+'</a></span><span class=\"v\">'+esc((p.user&&p.user.login)||\"\")+'</span></div>').join(\"\") : '<span class=\"muted\">Keine offenen PRs.</span>';\n");
        html.append("    if(br&&br.length) html+='<div class=\"kv\"><span class=\"k\">Branches</span><span class=\"v\">'+br.length+'</span></div>';\n");
        html.append("    render(\"github\", html);\n");
        html.append("  } catch(e){ setB(\"github\",\"!\"); render(\"github\",'<span class=\"err\">'+esc(e.message)+'</span>'); }\n");
        html.append("}\n");
        html.append("async function loadOpenRouter(){\n");
        html.append("  const k=getKeys(); if(!k.or){ noKey(\"openrouter\"); return; }\n");
        html.append("  try {\n");
        html.append("    const d = await fetchJson(\"https://openrouter.ai/api/v1/key\", {Authorization:\"Bearer \"+k.or});\n");
        html.append("    const x = (d&&d.data)||{};\n");
        html.append("    setB(\"openrouter\",\"ok\");\n");
        html.append("    render(\"openrouter\",\n");
        html.append("      '<div class=\"kv\"><span class=\"k\">Verbraucht (gesamt)</span><span class=\"v\">'+esc(x.usage)+'</span></div>'+");
        html.append("      '<div class=\"kv\"><span class=\"k\">Heute / Woche / Monat</span><span class=\"v\">'+esc(x.usage_daily)+' / '+esc(x.usage_weekly)+' / '+esc(x.usage_monthly)+'</span></div>'+");
        html.append("      '<div class=\"kv\"><span class=\"k\">Limit / Rest</span><span class=\"v\">'+esc(x.limit==null?\"∞\":x.limit)+' / '+esc(x.limit_remaining==null?\"∞\":x.limit_remaining)+'</span></div>');\n");
        html.append("  } catch(e){ setB(\"openrouter\",\"!\"); render(\"openrouter\",'<span class=\"err\">'+esc(e.message)+'</span>'); }\n");
        html.append("}\n");
        html.append("function iso30(){ const d=new Date(); d.setDate(d.getDate()-30); return d.toISOString().slice(0,10); }\n");
        html.append("async function loadOpenAI(){\n");
        html.append("  const k=getKeys(); if(!k.oai){ noKey(\"openai\"); return; }\n");
        html.append("  try {\n");
        html.append("    const start = Math.floor((Date.now()-30*864e5)/1000);\n");
        html.append("    const d = await fetchJson(\"https://api.openai.com/v1/organization/costs?start_time=\"+start+\"&limit=30\", {Authorization:\"Bearer \"+k.oai});\n");
        html.append("    let total=0; (d&&d.data||[]).forEach(b=>(b.results||[]).forEach(r=>{ total += (r.amount&&r.amount.value)||0; }));\n");
        html.append("    setB(\"openai\",\"ok\");\n");
        html.append("    render(\"openai\",'<div class=\"kv\"><span class=\"k\">Kosten 30 Tage (USD)</span><span class=\"v\">'+total.toFixed(2)+'</span></div>');\n");
        html.append("  } catch(e){ setB(\"openai\",\"!\"); render(\"openai\",'<span class=\"err\">'+esc(e.message)+' (oft CORS/Admin-Key nötig)</span>'); }\n");
        html.append("}\n");
        html.append("async function loadAnthropic(){\n");
        html.append("  const k=getKeys(); if(!k.anth){ noKey(\"anthropic\"); return; }\n");
        html.append("  try {\n");
        html.append("    const d = await fetchJson(\"https://api.anthropic.com/v1/organizations/cost_report?starting_at=\"+iso30(), {\"x-api-key\":k.anth,\"anthropic-version\":\"2023-06-01\"});\n");
        html.append("    setB(\"anthropic\",\"ok\");\n");
        html.append("    render(\"anthropic\",'<div class=\"kv\"><span class=\"k\">Cost-Report</span><span class=\"v\">'+esc(JSON.stringify(d).slice(0,80))+'…</span></div>');\n");
        html.append("  } catch(e){ setB(\"anthropic\",\"!\"); render(\"anthropic\",'<span class=\"err\">'+esc(e.message)+' (Browser-CORS oft blockiert)</span>'); }\n");
        html.append("}\n");
        html.append("async function loadTailscale(){\n");
        html.append("  const k=getKeys(); if(!k.ts){ noKey(\"tailscale\"); return; }\n");
        html.append("  try {\n");
        html.append("    const net = k.tsnet||\"-\";\n");
        html.append("    const d = await fetchJson(\"https://api.tailscale.com/api/v2/tailnet/\"+encodeURIComponent(net)+\"/devices\", {Authorization:\"Bearer \"+k.ts});\n");
        html.append("    const dev = (d&&d.devices)||[];\n");
        html.append("    setB(\"tailscale\", dev.length);\n");
        html.append("    render(\"tailscale\", dev.length ? dev.map(x=>'<div class=\"kv\"><span class=\"k\">'+esc(x.hostname||x.name)+'</span><span class=\"v\">'+(x.lastSeen?esc(x.lastSeen.slice(0,10)):\"\")+'</span></div>').join(\"\") : '<span class=\"muted\">Keine Geräte.</span>');\n");
        html.append("  } catch(e){ setB(\"tailscale\",\"!\"); render(\"tailscale\",'<span class=\"err\">'+esc(e.message)+' (Browser-CORS oft blockiert)</span>'); }\n");
        html.append("}\n");
        html.append("async function loadClawHub(){\n");
        html.append("  const k=getKeys(); const slugs=(k.clawhub||\"\").split(\",\").map(s=>s.trim()).filter(Boolean);\n");
        html.append("  if(!slugs.length){ noKey(\"clawhub\"); return; }\n");
        html.append("  const rows=[]; let okc=0, total=0;\n");
        html.append("  for(const slug of slugs){\n");
        html.append("    try {\n");
        html.append("      const d = await fetchJson(\"https://clawhub.ai/api/v1/skills/\"+encodeURIComponent(slug));\n");
        html.append("      const sk=(d&&d.skill)||{}; const ver=(d&&d.latestVersion&&d.latestVersion.version)||(sk.tags&&sk.tags.latest)||\"?\";\n");
        html.append("      const dl=(sk.stats&&(sk.stats.downloads!=null?sk.stats.downloads:sk.stats.downloadsAllTime));\n");
        html.append("      const verdict=(d&&d.moderation&&d.moderation.verdict)|| (d&&d.moderation&&d.moderation.isSuspicious?\"suspicious\":\"clean\");\n");
        html.append("      total+=(dl||0);\n");
        html.append("      rows.push('<div class=\"kv\"><span class=\"k\"><a href=\"https://clawhub.ai/'+esc(sk.ownerHandle||\"\")+\"/\"+esc(slug)+'\" target=\"_blank\">'+esc(sk.displayName||slug)+'</a> · v'+esc(ver)+'</span><span class=\"v\">'+(dl!=null?dl+' DL':'')+' · '+esc(verdict)+'</span></div>');\n");
        html.append("      okc++;\n");
        html.append("    } catch(e){ rows.push('<div class=\"kv\"><span class=\"k\">'+esc(slug)+'</span><span class=\"v err\">'+esc(e.message)+'</span></div>'); }\n");
        html.append("  }\n");
        html.append("  setB(\"clawhub\", okc+\"/\"+slugs.length);\n");
        html.append("  render(\"clawhub\", rows.join(\"\") + (total?'<div class=\"kv\"><span class=\"k\">Downloads gesamt</span><span class=\"v\">'+total+'</span></div>':''));\n");
        html.append("}\n");
        html.append("function loadPerplexity(){\n");
        html.append("  setB(\"perplexity\",\"i\");\n");
        html.append("  render(\"perplexity\",'<span class=\"muted\">Perplexity bietet keinen Verbrauchs-/Credits-Endpunkt. Credits nur im Dashboard sichtbar — daher hier keine Live-Daten.</span>');\n");
        html.append("}\n");
        html.append("\n");
        html.append("function loadAll(){\n");
        html.append("  scaffold();\n");
        html.append("  const k=getKeys();\n");
        html.append("  document.getElementById(\"sub\").textContent = Object.values(k).some(Boolean) ? \"Eigenständige Version · \"+(new Date()).toLocaleString(\"de-DE\") : \"Eigenständige Version · keine Keys hinterlegt — klicke \\\"Keys eingeben\".;\n");
        html.append("  loadGitHub(); loadOpenRouter(); loadOpenAI(); loadAnthropic(); loadTailscale(); loadClawHub(); loadPerplexity();\n");
        html.append("}\n");
        html.append("\n");
        html.append("scaffold();\n");
        html.append("if(!Object.values(getKeys()).some(Boolean)) openCfg();\n");
        html.append("loadAll();\n");
        html.append("</script>\n");
        html.append("</body>\n");
        html.append("</html>\n");
        
        return html.toString();
    }
}
