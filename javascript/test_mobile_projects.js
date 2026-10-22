#!/usr/bin/env node
// test_mobile_projects.py — portiert nach javascript
// Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_mobile_projects.py
// Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ROOT = path.resolve(__dirname, '..', '..');
const IOS = path.join(ROOT, 'mobile', 'ios');
const ANDROID = path.join(ROOT, 'mobile', 'android');
const SHARED = path.join(ROOT, 'plugin-source', 'mobile-shared', 'webview-bridge.js');

function requireCondition(condition, message) {
    if (!condition) {
        throw new Error(message);
    }
}

function readFileSync(filePath) {
    return fs.readFileSync(filePath, 'utf-8');
}

function readBinaryFileSync(filePath) {
    return fs.readFileSync(filePath);
}

function existsSync(dirPath) {
    return fs.existsSync(dirPath);
}

function globSync(pattern, options = {}) {
    const { cwd = '.', recursive = true } = options;
    const results = [];
    function walk(currentDir) {
        const entries = fs.readdirSync(currentDir, { withFileTypes: true });
        for (const entry of entries) {
            const fullPath = path.join(currentDir, entry.name);
            const relativePath = path.relative(cwd, fullPath);
            if (entry.isDirectory()) {
                if (recursive) walk(fullPath);
            } else {
                if (pattern === '*.aar' && entry.name.endsWith('.aar')) {
                    results.push(fullPath);
                } else if (pattern === '*.p8' && entry.name.endsWith('.p8')) {
                    results.push(fullPath);
                }
            }
        }
    }
    walk(cwd);
    return results;
}

function loadPlist(filePath) {
    // In a real scenario, you would use a plist parser like 'plist' package
    // For simplicity here, we'll just read the file and parse basic key-value manually
    const content = readFileSync(filePath);
    const plist = {};
    const versionMatch = content.match(/<key>CFBundleShortVersionString<\/key>\s*<string>(.*?)<\/string>/);
    if (versionMatch) {
        plist.CFBundleShortVersionString = versionMatch[1];
    }
    return plist;
}

if (existsSync(ANDROID)) {
    const manifestPath = path.join(ANDROID, 'app', 'src', 'main', 'AndroidManifest.xml');
    const gradlePath = path.join(ANDROID, 'app', 'build.gradle.kts');
    const androidWebviewPath = path.join(ANDROID, 'app', 'src', 'main', 'java', 'app', 'tiktoklivecompanion', 'CompanionWebView.kt');
    
    const manifest = readFileSync(manifestPath);
    const gradle = readFileSync(gradlePath);
    const android_webview = readFileSync(androidWebviewPath);
    
    requireCondition(gradle.includes('minSdk = 21') && gradle.includes('versionName = "0.8.2"'), "Android version contract");
    requireCondition(manifest.includes('usesCleartextTraffic="false"'), "Android cleartext must be disabled");
    requireCondition(!android_webview.includes("addJavascriptInterface"), "insecure Android JavaScript interface");
    requireCondition(android_webview.includes("addWebMessageListener") && android_webview.includes("ALLOWED_ORIGIN"), "origin-restricted Android bridge");
    
    const aarFiles = globSync('*.aar', { cwd: path.join(ANDROID, 'app', 'libs') });
    requireCondition(aarFiles.length === 0, "ShazamKit AAR must not be committed");
    
    const sharedBytes = readBinaryFileSync(SHARED);
    const androidBridgeBytes = readBinaryFileSync(path.join(ANDROID, 'app', 'src', 'main', 'res', 'raw', 'webview_bridge.js'));
    requireCondition(sharedBytes.equals(androidBridgeBytes), "Android bridge copy drift");
}

if (existsSync(IOS)) {
    const iosWebviewPath = path.join(IOS, 'TikTokLiveCompanion', 'CompanionWebView.swift');
    const pbxPath = path.join(IOS, 'TikTokLiveCompanion.xcodeproj', 'project.pbxproj');
    
    const ios_webview = readFileSync(iosWebviewPath);
    const pbx = readFileSync(pbxPath);
    
    requireCondition(
        ios_webview.includes("forMainFrameOnly: false") && 
        ios_webview.includes('securityOrigin.host == "www.tiktok.com"'),
        "origin-restricted iOS subframe bridge"
    );
    
    requireCondition(
        pbx.includes("MARKETING_VERSION = 0.8.2") && 
        pbx.includes("IPHONEOS_DEPLOYMENT_TARGET = 15.0"),
        "iOS version contract"
    );
    
    const requiredNames = [
        "StreamNameNormalizer.swift in Sources",
        "StreamNameNormalizerTests.swift in Sources", 
        "MobileUIStructureTests.swift in Sources"
    ];
    requireCondition(
        requiredNames.every(name => pbx.includes(name)),
        "iOS source and XCTest membership"
    );
    
    const sharedBytes = readBinaryFileSync(SHARED);
    const iosBridgeBytes = readBinaryFileSync(path.join(IOS, 'Resources', 'webview-bridge.js'));
    requireCondition(sharedBytes.equals(iosBridgeBytes), "iOS bridge copy drift");
    
    const infoPlistPath = path.join(IOS, 'TikTokLiveCompanion', 'Info.plist');
    const info = loadPlist(infoPlistPath);
    requireCondition(info.CFBundleShortVersionString === "0.8.2", "iOS plist version");
}

const p8Files = globSync('*.p8', { cwd: ROOT, recursive: true });
requireCondition(p8Files.length === 0, "Apple private key must not be committed");

const schemaPath = path.join(ROOT, 'plugin-source', 'mobile-shared', 'recognition-result.schema.json');
const schemaContent = readFileSync(schemaPath);
const schema = JSON.parse(schemaContent);
requireCondition(
    Array.isArray(schema.properties.source.enum) &&
    schema.properties.source.enum.includes("microphone") &&
    schema.properties.source.enum.includes("webview") &&
    schema.properties.source.enum.length === 2,
    "recognition source schema"
);

console.log("PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions");
