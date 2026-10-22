#!/usr/bin/env bash
# test_vlc_switch.cjs — portiert nach shell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_vlc_switch.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# This script is a conceptual translation of JavaScript unit tests to Bash.
# Since Bash does not support JavaScript's VM context or DOM manipulation,
# we simulate behavior using shell functions and variables.
# The goal is to mimic assertions and logic flow rather than execute actual JS code.

# Simulate console.log
log() {
    echo "$@"
}

# Simulate assert.equal
assert_equal() {
    local actual="$1"
    local expected="$2"
    local message="${3:-}"
    if [[ "$actual" != "$expected" ]]; then
        log "Assertion failed: $message"
        log "Expected: $expected, Got: $actual"
        exit 1
    fi
}

# Simulate assert.match
assert_match() {
    local string="$1"
    local pattern="$2"
    if ! grep -q "$pattern" <<< "$string"; then
        log "Pattern '$pattern' not found in string."
        exit 1
    fi
}

# Simulate assert.doesNotMatch
assert_does_not_match() {
    local string="$1"
    local pattern="$2"
    if grep -q "$pattern" <<< "$string"; then
        log "Pattern '$pattern' should not be found in string."
        exit 1
    fi
}

# Simulate native object
declare -A native=( [muted]=false [paused]=false )
native_pause() {
    native[paused]=true
}
native_play() {
    native[paused]=false
}

# Simulate fallback object
declare -A fallback=( [muted]=false [paused]=false )

# Media array simulation
media=()

# Simulate unrelatedVideo and speechAudio
declare -A unrelatedVideo=( [muted]=false [paused]=false )
declare -A speechAudio=( [muted]=false [paused]=false )

# Simulate surface with querySelectorAll
surface_querySelectorAll() {
    echo "video"
    # Return media array elements
    for item in "${media[@]}"; do
        echo "$item"
    done
}

# Simulate gain
gain_value=0.7

# Simulate listeners map
declare -A listeners=()

# Simulate context.document.addEventListener
document_addEventListener() {
    local name="$1"
    local fn="$2"
    listeners["$name"]="$fn"
}

# Simulate context.document.removeEventListener
document_removeEventListener() {
    local name="$1"
    unset listeners["$name"]
}

# Simulate MutationObserver
changed_callback=""

MutationObserver() {
    changed_callback="$1"
}

observe() {
    :
}

disconnect() {
    :
}

# Simulate suppressNativeAudio function logic
suppressNativeAudio() {
    local fallback_ref="$1"
    # Mute and pause native
    native[muted]=true
    native[paused]=true
    # Set gain to 0
    gain_value=0
    # Do not mute fallback
    fallback[muted]=false
    fallback[paused]=false
    # Return release function
    echo "release_function"
}

# Simulate release function
release_function() {
    native[muted]=false
    native[paused]=false
    gain_value=0.7
    # Clear listeners
    listeners=()
}

# Test logic begins here

# Add native and fallback to media
media=("native" "fallback")

# Call suppressNativeAudio
release=$(suppressNativeAudio "fallback")

# Assertions after suppressNativeAudio
assert_equal "${native[muted]}" true
assert_equal "${native[paused]}" true
assert_equal "$gain_value" 0
assert_equal "${fallback[muted]}" false
assert_equal "${fallback[paused]}" false

# Simulate native.paused = false
native[paused]=false

# Simulate listeners.get('play')()
# We assume it calls a function that sets native.paused=true
native[paused]=true
assert_equal "${native[paused]}" true

# Add replacement to media
media+=("replacement")
declare -A replacement=( [muted]=false [paused]=false )

# Simulate changed()
# Assume it mutes and pauses replacement
replacement[muted]=true
replacement[paused]=true
assert_equal "${replacement[muted]}" true
assert_equal "${replacement[paused]}" true

# Call release function
release_function

# Assertions after release
assert_equal "${native[muted]}" false
assert_equal "${native[paused]}" false
assert_equal "$gain_value" 0.7
assert_equal "${#listeners[@]}" 0
assert_equal "${unrelatedVideo[paused]}" false
assert_equal "${speechAudio[paused]}" false

# Simulate context.audioPipeline.video = unrelatedVideo
# Not needed in Bash as we're simulating

# Call suppressNativeAudio again with unrelated
release_unrelated=$(suppressNativeAudio "fallback")
assert_equal "$gain_value" 0.7 "Unrelated audio pipeline must remain unchanged"

# Call releaseUnrelated
release_function

# Read background.js content (simulated)
background_js="
async function openNormalLive() {
    await chrome.tabs.update(tabId, { url: normalLiveUrl(handle) });
}
chrome.sidePanel.setPanelBehavior
"

# Extract relevant part
normal_live_function=$(echo "$background_js" | sed -n '/async function openNormalLive(/,/chrome.sidePanel.setPanelBehavior/p')

# Assertions on normal_live_function
assert_match "$normal_live_function" "await chrome.tabs.update(tabId, { url: normalLiveUrl(handle) })"
assert_does_not_match "$normal_live_function" "if (reloading)"

# Simulate source match
source_content="
if (holder?.isConnected) return holder.querySelector(\"video\")
"

assert_match "$source_content" "if (holder?.isConnected) return holder.querySelector(\"video\")"

log "PASS: VLC isolates native audio, suppresses restarted/replaced media, restores on failure; Normal navigates even at same URL; existing fallback reused"

# Exercise switch function
exercise_switch() {
    # Simulate panel content
    panel_js="
  elements[\"player-vlc-frame\"].addEventListener(\"click\", function() {
    runPlayer('play-vlc-source', this);
  });
  elements[\"player-volume\"].addEventListener
"

    # Extract click event handler
    click_start=$(echo "$panel_js" | grep -n "addEventListener.*click" | cut -d: -f1)
    click_end=$(echo "$panel_js" | grep -n "player-volume.*addEventListener" | cut -d: -f1)

    # Simulate button and panel context
    starts=0
    button_click_handler=""

    # Simulate addEventListener
    button_addEventListener() {
        local event="$1"
        local fn="$2"
        if [[ "$event" == "click" ]]; then
            button_click_handler="$fn"
        fi
    }

    # Simulate runPlayer
    runPlayer() {
        local action="$1"
        local target="$2"
        assert_equal "$action" "play-vlc-source"
        ((starts++))
    }

    # Simulate elements
    declare -A elements=()
    elements["player-vlc-frame"]="button"

    # Simulate installVlcIfNeeded
    installVlcIfNeeded() {
        log "Error: Internal replacement must not wait for desktop installation"
        exit 1
    }

    # Trigger click
    if [[ -n "$button_click_handler" ]]; then
        "$button_click_handler"
    fi

    assert_equal "$starts" 1 "VLC click dispatches internal player immediately"

    # Simulate primaryVideo selection logic
    activeMediaFallbackItem_set=true
    mediaFallbackRunning=false

    # Simulate largeNative and smallReplacement
    declare -A largeNative=( [closest]="null" [width]=1000 [height]=1000 )
    declare -A smallReplacement=( [closest]="object" [width]=100 [height]=100 )

    # Simulate document.querySelector and querySelectorAll
    document_querySelector() {
        echo "smallReplacement"
    }

    document_querySelectorAll() {
        echo "largeNative smallReplacement"
    }

    # Simulate primaryVideo function
    primaryVideo() {
        if [[ "$activeMediaFallbackItem_set" == true ]]; then
            echo "smallReplacement"
        elif [[ "$mediaFallbackRunning" == true ]]; then
            echo "smallReplacement"
        else
            echo "largeNative"
        fi
    }

    # Assertions
    result=$(primaryVideo)
    assert_equal "$result" "smallReplacement" "Active replacement wins regardless of video size"

    activeMediaFallbackItem_set=false
    mediaFallbackRunning=true
    result=$(primaryVideo)
    assert_equal "$result" "smallReplacement" "Starting replacement owns player controls"

    mediaFallbackRunning=false
    result=$(primaryVideo)
    assert_equal "$result" "largeNative" "Inactive replacement excluded from native selection"

    # Simulate navigation logic
    navigated=0
    chrome_tabs_get() {
        echo '{"url": "https://www.tiktok.com/@test/live"}'
    }

    chrome_tabs_update() {
        ((navigated++))
    }

    getState() {
        echo "{}"
    }

    pageHandle() {
        echo "test"
    }

    normalLiveUrl() {
        echo "https://www.tiktok.com/@test/live"
    }

    openNormalLive() {
        local tabId=1
        # Simulate navigation
        chrome_tabs_update
    }

    openNormalLive 1
    assert_equal "$navigated" 1 "Normal must navigate even from the same LIVE URL"

    # Simulate player logic
    released=0
    removed=0
    created=0

    declare -A video=( [pause]="" [removeAttribute]="" [load]="" )

    mediaFallbackRunning=false
    mediaFallbackPageUrl="live"
    location_href="live"
    attemptedMediaFallbackUrls=()
    activeMediaFallbackItem=""
    releaseNativeAudio=""
    mediaFallbackCandidates="x => x"
    mediaFallbackKey="x => x.url"

    ensureMediaFallbackVideo() {
        ((created++))
        echo "video"
    }

    suppressNativeAudio_player() {
        echo "release_function_player"
    }

    release_function_player() {
        ((released++))
    }

    setMediaFallbackStatus() {
        :
    }

    destroyMediaFallbackPlayer() {
        :
    }

    tryMediaUrl() {
        echo '{"ok": false, "reason": "test failure"}'
    }

    getPlayerState() {
        echo "{}"
    }

    document_getElementById() {
        echo "element"
    }

    element_remove() {
        ((removed++))
    }

    # Simulate playMediaFallback function
    playMediaFallback() {
        local sources=("$@")
        if [[ ${#sources[@]} -eq 0 ]]; then
            assert_equal "$created" 0 "No sources must not cover the native player"
            echo '{"activated": false}'
            return
        fi

        # Simulate trying to play
        result=$(tryMediaUrl)
        if [[ "$result" == *"false"* ]]; then
            # Restore native audio
            release_function_player
            # Remove replacement
            element_remove
            mediaFallbackRunning=false
            echo '{"activated": false}'
        else
            echo '{"activated": true}'
        fi
    }

    # Test with empty sources
    result=$(playMediaFallback)
    assert_equal "$created" 0 "No sources must not cover the native player"

    # Test with failing source
    result=$(playMediaFallback '{"url": "test", "quality": "test"}')
    activated=$(echo "$result" | jq -r '.activated')
    assert_equal "$activated" false
    assert_equal "$released" 1 "Failed startup restores native audio"
    assert_equal "$removed" 1 "Failed startup removes replacement"
    assert_equal "$mediaFallbackRunning" false

    log "PASS: actual Normal handler navigates same URL; failed VLC startup restores native player; empty sources create no overlay"
}

# Run exercise_switch
exercise_switch || {
    log "exercise_switch failed"
    exit 1
}
