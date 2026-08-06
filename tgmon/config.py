"""Konfiguration laden. Reihenfolge: config.json -> Umgebungsvariablen."""
from __future__ import annotations

import json
import os
from typing import Any

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_PATH = os.path.join(ROOT, "config.json")
DATA_DIR = os.path.join(ROOT, "data")

DEFAULT: dict[str, Any] = {
    "telegram": {"bot_token": "", "api_id": "", "api_hash": "", "session": "tgmon"},
    "discord": {"bot_token": "", "client_id": ""},
    "search": {"use_web_discovery": True, "limit": 20},
    "tiktok": {"accounts": []},
    "notify": {"webhook_url": "", "command": ""},
}


def _merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    out = dict(base)
    for k, v in override.items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = _merge(out[k], v)
        else:
            out[k] = v
    return out


def load(path: str | None = None) -> dict[str, Any]:
    cfg = json.loads(json.dumps(DEFAULT))
    p = path or CONFIG_PATH
    if os.path.exists(p):
        with open(p, "r", encoding="utf-8") as fh:
            cfg = _merge(cfg, json.load(fh))
    env_map = {
        ("telegram", "bot_token"): "TELEGRAM_BOT_TOKEN",
        ("telegram", "api_id"): "TELEGRAM_API_ID",
        ("telegram", "api_hash"): "TELEGRAM_API_HASH",
        ("discord", "bot_token"): "DISCORD_BOT_TOKEN",
        ("discord", "client_id"): "DISCORD_CLIENT_ID",
    }
    for (section, key), env in env_map.items():
        if os.environ.get(env):
            cfg[section][key] = os.environ[env]
    os.makedirs(DATA_DIR, exist_ok=True)
    return cfg
