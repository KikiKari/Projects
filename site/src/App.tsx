import { lazy, Suspense, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { Link, Navigate, useLocation, useNavigate } from "react-router-dom";
import { featureData, pageSlugs, searchText, strings, type Language, type PageKey } from "./content";

const pageOrder = Object.keys(pageSlugs) as PageKey[];
const Architecture3D = lazy(() => import("./Architecture3D"));

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
      <div className="hero-copy"><h1>{s.heroTitle}</h1><p>{s.heroBody}</p><div className="hero-actions"><a className="button primary" href="/downloads/tiktok-live-companion-extension-0.7.1.zip" download><Icon name="download"/>{s.download}</a><Link className="button secondary" to={`/${lang}/installation`}><Icon name="external"/>{s.install}</Link></div><p className="compatibility"><span className="edge-dot"/><span className="chrome-dot"/>{s.compatibility}</p></div>
      <ProductMockup lang={lang}/>
    </section>
    <section className="why-band"><div className="page-width"><h2>{s.why}</h2><p>{s.whyBody}</p><div className="benefit-rail"><article><Icon name="monitor"/><h3>{s.local}</h3><p>{s.localBody}</p></article><article><Icon name="pulse"/><h3>{s.observable}</h3><p>{s.observableBody}</p></article><article><Icon name="caption"/><h3>{s.accessible}</h3><p>{s.accessibleBody}</p></article></div></div></section>
    <PlatformMatrix lang={lang}/>
  </>;
}

function PlatformMatrix({ lang }: { lang: Language }) {
  const de = lang === "de";
  const platforms = de ? [
    ["Edge & Chrome", "Manifest V3 · AudD", "Vollständiges Seitenpanel und manueller 12-Sekunden-Audioausschnitt über den lokalen Windows-Dienst."],
    ["iOS 15+", "SwiftUI · WKWebView · ShazamKit", "Mikrofon als stabiler Erkennungsweg; WebView-Audio ist experimentell und fällt transparent zurück."],
    ["Android & HyperOS", "Compose · AndroidX WebKit · ShazamKit", "Android-Standard-APIs ohne Google-Play-Services-Abhängigkeit; ShazamKit-AAR wird separat bezogen."]
  ] : [
    ["Edge & Chrome", "Manifest V3 · AudD", "Full side panel and a manually initiated twelve-second audio clip through the local Windows service."],
    ["iOS 15+", "SwiftUI · WKWebView · ShazamKit", "Microphone is the stable recognition path; experimental WebView audio falls back transparently."],
    ["Android & HyperOS", "Compose · AndroidX WebKit · ShazamKit", "Standard Android APIs without a Google Play Services dependency; obtain the ShazamKit AAR separately."]
  ];
  return <section className="platform-section page-width"><h2>{de ? "Version 0.7.0 auf drei Plattformen" : "Version 0.7.0 across three platforms"}</h2><p>{de ? "Eine Oberfläche, plattformspezifische und klar ausgewiesene Audiowege." : "One interface with platform-specific, clearly identified audio paths."}</p><div className="platform-grid">{platforms.map(([name, stack, body]) => <article key={name}><Icon name="monitor"/><h3>{name}</h3><strong>{stack}</strong><p>{body}</p></article>)}</div></section>;
}

function Installation({ lang }: { lang: Language }) {
  const de = lang === "de";
  const steps = de ? [["ZIP entpacken", "Lade die Erweiterung herunter und entpacke die ZIP-Datei."], ["Entwicklermodus aktivieren", "Öffne die Erweiterungsseite deines Browsers."], ["Entpackte Erweiterung laden", "Wähle den Ordner mit manifest.json."], ["TikTok-LIVE öffnen", "Öffne einen öffentlichen LIVE-Tab und das Seitenpanel."]] : [["Extract the ZIP", "Download and extract the extension package."], ["Enable developer mode", "Open your browser's extension page."], ["Load unpacked", "Select the folder containing manifest.json."], ["Open TikTok LIVE", "Open a public LIVE tab and the side panel."]];
  return <PageIntro title={de ? "In wenigen Minuten startklar" : "Ready in a few minutes"} lead={de ? "Die Erweiterung läuft lokal in Edge oder Chrome." : "The extension runs locally in Edge or Chrome."}>
    <div className="installation-layout"><ol className="step-rail">{steps.map(([title, body], index) => <li key={title} className={index === 2 ? "current" : ""}><span>{index + 1}</span><div><h2>{title}</h2><p>{body}</p></div></li>)}</ol><div className="extension-window"><div className="extension-toolbar">←　↻　 <strong>{de ? "Erweiterungen" : "Extensions"}</strong><span>{de ? "Entwicklermodus" : "Developer mode"}　<span className="toggle on"/></span></div><div className="extension-body"><button>{de ? "Erweiterung laden" : "Load extension"}</button><button className="focused">{de ? "Entpackte Erweiterung laden" : "Load unpacked"}</button><div className="installed-extension"><BrandMark/><div><strong>TikTok LIVE Companion　0.7.1</strong><p>{de ? "Chat vorlesen, Zuschauer beobachten und LIVE-Informationen nutzen." : "Speak chat, observe participants, and use LIVE information."}</p></div><span className="toggle on"/></div></div><aside><Icon name="link"/><strong>{de ? "Hook setzen, bevor der Player verbindet" : "Set the hook before the player connects"}</strong><p>{de ? "Der aktuelle Tab wird neu geladen. Cookies und Login bleiben erhalten." : "The current tab reloads. Cookies and login remain intact."}</p></aside></div></div>
    <Workflow lang={lang}/>
  </PageIntro>;
}

function Workflow({ lang }: { lang: Language }) {
  const labels = lang === "de" ? ["Seite prüfen", "Untertitel aktivieren", "Hook setzen", "Informationen nutzen", "JSONL exportieren"] : ["Inspect page", "Enable captions", "Set hook", "Use information", "Export JSONL"];
  return <div className="workflow" aria-label={lang === "de" ? "Arbeitsablauf" : "Workflow"}>{labels.map((label, i) => <div key={label}><span>{i + 1}</span><strong>{label}</strong>{i < labels.length - 1 && <b aria-hidden="true">→</b>}</div>)}</div>;
}

function Features({ lang }: { lang: Language }) {
  const [selected, setSelected] = useState(4);
  const items = featureData[lang];
  return <PageIntro title={lang === "de" ? "Funktionen im Detail" : "Features in detail"}>
    <div className="feature-layout"><div className="feature-tabs" role="tablist" aria-label={lang === "de" ? "Funktionsbereiche" : "Feature areas"}>{items.map(([title], index) => <button key={title} role="tab" aria-selected={selected === index} onClick={() => setSelected(index)}><Icon name={(["sound", "pulse", "caption", "info", "monitor", "pulse", "info"] as const)[index]}/>{title}</button>)}</div><div className="feature-detail"><h2>{items[selected][0]}</h2><p>{items[selected][1]}</p>{selected === 4 && <div className="info-callout"><Icon name="info"/>{lang === "de" ? "dBFS ist kein kalibrierter dB-SPL-Wert." : "dBFS is not a calibrated dB SPL value."}</div>}</div><PlayerPanel lang={lang}/></div>
    <DownloadBand lang={lang}/>
  </PageIntro>;
}

function PlayerPanel({ lang }: { lang: Language }) {
  return <div className="player-panel" aria-label={lang === "de" ? "Player- und Pegelschutzdarstellung" : "Player and peak-protection illustration"}><div className="panel-title"><BrandMark/><strong>LIVE Companion</strong><span>—　×</span></div><small>PLAYER</small><div className="player-buttons"><button><Icon name="play"/></button><Icon name="sound"/><div className="slider"><span/></div><b>56%</b></div><hr/><small>{lang === "de" ? "PEGELSCHUTZ" : "PEAK PROTECTION"}</small><div className="meter-label"><span>{lang === "de" ? "Eingangspegel (dBFS)" : "Input level (dBFS)"}</span><b>-18.7 dBFS</b></div><div className="meter">{Array.from({ length: 32 }).map((_, i) => <i key={i} className={i < 20 ? "lit" : ""}/>)}</div>{["Kompressor", "Schwelle", "Ratio", "Attack", "Release"].map((x, i) => <div className="panel-setting" key={x}><span>{lang === "de" ? x : (["Compressor", "Threshold", "Ratio", "Attack", "Release"])[i]}</span><div className="setting-line"><i style={{ left: `${45 + i * 6}%` }}/></div><b>{["on", "-6 dBFS", "4:1", "5 ms", "120 ms"][i]}</b></div>)}</div>;
}

function Architecture({ lang }: { lang: Language }) {
  const de = lang === "de";
  const nodes = de ? [["TikTok-LIVE-Tab", "öffentliche DOM-/Metadaten"], ["content.js", "isolierte passive Prüfung"], ["WebSocket-Hook", "Nachrichten nur lesen"], ["background.js", "Filterung und Streamzustand"], ["Browser-Speicher", "Streamdaten flüchtig, Einstellungen lokal"], ["Seitenpanel", "sichere Text- und Audioausgabe"]] : [["TikTok LIVE tab", "public DOM/metadata"], ["content.js", "isolated passive inspection"], ["WebSocket hook", "read messages only"], ["background.js", "filtering and stream state"], ["Browser storage", "volatile stream data, local settings"], ["Side panel", "safe text and audio output"]];
  return <PageIntro title={de ? "So bleiben Daten im Browser" : "How data stays in the browser"} lead={de ? "Beobachten statt verändern" : "Observe, never modify"}>
    <div className="architecture-flow">{nodes.map(([title, body], index) => <div className={`architecture-node node-${index}`} key={title}><Icon name={(["monitor", "info", "link", "pulse", "info", "caption"] as const)[index]}/><h2>{title}</h2><p>{body}</p>{index < nodes.length - 1 && <b aria-hidden="true">→</b>}</div>)}</div>
    <section className="architecture-visualization"><img src="/visualizations/tiktok-live-companion-architecture.svg" alt={de ? "Plattformarchitektur für Browser, iOS und Android/HyperOS" : "Platform architecture for browser, iOS, and Android/HyperOS"}/><div><p className="eyebrow">THREE.JS · SVG · GIF</p><h2>{de ? "Architektur interaktiv erkunden" : "Explore the architecture interactively"}</h2><p>{de ? "Die 3D-Ansicht, das SVG und das GIF werden aus demselben projektspezifischen Datenmodell erzeugt." : "The 3D view, SVG, and GIF are generated from the same project-specific data model."}</p><Link className="button primary" to={`/${lang}/architecture-3d`}>{de ? "3D-Ansicht öffnen" : "Open 3D view"}</Link><a className="architecture-gif-link" href="/visualizations/tiktok-live-companion-architecture.gif">GIF</a></div></section>
    <SecurityFacts lang={lang}/><PlatformMatrix lang={lang}/><div className="risk-band"><div><strong>{de ? "Wichtiger Hinweis" : "Important note"}</strong><p>{de ? "Signierte Stream-URLs sind zeitlich begrenzt und während ihrer Gültigkeit sensibel." : "Signed stream URLs are temporary and sensitive while valid."}</p></div><div><strong>{de ? "Einschränkung" : "Limitation"}</strong><p>{de ? "Beobachtungsprotokoll, kein kryptografisch authentifizierter Nachweis." : "Observational record, not cryptographically authenticated evidence."}</p></div></div>
  </PageIntro>;
}

function SecurityFacts({ lang }: { lang: Language }) {
  const facts = lang === "de" ? ["Keine Cookies", "Keine Telemetrie", "AudD nur nach Klick", "webRequest ohne Blocking", "textContent statt innerHTML"] : ["No cookies", "No telemetry", "AudD only after a click", "webRequest without blocking", "textContent, not innerHTML"];
  return <div className="security-facts">{facts.map(f => <span key={f}><b>✓</b>{f}</span>)}</div>;
}

function Security({ lang }: { lang: Language }) {
  const de = lang === "de";
  const controls = de ? [["Berechtigungen", "activeTab, scripting, sidePanel, storage, tabs, tabCapture und passives webRequest; keine Cookie- oder Blocking-Berechtigung."], ["Speicherung", "Stream-Zustand, Chat und beobachtete Personen bleiben flüchtig. Einstellungen und dauerhafte Mutes liegen lokal im Browser; AudD-Zugangsdaten nur in der Dienstkonfiguration."], ["Ausgabe", "Seitenwerte gelten als nicht vertrauenswürdig und werden ausschließlich mit textContent dargestellt."], ["Audio", "Browser-TTS bleibt lokal. Nur eine manuell gestartete zwölfsekündige Songerkennung sendet Audio über den gepaarten Loopback-Dienst an AudD."]] : [["Permissions", "activeTab, scripting, sidePanel, storage, tabs, tabCapture, and passive webRequest; no cookie or blocking permission."], ["Storage", "Stream state, chat, and observed people remain volatile. Settings and permanent mutes stay in browser-local storage; AudD credentials live only in the service configuration."], ["Output", "Page values are untrusted and rendered exclusively with textContent."], ["Audio", "Browser speech remains local. Only a manually started twelve-second recognition sends audio to AudD through the paired loopback service."]];
  return <PageIntro title={de ? "Sicherheit und Datenschutz" : "Security and privacy"} lead={de ? "Klare Grenzen statt verdeckter Datenflüsse." : "Clear boundaries instead of hidden data flows."}><SecurityFacts lang={lang}/><div className="security-list"><article><h2>{de ? "Release-Prüfung 0.7.0" : "0.7.0 release review"}</h2><p>{de ? "Die neue Prüfung umfasst zusätzlich Mobile-WebView-Bridges, ShazamKit-Audio und den Token-Endpunkt. Nicht verifizierte Plattformbuilds werden ausdrücklich gekennzeichnet." : "The new review additionally covers mobile WebView bridges, ShazamKit audio, and the token endpoint. Unverified platform builds are explicitly identified."}</p></article>{controls.map(([title, body]) => <article key={title}><h2>{title}</h2><p>{body}</p></article>)}</div><div className="risk-band"><div><strong>{de ? "Externe Übertragung" : "External transfer"}</strong><p>{de ? "AudD erhält im Browser nur nach Klick den kurzen Audioausschnitt; native Apps senden nicht das Audio, sondern ShazamKit-Signaturen an Apples Katalogdienst." : "In the browser, AudD receives the short clip only after a click; native apps use ShazamKit signatures with Apple's catalog service rather than uploading the audio."}</p></div><div><strong>{de ? "Mobile Bridge" : "Mobile bridge"}</strong><p>{de ? "Nur Hauptframe-Nachrichten von https://www.tiktok.com und bekannte Nachrichtentypen werden akzeptiert." : "Only main-frame messages from https://www.tiktok.com with known message types are accepted."}</p></div></div></PageIntro>;
}

function Troubleshooting({ lang }: { lang: Language }) {
  const de = lang === "de";
  const items = de ? [["Keine CaptionMessages", "caption_info und Menüpunkt zeigen nur Verfügbarkeit. Hook vor der Player-Verbindung setzen und neu laden."], ["Hook bleibt getrennt", "Refresh löscht nur flüchtigen Tab-Zustand, registriert den Hook neu und lädt ohne Cache."], ["Playeraktion abgelehnt", "Bild-in-Bild, Vollbild und Web Audio können eine unmittelbare Nutzeraktion oder Browserunterstützung benötigen."], ["Keine VLC-Links", "Der Stream kann nur ein Protokoll oder keine extrahierbare URL liefern. Automatisch ist kein VLC-Link."], ["Diagnoseexport", "Debug nur bei Bedarf aktivieren. Der Export entfernt signierte Parameterwerte und enthält keinen Chattext."]] : [["No CaptionMessages", "caption_info and a menu item indicate availability only. Set the hook before player connection and reload."], ["Hook stays disconnected", "Refresh clears volatile tab state only, registers the hook again, and reloads without cache."], ["Player action rejected", "Picture-in-picture, fullscreen, and Web Audio may require immediate user activation or browser support."], ["No VLC links", "A stream may expose only one protocol or no extractable URL. Automatic is not a VLC link."], ["Diagnostic export", "Enable debug only when needed. Export removes signed parameter values and contains no chat text."]];
  return <PageIntro title={de ? "Fehlerbehebung" : "Troubleshooting"} lead={de ? "Häufige Zustände lassen sich ohne Cookie- oder Login-Löschung beheben." : "Common states can be resolved without clearing cookies or login."}><div className="faq-list">{items.map(([q, a], i) => <details key={q} open={i === 0}><summary>{q}<span>＋</span></summary><p>{a}</p></details>)}</div></PageIntro>;
}

function DownloadBand({ lang }: { lang: Language }) {
  const de = lang === "de";
  return <section className="download-band"><h2>{de ? "Browser-Erweiterung 0.7.1 · weitere Pakete 0.7.0" : "Browser extension 0.7.1 · other packages 0.7.0"}</h2><a className="button primary" href="/downloads/tiktok-live-companion-extension-0.7.1.zip" download><Icon name="download"/>{de ? "Erweiterung ZIP" : "Extension ZIP"}</a><a className="button secondary" href="/downloads/tiktok-live-companion-plugin-0.7.0.zip" download><Icon name="link"/>{de ? "Codex-Plugin ZIP" : "Codex plugin ZIP"}</a><a className="button secondary" href="/downloads/tiktok-live-companion-service-0.7.0.zip" download><Icon name="sound"/>{de ? "Windows-Dienst ZIP" : "Windows service ZIP"}</a><a className="button secondary" href="/downloads/tiktok-live-companion-ios-0.7.0-source.zip" download><Icon name="monitor"/>{de ? "iOS-Quellprojekt" : "iOS source project"}</a><a className="button secondary" href="/downloads/tiktok-live-companion-android-0.7.0-source.zip" download><Icon name="monitor"/>{de ? "Android-/HyperOS-Quelle" : "Android/HyperOS source"}</a><a className="button secondary" href="/downloads/tiktok-live-companion-android-0.7.0-debug.apk" download><Icon name="download"/>{de ? "Android-Test-APK" : "Android test APK"}</a><a className="button secondary" href="/downloads/tiktok-live-companion-0.7.1-SHA256.txt" download><Icon name="info"/>{de ? "SHA-256 prüfen" : "Verify SHA-256"}</a></section>;
}

function Downloads({ lang }: { lang: Language }) {
  const de = lang === "de";
  const [copied, setCopied] = useState(false);
  const hashes = "35ae386bfe37a68e9b3afabb5dc3c5199457669b62f9878e732ad2af97154f9d  tiktok-live-companion-extension-0.7.1.zip\n4644ebf46bbd363edd499a16afc49b9ac7fa2c5cf03a1bae5149614ccbefb3b9  tiktok-live-companion-plugin-0.7.0.zip\n4bb5df40229c72a0e93ab822709182542d31846cc865f89962da3769e652fd1c  tiktok-live-companion-service-0.7.0.zip\n3b833ea2969487ea9a82571478a4f273f3e678cffb6a11bde51e94ee0e5bbff3  tiktok-live-companion-ios-0.7.0-source.zip\n62e57e5d901ffb581fc40dc8a47454fb7e46531c57ffdbd71b82b071f76ad594  tiktok-live-companion-android-0.7.0-source.zip\n00f8df107107661c5bb6204f0fedb9d1f485fdbe5085f19f27e0f8089481d0f5  tiktok-live-companion-android-0.7.0-debug.apk";
  return <PageIntro title={de ? "Downloads · Browser-Erweiterung 0.7.1" : "Downloads · Browser extension 0.7.1"} lead={de ? "Browser-, Dienst- und Mobile-Quellartefakte mit nachvollziehbaren Integritätswerten." : "Browser, service, and mobile-source artifacts with verifiable integrity values."}><DownloadBand lang={lang}/><div className="hash-block"><div><h2>SHA-256</h2><button onClick={async () => { await navigator.clipboard?.writeText(hashes); setCopied(true); }}>{copied ? (de ? "Kopiert" : "Copied") : (de ? "Prüfsummen kopieren" : "Copy checksums")}</button></div><pre>{hashes}</pre></div><section className="release-notes"><h2>{de ? "Änderungen" : "What's new"}</h2><p>{de ? "Browser-Erweiterung 0.7.1 erkennt Untertitelstatus und gemeldete Sprachen direkt aus echten LIVE-Untertitelereignissen, auch wenn TikTok keine caption_info-Metadaten liefert. Mobile, Dienst und Codex-Plugin bleiben unverändert auf 0.7.0." : "Browser extension 0.7.1 derives caption status and reported languages directly from real LIVE caption events, even when TikTok provides no caption_info metadata. Mobile, service, and Codex plugin remain unchanged at 0.7.0."}</p></section></PageIntro>;
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
  const architecture3DMatch = location.pathname.match(/^\/(de|en)\/architecture-3d\/?$/);
  const [searchOpen, setSearchOpen] = useState(false);
  useEffect(() => { const onKey = (event: KeyboardEvent) => { if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k") { event.preventDefault(); setSearchOpen(true); } if (event.key === "Escape") setSearchOpen(false); }; window.addEventListener("keydown", onKey); return () => window.removeEventListener("keydown", onKey); }, []);
  useEffect(() => { window.scrollTo(0, 0); }, [location.pathname]);
  if (architecture3DMatch) {
    const lang = architecture3DMatch[1] as Language;
    return <Suspense fallback={<main className="page-width content-page"><h1>{lang === "de" ? "3D-Architektur wird geladen" : "Loading 3D architecture"}</h1></main>}><Architecture3D lang={lang}/></Suspense>;
  }
  if (!parsed) return <Navigate to="/de" replace/>;
  const { lang, page } = parsed;
  const components: Record<PageKey, ReactNode> = { overview: <Home lang={lang}/>, installation: <Installation lang={lang}/>, features: <Features lang={lang}/>, architecture: <Architecture lang={lang}/>, security: <Security lang={lang}/>, troubleshooting: <Troubleshooting lang={lang}/>, downloads: <Downloads lang={lang}/> };
  return <><a className="skip-link" href="#main-content">{strings[lang].skip}</a><Header lang={lang} page={page} onSearch={() => setSearchOpen(true)}/><div id="main-content" tabIndex={-1}>{components[page]}</div><Footer lang={lang}/><SearchDialog lang={lang} open={searchOpen} onClose={() => setSearchOpen(false)}/></>;
}
