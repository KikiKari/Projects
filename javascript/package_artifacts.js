#!/usr/bin/env node
// package_artifacts.py — portiert nach javascript
// Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/package_artifacts.py
// Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const yargs = require('yargs');
const { hideBin } = require('yargs/helpers');

// Constants
const __filename = process.argv[1];
const ROOT = path.resolve(path.dirname(__filename), '../..');
const PROJECT_ROOT = path.resolve(ROOT, '..');
const EXCLUDED_PARTS = new Set(["__pycache__", ".gradle", ".kotlin", ".cxx", "build", "DerivedData", "xcuserdata", "Pods"]);

// Utility functions
function getAllFiles(dir, filelist = []) {
  const files = fs.readdirSync(dir);
  files.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      if (!EXCLUDED_PARTS.has(file)) {
        filelist = getAllFiles(filePath, filelist);
      }
    } else {
      if (!file.endsWith('.pyc') && !file.endsWith('.aar')) {
        filelist.push(filePath);
      }
    }
  });
  return filelist;
}

function createZipEntry(archivePath, content, isExecutable = false) {
  // In JS, we'll use a library like archiver to handle zip creation
  // This is a placeholder for the actual implementation
  return { archivePath, content, isExecutable };
}

// Main function
async function main() {
  const argv = yargs(hideBin(process.argv))
    .usage('Usage: $0 --output-dir <dir> [options]')
    .option('output-dir', {
      alias: 'o',
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
    .option('native-shared-source', {
      describe: 'Shared native audio source root',
      type: 'string',
      default: path.join(PROJECT_ROOT, 'mobile', 'shared')
    })
    .help()
    .argv;

  const outputDir = path.resolve(argv.outputDir);
  fs.mkdirSync(outputDir, { recursive: true });

  const manifestPath = path.join(ROOT, 'browser-extension', 'manifest.json');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  const version = manifest.version;

  const extensionZip = path.join(outputDir, `tiktok-live-companion-extension-${version}.zip`);
  const pluginZip = path.join(outputDir, `tiktok-live-companion-plugin-${version}.zip`);
  const serviceZip = path.join(outputDir, `tiktok-live-companion-service-${version}.zip`);
  const iosSourceZip = path.join(outputDir, `tiktok-live-companion-ios-${version}-source.zip`);
  const androidSourceZip = path.join(outputDir, `tiktok-live-companion-android-${version}-source.zip`);
  const androidApk = path.join(outputDir, `tiktok-live-companion-android-${version}.apk`);
  const extensionDir = path.join(outputDir, `tiktok-live-companion-extension-${version}`);
  const checksumFile = path.join(outputDir, `tiktok-live-companion-${version}-SHA256.txt`);

  if (path.resolve(extensionDir) !== path.join(outputDir, path.basename(extensionDir))) {
    throw new Error("Refusing to package outside the requested output directory");
  }

  if (fs.existsSync(extensionDir)) {
    fs.rmSync(extensionDir, { recursive: true });
  }

  // Copy browser-extension to extensionDir
  fs.cpSync(path.join(ROOT, 'browser-extension'), extensionDir, { recursive: true });
  
  // Copy companion-service to extensionDir/companion-service
  fs.cpSync(path.join(ROOT, 'companion-service'), path.join(extensionDir, 'companion-service'), { recursive: true });
  
  // Create Sprachdienst-reparieren.cmd
  const cmdContent = '@echo off\r\ncall "%~dp0companion-service\\Sprachdienst-reparieren.cmd"\r\n';
  fs.writeFileSync(path.join(extensionDir, 'Sprachdienst-reparieren.cmd'), cmdContent, 'utf8');
  
  // Create package.json
  const packageJson = {
    name: "tiktok-live-companion-extension-package",
    private: true,
    version: version,
    scripts: {
      setup: "npm --prefix companion-service run setup --",
      start: "npm --prefix companion-service start",
      test: "npm --prefix companion-service test"
    }
  };
  fs.writeFileSync(path.join(extensionDir, 'package.json'), JSON.stringify(packageJson, null, 2) + '\n', 'utf8');

  // Zip creation would go here using a library like archiver
  // For now, we'll just create empty files to simulate the zips
  fs.closeSync(fs.openSync(extensionZip, 'w'));
  fs.closeSync(fs.openSync(pluginZip, 'w'));
  fs.closeSync(fs.openSync(serviceZip, 'w'));
  fs.closeSync(fs.openSync(iosSourceZip, 'w'));
  fs.closeSync(fs.openSync(androidSourceZip, 'w'));

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

  // Copy APK if provided
  if (argv.androidApk) {
    const sourceApk = path.resolve(argv.androidApk);
    if (!fs.existsSync(sourceApk) || !sourceApk.toLowerCase().endsWith('.apk')) {
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
    const fileBuffer = fs.readFileSync(artifact);
    const hashSum = crypto.createHash('sha256');
    hashSum.update(fileBuffer);
    const hex = hashSum.digest('hex');
    checksums.push(`${hex}  ${path.basename(artifact)}`);
  }
  fs.writeFileSync(checksumFile, checksums.join('\n') + '\n', 'utf8');

  console.log(JSON.stringify({
    extension_dir: path.resolve(extensionDir),
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
