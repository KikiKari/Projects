#!/usr/bin/env node
// openclaw-audit.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import { execSync } from 'child_process';
import { writeFileSync, appendFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const DATE_STAMP = new Date().toISOString().split('T')[0];
const OUT = join(__dirname, `openclaw-audit-${DATE_STAMP}.log`);

const OC = ['openclaw', '--no-color'];

const writeHeader = () => {
  const header = [
    "================================================================",
    "OpenClaw audit run",
    `Started:  ${new Date().toISOString()}`,
    `Host:     ${execSync('hostname', { encoding: 'utf8' }).trim()}`,
    `User:     ${execSync('whoami', { encoding: 'utf8' }).trim()}`,
    `Version:  ${(() => {
      try {
        return execSync('openclaw --version', { encoding: 'utf8' }).trim();
      } catch {
        return 'unknown';
      }
    })()}`,
    `Output:   ${OUT}`,
    "================================================================"
  ].join('\n') + '\n';
  
  writeFileSync(OUT, header);
};

const run_cmd = (title, ...cmd) => {
  const timestamp = new Date().toISOString();
  const commandStr = cmd.join(' ');
  
  const output = [
    "",
    "----------------------------------------------------------------",
    `### ${title}`,
    `### $ ${commandStr}`,
    `### ${timestamp}`,
    "----------------------------------------------------------------"
  ].join('\n') + '\n';
  
  appendFileSync(OUT, output);
  
  try {
    const result = execSync(cmd.join(' '), { encoding: 'utf8' });
    appendFileSync(OUT, result);
    appendFileSync(OUT, `[exit: 0]\n`);
  } catch (error) {
    if (error.stdout) appendFileSync(OUT, error.stdout);
    if (error.stderr) appendFileSync(OUT, error.stderr);
    appendFileSync(OUT, `[exit: ${error.status || 1}]\n`);
  }
};

writeHeader();

run_cmd("tasks audit --severity error", ...OC, "tasks", "audit", "--severity", "error");
run_cmd("secrets audit", ...OC, "secrets", "audit");
run_cmd("security audit", ...OC, "security", "audit");
run_cmd("plugins doctor", ...OC, "plugins", "doctor");
run_cmd("plugins deps", ...OC, "plugins", "deps");
run_cmd("plugins registry", ...OC, "plugins", "registry");
run_cmd("skills check", ...OC, "skills", "check");
run_cmd("hooks check", ...OC, "hooks", "check");
run_cmd("gateway status --deep", ...OC, "gateway", "status", "--deep");
run_cmd("channels status --probe", ...OC, "channels", "status", "--probe");
run_cmd("memory status --deep", ...OC, "memory", "status", "--deep");
run_cmd("sessions --all-agents", ...OC, "sessions", "--all-agents");
run_cmd("tasks list", ...OC, "tasks", "list");
run_cmd("cron list", ...OC, "cron", "list");

const footer = [
  "",
  "================================================================",
  `Audit complete: ${new Date().toISOString()}`,
  "================================================================"
].join('\n') + '\n';

appendFileSync(OUT, footer);

console.log(`Audit complete. Output: ${OUT}`);
