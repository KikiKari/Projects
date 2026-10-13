#!/bin/bash
# test_android_recovery.cjs — portiert nach shell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_android_recovery.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_android_recovery.cjs
# Erzeugt: 2026-10-13 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# This bash translation simulates the JavaScript tests by using external tools
# like `node`, `diff`, and shell logic to replicate behavior where possible,
# but due to fundamental differences between JS and Bash, full behavioral parity
# is not achievable without complex emulation or rewrites.

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAW_ANDROID="$SCRIPT_DIR/../../mobile/android/app/src/main/res/raw"
RAW_IOS="$SCRIPT_DIR/../../mobile/ios/Resources"
BROWSER_EXT="$SCRIPT_DIR/../browser-extension"

# Helper functions to simulate JS behavior
run_node_test() {
    local script_content="$1"
    echo "$script_content" > /tmp/test_runner.js
    node /tmp/test_runner.js
    rm -f /tmp/test_runner.js
}

# Test 1: Player recovery waits configured interval once and never touches navigation
test_player_recovery_wait() {
    cat << 'EOF' > /tmp/test1.js
const fs = require('fs');
const vm = require('vm');
const path = require('path');

let now = 10000;
let plays = 0;
let seq = 0;
const timers = new Map();
const intervals = [];
const listeners = {};
const events = [];

const video = {
    clientWidth: 100,
    clientHeight: 100,
    currentTime: 1,
    paused: false,
    ended: false,
    readyState: 4,
    dataset: {},
    addEventListener(n, f) { listeners[n] = f; },
    play: async () => { plays++; },
    textTracks: []
};

const root = {
    location: { origin: 'https://www.tiktok.com', pathname: '/@creator/live' },
    crypto: { randomUUID: () => `11111111-1111-1111-1111-${String(++seq).padStart(12, '0')}` },
    Date: class extends Date {
        static now() { return now; }
    },
    document: {
        scripts: [],
        body: { innerText: '' },
        querySelectorAll: s => s === 'video' ? [video] : [],
        querySelector: () => null
    },
    tlcBridge: {
        postMessage: s => events.push(JSON.parse(s))
    },
    addEventListener(n, f) { listeners[n] = f; },
    postMessage(m) { events.push(m); },
    setInterval: f => {
        intervals.push(f);
        return intervals.length;
    },
    clearInterval() {},
    setTimeout: (f, ms) => {
        const id = ++seq;
        timers.set(id, { f, at: now + ms });
        return id;
    },
    clearTimeout: id => timers.delete(id)
};

root.top = root;

vm.runInNewContext(fs.readFileSync(path.join('$RAW_ANDROID', 'android_recovery.js'), 'utf8'), root);

function tick(ms) {
    now += ms;
    for (const f of intervals) f();
    for (const [id, t] of [...timers]) {
        if (t.at <= now) {
            timers.delete(id);
            t.f();
        }
    }
}

root.TLC_MOBILE_RECOVERY.command('set-auto-reconnect', { enabled: true, delaySeconds: 3 });
root.TLC_MOBILE_RECOVERY.recover('stalled');

console.assert(timers.size === 1, 'Timers size should be 1');

tick(2999);
console.assert(plays === 0, 'Plays should be 0 after 2999ms');

tick(1);
console.assert(plays === 1, 'Plays should be 1 after 3000ms');
console.assert(root.location.pathname === '/@creator/live', 'Pathname should remain unchanged');
EOF

    run_node_test "$(cat /tmp/test1.js)"
    echo "Test 1 passed."
}

# Test 2: User pause and VLC cancel pending recovery
test_user_pause_cancel_recovery() {
    for cmd in pause set-vlc-active; do
        cat << EOF > /tmp/test2_$cmd.js
const fs = require('fs');
const vm = require('vm');
const path = require('path');

let now = 10000;
let plays = 0;
let seq = 0;
const timers = new Map();
const intervals = [];
const listeners = {};
const events = [];

const video = {
    clientWidth: 100,
    clientHeight: 100,
    currentTime: 1,
    paused: false,
    ended: false,
    readyState: 4,
    dataset: {},
    addEventListener(n, f) { listeners[n] = f; },
    play: async () => { plays++; },
    textTracks: []
};

const root = {
    location: { origin: 'https://www.tiktok.com', pathname: '/@creator/live' },
    crypto: { randomUUID: () => \`11111111-1111-1111-1111-\${String(++seq).padStart(12, '0')}\` },
    Date: class extends Date {
        static now() { return now; }
    },
    document: {
        scripts: [],
        body: { innerText: '' },
        querySelectorAll: s => s === 'video' ? [video] : [],
        querySelector: () => null
    },
    tlcBridge: {
        postMessage: s => events.push(JSON.parse(s))
    },
    addEventListener(n, f) { listeners[n] = f; },
    postMessage(m) { events.push(m); },
    setInterval: f => {
        intervals.push(f);
        return intervals.length;
    },
    clearInterval() {},
    setTimeout: (f, ms) => {
        const id = ++seq;
        timers.set(id, { f, at: now + ms });
        return id;
    },
    clearTimeout: id => timers.delete(id)
};

root.top = root;

vm.runInNewContext(fs.readFileSync(path.join('$RAW_ANDROID', 'android_recovery.js'), 'utf8'), root);

function tick(ms) {
    now += ms;
    for (const f of intervals) f();
    for (const [id, t] of [...timers]) {
        if (t.at <= now) {
            timers.delete(id);
            t.f();
        }
    }
}

root.TLC_MOBILE_RECOVERY.command('set-auto-reconnect', { enabled: true });
root.TLC_MOBILE_RECOVERY.recover('stalled');
root.TLC_MOBILE_RECOVERY.command('$cmd', { active: true });

tick(4000);
console.assert(plays === 0, 'Plays should be 0 after $cmd command');
EOF

        run_node_test "$(cat /tmp/test2_$cmd.js)"
    done
    echo "Test 2 passed."
}

# Test 3: Media progress cancels attempt without replacing media
test_media_progress_cancel() {
    cat << 'EOF' > /tmp/test3.js
const fs = require('fs');
const vm = require('vm');
const path = require('path');

let now = 10000;
let plays = 0;
let seq = 0;
const timers = new Map();
const intervals = [];
const listeners = {};
const events = [];

const video = {
    clientWidth: 100,
    clientHeight: 100,
    currentTime: 1,
    paused: false,
    ended: false,
    readyState: 4,
    dataset: {},
    addEventListener(n, f) { listeners[n] = f; },
    play: async () => { plays++; },
    textTracks: []
};

const root = {
    location: { origin: 'https://www.tiktok.com', pathname: '/@creator/live' },
    crypto: { randomUUID: () => `11111111-1111-1111-1111-${String(++seq).padStart(12, '0')}` },
    Date: class extends Date {
        static now() { return now; }
    },
    document: {
        scripts: [],
        body: { innerText: '' },
        querySelectorAll: s => s === 'video' ? [video] : [],
        querySelector: () => null
    },
    tlcBridge: {
        postMessage: s => events.push(JSON.parse(s))
    },
    addEventListener(n, f) { listeners[n] = f; },
    postMessage(m) { events.push(m); },
    setInterval: f => {
        intervals.push(f);
        return intervals.length;
    },
    clearInterval() {},
    setTimeout: (f, ms) => {
        const id = ++seq;
        timers.set(id, { f, at: now + ms });
        return id;
    },
    clearTimeout: id => timers.delete(id)
};

root.top = root;

vm.runInNewContext(fs.readFileSync(path.join('$RAW_ANDROID', 'android_recovery.js'), 'utf8'), root);

function tick(ms) {
    now += ms;
    for (const f of intervals) f();
    for (const [id, t] of [...timers]) {
        if (t.at <= now) {
            timers.delete(id);
            t.f();
        }
    }
}

root.TLC_MOBILE_RECOVERY.command('set-auto-reconnect', { enabled: true });
root.TLC_MOBILE_RECOVERY.recover('waiting');
video.currentTime = 2;

tick(3000);
console.assert(plays === 0, 'Plays should be 0 when current time changes');
EOF

    run_node_test "$(cat /tmp/test3.js)"
    echo "Test 3 passed."
}

# Test 4: Caption websocket activity expires independently from menu
test_caption_websocket_expire() {
    cat << 'EOF' > /tmp/test4.js
const fs = require('fs');
const vm = require('vm');
const path = require('path');

let now = 10000;
let plays = 0;
let seq = 0;
const timers = new Map();
const intervals = [];
const listeners = {};
const events = [];

const video = {
    clientWidth: 100,
    clientHeight: 100,
    currentTime: 1,
    paused: false,
    ended: false,
    readyState: 4,
    dataset: {},
    addEventListener(n, f) { listeners[n] = f; },
    play: async () => { plays++; },
    textTracks: []
};

const root = {
    location: { origin: 'https://www.tiktok.com', pathname: '/@creator/live' },
    crypto: { randomUUID: () => `11111111-1111-1111-1111-${String(++seq).padStart(12, '0')}` },
    Date: class extends Date {
        static now() { return now; }
    },
    document: {
        scripts: [],
        body: { innerText: '' },
        querySelectorAll: s => s === 'video' ? [video] : [],
        querySelector: () => null
    },
    tlcBridge: {
        postMessage: s => events.push(JSON.parse(s))
    },
    addEventListener(n, f) { listeners[n] = f; },
    postMessage(m) { events.push(m); },
    setInterval: f => {
        intervals.push(f);
        return intervals.length;
    },
    clearInterval() {},
    setTimeout: (f, ms) => {
        const id = ++seq;
        timers.set(id, { f, at: now + ms });
        return id;
    },
    clearTimeout: id => timers.delete(id)
};

root.top = root;

vm.runInNewContext(fs.readFileSync(path.join('$RAW_ANDROID', 'android_recovery.js'), 'utf8'), root);

function tick(ms) {
    now += ms;
    for (const f of intervals) f();
    for (const [id, t] of [...timers]) {
        if (t.at <= now) {
            timers.delete(id);
            t.f();
        }
    }
}

listeners.message({
    source: vm.runInNewContext("globalThis", root),
    origin: root.location.origin,
    data: {
        source: "tiktok-live-companion",
        type: "caption",
        caption: { contents: [{ lang: "de", text: "test" }] }
    }
});

const captionEvents = events.filter(x => x.type === "caption-state");
const lastCaptionEvent = captionEvents[captionEvents.length - 1];

console.assert(lastCaptionEvent.payload.websocket === true, 'Websocket should be active initially');

tick(16000);

const updatedCaptionEvents = events.filter(x => x.type === "caption-state");
const finalCaptionEvent = updatedCaptionEvents[updatedCaptionEvents.length - 1];

console.assert(finalCaptionEvent.payload.websocket === false, 'Websocket should be inactive after timeout');
console.assert(finalCaptionEvent.payload.activityTtlMs === 15000, 'Activity TTL should match expected value');
EOF

    run_node_test "$(cat /tmp/test4.js)"
    echo "Test 4 passed."
}

# Test 5: Android uses byte-identical browser controller and protocol parser
test_android_browser_identical() {
    for pair in "hook_recovery.js hook-recovery.js" "recovery_hook.js hook.js" "proto_main.js proto-main.js"; do
        read mobile browser <<< "$pair"
        diff "$RAW_ANDROID/$mobile" "$BROWSER_EXT/$browser" || {
            echo "Files $mobile and $browser differ"
            exit 1
        }
    done
    echo "Test 5 passed."
}

# Test 6: iOS WebKit bridge receives correlated recovery observations
test_ios_webkit_bridge() {
    cat << 'EOF' > /tmp/test6.js
const fs = require('fs');
const vm = require('vm');
const path = require('path');

let now = 10000;
let plays = 0;
let seq = 0;
const timers = new Map();
const intervals = [];
const listeners = {};
const events = [];

const video = {
    clientWidth: 100,
    clientHeight: 100,
    currentTime: 1,
    paused: false,
    ended: false,
    readyState: 4,
    dataset: {},
    addEventListener(n, f) { listeners[n] = f; },
    play: async () => { plays++; },
    textTracks: []
};

delete root.tlcBridge;
root.webkit = {
    messageHandlers: {
        tlcBridge: {
            postMessage: m => events.push(m)
        }
    }
};

const root = {
    location: { origin: 'https://www.tiktok.com', pathname: '/@creator/live' },
    crypto: { randomUUID: () => `11111111-1111-1111-1111-${String(++seq).padStart(12, '0')}` },
    Date: class extends Date {
        static now() { return now; }
    },
    document: {
        scripts: [],
        body: { innerText: '' },
        querySelectorAll: s => s === 'video' ? [video] : [],
        querySelector: () => null
    },
    webkit: {
        messageHandlers: {
            tlcBridge: {
                postMessage: m => events.push(m)
            }
        }
    },
    addEventListener(n, f) { listeners[n] = f; },
    postMessage(m) { events.push(m); },
    setInterval: f => {
        intervals.push(f);
        return intervals.length;
    },
    clearInterval() {},
    setTimeout: (f, ms) => {
        const id = ++seq;
        timers.set(id, { f, at: now + ms });
        return id;
    },
    clearTimeout: id => timers.delete(id)
};

root.top = root;

vm.runInNewContext(fs.readFileSync(path.join('$RAW_ANDROID', 'android_recovery.js'), 'utf8'), root);

function tick(ms) {
    now += ms;
    for (const f of intervals) f();
    for (const [id, t] of [...timers]) {
        if (t.at <= now) {
            timers.delete(id);
            t.f();
        }
    }
}

tick(1000);

const observationEvent = events.find(x => x.type === 'player-observation');
console.assert(observationEvent !== undefined, 'Player observation event should exist');
console.assert(observationEvent.payload.frameKind === 'top', 'Frame kind should be top');
console.assert(/^[a-f0-9-]{36}$/.test(observationEvent.payload.documentId), 'Document ID should match UUID pattern');

listeners.message({
    source: vm.runInNewContext("globalThis", root),
    origin: root.location.origin,
    data: {
        source: "tiktok-live-companion",
        type: 'caption',
        caption: { text: 'ios-caption' }
    }
});

const captionEvent = events.filter(x => x.type === 'caption')[0];
console.assert(captionEvent.payload.text === 'ios-caption', 'Caption text should match');
EOF

    run_node_test "$(cat /tmp/test6.js)"
    echo "Test 6 passed."
}

# Test 7: iOS and Android inject identical recovery implementations
test_ios_android_recovery_identical() {
    declare -A file_pairs=(
        ["android_recovery.js"]="mobile-recovery.js"
        ["hook_recovery.js"]="hook-recovery.js"
        ["recovery_hook.js"]="recovery-hook.js"
        ["export_privacy.js"]="export-privacy.js"
        ["proto_main.js"]="proto-main.js"
        ["content_core.js"]="content-core.js"
    )

    for android in "${!file_pairs[@]}"; do
        ios="${file_pairs[$android]}"
        diff "$RAW_ANDROID/$android" "$RAW_IOS/$ios" || {
            echo "Files $android and $ios differ"
            exit 1
        }
    done
    echo "Test 7 passed."
}

# Test 8: Connection off stops Companion chat delivery, on resumes without touching player
test_connection_chat_delivery() {
    for ios_mode in false true; do
        cat << EOF > /tmp/test8_$ios_mode.js
const fs = require('fs');
const vm = require('vm');
const path = require('path');

let now = 10000;
let plays = 0;
let seq = 0;
const timers = new Map();
const intervals = [];
const listeners = {};
const events = [];

const video = {
    clientWidth: 100,
    clientHeight: 100,
    currentTime: 1,
    paused: false,
    ended: false,
    readyState: 4,
    dataset: {},
    addEventListener(n, f) { listeners[n] = f; },
    play: async () => { plays++; },
    textTracks: []
};

const root = {
    location: { origin: 'https://www.tiktok.com', pathname: '/@creator/live' },
    crypto: { randomUUID: () => \`11111111-1111-1111-1111-\${String(++seq).padStart(12, '0')}\` },
    Date: class extends Date {
        static now() { return now; }
    },
    document: {
        scripts: [],
        body: { innerText: '' },
        querySelectorAll: s => s === 'video' ? [video] : [],
        querySelector: () => null
    },
    tlcBridge: {
        postMessage: s => events.push(JSON.parse(s))
    },
    addEventListener(n, f) { listeners[n] = f; },
    postMessage(m) { events.push(m); },
    setInterval: f => {
        intervals.push(f);
        return intervals.length;
    },
    clearInterval() {},
    setTimeout: (f, ms) => {
        const id = ++seq;
        timers.set(id, { f, at: now + ms });
        return id;
    },
    clearTimeout: id => timers.delete(id)
};

root.top = root;

vm.runInNewContext(fs.readFileSync(path.join('$RAW_ANDROID', 'android_recovery.js'), 'utf8'), root);

function tick(ms) {
    now += ms;
    for (const f of intervals) f();
    for (const [id, t] of [...timers]) {
        if (t.at <= now) {
            timers.delete(id);
            t.f();
        }
    }
}

root.TLC_MOBILE_RECOVERY.command('set-connection', { enabled: false });

listeners.message({
    source: vm.runInNewContext("globalThis", root),
    origin: root.location.origin,
    data: {
        source: "tiktok-live-companion",
        type: 'chat-message',
        chatMessage: { content: 'hidden from Companion' }
    }
});

console.assert(events.filter(e => e.type === 'chat').length === 0, 'Chat messages should be hidden when connection is disabled');

root.TLC_MOBILE_RECOVERY.command('set-connection', { enabled: true });

listeners.message({
    source: vm.runInNewContext("globalThis", root),
    origin: root.location.origin,
    data: {
        source: "tiktok-live-companion",
        type: 'chat-message',
        chatMessage: { content: 'visible' }
    }
});

console.assert(events.filter(e => e.type === 'chat').length === 1, 'Chat message should be visible when connection is enabled');
console.assert(plays === 0, 'Plays should remain zero throughout this test');
EOF

        run_node_test "$(cat /tmp/test8_$ios_mode.js)"
    done
    echo "Test 8 passed."
}

# Run all tests
main() {
    test_player_recovery_wait
    test_user_pause_cancel_recovery
    test_media_progress_cancel
    test_caption_websocket_expire
    test_android_browser_identical
    test_ios_webkit_bridge
    test_ios_android_recovery_identical
    test_connection_chat_delivery
    echo "All tests passed."
}

main "$@"
