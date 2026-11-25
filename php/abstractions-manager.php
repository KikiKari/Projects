<?php
// abstraction-provenance: {"artifact_sha256": "d74fe984a26832abec9ea3958c9dd75c50fe2db9d29251f760ddf66f0c180c24", "source_sha256": "76a9327ec4d8b7b9abcabfcbbbf89350cb4a3a4fdc0c949a0b343fe059dc87a8", "target_language": "php"}
// abstractions-manager.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py
// Dieses Skript fuehrt das externe Shell-Skript abstractions-manager-cron.sh aus
// und uebergibt alle Kommandozeilenargumente unveraendert.

// Sammle alle Kommandozeilenargumente (ausser dem Skriptnamen)
$args = array_slice($argv, 1);

// Konstruiere den Befehl mit dem externen Skript und den Argumenten
$command = '/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh ' . implode(' ', array_map('escapeshellarg', $args));

// Fuehre den Befehl aus und uebergebe die volle Kontrolle (entspricht exec)
passthru($command, $exitCode);

// Beende das PHP-Skript mit dem gleichen Exit-Code wie das aufgerufene Skript
exit($exitCode);
?>
