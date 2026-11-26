<?php
// abstraction-provenance: {"artifact_sha256": "9a76b3032e91e5183a6c2a904fb931bb4655dd83515cf09968852c25bae1551d", "source_sha256": "47064dbc7b32c01d57d42222f8cc3ac7caf9c8d82b98029dc5fc6ecb0d32f2c9", "target_language": "php"}
// collect_ist_gateway_a.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
$baseDir = getenv('HOME') . '/.openclaw';
$outDir = $baseDir . '/workspace/vscode';

// Zeitstempel generieren
$nowUtc = gmdate('Y-m-d\TH:i:s\Z');
$nowLocal = date('Y-m-d H:i:s T');
$ts = date('Ymd-His');

// Ausgabeverzeichnis erstellen
if (!is_dir($outDir)) {
    mkdir($outDir, 0777, true);
}

// Dateipfade definieren
$istFile = $outDir . '/IST-ZUSTAND_GATEWAY-A_NODE1.md';
$invFile = $outDir . '/ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md';
$configFile = $outDir . '/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md';
$envFile = $outDir . '/ENV-STATUS_GATEWAY-A_NODE1.md';
$runFile = $outDir . '/RUN-' . $ts . '.md';

$openclawJson = $baseDir . '/openclaw.json';
$envDot = $baseDir . '/.env';
$envSystemd = $baseDir . '/gateway.systemd.env';
$vscodeDir = $baseDir . '/.vscode';

// Systeminformationen sammeln
$hostnameFqdn = trim(shell_exec('hostname -f 2>/dev/null') ?: gethostname());
$hostnameShort = gethostname();
$arch = trim(shell_exec('uname -m'));
$kernel = trim(shell_exec('uname -r'));
$osPretty = '';
if (file_exists('/etc/os-release')) {
    $lines = file('/etc/os-release', FILE_IGNORE_NEW_LINES);
    foreach ($lines as $line) {
        if (strpos($line, 'PRETTY_NAME=') === 0) {
            $osPretty = trim(substr($line, 12), '"');
            break;
        }
    }
}
$ipv4All = trim(shell_exec('hostname -I 2>/dev/null') ?: '');
$publicIp = trim(shell_exec('curl -4 -s --max-time 4 ifconfig.me 2>/dev/null') ?: '');
$tailscaleIp = trim(shell_exec('tailscale ip -4 2>/dev/null | head -n1') ?: '');
$openclawVer = trim(shell_exec('openclaw --version 2>/dev/null') ?: '');
$nodeVer = trim(shell_exec('node -v 2>/dev/null') ?: '');

// Fallback-Werte setzen
if (empty($publicIp)) $publicIp = '(nicht ermittelt)';
if (empty($tailscaleIp)) $tailscaleIp = '(nicht ermittelt)';
if (empty($openclawVer)) $openclawVer = '(nicht ermittelt)';
if (empty($nodeVer)) $nodeVer = '(nicht ermittelt)';

// IST-Zustand schreiben
$istContent = <<<EOM
# IST-Zustand: Gateway A / Node 1

Stand (lokal): {$nowLocal}  
Stand (UTC): {$nowUtc}

## 1) Identitaet & System

- Gateway: **A**
- Node: **1**
- Hostname (short): `{$hostnameShort}`
- Hostname (FQDN): `{$hostnameFqdn}`
- Architektur: `{$arch}`
- Kernel: `{$kernel}`
- OS: `{$osPretty}`
- IPv4 (lokal): `{$ipv4All}`
- Public IPv4: `{$publicIp}`
- Tailscale IPv4: `{$tailscaleIp}`
- OpenClaw Version: `{$openclawVer}`
- Node.js Version: `{$nodeVer}`

## 2) Arbeitsverzeichnisse

- Basis: `{$baseDir}`
- Funktionell VSCode: `{$vscodeDir}`
- Workspace Doku: `{$outDir}`

## 3) Kernartefakte (Existenz)

- `{$openclawJson}`: 
EOM;

$istContent .= (file_exists($openclawJson) ? "vorhanden\n" : "fehlt\n");
$istContent .= "- `{$envDot}`: " . (file_exists($envDot) ? "vorhanden\n" : "fehlt\n");
$istContent .= "- `{$envSystemd}`: " . (file_exists($envSystemd) ? "vorhanden\n" : "fehlt\n");
$istContent .= "- `{$baseDir}/plugins/installs.json`: " . (file_exists("{$baseDir}/plugins/installs.json") ? "vorhanden\n" : "fehlt\n");
$istContent .= "- `{$baseDir}/plugin-skills`: " . (is_dir("{$baseDir}/plugin-skills") ? "vorhanden\n" : "fehlt\n");

file_put_contents($istFile, $istContent);

// Artefakt-Inventar erstellen
ob_start();

echo "# Artefakt-Inventar: Gateway A / Node 1\n";
echo "\n";
echo "Stand: {$nowLocal}\n";
echo "\n";
echo "## Top-Level in ~/.openclaw\n";
echo "\n";
echo '```text' . "\n";
if (is_dir($baseDir)) {
    $files = scandir($baseDir);
    foreach ($files as $file) {
        if ($file !== '.' && $file !== '..') {
            echo $file . "\n";
        }
    }
}
echo '```' . "\n";
echo "\n";
echo "## ~/.openclaw/.vscode\n";
echo "\n";
echo '```text' . "\n";
if (is_dir($vscodeDir)) {
    echo shell_exec("ls -la " . escapeshellarg($vscodeDir));
} else {
    echo "(nicht vorhanden)\n";
}
echo '```' . "\n";
echo "\n";
echo "## plugin-skills/\n";
echo "\n";
echo '```text' . "\n";
if (is_dir("{$baseDir}/plugin-skills")) {
    $skills = scandir("{$baseDir}/plugin-skills");
    foreach ($skills as $skill) {
        if ($skill !== '.' && $skill !== '..') {
            echo $skill . "\n";
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

$backupFiles = glob("{$baseDir}/openclaw.json.bak*");
if (!empty($backupFiles)) {
    foreach ($backupFiles as $backup) {
        echo basename($backup) . "\n";
    }
} else {
    echo "(keine gefunden)\n";
}
echo '```' . "\n";

$inventoryContent = ob_get_clean();
file_put_contents($invFile, $inventoryContent);

// Konfigurations-Snapshot erstellen
ob_start();

echo "# OpenClaw Config Snapshot: Gateway A / Node 1\n";
echo "\n";
echo "Stand: {$nowLocal}\n";
echo "\n";
echo "## Schluesselpositionen (grep)\n";
echo "\n";
echo '```text' . "\n";
if (file_exists($openclawJson)) {
    $content = file_get_contents($openclawJson);
    $lines = explode("\n", $content);
    $lineNumber = 1;
    foreach ($lines as $line) {
        if (preg_match('/"gateway"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"/', $line)) {
            echo $lineNumber . ": " . $line . "\n";
        }
        $lineNumber++;
    }
} else {
    echo "openclaw.json fehlt\n";
}
echo '```' . "\n";
echo "\n";
echo "## Ausschnitt gateway/session/auth\n";
echo "\n";
echo '```json' . "\n";
if (file_exists($openclawJson)) {
    $lines = file($openclawJson, FILE_IGNORE_NEW_LINES);
    $start = 579; // 0-based index for line 580
    $end = 779;  // 0-based index for line 780
    for ($i = $start; $i <= $end && $i < count($lines); $i++) {
        echo $lines[$i] . "\n";
    }
} else {
    echo '{ "error": "openclaw.json fehlt" }' . "\n";
}
echo '```' . "\n";

$configContent = ob_get_clean();
file_put_contents($configFile, $configContent);

// ENV-Status erstellen
ob_start();

echo "# ENV-Status: Gateway A / Node 1\n";
echo "\n";
echo "Stand: {$nowLocal}\n";
echo "\n";
echo "## Dateien\n";
echo "\n";
echo '```text' . "\n";
if (file_exists($envDot) || file_exists($envSystemd)) {
    if (file_exists($envDot)) {
        echo shell_exec("ls -la " . escapeshellarg($envDot));
    }
    if (file_exists($envSystemd)) {
        echo shell_exec("ls -la " . escapeshellarg($envSystemd));
    }
}
echo '```' . "\n";
echo "\n";
echo "## .env (vollstaendig)\n";
echo "\n";
echo '```dotenv' . "\n";
if (file_exists($envDot)) {
    echo file_get_contents($envDot);
} else {
    echo "# .env fehlt\n";
}
echo '```' . "\n";
echo "\n";
echo "## gateway.systemd.env (vollstaendig)\n";
echo "\n";
echo '```dotenv' . "\n";
if (file_exists($envSystemd)) {
    echo file_get_contents($envSystemd);
} else {
    echo "# gateway.systemd.env fehlt\n";
}
echo '```' . "\n";

$envContent = ob_get_clean();
file_put_contents($envFile, $envContent);

// Laufprotokoll erstellen
$scriptPath = __FILE__;
$runContent = <<<EOM
# Laufprotokoll Gateway A / Node 1

- Zeit (lokal): {$nowLocal}
- Zeit (UTC): {$nowUtc}
- Script: {$scriptPath}

## Erzeugte Dateien

- IST-ZUSTAND_GATEWAY-A_NODE1.md
- ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md
- OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md
- ENV-STATUS_GATEWAY-A_NODE1.md

EOM;

file_put_contents($runFile, $runContent);

echo "OK: IST-Zustand erfasst.\n";
$files = scandir($outDir);
foreach ($files as $file) {
    if ($file !== '.' && $file !== '..') {
        echo "- {$file}\n";
    }
}
