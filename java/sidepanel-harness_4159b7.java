// abstraction-provenance: {"artifact_sha256": "2823375681f520bc3ab635be40952e410b752af85f4dacbbeb9a6f848c797c3f", "source_sha256": "4159b73c8ded244c9ae43694ca2c07c881918152d298b40260e15287bef2606f", "target_language": "java"}
// sidepanel-harness.html — portiert nach java
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/sidepanel-harness.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.time.*;
import java.util.*;

public class SidepanelHarness {
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Verwendung: java SidepanelHarness <ausgabedatei>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        
        try {
            String htmlContent = generateHtml();
            Files.write(Paths.get(outputFile), htmlContent.getBytes("UTF-8"));
            System.out.println("HTML-Datei erfolgreich erstellt: " + outputFile);
        } catch (IOException e) {
            System.err.println("Fehler beim Schreiben der Datei: " + e.getMessage());
            System.exit(1);
        }
    }
    
    private static String generateHtml() {
        StringBuilder html = new StringBuilder();
        
        // DOCTYPE und HTML-Grundstruktur
        html.append("<!doctype html>\n");
        html.append("<html lang=\"de\">\n");
        html.append("<head>\n");
        html.append("  <meta charset=\"utf-8\">\n");
        html.append("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
        html.append("  <title>Sidepanel Test Harness</title>\n");
        html.append("</head>\n");
        html.append("<body>\n");
        
        // Caption-Testzustand Select
        html.append("  <label>Caption-Testzustand\n");
        html.append("    <select id=\"test-caption-scenario\">\n");
        html.append("      <option value=\"metadata\">Seitenmetadaten</option>\n");
        html.append("      <option value=\"mixed\">DOM und WebSocket aktuell</option>\n");
        html.append("      <option value=\"historical\">Nur historische Captions</option>\n");
        html.append("      <option value=\"none\">Keine Captions</option>\n");
        html.append("    </select>\n");
        html.append("  </label>\n");
        
        // Embed-Testzustand Select
        html.append("  <label>Embed-Testzustand\n");
        html.append("    <select id=\"test-embed-scenario\">\n");
        html.append("      <option value=\"loading\">Startet</option>\n");
        html.append("      <option value=\"retry-wait\">Serverfehler – Wiederanlauf</option>\n");
        html.append("      <option value=\"awaiting-gesture\">Benutzeraktion nötig</option>\n");
        html.append("      <option value=\"playing\">Wiedergabe bestätigt</option>\n");
        html.append("      <option value=\"failed\">Versuche ausgeschöpft</option>\n");
        html.append("    </select>\n");
        html.append("  </label>\n");
        
        // Script-Block
        html.append("  <script>\n");
        html.append("    (async () => {\n");
        html.append("      const state = {\n");
        html.append("        page: { url: \"https://www.tiktok.com/@demo/live\", title: \"Demo LIVE\", scannedAtUtc: new Date().toISOString() },\n");
        html.append("        captionInfo: { present: true, open: true, supportLang: [\"de\", \"en\"], location: null, showType: 1 },\n");
        html.append("        menuCaptionAvailable: true,\n");
        html.append("        menuCaptionActive: false,\n");
        html.append("        quickRecoverEnabled: false,\n");
        html.append("        quickRecoverSeconds: 3,\n");
        html.append("        profileInfo: {\n");
        html.append("          present: true, nickname: \"Demo Creator\", uniqueId: \"demo\", signature: \"Barrierefreier Teststream\",\n");
        html.append("          followingCount: \"12\", followerCount: \"238800\", likeCount: \"1800000\", live: true, source: \"metadata\"\n");
        html.append("        },\n");
        html.append("        aiSummaryInfo: { featureFlagPresent: true, featureEnabled: true, text: \"\", source: null, overviewCardFound: true, overviewCardHovered: true },\n");
        html.append("        hook: { armed: true, installed: true, connected: true, lastError: null },\n");
        html.append("        stream: { key: \"demo|123\", handle: \"demo\", roomId: \"123\", teamTag: \"tmm\", teamEvidence: {} },\n");
        html.append("        liveStats: {\n");
        html.append("          viewerCount: \"143\", totalViewers: \"15842\", likeCount: \"430200\",\n");
        html.append("          followEvents: 7, shareEvents: 4, shareCount: \"19\", followerCount: \"238800\",\n");
        html.append("          lastUpdatedUtc: new Date().toISOString(), recentEventIds: []\n");
        html.append("        },\n");
        html.append("        playerState: {\n");
        html.append("          available: true, playing: true, muted: false, elapsedText: \"1:17:42\", pipActive: false, fullscreenActive: false,\n");
        html.append("          volume: 0.72, volumePercent: 72, volumeGainDb: -2.9, peakDbfs: -8.4,\n");
        html.append("          limiterEnabled: true, limiterThresholdDbfs: -6, limiterReductionDb: -1.2, limiterMode: \"Kompressor\",\n");
        html.append("          connectedStreams: 4, multiGuest: true, updatedAtUtc: new Date().toISOString()\n");
        html.append("        },\n");
        html.append("        selectedQuality: \"540p\",\n");
        html.append("        chatMessages: [\n");
        html.append("          { messageId: \"1\", participantKey: \"id:1\", author: \"Anna\", content: \"Guten Abend\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() },\n");
        html.append("          { messageId: \"2\", participantKey: \"id:2\", author: \"Ben\", content: \"Welche Sorte ist das?\", contentLanguage: \"de-DE\", source: \"dom\", receivedAtUtc: new Date().toISOString() },\n");
        html.append("          { messageId: \"3\", author: \"Clara\", content: \"Danke für die Erklärung\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() },\n");
        html.append("          { messageId: \"4\", author: \"David\", content: \"Bitte einmal mischen\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() },\n");
        html.append("          { messageId: \"5\", author: \"Eva\", content: \"Das ist gut lesbar\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() }\n");
        html.append("        ],\n");
        html.append("        participants: {\n");
        html.append("          \"id:1\": { key: \"id:1\", name: \"Anna\", messageCount: 12, wordCount: 48, giftEventCount: 2, giftItemCount: 24, lastSeenAtUtc: new Date().toISOString() },\n");
        html.append("          \"id:2\": { key: \"id:2\", name: \"Ben\", messageCount: 8, wordCount: 39, giftEventCount: 0, giftItemCount: 0, lastSeenAtUtc: new Date().toISOString() },\n");
        html.append("          \"name:clara\": { key: \"name:clara\", name: \"Clara\", messageCount: 6, wordCount: 31, giftEventCount: 1, giftItemCount: 1, lastSeenAtUtc: new Date().toISOString() }\n");
        html.append("        },\n");
        html.append("        streamMutes: [],\n");
        html.append("        participantsTruncated: false,\n");
        html.append("        media: [\n");
        html.append("          { url: \"https://pull.example.tiktokcdn.com/live/stream_hd.flv?expire=1&sign=test\", protocol: \"FLV\", quality: \"720p\", sdkKey: \"hd\", bitrate: 1800000, codec: \"h264\", width: 1280, height: 720, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn.com\", source: \"metadata\" },\n");
        html.append("          { url: \"https://pull.example.tiktokcdn-eu.com/live/stream_720p.m3u8?sign=test\", protocol: \"HLS\", quality: \"720p\", sdkKey: \"hd\", bitrate: 1800000, codec: \"h264\", width: 1280, height: 720, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn-eu.com\", source: \"network\" },\n");
        html.append("          { url: \"https://pull.example.tiktokcdn.com/live/stream_sd.flv?expire=1&sign=test\", protocol: \"FLV\", quality: \"540p\", sdkKey: \"sd\", bitrate: 900000, codec: \"h264\", width: 960, height: 540, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn.com\", source: \"metadata\" }\n");
        html.append("        ],\n");
        html.append("        captions: [\n");
        html.append("          { receivedAtUtc: new Date().toISOString(), sentenceId: \"42\", definite: true, contents: [{ lang: \"de\", text: \"Dies ist eine Test-Caption.\" }] }\n");
        html.append("        ],\n");
        html.append("        debug: { enabled: false, entries: [{ atUtc: new Date().toISOString(), event: \"scan\", detail: { mediaCount: 3 } }] }\n");
        html.append("      };\n");
        html.append("\n");
        html.append("      const stateListeners = [];\n");
        html.append("      globalThis.chrome = {\n");
        html.append("        tabs: {\n");
        html.append("          query: async () => [{ id: 1, url: state.page.url, title: state.page.title }],\n");
        html.append("          onActivated: { addListener() {} }\n");
        html.append("        },\n");
        html.append("        tabCapture: { capture(_options, callback) { callback(null); } },\n");
        html.append("        runtime: {\n");
        html.append("          sendMessage: async (message) => {\n");
        html.append("            if (message.type === \"TLC_GET_STATE\") return { ok: true, state };\n");
        html.append("            if (message.type === \"TLC_OPEN_EMBED_LIVE\") {\n");
        html.append("              state.embedStartup = TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), \"demo\", Date.now());\n");
        html.append("              return { ok: true, response: { activated: false, phase: \"loading\" } };\n");
        html.append("            }\n");
        html.append("            if (message.type === \"TLC_CANCEL_EMBED_STARTUP\" || message.type === \"TLC_OPEN_NORMAL_LIVE\") {\n");
        html.append("              if (state.embedStartup) state.embedStartup = { ...state.embedStartup, phase: \"cancelled\", nextAttemptAtMs: null };\n");
        html.append("              return { ok: true };\n");
        html.append("            }\n");
        html.append("            if (message.type === \"TLC_GET_SETTINGS\") return { ok: true, settings: { autoHook: true, keepSpeechActive: true, speechVolume: 0.5, speechLanguage: \"auto\", speakNames: true, shortenNames: false, serviceUrl: \"http://127.0.0.1:43117\", pairingCode: \"\", permanentMutes: [], quickRecoverEnabled: state.quickRecoverEnabled, quickRecoverSeconds: state.quickRecoverSeconds } };\n");
        html.append("            if (message.type === \"TLC_SET_QUICK_RECOVER\") {\n");
        html.append("              state.quickRecoverEnabled = Boolean(message.enabled);\n");
        html.append("              state.quickRecoverSeconds = Math.max(1, Math.min(59, Math.round(Number(message.seconds) || 3)));\n");
        html.append("              return { ok: true, state, seconds: state.quickRecoverSeconds };\n");
        html.append("            }\n");
        html.append("            if (message.type === \"TLC_GET_CAPTION_JSONL_EXPORT\") return { ok: true, records: TLC_EXPORT_PRIVACY.captions(state.captions) };\n");
        html.append("            if (message.type === \"TLC_GET_CAPTION_RAW_EXPORT\") return { ok: true, report: TLC_EXPORT_PRIVACY.captionReport({\n");
        html.append("              version: \"0.8.2\", generatedAtUtc: new Date().toISOString(), messages: state.captions,\n");
        html.append("              dataStreams: state.media, data: { captionInfo: state.captionInfo, captionSources: state.captionSources, playerState: state.playerState }, stream: { page: state.page }\n");
        html.append("            }) };\n");
        html.append("            if (message.type === \"TLC_SCAN\") {\n");
        html.append("              return { ok: true, response: { captionInfo: state.captionInfo, captionControl: true, mediaCount: state.media.length } };\n");
        html.append("            }\n");
        html.append("            if (message.type === \"TLC_GET_PLAYER_STATE\") return { ok: true, response: { playerState: state.playerState } };\n");
        html.append("            if (message.type === \"TLC_PLAYER_ACTION\") {\n");
        html.append("              if (message.action === \"toggle-play\") state.playerState.playing = !state.playerState.playing;\n");
        html.append("              if (message.action === \"toggle-mute\") state.playerState.muted = !state.playerState.muted;\n");
        html.append("              if (message.action === \"set-volume\") {\n");
        html.append("                state.playerState.volume = Number(message.value);\n");
        html.append("                state.playerState.volumePercent = Math.round(Number(message.value) * 100);\n");
        html.append("                state.playerState.volumeGainDb = Number(message.value) > 0 ? 20 * Math.log10(Number(message.value)) : null;\n");
        html.append("              }\n");
        html.append("              if (message.action === \"set-limiter\") {\n");
        html.append("                state.playerState.limiterEnabled = Boolean(message.enabled);\n");
        html.append("                state.playerState.limiterThresholdDbfs = Number(message.thresholdDbfs);\n");
        html.append("              }\n");
        html.append("              return { ok: true, response: { activated: true, playerState: state.playerState } };\n");
        html.append("            }\n");
        html.append("            if (message.type === \"TLC_CLEAR_CHAT\") {\n");
        html.append("              state.chatMessages = [];\n");
        html.append("              return { ok: true };\n");
        html.append("            }\n");
        html.append("            if (message.type === \"TLC_SET_DEBUG\") {\n");
        html.append("              state.debug.enabled = Boolean(message.enabled);\n");
        html.append("              return { ok: true, state };\n");
        html.append("            }\n");
        html.append("            if (message.type === \"TLC_CLEAR_DEBUG\") {\n");
        html.append("              state.debug.entries = [];\n");
        html.append("              return { ok: true };\n");
        html.append("            }\n");
        html.append("            if (message.type === \"TLC_SET_MUTE\") return { ok: true, state, settings: { permanentMutes: [] } };\n");
        html.append("            if (message.type === \"TLC_GET_DEBUG_REPORT\") return { ok: true, report: TLC_EXPORT_PRIVACY.diagnosticReport({ version: \"0.8.2\", debug: state.debug, page: state.page, media: state.media }) };\n");
        html.append("            return { ok: true, response: { activated: true } };\n");
        html.append("          },\n");
        html.append("          onMessage: { addListener(listener) { stateListeners.push(listener); } }\n");
        html.append("        }\n");
        html.append("      };\n");
        html.append("\n");
        html.append("      const assetVersion = Date.now();\n");
        html.append("      const source = await fetch(\"../browser-extension/sidepanel.html\", { cache: \"no-store\" }).then((response) => response.text());\n");
        html.append("      const parsed = new DOMParser().parseFromString(source, \"text/html\");\n");
        html.append("      document.title = parsed.title;\n");
        html.append("      for (const child of [...parsed.body.children]) {\n");
        html.append("        if (child.tagName !== \"SCRIPT\") document.body.append(document.importNode(child, true));\n");
        html.append("      }\n");
        html.append("      const css = document.createElement(\"link\");\n");
        html.append("      css.rel = \"stylesheet\";\n");
        html.append("      css.href = \"../browser-extension/sidepanel.css?v=0.7.0-1\";\n");
        html.append("      document.head.append(css);\n");
        html.append("      const coreScript = document.createElement(\"script\");\n");
        html.append("      coreScript.src = `../browser-extension/content-core.js?v=${assetVersion}`;\n");
        html.append("      coreScript.onload = () => {\n");
        html.append("        document.getElementById(\"test-embed-scenario\").addEventListener(\"change\", (event) => {\n");
        html.append("          state.embedStartup = {\n");
        html.append("            ...TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), \"demo\", Date.now()),\n");
        html.append("            phase: event.target.value, reason: \"server-error\", attempt: event.target.value === \"failed\" ? 3 : 1\n");
        html.append("          };\n");
        html.append("          stateListeners.forEach((listener) => listener({ type: \"TLC_STATE_UPDATED\", tabId: 1, state }));\n");
        html.append("        });\n");
        html.append("        document.getElementById(\"test-caption-scenario\").addEventListener(\"change\", (event) => {\n");
        html.append("          const mode = event.target.value;\n");
        html.append("          const observedAt = Date.now() - (mode === \"historical\" ? 60_000 : 0);\n");
        html.append("          state.captions = mode === \"none\" ? [] : [\"DomCaption\", \"WebcastCaptionMessage\"].map((method) => ({\n");
        html.append("            method, source: method === \"DomCaption\" ? \"dom\" : \"websocket\", receivedAtUtc: new Date(observedAt).toISOString(),\n");
        html.append("            contents: [{ lang: \"de\", text: \"Dies ist eine Test-Caption.\" }]\n");
        html.append("          }));\n");
        html.append("          state.captionSources = TLC_CONTENT_CORE.captionSourceSnapshot();\n");
        html.append("          if (mode === \"metadata\") state.captionSources.metadata = { present: true, open: true, supportLang: [\"de\"] };\n");
        html.append("          else for (const caption of state.captions) state.captionSources = TLC_CONTENT_CORE.observeCaptionSource(state.captionSources, caption, observedAt);\n");
        html.append("          state.captionInfo = TLC_CONTENT_CORE.summarizeCaptionSources(state.captionSources);\n");
        html.append("          stateListeners.forEach((listener) => listener({ type: \"TLC_STATE_UPDATED\", tabId: 1, state }));\n");
        html.append("        });\n");
        html.append("        const privacyScript = document.createElement(\"script\");\n");
        html.append("        privacyScript.src = `../browser-extension/export-privacy.js?v=${assetVersion}`;\n");
        html.append("        privacyScript.onload = () => {\n");
        html.append("          const script = document.createElement(\"script\");\n");
        html.append("          script.src = `../browser-extension/sidepanel.js?v=${assetVersion}`;\n");
        html.append("          document.body.append(script);\n");
        html.append("        };\n");
        html.append("        document.body.append(privacyScript);\n");
        html.append("      };\n");
        html.append("      document.body.append(coreScript);\n");
        html.append("    })();\n");
        html.append("  </script>\n");
        html.append("</body>\n");
        html.append("</html>\n");
        
        return html.toString();
    }
}
