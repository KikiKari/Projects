#!/usr/bin/perl
# sidepanel-harness.html — portiert nach perl5
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/sidepanel-harness.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use File::Basename;

# Get output filename from command line argument
my $output_file = $ARGV[0] or die "Usage: $0 <output_file>\n";

# Create the HTML document structure
my $html = create_html_document();

# Write to file
open my $fh, '>', $output_file or die "Cannot open $output_file: $!";
print $fh $html;
close $fh;

print "HTML document written to $output_file\n";

sub create_html_document {
    my $html = <<'EOF';
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sidepanel Test Harness</title>
</head>
<body>
  <script>
EOF

    $html .= "    (async () => {\n";
    
    # Generate the state object as JavaScript
    my $state_js = generate_state_object();
    $html .= $state_js;
    
    $html .= <<'EOF';

      globalThis.chrome = {
        tabs: {
          query: async () => [{ id: 1, url: state.page.url, title: state.page.title }],
          onActivated: { addListener() {} }
        },
        tabCapture: { capture(_options, callback) { callback(null); } },
        runtime: {
          sendMessage: async (message) => {
            if (message.type === "TLC_GET_STATE") return { ok: true, state };
            if (message.type === "TLC_GET_SETTINGS") return { ok: true, settings: { autoHook: true, keepSpeechActive: true, speechVolume: 0.5, speechLanguage: "auto", speakNames: true, shortenNames: false, serviceUrl: "http://127.0.0.1:43117", pairingCode: "", permanentMutes: [] } };
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
            if (message.type === "TLC_GET_DEBUG_REPORT") return { ok: true, report: { version: "0.7.0", debug: state.debug } };
            return { ok: true, response: { activated: true } };
          },
          onMessage: { addListener() {} }
        }
      };

      const source = await fetch("../browser-extension/sidepanel.html").then((response) => response.text());
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
      coreScript.src = "../browser-extension/content-core.js";
      coreScript.onload = () => {
        const script = document.createElement("script");
        script.src = "../browser-extension/sidepanel.js";
        document.body.append(script);
      };
      document.body.append(coreScript);
    })();
  </script>
</body>
</html>
EOF

    return $html;
}

sub generate_state_object {
    my $iso_time = get_iso_time();
    
    my $state = {
        page => {
            url => "https://www.tiktok.com/\@demo/live",
            title => "Demo LIVE",
            scannedAtUtc => $iso_time
        },
        captionInfo => {
            present => JSON::true,
            open => JSON::true,
            supportLang => ["de", "en"],
            location => JSON::null,
            showType => 1
        },
        menuCaptionAvailable => JSON::true,
        menuCaptionActive => JSON::false,
        profileInfo => {
            present => JSON::true,
            nickname => "Demo Creator",
            uniqueId => "demo",
            signature => "Barrierefreier Teststream",
            followingCount => "12",
            followerCount => "238800",
            likeCount => "1800000",
            live => JSON::true,
            source => "metadata"
        },
        aiSummaryInfo => {
            featureFlagPresent => JSON::true,
            featureEnabled => JSON::true,
            text => "",
            source => JSON::null,
            overviewCardFound => JSON::true,
            overviewCardHovered => JSON::true
        },
        hook => {
            armed => JSON::true,
            installed => JSON::true,
            connected => JSON::true,
            lastError => JSON::null
        },
        stream => {
            key => "demo|123",
            handle => "demo",
            roomId => "123",
            teamTag => "tmm",
            teamEvidence => {}
        },
        liveStats => {
            viewerCount => "143",
            totalViewers => "15842",
            likeCount => "430200",
            followEvents => 7,
            shareEvents => 4,
            shareCount => "19",
            followerCount => "238800",
            lastUpdatedUtc => $iso_time,
            recentEventIds => []
        },
        playerState => {
            available => JSON::true,
            playing => JSON::true,
            muted => JSON::false,
            elapsedText => "1:17:42",
            pipActive => JSON::false,
            fullscreenActive => JSON::false,
            volume => 0.72,
            volumePercent => 72,
            volumeGainDb => -2.9,
            peakDbfs => -8.4,
            limiterEnabled => JSON::true,
            limiterThresholdDbfs => -6,
            limiterReductionDb => -1.2,
            limiterMode => "Kompressor",
            connectedStreams => 4,
            multiGuest => JSON::true,
            updatedAtUtc => $iso_time
        },
        selectedQuality => "540p",
        chatMessages => [
            {
                messageId => "1",
                participantKey => "id:1",
                author => "Anna",
                content => "Guten Abend",
                contentLanguage => "de-DE",
                source => "websocket",
                receivedAtUtc => $iso_time
            },
            {
                messageId => "2",
                participantKey => "id:2",
                author => "Ben",
                content => "Welche Sorte ist das?",
                contentLanguage => "de-DE",
                source => "dom",
                receivedAtUtc => $iso_time
            },
            {
                messageId => "3",
                author => "Clara",
                content => "Danke für die Erklärung",
                contentLanguage => "de-DE",
                source => "websocket",
                receivedAtUtc => $iso_time
            },
            {
                messageId => "4",
                author => "David",
                content => "Bitte einmal mischen",
                contentLanguage => "de-DE",
                source => "websocket",
                receivedAtUtc => $iso_time
            },
            {
                messageId => "5",
                author => "Eva",
                content => "Das ist gut lesbar",
                contentLanguage => "de-DE",
                source => "websocket",
                receivedAtUtc => $iso_time
            }
        ],
        participants => {
            "id:1" => {
                key => "id:1",
                name => "Anna",
                messageCount => 12,
                wordCount => 48,
                giftEventCount => 2,
                giftItemCount => 24,
                lastSeenAtUtc => $iso_time
            },
            "id:2" => {
                key => "id:2",
                name => "Ben",
                messageCount => 8,
                wordCount => 39,
                giftEventCount => 0,
                giftItemCount => 0,
                lastSeenAtUtc => $iso_time
            },
            "name:clara" => {
                key => "name:clara",
                name => "Clara",
                messageCount => 6,
                wordCount => 31,
                giftEventCount => 1,
                giftItemCount => 1,
                lastSeenAtUtc => $iso_time
            }
        },
        streamMutes => [],
        participantsTruncated => JSON::false,
        media => [
            {
                url => "https://pull.example.tiktokcdn.com/live/stream_hd.flv?expire=1&sign=test",
                protocol => "FLV",
                quality => "720p",
                sdkKey => "hd",
                bitrate => 1800000,
                codec => "h264",
                width => 1280,
                height => 720,
                fps => 30,
                audioOnly => JSON::false,
                hostname => "pull.example.tiktokcdn.com",
                source => "metadata"
            },
            {
                url => "https://pull.example.tiktokcdn-eu.com/live/stream_720p.m3u8?sign=test",
                protocol => "HLS",
                quality => "720p",
                sdkKey => "hd",
                bitrate => 1800000,
                codec => "h264",
                width => 1280,
                height => 720,
                fps => 30,
                audioOnly => JSON::false,
                hostname => "pull.example.tiktokcdn-eu.com",
                source => "network"
            },
            {
                url => "https://pull.example.tiktokcdn.com/live/stream_sd.flv?expire=1&sign=test",
                protocol => "FLV",
                quality => "540p",
                sdkKey => "sd",
                bitrate => 900000,
                codec => "h264",
                width => 960,
                height => 540,
                fps => 30,
                audioOnly => JSON::false,
                hostname => "pull.example.tiktokcdn.com",
                source => "metadata"
            }
        ],
        captions => [
            {
                receivedAtUtc => $iso_time,
                sentenceId => "42",
                definite => JSON::true,
                contents => [
                    {
                        lang => "de",
                        text => "Dies ist eine Test-Caption."
                    }
                ]
            }
        ],
        debug => {
            enabled => JSON::false,
            entries => [
                {
                    atUtc => $iso_time,
                    event => "scan",
                    detail => {
                        mediaCount => 3
                    }
                }
            ]
        }
    };

    # Convert to JSON with proper formatting
    my $json = JSON->new->utf8->pretty->canonical;
    my $state_json = $json->encode($state);
    
    # Format the JavaScript state assignment
    my $js = "      const state = " . $state_json . ";\n";
    
    return $js;
}

sub get_iso_time {
    use POSIX qw(strftime);
    return strftime("%Y-%m-%dT%H:%M:%S.000Z", gmtime);
}
