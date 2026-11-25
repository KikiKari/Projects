<?php
// abstraction-provenance: {"artifact_sha256": "f673e208f8d374fd2f4efa8956a004f121e3a3e260840084595a93a32add6066", "source_sha256": "1b01ca0f5943b16d3905faf557953600ee54f15ecf1dc18c1461585eba94d376", "target_language": "php"}
// abstractions-manager-cron.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py
// Setzen der Umgebungsvariablen
putenv('PATH=/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin');

// Laden der Umgebungsvariablen aus der .env-Datei
$envFile = '/home/openclaw/.openclaw/.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos($line, '#') === 0 || empty($line)) {
            continue;
        }
        putenv($line);
        list($key, $value) = explode('=', $line, 2);
        $_ENV[$key] = $value;
        $_SERVER[$key] = $value;
    }
}

// Überprüfen, ob OPENROUTER_API_KEY gesetzt ist
if (!getenv('OPENROUTER_API_KEY')) {
    fwrite(STDERR, "OPENROUTER_API_KEY fehlt\n");
    exit(1);
}

// Setzen des GITHUB_TOKEN
$githubToken = getenv('GITHUB_TOKEN') ?: getenv('GH_TOKEN') ?: getenv('GH_ACCESS_TOKEN');
if ($githubToken) {
    putenv("GITHUB_TOKEN=$githubToken");
}

// Pfad zur Lock-Datei
$lockFile = '/home/openclaw/.openclaw/locks/abstractions-manager.lock';

// Versuchen, die Lock-Datei zu öffnen
$lockHandle = fopen($lockFile, 'w+');
if (!$lockHandle) {
    fwrite(STDERR, "Kann Lock-Datei nicht öffnen: $lockFile\n");
    exit(1);
}

// Versuchen, ein exklusives Lock zu erhalten (non-blocking)
if (!flock($lockHandle, LOCK_EX | LOCK_NB)) {
    fwrite(STDERR, "Konnte kein Lock erhalten. Skript läuft bereits.\n");
    fclose($lockHandle);
    exit(1);
}

// Pfad zum Python-Skript
$pythonScript = '/home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py';

// Argumente für das Skript vorbereiten
$args = implode(' ', array_map('escapeshellarg', array_slice($argv, 1)));

// Befehl zum Ausführen des Python-Skripts zusammenstellen
$command = "/usr/bin/python3 " . escapeshellarg($pythonScript) . " $args";

// Befehl ausführen und den Exit-Code speichern
$returnCode = 0;
passthru($command, $returnCode);

// Lock freigeben und Datei schließen
flock($lockHandle, LOCK_UN);
fclose($lockHandle);

// Mit dem gleichen Exit-Code beenden wie das Python-Skript
exit($returnCode);
