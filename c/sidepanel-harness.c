// abstraction-provenance: {"artifact_sha256": "cf4641abc4c34d2e3bce08c3bf5e37ebcecf95dd9ec88982c6443ee6e4645631", "source_sha256": "5cdd2168705597f720695d3eeea066c9b5361e819b3b2e47c23269290dddc1dd", "target_language": "c"}
// sidepanel-harness.html — portiert nach c
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/sidepanel-harness.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/sidepanel-harness.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/sidepanel-harness.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/sidepanel-harness.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

void write_html_document(const char* filename) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        perror("Fehler beim Öffnen der Datei");
        exit(EXIT_FAILURE);
    }

    // Aktuelles Datum für dynamische Inhalte
    time_t now = time(NULL);
    struct tm* tm_now = localtime(&now);
    char date_str[100];
    strftime(date_str, sizeof(date_str), "%Y-%m-%dT%H:%M:%S", tm_now);

    fprintf(file, "<!doctype html>\n");
    fprintf(file, "<html lang=\"de\">\n");
    fprintf(file, "<head>\n");
    fprintf(file, "  <meta charset=\"utf-8\">\n");
    fprintf(file, "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
    fprintf(file, "  <title>Sidepanel Test Harness</title>\n");
    fprintf(file, "</head>\n");
    fprintf(file, "<body>\n");
    fprintf(file, "  <label>Caption-Testzustand\n");
    fprintf(file, "    <select id=\"test-caption-scenario\">\n");
    fprintf(file, "      <option value=\"metadata\">Seitenmetadaten</option>\n");
    fprintf(file, "      <option value=\"mixed\">DOM und WebSocket aktuell</option>\n");
    fprintf(file, "      <option value=\"historical\">Nur historische Captions</option>\n");
    fprintf(file, "      <option value=\"none\">Keine Captions</option>\n");
    fprintf(file, "    </select>\n");
    fprintf(file, "  </label>\n");
    fprintf(file, "  <label>Embed-Testzustand\n");
    fprintf(file, "    <select id=\"test-embed-scenario\">\n");
    fprintf(file, "      <option value=\"loading\">Startet</option>\n");
    fprintf(file, "      <option value=\"retry-wait\">Serverfehler – Wiederanlauf</option>\n");
    fprintf(file, "      <option value=\"awaiting-gesture\">Benutzeraktion nötig</option>\n");
    fprintf(file, "      <option value=\"playing\">Wiedergabe bestätigt</option>\n");
    fprintf(file, "      <option value=\"failed\">Versuche ausgeschöpft</option>\n");
    fprintf(file, "    </select>\n");
    fprintf(file, "  </label>\n");
    fprintf(file, "  <script>\n");
    fprintf(file, "    (async () => {\n");
    fprintf(file, "      const state = {\n");
    fprintf(file, "        page: { url: \"https://www.tiktok.com/@demo/live\", title: \"Demo LIVE\", scannedAtUtc: \"%s\" },\n", date_str);
    fprintf(file, "        captionInfo: { present: true, open: true, supportLang: [\"de\", \"en\"], location: null, showType: 1 },\n");
    fprintf(file, "        menuCaptionAvailable: true,\n");
    fprintf(file, "        menuCaptionActive: false,\n");
    fprintf(file, "        quickRecoverEnabled: false,\n");
    fprintf(file, "        quickRecoverSeconds: 3,\n");
    fprintf(file, "        profileInfo: {\n");
    fprintf(file, "          present: true, nickname: \"Demo Creator\", uniqueId: \"demo\", signature: \"Barrierefreier Teststream\",\n");
    fprintf(file, "          followingCount: \"12\", followerCount: \"238800\", likeCount: \"1800000\", live: true, source: \"metadata\"\n");
    fprintf(file, "        },\n");
    fprintf(file, "        aiSummaryInfo: { featureFlagPresent: true, featureEnabled: true, text: \"\", source: null, overviewCardFound: true, overviewCardHovered: true },\n");
    fprintf(file, "        hook: { armed: true, installed: true, connected: true, lastError: null },\n");
    fprintf(file, "        stream: { key: \"demo|123\", handle: \"demo\", roomId: \"123\", teamTag: \"tmm\", teamEvidence: {} },\n");
    fprintf(file, "        liveStats: {\n");
    fprintf(file, "          viewerCount: \"143\", totalViewers: \"15842\", likeCount: \"430200\",\n");
    fprintf(file, "          followEvents: 7, shareEvents: 4, shareCount: \"19\", followerCount: \"238800\",\n");
    fprintf(file, "          lastUpdatedUtc: \"%s\", recentEventIds: []\n", date_str);
    fprintf(file, "        },\n");
    fprintf(file, "        playerState: {\n");
    fprintf(file, "          available: true, playing: true, muted: false, elapsedText: \"1:17:42\", pipActive: false, fullscreenActive: false,\n");
    fprintf(file, "          volume: 0.72, volumePercent: 72, volumeGainDb: -2.9, peakDbfs: -8.4,\n");
    fprintf(file, "          limiterEnabled: true, limiterThresholdDbfs: -6, limiterReductionDb: -1.2, limiterMode: \"Kompressor\",\n");
    fprintf(file, "          connectedStreams: 4, multiGuest: true, updatedAtUtc: \"%s\"\n", date_str);
    fprintf(file, "        },\n");
    fprintf(file, "        selectedQuality: \"540p\",\n");
    fprintf(file, "        chatMessages: [\n");
    fprintf(file, "          { messageId: \"1\", participantKey: \"id:1\", author: \"Anna\", content: \"Guten Abend\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: \"%s\" },\n", date_str);
    fprintf(file, "          { messageId: \"2\", participantKey: \"id:2\", author: \"Ben\", content: \"Welche Sorte ist das?\", contentLanguage: \"de-DE\", source: \"dom\", receivedAtUtc: \"%s\" },\n", date_str);
    fprintf(file, "          { messageId: \"3\", author: \"Clara\", content: \"Danke für die Erklärung\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: \"%s\" },\n", date_str);
    fprintf(file, "          { messageId: \"4\", author: \"David\", content: \"Bitte einmal mischen\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: \"%s\" },\n", date_str);
    fprintf(file, "          { messageId: \"5\", author: \"Eva\", content: \"Das ist gut lesbar\", contentLanguage: \"de-DE\", source: \"websocket\", receivedAtUtc: \"%s\" }\n", date_str);
    fprintf(file, "        ],\n");
    fprintf(file, "        participants: {\n");
    fprintf(file, "          \"id:1\": { key: \"id:1\", name: \"Anna\", messageCount: 12, wordCount: 48, giftEventCount: 2, giftItemCount: 24, lastSeenAtUtc: \"%s\" },\n", date_str);
    fprintf(file, "          \"id:2\": { key: \"id:2\", name: \"Ben\", messageCount: 8, wordCount: 39, giftEventCount: 0, giftItemCount: 0, lastSeenAtUtc: \"%s\" },\n", date_str);
    fprintf(file, "          \"name:clara\": { key: \"name:clara\", name: \"Clara\", messageCount: 6, wordCount: 31, giftEventCount: 1, giftItemCount: 1, lastSeenAtUtc: \"%s\" }\n", date_str);
    fprintf(file, "        },\n");
    fprintf(file, "        streamMutes: [],\n");
    fprintf(file, "        participantsTruncated: false,\n");
    fprintf(file, "        media: [\n");
    fprintf(file, "          { url: \"https://pull.example.tiktokcdn.com/live/stream_hd.flv?expire=1&sign=test\", protocol: \"FLV\", quality: \"720p\", sdkKey: \"hd\", bitrate: 1800000, codec: \"h264\", width: 1280, height: 720, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn.com\", source: \"metadata\" },\n");
    fprintf(file, "          { url: \"https://pull.example.tiktokcdn-eu.com/live/stream_720p.m3u8?sign=test\", protocol: \"HLS\", quality: \"720p\", sdkKey: \"hd\", bitrate: 1800000, codec: \"h264\", width: 1280, height: 720, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn-eu.com\", source: \"network\" },\n");
    fprintf(file, "          { url: \"https://pull.example.tiktokcdn.com/live/stream_sd.flv?expire=1&sign=test\", protocol: \"FLV\", quality: \"540p\", sdkKey: \"sd\", bitrate: 900000, codec: \"h264\", width: 960, height: 540, fps: 30, audioOnly: false, hostname: \"pull.example.tiktokcdn.com\", source: \"metadata\" }\n");
    fprintf(file, "        ],\n");
    fprintf(file, "        captions: [\n");
    fprintf(file, "          { receivedAtUtc: \"%s\", sentenceId: \"42\", definite: true, contents: [{ lang: \"de\", text: \"Dies ist eine Test-Caption.\" }] }\n", date_str);
    fprintf(file, "        ],\n");
    fprintf(file, "        debug: { enabled: false, entries: [{ atUtc: \"%s\", event: \"scan\", detail: { mediaCount: 3 } }] }\n", date_str);
    fprintf(file, "      };\n");
    fprintf(file, "\n");
    fprintf(file, "      const stateListeners = [];\n");
    fprintf(file, "      globalThis.chrome = {\n");
    fprintf(file, "        tabs: {\n");
    fprintf(file, "          query: async () => [{ id: 1, url: state.page.url, title: state.page.title }],\n");
    fprintf(file, "          onActivated: { addListener() {} }\n");
    fprintf(file, "        },\n");
    fprintf(file, "        tabCapture: { capture(_options, callback) { callback(null); } },\n");
    fprintf(file, "        runtime: {\n");
    fprintf(file, "          sendMessage: async (message) => {\n");
    fprintf(file, "            if (message.type === \"TLC_GET_STATE\") return { ok: true, state };\n");
    fprintf(file, "            if (message.type === \"TLC_OPEN_EMBED_LIVE\") {\n");
    fprintf(file, "              state.embedStartup = TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), \"demo\", Date.now());\n");
    fprintf(file, "              return { ok: true, response: { activated: false, phase: \"loading\" } };\n");
    fprintf(file, "            }\n");
    fprintf(file, "            if (message.type === \"TLC_CANCEL_EMBED_STARTUP\" || message.type === \"TLC_OPEN_NORMAL_LIVE\") {\n");
    fprintf(file, "              if (state.embedStartup) state.embedStartup = { ...state.embedStartup, phase: \"cancelled\", nextAttemptAtMs: null };\n");
    fprintf(file, "              return { ok: true };\n");
    fprintf(file, "            }\n");
    fprintf(file, "            if (message.type === \"TLC_GET_SETTINGS\") return { ok: true, settings: { autoHook: true, keepSpeechActive: true, speechVolume: 0.5, speechLanguage: \"auto\", speakNames: true, shortenNames: false, serviceUrl: \"http://127.0.0.1:43117\", pairingCode: \"\", permanentMutes: [], quickRecoverEnabled: state.quickRecoverEnabled, quickRecoverSeconds: state.quickRecoverSeconds } };\n");
    fprintf(file, "            if (message.type === \"TLC_SET_QUICK_RECOVER\") {\n");
    fprintf(file, "              state.quickRecoverEnabled = Boolean(message.enabled);\n");
    fprintf(file, "              state.quickRecoverSeconds = Math.max(1, Math.min(59, Math.round(Number(message.seconds) || 3)));\n");
    fprintf(file, "              return { ok: true, state, seconds: state.quickRecoverSeconds };\n");
    fprintf(file, "            }\n");
    fprintf(file, "            if (message.type === \"TLC_GET_CAPTION_JSONL_EXPORT\") return { ok: true, records: TLC_EXPORT_PRIVACY.captions(state.captions) };\n");
    fprintf(file, "            if (message.type === \"TLC_GET_CAPTION_RAW_EXPORT\") return { ok: true, report: TLC_EXPORT_PRIVACY.captionReport({\n");
    fprintf(file, "              version: \"0.8.2\", generatedAtUtc: new Date().toISOString(), messages: state.captions,\n");
    fprintf(file, "              dataStreams: state.media, data: { captionInfo: state.captionInfo, captionSources: state.captionSources, playerState: state.playerState }, stream: { page: state.page }\n");
    fprintf(file, "            }) };\n");
    fprintf(file, "            if (message.type === \"TLC_SCAN\") {\n");
    fprintf(file, "              return { ok: true, response: { captionInfo: state.captionInfo, captionControl: true, mediaCount: state.media.length } };\n");
    fprintf(file, "            }\n");
    fprintf(file, "            if (message.type === \"TLC_GET_PLAYER_STATE\") return { ok: true, response: { playerState: state.playerState } };\n");
    fprintf(file, "            if (message.type === \"TLC_PLAYER_ACTION\") {\n");
    fprintf(file, "              if (message.action === \"toggle-play\") state.playerState.playing = !state.playerState.playing;\n");
    fprintf(file, "              if (message.action === \"toggle-mute\") state.playerState.muted = !state.playerState.muted;\n");
    fprintf(file, "              if (message.action === \"set-volume\") {\n");
    fprintf(file, "                state.playerState.volume = Number(message.value);\n");
    fprintf(file, "                state.playerState.volumePercent = Math.round(Number(message.value) * 100);\n");
    fprintf(file, "                state.playerState.volumeGainDb = Number(message.value) > 0 ? 20 * Math.log10(Number(message.value)) : null;\n");
    fprintf(file, "              }\n");
    fprintf(file, "              if (message.action === \"set-limiter\") {\n");
    fprintf(file, "                state.playerState.limiterEnabled = Boolean(message.enabled);\n");
    fprintf(file, "                state.playerState.limiterThresholdDbfs = Number(message.thresholdDbfs);\n");
    fprintf(file, "              }\n");
    fprintf(file, "              return { ok: true, response: { activated: true, playerState: state.playerState } };\n");
    fprintf(file, "            }\n");
    fprintf(file, "            if (message.type === \"TLC_CLEAR_CHAT\") {\n");
    fprintf(file, "              state.chatMessages = [];\n");
    fprintf(file, "              return { ok: true };\n");
    fprintf(file, "            }\n");
    fprintf(file, "            if (message.type === \"TLC_SET_DEBUG\") {\n");
    fprintf(file, "              state.debug.enabled = Boolean(message.enabled);\n");
    fprintf(file, "              return { ok: true, state };\n");
    fprintf(file, "            }\n");
    fprintf(file, "            if (message.type === \"TLC_CLEAR_DEBUG\") {\n");
    fprintf(file, "              state.debug.entries = [];\n");
    fprintf(file, "              return { ok: true };\n");
    fprintf(file, "            }\n");
    fprintf(file, "            if (message.type === \"TLC_SET_MUTE\") return { ok: true, state, settings: { permanentMutes: [] } };\n");
    fprintf(file, "            if (message.type === \"TLC_GET_DEBUG_REPORT\") return { ok: true, report: TLC_EXPORT_PRIVACY.diagnosticReport({ version: \"0.8.2\", debug: state.debug, page: state.page, media: state.media }) };\n");
    fprintf(file, "            return { ok: true, response: { activated: true } };\n");
    fprintf(file, "          },\n");
    fprintf(file, "          onMessage: { addListener(listener) { stateListeners.push(listener); } }\n");
    fprintf(file, "        }\n");
    fprintf(file, "      };\n");
    fprintf(file, "\n");
    fprintf(file, "      const assetVersion = Date.now();\n");
    fprintf(file, "      const source = await fetch(\"../browser-extension/sidepanel.html\", { cache: \"no-store\" }).then((response) => response.text());\n");
    fprintf(file, "      const parsed = new DOMParser().parseFromString(source, \"text/html\");\n");
    fprintf(file, "      document.title = parsed.title;\n");
    fprintf(file, "      for (const child of [...parsed.body.children]) {\n");
    fprintf(file, "        if (child.tagName !== \"SCRIPT\") document.body.append(document.importNode(child, true));\n");
    fprintf(file, "      }\n");
    fprintf(file, "      const css = document.createElement(\"link\");\n");
    fprintf(file, "      css.rel = \"stylesheet\";\n");
    fprintf(file, "      css.href = \"../browser-extension/sidepanel.css?v=0.7.0-1\";\n");
    fprintf(file, "      document.head.append(css);\n");
    fprintf(file, "      const coreScript = document.createElement(\"script\");\n");
    fprintf(file, "      coreScript.src = `../browser-extension/content-core.js?v=${assetVersion}`;\n");
    fprintf(file, "      coreScript.onload = () => {\n");
    fprintf(file, "        document.getElementById(\"test-embed-scenario\").addEventListener(\"change\", (event) => {\n");
    fprintf(file, "          state.embedStartup = {\n");
    fprintf(file, "            ...TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), \"demo\", Date.now()),\n");
    fprintf(file, "            phase: event.target.value, reason: \"server-error\", attempt: event.target.value === \"failed\" ? 3 : 1\n");
    fprintf(file, "          };\n");
    fprintf(file, "          stateListeners.forEach((listener) => listener({ type: \"TLC_STATE_UPDATED\", tabId: 1, state }));\n");
    fprintf(file, "        });\n");
    fprintf(file, "        document.getElementById(\"test-caption-scenario\").addEventListener(\"change\", (event) => {\n");
    fprintf(file, "          const mode = event.target.value;\n");
    fprintf(file, "          const observedAt = Date.now() - (mode === \"historical\" ? 60_000 : 0);\n");
    fprintf(file, "          state.captions = mode === \"none\" ? [] : [\"DomCaption\", \"WebcastCaptionMessage\"].map((method) => ({\n");
    fprintf(file, "            method, source: method === \"DomCaption\" ? \"dom\" : \"websocket\", receivedAtUtc: new Date(observedAt).toISOString(),\n");
    fprintf(file, "            contents: [{ lang: \"de\", text: \"Dies ist eine Test-Caption.\" }]\n");
    fprintf(file, "          }));\n");
    fprintf(file, "          state.captionSources = TLC_CONTENT_CORE.captionSourceSnapshot();\n");
    fprintf(file, "          if (mode === \"metadata\") state.captionSources.metadata = { present: true, open: true, supportLang: [\"de\"] };\n");
    fprintf(file, "          else for (const caption of state.captions) state.captionSources = TLC_CONTENT_CORE.observeCaptionSource(state.captionSources, caption, observedAt);\n");
    fprintf(file, "          state.captionInfo = TLC_CONTENT_CORE.summarizeCaptionSources(state.captionSources);\n");
    fprintf(file, "          stateListeners.forEach((listener) => listener({ type: \"TLC_STATE_UPDATED\", tabId: 1, state }));\n");
    fprintf(file, "        });\n");
    fprintf(file, "        const privacyScript = document.createElement(\"script\");\n");
    fprintf(file, "        privacyScript.src = `../browser-extension/export-privacy.js?v=${assetVersion}`;\n");
    fprintf(file, "        privacyScript.onload = () => {\n");
    fprintf(file, "          const script = document.createElement(\"script\");\n");
    fprintf(file, "          script.src = `../browser-extension/sidepanel.js?v=${assetVersion}`;\n");
    fprintf(file, "          document.body.append(script);\n");
    fprintf(file, "        };\n");
    fprintf(file, "        document.body.append(privacyScript);\n");
    fprintf(file, "      };\n");
    fprintf(file, "      document.body.append(coreScript);\n");
    fprintf(file, "    })();\n");
    fprintf(file, "  </script>\n");
    fprintf(file, "</body>\n");
    fprintf(file, "</html>\n");

    fclose(file);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Verwendung: %s <ausgabedatei.html>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    write_html_document(argv[1]);
    printf("HTML-Dokument wurde erfolgreich in '%s' geschrieben.\n", argv[1]);

    return EXIT_SUCCESS;
}
