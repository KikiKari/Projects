<?php
// abstraction-provenance: {"artifact_sha256": "210961b1ae509abd7f0206428e94d0a407d2604bb9b5db8fad223dbf1e171b89", "source_sha256": "8621f6f7e524474de82b3d877ee62bbcbd9fa3b247b69c437b063b71fa995f5a", "target_language": "php"}
// ops-hub-heartbeat.js — portiert nach php
// Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
// auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
// Aktualisiere den Statusbericht mit aktueller Zeit
$statusPath = __DIR__ . '/../docs/ops-hub/status.md';

function updateHeartbeat() {
    global $statusPath;
    
    // Lese den Inhalt der Datei
    if (!file_exists($statusPath)) {
        error_log('❌ Konnte status.md nicht finden: ' . $statusPath);
        return;
    }
    
    try {
        $content = file_get_contents($statusPath);
        if ($content === false) {
            throw new Exception('Konnte Datei nicht lesen');
        }
    } catch (Exception $e) {
        error_log('❌ Konnte status.md nicht lesen: ' . $e->getMessage());
        return;
    }

    // Erhalte das aktuelle Datum und Uhrzeit in deutscher Zeitzone
    date_default_timezone_set('Europe/Berlin');
    $now = date('d.m.Y, H:i:s');
    $updated = preg_replace('/(Letzter Heartbeat:) [^\n]*/', '$1 ' . $now, $content);

    // Schreibe den aktualisierten Inhalt zurück in die Datei
    try {
        $result = file_put_contents($statusPath, $updated);
        if ($result === false) {
            throw new Exception('Konnte Datei nicht schreiben');
        }
        echo "✅ Heartbeat aktualisiert: " . $now . "\n";
    } catch (Exception $e) {
        error_log('❌ Konnte status.md nicht schreiben: ' . $e->getMessage());
    }
}

updateHeartbeat();
