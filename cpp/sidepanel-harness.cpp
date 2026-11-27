// abstraction-provenance: {"artifact_sha256": "e5259a528e2725d0d1ecfa550d6bff9695ed4bdd1582a1ea2c99e108b2a3fb15", "source_sha256": "5cdd2168705597f720695d3eeea066c9b5361e819b3b2e47c23269290dddc1dd", "target_language": "cpp"}
// sidepanel-harness.html — portiert nach cpp
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/sidepanel-harness.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/sidepanel-harness.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/sidepanel-harness.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/sidepanel-harness.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <filesystem>

void writeHtmlFile(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Fehler beim Öffnen der Datei: " << filename << std::endl;
        return;
    }

    file << "<!doctype html>\n";
    file << "<html lang=\"de\">\n";
    file << "<head>\n";
    file << "  <meta charset=\"utf-8\">\n";
    file << "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n";
    file << "  <title>Sidepanel Test Harness</title>\n";
    file << "</head>\n";
    file << "<body>\n";
    file << "  <label>Caption-Testzustand\n";
    file << "    <select id=\"test-caption-scenario\">\n";
    file << "      <option value=\"metadata\">Seitenmetadaten</option>\n";
    file << "      <option value=\"mixed\">DOM und WebSocket aktuell</option>\n";
    file << "      <option value=\"historical\">Nur historische Captions</option>\n";
    file << "      <option value=\"none\">Keine Captions</option>\n";
    file << "    </select>\n";
    file << "  </label>\n";
    file << "  <label>Embed-Testzustand\n";
    file << "    <select id=\"test-embed-scenario\">\n";
    file << "      <option value=\"loading\">Startet</option>\n";
    file << "      <option value=\"retry-wait\">Serverfehler – Wiederanlauf</option>\n";
    file << "      <option value=\"awaiting-gesture\">Benutzeraktion nötig</option>\n";
    file << "      <option value=\"playing\">Wiedergabe bestätigt</option>\n";
    file << "      <option value=\"failed\">Versuche ausgeschöpft</option>\n";
    file << "    </select>\n";
    file << "  </label>\n";
    file << "  <script>\n";
    file << "    (async () => {\n";
    file << "      const state = {\n";
    file << "        page: { url: \"https://www.tiktok.com/@demo/live\", title: \"Demo LIVE\", scannedAtUtc: new Date().toISOString() },\n";
    file << "        captionInfo: { present: true, open: true, supportLang: [\"de\", \"en\"], location: null, showType: 1 },\n";
    file << "        menuCaptionAvailable: true,\n";
    file << "        menuCaptionActive: false,\n";
    file << "        quickRecoverEnabled: false,\n";
    file << "        quickRecoverSeconds: 3,\n";
    file << "        profileInfo: {\n";
    file << "          present: true, nickname: \"Demo Creator\", uniqueId: \"demo\", signature: \"Barrierefreier Teststream\",\n";
    file << "          followingCount: \"12\", followerCount: \"238800\", likeCount: \"1800000\", live: true, source: \"metadata\"\n";
    file << "        },\n";
    file << "        aiSummaryInfo: { featureFlagPresent: true, featureEnabled: true, text: \"\", source: null, overviewCardFound: true, overviewCardHovered: true },\n";
    file << "        hook: { armed: true, installed: true, connected: true, lastError: null },\n";
    file << "        stream: { key: \"demo|123\", handle: \"demo\", roomId: \"123\", teamTag: \"tmm\", teamEvidence: {} },\n";
    file << "        liveStats: {\n";
    file << "          viewerCount: \"143\", totalViewers: \"15842\", likeCount: \"430200\",\n";
    file << "          followEvents: 7, shareEvents: 4, shareCount: \"19\", followerCount: \"238800\",\n";
    file << "          lastUpdatedUtc: new Date().toISOString(), recentEventIds: []\n";
    file << "        },\n";
    file << "        playerState: {\n";
    file << "          available: true, playing: true, muted: false, elapsedText: \"1:17:42\", pipActive: false, fullscreenActive: false,\n";
    file << "          volume: 0.72, volumePercent: 72, volumeGainDb: -2.9, peakDbfs: -8.4,\n";
    file << "          limiterEnabled: true, limiterThresholdDbfs: -6, limiterReductionDb: -1.2, limiterMode: \"Kompressor\",\n";
    file << "          connectedStreams: 4, multiGuest: true, updatedAtUtc: new Date().toISOString()\n";
    file << "        },\n";
    file << "        selectedQuality: \"540p\",\n";
    file << "        chatMessages: [\n";
    file << "          { messageId: \"1\", participantKey: \"id:1\", author: \"Anna\", content: \"Guten Abend\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() },\n";
    file << "          { messageId: \"2\", participantKey: \"id:2\", author: \"Ben\", content: \"Welche Sorte ist das?\", contentLanguage: \"de-DE\", source: \"dom\", receivedAtUtc: new Date().toISOString() },\n";
    file << "          { messageId: \"3\", author: \"Clara\", content: \"Danke für die Erklärung\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() },\n";
    file << "          { messageId: \"4\", author: \"David\", content: \"Bitte einmal mischen\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() },\n";
    file << "          { messageId: \"5\", author: \"Eva\", content: \"Das ist gut lesbar\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: new Date().toISOString() }\n";
    file << "        ],\n";
    file << "        participants: {\n";
    file << "          \"id:1\": { key: \"id:1\", name: \"Anna\", messageCount: 12, wordCount: 48, giftEventCount: 2, giftItemCount: 24, lastSeenAtUtc: new Date().toISOString() },\n";
    file << "          \"id:2\": { key: \"id:2\", name: \"Ben\", messageCount: 8, wordCount: 39, giftEventCount: 0, giftItemCount: 0, lastSeenAtUtc: new Date().toISOString() },\n";
    file << "          \"name:clara\": { key: \"name:clara\", name: \"Clara\", messageCount: 6, wordCount: 31, giftEventCount: 1, giftItemCount: 1, lastSeenAtUtc: new Date().toISOString() }\n";
    file << "        },\n";
    file << "        streamMutes: [],\n";
    file << "        participantsTruncated: false,\n";
    file << "        media: [\n";
    file << "          { url: \"https://pull.example.tiktokcdn.com/live/stream_hd.flv?expire=1&sign=test\", protocol: \"FLV\", quality: \"720p\", sdkKey: \"hd\", bitrate: 1800000, codec: \"h264\", width: 1280, height: 720, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn.com\", source: \"metadata\" },\n";
    file << "          { url: \"https://pull.example.tiktokcdn-eu.com/live/stream_720p.m3u8?sign=test\", protocol: \"HLS\", quality: \"720p\", sdkKey: \"hd\", bitrate: 1800000, codec: \"h264\", width: 1280, height: 720, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn-eu.com\", source: \"network\" },\n";
    file << "          { url: \"https://pull.example.tiktokcdn.com/live/stream_sd.flv?expire=1&sign=test\", protocol: \"FLV\", quality: \"540p\", sdkKey: \"sd\", bitrate: 900000, codec: \"h264\", width: 960, height: 540, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn.com\", source: \"metadata\" }\n";
    file << "        ],\n";
    file << "        captions: [\n";
    file << "          { receivedAtUtc: new Date().toISOString(), sentenceId: \"42\", definite: true, contents: [{ lang: \"de\", text: \"Dies ist eine Test-Caption.\" }] }\n";
    file << "        ],\n";
    file << "        debug: { enabled: false, entries: [{ atUtc: new Date().toISOString(), event: \"scan\", detail: { mediaCount: 3 } }] }\n";
    file << "      };\n";
    file << "\n";
    file << "      const stateListeners = [];\n";
    file << "      globalThis.chrome = {\n";
    file << "        tabs: {\n";
    file << "          query: async () => [{ id: 1, url: state.page.url, title: state.page.title }],\n";
    file << "          onActivated: { addListener() {} }\n";
    file << "        },\n";
    file << "        tabCapture: { capture(_options, callback) { callback(null); } },\n";
    file << "        runtime: {\n";
    file << "          sendMessage: async (message) => {\n";
    file << "            if (message.type === \"TLC_GET_STATE\") return { ok: true, state };\n";
    file << "            if (message.type === \"TLC_OPEN_EMBED_LIVE\") {\n";
    file << "              state.embedStartup = TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), \"demo\", Date.now());\n";
    file << "              return { ok: true, response: { activated: false, phase: \"loading\" } };\n";
    file << "            }\n";
    file << "            if (message.type === \"TLC_CANCEL_EMBED_STARTUP\" || message.type === \"TLC_OPEN_NORMAL_LIVE\") {\n";
    file << "              if (state.embedStartup) state.embedStartup = { ...state.embedStartup, phase: \"cancelled\", nextAttemptAtMs: null };\n";
    file << "              return { ok: true };\n";
    file << "            }\n";
    file << "            if (message.type === \"TLC_GET_SETTINGS\") return { ok: true, settings: { autoHook: true, keepSpeechActive: true, speechVolume: 0.5, speechLanguage: \"auto\", speakNames: true, shortenNames: false, serviceUrl: \"http://127.0.0.1:43117\", pairingCode: \"\", permanentMutes: [], quickRecoverEnabled: state.quickRecoverEnabled, quickRecoverSeconds: state.quickRecoverSeconds } };\n";
    file << "            if (message.type === \"TLC_SET_QUICK_RECOVER\") {\n";
    file << "              state.quickRecoverEnabled = Boolean(message.enabled);\n";
    file << "              state.quickRecoverSeconds = Math.max(1, Math.min(59, Math.round(Number(message.seconds) || 3)));\n";
    file << "              return { ok: true, state, seconds: state.quickRecoverSeconds };\n";
    file << "            }\n";
    file << "            if (message.type === \"TLC_GET_CAPTION_JSONL_EXPORT\") return { ok: true, records: TLC_EXPORT_PRIVACY.captions(state.captions) };\n";
    file << "            if (message.type === \"TLC_GET_CAPTION_RAW_EXPORT\") return { ok: true, report: TLC_EXPORT_PRIVACY.captionReport({\n";
    file << "              version: \"0.8.2\", generatedAtUtc: new Date().toISOString(), messages: state.captions,\n";
    file << "              dataStreams: state.media, data: { captionInfo: state.captionInfo, captionSources: state.captionSources, playerState: state.playerState }, stream: { page: state.page }\n";
    file << "            }) };\n";
    file << "            if (message.type === \"TLC_SCAN\") {\n";
    file << "              return { ok: true, response: { captionInfo: state.captionInfo, captionControl: true, mediaCount: state.media.length } };\n";
    file << "            }\n";
    file << "            if (message.type === \"TLC_GET_PLAYER_STATE\") return { ok: true, response: { playerState: state.playerState } };\n";
    file << "            if (message.type === \"TLC_PLAYER_ACTION\") {\n";
    file << "              if (message.action === \"toggle-play\") state.playerState.playing = !state.playerState.playing;\n";
    file << "              if (message.action === \"toggle-mute\") state.playerState.muted = !state.playerState.muted;\n";
    file << "              if (message.action === \"set-volume\") {\n";
    file << "                state.playerState.volume = Number(message.value);\n";
    file << "                state.playerState.volumePercent = Math.round(Number(message.value) * 100);\n";
    file << "                state.playerState.volumeGainDb = Number(message.value) > 0 ? 20 * Math.log10(Number(message.value)) : null;\n";
    file << "              }\n";
    file << "              if (message.action === \"set-limiter\") {\n";
    file << "                state.playerState.limiterEnabled = Boolean(message.enabled);\n";
    file << "                state.playerState.limiterThresholdDbfs = Number(message.thresholdDbfs);\n";
    file << "              }\n";
    file << "              return { ok: true, response: { activated: true, playerState: state.playerState } };\n";
    file << "            }\n";
    file << "            if (message.type === \"TLC_CLEAR_CHAT\") {\n";
    file << "              state.chatMessages = [];\n";
    file << "              return { ok: true };\n";
    file << "            }\n";
    file << "            if (message.type === \"TLC_SET_DEBUG\") {\n";
    file << "              state.debug.enabled = Boolean(message.enabled);\n";
    file << "              return { ok: true, state };\n";
    file << "            }\n";
    file << "            if (message.type === \"TLC_CLEAR_DEBUG\") {\n";
    file << "              state.debug.entries = [];\n";
    file << "              return { ok: true };\n";
    file << "            }\n";
    file << "            if (message.type === \"TLC_SET_MUTE\") return { ok: true, state, settings: { permanentMutes: [] } };\n";
    file << "            if (message.type === \"TLC_GET_DEBUG_REPORT\") return { ok: true, report: TLC_EXPORT_PRIVACY.diagnosticReport({ version: \"0.8.2\", debug: state.debug, page: state.page, media: state.media }) };\n";
    file << "            return { ok: true, response: { activated: true } };\n";
    file << "          },\n";
    file << "          onMessage: { addListener(listener) { stateListeners.push(listener); } }\n";
    file << "        }\n";
    file << "      };\n";
    file << "\n";
    file << "      const assetVersion = Date.now();\n";
    file << "      const source = await fetch(\"../browser-extension/sidepanel.html\", { cache: \"no-store\" }).then((response) => response.text());\n";
    file << "      const parsed = new DOMParser().parseFromString(source, \"text/html\");\n";
    file << "      document.title = parsed.title;\n";
    file << "      for (const child of [...parsed.body.children]) {\n";
    file << "        if (child.tagName !== \"SCRIPT\") document.body.append(document.importNode(child, true));\n";
    file << "      }\n";
    file << "      const css = document.createElement(\"link\");\n";
    file << "      css.rel = \"stylesheet\";\n";
    file << "      css.href = \"../browser-extension/sidepanel.css?v=0.7.0-1\";\n";
    file << "      document.head.append(css);\n";
    file << "      const coreScript = document.createElement(\"script\");\n";
    file << "      coreScript.src = `../browser-extension/content-core.js?v=${assetVersion}`;\n";
    file << "      coreScript.onload = () => {\n";
    file << "        document.getElementById(\"test-embed-scenario\").addEventListener(\"change\", (event) => {\n";
    file << "          state.embedStartup = {\n";
    file << "            ...TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), \"demo\", Date.now()),\n";
    file << "            phase: event.target.value, reason: \"server-error\", attempt: event.target.value === \"failed\" ? 3 : 1\n";
    file << "          };\n";
    file << "          stateListeners.forEach((listener) => listener({ type: \"TLC_STATE_UPDATED\", tabId: 1, state }));\n";
    file << "        });\n";
    file << "        document.getElementById(\"test-caption-scenario\").addEventListener(\"change\", (event) => {\n";
    file << "          const mode = event.target.value;\n";
    file << "          const observedAt = Date.now() - (mode === \"historical\" ? 60_000 : 0);\n";
    file << "          state.captions = mode === \"none\" ? [] : [\"DomCaption\", \"WebcastCaptionMessage\"].map((method) => ({\n";
    file << "            method, source: method === \"DomCaption\" ? \"dom\" : \"websocket\", receivedAtUtc: new Date(observedAt).toISOString(),\n";
    file << "            contents: [{ lang: \"de\", text: \"Dies ist eine Test-Caption.\" }]\n";
    file << "          }));\n";
    file << "          state.captionSources = TLC_CONTENT_CORE.captionSourceSnapshot();\n";
    file << "          if (mode === \"metadata\") state.captionSources.metadata = { present: true, open: true, supportLang: [\"de\"] };\n";
    file << "          else for (const caption of state.captions) state.captionSources = TLC_CONTENT_CORE.observeCaptionSource(state.captionSources, caption, observedAt);\n";
    file << "          state.captionInfo = TLC_CONTENT_CORE.summarizeCaptionSources(state.captionSources);\n";
    file << "          stateListeners.forEach((listener) => listener({ type: \"TLC_STATE_UPDATED\", tabId: 1, state }));\n";
    file << "        });\n";
    file << "        const privacyScript = document.createElement(\"script\");\n";
    file << "        privacyScript.src = `../browser-extension/export-privacy.js?v=${assetVersion}`;\n";
    file << "        privacyScript.onload = () => {\n";
    file << "          const script = document.createElement(\"script\");\n";
    file << "          script.src = `../browser-extension/sidepanel.js?v=${assetVersion}`;\n";
    file << "          document.body.append(script);\n";
    file << "        };\n";
    file << "        document.body.append(privacyScript);\n";
    file << "      };\n";
    file << "      document.body.append(coreScript);\n";
    file << "    })();\n";
    file << "  </script>\n";
    file << "</body>\n";
    file << "</html>\n";

    file.close();
}

int main(int argc, char* argv[]) {
    std::string filename = "sidepanel-harness.html";
    
    if (argc > 1) {
        filename = argv[1];
    }
    
    writeHtmlFile(filename);
    
    return 0;
}
