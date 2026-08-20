#!/usr/bin/env node
// test_mobile_projects.py — portiert nach javascript
// Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const IOS = path.join(ROOT, 'mobile', 'ios');
const ANDROID = path.join(ROOT, 'mobile', 'android');
const SHARED = path.join(ROOT, 'plugin-source', 'mobile-shared', 'webview-bridge.js');

function requireCondition(condition, message) {
    if (!condition) {
        throw new Error(message);
    }
}

if (fs.existsSync(ANDROID)) {
    const manifest = fs.readFileSync(path.join(ANDROID, 'app', 'src', 'main', 'AndroidManifest.xml'), 'utf-8');
    const gradle = fs.readFileSync(path.join(ANDROID, 'app', 'build.gradle.kts'), 'utf-8');
    const androidWebview = fs.readFileSync(path.join(ANDROID, 'app', 'src', 'main', 'java', 'app', 'tiktoklivecompanion', 'CompanionWebView.kt'), 'utf-8');
    
    requireCondition(gradle.includes('minSdk = 21') && gradle.includes('versionName = "0.8.0"'), 'Android version contract');
    requireCondition(manifest.includes('usesCleartextTraffic="false"'), 'Android cleartext must be disabled');
    requireCondition(!androidWebview.includes('addJavascriptInterface'), 'insecure Android JavaScript interface');
    requireCondition(androidWebview.includes('addWebMessageListener') && androidWebview.includes('ALLOWED_ORIGIN'), 'origin-restricted Android bridge');
    
    const aarFiles = fs.readdirSync(path.join(ANDROID, 'app', 'libs')).filter(file => file.endsWith('.aar'));
    requireCondition(aarFiles.length === 0, 'ShazamKit AAR must not be committed');
    
    const sharedBytes = fs.readFileSync(SHARED);
    const androidBridgeBytes = fs.readFileSync(path.join(ANDROID, 'app', 'src', 'main', 'res', 'raw', 'webview_bridge.js'));
    requireCondition(sharedBytes.equals(androidBridgeBytes), 'Android bridge copy drift');
}

if (fs.existsSync(IOS)) {
    const iosWebview = fs.readFileSync(path.join(IOS, 'TikTokLiveCompanion', 'CompanionWebView.swift'), 'utf-8');
    const pbx = fs.readFileSync(path.join(IOS, 'TikTokLiveCompanion.xcodeproj', 'project.pbxproj'), 'utf-8');
    
    requireCondition(iosWebview.includes('forMainFrameOnly: false') && iosWebview.includes('securityOrigin.host == "www.tiktok.com"'), 'origin-restricted iOS subframe bridge');
    requireCondition(pbx.includes('MARKETING_VERSION = 0.8.0') && pbx.includes('IPHONEOS_DEPLOYMENT_TARGET = 15.0'), 'iOS version contract');
    
    const requiredNames = [
        'StreamNameNormalizer.swift in Sources',
        'StreamNameNormalizerTests.swift in Sources',
        'MobileUIStructureTests.swift in Sources'
    ];
    requireCondition(requiredNames.every(name => pbx.includes(name)), 'iOS source and XCTest membership');
    
    const sharedBytes = fs.readFileSync(SHARED);
    const iosBridgeBytes = fs.readFileSync(path.join(IOS, 'Resources', 'webview-bridge.js'));
    requireCondition(sharedBytes.equals(iosBridgeBytes), 'iOS bridge copy drift');
    
    const infoPlist = fs.readFileSync(path.join(IOS, 'TikTokLiveCompanion', 'Info.plist'), 'utf-8');
    const info = require('plist').parse(infoPlist);
    requireCondition(info.CFBundleShortVersionString === '0.8.0', 'iOS plist version');
}

const p8Files = [];
function findP8Files(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);
        if (stat.isDirectory()) {
            findP8Files(filePath);
        } else if (file.endsWith('.p8')) {
            p8Files.push(filePath);
        }
    }
}
findP8Files(ROOT);
requireCondition(p8Files.length === 0, 'Apple private key must not be committed');

const schema = JSON.parse(fs.readFileSync(path.join(ROOT, 'plugin-source', 'mobile-shared', 'recognition-result.schema.json'), 'utf-8'));
requireCondition(
    Array.isArray(schema.properties.source.enum) && 
    schema.properties.source.enum.includes('microphone') && 
    schema.properties.source.enum.includes('webview') &&
    schema.properties.source.enum.length === 2,
    'recognition source schema'
);

console.log('PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions');
