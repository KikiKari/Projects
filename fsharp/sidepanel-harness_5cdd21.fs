// abstraction-provenance: {"artifact_sha256": "8eb97ba2d866c1abdadb9d5a0bca0895bd0a9bd0028da5cab362e584c55049a0", "source_sha256": "5cdd2168705597f720695d3eeea066c9b5361e819b3b2e47c23269290dddc1dd", "target_language": "fsharp"}
// sidepanel-harness.html — portiert nach fsharp
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/sidepanel-harness.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/sidepanel-harness.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/sidepanel-harness.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/sidepanel-harness.html
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text.Json
open System.Collections.Generic

type Page = {
    Url: string
    Title: string
    ScannedAtUtc: string
}

type CaptionInfo = {
    Present: bool
    Open: bool
    SupportLang: string array
    Location: string option
    ShowType: int
}

type ProfileInfo = {
    Present: bool
    Nickname: string
    UniqueId: string
    Signature: string
    FollowingCount: string
    FollowerCount: string
    LikeCount: string
    Live: bool
    Source: string
}

type AiSummaryInfo = {
    FeatureFlagPresent: bool
    FeatureEnabled: bool
    Text: string
    Source: string option
    OverviewCardFound: bool
    OverviewCardHovered: bool
}

type Hook = {
    Armed: bool
    Installed: bool
    Connected: bool
    LastError: string option
}

type Stream = {
    Key: string
    Handle: string
    RoomId: string
    TeamTag: string
    TeamEvidence: Dictionary<string, obj>
}

type LiveStats = {
    ViewerCount: string
    TotalViewers: string
    LikeCount: string
    FollowEvents: int
    ShareEvents: int
    ShareCount: string
    FollowerCount: string
    LastUpdatedUtc: string
    RecentEventIds: string array
}

type PlayerState = {
    Available: bool
    Playing: bool
    Muted: bool
    ElapsedText: string
    PipActive: bool
    FullscreenActive: bool
    Volume: float
    VolumePercent: int
    VolumeGainDb: float option
    PeakDbfs: float
    LimiterEnabled: bool
    LimiterThresholdDbfs: float
    LimiterReductionDb: float
    LimiterMode: string
    ConnectedStreams: int
    MultiGuest: bool
    UpdatedAtUtc: string
}

type ChatMessage = {
    MessageId: string
    ParticipantKey: string option
    Author: string
    Content: string
    ContentLanguage: string
    Source: string
    ReceivedAtUtc: string
}

type Participant = {
    Key: string
    Name: string
    MessageCount: int
    WordCount: int
    GiftEventCount: int
    GiftItemCount: int
    LastSeenAtUtc: string
}

type Media = {
    Url: string
    Protocol: string
    Quality: string
    SdkKey: string
    Bitrate: int
    Codec: string
    Width: int
    Height: int
    Fps: int
    AudioOnly: bool
    Hostname: string
    Source: string
}

type CaptionContent = {
    Lang: string
    Text: string
}

type Caption = {
    ReceivedAtUtc: string
    SentenceId: string option
    Definite: bool
    Contents: CaptionContent array
}

type DebugEntry = {
    AtUtc: string
    Event: string
    Detail: obj
}

type Debug = {
    Enabled: bool
    Entries: DebugEntry array
}

type State = {
    Page: Page
    CaptionInfo: CaptionInfo
    MenuCaptionAvailable: bool
    MenuCaptionActive: bool
    QuickRecoverEnabled: bool
    QuickRecoverSeconds: int
    ProfileInfo: ProfileInfo
    AiSummaryInfo: AiSummaryInfo
    Hook: Hook
    Stream: Stream
    LiveStats: LiveStats
    PlayerState: PlayerState
    SelectedQuality: string
    ChatMessages: ChatMessage array
    Participants: Map<string, Participant>
    StreamMutes: string array
    ParticipantsTruncated: bool
    Media: Media array
    Captions: Caption array
    Debug: Debug
}

let createState() =
    let now = DateTime.UtcNow.ToString("o")
    {
        Page = { 
            Url = "https://www.tiktok.com/@demo/live"
            Title = "Demo LIVE"
            ScannedAtUtc = now
        }
        CaptionInfo = {
            Present = true
            Open = true
            SupportLang = [| "de"; "en" |]
            Location = None
            ShowType = 1
        }
        MenuCaptionAvailable = true
        MenuCaptionActive = false
        QuickRecoverEnabled = false
        QuickRecoverSeconds = 3
        ProfileInfo = {
            Present = true
            Nickname = "Demo Creator"
            UniqueId = "demo"
            Signature = "Barrierefreier Teststream"
            FollowingCount = "12"
            FollowerCount = "238800"
            LikeCount = "1800000"
            Live = true
            Source = "metadata"
        }
        AiSummaryInfo = {
            FeatureFlagPresent = true
            FeatureEnabled = true
            Text = ""
            Source = None
            OverviewCardFound = true
            OverviewCardHovered = true
        }
        Hook = {
            Armed = true
            Installed = true
            Connected = true
            LastError = None
        }
        Stream = {
            Key = "demo|123"
            Handle = "demo"
            RoomId = "123"
            TeamTag = "tmm"
            TeamEvidence = Dictionary<string, obj>()
        }
        LiveStats = {
            ViewerCount = "143"
            TotalViewers = "15842"
            LikeCount = "430200"
            FollowEvents = 7
            ShareEvents = 4
            ShareCount = "19"
            FollowerCount = "238800"
            LastUpdatedUtc = now
            RecentEventIds = [||]
        }
        PlayerState = {
            Available = true
            Playing = true
            Muted = false
            ElapsedText = "1:17:42"
            PipActive = false
            FullscreenActive = false
            Volume = 0.72
            VolumePercent = 72
            VolumeGainDb = Some(-2.9)
            PeakDbfs = -8.4
            LimiterEnabled = true
            LimiterThresholdDbfs = -6.0
            LimiterReductionDb = -1.2
            LimiterMode = "Kompressor"
            ConnectedStreams = 4
            MultiGuest = true
            UpdatedAtUtc = now
        }
        SelectedQuality = "540p"
        ChatMessages = [|
            { 
                MessageId = "1"
                ParticipantKey = Some("id:1")
                Author = "Anna"
                Content = "Guten Abend"
                ContentLanguage = "de-DE"
                Source = "websocket"
                ReceivedAtUtc = now
            }
            {
                MessageId = "2"
                ParticipantKey = Some("id:2")
                Author = "Ben"
                Content = "Welche Sorte ist das?"
                ContentLanguage = "de-DE"
                Source = "dom"
                ReceivedAtUtc = now
            }
            {
                MessageId = "3"
                ParticipantKey = None
                Author = "Clara"
                Content = "Danke für die Erklärung"
                ContentLanguage = "de-DE"
                Source = "websocket"
                ReceivedAtUtc = now
            }
            {
                MessageId = "4"
                ParticipantKey = None
                Author = "David"
                Content = "Bitte einmal mischen"
                ContentLanguage = "de-DE"
                Source = "websocket"
                ReceivedAtUtc = now
            }
            {
                MessageId = "5"
                ParticipantKey = None
                Author = "Eva"
                Content = "Das ist gut lesbar"
                ContentLanguage = "de-DE"
                Source = "websocket"
                ReceivedAtUtc = now
            }
        |]
        Participants = Map [
            ("id:1", {
                Key = "id:1"
                Name = "Anna"
                MessageCount = 12
                WordCount = 48
                GiftEventCount = 2
                GiftItemCount = 24
                LastSeenAtUtc = now
            })
            ("id:2", {
                Key = "id:2"
                Name = "Ben"
                MessageCount = 8
                WordCount = 39
                GiftEventCount = 0
                GiftItemCount = 0
                LastSeenAtUtc = now
            })
            ("name:clara", {
                Key = "name:clara"
                Name = "Clara"
                MessageCount = 6
                WordCount = 31
                GiftEventCount = 1
                GiftItemCount = 1
                LastSeenAtUtc = now
            })
        ]
        StreamMutes = [||]
        ParticipantsTruncated = false
        Media = [|
            {
                Url = "https://pull.example.tiktokcdn.com/live/stream_hd.flv?expire=1&sign=test"
                Protocol = "FLV"
                Quality = "720p"
                SdkKey = "hd"
                Bitrate = 1800000
                Codec = "h264"
                Width = 1280
                Height = 720
                Fps = 30
                AudioOnly = false
                Hostname = "pull.example.tiktokcdn.com"
                Source = "metadata"
            }
            {
                Url = "https://pull.example.tiktokcdn-eu.com/live/stream_720p.m3u8?sign=test"
                Protocol = "HLS"
                Quality = "720p"
                SdkKey = "hd"
                Bitrate = 1800000
                Codec = "h264"
                Width = 1280
                Height = 720
                Fps = 30
                AudioOnly = false
                Hostname = "pull.example.tiktokcdn-eu.com"
                Source = "network"
            }
            {
                Url = "https://pull.example.tiktokcdn.com/live/stream_sd.flv?expire=1&sign=test"
                Protocol = "FLV"
                Quality = "540p"
                SdkKey = "sd"
                Bitrate = 900000
                Codec = "h264"
                Width = 960
                Height = 540
                Fps = 30
                AudioOnly = false
                Hostname = "pull.example.tiktokcdn.com"
                Source = "metadata"
            }
        |]
        Captions = [|
            {
                ReceivedAtUtc = now
                SentenceId = Some("42")
                Definite = true
                Contents = [| { Lang = "de"; Text = "Dies ist eine Test-Caption." } |]
            }
        |]
        Debug = {
            Enabled = false
            Entries = [| { AtUtc = now; Event = "scan"; Detail = {| MediaCount = 3 |} } |]
        }
    }

let generateHtml() =
    let state = createState()
    $"""<!doctype html>
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
    (async () => {{
      const state = {JsonSerializer.Serialize(state, JsonSerializerOptions())};
      
      const stateListeners = [];
      globalThis.chrome = {{
        tabs: {{
          query: async () => [{{ id: 1, url: state.page.url, title: state.page.title }}],
          onActivated: {{ addListener() {{}} }}
        }},
        tabCapture: {{ capture(_options, callback) {{ callback(null); }} }},
        runtime: {{
          sendMessage: async (message) => {{
            if (message.type === "TLC_GET_STATE") return {{ ok: true, state }};
            if (message.type === "TLC_OPEN_EMBED_LIVE") {{
              state.embedStartup = TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), "demo", Date.now());
              return {{ ok: true, response: {{ activated: false, phase: "loading" }} }};
            }}
            if (message.type === "TLC_CANCEL_EMBED_STARTUP" || message.type === "TLC_OPEN_NORMAL_LIVE") {{
              if (state.embedStartup) state.embedStartup = {{ ...state.embedStartup, phase: "cancelled", nextAttemptAtMs: null }};
              return {{ ok: true }};
            }}
            if (message.type === "TLC_GET_SETTINGS") return {{ ok: true, settings: {{ autoHook: true, keepSpeechActive: true, speechVolume: 0.5, speechLanguage: "auto", speakNames: true, shortenNames: false, serviceUrl: "http://127.0.0.1:43117", pairingCode: "", permanentMutes: [], quickRecoverEnabled: state.quickRecoverEnabled, quickRecoverSeconds: state.quickRecoverSeconds }} }};
            if (message.type === "TLC_SET_QUICK_RECOVER") {{
              state.quickRecoverEnabled = Boolean(message.enabled);
              state.quickRecoverSeconds = Math.max(1, Math.min(59, Math.round(Number(message.seconds) || 3)));
              return {{ ok: true, state, seconds: state.quickRecoverSeconds }};
            }}
            if (message.type === "TLC_GET_CAPTION_JSONL_EXPORT") return {{ ok: true, records: TLC_EXPORT_PRIVACY.captions(state.captions) }};
            if (message.type === "TLC_GET_CAPTION_RAW_EXPORT") return {{ ok: true, report: TLC_EXPORT_PRIVACY.captionReport({{
              version: "0.8.2", generatedAtUtc: new Date().toISOString(), messages: state.captions,
              dataStreams: state.media, data: {{ captionInfo: state.captionInfo, captionSources: state.captionSources, playerState: state.playerState }}, stream: {{ page: state.page }}
            }}) }};
            if (message.type === "TLC_SCAN") {{
              return {{ ok: true, response: {{ captionInfo: state.captionInfo, captionControl: true, mediaCount: state.media.length }} }};
            }}
            if (message.type === "TLC_GET_PLAYER_STATE") return {{ ok: true, response: {{ playerState: state.playerState }} }};
            if (message.type === "TLC_PLAYER_ACTION") {{
              if (message.action === "toggle-play") state.playerState.playing = !state.playerState.playing;
              if (message.action === "toggle-mute") state.playerState.muted = !state.playerState.muted;
              if (message.action === "set-volume") {{
                state.playerState.volume = Number(message.value);
                state.playerState.volumePercent = Math.round(Number(message.value) * 100);
                state.playerState.volumeGainDb = Number(message.value) > 0 ? 20 * Math.log10(Number(message.value)) : null;
              }}
              if (message.action === "set-limiter") {{
                state.playerState.limiterEnabled = Boolean(message.enabled);
                state.playerState.limiterThresholdDbfs = Number(message.thresholdDbfs);
              }}
              return {{ ok: true, response: {{ activated: true, playerState: state.playerState }} }};
            }}
            if (message.type === "TLC_CLEAR_CHAT") {{
              state.chatMessages = [];
              return {{ ok: true }};
            }}
            if (message.type === "TLC_SET_DEBUG") {{
              state.debug.enabled = Boolean(message.enabled);
              return {{ ok: true, state }};
            }}
            if (message.type === "TLC_CLEAR_DEBUG") {{
              state.debug.entries = [];
              return {{ ok: true }};
            }}
            if (message.type === "TLC_SET_MUTE") return {{ ok: true, state, settings: {{ permanentMutes: [] }} }};
            if (message.type === "TLC_GET_DEBUG_REPORT") return {{ ok: true, report: TLC_EXPORT_PRIVACY.diagnosticReport({{ version: "0.8.2", debug: state.debug, page: state.page, media: state.media }}) }};
            return {{ ok: true, response: {{ activated: true }} }};
          }},
          onMessage: {{ addListener(listener) {{ stateListeners.push(listener); }} }}
        }}
      }};

      const assetVersion = Date.now();
      const source = await fetch("../browser-extension/sidepanel.html", {{ cache: "no-store" }}).then((response) => response.text());
      const parsed = new DOMParser().parseFromString(source, "text/html");
      document.title = parsed.title;
      for (const child of [...parsed.body.children]) {{
        if (child.tagName !== "SCRIPT") document.body.append(document.importNode(child, true));
      }}
      const css = document.createElement("link");
      css.rel = "stylesheet";
      css.href = "../browser-extension/sidepanel.css?v=0.7.0-1";
      document.head.append(css);
      const coreScript = document.createElement("script");
      coreScript.src = `../browser-extension/content-core.js?v=${{assetVersion}}`;
      coreScript.onload = () => {{
        document.getElementById("test-embed-scenario").addEventListener("change", (event) => {{
          state.embedStartup = {{
            ...TLC_CONTENT_CORE.newEmbedSession(crypto.randomUUID(), "demo", Date.now()),
            phase: event.target.value, reason: "server-error", attempt: event.target.value === "failed" ? 3 : 1
          }};
          stateListeners.forEach((listener) => listener({{ type: "TLC_STATE_UPDATED", tabId: 1, state }}));
        }});
        document.getElementById("test-caption-scenario").addEventListener("change", (event) => {{
          const mode = event.target.value;
          const observedAt = Date.now() - (mode === "historical" ? 60_000 : 0);
          state.captions = mode === "none" ? [] : ["DomCaption", "WebcastCaptionMessage"].map((method) => ({{
            method, source: method === "DomCaption" ? "dom" : "websocket", receivedAtUtc: new Date(observedAt).toISOString(),
            contents: [{{ lang: "de", text: "Dies ist eine Test-Caption." }}]
          }}));
          state.captionSources = TLC_CONTENT_CORE.captionSourceSnapshot();
          if (mode === "metadata") state.captionSources.metadata = {{ present: true, open: true, supportLang: ["de"] }};
          else for (const caption of state.captions) state.captionSources = TLC_CONTENT_CORE.observeCaptionSource(state.captionSources, caption, observedAt);
          state.captionInfo = TLC_CONTENT_CORE.summarizeCaptionSources(state.captionSources);
          stateListeners.forEach((listener) => listener({{ type: "TLC_STATE_UPDATED", tabId: 1, state }}));
        }});
        const privacyScript = document.createElement("script");
        privacyScript.src = `../browser-extension/export-privacy.js?v=${{assetVersion}}`;
        privacyScript.onload = () => {{
          const script = document.createElement("script");
          script.src = `../browser-extension/sidepanel.js?v=${{assetVersion}}`;
          document.body.append(script);
        }};
        document.body.append(privacyScript);
      }};
      document.body.append(coreScript);
    }})();
  </script>
</body>
</html>"""

[<EntryPoint>]
let main argv =
    let outputPath = 
        if argv.Length > 0 then argv.[0] 
        else "sidepanel-harness.html"
    
    File.WriteAllText(outputPath, generateHtml())
    printfn $"HTML file generated: {outputPath}"
    0
