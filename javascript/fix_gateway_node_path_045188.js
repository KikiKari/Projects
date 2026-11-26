#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "f68894cc337493b3cafcc1adcfa2765155e2705c92616702ea0e3a9d21d0a8fd", "source_sha256": "04518825207cd6ef771c2d840daf0a025f3144f4e384f1d13b46e016570f59df", "target_language": "javascript"}
// fix_gateway_node_path.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
// auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import { execSync } from 'child_process';
import { copyFileSync } from 'fs';
import { join } from 'path';

// Backup der originalen Service-Datei
const timestamp = new Date().toISOString().replace(/[:T]/g, '-').slice(0, 19).replace(/-/g, '');
const backupPath = `/etc/systemd/system/openclaw-gateway.service.backup-${timestamp}`;
copyFileSync('/etc/systemd/system/openclaw-gateway.service', backupPath);

// Korrektur des Node.js Pfads in der Service-Datei
// Annahme: Node.js ist unter /usr/bin/node verfügbar (wie von 'which node' gezeigt)
try {
  execSync('sed -i "s|/home/openclaw/.nvm/versions/node/v22.22.2/bin/node|/usr/bin/node|g" /etc/systemd/system/openclaw-gateway.service');
} catch (error) {
  console.error('Fehler beim Aktualisieren der Service-Datei:', error.message);
  process.exit(1);
}

// Service neu laden und neu starten
try {
  execSync('systemctl daemon-reload');
  execSync('systemctl restart openclaw-gateway');
} catch (error) {
  console.error('Fehler beim Neustarten des Services:', error.message);
  process.exit(1);
}

// Status prüfen
try {
  const statusOutput = execSync('systemctl status openclaw-gateway --no-pager', { encoding: 'utf8' });
  console.log(statusOutput);
} catch (error) {
  console.error('Fehler beim Abfragen des Service-Status:', error.message);
  process.exit(1);
}
