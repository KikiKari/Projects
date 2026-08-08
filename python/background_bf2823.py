#!/usr/bin/env python3
# background.js — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/browser-extension/background.js
# auch in: Projects@TikTok-Live-Companion:release/0.7.1/tiktok-live-companion-extension-0.7.1/background.js
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/background.js
# auch in: Projects@TikTok-Live-Companion-Android:release/0.7.1/tiktok-live-companion-extension-0.7.1/background.js
# auch in: 2 weiteren Fundstellen
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

import asyncio
import base64
import hashlib
import json
import os
import random
import re
import string
import sys
import time
import urllib.parse
from collections import defaultdict, deque
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple, Union

# Import required modules
try:
    import aiohttp
    from aiohttp import web
except ImportError:
    print("Please install aiohttp: pip install aiohttp")
    sys.exit(1)

# Constants
STATE_PREFIX = "tlc-tab-"
LEGACY_HOOK_SCRIPT_ID = "tiktok-live-companion-ws-hook"
SETTINGS_KEY = "tlc-settings"
SERVICE_INSTALL_KEY = "tlc-service-install"
PROFILE_PREFIX = "tlc-profile-"
STREAM_CACHE_PREFIX = "tlc-stream-"
MAX_MEDIA = 60
MAX_CAPTIONS = 2000
MAX_CHAT = 500
MAX_EVENT_IDS = 500
MAX_DEBUG = 500
MAX_PARTICIPANTS = 5000

# Global variables
offscreen_creation = None
tabs = {}  # Simulated tabs storage
storage_session = {}  # Simulated chrome.storage.session
storage_local = {}  # Simulated chrome.storage.local

class TLCContentCore:
    EMPTY_PROFILE_INFO = {
        "present": False,
        "uniqueId": "",
        "nickname": "",
        "avatarThumb": "",
        "signature": "",
        "verified": False,
        "verifiedLabel": "",
        "livePro": False,
        "liveProLabel": "",
        "sponsoredContent": False,
        "sponsoredContentLabel": "",
        "paidPartnership": False,
        "paidPartnershipLabel": "",
        "followingCount": 0,
        "followerCount": 0,
        "likeCount": 0,
        "isLive": False
    }
    
    EMPTY_AI_SUMMARY_INFO = {
        "present": False,
        "title": "",
        "description": "",
        "keywords": [],
        "generatedAtUtc": None
    }

    @staticmethod
    def normalizedIdentity(value):
        return str(value or "").lower().strip()

    @staticmethod
    def sanitizeChatText(text):
        return str(text or "").strip()

    @staticmethod
    def wordCount(text):
        return len(str(text or "").split())

    @staticmethod
    def spokenNickname(name):
        return str(name or "").split()[0] if str(name or "").split() else "Unknown"

    @staticmethod
    def stripTeamTag(text, team_tag):
        if not team_tag:
            return text
        return re.sub(rf'\b{re.escape(team_tag)}\b', '', str(text or ""), flags=re.IGNORECASE).strip()

    @staticmethod
    def accumulateTeamEvidence(evidence, author, content, recent_messages):
        # Simplified implementation
        return {"evidence": evidence, "teamTag": ""}

    @staticmethod
    def sameParticipant(p1, p2):
        return (p1.get("userId") and p1["userId"] == p2.get("userId")) or \
               (p1.get("displayId") and p1["displayId"] == p2.get("displayId")) or \
               (p1.get("name") and p1["name"] == p2.get("name"))

    @staticmethod
    def mergeParticipantRecord(existing, raw, author, patch):
        result = {
            "userId": raw.get("userId") or (existing.get("userId") if existing else None),
            "displayId": raw.get("displayId") or (existing.get("displayId") if existing else ""),
            "name": author or (existing.get("name") if existing else "Chat"),
            "messageCount": (existing.get("messageCount", 0) if existing else 0) + (1 if not existing else 0),
            "wordCount": (existing.get("wordCount", 0) if existing else 0) + TLCContentCore.wordCount(raw.get("content", "")),
            "giftEventCount": existing.get("giftEventCount", 0) if existing else 0,
            "giftItemCount": existing.get("giftItemCount", 0) if existing else 0,
            "firstSeenAtUtc": existing.get("firstSeenAtUtc") if existing else datetime.now(timezone.utc).isoformat()
        }
        if patch:
            result.update(patch)
        return result

    @staticmethod
    def captionsOverlap(c1, c2):
        return False  # Simplified

    @staticmethod
    def captionText(caption):
        return " ".join([content.get("text", "") for content in caption.get("contents", [])])

    @staticmethod
    def mergeObservedCaptionInfo(current, new_caption):
        return current  # Simplified

    @staticmethod
    def classifyMediaUrl(url):
        return {"url": url, "protocol": "unknown", "audioOnly": False}  # Simplified

    @staticmethod
    def resolveSpeechLanguage(setting_lang, content_lang):
        return setting_lang if setting_lang != "auto" else (content_lang or "en-US")

    @staticmethod
    def shouldFilterGameModeSpeech(item, participants, chat_messages):
        return False  # Simplified

    @staticmethod
    def composeSpeechText(item, options):
        return f"{item.get('author', '')}: {item.get('content', '')}" if options.get("speakNames") else item.get("content", "")

    @staticmethod
    def gameEventSpeech(message):
        return ""  # Simplified

    @staticmethod
    def streamIdentityChanged(current, incoming):
        return current.get("handle") != incoming.get("handle") or current.get("roomId") != incoming.get("roomId")

    @staticmethod
    def limiterStrengthToDbfs(strength):
        return -20.0  # Simplified

    @staticmethod
    def limiterDbfsToStrength(dbfs):
        return 30  # Simplified

# Initialize core
core = TLCContentCore()

def stateKey(tabId):
    return f"{STATE_PREFIX}{tabId}"

def newBrowserSessionId():
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=32))

def emptyState():
    return {
        "enabled": False,
        "browserSessionId": "",
        "page": {"url": "", "title": "", "scannedAtUtc": None},
        "captionInfo": {"present": False, "open": None, "supportLang": [], "location": None, "showType": None, "observed": False, "source": None},
        "profileInfo": {**core.EMPTY_PROFILE_INFO},
        "aiSummaryInfo": {**core.EMPTY_AI_SUMMARY_INFO},
        "menuCaptionAvailable": False,
        "menuCaptionActive": False,
        "hook": {"armed": False, "installed": False, "connected": False, "lastError": None},
        "stream": {"key": "", "handle": "", "roomId": "", "teamTag": "", "teamEvidence": {}},
        "liveStats": {
            "viewerCount": None,
            "totalViewers": None,
            "likeCount": None,
            "followEvents": 0,
            "shareEvents": 0,
            "shareCount": None,
            "followerCount": None,
            "lastUpdatedUtc": None,
            "recentEventIds": []
        },
        "selectedQuality": None,
        "playerState": {
            "available": False, "playing": False, "muted": False, "elapsedText": "", "pipActive": False, "fullscreenActive": False,
            "volume": 1, "volumePercent": 100, "volumeGainDb": 0, "peakDbfs": None,
            "limiterEnabled": False, "limiterStrength": 30, "limiterThresholdDbfs": core.limiterStrengthToDbfs(30), "limiterReductionDb": 0,
            "connectedStreams": 0, "multiGuest": False
        },
        "media": [],
        "captions": [],
        "chatMessages": [],
        "chatSourceTabId": None,
        "chatTargetTabId": None,
        "chatSourceOnly": False,
        "participants": {},
        "participantsTruncated": False,
        "streamMutes": [],
        "recentGiftIds": [],
        "quickRecoverEnabled": False,
        "speech": {"enabled": False, "status": "Vorlesen ist ausgeschaltet.", "lastSpokenKey": "", "lastSpokenAtUtc": None, "queueDepth": 0},
        "recovery": {"lastQuickRecoverAtUtc": None, "lastReason": ""},
        "debug": {"enabled": False, "entries": []}
    }

async def getState(tabId):
    stored = storage_session.get(stateKey(tabId), {})
    defaults = emptyState()
    state = stored
    if not state:
        return defaults
    return {
        **defaults,
        **state,
        "hook": {**defaults["hook"], **(state.get("hook", {}))},
        "stream": {**defaults["stream"], **(state.get("stream", {})), "teamEvidence": state.get("stream", {}).get("teamEvidence", {})},
        "liveStats": {**defaults["liveStats"], **(state.get("liveStats", {}))},
        "playerState": {**defaults["playerState"], **(state.get("playerState", {}))},
        "profileInfo": {**defaults["profileInfo"], **(state.get("profileInfo", {}))},
        "aiSummaryInfo": {**defaults["aiSummaryInfo"], **(state.get("aiSummaryInfo", {}))},
        "chatMessages": state.get("chatMessages", []),
        "participants": state.get("participants", {}),
        "participantsTruncated": bool(state.get("participantsTruncated")),
        "streamMutes": state.get("streamMutes", []),
        "recentGiftIds": state.get("recentGiftIds", []),
        "quickRecoverEnabled": bool(state.get("quickRecoverEnabled")),
        "speech": {**defaults["speech"], **(state.get("speech", {}))},
        "recovery": {**defaults["recovery"], **(state.get("recovery", {}))},
        "captions": state.get("captions", []),
        "media": state.get("media", []),
        "debug": {**defaults["debug"], **(state.get("debug", {})), "entries": state.get("debug", {}).get("entries", [])}
    }

def pageHandle(page):
    try:
        url = page.get("url", "") if page else ""
        parsed = urllib.parse.urlparse(urllib.parse.unquote(url))
        path = parsed.path
        match = re.match(r"^/@([^/]+)/live/?$", path, re.IGNORECASE)
        if match:
            return match.group(1).lower()
        match = re.match(r"^/embed/live/@?([^/?#]+)/?$", path, re.IGNORECASE)
        if match:
            return match.group(1).lower()
        return ""
    except Exception:
        return ""

def normalizeHandle(value):
    return str(value or "").lstrip("@").lower()

def profileHandle(profile):
    return normalizeHandle(profile.get("uniqueId", profile.get("handle", "")))

def stateIdentityHandle(state):
    return normalizeHandle(
        state.get("stream", {}).get("handle", "") or
        state.get("profileInfo", {}).get("uniqueId", "") or
        pageHandle(state.get("page", {})) or
        ""
    )

def pageStateHandle(state, message=None):
    if message is None:
        message = {}
    return normalizeHandle(
        pageHandle(message.get("page", state.get("page", {}))) or
        profileHandle(message.get("profileInfo", {})) or
        state.get("stream", {}).get("handle", "") or
        ""
    )

def profileMatchesHandle(profile, handle):
    candidate = profileHandle(profile)
    return not handle or not candidate or candidate == handle

def resetPageIdentityState(state, handle):
    state["profileInfo"] = {**core.EMPTY_PROFILE_INFO}
    state["aiSummaryInfo"] = {**core.EMPTY_AI_SUMMARY_INFO}
    state["liveStats"]["followerCount"] = None

def resetPageIdentityIfChanged(state, nextHandle):
    currentHandle = stateIdentityHandle(state)
    if not nextHandle or not currentHandle or nextHandle == currentHandle:
        return False
    resetPageIdentityState(state, nextHandle)
    return True

def profileKey(handle):
    return f"{PROFILE_PREFIX}{str(handle or '').lower()}"

async def cacheProfile(profile):
    if not profile.get("present") or not profile.get("uniqueId"):
        return
    normalizedHandle = str(profile["uniqueId"]).lower()
    storage_session[profileKey(normalizedHandle)] = profile
    for key, value in storage_session.items():
        if not key.startswith(STATE_PREFIX) or pageHandle(value.get("page", {})) != normalizedHandle:
            continue
        merged = mergeProfile(value.get("profileInfo", {}), profile)
        value["profileInfo"] = merged
        if merged.get("followerCount") is not None:
            value["liveStats"]["followerCount"] = merged["followerCount"]
        targetTabId = int(key[len(STATE_PREFIX):])
        if isinstance(targetTabId, int):
            await setState(targetTabId, value)

async def cachedProfile(handle):
    if not handle:
        return None
    return storage_session.get(profileKey(handle), None)

async def addDebug(tabId, event, detail=None):
    if detail is None:
        detail = {}
    if not isinstance(tabId, int) or tabId < 0:
        return
    state = await getState(tabId)
    if not state["debug"].get("enabled"):
        return
    entries = state["debug"].get("entries", [])
    entries.append({
        "atUtc": datetime.now(timezone.utc).isoformat(),
        "event": event,
        "detail": detail
    })
    state["debug"]["entries"] = entries[-MAX_DEBUG:]
    await setState(tabId, state)

def redactUrl(raw):
    try:
        parsed = urllib.parse.urlparse(raw)
        query_dict = urllib.parse.parse_qs(parsed.query)
        for key in query_dict:
            query_dict[key] = ["REDACTED"]
        redacted_query = urllib.parse.urlencode(query_dict, doseq=True)
        return urllib.parse.urlunparse((
            parsed.scheme,
            parsed.netloc,
            parsed.path,
            parsed.params,
            redacted_query,
            parsed.fragment
        ))
    except Exception:
        return "ungültig"

async def setState(tabId, state):
    storage_session[stateKey(tabId)] = state
    await cacheStreamSnapshot(state)
    # In a real extension, this would send a message to other parts
    return state

async def getSettings():
    stored = storage_local.get(SETTINGS_KEY, {})
    return {
        "keepSpeechActive": False,
        "speechVolume": 0.5,
        "speechLanguage": "auto",
        "speechVoiceName": "",
        "gameModeEnabled": False,
        "speakNames": True,
        "shortenNames": False,
        "autoChatRefreshEnabled": False,
        "autoChatRefreshMinutes": 5,
        "serviceUrl": "http://127.0.0.1:43117",
        "pairingCode": "",
        "auddApiToken": "",
        "playerVolume": 100,
        "limiterStrength": 30,
        "limiterEnabled": False,
        "songRecognitionEnabled": False,
        "hookEnabled": False,
        "autoHook": False,
        "quickRecoverEnabled": False,
        "speechEnabled": False,
        "waitingForTikTok": True,
        "debugEnabled": False,
        "permanentMutes": [],
        **stored
    }

async def setSettings(patch):
    settings = {**(await getSettings()), **patch}
    storage_local[SETTINGS_KEY] = settings
    return settings

def booleanValue(value):
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value != 0
    if isinstance(value, str):
        return re.match(r"^(?:1|true|yes|ja|on)$", value.strip(), re.IGNORECASE) is not None
    return bool(value)

def normalizePlayerState(playerState=None):
    if playerState is None:
        playerState = {}
    return {
        **playerState,
        "available": booleanValue(playerState.get("available")),
        "videoAvailable": booleanValue(playerState.get("videoAvailable", playerState.get("available"))),
        "controlAvailable": booleanValue(playerState.get("controlAvailable")),
        "playing": booleanValue(playerState.get("playing")),
        "muted": booleanValue(playerState.get("muted")),
        "limiterEnabled": booleanValue(playerState.get("limiterEnabled")),
        "pipActive": booleanValue(playerState.get("pipActive")),
        "fullscreenActive": booleanValue(playerState.get("fullscreenActive")),
        "multiGuest": booleanValue(playerState.get("multiGuest"))
    }

def loopbackServiceUrl(value):
    try:
        url = urllib.parse.urlparse(str(value or ""))
        if url.scheme != "http" or url.hostname not in ["127.0.0.1", "localhost"]:
            return ""
        return f"{url.scheme}://{url.hostname}:{url.port if url.port else 80}"
    except Exception:
        return ""

def profileCompleteness(profile):
    fields = [
        profile.get("uniqueId"),
        profile.get("nickname"),
        profile.get("signature"),
        profile.get("followingCount"),
        profile.get("followerCount"),
        profile.get("likeCount"),
        "verified" if profile.get("verified") else "",
        "livePro" if profile.get("livePro") else "",
        "sponsoredContent" if profile.get("sponsoredContent") else "",
        "paidPartnership" if profile.get("paidPartnership") else ""
    ]
    return len([f for f in fields if f not in (None, "")])

def mergeProfile(current, incoming):
    if not incoming.get("present"):
        return current
    merged = {**current, **incoming} if not current.get("present") or profileCompleteness(incoming) >= profileCompleteness(current) else {**incoming, **current}
    return {
        **merged,
        "live": bool(current.get("live") or incoming.get("live")),
        "verified": bool(current.get("verified") or incoming.get("verified")),
        "verifiedLabel": current.get("verifiedLabel") or incoming.get("verifiedLabel") or "",
        "livePro": bool(current.get("livePro") or incoming.get("livePro")),
        "liveProLabel": current.get("liveProLabel") or incoming.get("liveProLabel") or "",
        "sponsoredContent": bool(current.get("sponsoredContent") or incoming.get("sponsoredContent")),
        "sponsoredContentLabel": current.get("sponsoredContentLabel") or incoming.get("sponsoredContentLabel") or "",
        "paidPartnership": bool(current.get("paidPartnership") or incoming.get("paidPartnership")),
        "paidPartnershipLabel": current.get("paidPartnershipLabel") or incoming.get("paidPartnershipLabel") or ""
    }

def streamCacheKey(handle):
    return f"{STREAM_CACHE_PREFIX}{str(handle or '').lower()}"

def streamCacheHandle(state):
    return str(
        state.get("stream", {}).get("handle", "") or
        pageHandle(state.get("page", {})) or
        state.get("profileInfo", {}).get("uniqueId", "") or
        ""
    ).lower()

def mergeLiveStats(current=None, incoming=None):
    if incoming is None or not isinstance(incoming, dict):
        return current or {}
    merged = {**emptyState()["liveStats"], **(current or {})}
    for key in ["viewerCount", "totalViewers", "likeCount", "shareCount", "followerCount"]:
        if incoming.get(key) is not None and incoming[key] != "":
            merged[key] = incoming[key]
    if incoming.get("lastUpdatedUtc"):
        merged["lastUpdatedUtc"] = incoming["lastUpdatedUtc"]
    return merged

async def cacheStreamSnapshot(state):
    handle = streamCacheHandle(state)
    if not handle:
        return
    hasLiveStats = bool(
        state.get("liveStats", {}).get("lastUpdatedUtc") or
        state.get("liveStats", {}).get("viewerCount") is not None or
        state.get("liveStats", {}).get("totalViewers") is not None or
        state.get("liveStats", {}).get("likeCount") is not None
    )
    hasChat = bool(
        len(state.get("chatMessages", [])) or
        len(state.get("participants", {}))
    )
    if not hasLiveStats and not hasChat:
        return
    storage_session[streamCacheKey(handle)] = {
        "handle": handle,
        "stream": state.get("stream", {}),
        "liveStats": state.get("liveStats", {}),
        "chatMessages": state.get("chatMessages", []),
        "participants": state.get("participants", {}),
        "participantsTruncated": bool(state.get("participantsTruncated")),
        "updatedAtUtc": datetime.now(timezone.utc).isoformat()
    }

async def cachedStreamSnapshot(handle):
    if not handle:
        return None
    return storage_session.get(streamCacheKey(handle), None)

def mergeStreamSnapshot(state, snapshot):
    if not snapshot:
        return state
    sameHandle = not state.get("stream", {}).get("handle") or not snapshot.get("handle") or state["stream"]["handle"] == snapshot["handle"]
    if not sameHandle:
        return state
    state["liveStats"] = mergeLiveStats(state.get("liveStats", {}), snapshot.get("liveStats", {}))
    if not len(state.get("chatMessages", [])) and len(snapshot.get("chatMessages", [])):
        state["chatMessages"] = snapshot["chatMessages"]
    if not len(state.get("participants", {})) and snapshot.get("participants"):
        state["participants"] = snapshot["participants"]
        state["participantsTruncated"] = bool(snapshot.get("participantsTruncated"))
    return state

async def patchState(tabId, patch):
    state = await getState(tabId)
    state.update(patch)
    return await setState(tabId, state)

async def addMedia(tabId, entries, source):
    if not isinstance(tabId, int) or tabId < 0:
        return
    state = await getState(tabId)
    
    def mediaKey(item):
        try:
            parsed = urllib.parse.urlparse(item["url"])
            return f"{item['protocol']}|{1 if item.get('audioOnly') else 0}|{parsed.path}"
        except Exception:
            return item["url"]
    
    def expiry(item):
        try:
            parsed = urllib.parse.urlparse(item["url"])
            params = urllib.parse.parse_qs(parsed.query)
            return int(params.get("expire", [0])[0])
        except Exception:
            return 0
    
    byUrl = {}
    for item in state["media"]:
        key = mediaKey(item)
        previous = byUrl.get(key)
        if not previous or expiry(item) >= expiry(previous):
            byUrl[key] = item
    
    for raw in entries or []:
        classified = core.classifyMediaUrl(raw) if isinstance(raw, str) else core.classifyMediaUrl(raw.get("url", ""))
        if not classified:
            continue
        enriched = {**classified, **(raw if isinstance(raw, dict) else {"url": classified["url"]}), "url": classified["url"]}
        key = mediaKey(enriched)
        previous = byUrl.get(key)
        candidate = {
            **(previous or {}),
            **enriched,
            "source": previous.get("source") if previous else source,
            "discoveredAtUtc": previous.get("discoveredAtUtc") if previous else datetime.now(timezone.utc).isoformat()
        }
        if not previous or expiry(candidate) >= expiry(previous):
            byUrl[key] = candidate
    
    state["media"] = list(byUrl.values())[-MAX_MEDIA:] if len(byUrl) > MAX_MEDIA else list(byUrl.values())
    await setState(tabId, state)

async def addCaption(tabId, caption):
    state = await getState(tabId)
    receivedAtUtc = caption.get("receivedAtUtc") or datetime.now(timezone.utc).isoformat()
    timestamp = datetime.fromisoformat(receivedAtUtc.replace("Z", "+00:00")).timestamp() * 1000 if "Z" in receivedAtUtc else time.time() * 1000
    
    if caption.get("source") == "dom":
        recentWebSocket = None
        for item in reversed(state["captions"]):
            if item.get("method") == "WebcastCaptionMessage":
                recentWebSocket = item
                break
        if recentWebSocket:
            recent_timestamp = datetime.fromisoformat(recentWebSocket.get("receivedAtUtc", "1970-01-01T00:00:00+00:00").replace("Z", "+00:00")).timestamp() * 1000
            if abs(timestamp - recent_timestamp) < 8000 and core.captionsOverlap(caption, recentWebSocket):
                return
        last = state["captions"][-1] if state["captions"] else None
        if last and last.get("source") == "dom":
            last_timestamp = datetime.fromisoformat(last.get("receivedAtUtc", "1970-01-01T00:00:00+00:00").replace("Z", "+00:00")).timestamp() * 1000
            if timestamp - last_timestamp < 2500 and core.captionsOverlap(last, caption):
                replacement_text_len = len(core.captionText(caption))
                last_text_len = len(core.captionText(last))
                replacement = {**caption, "receivedAtUtc": receivedAtUtc} if replacement_text_len >= last_text_len else {**last, "receivedAtUtc": receivedAtUtc}
                state["captions"][-1] = replacement
                state["captionInfo"] = core.mergeObservedCaptionInfo(state["captionInfo"], replacement)
                await setState(tabId, state)
                return
    
    entry = {**caption, "receivedAtUtc": receivedAtUtc}
    key = entry.get("sentenceId") or entry.get("sequenceId") or "\n".join([f"{content.get('lang', '')}:{content.get('text', '')}" for content in entry.get("contents", [])])
    duplicate = key and any(
        (item.get("sentenceId") or item.get("sequenceId") or "\n".join([f"{content.get('lang', '')}:{content.get('text', '')}" for content in item.get("contents", [])])) == key
        for item in state["captions"][-20:]
    )
    if duplicate:
        return
    
    if entry.get("method") == "WebcastCaptionMessage":
        filtered_captions = []
        for item in state["captions"]:
            if not (
                item.get("source") == "dom" and
                abs(timestamp - (datetime.fromisoformat(item.get("receivedAtUtc", "1970-01-01T00:00:00+00:00").replace("Z", "+00:00")).timestamp() * 1000)) < 8000 and
                core.captionsOverlap(item, entry)
            ):
                filtered_captions.append(item)
        state["captions"] = filtered_captions
    
    state["captions"].append(entry)
    state["captions"] = state["captions"][-MAX_CAPTIONS:]
    state["captionInfo"] = core.mergeObservedCaptionInfo(state["captionInfo"], entry)
    await setState(tabId, state)

def chatKey(author, content):
    return f"{str(author or '').lower()}\n{str(content or '').lower()}"

def participantKey(message, fallbackAuthor=""):
    if message.get("userId"):
        return f"id:{message['userId']}"
    if message.get("displayId"):
        return f"handle:{core.normalizedIdentity(message['displayId'])}"
    return f"name:{core.normalizedIdentity(message.get('author', message.get('nickname', fallbackAuthor or 'chat')))}"

def participantMuted(state, settings, key):
    return (key in (state.get("streamMutes", []))) or (key in (settings.get("permanentMutes", [])))

def cleanSpeechPayload(value):
    text = str(value or "")
    # Normalize and clean text
    text = text.encode('utf-8').decode('utf-8')
    # Remove control characters
    text = re.sub(r'[\x00-\x1f\x7f-\x9f]', ' ', text)
    # Remove zero-width characters
    text = re.sub(r'[\u200b-\u200f\u202a-\u202e\u2060-\u206f\ufeff]', '', text)
    # Remove variation selectors
    text = re.sub(r'[\ufe00-\ufe0f\u200d]', '', text)
    # Replace emoji with space
    text = re.sub(r'[\U0001f000-\U0001faff\U00002600-\U000027bf]', ' ', text)
    # Normalize whitespace
    text = re.sub(r'\s+', ' ', text)
    return text.strip()

def speechLanguage(settings, item, text):
    if settings.get("speechLanguage") == "auto" and re.search(r'[äöüÄÖÜß]', text):
        return "de-DE"
    return core.resolveSpeechLanguage(settings.get("speechLanguage"), item.get("contentLanguage"))

async def ensureOffscreenDocument():
    global offscreen_creation
    # This is a simplified version - in reality this would create an offscreen document
    if not offscreen_creation:
        offscreen_creation = asyncio.Future()
        offscreen_creation.set_result(True)
    await offscreen_creation

async def sendOffscreen(message):
    await ensureOffscreenDocument()
    # In a real implementation, this would send a message to the offscreen document
    pass

async def queueSpeechForTab(tabId, state, item):
    if not state.get("speech", {}).get("enabled") or item.get("muted"):
        return
    settings = await getSettings()
    if settings.get("gameModeEnabled") and core.shouldFilterGameModeSpeech(item, state.get("participants", {}), state.get("chatMessages", [])):
        return
    text = cleanSpeechPayload(core.composeSpeechText(item, {
        "teamTag": state.get("stream", {}).get("teamTag", ""),
        "speakNames": settings.get("speakNames", True),
        "shortenNames": bool(settings.get("shortenNames"))
    }))
    if not text:
        return
    key = f"{core.spokenNickname(item.get('author', ''))}|{text}".lower().replace(r'\s+', ' ').strip()
    lastAt = datetime.fromisoformat(state.get("speech", {}).get("lastSpokenAtUtc", "1970-01-01T00:00:00+00:00").replace("Z", "+00:00")).timestamp() * 1000 if state.get("speech", {}).get("lastSpokenAtUtc") else 0
    if key and state.get("speech", {}).get("lastSpokenKey") == key and (time.time() * 1000 - lastAt) <= 20000:
        return
    state["speech"] = {
        **state.get("speech", {}),
        "status": "Vorlesen aktiv · Zeile vorgemerkt.",
        "lastSpokenKey": key,
        "lastSpokenAtUtc": datetime.now(timezone.utc).isoformat(),
        "queueDepth": min(5, (state.get("speech", {}).get("queueDepth", 0) + 1))
    }
    await setState(tabId, state)
    await sendOffscreen({
        "type": "TLC_OFFSCREEN_SPEAK",
        "tabId": tabId,
        "text": text,
        "language": speechLanguage(settings, item, text),
        "voiceName": settings.get("speechVoiceName", ""),
        "volume": max(0, min(1, float(settings.get("speechVolume", 0.5)))),
        "serviceUrl": loopbackServiceUrl(settings.get("serviceUrl")) or "http://127.0.0.1:43117",
        "pairingCode": settings.get("pairingCode", "")
    })

def participantAliases(participant, fallbackKey=""):
    aliases = {fallbackKey}
    if participant.get("userId"):
        aliases.add(f"id:{participant['userId']}")
    if participant.get("displayId"):
        aliases.add(f"handle:{core.normalizedIdentity(participant['displayId'])}")
    if participant.get("name"):
        aliases.add(f"name:{core.normalizedIdentity(participant['name'])}")
    aliases.discard("")
    return list(aliases)

def relayTargetTabId(state):
    targetTabId = int(state.get("chatTargetTabId", -1))
    return targetTabId if isinstance(targetTabId, int) and targetTabId >= 0 else None

async def relayToEmbedTab(sourceTabId, state, msg_type, payload):
    targetTabId = relayTargetTabId(state)
    if targetTabId is None or payload.get("relayedFromTabId") == sourceTabId:
        return
    # In a real implementation, we would check if target tab exists and has correct URL
    relayPayload = {**payload, "relayedFromTabId": sourceTabId}
    if msg_type == "chat":
        await addChatMessage(targetTabId, relayPayload)
    elif msg_type == "gift":
        await addGiftMessage(targetTabId, relayPayload)
    elif msg_type == "live":
        await addLiveEvent(targetTabId, relayPayload)

def updateParticipant(state, raw, author, patch=None):
    if patch is None:
        patch = {}
    requestedKey = participantKey(raw, author)
    matchedEntry = None
    for key, participant in state.get("participants", {}).items():
        if core.sameParticipant(participant, {**raw, "name": author}):
            matchedEntry = (key, participant)
            break
    key = requestedKey if requestedKey in state.get("participants", {}) else (matchedEntry[0] if matchedEntry else requestedKey)
    existing = state.get("participants", {}).get(key)
    if not existing and len(state.get("participants", {})) >= MAX_PARTICIPANTS:
        state["participantsTruncated"] = True
        return {"key": key, "participant": None}
    participant = {
        "key": key,
        **core.mergeParticipantRecord(existing, raw, author, patch)
    }
    if "participants" not in state:
        state["participants"] = {}
    state["participants"][key] = participant
    return {"key": key, "participant": participant}

def observeTeamTag(state, author, content):
    if state.get("stream", {}).get("teamTag"):
        return state["stream"]["teamTag"]
    result = core.accumulateTeamEvidence(
        state.get("stream", {}).get("teamEvidence", {}),
        author,
        content,
        [item["content"] for item in state.get("chatMessages", [])]
    )
    state["stream"]["teamEvidence"] = result["evidence"]
    if result["teamTag"]:
        state["stream"]["teamTag"] = result["teamTag"]
        state["chatMessages"] = [
            {
                **item,
                "author": core.stripTeamTag(item["author"], result["teamTag"]),
                "content": core.stripTeamTag(item["content"], result["teamTag"])
            }
            for item in state.get("chatMessages", [])
        ]
        for participant in state.get("participants", {}).values():
            participant["name"] = core.stripTeamTag(participant["name"], result["teamTag"])
    return state["stream"]["teamTag"]

def resetStreamData(state, identity):
    state["stream"] = {
        "key": f"{identity.get('handle', '')}|{identity.get('roomId', '')}",
        "handle": identity.get("handle", ""),
        "roomId": identity.get("roomId", ""),
        "teamTag": "",
        "teamEvidence": {}
    }
    state["chatMessages"] = []
    state["participants"] = {}
    state["participantsTruncated"] = False
    state["streamMutes"] = []
    state["recentGiftIds"] = []
    state["liveStats"] = emptyState()["liveStats"]

def applyStreamIdentity(state, identity=None):
    if identity is None:
        identity = {}
    handle = str(identity.get("handle", state.get("stream", {}).get("handle", ""))).lower()
    roomId = str
