#!/usr/bin/env tclsh
# sidepanel-harness.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/sidepanel-harness.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 script to generate sidepanel-harness.html
# This script creates the HTML document dynamically and writes it to a file

proc generate_sidepanel_harness {filename} {
    set html [generate_html_content]
    set fh [open $filename w]
    puts $fh $html
    close $fh
}

proc generate_html_content {} {
    set html {}
    append html {<!doctype html>}
    append html {\n<html lang="de">}
    append html {\n<head>}
    append html {\n  <meta charset="utf-8">}
    append html {\n  <meta name="viewport" content="width=device-width, initial-scale=1">}
    append html {\n  <title>Sidepanel Test Harness</title>}
    append html {\n</head>}
    append html {\n<body>}
    append html {\n  <script>}
    append html [generate_javascript_content]
    append html {\n  </script>}
    append html {\n</body>}
    append html {\n</html>}
    return $html
}

proc generate_javascript_content {} {
    set js {}
    append js {\n    (async () => }
    append js "{"
    append js {\n      const state = }
    append js "{"
    append js {\n        page: }
    set now [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt true]
    append js "{ url: \"https://www.tiktok.com/@demo/live\", title: \"Demo LIVE\", scannedAtUtc: \"$now\" }"
    append js {,}
    append js {\n        captionInfo: }
    append js "{ present: true, open: true, supportLang: \[\"de\", \"en\"\], location: null, showType: 1 }"
    append js {,}
    append js {\n        menuCaptionAvailable: true,}
    append js {\n        menuCaptionActive: false,}
    append js {\n        profileInfo: }
    append js "{"
    append js {\n          present: true, nickname: "Demo Creator", uniqueId: "demo", signature: "Barrierefreier Teststream",}
    append js {\n          followingCount: "12", followerCount: "238800", likeCount: "1800000", live: true, source: "metadata"}
    append js {\n        \}}
    append js {,}
    append js {\n        aiSummaryInfo: }
    append js "{ featureFlagPresent: true, featureEnabled: true, text: "", source: null, overviewCardFound: true, overviewCardHovered: true }"
    append js {,}
    append js {\n        hook: }
    append js "{ armed: true, installed: true, connected: true, lastError: null }"
    append js {,}
    append js {\n        stream: }
    append js "{ key: \"demo|123\", handle: \"demo\", roomId: \"123\", teamTag: \"tmm\", teamEvidence: \{\} }"
    append js {,}
    append js {\n        liveStats: }
    append js "{"
    append js {\n          viewerCount: "143", totalViewers: "15842", likeCount: "430200",}
    append js {\n          followEvents: 7, shareEvents: 4, shareCount: "19", followerCount: "238800",}
    append js {\n          lastUpdatedUtc: \"$now\", recentEventIds: \[\]}
    append js {\n        \}}
    append js {,}
    append js {\n        playerState: }
    append js "{"
    append js {\n          available: true, playing: true, muted: false, elapsedText: "1:17:42", pipActive: false, fullscreenActive: false,}
    append js {\n          volume: 0.72, volumePercent: 72, volumeGainDb: -2.9, peakDbfs: -8.4,}
    append js {\n          limiterEnabled: true, limiterThresholdDbfs: -6, limiterReductionDb: -1.2, limiterMode: "Kompressor",}
    append js {\n          connectedStreams: 4, multiGuest: true, updatedAtUtc: \"$now\"}
    append js {\n        \}}
    append js {,}
    append js {\n        selectedQuality: "540p",}
    append js {\n        chatMessages: \[}
    append js {\n          }
    append js "{ messageId: "1", participantKey: "id:1", author: "Anna", content: "Guten Abend", contentLanguage: "de-DE", source: "websocket", receivedAtUtc: \"$now\" }"
    append js {,}
    append js {\n          }
    append js "{ messageId: "2", participantKey: "id:2", author: "Ben", content: "Welche Sorte ist das?", contentLanguage: "de-DE", source: "dom", receivedAtUtc: \"$now\" }"
    append js {,}
    append js {\n          }
    append js "{ messageId: "3", author: "Clara", content: "Danke für die Erklärung", contentLanguage: "de-DE", source: "websocket", receivedAtUtc: \"$now\" }"
    append js {,}
    append js {\n          }
    append js "{ messageId: "4", author: "David", content: "Bitte einmal mischen", contentLanguage: "de-DE", source: "websocket", receivedAtUtc: \"$now\" }"
    append js {,}
    append js {\n          }
    append js "{ messageId: "5", author: "Eva", content: "Das ist gut lesbar", contentLanguage: "de-DE", source: "websocket", receivedAtUtc: \"$now\" }"
    append js {\n        \]}
    append js {,}
    append js {\n        participants: }
    append js "{"
    append js {\n          "id:1": }
    append js "{ key: "id:1", name: "Anna", messageCount: 12, wordCount: 48, giftEventCount: 2, giftItemCount: 24, lastSeenAtUtc: \"$now\" }"
    append js {,}
    append js {\n          "id:2": }
    append js "{ key: "id:2", name: "Ben", messageCount: 8, wordCount: 39, giftEventCount: 0, giftItemCount: 0, lastSeenAtUtc: \"$now\" }"
    append js {,}
    append js {\n          "name:clara": }
    append js "{ key: "name:clara", name: "Clara", messageCount: 6, wordCount: 31, giftEventCount: 1, giftItemCount: 1, lastSeenAtUtc: \"$now\" }"
    append js {\n        \}}
    append js {,}
    append js {\n        streamMutes: \[\],}
    append js {\n        participantsTruncated: false,}
    append js {\n        media: \[}
    append js {\n          }
    append js "{ url: "https://pull.example.tiktokcdn.com/live/stream_hd.flv?expire=1&sign=test", protocol: "FLV", quality: "720p", sdkKey: "hd", bitrate: 1800000, codec: "h264", width: 1280, height: 720, fps: 30, audioOnly: false, hostname: "pull.example.tiktokcdn.com", source: "metadata" }"
    append js {,}
    append js {\n          }
    append js "{ url: "https://pull.example.tiktokcdn-eu.com/live/stream_720p.m3u8?sign=test", protocol: "HLS", quality: "720p", sdkKey: "hd", bitrate: 1800000, codec: "h264", width: 1280, height: 720, fps: 30, audioOnly: false, hostname: "pull.example.tiktokcdn-eu.com", source: "network" }"
    append js {,}
    append js {\n          }
    append js "{ url: "https://pull.example.tiktokcdn.com/live/stream_sd.flv?expire=1&sign=test", protocol: "FLV", quality: "540p", sdkKey: "sd", bitrate: 900000, codec: "h264", width: 960, height: 540, fps: 30, audioOnly: false, hostname: "pull.example.tiktokcdn.com", source: "metadata" }"
    append js {\n        \]}
    append js {,}
    append js {\n        captions: \[}
    append js {\n          }
    append js "{ receivedAtUtc: \"$now\", sentenceId: "42", definite: true, contents: \[{ lang: "de", text: "Dies ist eine Test-Caption." }\] \}}"
    append js {\n        \]}
    append js {,}
    append js {\n        debug: }
    append js "{ enabled: false, entries: \[{ atUtc: \"$now\", event: "scan", detail: }
    append js "{ mediaCount: 3 \} \] \}}"
    append js {\n      \};}
    append js {\n\n      globalThis.chrome = }
    append js "{"
    append js {\n        tabs: }
    append js "{"
    append js {\n          query: async () => \[{ id: 1, url: state.page.url, title: state.page.title }\],}
    append js {\n          onActivated: }
    append js "{ addListener() {} \}"
    append js {\n        \},}
    append js {\n        tabCapture: }
    append js "{ capture(_options, callback) }
    append js "{ callback(null); \} \},}
    append js {\n        runtime: }
    append js "{"
    append js {\n          sendMessage: async (message) => }
    append js "{"
    append js {\n            if (message.type === "TLC_GET_STATE") return }
    append js "{ ok: true, state \};}
    append js {\n            if (message.type === "TLC_GET_SETTINGS") return }
    append js "{ ok: true, settings: }
    append js "{ autoHook: true, keepSpeechActive: true, speechVolume: 0.5, speechLanguage: "auto", speakNames: true, shortenNames: false, serviceUrl: "http://127.0.0.1:43117", pairingCode: "", permanentMutes: \[\] \} \};}
    append js {\n            if (message.type === "TLC_SCAN") }
    append js "{}
    append js {\n              return }
    append js "{ ok: true, response: }
    append js "{ captionInfo: state.captionInfo, captionControl: true, mediaCount: state.media.length \} \};}
    append js {\n            \}}
    append js {\n            if (message.type === "TLC_GET_PLAYER_STATE") return }
    append js "{ ok: true, response: }
    append js "{ playerState: state.playerState \} \};}
    append js {\n            if (message.type === "TLC_PLAYER_ACTION") }
    append js "{}
    append js {\n              if (message.action === "toggle-play") state.playerState.playing = !state.playerState.playing;}
    append js {\n              if (message.action === "toggle-mute") state.playerState.muted = !state.playerState.muted;}
    append js {\n              if (message.action === "set-volume") }
    append js "{}
    append js {\n                state.playerState.volume = Number(message.value);}
    append js {\n                state.playerState.volumePercent = Math.round(Number(message.value) * 100);}
    append js {\n                state.playerState.volumeGainDb = Number(message.value) > 0 ? 20 * Math.log10(Number(message.value)) : null;}
    append js {\n              \}}
    append js {\n              if (message.action === "set-limiter") }
    append js "{}
    append js {\n                state.playerState.limiterEnabled = Boolean(message.enabled);}
    append js {\n                state.playerState.limiterThresholdDbfs = Number(message.thresholdDbfs);}
    append js {\n              \}}
    append js {\n              return }
    append js "{ ok: true, response: }
    append js "{ activated: true, playerState: state.playerState \} \};}
    append js {\n            \}}
    append js {\n            if (message.type === "TLC_CLEAR_CHAT") }
    append js "{}
    append js {\n              state.chatMessages = \[\];}
    append js {\n              return }
    append js "{ ok: true \};}
    append js {\n            \}}
    append js {\n            if (message.type === "TLC_SET_DEBUG") }
    append js "{}
    append js {\n              state.debug.enabled = Boolean(message.enabled);}
    append js {\n              return }
    append js "{ ok: true, state \};}
    append js {\n            \}}
    append js {\n            if (message.type === "TLC_CLEAR_DEBUG") }
    append js "{}
    append js {\n              state.debug.entries = \[\];}
    append js {\n              return }
    append js "{ ok: true \};}
    append js {\n            \}}
    append js {\n            if (message.type === "TLC_SET_MUTE") return }
    append js "{ ok: true, state, settings: }
    append js "{ permanentMutes: \[\] \} \};}
    append js {\n            if (message.type === "TLC_GET_DEBUG_REPORT") return }
    append js "{ ok: true, report: }
    append js "{ version: "0.7.0", debug: state.debug \} \};}
    append js {\n            return }
    append js "{ ok: true, response: }
    append js "{ activated: true \} \};}
    append js {\n          \},}
    append js {\n          onMessage: }
    append js "{ addListener() {} \}}
    append js {\n        \}}
    append js {\n      \};}
    append js {\n\n      const source = await fetch("../browser-extension/sidepanel.html").then((response) => response.text());}
    append js {\n      const parsed = new DOMParser().parseFromString(source, "text/html");}
    append js {\n      document.title = parsed.title;}
    append js {\n      for (const child of \[...parsed.body.children\]) }
    append js "{}
    append js {\n        if (child.tagName !== "SCRIPT") document.body.append(document.importNode(child, true));}
    append js {\n      \}}
    append js {\n      const css = document.createElement("link");}
    append js {\n      css.rel = "stylesheet";}
    append js {\n      css.href = "../browser-extension/sidepanel.css?v=0.7.0-1";}
    append js {\n      document.head.append(css);}
    append js {\n      const coreScript = document.createElement("script");}
    append js {\n      coreScript.src = "../browser-extension/content-core.js";}
    append js {\n      coreScript.onload = () => }
    append js "{}
    append js {\n        const script = document.createElement("script");}
    append js {\n        script.src = "../browser-extension/sidepanel.js";}
    append js {\n        document.body.append(script);}
    append js {\n      \};}
    append js {\n      document.body.append(coreScript);}
    append js {\n    \})();}
    append js {\n  }
    return $js
}

# Main execution
if {$argc != 1} {
    puts "Usage: $argv0 <output-file>"
    exit 1
}

set output_file [lindex $argv 0]
generate_sidepanel_harness $output_file
puts "Generated $output_file"
