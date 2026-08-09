#!/usr/bin/env node
// package_artifacts.py — portiert nach javascript
// Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import { createHash } from 'node:crypto';
import { createReadStream, createWriteStream } from 'node:fs';
import { mkdir, readdir, readFile, stat, writeFile, rm, copyFile } from 'node:fs/promises';
import { join, relative, dirname, basename, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createInterface } from 'node:readline';
import { constants } from 'node:zlib';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import archiver from 'archiver';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const ROOT = join(__dirname, '..', '..');
const PROJECT_ROOT = join(ROOT, '..');
const EXCLUDED_PARTS = new Set(['__pycache__', '.gradle', '.kotlin', 'build', 'DerivedData', 'xcuserdata']);

function shouldExcludePath(pathParts, ext) {
    return EXCLUDED_PARTS.has(pathParts[0]) || 
           EXCLUDED_PARTS.has(pathParts[pathParts.length - 1]) ||
           ext === '.pyc' || ext === '.aar';
}

async function addTree(archive, source, prefix = '') {
    const files = await getAllFiles(source);
    
    for (const file of files) {
        const relativePath = relative(source, file);
        const pathParts = relativePath.split(/[\/\\]/);
        const ext = extname(file).toLowerCase();
        
        if (shouldExcludePath(pathParts, ext)) {
            continue;
        }
        
        const archivePath = prefix ? join(prefix, relativePath).replace(/\\/g, '/') : relativePath.replace(/\\/g, '/');
        const data = await readFile(file);
        
        archive.append(data, {
            name: archivePath,
            date: new Date('1980-01-01T00:00:00Z')
        });
    }
}

async function getAllFiles(dir) {
    const dirents = await readdir(dir, { withFileTypes: true });
    const files = await Promise.all(dirents.map(async (dirent) => {
        const res = join(dir, dirent.name);
        return dirent.isDirectory() ? getAllFiles(res) : res;
    }));
    return files.flat().filter(file => !EXCLUDED_PARTS.has(basename(file)));
}

async function fileExists(path) {
    try {
        const stats = await stat(path);
        return stats.isFile();
    } catch {
        return false;
    }
}

async function dirExists(path) {
    try {
        const stats = await stat(path);
        return stats.isDirectory();
    } catch {
        return false;
    }
}

async function copyDir(src, dest) {
    await mkdir(dest, { recursive: true });
    const entries = await readdir(src, { withFileTypes: true });
    
    for (const entry of entries) {
        const srcPath = join(src, entry.name);
        const destPath = join(dest, entry.name);
        
        if (entry.isDirectory()) {
            await copyDir(srcPath, destPath);
        } else {
            await copyFile(srcPath, destPath);
        }
    }
}

async function createZip(outputPath, callback) {
    const output = createWriteStream(outputPath);
    const archive = archiver('zip', {
        zlib: { level: 9 }
    });
    
    archive.pipe(output);
    
    await callback(archive);
    
    archive.finalize();
    
    return new Promise((resolve, reject) => {
        output.on('close', resolve);
        output.on('error', reject);
    });
}

async function calculateSHA256(filePath) {
    const hash = createHash('sha256');
    const stream = createReadStream(filePath);
    
    return new Promise((resolve, reject) => {
        stream.on('data', (data) => hash.update(data));
        stream.on('end', () => resolve(hash.digest('hex')));
        stream.on('error', reject);
    });
}

const argv = yargs(hideBin(process.argv))
    .description('Package TikTok LIVE Companion artifacts.')
    .option('output-dir', {
        alias: 'o',
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
        default: join(PROJECT_ROOT, 'mobile', 'android'),
        describe: 'Verified Android source root'
    })
    .option('ios-source', {
        type: 'string',
        default: join(PROJECT_ROOT, 'mobile', 'ios'),
        describe: 'Verified iOS source root'
    })
    .coerce('output-dir', (arg) => arg)
    .coerce('android-apk', (arg) => arg)
    .coerce('android-source', (arg) => arg)
    .coerce('ios-source', (arg) => arg)
    .help()
    .argv;

(async () => {
    const outputDir = argv['output-dir'];
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
    
    if (dirname(extensionDir) !== outputDir) {
        throw new Error('Refusing to package outside the requested output directory');
    }
    
    const extensionDirExists = await dirExists(extensionDir);
    if (extensionDirExists) {
        await rm(extensionDir, { recursive: true });
    }
    
    await copyDir(join(ROOT, 'browser-extension'), extensionDir);
    await copyDir(join(ROOT, 'companion-service'), join(extensionDir, 'companion-service'));
    
    const packageJson = {
        name: 'tiktok-live-companion-extension-package',
        private: true,
        version: version,
        scripts: {
            setup: 'npm --prefix companion-service run setup --',
            start: 'npm --prefix companion-service start',
            test: 'npm --prefix companion-service test'
        }
    };
    
    await writeFile(
        join(extensionDir, 'package.json'),
        JSON.stringify(packageJson, null, 2) + '\n',
        'utf8'
    );
    
    await createZip(extensionZip, async (archive) => {
        await addTree(archive, extensionDir);
    });
    
    await createZip(pluginZip, async (archive) => {
        await addTree(archive, ROOT, 'tiktok-live-companion');
    });
    
    await createZip(serviceZip, async (archive) => {
        await addTree(archive, join(ROOT, 'companion-service'));
    });
    
    const iosSource = argv['ios-source'];
    const androidSource = argv['android-source'];
    
    if (!(await dirExists(iosSource)) || !(await dirExists(androidSource))) {
        throw new Error('--ios-source and --android-source must point to existing source directories');
    }
    
    await createZip(iosSourceZip, async (archive) => {
        await addTree(archive, iosSource, 'TikTokLiveCompanion-iOS');
    });
    
    await createZip(androidSourceZip, async (archive) => {
        await addTree(archive, androidSource, 'TikTokLiveCompanion-Android');
    });
    
    if (argv['android-apk']) {
        const sourceApk = argv['android-apk'];
        if (!(await fileExists(sourceApk)) || extname(sourceApk).toLowerCase() !== '.apk') {
            throw new Error('--android-apk must point to an existing APK');
        }
        await copyFile(sourceApk, androidApk);
    }
    
    const artifacts = [
        extensionZip,
        pluginZip,
        serviceZip,
        iosSourceZip,
        androidSourceZip
    ];
    
    if (await fileExists(androidApk)) {
        artifacts.push(androidApk);
    }
    
    const checksums = [];
    for (const artifact of artifacts) {
        const digest = await calculateSHA256(artifact);
        checksums.push(`${digest}  ${basename(artifact)}`);
    }
    
    await writeFile(checksumFile, checksums.join('\n') + '\n', 'utf8');
    
    const result = {
        extension_dir: extensionDir,
        extension_zip: extensionZip,
        plugin_zip: pluginZip,
        service_zip: serviceZip,
        ios_source_zip: iosSourceZip,
        android_source_zip: androidSourceZip,
        android_apk: (await fileExists(androidApk)) ? androidApk : null,
        checksum_file: checksumFile,
        version: version
    };
    
    console.log(JSON.stringify(result, null, 2));
})();
