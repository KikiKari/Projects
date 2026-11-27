// abstraction-provenance: {"artifact_sha256": "be7ba332416dc29ac82ef8424c61b27b419a557346e92950b6ef1167e490068e", "source_sha256": "4159b73c8ded244c9ae43694ca2c07c881918152d298b40260e15287bef2606f", "target_language": "go"}
// sidepanel-harness.html — portiert nach go
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/sidepanel-harness.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"time"
)

func main() {
	outputFile := flag.String("output", "sidepanel-harness.html", "Ausgabedatei")
	flag.Parse()

	htmlContent := generateHTML()
	
	if err := os.WriteFile(*outputFile, []byte(htmlContent), 0644); err != nil {
		fmt.Fprintf(os.Stderr, "Fehler beim Schreiben der Datei: %v\n", err)
		os.Exit(1)
	}
}

func generateHTML() string {
	now := time.Now().Format(time.RFC3339)
	
	return `<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sidepanel Test Harness</title>
</head>
<body>
  <label>Caption-Testzustand
    <select id="test-caption-scenario">
      <option value="metadata">Seitenmetadaten</option>
      <option value="mixed">DOM und WebSocket aktuell</option>
      <option value="historical">Nur historische Captions</option>
      <option value="none">Keine Captions</option>
    </select>
  </label>
  <label>Embed-Testzustand
    <select id="test-embed-scenario">
      <option value="loading">Startet</option>
      <option value="retry-wait">Serverfehler – Wiederanlauf</option>
      <option value="awaiting-gesture">Benutzeraktion nötig</option>
      <option value="playing">Wiedergabe bestätigt</option>
      <option value="failed">Versuche ausgeschöpft</option>
    </select>
  </label>
  <script>
    (async () => {
      const state = ` + getStateJSON(now) + `;

      const stateListeners = [];
      globalThis.chrome = {
        tabs: {
          query: async () => [{ id: 1, url: state.page.url, title: state.page.title }],
          onActivated: { addListener() {} }
        },
        tabCapture: { capture(_options, callback) { callback(null); } },
        runtime: {
          sendMessage: async (message) => {
            if (message.type === "TLC_GET_STATE") return { ok: true, state };
            if (message.type === "TLC_OPEN_EMBED_LIVE") {
              state.embedStartup = TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), "demo", Date.now());
              return { ok: true, response: { activated: false, phase: "loading" } };
            }
            if (message.type === "TLC_CANCEL_EMBED_STARTUP" || message.type === "TLC_OPEN_NORMAL_LIVE") {
              if (state.embedStartup) state.embedStartup = { ...state.embedStartup, phase: "cancelled", nextAttemptAtMs: null };
              return { ok: true };
            }
            if (message.type === "TLC_GET_SETTINGS") return { ok: true, settings: { autoHook: true, keepSpeechActive: true, speechVolume: 0.5, speechLanguage: "auto", speakNames: true, shortenNames: false, serviceUrl: "http://127.0.0.1:43117", pairingCode: "", permanentMutes: [], quickRecoverEnabled: state.quickRecoverEnabled, quickRecoverSeconds: state.quickRecoverSeconds } };
            if (message.type === "TLC_SET_QUICK_RECOVER") {
              state.quickRecoverEnabled = Boolean(message.enabled);
              state.quickRecoverSeconds = Math.max(1, Math.min(59, Math.round(Number(message.seconds) || 3)));
              return { ok: true, state, seconds: state.quickRecoverSeconds };
            }
            if (message.type === "TLC_GET_CAPTION_JSONL_EXPORT") return { ok: true, records: TLC_EXPORT_PRIVACY.captions(state.captions) };
            if (message.type === "TLC_GET_CAPTION_RAW_EXPORT") return { ok: true, report: TLC_EXPORT_PRIVACY.captionReport({
              version: "0.8.2", generatedAtUtc: new Date().toISOString(), messages: state.captions,
              dataStreams: state.media, data: { captionInfo: state.captionInfo, captionSources: state.captionSources, playerState: state.playerState }, stream: { page: state.page }
            }) };
            if (message.type === "TLC_SCAN") {
              return { ok: true, response: { captionInfo: state.captionInfo, captionControl: true, mediaCount: state.media.length } };
            }
            if (message.type === "TLC_GET_PLAYER_STATE") return { ok: true, response: { playerState: state.playerState } };
            if (message.type === "TLC_PLAYER_ACTION") {
              if (message.action === "toggle-play") state.playerState.playing = !state.playerState.playing;
              if (message.action === "toggle-mute") state.playerState.muted = !state.playerState.muted;
              if (message.action === "set-volume") {
                state.playerState.volume = Number(message.value);
                state.playerState.volumePercent = Math.round(Number(message.value) * 100);
                state.playerState.volumeGainDb = Number(message.value) > 0 ? 20 * Math.log10(Number(message.value)) : null;
              }
              if (message.action === "set-limiter") {
                state.playerState.limiterEnabled = Boolean(message.enabled);
                state.playerState.limiterThresholdDbfs = Number(message.thresholdDbfs);
              }
              return { ok: true, response: { activated: true, playerState: state.playerState } };
            }
            if (message.type === "TLC_CLEAR_CHAT") {
              state.chatMessages = [];
              return { ok: true };
            }
            if (message.type === "TLC_SET_DEBUG") {
              state.debug.enabled = Boolean(message.enabled);
              return { ok: true, state };
            }
            if (message.type === "TLC_CLEAR_DEBUG") {
              state.debug.entries = [];
              return { ok: true };
            }
            if (message.type === "TLC_SET_MUTE") return { ok: true, state, settings: { permanentMutes: [] } };
            if (message.type === "TLC_GET_DEBUG_REPORT") return { ok: true, report: TLC_EXPORT_PRIVACY.diagnosticReport({ version: "0.8.2", debug: state.debug, page: state.page, media: state.media }) };
            return { ok: true, response: { activated: true } };
          },
          onMessage: { addListener(listener) { stateListeners.push(listener); } }
        }
      };

      const assetVersion = Date.now();
      const source = await fetch("../browser-extension/sidepanel.html", { cache: "no-store" }).then((response) => response.text());
      const parsed = new DOMParser().parseFromString(source, "text/html");
      document.title = parsed.title;
      for (const child of [...parsed.body.children]) {
        if (child.tagName !== "SCRIPT") document.body.append(document.importNode(child, true));
      }
      const css = document.createElement("link");
      css.rel = "stylesheet";
      css.href = "../browser-extension/sidepanel.css?v=0.7.0-1";
      document.head.append(css);
      const coreScript = document.createElement("script");
      coreScript.src = ` + "`" + `../browser-extension/content-core.js?v=${assetVersion}` + "`" + `;
      coreScript.onload = () => {
        document.getElementById("test-embed-scenario").addEventListener("change", (event) => {
          state.embedStartup = {
            ...TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), "demo", Date.now()),
            phase: event.target.value, reason: "server-error", attempt: event.target.value === "failed" ? 3 : 1
          };
          stateListeners.forEach((listener) => listener({ type: "TLC_STATE_UPDATED", tabId: 1, state }));
        });
        document.getElementById("test-caption-scenario").addEventListener("change", (event) => {
          const mode = event.target.value;
          const observedAt = Date.now() - (mode === "historical" ? 60_000 : 0);
          state.captions = mode === "none" ? [] : ["DomCaption", "WebcastCaptionMessage"].map((method) => ({
            method, source: method === "DomCaption" ? "dom" : "websocket", receivedAtUtc: new Date(observedAt).toISOString(),
            contents: [{ lang: "de", text: "Dies ist eine Test-Caption." }]
          }));
          state.captionSources = TLC_CONTENT_CORE.captionSourceSnapshot();
          if (mode === "metadata") state.captionSources.metadata = { present: true, open: true, supportLang: ["de"] };
          else for (const caption of state.captions) state.captionSources = TLC_CONTENT_CORE.observeCaptionSource(state.captionSources, caption, observedAt);
          state.captionInfo = TLC_CONTENT_CORE.summarizeCaptionSources(state.captionSources);
          stateListeners.forEach((listener) => listener({ type: "TLC_STATE_UPDATED", tabId: 1, state }));
        });
        const privacyScript = document.createElement("script");
        privacyScript.src = ` + "`" + `../browser-extension/export-privacy.js?v=${assetVersion}` + "`" + `;
        privacyScript.onload = () => {
          const script = document.createElement("script");
          script.src = ` + "`" + `../browser-extension/sidepanel.js?v=${assetVersion}` + "`" + `;
          document.body.append(script);
        };
        document.body.append(privacyScript);
      };
      document.body.append(coreScript);
    })();
  </script>
</body>
</html>`
}

func getStateJSON(now string) string {
	state := map[string]interface{}{
		"page": map[string]interface{}{
			"url":         "https://www.tiktok.com/@demo/live",
			"title":       "Demo LIVE",
			"scannedAtUtc": now,
		},
		"captionInfo": map[string]interface{}{
			"present":       true,
			"open":          true,
			"supportLang":   []string{"de", "en"},
			"location":      nil,
			"showType":      1,
		},
		"menuCaptionAvailable": true,
		"menuCaptionActive":    false,
		"quickRecoverEnabled":  false,
		"quickRecoverSeconds":  3,
		"profileInfo": map[string]interface{}{
			"present":        true,
			"nickname":       "Demo Creator",
			"uniqueId":       "demo",
			"signature":      "Barrierefreier Teststream",
			"followingCount": "12",
			"followerCount":  "238800",
			"likeCount":      "1800000",
			"live":           true,
			"source":         "metadata",
		},
		"aiSummaryInfo": map[string]interface{}{
			"featureFlagPresent":  true,
			"featureEnabled":      true,
			"text":                "",
			"source":              nil,
			"overviewCardFound":   true,
			"overviewCardHovered": true,
		},
		"hook": map[string]interface{}{
			"armed":     true,
			"installed": true,
			"connected": true,
			"lastError": nil,
		},
		"stream": map[string]interface{}{
			"key":          "demo|123",
			"handle":       "demo",
			"roomId":       "123",
			"teamTag":      "tmm",
			"teamEvidence": map[string]interface{}{},
		},
		"liveStats": map[string]interface{}{
			"viewerCount":        "143",
			"totalViewers":       "15842",
			"likeCount":          "430200",
			"followEvents":       7,
			"shareEvents":        4,
			"shareCount":         "19",
			"followerCount":      "238800",
			"lastUpdatedUtc":     now,
			"recentEventIds":     []interface{}{},
		},
		"playerState": map[string]interface{}{
			"available":             true,
			"playing":               true,
			"muted":                 false,
			"elapsedText":           "1:17:42",
			"pipActive":             false,
			"fullscreenActive":      false,
			"volume":                0.72,
			"volumePercent":         72,
			"volumeGainDb":          -2.9,
			"peakDbfs":              -8.4,
			"limiterEnabled":        true,
			"limiterThresholdDbfs":  -6,
			"limiterReductionDb":    -1.2,
			"limiterMode":           "Kompressor",
			"connectedStreams":      4,
			"multiGuest":            true,
			"updatedAtUtc":          now,
		},
		"selectedQuality": "540p",
		"chatMessages": []map[string]interface{}{
			{
				"messageId":         "1",
				"participantKey":    "id:1",
				"author":            "Anna",
				"content":           "Guten Abend",
				"contentLanguage":   "de-DE",
				"source":            "websocket",
				"receivedAtUtc":     now,
			},
			{
				"messageId":         "2",
				"participantKey":    "id:2",
				"author":            "Ben",
				"content":           "Welche Sorte ist das?",
				"contentLanguage":   "de-DE",
				"source":            "dom",
				"receivedAtUtc":     now,
			},
			{
				"messageId":         "3",
				"author":            "Clara",
				"content":           "Danke für die Erklärung",
				"contentLanguage":   "de-DE",
				"source":            "websocket",
				"receivedAtUtc":     now,
			},
			{
				"messageId":         "4",
				"author":            "David",
				"content":           "Bitte einmal mischen",
				"contentLanguage":   "de-DE",
				"source":            "websocket",
				"receivedAtUtc":     now,
			},
			{
				"messageId":         "5",
				"author":            "Eva",
				"content":           "Das ist gut lesbar",
				"contentLanguage":   "de-DE",
				"source":            "websocket",
				"receivedAtUtc":     now,
			},
		},
		"participants": map[string]map[string]interface{}{
			"id:1": {
				"key":              "id:1",
				"name":             "Anna",
				"messageCount":    12,
				"wordCount":        48,
				"giftEventCount":  2,
				"giftItemCount":    24,
				"lastSeenAtUtc":    now,
			},
			"id:2": {
				"key":              "id:2",
				"name":             "Ben",
				"messageCount":     8,
				"wordCount":        39,
				"giftEventCount":   0,
				"giftItemCount":    0,
				"lastSeenAtUtc":    now,
			},
			"name:clara": {
				"key":              "name:clara",
				"name":             "Clara",
				"messageCount":    6,
				"wordCount":        31,
				"giftEventCount":   1,
				"giftItemCount":    1,
				"lastSeenAtUtc":    now,
			},
		},
		"streamMutes":         []interface{}{},
		"participantsTruncated": false,
		"media": []map[string]interface{}{
			{
				"url":        "https://pull.example.tiktokcdn.com/live/stream_hd.flv?expire=1&sign=test",
				"protocol":   "FLV",
				"quality":    "720p",
				"sdkKey":     "hd",
				"bitrate":    1800000,
				"codec":      "h264",
				"width":      1280,
				"height":     720,
				"fps":        30,
				"audioOnly":  false,
				"hostname":   "pull.example.tiktokcdn.com",
				"source":     "metadata",
			},
			{
				"url":        "https://pull.example.tiktokcdn-eu.com/live/stream_720p.m3u8?sign=test",
				"protocol":   "HLS",
				"quality":    "720p",
				"sdkKey":     "hd",
				"bitrate":    1800000,
				"codec":      "h264",
				"width":      1280,
				"height":     720,
				"fps":        30,
				"audioOnly":  false,
				"hostname":   "pull.example.tiktokcdn-eu.com",
				"source":     "network",
			},
			{
				"url":        "https://pull.example.tiktokcdn.com/live/stream_sd.flv?expire=1&sign=test",
				"protocol":   "FLV",
				"quality":    "540p",
				"sdkKey":     "sd",
				"bitrate":    900000,
				"codec":      "h264",
				"width":      960,
				"height":     540,
				"fps":        30,
				"audioOnly":  false,
				"hostname":   "pull.example.tiktokcdn.com",
				"source":     "metadata",
			},
		},
		"captions": []map[string]interface{}{
			{
				"receivedAtUtc": now,
				"sentenceId":    "42",
				"definite":      true,
				"contents": []map[string]string{
					{"lang": "de", "text": "Dies ist eine Test-Caption."},
				},
			},
		},
		"debug": map[string]interface{}{
			"enabled": false,
			"entries": []map[string]interface{}{
				{
					"atUtc":   now,
					"event":   "scan",
					"detail": map[string]int{"mediaCount": 3},
				},
			},
		},
	}
	
	jsonBytes, _ := json.MarshalIndent(state, "", "        ")
	return string(jsonBytes)
}
