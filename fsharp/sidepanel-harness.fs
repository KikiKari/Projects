// abstraction-provenance: {"artifact_sha256": "715c7ea0d448c207deb49408f11585ba917abe6b269e7bc6d3a732c6e905ed75", "source_sha256": "4159b73c8ded244c9ae43694ca2c07c881918152d298b40260e15287bef2606f", "target_language": "fsharp"}
// sidepanel-harness.html — portiert nach fsharp
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/sidepanel-harness.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

// Portierung von sidepanel-harness.html nach F#
// Erzeugt ein HTML-Dokument mit Testumgebung für Sidepanel

open System
open System.IO
open System.Text

/// Erstellt das HTML-Dokument für den Sidepanel-Test
let createSidepanelHarness () =
    let sb = StringBuilder()
    
    // HTML-Kopf und grundlegende Struktur
    sb.AppendLine("<!doctype html>") |> ignore
    sb.AppendLine("<html lang=\"de\">") |> ignore
    sb.AppendLine("<head>") |> ignore
    sb.AppendLine("  <meta charset=\"utf-8\">") |> ignore
    sb.AppendLine("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">") |> ignore
    sb.AppendLine("  <title>Sidepanel Test Harness</title>") |> ignore
    sb.AppendLine("</head>") |> ignore
    sb.AppendLine("<body>") |> ignore
    
    // Test-Szenarien für Caption
    sb.AppendLine("  <label>Caption-Testzustand") |> ignore
    sb.AppendLine("    <select id=\"test-caption-scenario\">") |> ignore
    sb.AppendLine("      <option value=\"metadata\">Seitenmetadaten</option>") |> ignore
    sb.AppendLine("      <option value=\"mixed\">DOM und WebSocket aktuell</option>") |> ignore
    sb.AppendLine("      <option value=\"historical\">Nur historische Captions</option>") |> ignore
    sb.AppendLine("      <option value=\"none\">Keine Captions</option>") |> ignore
    sb.AppendLine("    </select>") |> ignore
    sb.AppendLine("  </label>") |> ignore
    
    // Test-Szenarien für Embed
    sb.AppendLine("  <label>Embed-Testzustand") |> ignore
    sb.AppendLine("    <select id=\"test-embed-scenario\">") |> ignore
    sb.AppendLine("      <option value=\"loading\">Startet</option>") |> ignore
    sb.AppendLine("      <option value=\"retry-wait\">Serverfehler – Wiederanlauf</option>") |> ignore
    sb.AppendLine("      <option value=\"awaiting-gesture\">Benutzeraktion nötig</option>") |> ignore
    sb.AppendLine("      <option value=\"playing\">Wiedergabe bestätigt</option>") |> ignore
    sb.AppendLine("      <option value=\"failed\">Versuche ausgeschöpft</option>") |> ignore
    sb.AppendLine("    </select>") |> ignore
    sb.AppendLine("  </label>") |> ignore
    
    // JavaScript-Block mit Testdaten und Logik
    sb.AppendLine("  <script>") |> ignore
    sb.AppendLine("    (async () => {") |> ignore
    sb.AppendLine("      const state = {") |> ignore
    sb.AppendLine("        page: { url: \"https://www.tiktok.com/@demo/live\", title: \"Demo LIVE\", scannedAtUtc: new Date().toISOString() },") |> ignore
    sb.AppendLine("        captionInfo: { present: true, open: true, supportLang: [\"de\", \"en\"], location: null, showType: 1 },") |> ignore
    sb.AppendLine("        menuCaptionAvailable: true,") |> ignore
    sb.AppendLine("        menuCaptionActive: false,") |> ignore
    sb.AppendLine("        quickRecoverEnabled: false,") |> ignore
    sb.AppendLine("        quickRecoverSeconds: 3,") |> ignore
    sb.AppendLine("        profileInfo: {") |> ignore
    sb.AppendLine("          present: true, nickname: \"Demo Creator\", uniqueId: \"demo\", signature: \"Barrierefreier Teststream\",") |> ignore
    sb.AppendLine("          followingCount: \"12\", followerCount: \"238800\", likeCount: \"1800000\", live: true, source: \"metadata\"") |> ignore
    sb.AppendLine("        },") |> ignore
    sb.AppendLine("        aiSummaryInfo: { featureFlagPresent: true, featureEnabled: true, text: \"\", source: null, overviewCardFound: true, overviewCardHovered: true },") |> ignore
    sb.AppendLine("        hook: { armed: true, installed: true, connected: true, lastError: null },") |> ignore
    sb.AppendLine("        stream: { key: \"demo|123\", handle: \"demo\", roomId: \"123\", teamTag: \"tmm\", teamEvidence: {} },") |> ignore
    sb.AppendLine("        liveStats: {") |> ignore
    sb.AppendLine("          viewerCount: \"143\", totalViewers: \"15842\", likeCount: \"430200\",") |> ignore
    sb.AppendLine("          followEvents: 7, shareEvents: 4, shareCount: \"19\", followerCount: \"238800\",") |> ignore
    sb.AppendLine("          lastUpdatedUtc: new Date().toISOString(), recentEventIds: []") |> ignore
    sb.AppendLine("        },") |> ignore
    sb.AppendLine("        playerState: {") |> ignore
    sb.AppendLine("          available: true, playing: true, muted: false, elapsedText: \"1:17:42\", pipActive: false, fullscreenActive: false,") |> ignore
    sb.AppendLine("          volume: 0.72, volumePercent: 72, volumeGainDb: -2.9, peakDbfs: -8.4,") |> ignore
    sb.AppendLine("          limiterEnabled: true, limiterThresholdDbfs: -6, limiterReductionDb: -1.2, limiterMode: \"Kompressor\",") |> ignore
    sb.AppendLine("          connectedStreams: 4, multiGuest: true, updatedAtUtc: new Date().toISOString()") |> ignore
    sb.AppendLine("        },") |> ignore
    sb.AppendLine("        selectedQuality: \"540p\",") |> ignore
    sb.AppendLine("        chatMessages: [") |> ignore
    sb.AppendLine("          { messageId: \"1\", participantKey: \"id:1\", author: \"Anna\", content: \"Guten Abend\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() },") |> ignore
    sb.AppendLine("          { messageId: \"2\", participantKey: \"id:2\", author: \"Ben\", content: \"Welche Sorte ist das?\", contentLanguage: \"de-DE\", source: \"dom\", receivedAtUtc: new Date().toISOString() },") |> ignore
    sb.AppendLine("          { messageId: \"3\", author: \"Clara\", content: \"Danke für die Erklärung\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() },") |> ignore
    sb.AppendLine("          { messageId: \"4\", author: \"David\", content: \"Bitte einmal mischen\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() },") |> ignore
    sb.AppendLine("          { messageId: \"5\", author: \"Eva\", content: \"Das ist gut lesbar\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() }") |> ignore
    sb.AppendLine("        ],") |> ignore
    sb.AppendLine("        participants: {") |> ignore
    sb.AppendLine("          \"id:1\": { key: \"id:1\", name: \"Anna\", messageCount: 12, wordCount: 48, giftEventCount: 2, giftItemCount: 24, lastSeenAtUtc: new Date().toISOString() },") |> ignore
    sb.AppendLine("          \"id:2\": { key: \"id:2\", name: \"Ben\", messageCount: 8, wordCount: 39, giftEventCount: 0, giftItemCount: 0, lastSeenAtUtc: new Date().toISOString() },") |> ignore
    sb.AppendLine("          \"name:clara\": { key: \"name:clara\", name: \"Clara\", messageCount: 6, wordCount: 31, giftEventCount: 1, giftItemCount: 1, lastSeenAtUtc: new Date().toISOString() }") |> ignore
    sb.AppendLine("        },") |> ignore
    sb.AppendLine("        streamMutes: [],") |> ignore
    sb.AppendLine("        participantsTruncated: false,") |> ignore
    sb.AppendLine("        media: [") |> ignore
    sb.AppendLine("          { url: \"https://pull.example.tiktokcdn.com/live/stream_hd.flv?expire=1&sign=test\", protocol: \"FLV\", quality: \"720p\", sdkKey: \"hd\", bitrate: 1800000, codec: \"h264\", width: 1280, height: 720, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn.com\", source: \"metadata\" },") |> ignore
    sb.AppendLine("          { url: \"https://pull.example.tiktokcdn-eu.com/live/stream_720p.m3u8?sign=test\", protocol: \"HLS\", quality: \"720p\", sdkKey: \"hd\", bitrate: 1800000, codec: \"h264\", width: 1280, height: 720, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn-eu.com\", source: \"network\" },") |> ignore
    sb.AppendLine("          { url: \"https://pull.example.tiktokcdn.com/live/stream_sd.flv?expire=1&sign=test\", protocol: \"FLV\", quality: \"540p\", sdkKey: \"sd\", bitrate: 900000, codec: \"h264\", width: 960, height: 540, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn.com\", source: \"metadata\" }") |> ignore
    sb.AppendLine("        ],") |> ignore
    sb.AppendLine("        captions: [") |> ignore
    sb.AppendLine("          { receivedAtUtc: new Date().toISOString(), sentenceId: \"42\", definite: true, contents: [{ lang: \"de\", text: \"Dies ist eine Test-Caption.\" }] }") |> ignore
    sb.AppendLine("        ],") |> ignore
    sb.AppendLine("        debug: { enabled: false, entries: [{ atUtc: new Date().toISOString(), event: \"scan\", detail: { mediaCount: 3 } }] }") |> ignore
    sb.AppendLine("      };") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("      const stateListeners = [];") |> ignore
    sb.AppendLine("      globalThis.chrome = {") |> ignore
    sb.AppendLine("        tabs: {") |> ignore
    sb.AppendLine("          query: async () => [{ id: 1, url: state.page.url, title: state.page.title }],") |> ignore
    sb.AppendLine("          onActivated: { addListener() {} }") |> ignore
    sb.AppendLine("        },") |> ignore
    sb.AppendLine("        tabCapture: { capture(_options, callback) { callback(null); } },") |> ignore
    sb.AppendLine("        runtime: {") |> ignore
    sb.AppendLine("          sendMessage: async (message) => {") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_GET_STATE\") return { ok: true, state };") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_OPEN_EMBED_LIVE\") {") |> ignore
    sb.AppendLine("              state.embedStartup = TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), \"demo\", Date.now());") |> ignore
    sb.AppendLine("              return { ok: true, response: { activated: false, phase: \"loading\" } };") |> ignore
    sb.AppendLine("            }") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_CANCEL_EMBED_STARTUP\" || message.type === \"TLC_OPEN_NORMAL_LIVE\") {") |> ignore
    sb.AppendLine("              if (state.embedStartup) state.embedStartup = { ...state.embedStartup, phase: \"cancelled\", nextAttemptAtMs: null };") |> ignore
    sb.AppendLine("              return { ok: true };") |> ignore
    sb.AppendLine("            }") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_GET_SETTINGS\") return { ok: true, settings: { autoHook: true, keepSpeechActive: true, speechVolume: 0.5, speechLanguage: \"auto\", speakNames: true, shortenNames: false, serviceUrl: \"http://127.0.0.1:43117\", pairingCode: \"\", permanentMutes: [], quickRecoverEnabled: state.quickRecoverEnabled, quickRecoverSeconds: state.quickRecoverSeconds } };") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_SET_QUICK_RECOVER\") {") |> ignore
    sb.AppendLine("              state.quickRecoverEnabled = Boolean(message.enabled);") |> ignore
    sb.AppendLine("              state.quickRecoverSeconds = Math.max(1, Math.min(59, Math.round(Number(message.seconds) || 3)));") |> ignore
    sb.AppendLine("              return { ok: true, state, seconds: state.quickRecoverSeconds };") |> ignore
    sb.AppendLine("            }") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_GET_CAPTION_JSONL_EXPORT\") return { ok: true, records: TLC_EXPORT_PRIVACY.captions(state.captions) };") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_GET_CAPTION_RAW_EXPORT\") return { ok: true, report: TLC_EXPORT_PRIVACY.captionReport({") |> ignore
    sb.AppendLine("              version: \"0.8.2\", generatedAtUtc: new Date().toISOString(), messages: state.captions,") |> ignore
    sb.AppendLine("              dataStreams: state.media, data: { captionInfo: state.captionInfo, captionSources: state.captionSources, playerState: state.playerState }, stream: { page: state.page }") |> ignore
    sb.AppendLine("            }) };") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_SCAN\") {") |> ignore
    sb.AppendLine("              return { ok: true, response: { captionInfo: state.captionInfo, captionControl: true, mediaCount: state.media.length } };") |> ignore
    sb.AppendLine("            }") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_GET_PLAYER_STATE\") return { ok: true, response: { playerState: state.playerState } };") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_PLAYER_ACTION\") {") |> ignore
    sb.AppendLine("              if (message.action === \"toggle-play\") state.playerState.playing = !state.playerState.playing;") |> ignore
    sb.AppendLine("              if (message.action === \"toggle-mute\") state.playerState.muted = !state.playerState.muted;") |> ignore
    sb.AppendLine("              if (message.action === \"set-volume\") {") |> ignore
    sb.AppendLine("                state.playerState.volume = Number(message.value);") |> ignore
    sb.AppendLine("                state.playerState.volumePercent = Math.round(Number(message.value) * 100);") |> ignore
    sb.AppendLine("                state.playerState.volumeGainDb = Number(message.value) > 0 ? 20 * Math.log10(Number(message.value)) : null;") |> ignore
    sb.AppendLine("              }") |> ignore
    sb.AppendLine("              if (message.action === \"set-limiter\") {") |> ignore
    sb.AppendLine("                state.playerState.limiterEnabled = Boolean(message.enabled);") |> ignore
    sb.AppendLine("                state.playerState.limiterThresholdDbfs = Number(message.thresholdDbfs);") |> ignore
    sb.AppendLine("              }") |> ignore
    sb.AppendLine("              return { ok: true, response: { activated: true, playerState: state.playerState } };") |> ignore
    sb.AppendLine("            }") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_CLEAR_CHAT\") {") |> ignore
    sb.AppendLine("              state.chatMessages = [];") |> ignore
    sb.AppendLine("              return { ok: true };") |> ignore
    sb.AppendLine("            }") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_SET_DEBUG\") {") |> ignore
    sb.AppendLine("              state.debug.enabled = Boolean(message.enabled);") |> ignore
    sb.AppendLine("              return { ok: true, state };") |> ignore
    sb.AppendLine("            }") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_CLEAR_DEBUG\") {") |> ignore
    sb.AppendLine("              state.debug.entries = [];") |> ignore
    sb.AppendLine("              return { ok: true };") |> ignore
    sb.AppendLine("            }") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_SET_MUTE\") return { ok: true, state, settings: { permanentMutes: [] } };") |> ignore
    sb.AppendLine("            if (message.type === \"TLC_GET_DEBUG_REPORT\") return { ok: true, report: TLC_EXPORT_PRIVACY.diagnosticReport({ version: \"0.8.2\", debug: state.debug, page: state.page, media: state.media }) };") |> ignore
    sb.AppendLine("            return { ok: true, response: { activated: true } };") |> ignore
    sb.AppendLine("          },") |> ignore
    sb.AppendLine("          onMessage: { addListener(listener) { stateListeners.push(listener); } }") |> ignore
    sb.AppendLine("        }") |> ignore
    sb.AppendLine("      };") |> ignore
    sb.AppendLine("") |> ignore
    sb.AppendLine("      const assetVersion = Date.now();") |> ignore
    sb.AppendLine("      const source = await fetch(\"../browser-extension/sidepanel.html\", { cache: \"no-store\" }).then((response) => response.text());") |> ignore
    sb.AppendLine("      const parsed = new DOMParser().parseFromString(source, \"text/html\");") |> ignore
    sb.AppendLine("      document.title = parsed.title;") |> ignore
    sb.AppendLine("      for (const child of [...parsed.body.children]) {") |> ignore
    sb.AppendLine("        if (child.tagName !== \"SCRIPT\") document.body.append(document.importNode(child, true));") |> ignore
    sb.AppendLine("      }") |> ignore
    sb.AppendLine("      const css = document.createElement(\"link\");") |> ignore
    sb.AppendLine("      css.rel = \"stylesheet\";") |> ignore
    sb.AppendLine("      css.href = \"../browser-extension/sidepanel.css?v=0.7.0-1\";") |> ignore
    sb.AppendLine("      document.head.append(css);") |> ignore
    sb.AppendLine("      const coreScript = document.createElement(\"script\");") |> ignore
    sb.AppendLine("      coreScript.src = `../browser-extension/content-core.js?v=${assetVersion}`;") |> ignore
    sb.AppendLine("      coreScript.onload = () => {") |> ignore
    sb.AppendLine("        document.getElementById(\"test-embed-scenario\").addEventListener(\"change\", (event) => {") |> ignore
    sb.AppendLine("          state.embedStartup = {") |> ignore
    sb.AppendLine("            ...TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), \"demo\", Date.now()),") |> ignore
    sb.AppendLine("            phase: event.target.value, reason: \"server-error\", attempt: event.target.value === \"failed\" ? 3 : 1") |> ignore
    sb.AppendLine("          };") |> ignore
    sb.AppendLine("          stateListeners.forEach((listener) => listener({ type: \"TLC_STATE_UPDATED\", tabId: 1, state }));") |> ignore
    sb.AppendLine("        });") |> ignore
    sb.AppendLine("        document.getElementById(\"test-caption-scenario\").addEventListener(\"change\", (event) => {") |> ignore
    sb.AppendLine("          const mode = event.target.value;") |> ignore
    sb.AppendLine("          const observedAt = Date.now() - (mode === \"historical\" ? 60_000 : 0);") |> ignore
    sb.AppendLine("          state.captions = mode === \"none\" ? [] : [\"DomCaption\", \"WebcastCaptionMessage\"].map((method) => ({") |> ignore
    sb.AppendLine("            method, source: method === \"DomCaption\" ? \"dom\" : \"websocket\", receivedAtUtc: new Date(observedAt).toISOString(),") |> ignore
    sb.AppendLine("            contents: [{ lang: \"de\", text: \"Dies ist eine Test-Caption.\" }]") |> ignore
    sb.AppendLine("          }));") |> ignore
    sb.AppendLine("          state.captionSources = TLC_CONTENT_CORE.captionSourceSnapshot();") |> ignore
    sb.AppendLine("          if (mode === \"metadata\") state.captionSources.metadata = { present: true, open: true, supportLang: [\"de\"] };") |> ignore
    sb.AppendLine("          else for (const caption of state.captions) state.captionSources = TLC_CONTENT_CORE.observeCaptionSource(state.captionSources, caption, observedAt);") |> ignore
    sb.AppendLine("          state.captionInfo = TLC_CONTENT_CORE.summarizeCaptionSources(state.captionSources);") |> ignore
    sb.AppendLine("          stateListeners.forEach((listener) => listener({ type: \"TLC_STATE_UPDATED\", tabId: 1, state }));") |> ignore
    sb.AppendLine("        });") |> ignore
    sb.AppendLine("        const privacyScript = document.createElement(\"script\");") |> ignore
    sb.AppendLine("        privacyScript.src = `../browser-extension/export-privacy.js?v=${assetVersion}`;") |> ignore
    sb.AppendLine("        privacyScript.onload = () => {") |> ignore
    sb.AppendLine("          const script = document.createElement(\"script\");") |> ignore
    sb.AppendLine("          script.src = `../browser-extension/sidepanel.js?v=${assetVersion}`;") |> ignore
    sb.AppendLine("          document.body.append(script);") |> ignore
    sb.AppendLine("        };") |> ignore
    sb.AppendLine("        document.body.append(privacyScript);") |> ignore
    sb.AppendLine("      };") |> ignore
    sb.AppendLine("      document.body.append(coreScript);") |> ignore
    sb.AppendLine("    })();") |> ignore
    sb.AppendLine("  </script>") |> ignore
    sb.AppendLine("</body>") |> ignore
    sb.AppendLine("</html>") |> ignore
    
    sb.ToString()

/// Hauptfunktion zum Schreiben des HTML in eine Datei
let writeSidepanelHarnessToFile outputPath =
    let htmlContent = createSidepanelHarness()
    File.WriteAllText(outputPath, htmlContent, Encoding.UTF8)
    printfn "Sidepanel-Harness wurde erfolgreich erstellt: %s" outputPath

// Beispielaufruf
// writeSidepanelHarnessToFile "sidepanel-harness.html"
