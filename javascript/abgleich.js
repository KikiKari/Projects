#!/usr/bin/env node
// abgleich.sh — portiert nach javascript
// Quelle: shell, Projects@abstractions:abstractions/abgleich.sh
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// Haelt den Abstraktions-Bestand im Container aktuell.
//
// Alle zwoelf Stunden wird der oeffentliche Branch Projects@abstractions nach
// /home/openclaw/.openclaw/workspace/git/Abstraktionen geholt. Das Repository
// ist oeffentlich, es wird kein Token gebraucht — der Container liest nur.
//
// Erzeugt wird hier nichts: das Portieren laeuft in GitHub Actions, weil dort
// der Schluessel liegt und der Lauf auch dann stattfindet, wenn dieser Rechner
// aus ist. Ein Lauf von Hand ist trotzdem moeglich:
//
//   docker exec -e OPENROUTER_API_KEY=... abstractions-manager \
//       python abstractions/ABSTRACTIONS_MANAGER.py --anzahl 5

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const WURZEL = process.env.ABSTRACTIONS_WORKSPACE || '/home/openclaw/.openclaw/workspace';
const ZIEL = path.join(WURZEL, 'git', 'Abstraktionen');
const HERKUNFT = 'https://github.com/KikiKari/Projects.git';
const BRANCH = 'abstractions';
const TAKT = parseInt(process.env.ABGLEICH_TAKT || '43200'); // zwoelf Stunden

function melde(...args) {
    const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
    console.log(`${timestamp} | abgleich | ${args.join(' ')}`);
}

function abgleichen() {
    if (!fs.existsSync(path.join(ZIEL, '.git'))) {
        melde("Erstabgleich nach", ZIEL);
        fs.mkdirSync(ZIEL, { recursive: true });
        execSync(`git init -q "${ZIEL}"`, { stdio: 'ignore' });
        execSync(`git -C "${ZIEL}" remote add herkunft "${HERKUNFT}"`, { stdio: 'ignore' });
    }
    
    try {
        execSync(`git -C "${ZIEL}" fetch -q --depth 1 herkunft "${BRANCH}"`, { stdio: ['pipe', 'pipe', 'ignore'] });
        execSync(`git -C "${ZIEL}" checkout -q -f -B "${BRANCH}" FETCH_HEAD`, { stdio: 'ignore' });
        
        const stand = execSync(`git -C "${ZIEL}" rev-parse --short HEAD`, { encoding: 'utf-8' }).trim();
        
        const files = execSync(`find "${ZIEL}" -type f \\( -name '*.js' -o -name '*.pl' -o -name '*.ps1' -o -name '*.py' -o -name '*.sh' -o -name '*.tcl' \\) -not -path '*/.git/*'`, { encoding: 'utf-8' });
        const anzahl = files.trim() ? files.trim().split('\n').length : 0;
        
        melde(`Stand ${stand}, ${anzahl} Erzeugnisse`);
    } catch (error) {
        melde("Abgleich fehlgeschlagen — vorheriger Stand bleibt bestehen");
    }
}

melde(`Start, Takt ${TAKT}s`);
setInterval(abgleichen, TAKT * 1000);
