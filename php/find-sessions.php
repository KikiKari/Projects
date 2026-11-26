<?php
// abstraction-provenance: {"artifact_sha256": "fc33f510621cc5137d7772cb8ad2332b9384b9166af2d63b708c3c373e0a3723", "source_sha256": "a137d03b3b37332439a1592831d60479ff86315c7e6d6ed7da0fb799db0f13f7", "target_language": "php"}
// find-sessions.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/find-sessions.sh
// auch in: OpenClaw@gateway2:skills/tmux/scripts/find-sessions.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
function usage() {
    fwrite(STDERR, <<<USAGE
Usage: find-sessions.php [-L socket-name|-S socket-path|-A] [-q pattern]

List tmux sessions on a socket (default tmux socket if none provided).

Options:
  -L, --socket       tmux socket name (passed to tmux -L)
  -S, --socket-path  tmux socket path (passed to tmux -S)
  -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR
  -q, --query        case-insensitive substring to filter session names
  -h, --help         show this help

USAGE
);
}

$socket_name = "";
$socket_path = "";
$query = "";
$scan_all = false;
$socket_dir = getenv('CLAWDBOT_TMUX_SOCKET_DIR') ?: (getenv('TMPDIR') ?: '/tmp') . '/clawdbot-tmux-sockets';

$args = array_slice($argv, 1);
$i = 0;

while ($i < count($args)) {
    $arg = $args[$i];
    
    switch ($arg) {
        case '-L':
        case '--socket':
            if ($i + 1 >= count($args)) {
                fwrite(STDERR, "Option $arg requires an argument\n");
                usage();
                exit(1);
            }
            $socket_name = $args[$i + 1];
            $i += 2;
            break;
            
        case '-S':
        case '--socket-path':
            if ($i + 1 >= count($args)) {
                fwrite(STDERR, "Option $arg requires an argument\n");
                usage();
                exit(1);
            }
            $socket_path = $args[$i + 1];
            $i += 2;
            break;
            
        case '-A':
        case '--all':
            $scan_all = true;
            $i++;
            break;
            
        case '-q':
        case '--query':
            if ($i + 1 >= count($args)) {
                fwrite(STDERR, "Option $arg requires an argument\n");
                usage();
                exit(1);
            }
            $query = $args[$i + 1];
            $i += 2;
            break;
            
        case '-h':
        case '--help':
            usage();
            exit(0);
            
        default:
            fwrite(STDERR, "Unknown option: $arg\n");
            usage();
            exit(1);
    }
}

if ($scan_all && ($socket_name !== "" || $socket_path !== "")) {
    fwrite(STDERR, "Cannot combine --all with -L or -S\n");
    exit(1);
}

if ($socket_name !== "" && $socket_path !== "") {
    fwrite(STDERR, "Use either -L or -S, not both\n");
    exit(1);
}

// Check if tmux is available
exec('which tmux', $output, $return_var);
if ($return_var !== 0) {
    fwrite(STDERR, "tmux not found in PATH\n");
    exit(1);
}

function list_sessions($label, $tmux_args) {
    global $query;
    
    $cmd = ['tmux'] + $tmux_args + ['list-sessions', '-F', '#{session_name}\t#{session_attached}\t#{session_created_string}'];
    $process = proc_open(
        implode(' ', array_map('escapeshellarg', $cmd)),
        [
            0 => ['pipe', 'r'],
            1 => ['pipe', 'w'],
            2 => ['pipe', 'w']
        ],
        $pipes
    );
    
    if (!$process) {
        fwrite(STDERR, "Failed to execute tmux command\n");
        return 1;
    }
    
    fclose($pipes[0]);
    $sessions = stream_get_contents($pipes[1]);
    $errors = stream_get_contents($pipes[2]);
    $return_code = proc_close($process);
    
    if ($return_code !== 0) {
        fwrite(STDERR, "No tmux server found on $label\n");
        return 1;
    }
    
    if ($query !== "") {
        $lines = explode("\n", trim($sessions));
        $filtered_lines = [];
        foreach ($lines as $line) {
            if (stripos($line, $query) !== false) {
                $filtered_lines[] = $line;
            }
        }
        $sessions = implode("\n", $filtered_lines);
    }
    
    if (trim($sessions) === "") {
        echo "No sessions found on $label\n";
        return 0;
    }
    
    echo "Sessions on $label:\n";
    $lines = explode("\n", trim($sessions));
    foreach ($lines as $line) {
        $parts = explode("\t", $line);
        if (count($parts) >= 3) {
            $name = $parts[0];
            $attached = $parts[1];
            $created = $parts[2];
            $attached_label = ($attached == "1") ? "attached" : "detached";
            echo "  - $name ($attached_label, started $created)\n";
        }
    }
    
    return 0;
}

if ($scan_all) {
    if (!is_dir($socket_dir)) {
        fwrite(STDERR, "Socket directory not found: $socket_dir\n");
        exit(1);
    }
    
    $sockets = glob("$socket_dir/*");
    if (empty($sockets)) {
        fwrite(STDERR, "No sockets found under $socket_dir\n");
        exit(1);
    }
    
    $exit_code = 0;
    foreach ($sockets as $sock) {
        if (!is_socket($sock)) {
            continue;
        }
        $result = list_sessions("socket path '$sock'", ['-S', $sock]);
        if ($result !== 0) {
            $exit_code = $result;
        }
    }
    exit($exit_code);
}

$tmux_cmd = [];
$socket_label = "default socket";

if ($socket_name !== "") {
    $tmux_cmd = ['-L', $socket_name];
    $socket_label = "socket name '$socket_name'";
} elseif ($socket_path !== "") {
    $tmux_cmd = ['-S', $socket_path];
    $socket_label = "socket path '$socket_path'";
}

list_sessions($socket_label, $tmux_cmd);
