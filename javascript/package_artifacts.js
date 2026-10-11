#!/usr/bin/env node
// package_artifacts.py — portiert nach javascript
// Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
// auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/package_artifacts.py
// Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const yargs = require('yargs');
const { hideBin } = require('yargs/helpers');
const archiver = require('archiver');

const ROOT = path.resolve(__dirname);
const PROJECT_ROOT = path.dirname(ROOT);
const EXCLUDED_PARTS = new Set(["__pycache__", ".gradle", ".kotlin", ".cxx", "build", "DerivedData", "xcuserdata", "Pods"]);

function addTree(archive, source, prefix = "") {
    const files = getAllFiles(source);
    files.sort();
    
    for (const filePath of files) {
        const relativePath = path.relative(source, filePath);
        const parts = relativePath.split(path.sep);
        
        if (EXCLUDED_PARTS.has(path.basename(filePath)) || 
            EXCLUDED_PARTS.has(path.dirname(filePath).split(path.sep)[0]) ||
            path.extname(filePath) === '.pyc' || 
            path.extname(filePath) === '.aar') {
            continue;
        }
        
        const archivePath = path.posix.join(prefix, relativePath);
        const stat = fs.statSync(filePath);
        const mode = path.basename(filePath) === 'gradlew' ? 0o100755 : 0o100644;
        
        archive.file(filePath, {
            name: archivePath,
            mode: mode,
            date: new Date('1980-01-01T00:00:00.000Z')
        });
    }
}

function getAllFiles(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    
    list.forEach(file => {
        file = path.resolve(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            results = results.concat(getAllFiles(file));
        } else {
            results.push(file);
        }
    });
    
    return results;
}

function copyDir(src, dest) {
    fs.mkdirSync(dest, { recursive: true });
    const entries = fs.readdirSync(src, { withFileTypes: true });
    
    for (const entry of entries) {
        const srcPath = path.join(src, entry.name);
        const destPath = path.join(dest, entry.name);
        
        if (entry.isDirectory()) {
            copyDir(srcPath, destPath);
        } else {
            fs.copyFileSync(srcPath, destPath);
        }
    }
}

function readJsonFile(filePath) {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function writeJsonFile(filePath, data) {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

function calculateSHA256(filePath) {
    const fileBuffer = fs.readFileSync(filePath);
    const hashSum = crypto.createHash('sha256');
    hashSum.update(fileBuffer);
    return hashSum.digest('hex');
}

const argv = yargs(hideBin(process.argv))
    .description('Package TikTok LIVE Companion artifacts.')
    .option('output-dir', {
        type: 'string',
        demandOption: true,
        describe: 'Output directory'
    })
    .option('android-apk', {
        type: 'string',
        describe: 'Optional verified mockDebug or shazamDebug APK'
    })
    .option('android-source', {
        type: 'string',
        default: path.join(PROJECT_ROOT, 'mobile', 'android'),
        describe: 'Verified Android source root'
    })
    .option('ios-source', {
        type: 'string',
        default: path.join(PROJECT_ROOT, 'mobile', 'ios'),
        describe: 'Verified iOS source root'
    })
    .option('native-shared-source', {
        type: 'string',
        default: path.join(PROJECT_ROOT, 'mobile', 'shared'),
        describe: 'Shared native audio source root'
    })
    .argv;

const outputDir = path.resolve(argv.outputDir);
fs.mkdirSync(outputDir, { recursive: true });

const manifest = readJsonFile(path.join(ROOT, 'browser-extension', 'manifest.json'));
const version = manifest.version;
const extensionZip = path.join(outputDir, `tiktok-live-companion-extension-${version}.zip`);
const pluginZip = path.join(outputDir, `tiktok-live-companion-plugin-${version}.zip`);
const serviceZip = path.join(outputDir, `tiktok-live-companion-service-${version}.zip`);
const iosSourceZip = path.join(outputDir, `tiktok-live-companion-ios-${version}-source.zip`);
const androidSourceZip = path.join(outputDir, `tiktok-live-companion-android-${version}-source.zip`);
const androidApk = path.join(outputDir, `tiktok-live-companion-android-${version}.apk`);
const extensionDir = path.join(outputDir, `tiktok-live-companion-extension-${version}`);
const checksumFile = path.join(outputDir, `tiktok-live-companion-${version}-SHA256.txt`);

const resolvedExtensionDir = path.resolve(extensionDir);
if (path.dirname(resolvedExtensionDir) !== outputDir) {
    throw new Error("Refusing to package outside the requested output directory");
}

if (fs.existsSync(extensionDir)) {
    fs.rmSync(extensionDir, { recursive: true });
}

copyDir(path.join(ROOT, 'browser-extension'), extensionDir);
copyDir(path.join(ROOT, 'companion-service'), path.join(extensionDir, 'companion-service'));

fs.writeFileSync(
    path.join(extensionDir, 'Sprachdienst-reparieren.cmd'),
    '@echo off\r\ncall "%~dp0companion-service\\Sprachdienst-reparieren.cmd"\r\n',
    'utf8'
);

writeJsonFile(path.join(extensionDir, 'package.json'), {
    name: 'tiktok-live-companion-extension-package',
    private: true,
    version: version,
    scripts: {
        setup: 'npm --prefix companion-service run setup --',
        start: 'npm --prefix companion-service start',
        test: 'npm --prefix companion-service test'
    }
});

// Create extension zip
const extensionArchive = archiver('zip', { zlib: { level: 9 } });
const extensionOutput = fs.createWriteStream(extensionZip);
extensionArchive.pipe(extensionOutput);
addTree(extensionArchive, extensionDir);
extensionArchive.finalize();

// Create plugin zip
const pluginArchive = archiver('zip', { zlib: { level: 9 } });
const pluginOutput = fs.createWriteStream(pluginZip);
pluginArchive.pipe(pluginOutput);
addTree(pluginArchive, ROOT, 'tiktok-live-companion');
pluginArchive.finalize();

// Create service zip
const serviceArchive = archiver('zip', { zlib: { level: 9 } });
const serviceOutput = fs.createWriteStream(serviceZip);
serviceArchive.pipe(serviceOutput);
addTree(serviceArchive, path.join(ROOT, 'companion-service'));
serviceArchive.finalize();

const iosSource = path.resolve(argv.iosSource);
const androidSource = path.resolve(argv.androidSource);

if (!fs.existsSync(iosSource) || !fs.statSync(iosSource).isDirectory() || 
    !fs.existsSync(androidSource) || !fs.statSync(androidSource).isDirectory()) {
    throw new Error("--ios-source and --android-source must point to existing source directories");
}

const nativeShared = path.resolve(argv.nativeSharedSource);
if (!fs.existsSync(path.join(nativeShared, 'native', 'tlc_peak_limiter.h'))) {
    throw new Error("Shared native limiter source is required for both mobile source packages");
}

// Create iOS source zip
const iosSourceArchive = archiver('zip', { zlib: { level: 9 } });
const iosSourceOutput = fs.createWriteStream(iosSourceZip);
iosSourceArchive.pipe(iosSourceOutput);
addTree(iosSourceArchive, iosSource, 'TikTokLiveCompanion-iOS');
addTree(iosSourceArchive, nativeShared, 'shared');
iosSourceArchive.finalize();

// Create Android source zip
const androidSourceArchive = archiver('zip', { zlib: { level: 9 } });
const androidSourceOutput = fs.createWriteStream(androidSourceZip);
androidSourceArchive.pipe(androidSourceOutput);
addTree(androidSourceArchive, androidSource, 'TikTokLiveCompanion-Android');
addTree(androidSourceArchive, nativeShared, 'shared');
androidSourceArchive.finalize();

if (argv.androidApk) {
    const sourceApk = path.resolve(argv.androidApk);
    if (!fs.existsSync(sourceApk) || path.extname(sourceApk).toLowerCase() !== '.apk') {
        throw new Error("--android-apk must point to an existing APK");
    }
    if (path.resolve(sourceApk) !== path.resolve(androidApk)) {
        fs.copyFileSync(sourceApk, androidApk);
    }
}

const artifacts = [extensionZip, pluginZip, serviceZip, iosSourceZip, androidSourceZip];
if (fs.existsSync(androidApk)) {
    artifacts.push(androidApk);
}

const checksums = [];
for (const artifact of artifacts) {
    const digest = calculateSHA256(artifact);
    checksums.push(`${digest}  ${path.basename(artifact)}`);
}
fs.writeFileSync(checksumFile, checksums.join('\n') + '\n', 'utf8');

console.log(JSON.stringify({
    extension_dir: extensionDir,
    extension_zip: extensionZip,
    plugin_zip: pluginZip,
    service_zip: serviceZip,
    ios_source_zip: iosSourceZip,
    android_source_zip: androidSourceZip,
    android_apk: fs.existsSync(androidApk) ? androidApk : null,
    checksum_file: checksumFile,
    version: version
}, null, 2));
