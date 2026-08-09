#!/usr/bin/env node
// find-sessions.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/find-sessions.sh
// auch in: OpenClaw@gateway2:skills/tmux/scripts/find-sessions.sh
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import { spawnSync } from 'child_process';
import { existsSync, statSync } from 'fs';
import { readdir } from 'fs/promises';
import { join } from 'path';

const usage = () => {
  console.error(`Usage: find-sessions.sh [-L socket-name|-S socket-path|-A] [-q pattern]

List tmux sessions on a socket (default tmux socket if none provided).

Options:
  -L, --socket       tmux socket name (passed to tmux -L)
  -S, --socket-path  tmux socket path (passed to tmux -S)
  -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR
  -q, --query        case-insensitive substring to filter session names
  -h, --help         show this help`);
};

let socketName = '';
let socketPath = '';
let query = '';
let scanAll = false;
const socketDir = process.env.CLAWDBOT_TMUX_SOCKET_DIR || (process.env.TMPDIR || '/tmp') + '/clawdbot-tmux-sockets';

const args = process.argv.slice(2);
let i = 0;

while (i < args.length) {
  const arg = args[i];
  switch (arg) {
    case '-L':
    case '--socket':
      socketName = args[i + 1] || '';
      i += 2;
      break;
    case '-S':
    case '--socket-path':
      socketPath = args[i + 1] || '';
      i += 2;
      break;
    case '-A':
    case '--all':
      scanAll = true;
      i++;
      break;
    case '-q':
    case '--query':
      query = args[i + 1] || '';
      i += 2;
      break;
    case '-h':
    case '--help':
      usage();
      process.exit(0);
    default:
      console.error(`Unknown option: ${arg}`);
      usage();
      process.exit(1);
  }
}

if (scanAll && (socketName || socketPath)) {
  console.error('Cannot combine --all with -L or -S');
  process.exit(1);
}

if (socketName && socketPath) {
  console.error('Use either -L or -S, not both');
  process.exit(1);
}

const tmuxExists = spawnSync('which', ['tmux']).status === 0;
if (!tmuxExists) {
  console.error('tmux not found in PATH');
  process.exit(1);
}

const listSessions = (label, tmuxArgs) => {
  const tmuxCmd = ['tmux', ...tmuxArgs, 'list-sessions', '-F', '#{session_name}\t#{session_attached}\t#{session_created_string}'];
  
  const result = spawnSync(tmuxCmd[0], tmuxCmd.slice(1), { encoding: 'utf8' });
  
  if (result.status !== 0) {
    console.error(`No tmux server found on ${label}`);
    return false;
  }
  
  let sessions = result.stdout.trim();
  
  if (query) {
    const lines = sessions.split('\n').filter(line => line.toLowerCase().includes(query.toLowerCase()));
    sessions = lines.join('\n');
  }
  
  if (!sessions) {
    console.log(`No sessions found on ${label}`);
    return true;
  }
  
  console.log(`Sessions on ${label}:`);
  sessions.split('\n').forEach(line => {
    const [name, attached, created] = line.split('\t');
    const attachedLabel = attached === '1' ? 'attached' : 'detached';
    console.log(`  - ${name} (${attachedLabel}, started ${created})`);
  });
  
  return true;
};

if (scanAll) {
  if (!existsSync(socketDir) || !statSync(socketDir).isDirectory()) {
    console.error(`Socket directory not found: ${socketDir}`);
    process.exit(1);
  }
  
  let exitCode = 0;
  
  readdir(socketDir)
    .then(async files => {
      if (files.length === 0) {
        console.error(`No sockets found under ${socketDir}`);
        process.exit(1);
      }
      
      for (const file of files) {
        const fullPath = join(socketDir, file);
        if (statSync(fullPath).isSocket()) {
          const success = listSessions(`socket path '${fullPath}'`, ['-S', fullPath]);
          if (!success) exitCode = 1;
        }
      }
      
      process.exit(exitCode);
    })
    .catch(err => {
      console.error(err.message);
      process.exit(1);
    });
} else {
  const tmuxArgs = [];
  let socketLabel = 'default socket';
  
  if (socketName) {
    tmuxArgs.push('-L', socketName);
    socketLabel = `socket name '${socketName}'`;
  } else if (socketPath) {
    tmuxArgs.push('-S', socketPath);
    socketLabel = `socket path '${socketPath}'`;
  }
  
  listSessions(socketLabel, tmuxArgs);
}
