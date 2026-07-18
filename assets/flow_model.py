"""Gemeinsames, deterministisches Architekturmodell für SVG, GIF und 3D-Dokumentation."""

PALETTE = {
    "source": ("#9b87f5", "#6d5bd0", "#3f348d"),
    "browser": ("#32d3df", "#12aebb", "#087783"),
    "ios": ("#ff7c9b", "#f04d75", "#a92750"),
    "android": ("#68d5a4", "#35aa78", "#1e6c4d"),
    "external": ("#ffc866", "#e99b24", "#925d10"),
}

# id, x, y, half-width, height, palette, label, sublabel, lane
STAGES = [
    ("tiktok", 0.0, 0.0, 0.72, 0.55, "source", "TikTok LIVE", "öffentliche Seite", "shared"),
    ("browser_hook", 2.4, -2.4, 0.72, 0.62, "browser", "Content + Hook", "passiv lesen", "browser"),
    ("browser_state", 4.9, -2.4, 0.72, 0.62, "browser", "Service Worker", "flüchtiger Zustand", "browser"),
    ("sidepanel", 7.4, -2.4, 0.72, 0.55, "browser", "Seitenpanel", "Text · TTS · Player", "browser"),
    ("local_service", 4.9, -4.7, 0.72, 0.62, "external", "Loopback-Dienst", "127.0.0.1", "browser"),
    ("audd", 7.4, -4.7, 0.72, 0.55, "external", "AudD", "nur nach Klick", "browser"),
    ("ios_bridge", 2.4, 0.0, 0.72, 0.62, "ios", "WKWebView Bridge", "Origin + Schema", "ios"),
    ("ios_native", 4.9, 0.0, 0.72, 0.62, "ios", "SwiftUI", "State · TTS", "ios"),
    ("ios_shazam", 7.4, 0.0, 0.72, 0.55, "ios", "ShazamKit", "Mikrofon / PCM", "ios"),
    ("android_bridge", 2.4, 2.4, 0.72, 0.62, "android", "AndroidX WebKit", "Origin + Schema", "android"),
    ("android_native", 4.9, 2.4, 0.72, 0.62, "android", "Compose", "DataStore · TTS", "android"),
    ("android_shazam", 7.4, 2.4, 0.72, 0.55, "android", "ShazamKit AAR", "Mikrofon / PCM", "android"),
    ("token", 4.9, 4.7, 0.72, 0.55, "external", "Token-Dienst", "kurzlebiges ES256", "android"),
]

# from, to, label, role: observation | audio | token
EDGES = [
    ("tiktok", "browser_hook", "DOM + WebSocket", "observation"),
    ("browser_hook", "browser_state", "bereinigt", "observation"),
    ("browser_state", "sidepanel", "max. 50 Chatzeilen", "observation"),
    ("browser_hook", "local_service", "ca. 12 s Tab-Audio", "audio"),
    ("local_service", "audd", "Datei-Erkennung", "audio"),
    ("tiktok", "ios_bridge", "öffentliche Ereignisse", "observation"),
    ("ios_bridge", "ios_native", "Bridge v1", "observation"),
    ("ios_native", "ios_shazam", "nur Nutzeraktion", "audio"),
    ("tiktok", "android_bridge", "öffentliche Ereignisse", "observation"),
    ("android_bridge", "android_native", "Bridge v1", "observation"),
    ("android_native", "android_shazam", "nur Nutzeraktion", "audio"),
    ("token", "android_shazam", "Developer Token", "token"),
]

EDGE_COLORS = {"observation": "#25c5d2", "audio": "#ff557a", "token": "#e9a12d"}
LANE_LABELS = {"browser": "Browser · AudD", "ios": "iOS · ShazamKit", "android": "Android / HyperOS · ShazamKit"}
