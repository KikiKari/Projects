#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "530f8d99e61bc3bac0ff1c2e0cc22e0eff8f54db33772e21a60d90174f2c0119", "source_sha256": "a137d03b3b37332439a1592831d60479ff86315c7e6d6ed7da0fb799db0f13f7", "target_language": "javascript"}
// find-sessions.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/find-sessions.sh
// auch in: OpenClaw@gateway2:skills/tmux/scripts/find-sessions.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const usage = () => {
  process.stdout.write(`\
Usage: find-sessions.sh [-L socket-name|-S socket-path|-A] [-q pattern]

List tmux sessions on a socket (default tmux socket if none provided).

Options:
  -L, --socket       tmux socket name (passed to tmux -L)
  -S, --socket-path  tmux socket path (passed to tmux -S)
  -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR
  -q, --query        case-insensitive substring to filter session names
  -h, --help         show this help
`);
};

const args = process.argv.slice(2);
let socketName = "";
let socketPath = "";
let query = "";
let scanAll = false;
const socketDir = process.env.CLAWDBOT_TMUX_SOCKET_DIR || 
                 (process.env.TMPDIR || '/tmp') + '/clawdbot-tmux-sockets';

const unknownOption = (option) => {
  console.error(`Unknown option: ${option}`);
  usage();
  process.exit(1);
};

let i = 0;
while (i < args.length) {
  const arg = args[i];
  
  switch (arg) {
    case '-L':
    case '--socket':
      if (i + 1 >= args.length) {
        console.error('Option requires an argument:', arg);
        process.exit(1);
      }
      socketName = args[i + 1];
      i += 2;
      break;
      
    case '-S':
    case '--socket-path':
      if (i + 1 >= args.length) {
        console.error('Option requires an argument:', arg);
        process.exit(1);
      }
      socketPath = args[i + 1];
      i += 2;
      break;
      
    case '-A':
    case '--all':
      scanAll = true;
      i++;
      break;
      
    case '-q':
    case '--query':
      if (i + 1 >= args.length) {
        console.error('Option requires an argument:', arg);
        process.exit(1);
      }
      query = args[i + 1];
      i += 2;
      break;
      
    case '-h':
    case '--help':
      usage();
      process.exit(0);
      break;
      
    default:
      unknownOption(arg);
      break;
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

// Check if tmux exists
const whichResult = spawnSync('which', ['tmux'], { stdio: 'pipe' });
if (whichResult.status !== 0) {
  console.error('tmux not found in PATH');
  process.exit(1);
}

const listSessions = (label, tmuxArgs) => {
  const cmd = ['tmux', ...tmuxArgs, 'list-sessions', '-F', '#{session_name}\t#{session_attached}\t#{session_created_string}'];
  
  const result = spawnSync(cmd[0], cmd.slice(1), { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
  
  if (result.status !== 0) {
    console.error(`No tmux server found on ${label}`);
    return false;
  }
  
  let sessions = result.stdout.trim();
  if (!sessions) {
    console.log(`No sessions found on ${label}`);
    return true;
  }
  
  if (query) {
    const lines = sessions.split('\n').filter(line => 
      line.toLowerCase().includes(query.toLowerCase())
    );
    sessions = lines.join('\n');
    
    if (!sessions) {
      console.log(`No sessions found on ${label}`);
      return true;
    }
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
  if (!fs.existsSync(socketDir) || !fs.statSync(socketDir).isDirectory()) {
    console.error(`Socket directory not found: ${socketDir}`);
    process.exit(1);
  }
  
  const sockets = fs.readdirSync(socketDir)
    .map(file => path.join(socketDir, file))
    .filter(file => fs.statSync(file).isSocket());
  
  if (sockets.length === 0) {
    console.error(`No sockets found under ${socketDir}`);
    process.exit(1);
  }
  
  let exitCode = 0;
  for (const sock of sockets) {
    if (!listSessions(`socket path '${sock}'`, ['-S', sock])) {
      exitCode = 1;
    }
  }
  
  process.exit(exitCode);
}

const tmuxCmd = ['tmux'];
let socketLabel = 'default socket';

if (socketName) {
  tmuxCmd.push('-L', socketName);
  socketLabel = `socket name '${socketName}'`;
} else if (socketPath) {
  tmuxCmd.push('-S', socketPath);
  socketLabel = `socket path '${socketPath}'`;
}

listSessions(socketLabel, tmuxCmd.slice(1));
