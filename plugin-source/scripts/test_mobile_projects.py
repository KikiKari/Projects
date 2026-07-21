import json
import plistlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
IOS = ROOT / "mobile" / "ios"
ANDROID = ROOT / "mobile" / "android"
SHARED = ROOT / "plugin-source" / "mobile-shared" / "webview-bridge.js"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


if ANDROID.exists():
    manifest = (ANDROID / "app" / "src" / "main" / "AndroidManifest.xml").read_text(encoding="utf-8")
    gradle = (ANDROID / "app" / "build.gradle.kts").read_text(encoding="utf-8")
    android_webview = (ANDROID / "app" / "src" / "main" / "java" / "app" / "tiktoklivecompanion" / "CompanionWebView.kt").read_text(encoding="utf-8")
    require('minSdk = 21' in gradle and 'versionName = "0.7.0"' in gradle, "Android version contract")
    require('usesCleartextTraffic="false"' in manifest, "Android cleartext must be disabled")
    require("addJavascriptInterface" not in android_webview, "insecure Android JavaScript interface")
    require("addWebMessageListener" in android_webview and "ALLOWED_ORIGIN" in android_webview, "origin-restricted Android bridge")
    require(not list((ANDROID / "app" / "libs").glob("*.aar")), "ShazamKit AAR must not be committed")
    require(SHARED.read_bytes() == (ANDROID / "app" / "src" / "main" / "res" / "raw" / "webview_bridge.js").read_bytes(), "Android bridge copy drift")

if IOS.exists():
    ios_webview = (IOS / "TikTokLiveCompanion" / "CompanionWebView.swift").read_text(encoding="utf-8")
    pbx = (IOS / "TikTokLiveCompanion.xcodeproj" / "project.pbxproj").read_text(encoding="utf-8")
    require("forMainFrameOnly: false" in ios_webview and "securityOrigin.host == \"www.tiktok.com\"" in ios_webview, "origin-restricted iOS subframe bridge")
    require("MARKETING_VERSION = 0.7.0" in pbx and "IPHONEOS_DEPLOYMENT_TARGET = 15.0" in pbx, "iOS version contract")
    require(all(name in pbx for name in ["StreamNameNormalizer.swift in Sources", "StreamNameNormalizerTests.swift in Sources", "MobileUIStructureTests.swift in Sources"]), "iOS source and XCTest membership")
    require(SHARED.read_bytes() == (IOS / "Resources" / "webview-bridge.js").read_bytes(), "iOS bridge copy drift")
    with (IOS / "TikTokLiveCompanion" / "Info.plist").open("rb") as handle:
        info = plistlib.load(handle)
    require(info["CFBundleShortVersionString"] == "0.7.0", "iOS plist version")

require(not list(ROOT.rglob("*.p8")), "Apple private key must not be committed")

schema = json.loads((ROOT / "plugin-source" / "mobile-shared" / "recognition-result.schema.json").read_text(encoding="utf-8"))
require(schema["properties"]["source"]["enum"] == ["microphone", "webview"], "recognition source schema")
print("PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions")
