// abstraction-provenance: {"artifact_sha256": "7b008b5f95955e2c76d02fe931d371ad6787879dcb2574bf94340f80e4fe0041", "source_sha256": "5cdd2168705597f720695d3eeea066c9b5361e819b3b2e47c23269290dddc1dd", "target_language": "java"}
// sidepanel-harness.html — portiert nach java
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/sidepanel-harness.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/sidepanel-harness.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/sidepanel-harness.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/sidepanel-harness.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.time.*;
import java.util.*;

public class SidepanelHarness {
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java SidepanelHarness <output-file>");
            System.exit(1);
        }
        
        try {
            String htmlContent = generateHtml();
            Files.write(Paths.get(args[0]), htmlContent.getBytes());
        } catch (IOException e) {
            System.err.println("Error writing file: " + e.getMessage());
            System.exit(1);
        }
    }
    
    private static String generateHtml() {
        StringBuilder sb = new StringBuilder();
        
        // DOCTYPE
        sb.append("<!doctype html>\n");
        
        // HTML start
        sb.append("<html lang=\"de\">\n");
        
        // Head section
        sb.append("<head>\n");
        sb.append("  <meta charset=\"utf-8\">\n");
        sb.append("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
        sb.append("  <title>Sidepanel Test Harness</title>\n");
        sb.append("</head>\n");
        
        // Body start
        sb.append("<body>\n");
        
        // Caption test state selector
        sb.append("  <label>Caption-Testzustand\n");
        sb.append("    <select id=\"test-caption-scenario\">\n");
        sb.append("      <option value=\"metadata\">Seitenmetadaten</option>\n");
        sb.append("      <option value=\"mixed\">DOM und WebSocket aktuell</option>\n");
        sb.append("      <option value=\"historical\">Nur historische Captions</option>\n");
        sb.append("      <option value=\"none\">Keine Captions</option>\n");
        sb.append("    </select>\n");
        sb.append("  </label>\n");
        
        // Embed test state selector
        sb.append("  <label>Embed-Testzustand\n");
        sb.append("    <select id=\"test-embed-scenario\">\n");
        sb.append("      <option value=\"loading\">Startet</option>\n");
        sb.append("      <option value=\"retry-wait\">Serverfehler – Wiederanlauf</option>\n");
        sb.append("      <option value=\"awaiting-gesture\">Benutzeraktion nötig</option>\n");
        sb.append("      <option value=\"playing\">Wiedergabe bestätigt</option>\n");
        sb.append("      <option value=\"failed\">Versuche ausgeschöpft</option>\n");
        sb.append("    </select>\n");
        sb.append("  </label>\n");
        
        // Script section
        sb.append("  <script>\n");
        sb.append("    (async () => {\n");
        sb.append("      const state = {\n");
        sb.append("        page: { url: \"https://www.tiktok.com/@demo/live\", title: \"Demo LIVE\", scannedAtUtc: new Date().toISOString() },\n");
        sb.append("        captionInfo: { present: true, open: true, supportLang: [\"de\", \"en\"], location: null, showType: 1 },\n");
        sb.append("        menuCaptionAvailable: true,\n");
        sb.append("        menuCaptionActive: false,\n");
        sb.append("        quickRecoverEnabled: false,\n");
        sb.append("        quickRecoverSeconds: 3,\n");
        sb.append("        profileInfo: {\n");
        sb.append("          present: true, nickname: \"Demo Creator\", uniqueId: \"demo\", signature: \"Barrierefreier Teststream\",\n");
        sb.append("          followingCount: \"12\", followerCount: \"238800\", likeCount: \"1800000\", live: true, source: \"metadata\"\n");
        sb.append("        },\n");
        sb.append("        aiSummaryInfo: { featureFlagPresent: true, featureEnabled: true, text: \"\", source: null, overviewCardFound: true, overviewCardHovered: true },\n");
        sb.append("        hook: { armed: true, installed: true, connected: true, lastError: null },\n");
        sb.append("        stream: { key: \"demo|123\", handle: \"demo\", roomId: \"123\", teamTag: \"tmm\", teamEvidence: {} },\n");
        sb.append("        liveStats: {\n");
        sb.append("          viewerCount: \"143\", totalViewers: \"15842\", likeCount: \"430200\",\n");
        sb.append("          followEvents: 7, shareEvents: 4, shareCount: \"19\", followerCount: \"238800\",\n");
        sb.append("          lastUpdatedUtc: new Date().toISOString(), recentEventIds: []\n");
        sb.append("        },\n");
        sb.append("        playerState: {\n");
        sb.append("          available: true, playing: true, muted: false, elapsedText: \"1:17:42\", pipActive: false, fullscreenActive: false,\n");
        sb.append("          volume: 0.72, volumePercent: 72, volumeGainDb: -2.9, peakDbfs: -8.4,\n");
        sb.append("          limiterEnabled: true, limiterThresholdDbfs: -6, limiterReductionDb: -1.2, limiterMode: \"Kompressor\",\n");
        sb.append("          connectedStreams: 4, multiGuest: true, updatedAtUtc: new Date().toISOString()\n");
        sb.append("        },\n");
        sb.append("        selectedQuality: \"540p\",\n");
        sb.append("        chatMessages: [\n");
        sb.append("          { messageId: \"1\", participantKey: \"id:1\", author: \"Anna\", content: \"Guten Abend\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() },\n");
        sb.append("          { messageId: \"2\", participantKey: \"id:2\", author: \"Ben\", content: \"Welche Sorte ist das?\", contentLanguage: \"de-DE\", source: \"dom\", receivedAtUtc: new Date().toISOString() },\n");
        sb.append("          { messageId: \"3\", author: \"Clara\", content: \"Danke für die Erklärung\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() },\n");
        sb.append("          { messageId: \"4\", author: \"David\", content: \"Bitte einmal mischen\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() },\n");
        sb.append("          { messageId: \"5\", author: \"Eva\", content: \"Das ist gut lesbar\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() }\n");
        sb.append("        ],\n");
        sb.append("        participants: {\n");
        sb.append("          \"id:1\": { key: \"id:1\", name: \"Anna\", messageCount: 12, wordCount: 48, giftEventCount: 2, giftItemCount: 24, lastSeenAtUtc: new Date().toISOString() },\n");
        sb.append("          \"id:2\": { key: \"id:2\", name: \"Ben\", messageCount: 8, wordCount: 39, giftEventCount: 0, giftItemCount: 0, lastSeenAtUtc: new Date().toISOString() },\n");
        sb.append("          \"name:clara\": { key: \"name:clara\", name: \"Clara\", messageCount: 6, wordCount: 31, giftEventCount: 1, giftItemCount: 1, lastSeenAtUtc: new Date().toISOString() }\n");
        sb.append("        },\n");
        sb.append("        streamMutes: [],\n");
        sb.append("        participantsTruncated: false,\n");
        sb.append("        media: [\n");
        sb.append("          { url: \"https://pull.example.tiktokcdn.com/live/stream_hd.flv?expire=1&sign=test\", protocol: \"FLV\", quality: \"720p\", sdkKey: \"hd\", bitrate: 1800000, codec: \"h264\", width: 1280, height: 720, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn.com\", source: \"metadata\" },\n");
        sb.append("          { url: \"https://pull.example.tiktokcdn-eu.com/live/stream_720p.m3u8?sign=test\", protocol: \"HLS\", quality: \"720p\", sdkKey: \"hd\", bitrate: 1800000, codec: \"h264\", width: 1280, height: 720, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn-eu.com\", source: \"network\" },\n");
        sb.append("          { url: \"https://pull.example.tiktokcdn.com/live/stream_sd.flv?expire=1&sign=test\", protocol: \"FLV\", quality: \"540p\", sdkKey: \"sd\", bitrate: 900000, codec: \"h264\", width: 960, height: 540, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn.com\", source: \"metadata\" }\n");
        sb.append("        ],\n");
        sb.append("        captions: [\n");
        sb.append("          { receivedAtUtc: new Date().toISOString(), sentenceId: \"42\", definite: true, contents: [{ lang: \"de\", text: \"Dies ist eine Test-Caption.\" }] }\n");
        sb.append("        ],\n");
        sb.append("        debug: { enabled: false, entries: [{ atUtc: new Date().toISOString(), event: \"scan\", detail: { mediaCount: 3 } }] }\n");
        sb.append("      };\n");
        sb.append("\n");
        sb.append("      const stateListeners = [];\n");
        sb.append("      globalThis.chrome = {\n");
        sb.append("        tabs: {\n");
        sb.append("          query: async () => [{ id: 1, url: state.page.url, title: state.page.title }],\n");
        sb.append("          onActivated: { addListener() {} }\n");
        sb.append("        },\n");
        sb.append("        tabCapture: { capture(_options, callback) { callback(null); } },\n");
        sb.append("        runtime: {\n");
        sb.append("          sendMessage: async (message) => {\n");
        sb.append("            if (message.type === \"TLC_GET_STATE\") return { ok: true, state };\n");
        sb.append("            if (message.type === \"TLC_OPEN_EMBED_LIVE\") {\n");
        sb.append("              state.embedStartup = TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), \"demo\", Date.now());\n");
        sb.append("              return { ok: true, response: { activated: false, phase: \"loading\" } };\n");
        sb.append("            }\n");
        sb.append("            if (message.type === \"TLC_CANCEL_EMBED_STARTUP\" || message.type === \"TLC_OPEN_NORMAL_LIVE\") {\n");
        sb.append("              if (state.embedStartup) state.embedStartup = { ...state.embedStartup, phase: \"cancelled\", nextAttemptAtMs: null };\n");
        sb.append("              return { ok: true };\n");
        sb.append("            }\n");
        sb.append("            if (message.type === \"TLC_GET_SETTINGS\") return { ok: true, settings: { autoHook: true, keepSpeechActive: true, speechVolume: 0.5, speechLanguage: \"auto\", speakNames: true, shortenNames: false, serviceUrl: \"http://127.0.0.1:43117\", pairingCode: \"\", permanentMutes: [], quickRecoverEnabled: state.quickRecoverEnabled, quickRecoverSeconds: state.quickRecoverSeconds } };\n");
        sb.append("            if (message.type === \"TLC_SET_QUICK_RECOVER\") {\n");
        sb.append("              state.quickRecoverEnabled = Boolean(message.enabled);\n");
        sb.append("              state.quickRecoverSeconds = Math.max(1, Math.min(59, Math.round(Number(message.seconds) || 3)));\n");
        sb.append("              return { ok: true, state, seconds: state.quickRecoverSeconds };\n");
        sb.append("            }\n");
        sb.append("            if (message.type === \"TLC_GET_CAPTION_JSONL_EXPORT\") return { ok: true, records: TLC_EXPORT_PRIVACY.captions(state.captions) };\n");
        sb.append("            if (message.type === \"TLC_GET_CAPTION_RAW_EXPORT\") return { ok: true, report: TLC_EXPORT_PRIVACY.captionReport({\n");
        sb.append("              version: \"0.8.2\", generatedAtUtc: new Date().toISOString(), messages: state.captions,\n");
        sb.append("              dataStreams: state.media, data: { captionInfo: state.captionInfo, captionSources: state.captionSources, playerState: state.playerState }, stream: { page: state.page }\n");
        sb.append("            }) };\n");
        sb.append("            if (message.type === \"TLC_SCAN\") {\n");
        sb.append("              return { ok: true, response: { captionInfo: state.captionInfo, captionControl: true, mediaCount: state.media.length } };\n");
        sb.append("            }\n");
        sb.append("            if (message.type === \"TLC_GET_PLAYER_STATE\") return { ok: true, response: { playerState: state.playerState } };\n");
        sb.append("            if (message.type === \"TLC_PLAYER_ACTION\") {\n");
        sb.append("              if (message.action === \"toggle-play\") state.playerState.playing = !state.playerState.playing;\n");
        sb.append("              if (message.action === \"toggle-mute\") state.playerState.muted = !state.playerState.muted;\n");
        sb.append("              if (message.action === \"set-volume\") {\n");
        sb.append("                state.playerState.volume = Number(message.value);\n");
        sb.append("                state.playerState.volumePercent = Math.round(Number(message.value) * 100);\n");
        sb.append("                state.playerState.volumeGainDb = Number(message.value) > 0 ? 20 * Math.log10(Number(message.value)) : null;\n");
        sb.append("              }\n");
        sb.append("              if (message.action === \"set-limiter\") {\n");
        sb.append("                state.playerState.limiterEnabled = Boolean(message.enabled);\n");
        sb.append("                state.playerState.limiterThresholdDbfs = Number(message.thresholdDbfs);\n");
        sb.append("              }\n");
        sb.append("              return { ok: true, response: { activated: true, playerState: state.playerState } };\n");
        sb.append("            }\n");
        sb.append("            if (message.type === \"TLC_CLEAR_CHAT\") {\n");
        sb.append("              state.chatMessages = [];\n");
        sb.append("              return { ok: true };\n");
        sb.append("            }\n");
        sb.append("            if (message.type === \"TLC_SET_DEBUG\") {\n");
        sb.append("              state.debug.enabled = Boolean(message.enabled);\n");
        sb.append("              return { ok: true, state };\n");
        sb.append("            }\n");
        sb.append("            if (message.type === \"TLC_CLEAR_DEBUG\") {\n");
        sb.append("              state.debug.entries = [];\n");
        sb.append("              return { ok: true };\n");
        sb.append("            }\n");
        sb.append("            if (message.type === \"TLC_SET_MUTE\") return { ok: true, state, settings: { permanentMutes: [] } };\n");
        sb.append("            if (message.type === \"TLC_GET_DEBUG_REPORT\") return { ok: true, report: TLC_EXPORT_PRIVACY.diagnosticReport({ version: \"0.8.2\", debug: state.debug, page: state.page, media: state.media }) };\n");
        sb.append("            return { ok: true, response: { activated: true } };\n");
        sb.append("          },\n");
        sb.append("          onMessage: { addListener(listener) { stateListeners.push(listener); } }\n");
        sb.append("        }\n");
        sb.append("      };\n");
        sb.append("\n");
        sb.append("      const assetVersion = Date.now();\n");
        sb.append("      const source = await fetch(\"../browser-extension/sidepanel.html\", { cache: \"no-store\" }).then((response) => response.text());\n");
        sb.append("      const parsed = new DOMParser().parseFromString(source, \"text/html\");\n");
        sb.append("      document.title = parsed.title;\n");
        sb.append("      for (const child of [...parsed.body.children]) {\n");
        sb.append("        if (child.tagName !== \"SCRIPT\") document.body.append(document.importNode(child, true));\n");
        sb.append("      }\n");
        sb.append("      const css = document.createElement(\"link\");\n");
        sb.append("      css.rel = \"stylesheet\";\n");
        sb.append("      css.href = \"../browser-extension/sidepanel.css?v=0.7.0-1\";\n");
        sb.append("      document.head.append(css);\n");
        sb.append("      const coreScript = document.createElement(\"script\");\n");
        sb.append("      coreScript.src = `../browser-extension/content-core.js?v=${assetVersion}`;\n");
        sb.append("      coreScript.onload = () => {\n");
        sb.append("        document.getElementById(\"test-embed-scenario\").addEventListener(\"change\", (event) => {\n");
        sb.append("          state.embedStartup = {\n");
        sb.append("            ...TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), \"demo\", Date.now()),\n");
        sb.append("            phase: event.target.value, reason: \"server-error\", attempt: event.target.value === \"failed\" ? 3 : 1\n");
        sb.append("          };\n");
        sb.append("          stateListeners.forEach((listener) => listener({ type: \"TLC_STATE_UPDATED\", tabId: 1, state }));\n");
        sb.append("        });\n");
        sb.append("        document.getElementById(\"test-caption-scenario\").addEventListener(\"change\", (event) => {\n");
        sb.append("          const mode = event.target.value;\n");
        sb.append("          const observedAt = Date.now() - (mode === \"historical\" ? 60_000 : 0);\n");
        sb.append("          state.captions = mode === \"none\" ? [] : [\"DomCaption\", \"WebcastCaptionMessage\"].map((method) => ({\n");
        sb.append("            method, source: method === \"DomCaption\" ? \"dom\" : \"websocket\", receivedAtUtc: new Date(observedAt).toISOString(),\n");
        sb.append("            contents: [{ lang: \"de\", text: \"Dies ist eine Test-Caption.\" }]\n");
        sb.append("          }));\n");
        sb.append("          state.captionSources = TLC_CONTENT_CORE.captionSourceSnapshot();\n");
        sb.append("          if (mode === \"metadata\") state.captionSources.metadata = { present: true, open: true, supportLang: [\"de\"] };\n");
        sb.append("          else for (const caption of state.captions) state.captionSources = TLC_CONTENT_CORE.observeCaptionSource(state.captionSources, caption, observedAt);\n");
        sb.append("          state.captionInfo = TLC_CONTENT_CORE.summarizeCaptionSources(state.captionSources);\n");
        sb.append("          stateListeners.forEach((listener) => listener({ type: \"TLC_STATE_UPDATED\", tabId: 1, state }));\n");
        sb.append("        });\n");
        sb.append("        const privacyScript = document.createElement(\"script\");\n");
        sb.append("        privacyScript.src = `../browser-extension/export-privacy.js?v=${assetVersion}`;\n");
        sb.append("        privacyScript.onload = () => {\n");
        sb.append("          const script = document.createElement(\"script\");\n");
        sb.append("          script.src = `../browser-extension/sidepanel.js?v=${assetVersion}`;\n");
        sb.append("          document.body.append(script);\n");
        sb.append("        };\n");
        sb.append("        document.body.append(privacyScript);\n");
        sb.append("      };\n");
        sb.append("      document.body.append(coreScript);\n");
        sb.append("    })();\n");
        sb.append("  </script>\n");
        
        // Body end
        sb.append("</body>\n");
        
        // HTML end
        sb.append("</html>\n");
        
        return sb.toString();
    }
}
