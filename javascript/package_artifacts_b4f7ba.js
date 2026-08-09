#!/usr/bin/env node
// package_artifacts.py — portiert nach javascript
// Quelle: python, Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import { createHash } from 'crypto';
import { createReadStream, createWriteStream } from 'fs';
import { mkdir, readdir, stat, readFile, writeFile, copyFile, rm, copyFileSync } from 'fs/promises';
import { join, relative, dirname, basename, extname } from 'path';
import { fileURLToPath } from 'url';
import { program } from 'commander';
import archiver from 'archiver';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const ROOT = join(__dirname, '..', '..');
const PROJECT_ROOT = join(ROOT, '..');
const EXCLUDED_PARTS = new Set(["__pycache__", ".gradle", ".kotlin", "build", "DerivedData", "xcuserdata"]);

function shouldExcludePath(path) {
    const parts = path.split(/[\/\\]/);
    return parts.some(part => EXCLUDED_PARTS.has(part)) ||
           ['.pyc', '.aar'].includes(extname(path).toLowerCase());
}

async function addTree(archive, source, prefix = "") {
    const files = await readdir(source, { recursive: true });
    const filePaths = files.map(file => join(source, file));
    
    for (const filePath of filePaths) {
        const fileStat = await stat(filePath);
        if (!fileStat.isFile()) continue;
        
        const relativePath = relative(source, filePath);
        if (shouldExcludePath(relativePath)) continue;
        
        const archivePath = prefix ? join(prefix, relativePath) : relativePath;
        archive.file(filePath, { name: archivePath.replace(/\\/g, '/') });
    }
}

program
    .description('Package TikTok LIVE Companion artifacts.')
    .option('--output-dir <path>', 'Output directory', './dist')
    .option('--android-apk <path>', 'Optional verified mockDebug or shazamDebug APK');

program.parse();
const options = program.opts();

async function main() {
    const outputDir = join(process.cwd(), options.outputDir);
    await mkdir(outputDir, { recursive: true });
    
    const manifestPath = join(ROOT, 'browser-extension', 'manifest.json');
    const manifestContent = await readFile(manifestPath, 'utf8');
    const manifest = JSON.parse(manifestContent);
    const version = manifest.version;
    
    const extensionZip = join(outputDir, `tiktok-live-companion-extension-${version}.zip`);
    const pluginZip = join(outputDir, `tiktok-live-companion-plugin-${version}.zip`);
    const serviceZip = join(outputDir, `tiktok-live-companion-service-${version}.zip`);
    const iosSourceZip = join(outputDir, `tiktok-live-companion-ios-${version}-source.zip`);
    const androidSourceZip = join(outputDir, `tiktok-live-companion-android-${version}-source.zip`);
    const androidApk = join(outputDir, `tiktok-live-companion-android-${version}.apk`);
    const extensionDir = join(outputDir, `tiktok-live-companion-extension-${version}`);
    const checksumFile = join(outputDir, `tiktok-live-companion-${version}-SHA256.txt`);
    
    if (join(extensionDir, '..') !== outputDir) {
        throw new Error('Refusing to package outside the requested output directory');
    }
    
    await rm(extensionDir, { recursive: true, force: true });
    
    // Copy browser-extension directory
    const copyDir = async (src, dest) => {
        const entries = await readdir(src, { withFileTypes: true });
        await mkdir(dest, { recursive: true });
        for (const entry of entries) {
            const srcPath = join(src, entry.name);
            const destPath = join(dest, entry.name);
            if (entry.isDirectory()) {
                await copyDir(srcPath, destPath);
            } else {
                await copyFile(srcPath, destPath);
            }
        }
    };
    
    await copyDir(join(ROOT, 'browser-extension'), extensionDir);
    
    // Create extension zip
    const extensionOutput = createWriteStream(extensionZip);
    const extensionArchive = archiver('zip', { zlib: { level: 9 } });
    extensionArchive.pipe(extensionOutput);
    await addTree(extensionArchive, join(ROOT, 'browser-extension'));
    await extensionArchive.finalize();
    
    // Create plugin zip
    const pluginOutput = createWriteStream(pluginZip);
    const pluginArchive = archiver('zip', { zlib: { level: 9 } });
    pluginArchive.pipe(pluginOutput);
    await addTree(pluginArchive, ROOT, 'tiktok-live-companion');
    await pluginArchive.finalize();
    
    // Create service zip
    const serviceOutput = createWriteStream(serviceZip);
    const serviceArchive = archiver('zip', { zlib: { level: 9 } });
    serviceArchive.pipe(serviceOutput);
    await addTree(serviceArchive, join(ROOT, 'companion-service'));
    await serviceArchive.finalize();
    
    // Create iOS source zip
    const iosOutput = createWriteStream(iosSourceZip);
    const iosArchive = archiver('zip', { zlib: { level: 9 } });
    iosArchive.pipe(iosOutput);
    await addTree(iosArchive, join(PROJECT_ROOT, 'mobile', 'ios'), 'TikTokLiveCompanion-iOS');
    await iosArchive.finalize();
    
    // Create Android source zip
    const androidOutput = createWriteStream(androidSourceZip);
    const androidArchive = archiver('zip', { zlib: { level: 9 } });
    androidArchive.pipe(androidOutput);
    await addTree(androidArchive, join(PROJECT_ROOT, 'mobile', 'android'), 'TikTokLiveCompanion-Android');
    await androidArchive.finalize();
    
    // Copy Android APK if provided
    if (options.androidApk) {
        const sourceApk = join(process.cwd(), options.androidApk);
        const sourceStat = await stat(sourceApk);
        if (!sourceStat.isFile() || extname(sourceApk).toLowerCase() !== '.apk') {
            throw new Error('--android-apk must point to an existing APK');
        }
        copyFileSync(sourceApk, androidApk);
    }
    
    // Calculate checksums
    const artifacts = [extensionZip, pluginZip, serviceZip, iosSourceZip, androidSourceZip];
    if (await stat(androidApk).then(s => s.isFile()).catch(() => false)) {
        artifacts.push(androidApk);
    }
    
    const checksums = [];
    for (const artifact of artifacts) {
        const hash = createHash('sha256');
        const stream = createReadStream(artifact);
        await new Promise((resolve, reject) => {
            stream.on('data', chunk => hash.update(chunk));
            stream.on('end', () => {
                checksums.push(`${hash.digest('hex')}  ${basename(artifact)}`);
                resolve();
            });
            stream.on('error', reject);
        });
    }
    
    await writeFile(checksumFile, checksums.join('\n') + '\n', 'utf8');
    
    console.log(JSON.stringify({
        extension_dir: extensionDir,
        extension_zip: extensionZip,
        plugin_zip: pluginZip,
        service_zip: serviceZip,
        ios_source_zip: iosSourceZip,
        android_source_zip: androidSourceZip,
        android_apk: await stat(androidApk).then(s => s.isFile()).catch(() => false) ? androidApk : null,
        checksum_file: checksumFile,
        version: version
    }, null, 2));
}

main().catch(err => {
    console.error(err);
    process.exit(1);
});
