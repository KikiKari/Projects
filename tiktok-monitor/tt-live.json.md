# `tt-live.json` — Configuration Reference

Source: `tt-live.json`. Format: JSON5 (JSON with comments and trailing
commas allowed).

---

## 1. What this file is

`tt-live.json` is a **defaults reference document**. It records the
three runtime tunable values used by the TikTok LIVE monitor, with
their canonical default values.

**The current `tt_live.py` does NOT read this file.** The values live
as module-level constants inside `tt_live.py`:

| Constant in `tt_live.py` | Key in `tt-live.json` | Default |
|---|---|---|
| `URL_RETENTION_DAYS` | `url_retention_days` | `3` |
| `REQUEST_TIMEOUT_SEC` | `request_timeout_sec` | `15` |
| (uses `shutil.which("yt-dlp")`) | `yt_dlp_path` | `""` |

The values in this file are kept in **strict 1:1 correspondence** with
the module constants. They are not configuration in the conventional
sense — they are documentation of what the live, hardcoded values are.

---

## 2. The three keys

### 2.1 `url_retention_days`

**Type**: integer  ·  **Range**: ≥ 1  ·  **Default**: `3`

Stream URL retention window. `StateStore.strip_stale_urls()` removes
entries from `<sec_uid>.state.json` whose `captured_at` is older than
this many days. The strip runs on every state-write path (passive
garbage collection — there is no scheduler).

3 days is calibrated to TikTok's stream URL signature expiry, which is
roughly 14 days but with two-stage client-side restrictions kicking in
much earlier (~40-60s ABR downgrade, ~14min bundle swap). 3 days
balances "the cache is fresh enough to still be useful for forensics"
against "the file does not grow without bound."

### 2.2 `request_timeout_sec`

**Type**: integer  ·  **Range**: ≥ 1  ·  **Default**: `15`

Per-HTTP-request timeout for direct stdlib `urllib` calls
(`fetch_user_live_page`, `fetch_room_info`, `fetch_check_alive`).
Subprocess fallbacks receive `2 × request_timeout_sec` (30s default)
as their subprocess timeout.

15s is calibrated to TikTok's typical response latency from European
egress points (~200-600ms first byte) plus headroom for SIGI_STATE
delivery on slow CDN edges.

### 2.3 `yt_dlp_path`

**Type**: string  ·  **Default**: `""`

Override for the yt-dlp binary location used as the second-tier
stream-URL extraction fallback. Empty string means "auto-discover via
`shutil.which('yt-dlp')` on PATH".

A non-empty value must point at an executable file. If the path is set
but the file does not exist or is not executable, yt-dlp extraction
is skipped and the orchestrator falls through to streamlink.

---

## 3. Why these are hardcoded

The three values are **required for the tool to function correctly**.
They are not user preferences — they are tuned to:

- **TikTok's API behavior** (`request_timeout_sec` matches observed
  response latency)
- **TikTok's stream URL lifecycle** (`url_retention_days` matches
  practical signature validity)
- **The expected runtime environment** (`yt_dlp_path` defaults to
  PATH discovery, which works in 100% of standard installs)

Ad-hoc changes — especially to `request_timeout_sec` — can break the
tool. Setting it too low causes spurious fetch failures on slow
connections. Setting it too high makes daemon polls block past the
poll interval, breaking the polling rhythm.

**Do not edit these values casually.**

---

## 4. When and how to change values

If a value genuinely needs to change (for example, a permanently slow
network requiring a longer timeout), the recommended workflow is:

1. **Use a script** that knows the canonical defaults from this file.
2. The script applies the **targeted change** to `tt_live.py`'s module
   constants.
3. The script must also offer a **reset-to-default** mode that
   restores the values documented here.

This pattern keeps the canonical defaults discoverable (they live in
this file) while letting controlled overrides happen through a
reviewable, reversible mechanism. Ad-hoc hand-editing of `tt_live.py`
is discouraged because there is no way to "undo" the change without
remembering what the original value was.

The script itself is out of scope for this skill. It is the caller's
responsibility (typically an OpenClaw maintenance agent) to implement
it when it is needed. The defaults in this file are the authoritative
source the script should target.

---

## 5. File location

The skill looks for `tt-live.json` in two places, in this priority:

1. `$TT_LIVE_WORKSPACE/tt-live.json` — workspace override (typically
   `~/.openclaw/workspace/tiktok-monitor/tt-live.json`)
2. Same directory as `tt_live.py` and `tt-live.sh` — skill default

This priority matches the workspace convention: data lives in
`$TT_LIVE_WORKSPACE`, code lives next to the entry-point scripts.

Since the current `tt_live.py` does not load the file at all, both
paths are documentation-only for now. They define the canonical
locations a future loader (or the change-script described in §4)
should look at.

---

## 6. Format details

JSON5 specifics used in this file:

- `//`-style line comments
- Trailing commas in objects and arrays (not used here but allowed)
- Unquoted identifier keys (not used here — all keys are quoted for
  maximum tooling compatibility)

To parse the file with stock Python `json`:

```python
import re, json

def load_tt_live_json(path):
    src = open(path).read()
    # strip // line comments
    src = re.sub(r'//.*$', '', src, flags=re.MULTILINE)
    # strip trailing commas before } or ]
    src = re.sub(r',(\s*[\]}])', r'\1', src)
    return json.loads(src)
```

This snippet handles the JSON5 subset actually used in
`tt-live.json`. The full JSON5 spec is broader; install a real JSON5
library (e.g. `pyjson5`) if more advanced features are needed.

---

## 7. What is intentionally NOT in this file

For audit purposes, the following keys were considered and
**deliberately excluded** based on confirmed requirements:

- No `format_cap` — 360p cap is hardcoded in `tt_live.py` and is
  required for the bandwidth profile assumed by the skill
- No `min_poll_minutes` — 5-minute floor is hardcoded; lowering it
  risks TikTok rate-limit pushback
- No `default_daemon_hours` — already exposed via `--hours` CLI flag
- No `tt_aid` — `1988` is a TikTok constant, not a user choice
- No `user_agent` — changing it can cause webcast endpoints to reject
  requests
- No `notifications.*` keys — the tool is a pure data provider; no
  outbound notifications
- No `webhook_*` keys, no `slack_*` keys, no `discord_*` keys
- No `streamlink_path` — only `yt_dlp_path` was specified; if
  streamlink needs an override later, it gets added explicitly
- No `log_level` / `log_path` — the wrapper handles daemon log files;
  the Python code has no internal logging knob
- No `workspace` key — that is the `TT_LIVE_WORKSPACE` env var's job

Each absence is a deliberate scope choice, not an oversight.
