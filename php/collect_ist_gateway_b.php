<?php
// abstraction-provenance: {"artifact_sha256": "b6624009e820079a30e9880ff450fd7a2b6cbd45a56a708e4b35e0bda2fb6a26", "source_sha256": "da890cc26fb848b78b6a85373d6cfa4e08f6e7c2002921e1c0247960b8b361d7", "target_language": "php"}
// collect_ist_gateway_b.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
$BASE_DIR = getenv('HOME') . '/.openclaw';
$OUT_DIR = $BASE_DIR . '/workspace/vscode';
@mkdir($OUT_DIR, 0777, true);

date_default_timezone_set('UTC');
$NOW_UTC = gmdate("Y-m-d\TH:i:s\Z");
$NOW_LOCAL = date("Y-m-d H:i:s T");
$TS = date("Ymd-His");

$IST_FILE = $OUT_DIR . '/IST-ZUSTAND_GATEWAY-B_NODE7.md';
$INV_FILE = $OUT_DIR . '/ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md';
$CFG_FILE = $OUT_DIR . '/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md';
$ENV_FILE = $OUT_DIR . '/ENV-STATUS_GATEWAY-B_NODE7.md';
$RUN_FILE = $OUT_DIR . '/RUN-' . $TS . '.md';

$OPENCLAW_JSON = $BASE_DIR . '/openclaw.json';
$ENV_DOT = $BASE_DIR . '/.env';
$ENV_SYSTEMD = $BASE_DIR . '/gateway.systemd.env';
$VSCODE_DIR = $BASE_DIR . '/.vscode';

$HOSTNAME_FQDN = trim(shell_exec('hostname -f 2>/dev/null') ?: gethostname());
$HOSTNAME_SHORT = gethostname();
$ARCH = php_uname('m');
$KERNEL = php_uname('r');
$OS_PRETTY = '';
if (file_exists('/etc/os-release')) {
    $lines = file('/etc/os-release', FILE_IGNORE_NEW_LINES);
    foreach ($lines as $line) {
        if (strpos($line, 'PRETTY_NAME=') === 0) {
            $OS_PRETTY = trim(substr($line, 12), '"');
            break;
        }
    }
}
$IPV4_ALL = trim(shell_exec('hostname -I 2>/dev/null') ?: '');
$PUBLIC_IP = trim(shell_exec('curl -4 -s --max-time 4 ifconfig.me 2>/dev/null') ?: '');
$TAILSCALE_IP = trim(shell_exec('tailscale ip -4 2>/dev/null | head -n1') ?: '');
$OPENCLAW_VER = trim(shell_exec('openclaw --version 2>/dev/null') ?: '');
$NODE_VER = trim(shell_exec('node -v 2>/dev/null') ?: '');

if (!$PUBLIC_IP) $PUBLIC_IP = "(nicht ermittelt)";
if (!$TAILSCALE_IP) $TAILSCALE_IP = "(nicht ermittelt)";
if (!$OPENCLAW_VER) $OPENCLAW_VER = "(nicht ermittelt)";
if (!$NODE_VER) $NODE_VER = "(nicht ermittelt)";

// IST Zustand
$ist_content = <<<EOF
# IST-Zustand: Gateway B / Node 7

Stand (lokal): {$NOW_LOCAL}  
Stand (UTC): {$NOW_UTC}

## 1) Identität & System

- Gateway: **B**
- Node: **7**
- Hostname (short): `{$HOSTNAME_SHORT}`
- Hostname (FQDN): `{$HOSTNAME_FQDN}`
- Architektur: `{$ARCH}`
- Kernel: `{$KERNEL}`
- OS: `{$OS_PRETTY}`
- IPv4 (lokal): `{$IPV4_ALL}`
- Public IPv4: `{$PUBLIC_IP}`
- Tailscale IPv4: `{$TAILSCALE_IP}`
- OpenClaw Version: `{$OPENCLAW_VER}`
- Node.js Version: `{$NODE_VER}`

## 2) Arbeitsverzeichnisse

- Basis: `{$BASE_DIR}`
- Funktionell VSCode: `{$VSCODE_DIR}`
- Workspace Doku: `{$OUT_DIR}`

## 3) Kernartefakte (Existenz)

- `{$OPENCLAW_JSON}`: 
EOF;

$ist_content .= (file_exists($OPENCLAW_JSON) ? "vorhanden\n" : "fehlt\n");
$ist_content .= "- `{$ENV_DOT}`: ";
$ist_content .= (file_exists($ENV_DOT) ? "vorhanden\n" : "fehlt\n");
$ist_content .= "- `{$ENV_SYSTEMD}`: ";
$ist_content .= (file_exists($ENV_SYSTEMD) ? "vorhanden\n" : "fehlt\n");
$ist_content .= "- `{$BASE_DIR}/plugins/installs.json`: ";
$ist_content .= (file_exists($BASE_DIR . '/plugins/installs.json') ? "vorhanden\n" : "fehlt\n");
$ist_content .= "- `{$BASE_DIR}/plugin-skills`: ";
$ist_content .= (is_dir($BASE_DIR . '/plugin-skills') ? "vorhanden\n" : "fehlt\n");

$ist_content .= <<<EOF

## 4) Hinweis

Diese Datei wird bei jedem Lauf neu geschrieben.
Zusätzlich wird ein Laufprotokoll als `RUN-*.md` erzeugt.
EOF;

file_put_contents($IST_FILE, $ist_content);

// Artefakt Inventar
ob_start();

echo "# Artefakt-Inventar: Gateway B / Node 7\n";
echo "\n";
echo "Stand: {$NOW_LOCAL}\n";
echo "\n";
echo "## Top-Level in ~/.openclaw\n";
echo "\n";
echo '```text' . "\n";
if (is_dir($BASE_DIR)) {
    $files = scandir($BASE_DIR);
    foreach ($files as $file) {
        if ($file !== '.' && $file !== '..') {
            echo "$file\n";
        }
    }
}
echo '```' . "\n";
echo "\n";
echo "## ~/.openclaw/.vscode\n";
echo "\n";
echo '```text' . "\n";
if (is_dir($VSCODE_DIR)) {
    echo shell_exec("ls -la " . escapeshellarg($VSCODE_DIR));
} else {
    echo "(nicht vorhanden)\n";
}
echo '```' . "\n";
echo "\n";
echo "## plugin-skills/\n";
echo "\n";
echo '```text' . "\n";
if (is_dir($BASE_DIR . '/plugin-skills')) {
    $skills = scandir($BASE_DIR . '/plugin-skills');
    foreach ($skills as $skill) {
        if ($skill !== '.' && $skill !== '..') {
            echo "$skill\n";
        }
    }
} else {
    echo "(nicht vorhanden)\n";
}
echo '```' . "\n";
echo "\n";
echo "## openclaw.json Backups\n";
echo "\n";
echo '```text' . "\n";
$backup_files = glob($BASE_DIR . '/openclaw.json.bak*');
if (!empty($backup_files)) {
    foreach ($backup_files as $bf) {
        echo basename($bf) . "\n";
    }
} else {
    echo "(keine gefunden)\n";
}
echo '```';

$inv_content = ob_get_clean();
file_put_contents($INV_FILE, $inv_content);

// Config Snapshot
ob_start();

echo "# OpenClaw Config Snapshot: Gateway B / Node 7\n";
echo "\n";
echo "Stand: {$NOW_LOCAL}\n";
echo "\n";
echo "## Schlüsselpositionen (grep)\n";
echo "\n";
echo '```text' . "\n";
if (file_exists($OPENCLAW_JSON)) {
    $content = file_get_contents($OPENCLAW_JSON);
    $lines = explode("\n", $content);
    $pattern = '/"(gateway|session|dmScope|auth|secrets|tools|plugins|profile|alsoAllow|denyCommands)"/';
    foreach ($lines as $num => $line) {
        if (preg_match($pattern, $line)) {
            echo ($num + 1) . ": " . trim($line) . "\n";
        }
    }
} else {
    echo "openclaw.json fehlt\n";
}
echo '```' . "\n";
echo "\n";
echo "## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)\n";
echo "\n";
echo '```json' . "\n";
if (file_exists($OPENCLAW_JSON)) {
    $lines = file($OPENCLAW_JSON, FILE_IGNORE_NEW_LINES);
    $start = 579;
    $end = 779;
    for ($i = $start; $i <= $end && isset($lines[$i]); $i++) {
        echo $lines[$i] . "\n";
    }
} else {
    echo '{ "error": "openclaw.json fehlt" }' . "\n";
}
echo '```';

$config_content = ob_get_clean();
file_put_contents($CFG_FILE, $config_content);

// ENV Status
ob_start();

echo "# ENV-Status: Gateway B / Node 7\n";
echo "\n";
echo "Stand: {$NOW_LOCAL}\n";
echo "\n";
echo "## Dateien\n";
echo "\n";
echo '```text' . "\n";
if (file_exists($ENV_DOT) || file_exists($ENV_SYSTEMD)) {
    if (file_exists($ENV_DOT)) {
        echo sprintf("%-10s %s\n", filetype($ENV_DOT), $ENV_DOT);
    }
    if (file_exists($ENV_SYSTEMD)) {
        echo sprintf("%-10s %s\n", filetype($ENV_SYSTEMD), $ENV_SYSTEMD);
    }
}
echo '```' . "\n";
echo "\n";
echo "## .env (vollständig, ungefiltert)\n";
echo "\n";
echo '```dotenv' . "\n";
if (file_exists($ENV_DOT)) {
    readfile($ENV_DOT);
} else {
    echo "# .env fehlt\n";
}
echo '```' . "\n";
echo "\n";
echo "## gateway.systemd.env (vollständig, ungefiltert)\n";
echo "\n";
echo '```dotenv' . "\n";
if (file_exists($ENV_SYSTEMD)) {
    readfile($ENV_SYSTEMD);
} else {
    echo "# gateway.systemd.env fehlt\n";
}
echo '```';

$env_content = ob_get_clean();
file_put_contents($ENV_FILE, $env_content);

// Run File
$run_content = <<<EOF
# Laufprotokoll Gateway B / Node 7

- Zeit (lokal): {$NOW_LOCAL}
- Zeit (UTC): {$NOW_UTC}
- Script: {$_SERVER['SCRIPT_FILENAME']}

## Erzeugte Dateien

- IST-ZUSTAND_GATEWAY-B_NODE7.md
- ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md
- OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md
- ENV-STATUS_GATEWAY-B_NODE7.md

EOF;

file_put_contents($RUN_FILE, $run_content);

echo "OK: IST-Zustand erfasst.\n";
echo "Ausgabeordner: {$OUT_DIR}\n";
echo "Dateien:\n";

$files = scandir($OUT_DIR);
foreach ($files as $file) {
    if ($file !== '.' && $file !== '..') {
        echo "- $file\n";
    }
}

?>
