#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "383a4b9b1741b504be08176c4fa5b4796d32b54ff95d0135297c25bfc0be9f60", "source_sha256": "e51b94641336291974fe14bf4bb7299a75ec7dcce49e1d413282c8043e9f09f1", "target_language": "javascript"}
// openclaw-audit.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

// OpenClaw read-only audit/diagnostic sweep
// Output: openclaw-audit-YYYY-MM-DD.log im selben Verzeichnis wie dieses Script

import { spawnSync } from 'child_process';
import { writeFileSync, appendFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const DATE_STAMP = new Date().toISOString().split('T')[0];
const OUT = join(__dirname, `openclaw-audit-${DATE_STAMP}.log`);

const OC = ['openclaw', '--no-color'];

const writeHeader = () => {
  const header = `================================================================
OpenClaw audit run
Started:  ${new Date().toISOString()}
Host:     ${process.env.HOSTNAME || 'unknown'}
User:     ${process.env.USER || 'unknown'}
Version:  ${(spawnSync('openclaw', ['--version'], { encoding: 'utf-8' }).stdout || 'unknown').trim()}
Output:   ${OUT}
================================================================\n`;
  writeFileSync(OUT, header);
};

const run_cmd = (title, ...args) => {
  const cmdOutput = spawnSync(args[0], args.slice(1), { encoding: 'utf-8' });
  const output = `
----------------------------------------------------------------
### ${title}
### $ ${args.join(' ')}
### ${new Date().toISOString()}
----------------------------------------------------------------
${cmdOutput.stdout || ''}
${cmdOutput.stderr ? cmdOutput.stderr + '\n' : ''}
[exit: ${cmdOutput.status}]
`;
  appendFileSync(OUT, output);
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

const footer = `
================================================================
Audit complete: ${new Date().toISOString()}
================================================================\n`;
appendFileSync(OUT, footer);

console.log(`Audit complete. Output: ${OUT}`);
