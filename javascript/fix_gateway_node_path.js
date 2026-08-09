#!/usr/bin/env node
// fix_gateway_node_path.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
// auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import { execSync } from 'child_process';
import { copyFileSync } from 'fs';
import { join } from 'path';

// Backup der originalen Service-Datei
const timestamp = new Date().toISOString().replace(/[:.]/g, '-').replace('T', '_').split('Z')[0];
const sourceFile = '/etc/systemd/system/openclaw-gateway.service';
const backupFile = `/etc/systemd/system/openclaw-gateway.service.backup-${timestamp}`;
copyFileSync(sourceFile, backupFile);

// Korrektur des Node.js Pfads in der Service-Datei
// Annahme: Node.js ist unter /usr/bin/node verfügbar (wie von 'which node' gezeigt)
const fs = await import('fs');
let serviceContent = fs.readFileSync(sourceFile, 'utf8');
serviceContent = serviceContent.replace(
  '/home/openclaw/.nvm/versions/node/v22.22.2/bin/node',
  '/usr/bin/node'
);
fs.writeFileSync(sourceFile, serviceContent);

// Service neu laden und neu starten
execSync('systemctl daemon-reload', { stdio: 'inherit' });
execSync('systemctl restart openclaw-gateway', { stdio: 'inherit' });

// Status prüfen
execSync('systemctl status openclaw-gateway --no-pager', { stdio: 'inherit' });
