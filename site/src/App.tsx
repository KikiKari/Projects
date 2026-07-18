import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { Link, Navigate, useLocation, useNavigate } from "react-router-dom";
import { featureData, pageSlugs, searchText, strings, type Language, type PageKey } from "./content";

const pageOrder = Object.keys(pageSlugs) as PageKey[];

function BrandMark() {
  return <span className="brand-mark" aria-hidden="true"><span /><span /></span>;
}

function Icon({ name }: { name: "download" | "external" | "search" | "play" | "caption" | "link" | "info" | "sound" | "monitor" | "pulse" }) {
  const paths: Record<typeof name, ReactNode> = {
    download: <><path d="M12 3v11"/><path d="m7 10 5 5 5-5"/><path d="M4 19h16"/></>,
    external: <><path d="M14 4h6v6"/><path d="m20 4-9 9"/><path d="M18 13v6a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h6"/></>,
    search: <><circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/></>,
    play: <path d="m9 7 8 5-8 5Z"/>, caption: <><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M7 10h3M7 14h3M14 10h3M14 14h3"/></>,
    link: <><path d="M10 13a5 5 0 0 0 7.5.5l2-2a5 5 0 0 0-7-7l-1.1 1"/><path d="M14 11a5 5 0 0 0-7.5-.5l-2 2a5 5 0 0 0 7 7l1.1-1"/></>,
    info: <><circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7h.01"/></>, sound: <><path d="M5 10h3l4-4v12l-4-4H5Z"/><path d="M16 9a4 4 0 0 1 0 6"/></>,
    monitor: <><rect x="3" y="4" width="18" height="13" rx="2"/><path d="M8 21h8M12 17v4"/></>, pulse: <path d="M3 12h4l2-6 4 12 2-6h6"/>
  };
  return <svg className="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[name]}</svg>;
}

function ProductMockup({ lang }: { lang: Language }) {
  const labels = lang === "de" ? ["Chatzeilen", "Untertitel", "WebSocket-Hook", "LIVE-Informationen", "Playersteuerung"] : ["Chat lines", "Captions", "WebSocket hook", "LIVE information", "Player controls"];
  const icons: Array<"info" | "caption" | "link" | "pulse" | "play"> = ["info", "caption", "link", "pulse", "play"];
  return <div className="browser-mockup" aria-label={lang === "de" ? "Produktdarstellung des Seitenpanels" : "Product illustration of the side panel"}>
    <div className="browser-bar"><span className="browser-dot"/><span>TikTok LIVE – Browser</span><span className="browser-actions">＋ ···</span></div>
    <div className="browser-content">
      <div className="video-placeholder"><span className="live-label">LIVE</span><span className="video-play"><Icon name="play" /></span><span className="video-controls">Ⅱ　◖━━●　⚙</span></div>
      <div className="chat-ghost" aria-hidden="true">{Array.from({ length: 7 }).map((_, i) => <span key={i} style={{ width: `${58 + (i % 3) * 10}%` }} />)}</div>
    </div>
    <div className="panel-mockup">
      <div className="panel-title"><BrandMark /> <strong>TikTok LIVE Companion</strong><span>···</span></div>
      {labels.map((label, index) => <div className="panel-row" key={label}><Icon name={icons[index]} /><span>{label}</span><b>⌄</b></div>)}
    </div>
  </div>;
}

function Header({ lang, page, onSearch }: { lang: Language; page: PageKey; onSearch: () => void }) {
  const s = strings[lang];
  const other = lang === "de" ? "en" : "de";
  const languagePath = `/${other}/${pageSlugs[page]}`.replace(/\/$/, page === "overview" ? "" : "/");
  return <header className="site-header">
    <Link to={`/${lang}`} className="brand"><BrandMark /><span>TikTok <b>LIVE</b> Companion</span></Link>
    <nav aria-label={lang === "de" ? "Hauptnavigation" : "Primary navigation"}>
      {(["overview", "installation", "features", "architecture", "security"] as PageKey[]).map(key => <Link key={key} className={page === key ? "active" : ""} aria-current={page === key ? "page" : undefined} to={`/${lang}/${pageSlugs[key]}`}>{s.nav[key]}</Link>)}
    </nav>
    <div className="header-tools">
      <button className="search-button" onClick={onSearch} aria-label={s.search}><Icon name="search"/><span>{lang === "de" ? "Suchen" : "Search"}</span><kbd>Ctrl K</kbd></button>
      <Link className="language-switch" to={languagePath} aria-label={`${s.language}: ${other.toUpperCase()}`}>{lang.toUpperCase()} <span>|</span> {other.toUpperCase()}</Link>
    </div>
  </header>;
}

function SearchDialog({ lang, open, onClose }: { lang: Language; open: boolean; onClose: () => void }) {
  const [query, setQuery] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);
  const navigate = useNavigate();
  const s = strings[lang];
  useEffect(() => { if (open) { setQuery(""); setTimeout(() => inputRef.current?.focus(), 0); } }, [open]);
  const results = useMemo(() => pageOrder.filter(key => `${s.nav[key]} ${searchText[lang][key]}`.toLowerCase().includes(query.toLowerCase().trim())), [lang, query, s.nav]);
  if (!open) return null;
  return <div className="dialog-backdrop" role="presentation" onMouseDown={e => { if (e.target === e.currentTarget) onClose(); }}>
    <section className="search-dialog" role="dialog" aria-modal="true" aria-label={s.search}>
      <div className="search-field"><Icon name="search"/><input ref={inputRef} value={query} onChange={e => setQuery(e.target.value)} placeholder={s.searchHint}/><button onClick={onClose} aria-label={s.close}>×</button></div>
      <div className="search-results">{results.length ? results.map(key => <button key={key} onClick={() => { navigate(`/${lang}/${pageSlugs[key]}`); onClose(); }}><span>{s.nav[key]}</span><small>{searchText[lang][key]}</small></button>) : <p>{s.noResults}</p>}</div>
    </section>
  </div>;
}

function Home({ lang }: { lang: Language }) {
  const s = strings[lang];
  return <>
    <section className="hero page-width">
      <div className="hero-copy"><h1>{s.heroTitle}</h1><p>{s.heroBody}</p><div className="hero-actions"><a className="button primary" href="/downloads/tiktok-live-companion-extension-0.5.0.zip" download><Icon name="download"/>{s.download}</a><Link className="button secondary" to={`/${lang}/installation`}><Icon name="external"/>{s.install}</Link></div><p className="compatibility"><span className="edge-dot"/><span className="chrome-dot"/>{s.compatibility}</p></div>
      <ProductMockup lang={lang}/>
    </section>
    <section className="why-band"><div className="page-width"><h2>{s.why}</h2><p>{s.whyBody}</p><div className="benefit-rail"><article><Icon name="monitor"/><h3>{s.local}</h3><p>{s.localBody}</p></article><article><Icon name="pulse"/><h3>{s.observable}</h3><p>{s.observableBody}</p></article><article><Icon name="caption"/><h3>{s.accessible}</h3><p>{s.accessibleBody}</p></article></div></div></section>
  </>;
}

function Installation({ lang }: { lang: Language }) {
  const de = lang === "de";
  const steps = de ? [["ZIP entpacken", "Lade die Erweiterung herunter und entpacke die ZIP-Datei."], ["Entwicklermodus aktivieren", "Öffne die Erweiterungsseite deines Browsers."], ["Entpackte Erweiterung laden", "Wähle den Ordner mit manifest.json."], ["TikTok-LIVE öffnen", "Öffne einen öffentlichen LIVE-Tab und das Seitenpanel."]] : [["Extract the ZIP", "Download and extract the extension package."], ["Enable developer mode", "Open your browser's extension page."], ["Load unpacked", "Select the folder containing manifest.json."], ["Open TikTok LIVE", "Open a public LIVE tab and the side panel."]];
  return <PageIntro title={de ? "In wenigen Minuten startklar" : "Ready in a few minutes"} lead={de ? "Die Erweiterung läuft lokal in Edge oder Chrome." : "The extension runs locally in Edge or Chrome."}>
    <div className="installation-layout"><ol className="step-rail">{steps.map(([title, body], index) => <li key={title} className={index === 2 ? "current" : ""}><span>{index + 1}</span><div><h2>{title}</h2><p>{body}</p></div></li>)}</ol><div className="extension-window"><div className="extension-toolbar">←　↻　 <strong>{de ? "Erweiterungen" : "Extensions"}</strong><span>{de ? "Entwicklermodus" : "Developer mode"}　<span className="toggle on"/></span></div><div className="extension-body"><button>{de ? "Erweiterung laden" : "Load extension"}</button><button className="focused">{de ? "Entpackte Erweiterung laden" : "Load unpacked"}</button><div className="installed-extension"><BrandMark/><div><strong>TikTok LIVE Companion　0.5.0</strong><p>{de ? "Untertitel prüfen, Hook setzen und LIVE-Informationen nutzen." : "Inspect captions, set the hook, and use LIVE information."}</p></div><span className="toggle on"/></div></div><aside><Icon name="link"/><strong>{de ? "Hook setzen, bevor der Player verbindet" : "Set the hook before the player connects"}</strong><p>{de ? "Der aktuelle Tab wird neu geladen. Cookies und Login bleiben erhalten." : "The current tab reloads. Cookies and login remain intact."}</p></aside></div></div>
    <Workflow lang={lang}/>
  </PageIntro>;
}

function Workflow({ lang }: { lang: Language }) {
  const labels = lang === "de" ? ["Seite prüfen", "Untertitel aktivieren", "Hook setzen", "Informationen nutzen", "JSONL exportieren"] : ["Inspect page", "Enable captions", "Set hook", "Use information", "Export JSONL"];
  return <div className="workflow" aria-label={lang === "de" ? "Arbeitsablauf" : "Workflow"}>{labels.map((label, i) => <div key={label}><span>{i + 1}</span><strong>{label}</strong>{i < labels.length - 1 && <b aria-hidden="true">→</b>}</div>)}</div>;
}

function Features({ lang }: { lang: Language }) {
  const [selected, setSelected] = useState(3);
  const items = featureData[lang];
  return <PageIntro title={lang === "de" ? "Funktionen im Detail" : "Features in detail"}>
    <div className="feature-layout"><div className="feature-tabs" role="tablist" aria-label={lang === "de" ? "Funktionsbereiche" : "Feature areas"}>{items.map(([title], index) => <button key={title} role="tab" aria-selected={selected === index} onClick={() => setSelected(index)}><Icon name={(["info", "caption", "info", "sound", "monitor", "pulse"] as const)[index]}/>{title}</button>)}</div><div className="feature-detail"><h2>{items[selected][0]}</h2><p>{items[selected][1]}</p>{selected === 3 && <div className="info-callout"><Icon name="info"/>{lang === "de" ? "dBFS ist kein kalibrierter dB-SPL-Wert." : "dBFS is not a calibrated dB SPL value."}</div>}</div><PlayerPanel lang={lang}/></div>
    <DownloadBand lang={lang}/>
  </PageIntro>;
}

function PlayerPanel({ lang }: { lang: Language }) {
  return <div className="player-panel" aria-label={lang === "de" ? "Player- und Pegelschutzdarstellung" : "Player and peak-protection illustration"}><div className="panel-title"><BrandMark/><strong>LIVE Companion</strong><span>—　×</span></div><small>PLAYER</small><div className="player-buttons"><button><Icon name="play"/></button><Icon name="sound"/><div className="slider"><span/></div><b>56%</b></div><hr/><small>{lang === "de" ? "PEGELSCHUTZ" : "PEAK PROTECTION"}</small><div className="meter-label"><span>{lang === "de" ? "Eingangspegel (dBFS)" : "Input level (dBFS)"}</span><b>-18.7 dBFS</b></div><div className="meter">{Array.from({ length: 32 }).map((_, i) => <i key={i} className={i < 20 ? "lit" : ""}/>)}</div>{["Kompressor", "Schwelle", "Ratio", "Attack", "Release"].map((x, i) => <div className="panel-setting" key={x}><span>{lang === "de" ? x : (["Compressor", "Threshold", "Ratio", "Attack", "Release"])[i]}</span><div className="setting-line"><i style={{ left: `${45 + i * 6}%` }}/></div><b>{["on", "-6 dBFS", "4:1", "5 ms", "120 ms"][i]}</b></div>)}</div>;
}

function Architecture({ lang }: { lang: Language }) {
  const de = lang === "de";
  const nodes = de ? [["TikTok-LIVE-Tab", "öffentliche DOM-/Metadaten"], ["content.js", "isolierte passive Prüfung"], ["WebSocket-Hook", "Nachrichten nur lesen"], ["background.js", "Filterung und Tab-Zustand"], ["storage.session", "flüchtig, keine Persistenz"], ["Seitenpanel", "sichere Textausgabe"]] : [["TikTok LIVE tab", "public DOM/metadata"], ["content.js", "isolated passive inspection"], ["WebSocket hook", "read messages only"], ["background.js", "filtering and tab state"], ["storage.session", "volatile, no persistence"], ["Side panel", "safe text output"]];
  return <PageIntro title={de ? "So bleiben Daten im Browser" : "How data stays in the browser"} lead={de ? "Beobachten statt verändern" : "Observe, never modify"}>
    <div className="architecture-flow">{nodes.map(([title, body], index) => <div className={`architecture-node node-${index}`} key={title}><Icon name={(["monitor", "info", "link", "pulse", "info", "caption"] as const)[index]}/><h2>{title}</h2><p>{body}</p>{index < nodes.length - 1 && <b aria-hidden="true">→</b>}</div>)}</div>
    <SecurityFacts lang={lang}/><div className="risk-band"><div><strong>{de ? "Wichtiger Hinweis" : "Important note"}</strong><p>{de ? "Signierte Stream-URLs sind zeitlich begrenzt und während ihrer Gültigkeit sensibel." : "Signed stream URLs are temporary and sensitive while valid."}</p></div><div><strong>{de ? "Einschränkung" : "Limitation"}</strong><p>{de ? "Beobachtungsprotokoll, kein kryptografisch authentifizierter Nachweis." : "Observational record, not cryptographically authenticated evidence."}</p></div></div>
  </PageIntro>;
}

function SecurityFacts({ lang }: { lang: Language }) {
  const facts = lang === "de" ? ["Keine Cookies", "Keine Telemetrie", "Keine API-Keys", "webRequest ohne Blocking", "textContent statt innerHTML"] : ["No cookies", "No telemetry", "No API keys", "webRequest without blocking", "textContent, not innerHTML"];
  return <div className="security-facts">{facts.map(f => <span key={f}><b>✓</b>{f}</span>)}</div>;
}

function Security({ lang }: { lang: Language }) {
  const de = lang === "de";
  const controls = de ? [["Berechtigungen", "activeTab, scripting, sidePanel, storage, tabs und passives webRequest; keine Cookie- oder Blocking-Berechtigung."], ["Speicherung", "Stream-Zustand, Captions, Chat und Diagnose bleiben in storage.session. Nur drei harmlose Einstellungen sind persistent."], ["Ausgabe", "Seitenwerte gelten als nicht vertrauenswürdig und werden ausschließlich mit textContent dargestellt."], ["Audio", "Sprachausgabe und DynamicsCompressorNode laufen lokal. dBFS ist kein physikalischer dB-SPL-Messwert."]] : [["Permissions", "activeTab, scripting, sidePanel, storage, tabs, and passive webRequest; no cookie or blocking permission."], ["Storage", "Stream state, captions, chat, and diagnostics remain in storage.session. Only three harmless settings persist."], ["Output", "Page values are untrusted and rendered exclusively with textContent."], ["Audio", "Speech and DynamicsCompressorNode run locally. dBFS is not a physical dB SPL measurement."]];
  return <PageIntro title={de ? "Sicherheit und Datenschutz" : "Security and privacy"} lead={de ? "Klare Grenzen statt verdeckter Datenflüsse." : "Clear boundaries instead of hidden data flows."}><SecurityFacts lang={lang}/><div className="security-list"><article><h2>{de ? "Formales Release-Gate" : "Formal release gate"}</h2><p>{de ? "Der vollständige Scan vom 17. Juli 2026 schloss alle neun Prüfumfänge: 0 kritische, hohe oder mittlere Findings und 2 validierte Low/P3-Restrisiken. Die unveränderten 0.5.0-Artefakte sind zur Veröffentlichung freigegeben." : "The complete scan on 17 July 2026 closed all nine review scopes: 0 critical, high, or medium findings and 2 validated Low/P3 residual risks. The unchanged 0.5.0 artifacts are cleared for publication."}</p></article>{controls.map(([title, body]) => <article key={title}><h2>{title}</h2><p>{body}</p></article>)}</div><div className="risk-band"><div><strong>{de ? "Restrisiko" : "Residual risk"}</strong><p>{de ? "Größenbudgets für Bridge-Objekte und dekomprimierte Nachrichten werden für eine Folgeversion verfolgt; Konto-, Cookie-, Secret- oder Cross-Origin-Zugriff wurde nicht nachgewiesen." : "Byte budgets for bridge objects and decompressed messages are tracked for a subsequent release; no account, cookie, secret, or cross-origin access was demonstrated."}</p></div><div><strong>{de ? "Veröffentlichungsregel" : "Publication rule"}</strong><p>{de ? "Öffentliche Berichte enthalten keine PoCs, Cookies, Chattexte oder gültigen Tokens." : "Public reports contain no PoCs, cookies, chat contents, or valid tokens."}</p></div></div></PageIntro>;
}

function Troubleshooting({ lang }: { lang: Language }) {
  const de = lang === "de";
  const items = de ? [["Keine CaptionMessages", "caption_info und Menüpunkt zeigen nur Verfügbarkeit. Hook vor der Player-Verbindung setzen und neu laden."], ["Hook bleibt getrennt", "Refresh löscht nur flüchtigen Tab-Zustand, registriert den Hook neu und lädt ohne Cache."], ["Playeraktion abgelehnt", "Bild-in-Bild, Vollbild und Web Audio können eine unmittelbare Nutzeraktion oder Browserunterstützung benötigen."], ["Keine VLC-Links", "Der Stream kann nur ein Protokoll oder keine extrahierbare URL liefern. Automatisch ist kein VLC-Link."], ["Diagnoseexport", "Debug nur bei Bedarf aktivieren. Der Export entfernt signierte Parameterwerte und enthält keinen Chattext."]] : [["No CaptionMessages", "caption_info and a menu item indicate availability only. Set the hook before player connection and reload."], ["Hook stays disconnected", "Refresh clears volatile tab state only, registers the hook again, and reloads without cache."], ["Player action rejected", "Picture-in-picture, fullscreen, and Web Audio may require immediate user activation or browser support."], ["No VLC links", "A stream may expose only one protocol or no extractable URL. Automatic is not a VLC link."], ["Diagnostic export", "Enable debug only when needed. Export removes signed parameter values and contains no chat text."]];
  return <PageIntro title={de ? "Fehlerbehebung" : "Troubleshooting"} lead={de ? "Häufige Zustände lassen sich ohne Cookie- oder Login-Löschung beheben." : "Common states can be resolved without clearing cookies or login."}><div className="faq-list">{items.map(([q, a], i) => <details key={q} open={i === 0}><summary>{q}<span>＋</span></summary><p>{a}</p></details>)}</div></PageIntro>;
}

function DownloadBand({ lang }: { lang: Language }) {
  const de = lang === "de";
  return <section className="download-band"><h2>Version 0.5.0</h2><a className="button primary" href="/downloads/tiktok-live-companion-extension-0.5.0.zip" download><Icon name="download"/>{de ? "Erweiterung ZIP" : "Extension ZIP"}</a><a className="button secondary" href="/downloads/tiktok-live-companion-plugin-0.5.0.zip" download><Icon name="link"/>{de ? "Codex-Plugin ZIP" : "Codex plugin ZIP"}</a><a className="button secondary" href="/downloads/tiktok-live-companion-0.5.0-SHA256.txt" download><Icon name="info"/>{de ? "SHA-256 prüfen" : "Verify SHA-256"}</a></section>;
}

function Downloads({ lang }: { lang: Language }) {
  const de = lang === "de";
  const [copied, setCopied] = useState(false);
  const hashes = "9439e21db0e8fc2e874a478079d1243297d4c95e0dbb140795912f75eb250b02  tiktok-live-companion-extension-0.5.0.zip\na99fdfb14cd0effac4f89468758258e073dc75ed0f59763bc9764c4c380088a0  tiktok-live-companion-plugin-0.5.0.zip";
  return <PageIntro title={de ? "Downloads und Release 0.5.0" : "Downloads and release 0.5.0"} lead={de ? "Unveränderte Artefakte mit nachvollziehbaren Integritätswerten." : "Unchanged artifacts with verifiable integrity values."}><DownloadBand lang={lang}/><div className="hash-block"><div><h2>SHA-256</h2><button onClick={async () => { await navigator.clipboard?.writeText(hashes); setCopied(true); }}>{copied ? (de ? "Kopiert" : "Copied") : (de ? "Prüfsummen kopieren" : "Copy checksums")}</button></div><pre>{hashes}</pre></div><section className="release-notes"><h2>{de ? "Änderungen" : "What's new"}</h2><p>{de ? "Version 0.5.0 bündelt zugänglichen Chat, lokale Sprachausgabe, erweiterte LIVE-Werte, Player- und dBFS-Steuerung, Qualitätswechsel, Mehrgast-Erkennung, Autostart, vollständigen Tab-Refresh und bereinigte Diagnosen." : "Version 0.5.0 combines accessible chat, local speech, expanded LIVE values, player and dBFS controls, quality selection, multi-guest detection, auto-hook, full tab refresh, and sanitized diagnostics."}</p></section></PageIntro>;
}

function PageIntro({ title, lead, children }: { title: string; lead?: string; children: ReactNode }) {
  return <main className="page-width content-page"><h1>{title}</h1>{lead && <p className="page-lead">{lead}</p>}{children}</main>;
}

function Footer({ lang }: { lang: Language }) {
  const s = strings[lang];
  return <footer><div className="page-width"><div className="brand footer-brand"><BrandMark/><span>TikTok <b>LIVE</b> Companion</span></div><p>{s.independent}</p><div><Link to={`/${lang}/troubleshooting`}>{s.nav.troubleshooting}</Link><Link to={`/${lang}/downloads`}>{s.nav.downloads}</Link><a href="https://github.com/KikiKari/Projects/tree/TikTok-Live-Companion">GitHub</a><a href="https://linear.app/0penclaw/project/tiktok-live-companion-ed2f087b24bc">Linear</a><a href="https://app.notion.com/p/3a18d8ad3db9817f882bd79682fbbc51">Notion</a></div></div></footer>;
}

function parsePath(pathname: string): { lang: Language; page: PageKey } | null {
  const parts = pathname.replace(/^\/+|\/+$/g, "").split("/");
  const lang = parts[0] as Language;
  if (lang !== "de" && lang !== "en") return null;
  const slug = parts[1] || "";
  const page = pageOrder.find(key => pageSlugs[key] === slug);
  return page ? { lang, page } : null;
}

export default function App() {
  const location = useLocation();
  const parsed = parsePath(location.pathname);
  const [searchOpen, setSearchOpen] = useState(false);
  useEffect(() => { const onKey = (event: KeyboardEvent) => { if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k") { event.preventDefault(); setSearchOpen(true); } if (event.key === "Escape") setSearchOpen(false); }; window.addEventListener("keydown", onKey); return () => window.removeEventListener("keydown", onKey); }, []);
  useEffect(() => { window.scrollTo(0, 0); }, [location.pathname]);
  if (!parsed) return <Navigate to="/de" replace/>;
  const { lang, page } = parsed;
  const components: Record<PageKey, ReactNode> = { overview: <Home lang={lang}/>, installation: <Installation lang={lang}/>, features: <Features lang={lang}/>, architecture: <Architecture lang={lang}/>, security: <Security lang={lang}/>, troubleshooting: <Troubleshooting lang={lang}/>, downloads: <Downloads lang={lang}/> };
  return <><a className="skip-link" href="#main-content">{strings[lang].skip}</a><Header lang={lang} page={page} onSearch={() => setSearchOpen(true)}/><div id="main-content" tabIndex={-1}>{components[page]}</div><Footer lang={lang}/><SearchDialog lang={lang} open={searchOpen} onClose={() => setSearchOpen(false)}/></>;
}

