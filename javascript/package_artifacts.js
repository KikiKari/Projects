#!/usr/bin/env node
// package_artifacts.py — portiert nach javascript
// Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const yargs = require('yargs');
const archiver = require('archiver');

const ROOT = path.resolve(__dirname, '..');
const PROJECT_ROOT = path.resolve(ROOT, '..');
const EXCLUDED_PARTS = new Set(['__pycache__', '.gradle', '.kotlin', 'build', 'DerivedData', 'xcuserdata']);

function shouldExclude(filePath, sourceDir) {
    const relativePath = path.relative(sourceDir, filePath);
    const parts = relativePath.split(path.sep);
    
    // Check if any part is in excluded set
    if (parts.some(part => EXCLUDED_PARTS.has(part))) {
        return true;
    }
    
    // Check file extensions
    const ext = path.extname(filePath);
    if (ext === '.pyc' || ext === '.aar') {
        return true;
    }
    
    return false;
}

function addTree(archive, source, prefix = '') {
    const files = getAllFiles(source);
    
    files.sort(); // Sort for consistent ordering
    
    for (const filePath of files) {
        if (shouldExclude(filePath, source)) {
            continue;
        }
        
        const relative = path.relative(source, filePath);
        const archivePath = path.posix.join(prefix, relative.split(path.sep).join('/'));
        
        const stat = fs.statSync(filePath);
        const data = fs.readFileSync(filePath);
        
        archive.append(data, {
            name: archivePath,
            date: new Date('1980-01-01T00:00:00.000Z'),
            mode: 0o100644
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

function rimraf(dir) {
    if (!fs.existsSync(dir)) return;
    
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    
    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            rimraf(fullPath);
        } else {
            fs.unlinkSync(fullPath);
        }
    }
    
    fs.rmdirSync(dir);
}

function readJsonFile(filePath) {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function writeJsonFile(filePath, data) {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

async function createZip(outputPath, callback) {
    return new Promise((resolve, reject) => {
        const output = fs.createWriteStream(outputPath);
        const archive = archiver('zip', {
            zlib: { level: 9 }
        });
        
        output.on('close', () => resolve());
        archive.on('error', err => reject(err));
        
        archive.pipe(output);
        callback(archive);
        archive.finalize();
    });
}

async function main() {
    const argv = yargs
        .usage('Usage: $0 [options]')
        .option('output-dir', {
            describe: 'Output directory for packaged artifacts',
            type: 'string',
            demandOption: true
        })
        .option('android-apk', {
            describe: 'Optional verified mockDebug or shazamDebug APK',
            type: 'string'
        })
        .option('android-source', {
            describe: 'Verified Android source root',
            type: 'string',
            default: path.join(PROJECT_ROOT, 'mobile', 'android')
        })
        .option('ios-source', {
            describe: 'Verified iOS source root',
            type: 'string',
            default: path.join(PROJECT_ROOT, 'mobile', 'ios')
        })
        .help()
        .argv;

    const outputDir = path.resolve(argv['output-dir']);
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
        throw new Error('Refusing to package outside the requested output directory');
    }
    
    if (fs.existsSync(extensionDir)) {
        rimraf(extensionDir);
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

    await createZip(extensionZip, archive => {
        addTree(archive, extensionDir);
    });

    await createZip(pluginZip, archive => {
        addTree(archive, ROOT, 'tiktok-live-companion');
    });

    await createZip(serviceZip, archive => {
        addTree(archive, path.join(ROOT, 'companion-service'));
    });

    const iosSource = path.resolve(argv['ios-source']);
    const androidSource = path.resolve(argv['android-source']);
    
    if (!fs.existsSync(iosSource) || !fs.statSync(iosSource).isDirectory() ||
        !fs.existsSync(androidSource) || !fs.statSync(androidSource).isDirectory()) {
        throw new Error('--ios-source and --android-source must point to existing source directories');
    }

    await createZip(iosSourceZip, archive => {
        addTree(archive, iosSource, 'TikTokLiveCompanion-iOS');
    });

    await createZip(androidSourceZip, archive => {
        addTree(archive, androidSource, 'TikTokLiveCompanion-Android');
    });

    if (argv['android-apk']) {
        const sourceApk = path.resolve(argv['android-apk']);
        if (!fs.existsSync(sourceApk) || path.extname(sourceApk).toLowerCase() !== '.apk') {
            throw new Error('--android-apk must point to an existing APK');
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
        const data = fs.readFileSync(artifact);
        const hash = crypto.createHash('sha256').update(data).digest('hex');
        checksums.push(`${hash}  ${path.basename(artifact)}`);
    }
    
    fs.writeFileSync(checksumFile, checksums.join('\n') + '\n', 'utf8');

    console.log(JSON.stringify({
        extension_dir: resolvedExtensionDir,
        extension_zip: path.resolve(extensionZip),
        plugin_zip: path.resolve(pluginZip),
        service_zip: path.resolve(serviceZip),
        ios_source_zip: path.resolve(iosSourceZip),
        android_source_zip: path.resolve(androidSourceZip),
        android_apk: fs.existsSync(androidApk) ? path.resolve(androidApk) : null,
        checksum_file: path.resolve(checksumFile),
        version: version
    }, null, 2));
}

main().catch(err => {
    console.error(err);
    process.exit(1);
});
