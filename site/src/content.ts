export type Language = "de" | "en";
export type PageKey = "overview" | "installation" | "features" | "architecture" | "security" | "troubleshooting" | "downloads";

export const pageSlugs: Record<PageKey, string> = {
  overview: "",
  installation: "installation",
  features: "features",
  architecture: "architecture",
  security: "security",
  troubleshooting: "troubleshooting",
  downloads: "downloads"
};

export const strings = {
  de: {
    nav: { overview: "Überblick", installation: "Installation", features: "Funktionen", architecture: "Architektur", security: "Sicherheit", troubleshooting: "Fehlerbehebung", downloads: "Downloads" },
    search: "Dokumentation durchsuchen", searchHint: "Titel oder Thema eingeben", noResults: "Keine passenden Inhalte gefunden.", skip: "Zum Inhalt springen",
    heroTitle: "Öffentliche TikTok-LIVE-Streams zugänglicher nutzen",
    heroBody: "Chat lesen und lokal vorlesen, native Untertitel prüfen, Player steuern und Stream-Informationen verstehen – direkt im Browser.",
    download: "Version 0.7.0 herunterladen", install: "Installation öffnen", compatibility: "Edge & Chrome · Manifest V3 · optionaler lokaler Windows-Dienst",
    why: "Warum TikTok LIVE Companion?", whyBody: "Funktionen, die das Seherlebnis verbessern und Barrierefreiheit fördern.",
    local: "Lokal im Browser", localBody: "Keine Cookies, Telemetrie oder externen Analysedienste.",
    observable: "Beobachten statt verändern", observableBody: "Passive Ereignis- und CDN-Beobachtung ohne Request-Blocking.",
    accessible: "Zugängliche Bedienung", accessibleBody: "Textausgabe, Tastatursteuerung, lokale Sprachausgabe und klare Statussignale.",
    independent: "Nicht mit TikTok verbunden oder von TikTok unterstützt.", language: "Sprache", close: "Schließen"
  },
  en: {
    nav: { overview: "Overview", installation: "Installation", features: "Features", architecture: "Architecture", security: "Security", troubleshooting: "Troubleshooting", downloads: "Downloads" },
    search: "Search documentation", searchHint: "Enter a title or topic", noResults: "No matching content found.", skip: "Skip to content",
    heroTitle: "Make public TikTok LIVE streams more accessible",
    heroBody: "Read chat and hear it locally, inspect native captions, control the player, and understand stream information – directly in your browser.",
    download: "Download version 0.7.0", install: "Open installation", compatibility: "Edge & Chrome · Manifest V3 · optional local Windows service",
    why: "Why TikTok LIVE Companion?", whyBody: "Features that improve the viewing experience and support accessibility.",
    local: "Local in the browser", localBody: "No cookies, telemetry, or external analytics services.",
    observable: "Observe, never modify", observableBody: "Passive event and CDN observation without request blocking.",
    accessible: "Accessible controls", accessibleBody: "Text output, keyboard controls, local speech, and clear status signals.",
    independent: "Not affiliated with or endorsed by TikTok.", language: "Language", close: "Close"
  }
} as const;

export const featureData = {
  de: [
    ["Chat, Top-Chatter & Vorlesen", "Teamkürzel, Empfänger und Fragen werden natürlich verarbeitet. Sonderzeichen und Zahlen entfallen in der Namensansage, lange user-Namen werden begrenzt und Lachspam wird zu haha. Top-Chatter, Mutes und beobachtete Personen bleiben pro Stream lokal."],
    ["Optionale Songerkennung", "Nur nach einem Klick wird ein kurzer Tab-Audioausschnitt über den lokalen Dienst an AudD gesendet."],
    ["Untertitel", "caption_info, sichtbarer Menüpunkt und empfangene CaptionMessages werden als getrennte Signale erklärt."],
    ["LIVE-Informationen", "Zuschauerzahl, Aufrufe, Likes, Follows und Teilungen stammen aus beobachteten Webcast-Ereignissen."],
    ["Player & Pegelschutz", "Wiedergabe, Lautstärke, Stumm, Bild-in-Bild und Vollbild steuern. Der optionale Kompressor begrenzt digitale Spitzen lokal."],
    ["Bildqualität & VLC", "Verfügbare Qualitätsstufen wählen und zeitlich begrenzte FLV- oder HLS-Links kopieren."],
    ["Diagnose", "Bereinigte Diagnoseereignisse exportieren, ohne Chattext, Cookies, API-Keys oder signierte Parameterwerte."]
  ],
  en: [
    ["Chat, top chatters & speech", "Team tags, recipients, and questions are prepared naturally. Spoken names omit punctuation and digits, long user names are bounded, and laughter spam becomes haha. Top chatters, mutes, and observed people stay local to each stream."],
    ["Optional song recognition", "Only after a click is a short tab-audio clip sent to AudD through the local service."],
    ["Captions", "caption_info, a visible menu item, and received CaptionMessages are presented as separate signals."],
    ["LIVE information", "Viewer count, total views, likes, follows, and shares come from observed Webcast events."],
    ["Player & peak protection", "Control playback, volume, mute, picture-in-picture, and fullscreen. The optional compressor limits digital peaks locally."],
    ["Quality & VLC", "Select available quality levels and copy temporary FLV or HLS links."],
    ["Diagnostics", "Export sanitized diagnostics without chat text, cookies, API keys, or signed parameter values."]
  ]
} as const;

export const searchText: Record<Language, Record<PageKey, string>> = {
  de: {
    overview: "Überblick zugänglicher Chat Vorlesen Untertitel Player Stream lokal",
    installation: "Installation Edge Chrome Entwicklermodus entpackte Erweiterung Hook Refresh",
    features: "Funktionen Chat Vorlesen Caption LIVE Player dBFS Qualität VLC Diagnose",
    architecture: "Architektur content WebSocket background storage session Seitenpanel Mermaid",
    security: "Sicherheit Datenschutz Cookies Telemetrie webRequest textContent Restrisiken",
    troubleshooting: "Fehlerbehebung Caption Hook Player VLC Debug",
    downloads: "Downloads Release ZIP SHA-256 Prüfsumme 0.7.0"
  },
  en: {
    overview: "Overview accessible chat speech captions player stream local",
    installation: "Installation Edge Chrome developer mode unpacked extension hook refresh",
    features: "Features chat speech top chatters mute song recognition caption LIVE player dBFS quality VLC diagnostics",
    architecture: "Architecture content WebSocket background storage session side panel Mermaid",
    security: "Security privacy cookies telemetry webRequest textContent residual risks",
    troubleshooting: "Troubleshooting caption hook player VLC debug",
    downloads: "Downloads release ZIP SHA-256 checksum 0.7.0"
  }
};
