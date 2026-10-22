#!/usr/bin/env node
// verify-downloads.py — portiert nach javascript
// Quelle: python, Projects@TikTok-Live-Companion:site/scripts/verify-downloads.py
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/scripts/verify-downloads.py
// Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

/** Verify the candidate's actual HTTP downloads against committed files. */
import fs from 'fs';
import crypto from 'crypto';
import https from 'https';
import http from 'http';
import { createRequire } from 'module';
import path from 'path';
import { fileURLToPath } from 'url';
import { createReadStream } from 'fs';
import { Readable } from 'stream';
import { pipeline } from 'stream/promises';
import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const root = path.resolve(__dirname, '../..');

const argv = yargs(hideBin(process.argv))
  .option('base-url', {
    describe: 'Base URL for downloads',
    demandOption: true,
    type: 'string'
  })
  .option('report', {
    describe: 'Report output file path',
    demandOption: true,
    type: 'string'
  })
  .argv;

async function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith('https') ? https : http;
    const req = lib.get(url, { timeout: 30000 }, (response) => {
      const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => resolve(Buffer.concat(chunks)));
      response.on('error', reject);
    });
    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
  });
}

function getZipEntries(zipBuffer) {
  const JSZip = createRequire(import.meta.url)('jszip');
  return JSZip.loadAsync(zipBuffer);
}

async function main() {
  const checksumPath = path.join(root, 'public/downloads/tiktok-live-companion-0.8.2-SHA256.txt');
  const checksumContent = fs.readFileSync(checksumPath, 'utf8');
  const lines = checksumContent.split('\n').filter(line => line.trim() !== '');
  
  const results = [];
  
  for (const line of lines) {
    const [expected, name] = line.split('  ');
    const url = argv.baseUrl.replace(/\/$/, '') + '/downloads/' + name;
    
    const data = await fetchUrl(url);
    const actual = crypto.createHash('sha256').update(data).digest('hex');
    
    const localFilePath = path.join(root, 'public/downloads', name);
    const localData = fs.readFileSync(localFilePath);
    
    if (actual !== expected || !data.equals(localData)) {
      throw new Error('HTTP artifact mismatch: ' + name);
    }
    
    const zip = await getZipEntries(data);
    
    // Test if archive is valid by trying to read all entries
    try {
      for (const [fileName] of Object.entries(zip.files)) {
        await zip.file(fileName).async('nodebuffer');
      }
    } catch (err) {
      throw new Error('Corrupt archive: ' + name);
    }
    
    if (name.includes('-extension-')) {
      const manifestContent = await zip.file('manifest.json').async('string');
      const manifest = JSON.parse(manifestContent);
      
      if (manifest.version !== '0.8.2') {
        throw new Error('Wrong extension version');
      }
      
      const sources = ['background.js', 'content.js', 'sidepanel.js', 'sidepanel.html'];
      for (const source of sources) {
        const sourceContent = await zip.file(source).async('nodebuffer');
        const expectedSourcePath = path.join(root, '../plugin-source/browser-extension', source);
        const expectedSourceContent = fs.readFileSync(expectedSourcePath);
        
        if (!sourceContent.equals(expectedSourceContent)) {
          throw new Error('Extension source mismatch: ' + source);
        }
      }
    }
    
    results.push({
      name: name,
      sha256: actual,
      bytes: data.length,
      verified: true
    });
  }
  
  const reportData = {
    base_url: argv.baseUrl,
    artifacts: results
  };
  
  fs.writeFileSync(argv.report, JSON.stringify(reportData, null, 2), 'utf8');
  console.log(JSON.stringify(results, null, 2));
}

main().catch(err => {
  console.error(err.message);
  process.exit(1);
});
