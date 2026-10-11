#!/usr/bin/env node
// test_mobile_projects.py — portiert nach javascript
// Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
// auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_mobile_projects.py
// Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

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
    const android_webview = fs.readFileSync(path.join(ANDROID, 'app', 'src', 'main', 'java', 'app', 'tiktoklivecompanion', 'CompanionWebView.kt'), 'utf-8');
    
    requireCondition(gradle.includes('minSdk = 21') && gradle.includes('versionName = "0.8.2"'), 'Android version contract');
    requireCondition(manifest.includes('usesCleartextTraffic="false"'), 'Android cleartext must be disabled');
    requireCondition(!android_webview.includes('addJavascriptInterface'), 'insecure Android JavaScript interface');
    requireCondition(android_webview.includes('addWebMessageListener') && android_webview.includes('ALLOWED_ORIGIN'), 'origin-restricted Android bridge');
    
    const aarFiles = fs.readdirSync(path.join(ANDROID, 'app', 'libs')).filter(file => file.endsWith('.aar'));
    requireCondition(aarFiles.length === 0, 'ShazamKit AAR must not be committed');
    
    const sharedBytes = fs.readFileSync(SHARED);
    const androidBridgeBytes = fs.readFileSync(path.join(ANDROID, 'app', 'src', 'main', 'res', 'raw', 'webview_bridge.js'));
    requireCondition(sharedBytes.equals(androidBridgeBytes), 'Android bridge copy drift');
}

if (fs.existsSync(IOS)) {
    const ios_webview = fs.readFileSync(path.join(IOS, 'TikTokLiveCompanion', 'CompanionWebView.swift'), 'utf-8');
    const pbx = fs.readFileSync(path.join(IOS, 'TikTokLiveCompanion.xcodeproj', 'project.pbxproj'), 'utf-8');
    
    requireCondition(ios_webview.includes('forMainFrameOnly: false') && ios_webview.includes('securityOrigin.host == "www.tiktok.com"'), 'origin-restricted iOS subframe bridge');
    requireCondition(pbx.includes('MARKETING_VERSION = 0.8.2') && pbx.includes('IPHONEOS_DEPLOYMENT_TARGET = 15.0'), 'iOS version contract');
    
    const requiredNames = [
        'StreamNameNormalizer.swift in Sources',
        'StreamNameNormalizerTests.swift in Sources', 
        'MobileUIStructureTests.swift in Sources'
    ];
    requireCondition(requiredNames.every(name => pbx.includes(name)), 'iOS source and XCTest membership');
    
    const sharedBytes = fs.readFileSync(SHARED);
    const iosBridgeBytes = fs.readFileSync(path.join(IOS, 'Resources', 'webview-bridge.js'));
    requireCondition(sharedBytes.equals(iosBridgeBytes), 'iOS bridge copy drift');
    
    const infoPlist = fs.readFileSync(path.join(IOS, 'TikTokLiveCompanion', 'Info.plist'));
    const info = parsePlist(infoPlist);
    requireCondition(info.CFBundleShortVersionString === '0.8.2', 'iOS plist version');
}

const p8Files = getAllFiles(ROOT).filter(file => file.endsWith('.p8'));
requireCondition(p8Files.length === 0, 'Apple private key must not be committed');

const schemaPath = path.join(ROOT, 'plugin-source', 'mobile-shared', 'recognition-result.schema.json');
const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf-8'));
requireCondition(
    JSON.stringify(schema.properties.source.enum) === JSON.stringify(['microphone', 'webview']),
    'recognition source schema'
);

console.log('PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions');

// Helper functions
function parsePlist(buffer) {
    // Simple plist parser for this specific use case
    const content = buffer.toString();
    const result = {};
    
    // Extract CFBundleShortVersionString
    const versionMatch = content.match(/<key>CFBundleShortVersionString<\/key>\s*<string>(.*?)<\/string>/);
    if (versionMatch) {
        result.CFBundleShortVersionString = versionMatch[1];
    }
    
    return result;
}

function getAllFiles(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    
    list.forEach(file => {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        
        if (stat && stat.isDirectory()) {
            results = results.concat(getAllFiles(file));
        } else {
            results.push(file);
        }
    });
    
    return results;
}
