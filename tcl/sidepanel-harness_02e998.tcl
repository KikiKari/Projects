#!/usr/bin/env tclsh
# sidepanel-harness.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion-Android:plugin-source/tests/sidepanel-harness.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/sidepanel-harness.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# sidepanel-harness.tcl - Erzeugt eine HTML-Datei mit Testdaten für die Sidepanel-Ansicht
# Portiert von sidepanel-harness.html nach Tcl 8.6

package require json

# Hilfsfunktion zur Erstellung von ISO-Datumsstempeln
proc now_iso {} {
    return [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt true]
}

# Erstellung des JavaScript-Objekts 'state'
proc create_state {} {
    set now [now_iso]
    
    # chatMessages Array
    set chatMessages [list]
    lappend chatMessages [dict create \
        messageId "1" \
        participantKey "id:1" \
        author "Anna" \
        content "Guten Abend" \
        contentLanguage "de-DE" \
        source "websocket" \
        receivedAtUtc $now]
    lappend chatMessages [dict create \
        messageId "2" \
        participantKey "id:2" \
        author "Ben" \
        content "Welche Sorte ist das?" \
        contentLanguage "de-DE" \
        source "dom" \
        receivedAtUtc $now]
    lappend chatMessages [dict create \
        messageId "3" \
        author "Clara" \
        content "Danke für die Erklärung" \
        contentLanguage "de-DE" \
        source "websocket" \
        receivedAtUtc $now]
    lappend chatMessages [dict create \
        messageId "4" \
        author "David" \
        content "Bitte einmal mischen" \
        contentLanguage "de-DE" \
        source "websocket" \
        receivedAtUtc $now]
    lappend chatMessages [dict create \
        messageId "5" \
        author "Eva" \
        content "Das ist gut lesbar" \
        contentLanguage "de-DE" \
        source "websocket" \
        receivedAtUtc $now]
    
    # participants Dict
    set participants [dict create]
    dict set participants "id:1" [dict create \
        key "id:1" \
        name "Anna" \
        messageCount 12 \
        wordCount 48 \
        giftEventCount 2 \
        giftItemCount 24 \
        lastSeenAtUtc $now]
    dict set participants "id:2" [dict create \
        key "id:2" \
        name "Ben" \
        messageCount 8 \
        wordCount 39 \
        giftEventCount 0 \
        giftItemCount 0 \
        lastSeenAtUtc $now]
    dict set participants "name:clara" [dict create \
        key "name:clara" \
        name "Clara" \
        messageCount 6 \
        wordCount 31 \
        giftEventCount 1 \
        giftItemCount 1 \
        lastSeenAtUtc $now]
    
    # media Array
    set media [list]
    lappend media [dict create \
        url "https://pull.example.tiktokcdn.com/live/stream_hd.flv?expire=1&sign=test" \
        protocol "FLV" \
        quality "720p" \
        sdkKey "hd" \
        bitrate 1800000 \
        codec "h264" \
        width 1280 \
        height 720 \
        fps 30 \
        audioOnly false \
        hostname "pull.example.tiktokcdn.com" \
        source "metadata"]
    lappend media [dict create \
        url "https://pull.example.tiktokcdn-eu.com/live/stream_720p.m3u8?sign=test" \
        protocol "HLS" \
        quality "720p" \
        sdkKey "hd" \
        bitrate 1800000 \
        codec "h264" \
        width 1280 \
        height 720 \
        fps 30 \
        audioOnly false \
        hostname "pull.example.tiktokcdn-eu.com" \
        source "network"]
    lappend media [dict create \
        url "https://pull.example.tiktokcdn.com/live/stream_sd.flv?expire=1&sign=test" \
        protocol "FLV" \
        quality "540p" \
        sdkKey "sd" \
        bitrate 900000 \
        codec "h264" \
        width 960 \
        height 540 \
        fps 30 \
        audioOnly false \
        hostname "pull.example.tiktokcdn.com" \
        source "metadata"]
    
    # captions Array
    set captions [list]
    lappend captions [dict create \
        receivedAtUtc $now \
        sentenceId "42" \
        definite true \
        contents [list [dict create lang "de" text "Dies ist eine Test-Caption."]]]
    
    # debug entries Array
    set debugEntries [list]
    lappend debugEntries [dict create \
        atUtc $now \
        event "scan" \
        detail [dict create mediaCount 3]]
    
    # Zusammenstellung des state dicts
    set state [dict create \
        page [dict create \
            url "https://www.tiktok.com/@demo/live" \
            title "Demo LIVE" \
            scannedAtUtc $now] \
        captionInfo [dict create \
            present true \
            open true \
            supportLang [list "de" "en"] \
            location {} \
            showType 1] \
        menuCaptionAvailable true \
        menuCaptionActive false \
        profileInfo [dict create \
            present true \
            nickname "Demo Creator" \
            uniqueId "demo" \
            signature "Barrierefreier Teststream" \
            followingCount "12" \
            followerCount "238800" \
            likeCount "1800000" \
            live true \
            source "metadata"] \
        aiSummaryInfo [dict create \
            featureFlagPresent true \
            featureEnabled true \
            text "" \
            source {} \
            overviewCardFound true \
            overviewCardHovered true] \
        hook [dict create \
            armed true \
            installed true \
            connected true \
            lastError {}] \
        stream [dict create \
            key "demo|123" \
            handle "demo" \
            roomId "123" \
            teamTag "tmm" \
            teamEvidence [dict create]] \
        liveStats [dict create \
            viewerCount "143" \
            totalViewers "15842" \
            likeCount "430200" \
            followEvents 7 \
            shareEvents 4 \
            shareCount "19" \
            followerCount "238800" \
            lastUpdatedUtc $now \
            recentEventIds [list]] \
        playerState [dict create \
            available true \
            playing true \
            muted false \
            elapsedText "1:17:42" \
            pipActive false \
            fullscreenActive false \
            volume 0.72 \
            volumePercent 72 \
            volumeGainDb -2.9 \
            peakDbfs -8.4 \
            limiterEnabled true \
            limiterThresholdDbfs -6 \
            limiterReductionDb -1.2 \
            limiterMode "Kompressor" \
            connectedStreams 4 \
            multiGuest true \
            updatedAtUtc $now] \
        selectedQuality "540p" \
        chatMessages $chatMessages \
        participants $participants \
        streamMutes [list] \
        participantsTruncated false \
        media $media \
        captions $captions \
        debug [dict create \
            enabled false \
            entries $debugEntries]]
    
    return $state
}

# Konvertiert ein Tcl-Dict in einen JavaScript-Objekt-String
proc dict_to_js {d {indent 0}} {
    set indent_str [string repeat "  " $indent]
    set next_indent_str [string repeat "  " [expr {$indent + 1}]]
    set result "{\n"
    
    dict for {key value} $d {
        append result "${next_indent_str}${key}: "
        if {[dict exists $value]} {
            append result [dict_to_js $value [expr {$indent + 1}]]
        } elseif {[llength $value] > 1 && ![string is integer -strict [lindex $value 0]]} {
            append result "[list_to_js_array $value [expr {$indent + 1}]]"
        } else {
            append result "[tcl_to_js $value]"
        }
        append result ",\n"
    }
    
    # Entferne das letzte Komma
    if {[string length $result] > 2} {
        set result [string range $result 0 end-2]
    }
    append result "\n${indent_str}}"
    return $result
}

# Konvertiert eine Tcl-Liste in ein JavaScript-Array
proc list_to_js_array {lst indent} {
    set indent_str [string repeat "  " $indent]
    set next_indent_str [string repeat "  " [expr {$indent + 1}]]
    set result "[\n"
    
    foreach item $lst {
        append result "${next_indent_str}"
        if {[dict exists $item]} {
            append result [dict_to_js $item [expr {$indent + 1}]]
        } elseif {[llength $item] > 1} {
            append result "[list_to_js_array $item [expr {$indent + 1}]]"
        } else {
            append result "[tcl_to_js $item]"
        }
        append result ",\n"
    }
    
    # Entferne das letzte Komma
    if {[string length $result] > 2} {
        set result [string range $result 0 end-2]
    }
    append result "\n${indent_str}]"
    return $result
}

# Konvertiert einen Tcl-Wert in einen JavaScript-Wert
proc tcl_to_js {value} {
    if {$value eq "true" || $value eq "false"} {
        return $value
    } elseif {[string is double -strict $value] || [string is integer -strict $value]} {
        return $value
    } elseif {[string equal $value ""]} {
        return "null"
    } else {
        # Escape double quotes
        set escaped [string map {\" \\\"} $value]
        return "\"$escaped\""
    }
}

# Erstellt das chrome-Objekt als JavaScript-String
proc create_chrome_object {state} {
    set js "
      globalThis.chrome = {
        tabs: {
          query: async () => [{ id: 1, url: state.page.url, title: state.page.title }],
          onActivated: { addListener() {} }
        },
        tabCapture: { capture(_options, callback) { callback(null); } },
        runtime: {
          sendMessage: async (message) => {
            if (message.type === \"TLC_GET_STATE\") return { ok: true, state };
            if (message.type === \"TLC_GET_SETTINGS\") return { ok: true, settings: { autoHook: true, keepSpeechActive: true, speechVolume: 0.5, speechLanguage: \"auto\", speakNames: true, shortenNames: false, serviceUrl: \"http://127.0.0.1:43117\", pairingCode: \"\", permanentMutes: [] } };
            if (message.type === \"TLC_SCAN\") {
              return { ok: true, response: { captionInfo: state.captionInfo, captionControl: true, mediaCount: state.media.length } };
            }
            if (message.type === \"TLC_GET_PLAYER_STATE\") return { ok: true, response: { playerState: state.playerState } };
            if (message.type === \"TLC_PLAYER_ACTION\") {
              if (message.action === \"toggle-play\") state.playerState.playing = !state.playerState.playing;
              if (message.action === \"toggle-mute\") state.playerState.muted = !state.playerState.muted;
              if (message.action === \"set-volume\") {
                state.playerState.volume = Number(message.value);
                state.playerState.volumePercent = Math.round(Number(message.value) * 100);
                state.playerState.volumeGainDb = Number(message.value) > 0 ? 20 * Math.log10(Number(message.value)) : null;
              }
              if (message.action === \"set-limiter\") {
                state.playerState.limiterEnabled = Boolean(message.enabled);
                state.playerState.limiterThresholdDbfs = Number(message.thresholdDbfs);
              }
              return { ok: true, response: { activated: true, playerState: state.playerState } };
            }
            if (message.type === \"TLC_CLEAR_CHAT\") {
              state.chatMessages = [];
              return { ok: true };
            }
            if (message.type === \"TLC_SET_DEBUG\") {
              state.debug.enabled = Boolean(message.enabled);
              return { ok: true, state };
            }
            if (message.type === \"TLC_CLEAR_DEBUG\") {
              state.debug.entries = [];
              return { ok: true };
            }
            if (message.type === \"TLC_SET_MUTE\") return { ok: true, state, settings: { permanentMutes: [] } };
            if (message.type === \"TLC_GET_DEBUG_REPORT\") return { ok: true, report: { version: \"0.7.1\", debug: state.debug } };
            return { ok: true, response: { activated: true } };
          },
          onMessage: { addListener() {} }
        }
      };"
    return $js
}

# Hauptfunktion zur Erstellung der HTML-Datei
proc create_html {filename} {
    set state [create_state]
    set state_js [dict_to_js $state]
    
    set html "<!doctype html>
<html lang=\"de\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>Sidepanel Test Harness</title>
</head>
<body>
  <script>
    (async () => {
      const state = $state_js;
      
      [create_chrome_object $state]

      const source = await fetch(\"../browser-extension/sidepanel.html\").then((response) => response.text());
      const parsed = new DOMParser().parseFromString(source, \"text/html\");
      document.title = parsed.title;
      for (const child of [...parsed.body.children]) {
        if (child.tagName !== \"SCRIPT\") document.body.append(document.importNode(child, true));
      }
      const css = document.createElement(\"link\");
      css.rel = \"stylesheet\";
      css.href = \"../browser-extension/sidepanel.css?v=0.7.1-1\";
      document.head.append(css);
      const coreScript = document.createElement(\"script\");
      coreScript.src = \"../browser-extension/content-core.js\";
      coreScript.onload = () => {
        const script = document.createElement(\"script\");
        script.src = \"../browser-extension/sidepanel.js\";
        document.body.append(script);
      };
      document.body.append(coreScript);
    })();
  </script>
</body>
</html>"
    
    set fh [open $filename w]
    puts $fh $html
    close $fh
    
    puts "HTML-Datei wurde erfolgreich erstellt: $filename"
}

# Hauptprogramm
if {$argc != 1} {
    puts "Verwendung: tclsh sidepanel-harness.tcl <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
create_html $output_file
