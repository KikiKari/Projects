#!/usr/bin/env python3
# sidepanel-harness.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/sidepanel-harness.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/sidepanel-harness.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/sidepanel-harness.html
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/tests/sidepanel-harness.html
# Erzeugt: 2026-10-12 durch ABSTRACTIONS_MANAGER.py

import argparse
import json
from datetime import datetime, timedelta
import random
import string


def generate_html(output_file):
    """Generates the sidepanel test harness HTML content"""
    
    # Generate current timestamp for dynamic content
    current_time = datetime.utcnow().isoformat() + 'Z'
    
    # Create the HTML structure
    html_content = '''<!doctype html>
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
      const state = ''' + json.dumps(generate_state_data(current_time), indent=6) + ''';

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
      coreScript.src = `../browser-extension/content-core.js?v=${assetVersion}`;
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
        privacyScript.src = `../browser-extension/export-privacy.js?v=${assetVersion}`;
        privacyScript.onload = () => {
          const script = document.createElement("script");
          script.src = `../browser-extension/sidepanel.js?v=${assetVersion}`;
          document.body.append(script);
        };
        document.body.append(privacyScript);
      };
      document.body.append(coreScript);
    })();
  </script>
</body>
</html>'''

    # Write to file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_content)


def generate_state_data(current_time):
    """Generates the state data structure with current timestamps"""
    
    # Generate chat messages with current timestamps
    chat_messages = []
    authors = [("Anna", "id:1"), ("Ben", "id:2"), ("Clara", None), ("David", None), ("Eva", None)]
    base_time = datetime.utcnow()
    
    for i, (author, participant_key) in enumerate(authors):
        msg_time = (base_time - timedelta(seconds=len(chat_messages) * 10)).isoformat() + 'Z'
        message = {
            "messageId": str(i + 1),
            "author": author,
            "content": "",
            "contentLanguage": "de-DE",
            "source": "websocket" if author not in ["Ben"] else "dom",
            "receivedAtUtc": msg_time
        }
        
        if participant_key:
            message["participantKey"] = participant_key
            
        if author == "Anna":
            message["content"] = "Guten Abend"
        elif author == "Ben":
            message["content"] = "Welche Sorte ist das?"
        elif author == "Clara":
            message["content"] = "Danke für die Erklärung"
        elif author == "David":
            message["content"] = "Bitte einmal mischen"
        elif author == "Eva":
            message["content"] = "Das ist gut lesbar"
            
        chat_messages.append(message)
    
    # Generate participants data
    participants = {
        "id:1": {
            "key": "id:1",
            "name": "Anna",
            "messageCount": 12,
            "wordCount": 48,
            "giftEventCount": 2,
            "giftItemCount": 24,
            "lastSeenAtUtc": (datetime.utcnow() - timedelta(minutes=5)).isoformat() + 'Z'
        },
        "id:2": {
            "key": "id:2",
            "name": "Ben",
            "messageCount": 8,
            "wordCount": 39,
            "giftEventCount": 0,
            "giftItemCount": 0,
            "lastSeenAtUtc": (datetime.utcnow() - timedelta(minutes=3)).isoformat() + 'Z'
        },
        "name:clara": {
            "key": "name:clara",
            "name": "Clara",
            "messageCount": 6,
            "wordCount": 31,
            "giftEventCount": 1,
            "giftItemCount": 1,
            "lastSeenAtUtc": (datetime.utcnow() - timedelta(minutes=2)).isoformat() + 'Z'
        }
    }
    
    # Generate media streams
    media = [
        {
            "url": "https://pull.example.tiktokcdn.com/live/stream_hd.flv?expire=1&sign=test",
            "protocol": "FLV",
            "quality": "720p",
            "sdkKey": "hd",
            "bitrate": 1800000,
            "codec": "h264",
            "width": 1280,
            "height": 720,
            "fps": 30,
            "audioOnly": False,
            "hostname": "pull.example.tiktokcdn.com",
            "source": "metadata"
        },
        {
            "url": "https://pull.example.tiktokcdn-eu.com/live/stream_720p.m3u8?sign=test",
            "protocol": "HLS",
            "quality": "720p",
            "sdkKey": "hd",
            "bitrate": 1800000,
            "codec": "h264",
            "width": 1280,
            "height": 720,
            "fps": 30,
            "audioOnly": False,
            "hostname": "pull.example.tiktokcdn-eu.com",
            "source": "network"
        },
        {
            "url": "https://pull.example.tiktokcdn.com/live/stream_sd.flv?expire=1&sign=test",
            "protocol": "FLV",
            "quality": "540p",
            "sdkKey": "sd",
            "bitrate": 900000,
            "codec": "h264",
            "width": 960,
            "height": 540,
            "fps": 30,
            "audioOnly": False,
            "hostname": "pull.example.tiktokcdn.com",
            "source": "metadata"
        }
    ]
    
    # Generate captions
    captions = [
        {
            "receivedAtUtc": current_time,
            "sentenceId": "42",
            "definite": True,
            "contents": [{"lang": "de", "text": "Dies ist eine Test-Caption."}]
        }
    ]
    
    # Generate debug entries
    debug_entries = [
        {
            "atUtc": current_time,
            "event": "scan",
            "detail": {"mediaCount": 3}
        }
    ]
    
    # Main state structure
    state = {
        "page": {
            "url": "https://www.tiktok.com/@demo/live",
            "title": "Demo LIVE",
            "scannedAtUtc": current_time
        },
        "captionInfo": {
            "present": True,
            "open": True,
            "supportLang": ["de", "en"],
            "location": None,
            "showType": 1
        },
        "menuCaptionAvailable": True,
        "menuCaptionActive": False,
        "quickRecoverEnabled": False,
        "quickRecoverSeconds": 3,
        "profileInfo": {
            "present": True,
            "nickname": "Demo Creator",
            "uniqueId": "demo",
            "signature": "Barrierefreier Teststream",
            "followingCount": "12",
            "followerCount": "238800",
            "likeCount": "1800000",
            "live": True,
            "source": "metadata"
        },
        "aiSummaryInfo": {
            "featureFlagPresent": True,
            "featureEnabled": True,
            "text": "",
            "source": None,
            "overviewCardFound": True,
            "overviewCardHovered": True
        },
        "hook": {
            "armed": True,
            "installed": True,
            "connected": True,
            "lastError": None
        },
        "stream": {
            "key": "demo|123",
            "handle": "demo",
            "roomId": "123",
            "teamTag": "tmm",
            "teamEvidence": {}
        },
        "liveStats": {
            "viewerCount": "143",
            "totalViewers": "15842",
            "likeCount": "430200",
            "followEvents": 7,
            "shareEvents": 4,
            "shareCount": "19",
            "followerCount": "238800",
            "lastUpdatedUtc": current_time,
            "recentEventIds": []
        },
        "playerState": {
            "available": True,
            "playing": True,
            "muted": False,
            "elapsedText": "1:17:42",
            "pipActive": False,
            "fullscreenActive": False,
            "volume": 0.72,
            "volumePercent": 72,
            "volumeGainDb": -2.9,
            "peakDbfs": -8.4,
            "limiterEnabled": True,
            "limiterThresholdDbfs": -6,
            "limiterReductionDb": -1.2,
            "limiterMode": "Kompressor",
            "connectedStreams": 4,
            "multiGuest": True,
            "updatedAtUtc": current_time
        },
        "selectedQuality": "540p",
        "chatMessages": chat_messages,
        "participants": participants,
        "streamMutes": [],
        "participantsTruncated": False,
        "media": media,
        "captions": captions,
        "debug": {
            "enabled": False,
            "entries": debug_entries
        }
    }
    
    return state


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate Sidepanel Test Harness HTML')
    parser.add_argument('output_file', help='Output HTML file path')
    args = parser.parse_args()
    
    generate_html(args.output_file)
