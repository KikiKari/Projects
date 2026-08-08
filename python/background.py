#!/usr/bin/env python3
# background.js — portiert nach python
# Quelle: javascript, Projects@Telegram-Monitor:plugin/extension/background.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

"""
Hintergrunddienst: prüft im Turnus und meldet den Livegang.
Läuft ohne offenen Tab — der Browser weckt den Dienst über einen Alarm.
"""

import asyncio
import json
import logging
import time
from datetime import datetime, timezone
import aiohttp
from aiohttp import web

# Globale Konstanten
ALARM = 'ttc-check'
API_BASE = 'http://127.0.0.1:8765'
STORAGE_FILE = 'settings.json'

# Logging konfigurieren
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TikTokCompanion:
    def __init__(self, api_base=API_BASE):
        self.api_base = api_base
        self.user = ""
        self.session = None

    async def init_session(self):
        if not self.session:
            self.session = aiohttp.ClientSession()

    async def close_session(self):
        if self.session:
            await self.session.close()
            self.session = None

    async def refresh(self):
        if not self.user:
            return None
        await self.init_session()
        try:
            url = f"{self.api_base}/user/{self.user}/live"
            async with self.session.get(url) as response:
                if response.status == 200:
                    data = await response.json()
                    return data
                else:
                    logger.error(f"API error: {response.status}")
                    return None
        except Exception as e:
            logger.error(f"Error fetching live status: {e}")
            return None

def load_settings():
    try:
        with open(STORAGE_FILE, 'r') as f:
            s = json.load(f)
    except FileNotFoundError:
        s = {}

    return {
        'user': s.get('user', ''),
        'minutes': int(s.get('minutes', 2)),
        'notify': s.get('notify', True),
        'lastLive': bool(s.get('lastLive', False)),
        'lastState': s.get('lastState', {})
    }

def save_settings(settings_dict):
    with open(STORAGE_FILE, 'w') as f:
        json.dump(settings_dict, f)

async def schedule(companion_instance, minutes):
    # In einer echten Erweiterung würde hier ein Alarm geplant werden
    # Da wir in Python sind, simulieren wir das mit asyncio
    pass

async def check(companion_instance, settings_dict):
    user = settings_dict.get('user')
    notify = settings_dict.get('notify')
    last_live = settings_dict.get('lastLive')

    if not user:
        return

    companion_instance.user = user
    st = await companion_instance.refresh()

    if not st or 'live' not in st:
        return

    is_live = st['live'] is True
    settings_dict['lastLive'] = is_live
    settings_dict['lastState'] = st
    save_settings(settings_dict)

    # Badge-Anzeige (nur simuliert)
    badge_text = 'LIVE' if is_live else ''
    badge_color = '#fe2c55'
    logger.info(f"Badge text: {badge_text}, color: {badge_color}")

    if is_live and not last_live and notify:
        title = f"@{user} ist live"
        message = st.get('title', 'Die Sendung läuft.')
        logger.info(f"Notification: {title} - {message}")

async def main_loop():
    companion = TikTokCompanion()
    while True:
        settings_dict = load_settings()
        minutes = settings_dict.get('minutes', 2)
        if minutes <= 0:
            minutes = 2  # Standardwert

        await check(companion, settings_dict)
        await asyncio.sleep(minutes * 60)  # Warte die eingestellte Zeit

if __name__ == '__main__':
    print("TikTok Companion Background Service started")
    try:
        asyncio.run(main_loop())
    except KeyboardInterrupt:
        print("Service stopped")
