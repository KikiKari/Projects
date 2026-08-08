#!/usr/bin/env node
// TelegramMonitorCompanion.ps1 — portiert nach javascript
// Quelle: powershell, Projects@Telegram-Monitor:TelegramMonitorCompanion.ps1
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

/*
    Telegram Monitor Companion — Starter

    Startet den lokalen Monitor im Hintergrund (kein Konsolenfenster), wartet,
    bis der Port wirklich antwortet, und oeffnet die Oberflaeche als eigenes
    Fenster ohne Adressleiste. Laeuft der Monitor schon, wird er nicht erneut
    gestartet — dann wird nur das Fenster geoeffnet.

    Aufruf:
      node TelegramMonitorCompanion.js              starten und oeffnen
      node TelegramMonitorCompanion.js --stop        beenden
      node TelegramMonitorCompanion.js --status      nachsehen, ob er laeuft
      node TelegramMonitorCompanion.js --port 9000   anderer Port
      node TelegramMonitorCompanion.js --console     mit sichtbarem Fenster (Fehlersuche)
*/

const fs = require('fs');
const path = require('path');
const { spawn, execSync } = require('child_process');
const http = require('http');
const os = require('os');

const argv = require('yargs')
  .option('port', {
    alias: 'p',
    type: 'number',
    default: 8765,
    describe: 'Portnummer'
  })
  .option('interval', {
    alias: 'i',
    type: 'number',
    default: 120,
    describe: 'Poll-Intervall in Sekunden'
  })
  .option('stop', {
    alias: 's',
    type: 'boolean',
    describe: 'Monitor beenden'
  })
  .option('status', {
    alias: 't',
    type: 'boolean',
    describe: 'Status abfragen'
  })
  .option('console', {
    alias: 'c',
    type: 'boolean',
    describe: 'Mit sichtbarem Konsolenfenster starten'
  })
  .option('no-browser', {
    alias: 'n',
    type: 'boolean',
    describe: 'Kein Browserfenster oeffnen'
  })
  .help()
  .argv;

const rootDir = __dirname;
const pidFile = path.join(rootDir, 'data', 'companion.pid');
const logFile = path.join(rootDir, 'data', 'companion.log');
const url = `http://127.0.0.1:${argv.port}`;

function writeStep(msg) {
  console.log(`  ${msg}`);
}

function testMonitor() {
  return new Promise((resolve) => {
    const req = http.get(`${url}/api/status`, { timeout: 2000 }, (res) => {
      resolve(res.statusCode === 200);
    });
    req.on('error', () => resolve(false));
    req.on('timeout', () => {
      req.destroy();
      resolve(false);
    });
  });
}

function getMonitorProcess() {
  if (!fs.existsSync(pidFile)) return null;
  try {
    const pid = parseInt(fs.readFileSync(pidFile, 'utf8').trim(), 10);
    if (isNaN(pid)) return null;
    process.kill(pid, 0); // prüft, ob Prozess existiert
    return { pid };
  } catch (e) {
    return null;
  }
}

// ---------------------------------------------------------------- beenden ---
if (argv.stop) {
  const proc = getMonitorProcess();
  if (proc) {
    try {
      process.kill(proc.pid, 'SIGTERM');
      writeStep(`Monitor beendet (PID ${proc.pid}).`);
    } catch (e) {
      writeStep(`Konnte Monitor nicht beenden (PID ${proc.pid}).`);
    }
  } else {
    writeStep('Es lief kein Monitor aus diesem Starter.');
  }
  if (fs.existsSync(pidFile)) fs.unlinkSync(pidFile);
  process.exit(0);
}

// ----------------------------------------------------------------- Status ---
if (argv.status) {
  testMonitor().then((running) => {
    if (running) {
      const proc = getMonitorProcess();
      writeStep(`Monitor laeuft auf ${url}${proc ? `  (PID ${proc.pid})` : ''}.`);
    } else {
      writeStep(`Auf ${url} antwortet nichts.`);
    }
  });
  return;
}

// ------------------------------------------------------------------ Start ---
console.log('');
console.log('  Telegram Monitor Companion');
console.log('  --------------------------');

// Python suchen
let exe = null;
let pre = [];
const candidates = [
  { e: 'py', a: ['-3'] },
  { e: 'python', a: [] },
  { e: 'python3', a: [] }
];

for (const c of candidates) {
  try {
    execSync(`${c.e} --version`, { stdio: 'ignore' });
    exe = c.e;
    pre = c.a;
    break;
  } catch (e) {
    // continue
  }
}

if (!exe) {
  console.log('');
  console.log('  Python wurde nicht gefunden.');
  console.log('  Herunterladen: https://www.python.org/downloads/');
  console.log('  Beim Installieren "Add python.exe to PATH" ankreuzen.');
  console.log('');
  process.exit(1);
}
writeStep(`Python: ${exe} ${pre.join(' ')}`);

testMonitor().then((running) => {
  if (running) {
    writeStep(`Monitor laeuft bereits auf ${url} — wird nicht erneut gestartet.`);
    openBrowser();
  } else {
    fs.mkdirSync(path.dirname(pidFile), { recursive: true });
    const args = [...pre, 'server.py', '--port', argv.port.toString(), '--poll-interval', argv.interval.toString(), '--no-browser'];

    let proc;
    if (argv.console) {
      proc = spawn(exe, args, { cwd: rootDir, stdio: 'inherit' });
    } else {
      const logStream = fs.createWriteStream(logFile, { flags: 'a' });
      const errStream = fs.createWriteStream(logFile + '.err', { flags: 'a' });
      proc = spawn(exe, args, {
        cwd: rootDir,
        stdio: ['ignore', logStream, errStream],
        detached: true
      });
    }

    fs.writeFileSync(pidFile, proc.pid.toString());
    writeStep(`Gestartet (PID ${proc.pid}), warte auf Antwort ...`);

    let ok = false;
    let attempts = 0;
    const maxAttempts = 40;

    const check = () => {
      attempts++;
      testMonitor().then((isUp) => {
        if (isUp) {
          ok = true;
          writeStep('Antwortet.');
          openBrowser();
        } else if (attempts >= maxAttempts) {
          console.log('');
          console.log('  Der Monitor hat nicht geantwortet.');
          if (fs.existsSync(logFile + '.err')) {
            console.log('  Letzte Zeilen der Fehlerausgabe:');
            const lines = fs.readFileSync(logFile + '.err', 'utf8').split('\n').slice(-15);
            lines.forEach(line => console.log(`    ${line}`));
          }
          console.log('');
          console.log('  Nochmal mit sichtbarem Fenster:  node TelegramMonitorCompanion.js --console');
          process.exit(1);
        } else {
          setTimeout(check, 500);
        }
      });
    };

    proc.on('exit', () => {
      if (!ok) {
        console.log('');
        console.log('  Der Monitor-Prozess ist unerwartet beendet worden.');
        process.exit(1);
      }
    });

    check();
  }
});

function openBrowser() {
  if (argv.noBrowser) {
    writeStep(`Bereit: ${url}`);
    return;
  }

  const edge = path.join(process.env['ProgramFiles(x86)'] || '', 'Microsoft', 'Edge', 'Application', 'msedge.exe');
  const chrome = path.join(process.env['ProgramFiles'] || '', 'Google', 'Chrome', 'Application', 'chrome.exe');

  if (fs.existsSync(edge)) {
    spawn(edge, [`--app=${url}`], { detached: true, stdio: 'ignore' });
    writeStep('Als eigenes Fenster geoeffnet (Edge).');
  } else if (fs.existsSync(chrome)) {
    spawn(chrome, [`--app=${url}`], { detached: true, stdio: 'ignore' });
    writeStep('Als eigenes Fenster geoeffnet (Chrome).');
  } else {
    const start = os.platform() === 'win32' ? 'start' :
                  os.platform() === 'darwin' ? 'open' : 'xdg-open';
    spawn(start, [url], { detached: true, stdio: 'ignore' });
    writeStep('Im Standardbrowser geoeffnet.');
  }

  console.log('');
  console.log(`  Laeuft im Hintergrund auf ${url}`);
  console.log('  Beenden:  node TelegramMonitorCompanion.js --stop');
  console.log('');
}
