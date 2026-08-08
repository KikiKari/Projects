#!/usr/bin/env node
// build_artifact.py — portiert nach javascript
// Quelle: python, Projects@Telegram-Monitor:build_artifact.py
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

/**
 * Baut aus web/artifact_template.html + data/latest.json die fertige
 * Uebersichtsseite telegram-monitor-uebersicht.html (eine Datei, offline nutzbar).
 *
 *   python cli.py scan --json > /tmp/scan.json     // optional: frische Daten
 *   node build_artifact.js
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ROOT = __dirname;
const TEMPLATE = path.join(ROOT, "web", "artifact_template.html");
const DATA = path.join(ROOT, "data", "latest.json");
const OUT = path.join(path.dirname(ROOT), "telegram-monitor-uebersicht.html");

function build(dataPath = DATA, outPath = OUT) {
    const tpl = fs.readFileSync(TEMPLATE, 'utf-8');
    const data = JSON.parse(fs.readFileSync(dataPath, 'utf-8'));
    const payload = JSON.stringify(data, null, 0).replace(/<\/([^a-z])/g, '<\\/$1');
    const html = tpl.replace("/*__DATA__*/{}", payload);
    fs.writeFileSync(outPath, html, 'utf-8');
    return outPath;
}

if (import.meta.url === `file://${process.argv[1]}`) {
    const path = build(process.argv[2]);
    console.log(`geschrieben: ${path} (${fs.statSync(path).size} Bytes)`);
}
